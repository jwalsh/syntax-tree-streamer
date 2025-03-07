#!/usr/bin/env bash
# Setup script for Syntax Tree Parser
# Creates BNF grammar definitions, lexer, parser, and test files

set -e  # Exit on error
set -u  # Treat unset variables as errors

# Base directory for the project
PROJECT_DIR=~/projects/496a7472-0de1-4224-829c-75491f63b8f2
EXAMPLES_DIR="$PROJECT_DIR/examples"
PARSER_DIR="$PROJECT_DIR/syntax-parser"

# Check if Bison is installed
if ! command -v bison &> /dev/null; then
    echo "ERROR: Bison is required but not found"
    exit 1
fi

# Create parser directory structure
mkdir -p "$PARSER_DIR"/{src,include,tests,examples,doc}

# Check existing examples
echo "Checking existing examples:"
ls -l "$EXAMPLES_DIR"

# Copy existing examples to parser examples directory
echo "Copying examples to parser directory..."
cp "$EXAMPLES_DIR"/*.lisp "$PARSER_DIR/examples/"

# Create grammar file
cat > "$PARSER_DIR/src/syntax_tree.y" << 'EOF'
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "syntax_tree.h"

/* Declarations */
extern int yylex(void);
extern int yylineno;
extern char* yytext;
void yyerror(const char* s);

/* Root of the parsed syntax tree */
syntax_node_t* syntax_root = NULL;
%}

/* Bison declarations */
%union {
    char* str_val;
    syntax_node_t* node;
    property_t* prop;
    property_list_t* prop_list;
    node_list_t* node_list;
    metadata_t* metadata;
}

/* Token definitions */
%token <str_val> CATEGORY STRING SYMBOL KEYWORD
%token LPAREN RPAREN COLON LBRACE RBRACE

/* Non-terminal type declarations */
%type <node> syntax_tree node
%type <str_val> category content
%type <prop> property
%type <prop_list> properties_list
%type <node_list> node_list
%type <metadata> metadata_map metadata_entry_list metadata_entry

%start syntax_tree

%%

/* Grammar rules */

syntax_tree
    : node
    { 
        syntax_root = $1;
        $$ = $1;
    }
    ;

node
    : LPAREN category content properties_list node_list RPAREN
    {
        $$ = create_node($2, $3, $4, $5);
    }
    | LPAREN category content properties_list RPAREN
    {
        $$ = create_node($2, $3, $4, NULL);
    }
    | LPAREN category STRING RPAREN
    {
        $$ = create_leaf_node($2, $3);
    }
    ;

category
    : CATEGORY
    { 
        $$ = $1;
    }
    ;

content
    : STRING
    {
        $$ = $1;
    }
    | /* empty */
    {
        $$ = NULL;
    }
    ;

properties_list
    : /* empty */
    {
        $$ = create_empty_prop_list();
    }
    | properties_list property
    {
        $$ = add_property($1, $2);
    }
    ;

property
    : COLON SYMBOL metadata_map
    {
        $$ = create_property($2, $3);
    }
    | COLON SYMBOL STRING
    {
        $$ = create_string_property($2, $3);
    }
    ;

metadata_map
    : LBRACE metadata_entry_list RBRACE
    {
        $$ = $2;
    }
    | LBRACE RBRACE
    {
        $$ = create_empty_metadata();
    }
    ;

metadata_entry_list
    : metadata_entry
    {
        $$ = $1;
    }
    | metadata_entry_list metadata_entry
    {
        $$ = merge_metadata($1, $2);
    }
    ;

metadata_entry
    : KEYWORD STRING
    {
        $$ = create_metadata_entry($1, $2);
    }
    | KEYWORD LBRACE metadata_entry_list RBRACE
    {
        $$ = create_nested_metadata($1, $3);
    }
    ;

node_list
    : node
    {
        $$ = create_node_list($1);
    }
    | node_list node
    {
        $$ = add_node($1, $2);
    }
    ;

%%

/* Support functions */

void yyerror(const char* s) {
    fprintf(stderr, "Parse error at line %d: %s near '%s'\n", yylineno, s, yytext);
}
EOF

# Create lexer file
cat > "$PARSER_DIR/src/syntax_tree.l" << 'EOF'
%{
#include <stdio.h>
#include <string.h>
#include "syntax_tree.h"
#include "syntax_tree.tab.h"

/* Uncomment for standalone testing
#ifndef YYSTYPE
typedef union {
    char* str_val;
} YYSTYPE;
extern YYSTYPE yylval;
#endif
*/

char* strip_quotes(char* str);
%}

%option noyywrap
%option yylineno

