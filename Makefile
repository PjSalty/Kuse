PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin
SHAREDIR := $(PREFIX)/share/kuse
COMPDIR := /etc/bash_completion.d

all:
	@echo "Use 'make install' to install, or 'make uninstall'."

install:
	@echo "Installing to $(PREFIX) ..."
	mkdir -p "$(SHAREDIR)" "$(BINDIR)"
	cp -r scripts/* "$(SHAREDIR)/"
	chmod 0755 "$(SHAREDIR)"/*.sh

	# Create wrapper in $(BINDIR)
	install -m 0755 -d "$(BINDIR)"
	printf '#!/usr/bin/env bash\nexport KCS_CONFIG_FILE="$$HOME/.kcs.env"\nKCS_SHAREDIR="$(dirname "$(readlink -f "$$0")")/../share/kuse"\nsource "$$KCS_SHAREDIR/kubeconfig-switcher.sh"\nkuse "$$@"\n' \
		> "$(BINDIR)/kuse"
	chmod +x "$(BINDIR)/kuse"

	# Install completion if possible
	if [ -d "$(COMPDIR)" ]; then \
	  install -m 0644 "$(SHAREDIR)/completion-kuse.sh" "$(COMPDIR)/kuse"; \
	else \
	  echo "Warning: $(COMPDIR) not found. Skipping completion."; \
	fi

	@echo "Done."

uninstall:
	rm -f "$(BINDIR)/kuse"
	rm -f "$(COMPDIR)/kuse"
	rm -rf "$(SHAREDIR)"
	@echo "Uninstalled."

.PHONY: all install uninstall
