SHELL  = /bin/bash
CASK   = cask
export EMACS ?= emacs
EFLAGS = 
TFLAGS = 

EL     =  $(filter-out %-autoloads.el, $(wildcard *.el))
ELC    =  ${EL:.el=.elc}
PKG    =  strace
PKGDIR =  $(shell EMACS=$(EMACS) $(CASK) package-directory)
TSDIR  ?= $(CURDIR)/tree-sitter-strace


all: 
	@

tree-sitter: $(TSDIR)
$(TSDIR):
	@git clone --depth=1 https://github.com/sigmaSd/tree-sitter-strace
	@printf "\e[1m\e[31mNote\e[22m\e[0m npm build can take a while\n" >&2
	cd $(TSDIR) &&                                         \
		npm --loglevel=info --progress=true install && \
		npm run generate
.PHONY: parse-%
parse-%:
	cd $(TSDIR) && npx tree-sitter parse $(TESTDIR)/$(subst parse-,,$@)

.PHONY: deps compile clean test
deps:
	$(CASK) install
	$(CASK) update
	touch $@

compile: deps
	$(CASK) build

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

distclean: clean
	$(RM) -rf $$(git ls-files --others --ignored --exclude-standard)
