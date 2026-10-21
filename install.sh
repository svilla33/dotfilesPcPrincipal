#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & Linker for Arch Linux
# Manages symlinks for i3, niri, desktop tools, and custom scripts.
# ==============================================================================

set -uo pipefail

# Colores para salida de terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directorios principales
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"
BIN_DIR="$DOTFILES_DIR/bin"
THEMES_DIR="$DOTFILES_DIR/themes"
FONTS_DIR="$DOTFILES_DIR/fonts"
TARGET_CONFIG="$HOME/.config"
TARGET_BIN="$HOME/.local/bin"
TARGET_THEMES="$HOME/.themes"
TARGET_FONTS="$HOME/.local/share/fonts/dotfiles-fonts"
TARGET_COLOR_SCHEMES="$HOME/.local/share/color-schemes"

BASE_BACKUP_DIR="$HOME/.dotfiles_backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$BASE_BACKUP_DIR/$TIMESTAMP"
HAS_BACKUP=false

DRY_RUN=false
FORCE=false

# ------------------------------------------------------------------------------
# Funciones auxiliares de log
# ------------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_err() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ------------------------------------------------------------------------------
# Ayuda
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
Uso: $(basename "$0") [OPCIONES] [MODULOS...]

Opciones:
  -d, --deps        Instala las dependencias y paquetes necesarios (pacman/paru).
  -c, --check-deps  Comprueba qué paquetes están instalados o faltan en el sistema.
  -n, --dry-run     Modo simulación, muestra qué se enlazará sin hacer cambios.
  -f, --force       Fuerza el enlace sobrescribiendo enlaces existentes.
  -s, --status      Muestra el estado actual de los enlaces simbólicos.
  -r, --restore     Restaura el respaldo más reciente desde ~/.dotfiles_backup/.
  -h, --help        Muestra esta ayuda.

Módulos disponibles:
  all         Instala todas las configuraciones, scripts, temas y fuentes (por defecto).
  i3          Configuración de i3 window manager.
  niri        Configuración de niri compositor.
  waybar      Configuración de waybar.
  polybar     Configuración de polybar.
  rofi        Temas y launchers de rofi.
  alacritty   Configuración y temas de alacritty.
  gtk         Temas y configuraciones GTK (gtk-2.0, 3.0, 4.0, nwg-look).
  qt          Configuración de Qt5ct, Qt6ct y esquemas de color Nightfly.
  themes      Temas de ventana en ~/.themes (Breeze-Dark, NightFly).
  fonts       Fuentes libres (Cozette, SUSE) y configuración de fontconfig.
  bin         Scripts personalizados en ~/.local/bin.

Ejemplos:
  $(basename "$0")              # Enlaza todo con respaldos automáticos
  $(basename "$0") --deps       # Instala todos los programas y dependencias requeridas
  $(basename "$0") -c           # Comprueba estado de dependencias del sistema
  $(basename "$0") gtk qt       # Enlaza temas GTK y Qt
  $(basename "$0") fonts        # Enlaza fuentes libres y fontconfig
  $(basename "$0") --dry-run    # Simula la instalación
  $(basename "$0") --status     # Consulta estado de enlaces
  $(basename "$0") --restore    # Revierte al respaldo anterior
EOF
}

# ------------------------------------------------------------------------------
# Dependencias por Módulo (Arch Linux)
# ------------------------------------------------------------------------------
get_module_deps() {
    case "$1" in
        i3)
            echo "i3-wm feh picom dex rofi maim xclip xorg-xrandr xorg-xset xorg-xinput libpulse ttf-dejavu"
            ;;
        niri)
            echo "niri swaybg swaylock rofi-wayland brightnessctl grim slurp wl-clipboard xdg-desktop-portal-gnome wireplumber playerctl"
            ;;
        waybar)
            echo "waybar ttf-terminus-nerd wireplumber libpulse"
            ;;
        polybar)
            echo "polybar acpi ttf-terminus-nerd libpulse"
            ;;
        rofi)
            echo "rofi-wayland"
            ;;
        alacritty)
            echo "alacritty noto-fonts noto-fonts-cjk"
            ;;
        gtk)
            echo "breeze-icons nwg-look"
            ;;
        qt)
            echo "qt5ct qt6ct breeze"
            ;;
        fonts)
            echo "fontconfig noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-terminus-nerd"
            ;;
        bin|scripts)
            echo "curl jq unzip gcc podman ffmpeg v4l2loopback-dkms"
            ;;
        common)
            echo "pcmanfm network-manager-applet polkit-gnome pipewire wireplumber libpulse"
            ;;
    esac
}

