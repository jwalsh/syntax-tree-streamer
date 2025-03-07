#!/usr/bin/env python3
"""
Proust Reader - A streaming text viewer with AST-like features

This script displays a "reading progress" window for Proust's "Du côté de chez Swann",
highlighting the current paragraph, sentence, and word to simulate a stream of thought.
"""

import os
import sys
import time
import re
import curses
import random
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Dict, Any

try:
    import spacy
    SPACY_AVAILABLE = True
except ImportError:
    SPACY_AVAILABLE = False
    print("spaCy not available. Using basic text processing instead.")
    print("To install spaCy: pip install spacy")
    print("To install French language model: python -m spacy download fr_core_news_sm")

@dataclass
class TextUnit:
    text: str
    unit_type: str  # 'paragraph', 'sentence', 'word', 'phrase', etc.
    parent: Optional['TextUnit'] = None
    children: List['TextUnit'] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    span: Any = None  # spaCy span object
    
    @property
    def id(self) -> str:
        """Generate a unique ID for this unit based on position in hierarchy."""
        if self.parent is None:
            return self.unit_type.lower()
        
        # Get index of this unit in its parent's children
        if self.parent.children:
            idx = next((i for i, child in enumerate(self.parent.children) 
                       if child is self), 0)
        else:
            idx = 0
            
        return f"{self.parent.id}-{self.unit_type[0].lower()}{idx}"
        
    def to_s_expr(self, indent=0) -> str:
        """Convert this unit to an S-expression."""
        ind = "  " * indent
        meta_str = ""
        
        if self.metadata:
            meta_items = [f"{k} {v}" for k, v in self.metadata.items()]
            meta_str = f" :metadata {{{', '.join(meta_items)}}}"
            
        if self.unit_type in ["WORD", "PUNCT", "NUM", "SYM"]:
            # Terminal nodes include the actual text
            return f"{ind}({self.unit_type} \"{self.text}\"{meta_str})"
            
        # Non-terminal nodes include their children
        result = [f"{ind}({self.unit_type} :id \"{self.id}\"{meta_str}"]
        
        for child in self.children:
            result.append(child.to_s_expr(indent + 1))
            
        result.append(f"{ind})")
        return "\n".join(result)

