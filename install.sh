#!/bin/bash
#
# Dotfiles & System Setup Script
#
# This script sets up symlinks for dotfiles and installs essential software.
# It's designed to be idempotent and safe to run multiple times.
#

# --- 全局变量 ---
# 获取脚本所在的目录 (dotfiles 仓库的根目录)
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
OS_NAME="$(uname -s)"

is_macos() {
  [ "$OS_NAME" = "Darwin" ]
}

is_linux() {
  [ "$OS_NAME" = "Linux" ]
}


# ==============================================================================
# 软件安装函数 (Software Installation Functions)
# ==============================================================================

# --- 安装 Homebrew 软件包和字体 ---
install_homebrew_packages() {
  echo -e "\n››› Installing Homebrew packages..."

  # 检查 Homebrew 是否已安装
  if ! command -v brew &> /dev/null; then
    echo "  Homebrew not found. Please install it first by running:"
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return 1 # 返回错误，中止函数
  fi

  # 定义需要安装的软件包列表
  local brew_packages=(
    yazi
    ffmpeg
    sevenzip
    jq
    poppler
    fd
    ripgrep
    fzf
    zoxide
    resvg
    imagemagick
    eza
    nvim
    starship
    rich-cli
    virtualenv
  )

  # 定义需要安装的字体/应用列表 (Casks)
  local brew_casks=(
    font-jetbrains-mono-nerd-font
  )

  echo "  Installing formulae: ${brew_packages[*]}"
  brew install "${brew_packages[@]}"

  echo "  Installing casks: ${brew_casks[*]}"
  brew install --cask "${brew_casks[@]}"

  echo "  ✅ Homebrew packages installation complete."
}


# --- 安装 Ubuntu 软件包；仓库里没有的软件自动跳过 ---
install_ubuntu_packages() {
  echo -e "\n››› Installing Ubuntu packages..."

  if ! command -v apt-get &> /dev/null; then
    echo "  apt-get not found. Skipping package installation."
    return 0
  fi

  local apt_packages=(
    git
    curl
    wget
    tmux
    btop
    ffmpeg
    p7zip-full
    jq
    poppler-utils
    fd-find
    ripgrep
    fzf
    zoxide
    librsvg2-bin
    imagemagick
    eza
    neovim
    snapd
    starship
    python3-virtualenv
  )

  local installable=()
  local pkg
  for pkg in "${apt_packages[@]}"; do
    if apt-cache show "$pkg" &> /dev/null; then
      installable+=("$pkg")
    else
      echo "  Package not available in apt: $pkg. Skipping."
    fi
  done

  if [ "${#installable[@]}" -eq 0 ]; then
    echo "  No apt packages available to install."
    return 0
  fi

  local sudo_cmd=()
  if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
      sudo_cmd=(sudo)
    else
      echo "  sudo not found and not running as root. Skipping package installation."
      return 0
    fi
  fi

  "${sudo_cmd[@]}" apt-get update
  "${sudo_cmd[@]}" apt-get install -y "${installable[@]}"

  mkdir -p "$HOME/.local/bin"
  if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "  Linked fdfind as ~/.local/bin/fd"
  fi

  echo "  ✅ Ubuntu package installation complete."

  install_ubuntu_yazi
}


install_ubuntu_yazi() {
  echo -e "\n››› Installing Yazi for Ubuntu..."

  if command -v yazi &> /dev/null || [ -x /snap/bin/yazi ]; then
    echo "  Yazi already installed. Skipping."
    return 0
  fi

  local sudo_cmd=()
  if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
      sudo_cmd=(sudo)
    else
      echo "  sudo not found and not running as root. Cannot install Yazi."
      return 1
    fi
  fi

  if apt-cache show yazi &> /dev/null; then
    "${sudo_cmd[@]}" apt-get install -y yazi
  fi

  if command -v yazi &> /dev/null || [ -x /snap/bin/yazi ]; then
    echo "  ✅ Yazi installation complete."
    return 0
  fi

  if command -v snap &> /dev/null; then
    "${sudo_cmd[@]}" snap install yazi --classic || true
  fi

  if command -v yazi &> /dev/null || [ -x /snap/bin/yazi ]; then
    echo "  ✅ Yazi installation complete."
    return 0
  fi

  echo "  Yazi was not installed. Install it manually, then rerun bash install.sh."
  return 1
}


