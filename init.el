;;; init.el --- Project-specific Emacs configuration for syntax tree parser project

;;; Commentary:
;; This file configures Emacs for working with the syntax tree parser project.
;; It sets up org-mode, babel, bibtex, and other necessary packages.
;;
;; Usage:
;; - From command line: emacs -q -l init.el
;; - From within Emacs: M-x load-file RET /path/to/init.el RET
;;
;; It's recommended to use this with STRAIGHT or quelpa package managers
;; for reproducible package installation.

;;; Code:

;; Set up package management
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)
(package-initialize)

;; Install use-package if not already present
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)  ; Auto-install packages

;; Configure project path
(defvar syntax-tree-project-path
  (or (getenv "PROJECT_DIR")
      (file-name-directory (or load-file-name buffer-file-name))))

(message "Using project path: %s" syntax-tree-project-path)

;; Utility function for path composition
(defun project-path (path)
  "Return absolute path by combining PROJECT_PATH with PATH."
  (expand-file-name path syntax-tree-project-path))

;; Basic editor settings
(use-package emacs
  :ensure nil  ; Built-in package
  :config
  (set-language-environment "UTF-8")
  (setq-default indent-tabs-mode nil)
  (setq-default tab-width 2)
  (global-auto-revert-mode 1)
  (column-number-mode 1)
  (show-paren-mode 1)
  
  ;; Create necessary directories
  (unless (file-exists-p (project-path "doc"))
    (make-directory (project-path "doc") t))
  (unless (file-exists-p (project-path "scheme"))
    (make-directory (project-path "scheme") t))
  (unless (file-exists-p (project-path "build"))
    (make-directory (project-path "build") t)))

;; Load org-mode and extensions
(use-package org
  :mode ("\\.org\\'" . org-mode)
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda)
         ("C-c c" . org-capture))
  :custom
  (org-directory (project-path "doc"))
  (org-default-notes-file (project-path "doc/notes.org"))
  (org-startup-indented t)
  (org-startup-folded 'content)
  (org-startup-with-inline-images t)
  (org-hide-emphasis-markers t)
  (org-pretty-entities t)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-confirm-babel-evaluate nil)
  (org-export-with-toc t)
  (org-export-with-author t)
  (org-export-with-smart-quotes t)
  
  :config
  ;; Set up org-babel languages
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (scheme . t)
     (C . t)
     (python . t)
     (js . t)
     (shell . t)
     (lisp . t)
     (dot . t)
     (latex . t)))
  
  ;; Custom tangling directory
  (setq org-babel-tangle-use-relative-file-links nil)
  (setq org-babel-tangle-dir (project-path "build"))
  
  ;; Set up org-babel C and scheme headers
  (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
  (add-to-list 'org-structure-template-alist '("c" . "src c"))
  (add-to-list 'org-structure-template-alist '("js" . "src js"))
  (add-to-list 'org-structure-template-alist '("bnf" . "src bnf"))
  (add-to-list 'org-structure-template-alist '("bison" . "src bison"))
  (add-to-list 'org-structure-template-alist '("flex" . "src flex"))
  
  ;; Configure babel headers for scheme
  (setq org-babel-default-header-args:scheme
        '((:results . "output replace")
          (:exports . "both")
          (:tangle . "yes"))))

;; Babel extensions
(use-package ob-C
  :ensure nil) ; Built-in

(use-package ob-shell
  :ensure nil) ; Built-in

(use-package ob-js
  :ensure nil) ; Built-in

