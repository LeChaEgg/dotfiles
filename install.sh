#!/bin/bash

# 获取脚本所在的目录 (dotfiles 仓库的根目录)
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Symlinking dotfiles from $DOTFILES_DIR"

# --- 1. 链接 Home 根目录下的文件 ---
# 格式: "仓库中的文件名;目标链接路径"
root_files=(
    "zshrc;~/.zshrc"
    "zprofile;~/.zprofile"
    "gitconfig;~/.gitconfig"
    # 如果有其他根目录文件，在这里添加
)

echo -e "\nLinking root files..."
for file_pair in "${root_files[@]}"; do
    IFS=';' read -r src dest <<< "$file_pair"
    src_path="$DOTFILES_DIR/$src"
    dest_path="${dest/#\~/$HOME}"
    
    if [ -L "$dest_path" ]; then
        echo "Symlink already exists for $dest_path. Skipping."
        continue
    fi
    
    if [ -e "$dest_path" ]; then
        echo "Backing up existing $dest_path to $dest_path.bak"
        mv "$dest_path" "$dest_path.bak"
    fi
    
    ln -s "$src_path" "$dest_path"
    echo "Linked $src_path -> $dest_path"
done


# --- 2. 链接 .config 目录下的所有内容 ---
CONFIG_SRC_DIR="$DOTFILES_DIR/config"
CONFIG_DEST_DIR="$HOME/.config"

mkdir -p "$CONFIG_DEST_DIR" # 确保 ~/.config 目录存在

echo -e "\nLinking .config files..."
for item in "$CONFIG_SRC_DIR"/*; do
    item_name=$(basename "$item")
    src_path="$item"
    dest_path="$CONFIG_DEST_DIR/$item_name"

    if [ -L "$dest_path" ]; then
        echo "Symlink already exists for $dest_path. Skipping."
        continue
    fi

    if [ -e "$dest_path" ]; then
        echo "Backing up existing $dest_path to $dest_path.bak"
        mv "$dest_path" "$dest_path.bak"
    fi

    ln -s "$src_path" "$dest_path"
    echo "Linked $src_path -> $dest_path"
done

echo -e "\n✅ Dotfiles symlinking complete."
