PREFIX ?= $(HOME)/.local/share/noctalia/plugins
PLUGIN_NAME = kp-noctalia
DEST = $(PREFIX)/$(PLUGIN_NAME)

.PHONY: install dev uninstall

install:
	@echo "Instalando $(PLUGIN_NAME) en $(DEST)..."
	@mkdir -p $(DEST)
	@cp manifest.toml finder.luau $(DEST)/
	@echo "Instalado correctamente en $(DEST)."

dev:
	@echo "Enlazando para desarrollo..."
	@mkdir -p $(PREFIX)
	@rm -rf $(DEST)
	@ln -s $(CURDIR) $(DEST)
	@echo "Symlink creado: $(DEST) -> $(CURDIR)"

uninstall:
	@echo "Desinstalando $(PLUGIN_NAME)..."
	@rm -rf $(DEST)
