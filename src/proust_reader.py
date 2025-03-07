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
from dataclasses import dataclass
from typing import List, Tuple

@dataclass
class TextUnit:
    text: str
    unit_type: str  # 'paragraph', 'sentence', 'word', etc.
    parent: 'TextUnit' = None
    children: List['TextUnit'] = None
    
    def __post_init__(self):
        if self.children is None:
            self.children = []

class ProustReader:
    def __init__(self, file_path, start_line=56):
        """Initialize the Proust reader with the given file path."""
        self.file_path = file_path
        self.paragraphs = []
        self.current_paragraph_idx = 0
        self.current_sentence_idx = 0
        self.current_word_idx = 0
        self.reading_speed = 0.3  # seconds per word
        self.start_line = start_line  # Skip header and start at first content paragraph
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
        self.text_tree = TextUnit("Du côté de chez Swann", "book")
        
        for paragraph_text in self.paragraphs:
            paragraph = TextUnit(paragraph_text, "paragraph", self.text_tree)
            self.text_tree.children.append(paragraph)
            
            # Split paragraph into sentences
            sentences = re.split(r'(?<=[.!?])\s+', paragraph_text)
            for sentence_text in sentences:
                if not sentence_text.strip():
                    continue
                sentence = TextUnit(sentence_text, "sentence", paragraph)
                paragraph.children.append(sentence)
                
                # Split sentence into words
                words = re.findall(r'\b\w+\b|[.,;:!?]', sentence_text)
                for word_text in words:
                    if not word_text.strip():
                        continue
                    word = TextUnit(word_text, "word", sentence)
                    sentence.children.append(word)

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

def generate_ast(paragraphs, start_idx=0, end_idx=2):
    """Generate an S-expression AST representation of paragraphs."""
    ast = []
    
    for i, para in enumerate(paragraphs[start_idx:end_idx]):
        para_id = f"para-{start_idx + i}"
        para_node = f"(PARAGRAPH :id \"{para_id}\" :metadata {{:position {start_idx + i} :length {len(para)}}}\n"
        
        # Split into sentences
        sentences = re.split(r'(?<=[.!?])\s+', para)
        for j, sent in enumerate(sentences):
            if not sent.strip():
                continue
                
            sent_id = f"{para_id}-s{j}"
            sent_node = f"  (SENTENCE :id \"{sent_id}\" :metadata {{:position {j} :length {len(sent)}}}\n"
            
            # Split into phrases (roughly by commas, semicolons)
            phrases = re.split(r'([,;])', sent)
            phrase_fragments = []
            
            for k, phrase in enumerate(phrases):
                if not phrase.strip():
                    continue
                    
                if phrase in [',', ';']:
                    phrase_fragments.append(f"    (PUNCT \"{phrase}\")\n")
                    continue
                    
                phrase_id = f"{sent_id}-p{k}"
                phrase_node = f"    (PHRASE :id \"{phrase_id}\" :metadata {{:position {k}}}\n"
                
                # Process words and punctuation
                tokens = re.findall(r'\b\w+\b|[.,;:!?]', phrase)
                for m, token in enumerate(tokens):
                    if re.match(r'[.,;:!?]', token):
                        phrase_node += f"      (PUNCT \"{token}\")\n"
                    else:
                        # Determine POS tag (simplified)
                        pos = "N"  # Default to noun
                        if m == 0 and token.lower() in ["je", "tu", "il", "elle", "nous", "vous", "ils", "elles"]:
                            pos = "PRON"
                        elif token.lower() in ["et", "ou", "mais", "donc", "car", "ni"]:
                            pos = "CONJ"
                        elif token.lower() in ["le", "la", "les", "un", "une", "des", "ma", "mon", "mes"]:
                            pos = "DET"
                        elif token.lower() in ["à", "de", "en", "dans", "sur", "sous", "par", "pour", "avec", "sans"]:
                            pos = "P"
                        elif token.lower().endswith(("ais", "ait", "ions", "iez", "aient", "é", "i", "u")):
                            pos = "V"
                            
                        phrase_node += f"      ({pos} \"{token}\")\n"
                
                phrase_node += "    )\n"
                phrase_fragments.append(phrase_node)
            
            sent_node += "".join(phrase_fragments)
            sent_node += "  )\n"
            para_node += sent_node
        
        para_node += ")\n"
        ast.append(para_node)
    
    return "".join(ast)

def main():
    """Main function."""
    # Get the path to the book
    script_dir = os.path.dirname(os.path.abspath(__file__))
    book_path = os.path.join(os.path.dirname(script_dir), "data", "pg2650.txt")
    
    if len(sys.argv) > 1 and sys.argv[1] == "--ast":
        # Generate AST representation
        reader = ProustReader(book_path)
        ast = generate_ast(reader.paragraphs)
        
        ast_path = os.path.join(os.path.dirname(script_dir), "examples", "proust_ast.lisp")
        with open(ast_path, 'w', encoding='utf-8') as f:
            f.write(ast)
        print(f"AST representation saved to {ast_path}")
    else:
        # Run the reader
        reader = ProustReader(book_path)
        curses.wrapper(reader.run_with_curses)

if __name__ == "__main__":
    main()