%%

"("                         { return LPAREN; }
")"                         { return RPAREN; }
":"                         { return COLON; }
"{"                         { return LBRACE; }
"}"                         { return RBRACE; }

[ \t\n\r]+                  { /* Skip whitespace */ }

"S"|"NP"|"VP"|"PP"|"ADVP"|"AP"|"PARTCL"|"RELCL"|"INFCL"|"SUBCL"|"NOMCL"|"V"|"N"|"DET"|"PRON"|"ADJ"|"ADV"|"P"|"CONJ"|"SUB"|"REL"|"PART"|"NUM"|"PUNCT"|"AUX" {
                                yylval.str_val = strdup(yytext);
                                return CATEGORY;
                            }

":"[a-zA-Z][a-zA-Z0-9-]*   {
                                yylval.str_val = strdup(yytext);
                                return KEYWORD;
                            }

[a-zA-Z][a-zA-Z0-9-]*      {
                                yylval.str_val = strdup(yytext);
                                return SYMBOL;
                            }

\"[^\"]*\"                  {
                                yylval.str_val = strip_quotes(strdup(yytext));
                                return STRING;
                            }

.                           { fprintf(stderr, "Unrecognized character: %s\n", yytext); }

%%

char* strip_quotes(char* str) {
    int len = strlen(str);
    if (len >= 2) {
        str[len-1] = '\0';  // Remove ending quote
        return str + 1;     // Skip starting quote
    }
    return str;
}
EOF

# Create header file
cat > "$PARSER_DIR/include/syntax_tree.h" << 'EOF'
#ifndef SYNTAX_TREE_H
#define SYNTAX_TREE_H

/* Data structures for the syntax tree */

typedef struct metadata_s {
    char* key;
    union {
        char* str_value;
        struct metadata_s* nested;
    } value;
    int is_nested;
    struct metadata_s* next;
} metadata_t;

typedef struct property_s {
    char* key;
    metadata_t* value;
    struct property_s* next;
} property_t;

typedef struct property_list_s {
    property_t* first;
    property_t* last;
} property_list_t;

typedef struct node_s {
    char* category;
    char* content;
    property_list_t* properties;
    struct node_list_s* children;
} syntax_node_t;

typedef struct node_list_s {
    syntax_node_t* node;
    struct node_list_s* next;
} node_list_t;

/* Function prototypes */
syntax_node_t* create_node(char* category, char* content, property_list_t* props, node_list_t* children);
syntax_node_t* create_leaf_node(char* category, char* content);
property_list_t* create_empty_prop_list();
property_t* create_property(char* key, metadata_t* value);
property_t* create_string_property(char* key, char* value);
property_list_t* add_property(property_list_t* list, property_t* prop);
node_list_t* create_node_list(syntax_node_t* node);
node_list_t* add_node(node_list_t* list, syntax_node_t* node);
metadata_t* create_empty_metadata();
metadata_t* create_metadata_entry(char* key, char* value);
metadata_t* create_nested_metadata(char* key, metadata_t* nested);
metadata_t* merge_metadata(metadata_t* first, metadata_t* second);
void print_syntax_tree(syntax_node_t* root, int indent);

#endif /* SYNTAX_TREE_H */
EOF

# Create implementation file
cat > "$PARSER_DIR/src/syntax_tree.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "syntax_tree.h"

syntax_node_t* create_node(char* category, char* content, property_list_t* props, node_list_t* children) {
    syntax_node_t* node = (syntax_node_t*)malloc(sizeof(syntax_node_t));
    if (!node) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    
    node->category = category;
    node->content = content;
    node->properties = props;
    node->children = children;
    
    return node;
}

syntax_node_t* create_leaf_node(char* category, char* content) {
    return create_node(category, content, create_empty_prop_list(), NULL);
}

property_list_t* create_empty_prop_list() {
    property_list_t* list = (property_list_t*)malloc(sizeof(property_list_t));
    if (!list) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    
    list->first = NULL;
    list->last = NULL;
    
    return list;
}

property_t* create_property(char* key, metadata_t* value) {
    property_t* prop = (property_t*)malloc(sizeof(property_t));
    if (!prop) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    
    prop->key = key;
    prop->value = value;
    prop->next = NULL;
    
    return prop;
}

property_t* create_string_property(char* key, char* value) {
    metadata_t* meta = create_metadata_entry("value", value);
    return create_property(key, meta);
}

property_list_t* add_property(property_list_t* list, property_t* prop) {
    if (!list->first) {
        list->first = prop;
        list->last = prop;
    } else {
        list->last->next = prop;
        list->last = prop;
    }
    
    return list;
}

