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


# --- 安装 Zim Zsh Framework ---
install_zimfw() {
  echo -e "\n››› Installing Zim Zsh Framework..."

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

  # --- 1. 链接 Home 根目录下的文件 ---
  # 格式: "仓库中的文件名;目标链接路径"
  local root_files=(
      "zshrc;~/.zshrc"
      "zprofile;~/.zprofile"
      "gitconfig;~/.gitconfig"
  )

  echo -e "\n  Linking root files..."
  for file_pair in "${root_files[@]}"; do
      IFS=';' read -r src dest <<< "$file_pair"
      local src_path="$DOTFILES_DIR/$src"
      local dest_path="${dest/#\~/$HOME}"
      
      if [ -L "$dest_path" ]; then
          echo "    Symlink already exists for $dest_path. Skipping."
          continue
      fi
      
      if [ -e "$dest_path" ]; then
          echo "    Backing up existing $dest_path to $dest_path.bak"
          mv "$dest_path" "$dest_path.bak"
      fi
      
      ln -s "$src_path" "$dest_path"
      echo "    Linked $src_path -> $dest_path"
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

      if [ -L "$dest_path" ]; then
          echo "    Symlink already exists for $dest_path. Skipping."
          continue
      fi

      if [ -e "$dest_path" ]; then
          echo "    Backing up existing $dest_path to $dest_path.bak"
          mv "$dest_path" "$dest_path.bak"
      fi

      ln -s "$src_path" "$dest_path"
      echo "    Linked $src_path -> $dest_path"
  done
  
  # --- 3. 链接 .ssh 目录下的安全文件 ---
  local SSH_SRC_DIR="$DOTFILES_DIR/ssh"
  local SSH_DEST_DIR="$HOME/.ssh"
  
  # 检查 ssh 源目录是否存在
  if [ -d "$SSH_SRC_DIR" ]; then
    mkdir -p "$SSH_DEST_DIR" && chmod 700 "$SSH_DEST_DIR"
    echo -e "\n  Linking .ssh files..."

    for item in "$SSH_SRC_DIR"/*; do
      local item_name=$(basename "$item")
      # 忽略 .gitignore 文件本身
      if [ "$item_name" == ".gitignore" ]; then
          continue
      fi

      local src_path="$item"
      local dest_path="$SSH_DEST_DIR/$item_name"

      if [ -L "$dest_path" ]; then
          echo "    Symlink already exists for $dest_path. Skipping."
          continue
      fi

      if [ -e "$dest_path" ]; then
          echo "    Backing up existing $dest_path to $dest_path.bak"
          mv "$dest_path" "$dest_path.bak"
      fi

      ln -s "$src_path" "$dest_path"
      echo "    Linked $src_path -> $dest_path"
    done
  fi
  
  echo -e "\n  ✅ Symlinking complete."
}


# ==============================================================================
# 主函数 (Main Function)
# ==============================================================================

main() {
  echo "🚀 Starting dotfiles setup..."
  
  # 推荐的执行顺序：先安装好工具和环境，再部署依赖这些工具的配置文件
  install_homebrew_packages
  install_zimfw
  link_dotfiles

  echo -e "\n🎉 All tasks complete! Please restart your shell or run 'source ~/.zshrc' for all changes to take effect."
}

# --- 执行主函数 ---
main