get_all_deps() {
    local raw_pkgs=""
    for m in "$@"; do
        if [ "$m" = "all" ]; then
            raw_pkgs="$raw_pkgs $(get_module_deps common) $(get_module_deps i3) $(get_module_deps niri) $(get_module_deps waybar) $(get_module_deps polybar) $(get_module_deps rofi) $(get_module_deps alacritty) $(get_module_deps gtk) $(get_module_deps qt) $(get_module_deps fonts) $(get_module_deps bin)"
        else
            raw_pkgs="$raw_pkgs $(get_module_deps common) $(get_module_deps "$m")"
        fi
    done
    echo "$raw_pkgs" | tr -s ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' '
}

check_dependencies() {
    local pkgs=($(get_all_deps "$@"))
    local missing=()
    local installed=()

    echo -e "${BOLD}--- Estado de Dependencias y Paquetes (${#pkgs[@]} evaluados) ---${NC}"
    for pkg in "${pkgs[@]}"; do
        if pacman -T "$pkg" >/dev/null 2>&1; then
            installed+=("$pkg")
            echo -e "  ${GREEN}✔${NC} $pkg"
        else
            missing+=("$pkg")
            echo -e "  ${RED}✖${NC} $pkg (faltante)"
        fi
    done

    echo ""
    log_info "Total requeridos: ${#pkgs[@]} | Instalados: ${#installed[@]} | Faltantes: ${#missing[@]}"
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}Para instalar los paquetes faltantes ejecuta:${NC}"
        echo -e "  sudo pacman -S --needed ${missing[*]}"
        echo -e "  O corre: $(basename "$0") --deps ${*:-}"
    else
        log_ok "¡Todas las dependencias necesarias están instaladas!"
    fi
}