node_list_t* create_node_list(syntax_node_t* node) {
    node_list_t* list = (node_list_t*)malloc(sizeof(node_list_t));
    if (!list) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    
    list->node = node;
    list->next = NULL;
    
    return list;
}

node_list_t* add_node(node_list_t* list, syntax_node_t* node) {
    node_list_t* new_item = create_node_list(node);
    new_item->next = list;
    return new_item;
}

metadata_t* create_empty_metadata() {
    return NULL;
}

metadata_t* create_metadata_entry(char* key, char* value) {
    metadata_t* meta = (metadata_t*)malloc(sizeof(metadata_t));
    if (!meta) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    
    meta->key = key;
    meta->value.str_value = value;
    meta->is_nested = 0;
    meta->next = NULL;
    
    return meta;
}

metadata_t* create_nested_metadata(char* key, metadata_t* nested) {
    metadata_t* meta = (metadata_t*)malloc(sizeof(metadata_t));
    if (!meta) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    
    meta->key = key;
    meta->value.nested = nested;
    meta->is_nested = 1;
    meta->next = NULL;
    
    return meta;
}

metadata_t* merge_metadata(metadata_t* first, metadata_t* second) {
    if (!first) return second;
    
    metadata_t* current = first;
    while (current->next) {
        current = current->next;
    }
    current->next = second;
    
    return first;
}

void print_indent(int indent) {
    for (int i = 0; i < indent; i++) {
        printf("  ");
    }
}

void print_metadata(metadata_t* meta, int indent) {
    if (!meta) return;
    
    metadata_t* current = meta;
    while (current) {
        print_indent(indent);
        printf("%s: ", current->key);
        
        if (current->is_nested) {
            printf("{\n");
            print_metadata(current->value.nested, indent + 1);
            print_indent(indent);
            printf("}");
        } else {
            printf("\"%s\"", current->value.str_value);
        }
        
        if (current->next) {
            printf(",\n");
        } else {
            printf("\n");
        }
        
        current = current->next;
    }
}

void print_properties(property_list_t* props, int indent) {
    if (!props || !props->first) return;
    
    property_t* current = props->first;
    while (current) {
        print_indent(indent);
        printf(":%s ", current->key);
        
        if (strcmp(current->key, "metadata") == 0) {
            printf("{\n");
            print_metadata(current->value, indent + 1);
            print_indent(indent);
            printf("}");
        } else {
            printf("%s", current->value->value.str_value);
        }
        
        if (current->next) {
            printf("\n");
        }
        
        current = current->next;
    }
}

void print_syntax_tree(syntax_node_t* root, int indent) {
    if (!root) return;
    
    print_indent(indent);
    printf("(%s", root->category);
    
    if (root->content) {
        printf(" \"%s\"", root->content);
    }
    
    if (root->properties && root->properties->first) {
        printf("\n");
        print_properties(root->properties, indent + 1);
    }
    
    if (root->children) {
        printf("\n");
        node_list_t* current = root->children;
        while (current) {
            print_syntax_tree(current->node, indent + 1);
            if (current->next) {
                printf("\n");
            }
            current = current->next;
        }
    }
    
    printf(")");
}
EOF

# Create main driver program
cat > "$PARSER_DIR/src/main.c" << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "syntax_tree.h"

extern FILE* yyin;
extern int yyparse(void);
extern syntax_node_t* syntax_root;

void print_usage(const char* program_name) {
    printf("Usage: %s <input_file.lisp>\n", program_name);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    FILE* input_file = fopen(argv[1], "r");
    if (!input_file) {
        fprintf(stderr, "Error: Could not open file %s\n", argv[1]);
        return 1;
    }
    
    yyin = input_file;
    int result = yyparse();
    fclose(input_file);
    
    if (result == 0 && syntax_root) {
        printf("Parse successful!\n\n");
        printf("Syntax Tree:\n");
        print_syntax_tree(syntax_root, 0);
        printf("\n");
        return 0;
    } else {
        fprintf(stderr, "Parse failed.\n");
        return 1;
    }
}
EOF

# Create Makefile
cat > "$PARSER_DIR/Makefile" << 'EOF'
CC = gcc
CFLAGS = -Wall -I./include
LDFLAGS =

SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin

SOURCES = $(SRC_DIR)/syntax_tree.c $(SRC_DIR)/main.c
PARSER_SRC = $(SRC_DIR)/syntax_tree.y
LEXER_SRC = $(SRC_DIR)/syntax_tree.l
OBJECTS = $(BUILD_DIR)/syntax_tree.o $(BUILD_DIR)/main.o $(BUILD_DIR)/syntax_tree.tab.o $(BUILD_DIR)/lex.yy.o

