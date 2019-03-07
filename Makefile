CASK   = cask
export EMACS ?= emacs
EFLAGS = 
TFLAGS = 

EL     = $(filter-out %-autoloads.el, $(wildcard *.el))
ELC    = ${EL:.el=.elc}
PKG    = strace
PKGDIR = $(shell EMACS=$(EMACS) $(CASK) package-directory)

.PHONY: deps compile clean test
all: # ${ELC} ${PKG}-autoloads.el README.md
	@echo ${PKGDIR}

deps:
	$(CASK) install
	$(CASK) update
	touch $@

compile: deps
	$(CASK) build

clean:
	$(RM) ${ELC} *~

test: ${PKGDIR}
	${CASK} exec 

README.md : el2markdown.el ${PKG}.el
	$(EMACS) -batch -l $< ${PKG}.el -f el2markdown-write-readme

.INTERMEDIATE: el2markdown.el
el2markdown.el:
	wget \
  -q -O $@ "https://github.com/Lindydancer/el2markdown/raw/master/el2markdown.el"

define LOADDEFS_TMPL
;;; ${PKG}-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$$) (car load-path))))


;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; ${PKG}-autoloads.el ends here
endef
export LOADDEFS_TMPL
#'

${PKG}-autoloads.el: ${EL}
	@echo "Generating $@"
	@printf "%s" "$$LOADDEFS_TMPL" > $@
	@${EMACS} -Q --batch --eval "(progn                        \
	(setq make-backup-files nil)                               \
	(setq vc-handled-backends nil)                             \
	(setq default-directory (file-truename default-directory)) \
	(setq generated-autoload-file (expand-file-name \"$@\"))   \
	(setq find-file-visit-truename t)                          \
	(update-directory-autoloads default-directory))"

.PHONY: clean
clean:
	$(RM) *~ *.elc ${PKG}-autoloads.el
