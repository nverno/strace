;;; strace.el --- Major mode/interaction w/ strace output -*- lexical-binding: t; -*-

;; This is free and unencumbered software released into the public domain.

;; Last modified: <2019-03-14 20:04:25>
;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/strace
;; Package-Requires: ((transient "0.1"))
;; Created: 12 October 2017

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

;; Major mode to interact with strace output.
;; TODO:
;; - use transient popup to define and rerun strace
;; - https://github.com/magit/transient

;;; Code:
(require 'transient)

(defgroup strace nil
  "Major mode to examine strace output."
  :group 'strace
  :prefix "strace-")

(defun strace-print-stuff (&rest args)
  (interactive)
  (message "%S" args))

;; (define-transient-command strace-popup
;;   "Arguments to compile and pass to strace to revert buffer."
;;   :group 'strace
;;   :actions (("g" "Recompile and revert" strace-print-stuff)))

;; -------------------------------------------------------------------
;;; Commands

;; FIXME: too aggressive
;; align equals in region or whole buffer
(defun strace-align-equals (&optional beg end)
  (interactive "r")
  (let ((re "\\(\\s-+\\)=\\(\\s-+\\)")
        buffer-read-only)
    (if (region-active-p)
        (align-regexp beg end re)
      (align-regexp (point-min) (point-max) re))))

;; show man page for command on current line
(defun strace-help-at-point ()
  (interactive)
  (save-excursion
    (beginning-of-line)
    (and (looking-at "[0-9]+\\s-*\\([a-z_]+\\)\(")
         (man (concat "2 " (match-string 1))))))

;; (defun strace-revert-buffer (compile-cmd)
;;   (interactive
;;    (list (let ((command (eval compile-command)))
;;            (if current-prefix-arg (compilation-read-command command)
;;              command)))))

;; -------------------------------------------------------------------
;;; Major Mode

(defvar strace-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?| "." st)
    (modify-syntax-entry ?= "." st)
    (modify-syntax-entry ?\" "\"" st)
    (modify-syntax-entry ?\\ "\\" st)
    (modify-syntax-entry ?\* ". 23" st) ;c-style comments 
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?\n "> b" st)
    st))

(defvar strace-mode-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "M-?")   'strace-help-at-point)
    (define-key km (kbd "C-c =") 'strace-align-equals)
    km))

(defvar strace-font-lock-keywords
  `(("\\(\\_<[A-DF-Z_][A-Z_]+\\_>\\)" . (1 font-lock-variable-name-face)) ;macros
    ("^\\([a-zA-Z0-9_]+\\)\("         . (1 font-lock-function-name-face)) ;functions
    ("^\\([0-9]+\\) "                 . (1 font-lock-warning-face))
    ;; ("^[0-9]+ \\([a-zA-Z0-9_]*\\)(" . (1 font-lock-constant-face))
    (" = \\(0x[[:xdigit:]]+\\).*$"    . (1 font-lock-type-face))
    (" = \\(-?[[:digit:]?]+\\).*$"    . (1 font-lock-type-face))
    ;; (" = 0x[[:xdigit:]]+ \\([[:upper:]]+\\).*$" . (1 font-lock-negation-char-face))
    ;; (" = -?[[:digit:]?]+ \\([[:upper:]]+\\).*$" . (1 font-lock-negation-char-face))
    ("E[A-Z_]+"                       . font-lock-warning-face)
    (" \\((.*)\\)$"                   . (1 font-lock-comment-face))))

;;;###autoload
(define-derived-mode strace text-mode "Strace"
  "Major mode for viewing strace output."
  :abbrev-table nil
  (setq-local font-lock-defaults '(strace-font-lock-keywords))
  (view-mode-enter))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.strace\\'" . strace))

(provide 'strace)
;;; strace.el ends here
