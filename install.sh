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
TARGET_CONFIG="$HOME/.config"
TARGET_BIN="$HOME/.local/bin"

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
  all         Instala todas las configuraciones y scripts (por defecto).
  i3          Configuración de i3 window manager.
  niri        Configuración de niri compositor.
  waybar      Configuración de waybar.
  polybar     Configuración de polybar.
  rofi        Temas y launchers de rofi.
  alacritty   Configuración y temas de alacritty.
  bin         Scripts personalizados en ~/.local/bin.

Ejemplos:
  $(basename "$0")              # Enlaza todo con respaldos automáticos
  $(basename "$0") --deps       # Instala todos los programas y dependencias requeridas
  $(basename "$0") -c           # Comprueba estado de dependencias del sistema
  $(basename "$0") --deps niri  # Instala solo dependencias de Niri y Waybar
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
            raw_pkgs="$raw_pkgs $(get_module_deps common) $(get_module_deps i3) $(get_module_deps niri) $(get_module_deps waybar) $(get_module_deps polybar) $(get_module_deps rofi) $(get_module_deps alacritty) $(get_module_deps bin)"
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
        all|i3|niri|waybar|polybar|rofi|alacritty|bin|scripts)
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
            link_scripts
            ;;
        i3|niri|waybar|polybar|rofi|alacritty)
            link_dir "$mod"
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