class ProustReader:
    def __init__(self, file_path, start_line=56, use_spacy=True):
        """Initialize the Proust reader with the given file path."""
        self.file_path = file_path
        self.paragraphs = []
        self.current_paragraph_idx = 0
        self.current_sentence_idx = 0
        self.current_word_idx = 0
        self.reading_speed = 0.3  # seconds per word
        self.start_line = start_line  # Skip header and start at first content paragraph
        self.use_spacy = use_spacy and SPACY_AVAILABLE
        
        # Initialize spaCy if available
        if self.use_spacy:
            try:
                self.nlp = spacy.load("fr_core_news_sm")
                print("Using spaCy French language model for analysis")
            except OSError:
                print("French language model not found. Downloading...")
                os.system("python -m spacy download fr_core_news_sm")
                try:
                    self.nlp = spacy.load("fr_core_news_sm")
                    print("French model loaded successfully")
                except Exception as e:
                    print(f"Error loading French model: {e}")
                    self.use_spacy = False
        
        self.load_text()
        self.parse_text()

    def load_text(self):
        """Load the text from the file and split it into paragraphs."""
        with open(self.file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()[self.start_line:]  # Skip header
            
        # Join lines into paragraphs (empty line is paragraph separator)
        paragraph = ""
        for line in lines:
            if line.strip():
                paragraph += line.strip() + " "
            elif paragraph:
                self.paragraphs.append(paragraph.strip())
                paragraph = ""
        
        if paragraph:  # Add the last paragraph if it exists
            self.paragraphs.append(paragraph.strip())
            
        # Limit to first 20 paragraphs for demo
        self.paragraphs = self.paragraphs[:20]

    def parse_text(self):
        """Parse the text into a tree structure (paragraph -> sentence -> word)."""
        self.text_tree = TextUnit("Du côté de chez Swann", "BOOK")
        
        if self.use_spacy:
            self._parse_with_spacy()
        else:
            self._parse_with_regex()
    
    def _parse_with_spacy(self):
        """Parse the text using spaCy's linguistic features."""
        for i, paragraph_text in enumerate(self.paragraphs):
            # Process the paragraph with spaCy
            doc = self.nlp(paragraph_text)
            
            # Create paragraph node
            paragraph = TextUnit(paragraph_text, "PARAGRAPH", self.text_tree)
            paragraph.metadata = {
                "position": i,
                "length": len(paragraph_text)
            }
            paragraph.span = doc
            self.text_tree.children.append(paragraph)
            
            # Add sentences
            for j, sent in enumerate(doc.sents):
                sentence = TextUnit(sent.text, "SENTENCE", paragraph)
                sentence.metadata = {
                    "position": j,
                    "length": len(sent.text)
                }
                sentence.span = sent
                paragraph.children.append(sentence)
                
                # Analyze phrases (based on noun chunks and verb phrases)
                phrases = list(sent.noun_chunks)
                
                # Simple algorithm to break remaining tokens into phrases
                current_phrase_tokens = []
                current_phrase_type = None
                
                for token in sent:
                    # Check if token is start of a new phrase type
                    if token.pos_ in ("NOUN", "PROPN") and current_phrase_type != "NP":
                        # Save current phrase if it exists
                        if current_phrase_tokens:
                            self._add_phrase(sentence, current_phrase_tokens, current_phrase_type)
                            current_phrase_tokens = []
                        current_phrase_type = "NP"
                    elif token.pos_ == "VERB" and current_phrase_type != "VP":
                        if current_phrase_tokens:
                            self._add_phrase(sentence, current_phrase_tokens, current_phrase_type)
                            current_phrase_tokens = []
                        current_phrase_type = "VP"
                    elif token.pos_ == "ADP" and current_phrase_type != "PP":
                        if current_phrase_tokens:
                            self._add_phrase(sentence, current_phrase_tokens, current_phrase_type)
                            current_phrase_tokens = []
                        current_phrase_type = "PP"
                    elif token.pos_ == "PUNCT" and token.text not in [",", "."]:
                        # Handle punctuation as separate units
                        if current_phrase_tokens:
                            self._add_phrase(sentence, current_phrase_tokens, current_phrase_type)
                            current_phrase_tokens = []
                        
                        # Add punctuation directly to sentence
                        punct = TextUnit(token.text, "PUNCT", sentence)
                        punct.metadata = {
                            "pos": token.pos_,
                            "lemma": token.lemma_
                        }
                        punct.span = token
                        sentence.children.append(punct)
                        continue
                    
                    # Add token to current phrase
                    current_phrase_tokens.append(token)
                
                # Add final phrase if it exists
                if current_phrase_tokens:
                    self._add_phrase(sentence, current_phrase_tokens, current_phrase_type)
    
    def _add_phrase(self, sentence, tokens, phrase_type):
        """Helper to add a phrase with its tokens to a sentence."""
        if not tokens:
            return
            
        # Default to generic phrase type if none determined
        if not phrase_type:
            phrase_type = "PHRASE"
            
        # Create the phrase node
        phrase_text = " ".join(t.text for t in tokens)
        phrase = TextUnit(phrase_text, phrase_type, sentence)
        phrase.metadata = {
            "length": len(phrase_text)
        }
        phrase.span = tokens[0].doc[tokens[0].i:tokens[-1].i+1]
        sentence.children.append(phrase)
        
        # Add individual words
        for token in tokens:
            # Determine token type based on POS
            if token.pos_ == "PUNCT":
                token_type = "PUNCT"
            elif token.pos_ == "NUM":
                token_type = "NUM"
            elif token.pos_ in ("NOUN", "PROPN"):
                token_type = "N"
            elif token.pos_ == "VERB":
                token_type = "V"
            elif token.pos_ == "PRON":
                token_type = "PRON"
            elif token.pos_ == "DET":
                token_type = "DET"
            elif token.pos_ == "ADJ":
                token_type = "ADJ"
            elif token.pos_ == "ADV":
                token_type = "ADV"
            elif token.pos_ == "ADP":
                token_type = "P"
            elif token.pos_ == "CCONJ":
                token_type = "CONJ"
            elif token.pos_ == "SCONJ":
                token_type = "SUB"
            else:
                token_type = token.pos_
                
            word = TextUnit(token.text, token_type, phrase)
            word.metadata = {
                "pos": token.pos_,
                "lemma": token.lemma_,
                "tag": token.tag_
            }
            word.span = token
            phrase.children.append(word)
    
    def _parse_with_regex(self):
        """Parse the text using regular expressions (fallback)."""
        for i, paragraph_text in enumerate(self.paragraphs):
            paragraph = TextUnit(paragraph_text, "PARAGRAPH", self.text_tree)
            paragraph.metadata = {
                "position": i,
                "length": len(paragraph_text)
            }
            self.text_tree.children.append(paragraph)
            
            # Split paragraph into sentences
            sentences = re.split(r'(?<=[.!?])\s+', paragraph_text)
            for j, sentence_text in enumerate(sentences):
                if not sentence_text.strip():
                    continue
                    
                sentence = TextUnit(sentence_text, "SENTENCE", paragraph)
                sentence.metadata = {
                    "position": j,
                    "length": len(sentence_text)
                }
                paragraph.children.append(sentence)
                
                # Split sentences into phrases (by commas)
                phrases = re.split(r'(,\s*)', sentence_text)
                current_phrase_text = ""
                
                for k, phrase_part in enumerate(phrases):
                    if re.match(r',\s*', phrase_part):
                        # Add current phrase if it exists
                        if current_phrase_text:
                            phrase = TextUnit(current_phrase_text, "PHRASE", sentence)
                            phrase.metadata = {
                                "position": k // 2,  # Account for split capturing comma
                                "length": len(current_phrase_text)
                            }
                            sentence.children.append(phrase)
                            
                            # Add words to phrase
                            self._add_words_to_unit(phrase, current_phrase_text)
                            current_phrase_text = ""
                            
                        # Add comma as punctuation
                        punct = TextUnit(phrase_part.strip(), "PUNCT", sentence)
                        sentence.children.append(punct)
                    else:
                        current_phrase_text += phrase_part
                
                # Add final phrase if it exists
                if current_phrase_text:
                    phrase = TextUnit(current_phrase_text, "PHRASE", sentence)
                    phrase.metadata = {
                        "position": len(phrases) // 2,
                        "length": len(current_phrase_text)
                    }
                    sentence.children.append(phrase)
                    
                    # Add words to phrase
                    self._add_words_to_unit(phrase, current_phrase_text)
    
    def _add_words_to_unit(self, unit, text):
        """Add words to a textual unit using basic regex parsing."""
        # Simple word and punctuation detection
        tokens = re.findall(r'\b\w+\b|[.,;:!?]', text)
        
        for token in tokens:
            if not token.strip():
                continue
                
            # Basic POS determination
            if re.match(r'[.,;:!?]', token):
                token_type = "PUNCT"
            elif token.lower() in ["je", "tu", "il", "elle", "nous", "vous", "ils", "elles", "me", "te", "se", "le", "la"]:
                token_type = "PRON"
            elif token.lower() in ["et", "ou", "mais", "donc", "car", "ni"]:
                token_type = "CONJ"
            elif token.lower() in ["le", "la", "les", "un", "une", "des", "ma", "mon", "mes"]:
                token_type = "DET"
            elif token.lower() in ["à", "de", "en", "dans", "sur", "sous", "par", "pour", "avec", "sans"]:
                token_type = "P"
            elif token.lower() in ["que", "qui", "dont", "où", "quand", "comment", "pourquoi"]:
                token_type = "SUB"
            elif re.match(r'\d+', token):
                token_type = "NUM"
            else:
                token_type = "WORD"
                
            word = TextUnit(token, token_type, unit)
            unit.children.append(word)

    def get_visible_text(self, window_height):
        """Get the text to display in the window."""
        # Find the index of the first paragraph to display
        start_idx = max(0, self.current_paragraph_idx - 3)
        end_idx = min(len(self.paragraphs), start_idx + window_height)
        
        visible_paragraphs = self.paragraphs[start_idx:end_idx]
        return visible_paragraphs, start_idx

    def get_current_elements(self):
        """Get the current paragraph, sentence, and word."""
        if not self.text_tree.children:
            return None, None, None
            
        current_paragraph = self.text_tree.children[self.current_paragraph_idx]
        if not current_paragraph.children:
            return current_paragraph, None, None
            
        current_sentence = current_paragraph.children[self.current_sentence_idx]
        if not current_sentence.children:
            return current_paragraph, current_sentence, None
            
        current_word = current_sentence.children[self.current_word_idx]
        return current_paragraph, current_sentence, current_word

    def move_to_next_word(self):
        """Move to the next word in the text."""
        current_paragraph = self.text_tree.children[self.current_paragraph_idx]
        current_sentence = current_paragraph.children[self.current_sentence_idx]
        
        # Move to next word
        self.current_word_idx += 1
        
        # If at end of sentence, move to next sentence
        if self.current_word_idx >= len(current_sentence.children):
            self.current_word_idx = 0
            self.current_sentence_idx += 1
            
            # If at end of paragraph, move to next paragraph
            if self.current_sentence_idx >= len(current_paragraph.children):
                self.current_sentence_idx = 0
                self.current_paragraph_idx += 1
                
                # If at end of text, wrap around
                if self.current_paragraph_idx >= len(self.text_tree.children):
                    self.current_paragraph_idx = 0

    def run_with_curses(self, stdscr):
        """Run the reader with a curses interface."""
        # Set up curses
        curses.curs_set(0)  # Hide the cursor
        stdscr.clear()
        
        # Define colors
        curses.start_color()
        curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_WHITE)  # Current paragraph
        curses.init_pair(2, curses.COLOR_BLACK, curses.COLOR_YELLOW)  # Current sentence
        curses.init_pair(3, curses.COLOR_WHITE, curses.COLOR_BLUE)    # Current word
        curses.init_pair(4, curses.COLOR_WHITE, curses.COLOR_BLACK)   # Normal text
        
        # Get window dimensions
        max_y, max_x = stdscr.getmaxlines(), stdscr.getmaxyx()[1]
        text_height = max_y - 5  # Leave room for instructions
        
        # Main loop
        running = True
        paused = False
        
        while running:
            stdscr.clear()
            
            # Display instructions
            stdscr.addstr(0, 0, "PROUST READER - Streaming Text Viewer", curses.A_BOLD)
            stdscr.addstr(1, 0, "Press 'q' to quit, 'p' to pause/resume, arrow keys to adjust speed")
            
            # Get current elements
            current_para, current_sent, current_word = self.get_current_elements()
            
            # Display text
            visible_paragraphs, start_idx = self.get_visible_text(text_height)
            y_pos = 3  # Start position after instructions
            
            for i, para_text in enumerate(visible_paragraphs):
                para_idx = start_idx + i
                
                # Check if this is the current paragraph
                is_current_para = (para_idx == self.current_paragraph_idx)
                
                if is_current_para and current_sent:
                    # Display paragraph with highlighted sentence
                    sentences = re.split(r'(?<=[.!?])\s+', para_text)
                    x_pos = 0
                    
                    for j, sent in enumerate(sentences):
                        is_current_sent = (j == self.current_sentence_idx)
                        
                        if is_current_sent and current_word:
                            # Display sentence with highlighted word
                            words = re.findall(r'\b\w+\b|[.,;:!?]|\s+', sent)
                            for k, word in enumerate(words):
                                if k == self.current_word_idx:
                                    stdscr.addstr(y_pos, x_pos, word, curses.color_pair(3))
                                else:
                                    stdscr.addstr(y_pos, x_pos, word, curses.color_pair(2))
                                x_pos += len(word)
                        else:
                            attr = curses.color_pair(2) if is_current_sent else curses.color_pair(4)
                            stdscr.addstr(y_pos, x_pos, sent + " ", attr)
                            x_pos += len(sent) + 1
                        
                        # Wrap text if needed
                        if x_pos >= max_x:
                            y_pos += 1
                            x_pos = 0
                    
                    y_pos += 2  # Extra space after current paragraph
                else:
                    # Display normal paragraph
                    attr = curses.color_pair(1) if is_current_para else curses.color_pair(4)
                    
                    # Split paragraph into lines to fit window width
                    words = para_text.split()
                    line = ""
                    for word in words:
                        if len(line) + len(word) + 1 > max_x:
                            stdscr.addstr(y_pos, 0, line.strip(), attr)
                            y_pos += 1
                            line = ""
                        line += word + " "
                    
                    if line:
                        stdscr.addstr(y_pos, 0, line.strip(), attr)
                    
                    y_pos += 2  # Space between paragraphs
            
            # Show reading speed
            speed_text = f"Reading speed: {1/self.reading_speed:.1f} words per second"
            status = "PAUSED" if paused else "RUNNING"
            stdscr.addstr(max_y-1, 0, f"{speed_text} | Status: {status}")
            
            # Refresh the screen
            stdscr.refresh()
            
            # Check for keyboard input (non-blocking)
            stdscr.nodelay(True)
            key = stdscr.getch()
            
            if key == ord('q'):
                running = False
            elif key == ord('p'):
                paused = not paused
            elif key == curses.KEY_RIGHT:
                self.reading_speed = max(0.05, self.reading_speed - 0.05)
            elif key == curses.KEY_LEFT:
                self.reading_speed = min(1.0, self.reading_speed + 0.05)
            
            # Move to next word if not paused
            if not paused:
                self.move_to_next_word()
                time.sleep(self.reading_speed)