install_packages() {
  if is_macos; then
    install_homebrew_packages
  elif is_linux; then
    install_ubuntu_packages
  else
    echo -e "\n››› Unsupported OS '$OS_NAME'. Skipping package installation."
  fi
}


# --- 安装 Zim Zsh Framework ---
install_zimfw() {
  echo -e "\n››› Installing Zim Zsh Framework..."

  if ! command -v zsh &> /dev/null; then
    echo "  zsh not found. Skipping Zim installation."
    return 0
  fi

  # 检查 Zim 是否已安装，避免重复执行
  if [ -d "${ZIM_HOME:-$HOME/.zim}" ]; then
    echo "  Zim Framework already installed. Skipping."
  else
    echo "  Downloading and running Zim installer..."
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
    echo "  ✅ Zim installation complete."
  fi
}


# ==============================================================================
# 配置文件链接函数 (Dotfiles Symlinking Function)
# ==============================================================================

link_dotfiles() {
  echo -e "\n››› Symlinking dotfiles from $DOTFILES_DIR..."

  backup_path() {
      local path="$1"
      local backup_path="$path.bak"

      if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
          backup_path="$path.bak.$(date +%Y%m%d%H%M%S)"
      fi

      echo "    Backing up existing $path to $backup_path"
      mv "$path" "$backup_path"
  }

  link_path() {
      local src_path="$1"
      local dest_path="$2"

      if [ ! -e "$src_path" ]; then
          echo "    Source missing: $src_path. Skipping."
          return
      fi

      mkdir -p "$(dirname "$dest_path")"

      if [ -L "$dest_path" ]; then
          if [ "$(readlink "$dest_path")" = "$src_path" ]; then
              echo "    Symlink already exists for $dest_path. Skipping."
              return
          fi
          backup_path "$dest_path"
      fi

      if [ -e "$dest_path" ]; then
          backup_path "$dest_path"
      fi

      ln -s "$src_path" "$dest_path"
      echo "    Linked $src_path -> $dest_path"
  }

  prepare_real_dir() {
      local dest_dir="$1"

      if [ -L "$dest_dir" ]; then
          backup_path "$dest_dir"
      fi

      mkdir -p "$dest_dir"
  }

  should_link_linux_config() {
      local item_name="$1"

      case "$item_name" in
          btop) command -v btop &> /dev/null ;;
          gh) command -v gh &> /dev/null ;;
          nvim) command -v nvim &> /dev/null ;;
          starship.toml) command -v starship &> /dev/null ;;
          tmux) command -v tmux &> /dev/null ;;
          yazi) command -v yazi &> /dev/null || [ -x /snap/bin/yazi ] ;;
          *) return 1 ;;
      esac
  }

  ensure_bashrc_source() {
      local source_line='[ -f "$HOME/.config/dotfiles-ubuntu-bash.sh" ] && source "$HOME/.config/dotfiles-ubuntu-bash.sh"'
      local bashrc="$HOME/.bashrc"

      touch "$bashrc"
      if grep -Fq "$source_line" "$bashrc"; then
          echo "    ~/.bashrc already sources Ubuntu bash profile. Skipping."
      else
          printf '\n# Dotfiles Ubuntu bash profile\n%s\n' "$source_line" >> "$bashrc"
          echo "    Added Ubuntu bash profile source to ~/.bashrc"
      fi
  }

  link_ubuntu_yazi_profile() {
      local yazi_dest_dir="$HOME/.config/yazi"
      prepare_real_dir "$yazi_dest_dir"
      link_path "$DOTFILES_DIR/profiles/yazi-ubuntu/yazi.toml" "$yazi_dest_dir/yazi.toml"
      link_path "$DOTFILES_DIR/profiles/yazi-ubuntu/shell.snippet.sh" "$HOME/.config/yazi-ubuntu-shell.sh"
  }

  link_ubuntu_bash_profile() {
      link_path "$DOTFILES_DIR/profiles/ubuntu-bash/bashrc.snippet.sh" "$HOME/.config/dotfiles-ubuntu-bash.sh"
      ensure_bashrc_source
  }

  link_ubuntu_tmux_profile() {
      local tmux_dest_dir="$HOME/.config/tmux"
      prepare_real_dir "$tmux_dest_dir"
      link_path "$DOTFILES_DIR/profiles/tmux-ubuntu/tmux.conf" "$tmux_dest_dir/tmux.conf"
  }

  # --- 1. 链接 Home 根目录下的文件 ---
  # 格式: "仓库中的文件名;目标链接路径"
  local root_files=(
      "gitconfig;~/.gitconfig"
  )

  if is_macos; then
      root_files+=("zshrc;~/.zshrc")
      root_files+=("zprofile;~/.zprofile")
      root_files+=("config/hammerspoon;~/.hammerspoon")
  fi

  echo -e "\n  Linking root files..."
  for file_pair in "${root_files[@]}"; do
      IFS=';' read -r src dest <<< "$file_pair"
      local src_path="$DOTFILES_DIR/$src"
      local dest_path="${dest/#\~/$HOME}"
      link_path "$src_path" "$dest_path"
  done

  # --- 2. 链接 .config 目录下的所有内容 ---
  local CONFIG_SRC_DIR="$DOTFILES_DIR/config"
  local CONFIG_DEST_DIR="$HOME/.config"
  mkdir -p "$CONFIG_DEST_DIR" # 确保 ~/.config 目录存在

  echo -e "\n  Linking .config files..."
  for item in "$CONFIG_SRC_DIR"/*; do
      local item_name=$(basename "$item")
      local src_path="$item"
      local dest_path="$CONFIG_DEST_DIR/$item_name"

      if is_linux && [ "$item_name" = "tmux" ]; then
          if should_link_linux_config "$item_name"; then
              link_ubuntu_tmux_profile
          else
              echo "    tmux not found. Skipping Ubuntu tmux profile."
          fi
          continue
      fi

      if is_linux && [ "$item_name" = "yazi" ]; then
          if should_link_linux_config "$item_name"; then
              link_ubuntu_yazi_profile
          else
              echo "    yazi not found. Skipping Ubuntu Yazi profile."
          fi
          continue
      fi

      if is_linux && ! should_link_linux_config "$item_name"; then
          echo "    $item_name not available or not Linux-safe. Skipping."
          continue
      fi

      link_path "$src_path" "$dest_path"
  done

  if is_linux; then
      link_ubuntu_bash_profile
  fi
  
  # --- 3. 仅部署 SSH 模板配置，不链接私钥文件 ---
  local SSH_TEMPLATE_PATH="$DOTFILES_DIR/ssh/config.example"
  local SSH_DEST_DIR="$HOME/.ssh"
  local SSH_DEST_CONFIG="$SSH_DEST_DIR/config"

  if [ -f "$SSH_TEMPLATE_PATH" ]; then
    mkdir -p "$SSH_DEST_DIR" && chmod 700 "$SSH_DEST_DIR"
    echo -e "\n  Installing SSH config template..."

    if [ -e "$SSH_DEST_CONFIG" ]; then
      echo "    ~/.ssh/config already exists. Skipping template copy."
    else
      cp "$SSH_TEMPLATE_PATH" "$SSH_DEST_CONFIG"
      chmod 600 "$SSH_DEST_CONFIG"
      echo "    Copied template to ~/.ssh/config"
    fi
  fi

  echo -e "\n  ✅ Symlinking complete."
}


# ==============================================================================
# 主函数 (Main Function)
# ==============================================================================

main() {
  echo "🚀 Starting dotfiles setup..."
  
  # 推荐的执行顺序：先安装好工具和环境，再部署依赖这些工具的配置文件
  install_packages
  if is_macos; then
    install_zimfw
  fi
  link_dotfiles

  echo -e "\n🎉 All tasks complete! Please restart your shell or reload your shell config."
}

# --- 执行主函数 ---
main