;; BibTeX integration
(use-package bibtex
  :mode ("\\.bib\\'" . bibtex-mode)
  :custom
  (bibtex-dialect 'biblatex)
  (bibtex-autokey-year-length 4)
  (bibtex-autokey-name-year-separator "-")
  (bibtex-autokey-year-title-separator "-")
  (bibtex-autokey-titleword-separator "-")
  (bibtex-autokey-titlewords 3)
  (bibtex-autokey-titlewords-stretch 1)
  (bibtex-autokey-titleword-length 10))

(use-package biblio
  :commands (biblio-lookup)
  :config
  (setq biblio-bibtex-use-autokey t))

(use-package org-ref
  :after org
  :custom
  (org-ref-bibliography-notes (project-path "doc/notes.org"))
  (org-ref-default-bibliography `(,(project-path "references.bib")))
  (org-ref-pdf-directory (project-path "doc/pdf"))
  :config
  (unless (file-exists-p org-ref-pdf-directory)
    (make-directory org-ref-pdf-directory t)))

;; LaTeX export support
(use-package ox-latex
  :ensure nil ; Built-in with org
  :after org
  :custom
  (org-latex-pdf-process
   '("pdflatex -interaction nonstopmode -output-directory %o %f"
     "bibtex %b"
     "pdflatex -interaction nonstopmode -output-directory %o %f"
     "pdflatex -interaction nonstopmode -output-directory %o %f"))
  (org-latex-listings 'minted)
  (org-latex-minted-options
   '(("frame" "lines") ("linenos" "") ("breaklines" "true") ("fontsize" "\\footnotesize")))
  :config
  (add-to-list 'org-latex-packages-alist '("" "minted"))
  (add-to-list 'org-latex-packages-alist '("" "listings"))
  (add-to-list 'org-latex-packages-alist '("" "color"))
  
  ;; Create custom export template with bibtex support
  (add-to-list 'org-latex-classes
               '("syntax-article"
                 "\\documentclass[11pt,a4paper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage{graphicx}
\\usepackage{longtable}
\\usepackage{hyperref}
\\usepackage{natbib}
\\usepackage{minted}
\\bibliographystyle{plainnat}
[NO-DEFAULT-PACKAGES]
[PACKAGES]
[EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))

;; HTML export with syntax highlighting
(use-package ox-html
  :ensure nil ; Built-in with org
  :after org
  :custom
  (org-html-doctype "html5")
  (org-html-html5-fancy t)
  (org-html-validation-link nil)
  (org-html-head-include-scripts t)
  (org-html-head-include-default-style t)
  
  :config
  ;; Use syntax highlighting
  (setq org-html-htmlize-output-type 'css))

;; Syntax highlighting for HTML export
(use-package htmlize
  :after org)

;; Language-specific modes
(use-package scheme-mode
  :ensure nil  ; Built-in
  :mode ("\\.scm\\'" "\\.ss\\'")
  :hook (scheme-mode . (lambda ()
                         (setq-local indent-tabs-mode nil)
                         (setq-local tab-width 2)))
  :config
  (setq scheme-program-name "guile"))

(use-package geiser
  :after scheme-mode
  :custom
  (geiser-active-implementations '(guile))
  (geiser-default-implementation 'guile)
  (geiser-guile-binary "guile")
  (geiser-repl-use-other-window t))

(use-package geiser-guile
  :after geiser)

(use-package cc-mode
  :ensure nil  ; Built-in
  :mode (("\\.c\\'" . c-mode)
         ("\\.h\\'" . c-mode)
         ("\\.y\\'" . c-mode)  ; Bison files
         ("\\.l\\'" . c-mode))  ; Flex files
  :hook (c-mode . (lambda ()
                    (setq c-basic-offset 2)
                    (setq-local indent-tabs-mode nil))))

(use-package bison-mode
  :mode ("\\.y\\'" "\\.yy\\'" "\\.ypp\\'"))

(use-package flex-mode
  :mode ("\\.l\\'" "\\.ll\\'" "\\.lpp\\'"))

;; Markdown and documentation
(use-package markdown-mode
  :mode ("\\.md\\'" "\\.markdown\\'")
  :custom
  (markdown-command "pandoc"))

;; Completion and syntax checking
(use-package company
  :diminish
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 2))

(use-package flycheck
  :diminish
  :hook (after-init . global-flycheck-mode))

;; Project management
(use-package projectile
  :diminish
  :custom
  (projectile-project-search-path `(,syntax-tree-project-path))
  (projectile-completion-system 'ivy)
  :config
  (projectile-mode +1)
  :bind-keymap ("C-c p" . projectile-command-map))

;; Version control
(use-package magit
  :bind ("C-x g" . magit-status))

;; Tree visualization
(use-package treemacs
  :bind (("C-c t" . treemacs))
  :custom
  (treemacs-position 'left)
  (treemacs-width 40))

;; Utility functions
(defun tangle-org-file (file-path)
  "Tangle the org file at FILE-PATH."
  (interactive "fOrg file to tangle: ")
  (let ((org-babel-tangle-dir (project-path "build")))
    (org-babel-tangle-file file-path)))

(defun export-org-to-pdf (file-path)
  "Export the org file at FILE-PATH to PDF using LaTeX."
  (interactive "fOrg file to export: ")
  (with-current-buffer (find-file-noselect file-path)
    (org-latex-export-to-pdf)))

(defun export-org-to-html (file-path)
  "Export the org file at FILE-PATH to HTML."
  (interactive "fOrg file to export: ")
  (with-current-buffer (find-file-noselect file-path)
    (org-html-export-to-html)))

(defun create-references-bib ()
  "Create a references.bib file with the sample BibTeX entries if it doesn't exist."
  (interactive)
  (let ((refs-file (project-path "references.bib")))
    (when (not (file-exists-p refs-file))
      (with-temp-file refs-file
        (insert "@book{Boersma2024-BOEUFD,
  author    = {Boersma, Meinte},
  title     = {Building User-Friendly {DSLs}},
  publisher = {Manning Publications},
  year      = {2024},
  month     = {October},
  isbn      = {9781617296475},
  pages     = {504},
  note      = {Foreword by Federico Tomassetti},
  url       = {https://www.manning.com/books/building-user-friendly-dsls}
}

@book{Kockelmans1972-KOCOHA,
  address = {Evanston [Ill.]},
  editor = {Joseph J. Kockelmans},
  publisher = {Northwestern University Press},
  title = {On Heidegger and Language},
  year = {1972}
}

@book{Fowler2010-FOWDSL,
  author    = {Fowler, Martin},
  title     = {Domain-Specific Languages},
  publisher = {Addison-Wesley Professional},
  year      = {2010},
  isbn      = {9780321712943},
  series    = {Addison-Wesley Signature Series}
}

@book{Parr2010-PARLAA,
  author    = {Parr, Terence},
  title     = {Language Implementation Patterns: Create Your Own Domain-Specific and General Programming Languages},
  publisher = {Pragmatic Bookshelf},
  year      = {2010},
  isbn      = {9781934356456}
}

@book{Kleppe2008-KLESPL,
  author    = {Kleppe, Anneke},
  title     = {Software Language Engineering: Creating Domain-Specific Languages Using Metamodels},
  publisher = {Addison-Wesley},
  year      = {2008},
  isbn      = {9780321553454}
}

@book{Tomassetti2017-TOPWPI,
  author    = {Tomassetti, Federico},
  title     = {The Practical Guide to Language Design with Antlr and Java},
  publisher = {Leanpub},
  year      = {2017},
  url       = {https://leanpub.com/language-implementation-patterns-creating-your-own-domain-specific-and-general-programming-languages}
}

@article{Voelter2014-VOEPDS,
  author    = {Voelter, Markus and Benz, Sebastian and Dietrich, Christian and Engelmann, Birgit and Helander, Mats and Kats, Lennart C. L. and Visser, Eelco and Wachsmuth, Guido},
  title     = {DSL Engineering: Designing, Implementing and Using Domain-Specific Languages},
  journal   = {CreateSpace Independent Publishing Platform},
  year      = {2013},
  url       = {http://dslbook.org}
}

@inproceedings{Erdweg2011-ERDSEL,
  author    = {Erdweg, Sebastian and Rendel, Tillmann and K{\"a}stner, Christian and Ostermann, Klaus},
  title     = {{SugarJ}: Library-based Syntactic Language Extensibility},
  booktitle = {Proceedings of the 2011 ACM International Conference on Object Oriented Programming Systems Languages and Applications},
  series    = {OOPSLA '11},
  year      = {2011},
  pages     = {391--406},
  publisher = {ACM},
  address   = {New York, NY, USA}
}

@article{Renggli2010-RENTEL,
  author    = {Renggli, Lukas and Denker, Marcus and Nierstrasz, Oscar},
  title     = {Language Boxes: Bending the Host Language with Modular Language Changes},
  journal   = {Software Language Engineering},
  year      = {2010},
  pages     = {274--293},
  publisher = {Springer}
}

@inproceedings{Wachsmuth2008-WACMEM,
  author    = {Wachsmuth, Guido},
  title     = {Metamodel Adaptation and Model Co-adaptation},
  booktitle = {ECOOP 2007 -- Object-Oriented Programming},
  year      = {2007},
  pages     = {600--624},
  publisher = {Springer Berlin Heidelberg}
}

@article{Shriram2012-SHRROL,
  author    = {Krishnamurthi, Shriram},
  title     = {The Racket of Language-Oriented Programming},
  journal   = {Communications of the ACM},
  volume    = {55},
  number    = {1},
  year      = {2012},
  pages     = {38--44}
}

@book{Friedman2008-FRIELE,
  author    = {Friedman, Daniel P. and Wand, Mitchell},
  title     = {Essentials of Programming Languages},
  edition   = {3rd},
  publisher = {MIT Press},
  year      = {2008},
  isbn      = {9780262062794}
}")
      (message "Created references.bib file with sample entries."))))

;; Initialize project resources
(create-references-bib)

;; Custom key bindings for the project
(global-set-key (kbd "C-c C-t") 'tangle-org-file)
(global-set-key (kbd "C-c C-p") 'export-org-to-pdf)
(global-set-key (kbd "C-c C-h") 'export-org-to-html)

;; Load project-specific research.org if it exists
(let ((research-file (project-path "research.org")))
  (when (file-exists-p research-file)
    (find-file research-file)))

(provide 'init)
;;; init.el ends here