def main():
    """Main function."""
    # Get the path to the book
    script_dir = os.path.dirname(os.path.abspath(__file__))
    book_path = os.path.join(os.path.dirname(script_dir), "data", "pg2650.txt")
    
    # Parse command line arguments
    import argparse
    parser = argparse.ArgumentParser(description="Proust Reader - A streaming text viewer with AST generation")
    parser.add_argument("--ast", action="store_true", help="Generate AST representation")
    parser.add_argument("--no-spacy", action="store_true", help="Disable spaCy processing")
    parser.add_argument("--paragraphs", type=int, default=2, help="Number of paragraphs to process for AST")
    parser.add_argument("--output", help="Output file for AST (default: examples/proust_ast.lisp)")
    args = parser.parse_args()
    
    # Set default output path
    if args.ast and not args.output:
        args.output = os.path.join(os.path.dirname(script_dir), "examples", "proust_ast.lisp")
    
    # Initialize reader with or without spaCy
    reader = ProustReader(book_path, use_spacy=not args.no_spacy)
    
    if args.ast:
        # Generate AST representation using the enhanced TextUnit.to_s_expr method
        print(f"Generating AST for {args.paragraphs} paragraphs...")
        
        # Get the specified number of paragraphs from the text tree
        paragraphs = reader.text_tree.children[:args.paragraphs]
        
        # Generate S-expressions
        ast_content = ""
        for paragraph in paragraphs:
            ast_content += paragraph.to_s_expr() + "\n"
        
        # Write to file
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(ast_content)
        print(f"AST representation saved to {args.output}")
    else:
        # Run the interactive reader
        try:
            curses.wrapper(reader.run_with_curses)
        except KeyboardInterrupt:
            print("Reader terminated by user.")
        except Exception as e:
            print(f"Error running reader: {e}")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    main()