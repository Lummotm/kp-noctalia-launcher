PREFIX     ?= $(HOME)/.local/share/noctalia/plugins
PLUGIN_ID   = Lummotm/keepass
DEST        = $(PREFIX)/kp-launcher
DAEMON_REPO ?= https://github.com/Lummotm/kp-daemon.git

.PHONY: all get-daemon install dev uninstall clean

all: install

# Clona el código de kp-daemon si no existe
get-daemon:
	@if [ ! -d "daemon" ]; then \
		echo "Descargando código de kp-daemon..."; \
		git clone --depth 1 $(DAEMON_REPO) daemon; \
		rm -rf daemon/.git daemon/.github; \
	fi

# Instalación estándar: delega en el Makefile del daemon y copia los ficheros del plugin
install: get-daemon
	@echo "Instalando binario kp-daemon..."
	@$(MAKE) -C daemon install
	@echo "Limpiando e instalando plugin en $(DEST)..."
	@rm -rf $(DEST)
	@mkdir -p $(DEST)
	@cp plugin.toml finder.luau $(DEST)/
	@echo "Activando plugin en Noctalia..."
	@-noctalia msg plugins enable $(PLUGIN_ID)
	@echo "Instalado correctamente."

# Modo desarrollo: compila el daemon y crea el symlink para desarrollo
dev: get-daemon
	@echo "Instalando binario kp-daemon..."
	@$(MAKE) -C daemon install
	@echo "Enlazando plugin para desarrollo..."
	@rm -rf $(DEST)
	@mkdir -p $(dir $(DEST))
	@ln -s $(CURDIR) $(DEST)
	@echo "Activando plugin en Noctalia..."
	@-noctalia msg plugins enable $(PLUGIN_ID)
	@echo "Modo desarrollo listo."

# Desinstalación: delega en el daemon y desactiva el plugin
uninstall:
	@-noctalia msg plugins disable $(PLUGIN_ID)
	@rm -rf $(DEST)
	@if [ -d "daemon" ]; then $(MAKE) -C daemon uninstall; fi
	@echo "Desinstalado correctamente."

clean:
	@if [ -d "daemon" ]; then $(MAKE) -C daemon clean; fi
	@rm -rf daemon
	@echo "Limpieza completada."
