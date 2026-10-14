PREFIX     ?= $(HOME)/.local/share/noctalia/plugins
BINDIR     ?= /usr/local/bin
SUDO       ?= sudo
PLUGIN_ID   = Lummotm/keepass
DEST        = $(PREFIX)/kp-launcher
DAEMON_REPO ?= https://github.com/Lummotm/kp-daemon.git

.PHONY: all get-daemon install dev uninstall clean

all: install

get-daemon:
	@if [ ! -d "daemon" ]; then \
		echo "Descargando código de kp-daemon..."; \
		git clone --depth 1 $(DAEMON_REPO) daemon; \
		rm -rf daemon/.git daemon/.github; \
	fi

# Instalación para usuario: instala binario, plugin, activa y limpia la descarga
install: get-daemon
	@echo "Instalando binario kp-daemon..."
	@$(MAKE) -C daemon install BINDIR=$(BINDIR) SUDO=$(SUDO)
	@echo "Instalando plugin en $(DEST)..."
	@rm -rf $(DEST)
	@mkdir -p $(DEST)
	@cp plugin.toml finder.luau $(DEST)/
	@echo "Activando plugin en Noctalia..."
	@-noctalia msg plugins enable $(PLUGIN_ID)
	@echo "Limpiando archivos temporales de compilación..."
	@rm -rf daemon
	@echo "Instalación completada y directorio limpio."

# Modo desarrollo: compila e instala, pero CONSERVA daemon/ y crea symlink
dev: get-daemon
	@echo "Instalando binario kp-daemon..."
	@$(MAKE) -C daemon install BINDIR=$(BINDIR) SUDO=$(SUDO)
	@echo "Enlazando plugin para desarrollo..."
	@rm -rf $(DEST)
	@mkdir -p $(dir $(DEST))
	@ln -s $(CURDIR) $(DEST)
	@echo "Activando plugin en Noctalia..."
	@-noctalia msg plugins enable $(PLUGIN_ID)
	@echo "Modo desarrollo listo (carpeta daemon/ conservada)."

uninstall:
	@echo "Desactivando plugin en Noctalia..."
	@-noctalia msg plugins disable $(PLUGIN_ID)
	@echo "Eliminando archivos del plugin..."
	@rm -rf $(DEST)
	@echo "Eliminando binario kp-daemon de $(BINDIR)..."
	@if [ -d "daemon" ]; then \
		$(MAKE) -C daemon uninstall BINDIR=$(BINDIR) SUDO=$(SUDO); \
	else \
		$(SUDO) rm -f $(BINDIR)/kp-daemon; \
		rm -rf daemon/; \ 
	fi
	@echo "Desinstalado correctamente."

clean:
	@if [ -d "daemon" ]; then $(MAKE) -C daemon clean; fi
	@rm -rf daemon
	@echo "Limpieza completada."