install_dependencies() {
    local pkgs=($(get_all_deps "$@"))
    local missing=()

    for pkg in "${pkgs[@]}"; do
        if ! pacman -T "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        log_ok "Todas las dependencias evaluadas ya están instaladas en el sistema."
        return 0
    fi

    echo -e "${YELLOW}Se detectaron ${#missing[@]} paquetes faltantes:${NC}"
    echo -e "  ${BOLD}${missing[*]}${NC}"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Se ejecutaría la instalación de: ${missing[*]}"
        return 0
    fi

    log_info "Iniciando instalación mediante el gestor de paquetes..."
    if command -v paru >/dev/null 2>&1; then
        paru -S --needed "${missing[@]}"
    elif command -v yay >/dev/null 2>&1; then
        yay -S --needed "${missing[@]}"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed "${missing[@]}"
    else
        log_err "No se encontró pacman, paru o yay en el sistema."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Comprobación de Estado
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}--- Estado de Configuraciones (.config) ---${NC}"
    for dir in "$CONFIG_DIR"/*; do
        [ -d "$dir" ] || continue
        local name
        name="$(basename "$dir")"
        [ "$name" = "gtk-2.0" ] || [ "$name" = "color-schemes" ] && continue
        local target="$TARGET_CONFIG/$name"

        if [ -L "$target" ]; then
            local dest
            dest="$(readlink -f "$target")"
            if [ "$dest" = "$(readlink -f "$dir")" ]; then
                echo -e "  ${GREEN}✔${NC} $name -> $target (correcto)"
            else
                echo -e "  ${YELLOW}⚠${NC} $name -> apunta a $dest (diferente)"
            fi
        elif [ -e "$target" ]; then
            echo -e "  ${RED}✖${NC} $name existe en $TARGET_CONFIG pero NO es un symlink"
        else
            echo -e "  ${YELLOW}○${NC} $name no está instalado en $TARGET_CONFIG"
        fi
    done

    echo -e "\n${BOLD}--- Estado de Temas y Apariencia ---${NC}"
    # GTK 2
    if [ -L "$HOME/.gtkrc-2.0" ] && [ "$(readlink -f "$HOME/.gtkrc-2.0")" = "$(readlink -f "$CONFIG_DIR/gtk-2.0/gtkrc-2.0")" ]; then
        echo -e "  ${GREEN}✔${NC} ~/.gtkrc-2.0 (correcto)"
    else
        echo -e "  ${YELLOW}○${NC} ~/.gtkrc-2.0 no apunta a dotfiles"
    fi
    # Themes
    for th in "$THEMES_DIR"/*; do
        [ -d "$th" ] || continue
        local th_name
        th_name="$(basename "$th")"
        local target_th="$TARGET_THEMES/$th_name"
        if [ -L "$target_th" ] && [ "$(readlink -f "$target_th")" = "$(readlink -f "$th")" ]; then
            echo -e "  ${GREEN}✔${NC} Tema: $th_name"
        else
            echo -e "  ${YELLOW}○${NC} Tema: $th_name no enlazado"
        fi
    done
    # Color schemes
    for cs in "$CONFIG_DIR/color-schemes"/*; do
        [ -e "$cs" ] || continue
        local cs_name
        cs_name="$(basename "$cs")"
        local target_cs="$TARGET_COLOR_SCHEMES/$cs_name"
        if [ -L "$target_cs" ] && [ "$(readlink -f "$target_cs")" = "$(readlink -f "$cs")" ]; then
            echo -e "  ${GREEN}✔${NC} Color scheme: $cs_name"
        else
            echo -e "  ${YELLOW}○${NC} Color scheme: $cs_name no enlazado"
        fi
    done
    # Fonts
    if [ -L "$TARGET_FONTS" ] && [ "$(readlink -f "$TARGET_FONTS")" = "$(readlink -f "$FONTS_DIR")" ]; then
        echo -e "  ${GREEN}✔${NC} Fuentes libres en $TARGET_FONTS"
    else
        echo -e "  ${YELLOW}○${NC} Fuentes libres no enlazadas en $TARGET_FONTS"
    fi

    echo -e "\n${BOLD}--- Estado de Scripts (~/.local/bin) ---${NC}"
    for script in "$BIN_DIR"/*; do
        [ -e "$script" ] || continue
        local name
        name="$(basename "$script")"
        local target="$TARGET_BIN/$name"

        if [ -L "$target" ]; then
            local dest
            dest="$(readlink -f "$target")"
            if [ "$dest" = "$(readlink -f "$script")" ]; then
                echo -e "  ${GREEN}✔${NC} $name (enlazado)"
            else
                echo -e "  ${YELLOW}⚠${NC} $name -> $dest (diferente)"
            fi
        elif [ -e "$target" ]; then
            echo -e "  ${RED}✖${NC} $name existe en $TARGET_BIN pero es archivo físico"
        else
            echo -e "  ${YELLOW}○${NC} $name no está en $TARGET_BIN"
        fi
    done
}

# ------------------------------------------------------------------------------
# Restauración desde respaldo
# ------------------------------------------------------------------------------
restore_backup() {
    if [ ! -d "$BASE_BACKUP_DIR" ]; then
        log_err "No existe el directorio de respaldos: $BASE_BACKUP_DIR"
        exit 1
    fi

    local latest_backup
    latest_backup="$(ls -td "$BASE_BACKUP_DIR"/*/ 2>/dev/null | head -n 1)"

    if [ -z "$latest_backup" ]; then
        log_err "No se encontraron respaldos en $BASE_BACKUP_DIR"
        exit 1
    fi

    latest_backup="${latest_backup%/}"
    echo -e "${YELLOW}Restaurando desde respaldo más reciente:${NC} $latest_backup"

    # Restaurar configs
    if [ -d "$latest_backup/.config" ]; then
        for item in "$latest_backup/.config"/*; do
            [ -e "$item" ] || continue
            local name
            name="$(basename "$item")"
            local target="$TARGET_CONFIG/$name"

            if [ -L "$target" ]; then
                rm "$target"
            fi
            mv "$item" "$target"
            log_ok "Restaurado: .config/$name"
        done
    fi

    # Restaurar ~/.gtkrc-2.0
    if [ -f "$latest_backup/.gtkrc-2.0" ]; then
        [ -L "$HOME/.gtkrc-2.0" ] && rm "$HOME/.gtkrc-2.0"
        mv "$latest_backup/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
        log_ok "Restaurado: ~/.gtkrc-2.0"
    fi

    # Restaurar ~/.themes
    if [ -d "$latest_backup/.themes" ]; then
        for item in "$latest_backup/.themes"/*; do
            [ -e "$item" ] || continue
            local name
            name="$(basename "$item")"
            [ -L "$TARGET_THEMES/$name" ] && rm "$TARGET_THEMES/$name"
            mv "$item" "$TARGET_THEMES/$name"
            log_ok "Restaurado: .themes/$name"
        done
    fi

    # Restaurar color-schemes
    if [ -d "$latest_backup/.local/share/color-schemes" ]; then
        for item in "$latest_backup/.local/share/color-schemes"/*; do
            [ -e "$item" ] || continue
            local name
            name="$(basename "$item")"
            [ -L "$TARGET_COLOR_SCHEMES/$name" ] && rm "$TARGET_COLOR_SCHEMES/$name"
            mv "$item" "$TARGET_COLOR_SCHEMES/$name"
            log_ok "Restaurado: .local/share/color-schemes/$name"
        done
    fi

    # Restaurar scripts
    if [ -d "$latest_backup/.local/bin" ]; then
        for item in "$latest_backup/.local/bin"/*; do
            [ -e "$item" ] || continue
            local name
            name="$(basename "$item")"
            local target="$TARGET_BIN/$name"

            if [ -L "$target" ]; then
                rm "$target"
            fi
            mv "$item" "$target"
            log_ok "Restaurado: .local/bin/$name"
        done
    fi

    log_ok "Restauración completada."
    exit 0
}

# ------------------------------------------------------------------------------
# Funciones de Respaldo y Enlace
# ------------------------------------------------------------------------------
backup_item() {
    local src="$1"
    local rel_dest="$2"
    local dest="$BACKUP_DIR/$rel_dest"

    if [ "$DRY_RUN" = true ]; then
        log_warn "[DRY-RUN] Se respaldaría $src -> $dest"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    mv "$src" "$dest"
    HAS_BACKUP=true
    log_warn "Respaldado: $src -> $dest"
}

link_dir() {
    local mod_name="$1"
    local source_path="$CONFIG_DIR/$mod_name"
    local target_path="$TARGET_CONFIG/$mod_name"

    if [ ! -d "$source_path" ]; then
        log_err "El módulo '$mod_name' no existe en $CONFIG_DIR"
        return 1
    fi

    # Si ya es un enlace apuntando al destino correcto
    if [ -L "$target_path" ]; then
        local current_link
        current_link="$(readlink -f "$target_path")"
        local expected_link
        expected_link="$(readlink -f "$source_path")"

        if [ "$current_link" = "$expected_link" ]; then
            log_ok "Ya enlazado: $target_path -> $source_path"
            return 0
        else
            log_warn "Enlace existente apunta a otro destino: $current_link"
            if [ "$DRY_RUN" = false ]; then
                rm "$target_path"
            fi
        fi
    elif [ -e "$target_path" ]; then
        # Es un directorio o archivo real, respaldar
        backup_item "$target_path" ".config/$mod_name"
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Se crearía symlink: $target_path -> $source_path"
    else
        mkdir -p "$TARGET_CONFIG"
        ln -sfn "$source_path" "$target_path"
        log_ok "Enlazado: $target_path -> $source_path"
    fi
}

link_scripts() {
    if [ ! -d "$BIN_DIR" ]; then
        log_err "No se encontró el directorio de scripts: $BIN_DIR"
        return 1
    fi

    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$TARGET_BIN"
    fi

    log_info "Procesando scripts en $BIN_DIR..."

    for script_path in "$BIN_DIR"/*; do
        [ -e "$script_path" ] || continue
        local script_name
        script_name="$(basename "$script_path")"
        local target_script="$TARGET_BIN/$script_name"

        if [ -L "$target_script" ]; then
            local current_link
            current_link="$(readlink -f "$target_script")"
            local expected_link
            expected_link="$(readlink -f "$script_path")"

            if [ "$current_link" = "$expected_link" ]; then
                log_ok "Script ya enlazado: $script_name"
                continue
            else
                if [ "$DRY_RUN" = false ]; then
                    rm "$target_script"
                fi
            fi
        elif [ -e "$target_script" ]; then
            # Respaldar archivo real existente
            backup_item "$target_script" ".local/bin/$script_name"
        fi

        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY-RUN] Se crearía symlink: $target_script -> $script_path"
        else
            chmod +x "$script_path"
            ln -sf "$script_path" "$target_script"
            log_ok "Script enlazado: $script_name"
        fi
    done
}

link_file() {
    local source_path="$1"
    local target_path="$2"
    local rel_dest="$3"

    if [ ! -f "$source_path" ]; then
        log_err "Archivo no encontrado: $source_path"
        return 1
    fi

    if [ -L "$target_path" ]; then
        local current_link
        current_link="$(readlink -f "$target_path")"
        local expected_link
        expected_link="$(readlink -f "$source_path")"
        if [ "$current_link" = "$expected_link" ]; then
            log_ok "Ya enlazado: $target_path -> $source_path"
            return 0
        else
            log_warn "Enlace apunta a otro destino: $current_link"
            if [ "$DRY_RUN" = false ]; then
                rm "$target_path"
            fi
        fi
    elif [ -e "$target_path" ]; then
        backup_item "$target_path" "$rel_dest"
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Se crearía symlink: $target_path -> $source_path"
    else
        mkdir -p "$(dirname "$target_path")"
        ln -sf "$source_path" "$target_path"
        log_ok "Enlazado: $target_path -> $source_path"
    fi
}

link_gtk() {
    log_info "Instalando configuraciones y temas GTK..."
    link_dir "gtk-3.0"
    link_dir "gtk-4.0"
    link_dir "nwg-look"
    link_file "$CONFIG_DIR/gtk-2.0/gtkrc-2.0" "$HOME/.gtkrc-2.0" ".gtkrc-2.0"
}

link_qt() {
    log_info "Instalando configuraciones Qt y esquemas de color..."
    link_dir "qt5ct"
    link_dir "qt6ct"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$TARGET_COLOR_SCHEMES"
    fi
    for cs in "$CONFIG_DIR/color-schemes"/*; do
        [ -e "$cs" ] || continue
        link_file "$cs" "$TARGET_COLOR_SCHEMES/$(basename "$cs")" ".local/share/color-schemes/$(basename "$cs")"
    done
}

link_themes() {
    log_info "Instalando temas de ventanas en ~/.themes..."
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$TARGET_THEMES"
    fi
    for th in "$THEMES_DIR"/*; do
        [ -d "$th" ] || continue
        local th_name
        th_name="$(basename "$th")"
        local target_th="$TARGET_THEMES/$th_name"

        if [ -L "$target_th" ]; then
            local current_link
            current_link="$(readlink -f "$target_th")"
            if [ "$current_link" = "$(readlink -f "$th")" ]; then
                log_ok "Tema ya enlazado: $th_name"
                continue
            else
                [ "$DRY_RUN" = false ] && rm "$target_th"
            fi
        elif [ -e "$target_th" ]; then
            backup_item "$target_th" ".themes/$th_name"
        fi

        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY-RUN] Se crearía symlink: $target_th -> $th"
        else
            ln -sfn "$th" "$target_th"
            log_ok "Tema enlazado: $th_name"
        fi
    done
}

link_fonts() {
    log_info "Instalando fuentes libres y configuración de fontconfig..."
    link_dir "fontconfig"

    local target_f="$TARGET_FONTS"
    if [ -L "$target_f" ]; then
        local current_link
        current_link="$(readlink -f "$target_f")"
        if [ "$current_link" = "$(readlink -f "$FONTS_DIR")" ]; then
            log_ok "Directorio de fuentes ya enlazado: $target_f"
            return 0
        else
            [ "$DRY_RUN" = false ] && rm "$target_f"
        fi
    elif [ -e "$target_f" ]; then
        backup_item "$target_f" ".local/share/fonts/dotfiles-fonts"
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Se crearía symlink: $target_f -> $FONTS_DIR"
    else
        mkdir -p "$(dirname "$target_f")"
        ln -sfn "$FONTS_DIR" "$target_f"
        log_ok "Fuentes libres enlazadas: $target_f -> $FONTS_DIR"
        if command -v fc-cache >/dev/null 2>&1; then
            log_info "Actualizando caché de fuentes del sistema..."
            fc-cache -f "$target_f" >/dev/null 2>&1 || true
            log_ok "Caché de fuentes actualizada."
        fi
    fi
}

# ------------------------------------------------------------------------------
# Procesamiento de argumentos
# ------------------------------------------------------------------------------
MODULES=()
ACTION="link"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--deps|--install-deps)
            ACTION="deps"
            shift
            ;;
        -c|--check-deps)
            ACTION="check_deps"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -s|--status)
            show_status
            exit 0
            ;;
        -r|--restore)
            restore_backup
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        all|i3|niri|waybar|polybar|rofi|alacritty|bin|scripts|gtk|qt|themes|fonts)
            MODULES+=("$1")
            shift
            ;;
        *)
            log_err "Opción o módulo desconocido: $1"
            show_help
            exit 1
            ;;
    esac
done

# Si no se pasaron módulos, instalar o comprobar todos por defecto
if [ ${#MODULES[@]} -eq 0 ]; then
    MODULES=("all")
fi

# Acción: Solo comprobar dependencias
if [ "$ACTION" = "check_deps" ]; then
    check_dependencies "${MODULES[@]}"
    exit 0
fi

# Acción: Instalar paquetes y dependencias
if [ "$ACTION" = "deps" ]; then
    install_dependencies "${MODULES[@]}"
    exit 0
fi

echo -e "${BOLD}=====================================================${NC}"
echo -e "${BOLD}   Instalador de Dotfiles Arch Linux (i3 & niri)    ${NC}"
echo -e "${BOLD}=====================================================${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}MODO SIMULACIÓN (DRY-RUN) ACTIVO: No se aplicarán cambios.${NC}\n"
fi

for mod in "${MODULES[@]}"; do
    case "$mod" in
        all)
            log_info "Instalando todos los módulos..."
            link_dir "i3"
            link_dir "niri"
            link_dir "waybar"
            link_dir "polybar"
            link_dir "rofi"
            link_dir "alacritty"
            link_gtk
            link_qt
            link_themes
            link_fonts
            link_scripts
            ;;
        i3|niri|waybar|polybar|rofi|alacritty)
            link_dir "$mod"
            ;;
        gtk)
            link_gtk
            ;;
        qt)
            link_qt
            ;;
        themes)
            link_themes
            ;;
        fonts)
            link_fonts
            ;;
        bin|scripts)
            link_scripts
            ;;
    esac
done

echo ""
echo -e "${BOLD}=====================================================${NC}"
log_ok "Proceso completado con éxito."

# Advertir si faltan programas para los módulos instalados
missing_summary=()
for p in $(get_all_deps "${MODULES[@]}"); do
    if ! pacman -T "$p" >/dev/null 2>&1; then
        missing_summary+=("$p")
    fi
done

if [ ${#missing_summary[@]} -gt 0 ]; then
    echo ""
    log_warn "Se detectaron ${#missing_summary[@]} programas recomendados no instalados: ${missing_summary[*]}"
    echo -e "  💡 Para instalarlos ahora, corre: ${BOLD}./install.sh --deps ${MODULES[*]}${NC}"
fi

if [ "$HAS_BACKUP" = true ]; then
    echo -e "\n${YELLOW}Se realizaron respaldos de tus archivos previos en:${NC}"
    echo -e "  📂 $BACKUP_DIR"
fi
echo -e "${BOLD}=====================================================${NC}"
