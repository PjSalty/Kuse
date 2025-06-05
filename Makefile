PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
SHAREDIR := $(PREFIX)/share/kuse
COMPDIR_BASH := /etc/bash_completion.d
COMPDIR_ZSH := /usr/share/zsh/site-functions
COMPDIR_FISH := /etc/fish/completions

all:
	@echo "Use 'make install' to install, or 'make uninstall'."

install:
	@echo "Installing to $(PREFIX) ..."
	mkdir -p "$(SHAREDIR)" "$(BINDIR)"
	cp -r scripts/* "$(SHAREDIR)/"
	chmod 0755 "$(SHAREDIR)"/*.sh

	# Create wrapper
	install -m 0755 -d "$(BINDIR)"
	printf '#!/usr/bin/env bash\nexport KCS_CONFIG_FILE="$$HOME/.kcs.env"\nKCS_SHAREDIR="$(dirname "$(readlink -f "$$0")")/../share/kuse"\nsource "$$KCS_SHAREDIR/kubeconfig-switcher.sh"\nkuse "$$@"\n' \
		> "$(BINDIR)/kuse"
	chmod +x "$(BINDIR)/kuse"

	# Bash completion
	if [ -d "$(COMPDIR_BASH)" ]; then \
	  install -m 0644 "$(SHAREDIR)/completion-kuse.sh" "$(COMPDIR_BASH)/kuse"; \
	else \
	  echo "Warning: $(COMPDIR_BASH) not found. Skipping Bash completion."; \
	fi

	# Zsh completion
	if [ -d "$(COMPDIR_ZSH)" ]; then \
	  install -m 0644 "$(SHAREDIR)/completion-kuse.zsh" "$(COMPDIR_ZSH)/_kuse"; \
	else \
	  echo "Warning: $(COMPDIR_ZSH) not found. Skipping Zsh completion."; \
	fi

	# Fish completion
	if [ -d "$(COMPDIR_FISH)" ]; then \
	  install -m 0644 "$(SHAREDIR)/completion-kuse.fish" "$(COMPDIR_FISH)/kuse.fish"; \
	else \
	  echo "Warning: $(COMPDIR_FISH) not found. Skipping Fish completion."; \
	fi

	@echo "Done."

uninstall:
	rm -f "$(BINDIR)/kuse"
	rm -f "$(COMPDIR_BASH)/kuse"
	rm -f "$(COMPDIR_ZSH)/_kuse"
	rm -f "$(COMPDIR_FISH)/kuse.fish"
	rm -rf "$(SHAREDIR)"
	@echo "Uninstalled."

.PHONY: all install uninstall