EXECUTABLE = $(BIN_DIR)/syntax_parser

.PHONY: all clean

all: setup $(EXECUTABLE)

setup:
	mkdir -p $(BUILD_DIR) $(BIN_DIR)

$(BUILD_DIR)/lex.yy.c: $(LEXER_SRC) $(BUILD_DIR)/syntax_tree.tab.h
	flex -o $@ $<

$(BUILD_DIR)/syntax_tree.tab.c $(BUILD_DIR)/syntax_tree.tab.h: $(PARSER_SRC)
	bison -d -o $(BUILD_DIR)/syntax_tree.tab.c $<

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/lex.yy.o: $(BUILD_DIR)/lex.yy.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/syntax_tree.tab.o: $(BUILD_DIR)/syntax_tree.tab.c
	$(CC) $(CFLAGS) -c $< -o $@

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)
EOF

# Create a simple test file
cat > "$PARSER_DIR/tests/simple.lisp" << 'EOF'
(S :metadata {:stream-position 42 :complete true}
  (NP :metadata {:semantic-role :agent}
    (PRON "je" :metadata {:person 1 :number :sing})
  )
  
  (VP
    (V "souhaite" :metadata {:features (INDIC PRES)})
    (V "installer" :metadata {:features (INF)})
    
    (NP
      (N "Emacs" :metadata {:entity-type :software})
      (NUM "31.0")
    )
  )
)
EOF

# Create a test script
cat > "$PARSER_DIR/tests/run_tests.sh" << 'EOF'
#!/bin/bash

PARSER="../bin/syntax_parser"

# Check if parser exists
if [ ! -f "$PARSER" ]; then
    echo "Error: Parser not found. Run 'make' in the parent directory first."
    exit 1
fi

# Run tests
for testfile in *.lisp; do
    echo "Testing $testfile..."
    $PARSER $testfile
    
    if [ $? -eq 0 ]; then
        echo "Test passed: $testfile"
        echo "-----------------------------"
    else
        echo "Test failed: $testfile"
        echo "-----------------------------"
    fi
done
EOF
chmod +x "$PARSER_DIR/tests/run_tests.sh"

# Create README file
cat > "$PARSER_DIR/README.md" << 'EOF'
# Syntax Tree Parser

This is a parser for s-expression based syntax trees used for linguistic analysis.

## Directory Structure

- `src/`: Source code for the parser
- `include/`: Header files
- `build/`: Compiled object files (created by make)
- `bin/`: Compiled executables (created by make)
- `tests/`: Test files and scripts
- `examples/`: Example syntax trees
- `doc/`: Documentation

## Building

To build the parser:

```bash
make clean  # Optional, to clean previous builds
make
```

This will create the `syntax_parser` executable in the `bin/` directory.

## Running

To parse a syntax tree file:

```bash
./bin/syntax_parser examples/freebsd-upgrade.lisp
```

## Testing

To run the tests:

```bash
cd tests
./run_tests.sh
```

## BNF Grammar

The parser is based on the following BNF grammar:

```bnf
<syntax-tree> ::= <node>

<node> ::= "(" <category> <content> <properties>* <child>* ")"

<category> ::= "S" | "NP" | "VP" | "PP" | "ADVP" | "AP" 
             | "PARTCL" | "RELCL" | "INFCL" | "SUBCL" | "NOMCL"
             | "V" | "N" | "DET" | "PRON" | "ADJ" | "ADV" | "P" | "CONJ" | "SUB" | "REL"
             | "PART" | "NUM" | "PUNCT" | "AUX"

<content> ::= <string> | ε

<properties> ::= <property-key> <property-value>

<property-key> ::= ":" <identifier>

<property-value> ::= <atom> | <list> | <map>
```

## Example Syntax Tree

```lisp
(S :metadata {:stream-position 0 :complete true}
  (NP
    (PRON "je")
  )
  (VP
    (V "souhaite")
    (V "installer")
    (NP
      (N "Emacs")
      (NUM "31.0")
    )
  )
)
```
EOF

# Make the script executable
chmod +x "$PARSER_DIR/tests/run_tests.sh"

echo "====================================================="
echo "Setup complete! Directory structure created at:"
echo "$PARSER_DIR"
echo "====================================================="
echo "To build the parser:"
echo "cd $PARSER_DIR"
echo "make"
echo ""
echo "To run on your example:"
echo "./bin/syntax_parser examples/freebsd-upgrade.lisp"
echo "====================================================="
