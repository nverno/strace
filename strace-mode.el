;;; strace-mode.el --- Major mode for strace -*- lexical-binding: t; -*-

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/strace
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; Created:  7 October 2023
;; Keywords: tools strace

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Major modes for strace output.
;;
;; The tree-sitter mode, `strace-ts-mode', requires the grammar from
;; https://github.com/sigmaSd/tree-sitter-strace.
;;
;;     (add-to-list 'treesit-language-source-alist
;;                  '(strace "https://github.com/sigmaSd/tree-sitter-strace"))
;;     (treesit-install-language-grammar 'strace)
;; 
;;; Code:

(declare-function treesit-parser-create "treesit.c")

(defface strace-error-description-face
  '((t (:inherit font-lock-warning-face :weight light)))
  "Face for strace error descriptions."
  :group 'strace)

(defvar strace-mode-font-lock-keywords
  `(("\\(\\_<[A-DF-Z_][A-Z_]+\\_>\\)" . (1 font-lock-variable-name-face)) ; macros
    ("^\\([a-zA-Z0-9_]+\\)\("         . (1 font-lock-function-name-face)) ; functions
    ("^\\([0-9]+\\) "                 . (1 font-lock-warning-face))
    ;; ("^[0-9]+ \\([a-zA-Z0-9_]*\\)(" . (1 font-lock-constant-face))
    (" = \\(0x[[:xdigit:]]+\\).*$"    . (1 font-lock-type-face))
    (" = \\(-?[[:digit:]?]+\\).*$"    . (1 font-lock-type-face))
    ;; (" = 0x[[:xdigit:]]+ \\([[:upper:]]+\\).*$" . (1 font-lock-negation-char-face))
    ;; (" = -?[[:digit:]?]+ \\([[:upper:]]+\\).*$" . (1 font-lock-negation-char-face))
    ("E[A-Z_]+"                       . font-lock-warning-face)
    (" \\((.*)\\)$"                   . (1 strace-error-description-face)))
  "Font-locking for `strace-mode'.")

;;; Syntax

(defvar strace-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?| "." st)
    (modify-syntax-entry ?= "." st)
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\\ "\\" st)
    (modify-syntax-entry ?\* ". 23" st) ; c-style comments
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?\n "> b" st)
    st)
  "Syntax table for strace.")

;;; Commands

;; FIXME: too aggressive
(defun strace-align-equals (beg end)
  "Align equals from BEG to END or entire buffer if region isn't active."
  (interactive
   (if (region-active-p) (list (region-beginning) (region-end))
     (list (point-min) (point-max))))
  (let ((re "\\(\\s-+\\)=\\(\\s-+\\)")
        buffer-read-only)
    (align-regexp beg end re)))

(defun strace-help-at-point ()
  "Show man page for command on current line."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (and (looking-at "[0-9]*\\s-*\\([a-z_]+\\)\(")
         (man (concat "2 " (match-string 1))))))

;;; Keymap

(defvar strace-mode-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "M-?")   'strace-help-at-point)
    (define-key km (kbd "C-c =") 'strace-align-equals)
    km)
  "Keymap for `strace-mode'.")

;;;###autoload
(define-derived-mode strace-mode text-mode "Strace"
  "Major mode for viewing strace output.

\\<strace-mode-map>"
  :group 'strace
  :abbrev-table nil
  (setq-local font-lock-defaults '(strace-mode-font-lock-keywords))
  (view-mode-enter))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.strace\\'" . strace-mode))

;; -------------------------------------------------------------------
;;; Tree-sitter

(require 'treesit nil t)

(defvar strace-ts-mode--keywords
  '("killed" "by" "exited" "with" "<unfinished ...>" "<..." "resumed>")
  "Keywords for tree-sitter to font-lock in `strace-ts-mode'.")

(defvar strace-ts-mode--feature-list
  '(( comment)
    ( string error keyword)
    ( function variable property literal)
    ( operator delimiter bracket))
  "See `treesit-font-lock-feature-list'.")

(defvar strace-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'strace
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'strace
   :feature 'keyword
   `([,@strace-ts-mode--keywords] @font-lock-keyword-face)

   :language 'strace
   :feature 'error
   '((errorName) @font-lock-warning-face
     (errorDescription) @strace-error-description-face)

   :language 'strace
   :feature 'string
   '((string) @font-lock-string-face)

   :language 'strace
   :feature 'function
   '((syscall) @font-lock-function-call-face)

   :language 'strace
   :feature 'property
   '((dictElem (dictKey) @font-lock-property-name-face))

   :language 'strace
   :feature 'literal
   '((integer) @font-lock-number-face
     ["NULL" (pointer)] @font-lock-constant-face)

   :language 'strace
   :feature 'variable
   '((value) @font-lock-variable-name-face)
   
   :language 'strace
   :feature 'operator
   '(["=" "|" "*" "&&" "=="] @font-lock-operator-face
     ["+++" "---" "~" "..." "?"] @font-lock-misc-punctuation-face)

   :language 'strace
   :feature 'delimiter
   '(["," "=>"] @font-lock-delimiter-face)

   :language 'strace
   :feature 'bracket
   '(["(" ")" "[" "]" "{" "}"] @font-lock-bracket-face))
  "Tree-sitter font-lock rules for `strace-ts-mode'.")

(defvar strace-ts-mode--sexp-nodes nil
  "See `treesit-sexp-type-regexp' for more information.")

(defvar strace-ts-mode--sentence-nodes "line"
  "See `treesit-sentence-type-regexp' for more information.")

(defvar strace-ts-mode--text-nodes (rx (or "errorDescription"
                                           "comment"
                                           "string"
                                           "exit"))
  "See `treesit-text-type-regexp' for more information.")

(defvar-keymap strace-ts-mode-map
  :doc "Keymap for `strace-ts-mode'."
  :parent strace-mode-map)

;;;###autoload
(define-derived-mode strace-ts-mode text-mode "Strace"
  "Major mode for strace output.

\\<strace-mode-ts-map>"
  :group 'strace
  :syntax-table strace-mode-syntax-table
  :abbrev-table nil
  (when (treesit-ready-p 'strace)
    (treesit-parser-create 'strace)

    ;; Font-lock
    (setq-local treesit-font-lock-settings strace-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list strace-ts-mode--feature-list)
    
    ;; Navigation
    (setq-local treesit-thing-settings
                `((strace
                   (sexp ,strace-ts-mode--sexp-nodes)
                   (sentence ,strace-ts-mode--sentence-nodes)
                   (text ,strace-ts-mode--text-nodes))))
    
    (treesit-major-mode-setup)))

(if (treesit-ready-p 'strace)
    (add-to-list 'auto-mode-alist '("\\.strace\\'" . strace-ts-mode)))

(provide 'strace-mode)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; strace-mode.el ends here
