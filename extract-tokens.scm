#!/usr/bin/env guile
!#
(use-modules (ice-9 rdelim)
             (ice-9 pretty-print)
             (srfi srfi-1))

;; Debug flag - set to #t for verbose output
(define debug-mode #f)

;; Debug function
(define (debug-msg msg val)
  (when debug-mode
    (display "DEBUG: ")
    (display msg)
    (display ": ")
    (pretty-print val)
    (newline))
  val)

;; Read an S-expression from a file
(define (read-sexp-from-file filename)
  (when debug-mode
    (display "Reading file: ")
    (display filename)
    (newline))
  
  (let ((result
         (with-input-from-file filename
           (lambda ()
             (read)))))
    (when debug-mode
      (display "Read complete. First element type: ")
      (display (if (pair? result) 
                  (symbol->string (car result))
                  (if (null? result) "empty list" "unknown")))
      (newline))
    result))

;; Check if a symbol is a property key (starts with :)
(define (property-key? sym)
  (and (symbol? sym)
       (let ((sym-name (symbol->string sym)))
         (and (> (string-length sym-name) 0)
              (char=? (string-ref sym-name 0) #\:)))))

;; Extract only token values (ignoring properties and metadata)
(define (extract-token-values sexp)
  (cond
    ;; If it's a string, it's a token value - return as a list
    ((string? sexp) 
     (debug-msg "Found token" sexp)
     (list sexp))
    
    ;; If it's not a list, ignore it
    ((not (pair? sexp)) '())
    
    ;; If it's an empty list, return empty list
    ((null? sexp) '())
    
    ;; If the list starts with a category symbol (S, NP, VP, etc.)
    ((symbol? (car sexp))
     (if (property-key? (car sexp))
         ;; If it's a property key, skip it and its value
         (if (>= (length sexp) 3)
             (extract-token-values (cddr sexp))
             '())
         ;; Otherwise it's a category node
         (begin
           (debug-msg "Processing category" (car sexp))
           ;; Process all children, skipping property declarations
           (let loop ((items (cdr sexp))
                      (result '()))
             (if (null? items)
                 result
                 (if (property-key? (car items))
                     ;; Skip property and its value
                     (loop (if (>= (length items) 3) (cddr items) '()) result)
                     ;; Process this item
                     (loop (cdr items) 
                           (append result (extract-token-values (car items))))))))))
    
    ;; Otherwise, process all elements in the list
    (else
     (debug-msg "Processing list" (if (< (length sexp) 3) sexp "..."))
     (append-map extract-token-values sexp))))

;; Main function to process a file
(define (extract-tokens-from-file filename)
  (let ((sexp (read-sexp-from-file filename)))
    (let ((tokens (extract-token-values sexp)))
      (debug-msg "Extracted tokens count" (length tokens))
      tokens)))

;; Example usage
(define (main args)
  (if (= (length args) 2)
      (set! debug-mode (string=? (cadr args) "--debug")))
  
  (if (< (length args) 2)
      (begin
        (display "Usage: guile extract-tokens.scm <filename> [--debug]\n")
        (exit 1))
      (let ((filename (cadr args)))
        (when debug-mode
          (display "Processing file: ")
          (display filename)
          (newline))
        
        (let ((tokens (extract-tokens-from-file filename)))
          (display (string-join tokens " "))
          (newline)))))

(main (command-line))
