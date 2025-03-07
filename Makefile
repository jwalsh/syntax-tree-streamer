# Makefile for Research and Development Workflow
# This Makefile provides a comprehensive set of targets to support
# research, development, documentation, and publication processes.

# Project Configuration
# Customize these variables to match your project structure
SRC_DIR = src            # Source code directory
BUILD_DIR = build        # Build output directory
DOC_DIR = doc            # Documentation directory
SCHEME_DIR = scheme      # Scheme-specific code directory
EXAMPLES_DIR = examples  # Examples directory

# Tool Configuration
EMACS = emacs            # Emacs executable
EMACS_BATCH = $(EMACS) --batch --quick  # Batch mode Emacs command

# Help Target - Dynamically generates help text from target comments
.PHONY: help
help: ## Display this help message with all available targets and their descriptions
	@echo "Available targets:"
	@echo ""
	@awk -F':.*##' '/^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Usage: make [target]"
	@echo "Example: make build - Builds the entire project"

# Default goal - runs help if no target is specified
.DEFAULT_GOAL := help

# High-Level Project Targets
.PHONY: all
all: build docs ## Build entire project (compilation + documentation)

# Build Workflow Targets
.PHONY: build
build: tangle compile ## Complete build process: tangle code + compile

# Tangling Targets (converting literate programming files to source code)
.PHONY: tangle
tangle: tangle-research ## Tangle all project files (currently research.org)

# Research Org Tangling with enhanced logging and error handling
research.org.tangle: research.org ## Tangle research.org into source code
	@echo "Tangling research.org..."
	@$(EMACS_BATCH) --eval "(require 'org)" \
		--eval "(setq org-confirm-babel-evaluate nil)" \
		--eval "(setq org-babel-tangle-use-relative-file-links nil)" \
		--eval "(find-file \"$<\")" \
		--eval "(condition-case err (org-babel-tangle) (error (princ (format \"Tangling failed: %s\n\" err))))" \
		--kill
	@touch $@
	@echo "Tangling of research.org completed successfully."

tangle-research: research.org.tangle ## Alias for research.org tangling

# Documentation Generation
.PHONY: docs
docs: research.pdf ## Generate all documentation (currently research PDF)

# LaTeX and PDF Generation
research.tex: research.org ## Convert research.org to LaTeX
	@echo "Generating LaTeX from research.org..."
	@$(EMACS_BATCH) --eval "(require 'org)" \
		--eval "(setq org-confirm-babel-evaluate nil)" \
		--eval "(find-file \"$<\")" \
		--eval "(org-latex-export-to-latex)" \
		--kill

research.pdf: research.tex ## Generate final PDF from LaTeX
	@echo "Compiling PDF (first pass)..."
	@pdflatex $<
	@echo "Generating bibliography..."
	@bibtex $(basename $<)
	@echo "Compiling PDF (second pass)..."
	@pdflatex $<
	@pdflatex $<
	@echo "PDF generation complete."

# Publication Targets
.PHONY: publish
publish: publish-research ## Publish all documentation (currently research)

publish-research: research.org ## Publish research.org as HTML
	@echo "Publishing research.org to HTML..."
	@$(EMACS_BATCH) --eval "(require 'org)" \
		--eval "(setq org-confirm-babel-evaluate nil)" \
		--eval "(find-file \"$<\")" \
		--eval "(org-html-export-to-html)" \
		--kill
	@echo "Research published as HTML successfully."

# Convenience Viewing Target
.PHONY: view-research
view-research: research.pdf ## Open research PDF in default viewer
	@echo "Opening research PDF..."
	@xpdf $< || evince $< || open $< || echo "Could not find a PDF viewer"

# Compilation Target
.PHONY: compile
compile: ## Compile source files (placeholder for project-specific compilation)
	@echo "Compiling source files..."
	@mkdir -p $(BUILD_DIR)
	# Add your specific compilation commands here
	# Example: gcc, g++, javac, etc.
	@echo "Compilation complete."

# Templates Target (optional)
templates/els-2025.tex: ## Download ELS 2025 LaTeX template
	@echo "Downloading ELS 2025 LaTeX template..."
	@mkdir -p $(dir $@)
	@wget -O $@ https://european-lisp-symposium.org/static/submission/template.tex
	@echo "Template downloaded successfully."

# Data
data:
	mkdir -p $@

data/pg2650.txt: data ## Du côté de chez Swann
	wget -O $@  https://www.gutenberg.org/cache/epub/2650/pg2650.txt

# Cleanup Targets
.PHONY: clean
clean: ## Remove generated files from the current build
	@echo "Cleaning generated files..."
	@rm -f research.tex research.pdf research.aux research.log
	@rm -f research.bbl research.blg research.out
	@rm -f research.org.tangle
	@rm -f research.html
	@echo "Clean completed."

.PHONY: clean-all
clean-all: clean ## Perform a deep clean, removing all build artifacts
	@echo "Performing deep clean..."
	@rm -rf $(BUILD_DIR)/*
	@echo "Deep clean completed."

# Additional targets can be added here as needed
