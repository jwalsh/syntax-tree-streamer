# Syntax Tree Streamer

A syntax tree representation and processing system for streaming S-expression-based data from LLMs, with a focus on linguistic analysis and incremental parsing.

## Features

- Interactive text streaming viewer with highlighting for currently processed text
- S-expression Abstract Syntax Tree (AST) generation for linguistic analysis
- Integration with spaCy for advanced natural language processing
- Hierarchical representation of text (paragraphs → sentences → phrases → words)
- Rich metadata annotations for linguistic features

## Proust Reader Demo

This repository includes a demonstration application called "Proust Reader" that processes Marcel Proust's "Du côté de chez Swann" and displays it with syntax highlighting while generating S-expression-based AST representations.

## Installation

### Using Poetry (recommended)

```bash
# Clone the repository
git clone https://github.com/jwalsh/syntax-tree-streamer.git
cd syntax-tree-streamer

# Install dependencies with Poetry
poetry install

# Activate the Poetry virtual environment
poetry shell
```

### Using pip

```bash
# Clone the repository
git clone https://github.com/jwalsh/syntax-tree-streamer.git
cd syntax-tree-streamer

# Install dependencies
pip install -r requirements.txt

# Install the French language model for spaCy
python -m spacy download fr_core_news_sm
```

## Usage

### Running the Proust Reader

```bash
# Using Poetry
poetry run proust-reader

# Or directly using Python
python src/proust_reader.py
```

### Generating AST Representations

```bash
# Generate AST for the first 2 paragraphs (default)
python src/proust_reader.py --ast

# Generate AST for more paragraphs
python src/proust_reader.py --ast --paragraphs 5

# Save to a specific file
python src/proust_reader.py --ast --output my_ast.lisp

# Generate AST without using spaCy (falls back to regex-based parsing)
python src/proust_reader.py --ast --no-spacy
```

### Interactive Controls

While in the interactive reader mode:
- `q` - Quit the application
- `p` - Pause/resume reading
- `←/→` - Adjust reading speed
- `Ctrl+C` - Force quit

## Project Structure

- `src/` - Source code
  - `proust_reader.py` - Main reader application
- `examples/` - Example S-expression AST representations
  - `proust_ast.lisp` - Generated AST for Proust's text
- `data/` - Input data
  - `pg2650.txt` - Marcel Proust's "Du côté de chez Swann"
- `templates/` - LaTeX templates for documentation

## Development

This project uses a literate programming approach with org-mode for documentation and code generation. Use the Makefile targets for common development tasks:

```bash
# Setup development directories
make setup-dirs

# Clean generated files
make clean

# Download required data
make data/pg2650.txt
```

## License

MIT