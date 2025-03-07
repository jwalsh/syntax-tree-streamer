# Working with Claude: Build Commands and Code Style

## Build Commands
- **Build entire project**: `make all` (tangling + compilation + docs)
- **Tangle code from org**: `make tangle` 
- **Generate documentation**: `make docs` (produces PDF)
- **View documentation**: `make view-research`
- **Publish HTML**: `make publish-research`
- **Clean build artifacts**: `make clean` or `make clean-all`
- **Download data**: `make data/pg2650.txt`

## Git Workflow
- **IMPORTANT**: Always use `--no-gpg-sign` with git commands to prevent freezes
- **Incremental commits**: Add files with specific scoped changes
- **Commit style**: Use Conventional Commits format:
  - `feat: add new feature`
  - `fix: resolve specific issue`
  - `docs: update documentation`
  - `refactor: improve code structure`
  - `test: add or update tests`
- **Example**: `git add --no-gpg-sign specific-file.ext && git commit --no-gpg-sign -m "feat: add parser for S-expressions"`
- **Repositories**: Always create new repos and gists as private by default
- **GitHub commands**: `gh repo create --private` or `gh gist create --private`

## Collaboration & Project Management
- **RFC reviews**: Add @aygp-dr (LLM Agent reviewer)
- **Architecture reviews**: Add @seanjensengrey
- **Standard dev feedback**: Use @defrecord/developers
- **PR creation**: Always add appropriate reviewers when creating pull requests
- **Issue tracking**: Use GitHub issues for all open tasks
- **Project registration**: Add projects to @defrecord/tools by default

## Diagrams & Documentation
- **Diagram format**: Prefer Mermaid for all diagrams
- **Priority diagrams**:
  - System architecture diagrams
  - Data flow diagrams
  - User control flow diagrams
  - User/data sequence diagrams
- **Use sparingly**: Gantt charts and mindmaps
- **Example**:
  ```mermaid
  sequenceDiagram
    User->>Parser: Input S-expression
    Parser->>SyntaxTree: Create nodes
    SyntaxTree->>Analyzer: Process tree
    Analyzer->>User: Return analysis
  ```

## Code Style Guidelines

### S-expression Syntax
- Use proper indentation (2 spaces) for nested S-expressions
- Include node categories in uppercase (NP, VP, S, etc.)
- Always add metadata with the `:metadata` keyword
- Use key-value pairs for metadata attributes

### Org-mode Usage
- Tangle code using `:mkdirp t` to auto-create directories
- Each language gets its own tangle path (see header-args in research.org)
- Follow BNF grammar specified in research.org for tree nodes
- Use `:noexport:` tag for sections with examples/tests

### Programming Languages
- **Scheme**: Use Guile pattern matching for tree operations
- **C/C++**: Follow structures defined in research.org
- **Parser**: Use Bison/Flex consistent with examples
- **Web**: D3.js for visualization components

## Development Environment Preferences
- **Editor**: Emacs is my preferred editor for all development work
- **Literate Programming**: I use org-mode extensively with Babel
- **FreeBSD**: I primarily work in a FreeBSD environment (nexushive)
- **Installation**: I prefer using ports over pkg for software installation

## Documentation Preferences
- **Format**: org-mode with proper heading structure
- **Citations**: BibTeX with org-ref (references.bib file)
- **PDF Generation**: Documentation should be exportable to PDF

---

*This file guides Claude's understanding of this codebase's style and build processes.*