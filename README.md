# 🛠️ Arch Linux Dotfiles (Niri & i3)

Repositorio de dotfiles para **Arch Linux** configurado con dos entornos de ventanas:
- **[Niri](https://github.com/YaLTeR/niri)** (Wayland - Scrollable-tiling compositor)
- **[i3-wm](https://i3wm.org/)** (X11 - Manual tiling window manager)

Incluye barra de estado, lanzadores, emulador de terminal y scripts personalizados de productividad y mantenimiento.

---

## 📁 Estructura del Repositorio

```text
dotfiles/
├── bin/                          # Scripts personales (enlazados a ~/.local/bin)
│   ├── appimages-sync            # Sincroniza AppImages con el menú de aplicaciones
│   ├── clean-downloads.sh        # Clasifica descargas por tipo en ~/Downloads
│   ├── cleanup-temp.sh           # Limpieza de archivos temporales
│   ├── consolidate-folders.sh    # Resuelve carpetas duplicadas
│   ├── cpp_run.sh                # Compila y ejecuta archivos C++
│   ├── c_run.sh                  # Compila y ejecuta archivos C
│   ├── dic.sh                    # Consulta definiciones en Wiktionary
│   ├── extract_all.sh            # Descompresor universal para archivos anidados
│   ├── hackermode                # Script visual temático interactivo
│   ├── muget                     # Descargador y gestor de música
│   ├── organizadorAnios.sh       # Organiza archivos por año según fecha
│   ├── organize-home.sh          # Mueve archivos sueltos de ~/ a carpetas estándar
│   ├── osu-wine                  # Script de inicio optimizado para osu! vía Wine
│   ├── samba-container.sh        # Servidor Samba local en contenedor
│   ├── screenshot.sh             # Capturas de pantalla con grim/slurp
│   ├── startCamera.sh            # Inicializa cámara virtual v4l2loopback
│   └── wellcome                  # Script de bienvenida con información de sistema
├── config/                       # Configuraciones (enlazadas a ~/.config)
│   ├── alacritty/                # Terminal Alacritty con tema Nightfly
│   ├── color-schemes/            # Esquemas de color Qt (NightflyCustom, Nightfly)
│   ├── fontconfig/               # Reglas de renderizado y emojis (fonts.conf)
│   ├── gtk-2.0/                  # Archivo ~/.gtkrc-2.0
│   ├── gtk-3.0/                  # Tema Breeze-Dark / colores Nightfly y CSS
│   ├── gtk-4.0/                  # Tema Breeze-Dark / colores Nightfly para GTK4
│   ├── i3/                       # Configuración de i3, fondos y screenshot.sh
│   ├── niri/                     # Configuración de Niri (config.kdl, monitor.kdl)
│   ├── nwg-look/                 # Configuración de apariencia nwg-look
│   ├── polybar/                  # Barra de estado Polybar para i3 (launch.sh)
│   ├── qt5ct/                    # Configuración de estilo y paleta para Qt5
│   ├── qt6ct/                    # Configuración de estilo y paleta para Qt6
│   ├── rofi/                     # Lanzador Rofi (temas Catppuccin, Nightfly, Launchpad)
│   └── waybar/                   # Barra de estado Waybar para Niri
├── fonts/                        # Fuentes libres y OFL (Cozette, SUSE, CustomTkinter)
├── themes/                       # Temas de ventana (enlazados a ~/.themes)
│   ├── Breeze-Dark/              # Tema Breeze-Dark modificado con nwg-look
│   └── NightFly/                 # Tema NightFly GTK2/3/4
├── install.sh                    # Script de instalación, symlinks y respaldos
└── README.md                     # Documentación general
```

---

## 🎨 Temas, Apariencia y Fuentes

- **Tema GTK (`config/gtk-*`, `themes/`)**: Configuración completa para GTK 2, 3 y 4 con estilo **Breeze-Dark** modificado con la paleta **Nightfly** (`#011627`, `#21c7a8`, `#30ffd2`), cursores `breeze_cursors` e iconos `breeze-dark`.
- **Tema Qt (`config/qt5ct`, `config/qt6ct`, `config/color-schemes`)**: Coherencia visual total entre aplicaciones Qt y GTK mediante `qt5ct` y `qt6ct` usando el motor Breeze con el esquema `NightflyCustom.colors`.
- **Fuentes (`fonts/`, `config/fontconfig`)**:
  - Contiene exclusivamente tipografías de código abierto y libres de licencia (familia **SUSE / SUSEMono** bajo licencia SIL OFL, **Cozette** bitmap/vectorial bajo MIT).
  - Reglas avanzadas de **fontconfig** (`fonts.conf`) para priorizar emojis y suavizado subpixel RGB.
  - **Fuentes de Windows excluidas**: Todas las fuentes propietarias de Microsoft (Arial, Calibri, Tahoma, Segoe UI, Consolas, MS Gothic, etc.) han sido estrictamente filtradas e ignoradas en `.gitignore`.

---

## 🚀 Instalación y Gestión (`install.sh`)

El repositorio incluye un script `install.sh` que gestiona de manera segura los enlaces simbólicos (`symlinks`), instala las dependencias necesarias y crea un respaldo automático con marca de tiempo en `~/.dotfiles_backup/` de cualquier archivo existente antes de reemplazarlo.

### 1. Comprobar dependencias del sistema
Verifica qué paquetes y herramientas necesarias están instaladas o faltan:
```bash
./install.sh -c
```

### 2. Instalar paquetes y dependencias faltantes
Instala automáticamente los programas necesarios a través de `paru` / `yay` / `pacman`:
```bash
./install.sh --deps        # Instala dependencias para todos los módulos
./install.sh --deps niri   # Solo dependencias para Niri y Waybar
./install.sh --deps gtk    # Dependencias de temas GTK
./install.sh --deps qt     # Dependencias de Qt (qt5ct, qt6ct, breeze)
```

### 3. Comprobar estado de enlaces simbólicos
```bash
./install.sh --status
```

### 4. Simular instalación de enlaces (Dry-Run)
Verifica los cambios que se harían sin modificar nada en tu sistema:
```bash
./install.sh --dry-run
```

### 5. Enlazar dotfiles
Aplica los symlinks de todos los entornos, temas, fuentes y scripts:
```bash
./install.sh
```

### 6. Instalar módulos específicos
Puedes enlazar únicamente lo que necesites:
```bash
./install.sh gtk qt themes fonts # Solo apariencia y fuentes
./install.sh niri waybar          # Solo Niri y Waybar
./install.sh i3 polybar           # Solo i3 y Polybar
./install.sh bin                  # Solo los scripts de ~/.local/bin
```

### 7. Revertir cambios
Si deseas deshacer la instalación y restaurar los archivos previos:
```bash
./install.sh --restore
```

---

## 📦 Paquetes y Dependencias Recomendadas (Arch Linux)

Para aprovechar al máximo todas las funciones de ambas sesiones:

### Gestores de Ventanas & Compositor
```bash
# Niri (Wayland)
sudo pacman -S niri waybar swaybg xdg-desktop-portal-gnome polkit-gnome

# i3 (X11)
sudo pacman -S i3-wm polybar feh dex picom rofi
```

### Terminal, Audio y Herramientas Comunes
```bash
sudo pacman -S alacritty pipewire wireplumber playerctl brightnessctl grim slurp
```

---

## ⚙️ Detalles de Configuración

- **i3 (`config/i3`)**: Atajos de teclado estilo Hyprland/moderno, compatibilidad multimonitor (1080p + 1440p), integración con Polybar y fondo en `back2.jpg`.
- **Niri (`config/niri`)**: Desplazamiento horizontal dinámico, integración con Waybar y Rofi en modo Wayland, audio controlado por WirePlumber (`wpctl`).
- **Scripts (`bin/`)**: No tocan binarios pesados de terceros (`agy`, `blender`, etc.) que residen en `~/.local/bin`; únicamente versionan tus utilidades y scripts personales.
