#!/usr/bin/env racket
#lang racket

(require threading)
(require json)

(define pkg-name 
  (~>
    (current-command-line-arguments)
    (vector-ref 0)
  )
)

(define nixpkgs-location 
  (~>
    (current-command-line-arguments)
    (vector-ref 1)
  )
)

(define (log-and-return value)
  (λ (ignore return) (return))
    (displayln value) value
)

(define (run-string command)
  (with-output-to-string (λ () (system command)))
)

(define (run . command-list)
  (~>>
    (add-between command-list " ")
    (foldr string-append "")
    (run-string)
  )
)

(define (find-pkg-location)
  (~>
    (run "find" nixpkgs-location "-name" pkg-name)
    (string-split "\n")
    (filter-not (λ (s) (string-contains? s "test")) _)
    (first)
  )
)

(define (determine-pkg-hashes pkg-location)
  (~>
    (run "git -C" nixpkgs-location "log --pretty=format:%H" pkg-location)
    (string-split "\n")
    (log-and-return)
  )
)

(define (pkg-hash-to-version hash)
  (~>
    (run "git -C" nixpkgs-location "checkout -q" hash)
    (run "nix-instantiate --eval -E"
	 (string-append "'with import " nixpkgs-location "/default.nix { }; " pkg-name ".version'")
	 "| tr -d '\"'"
	 "| tr -d '\\n'"
    )
    ;; nix "eval" "--raw" "--read-only" (string-append nixpkgs-location "#" pkg-name ".version")
    (string->symbol)
  )
)

(define (pkg-hashes-with-version pkg-hashes)
  (~>>
    pkg-hashes
    (map (λ (hash) (~> hash (pkg-hash-to-version) (cons hash) (log-and-return))))
    (filter (λ (pair) (~> (car pair) (eq? '||) (not))))
    (make-immutable-hash)
  )
)

(define (write-result-hashtable hashtable path)
  (call-with-output-file #:exists 'replace
    path
    (λ (out) (write-json hashtable out))
  )
)

(~>
  (find-pkg-location)
  (determine-pkg-hashes)
  (pkg-hashes-with-version)
  (write-result-hashtable "out.rkt")
)
