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

# --- 记录失败的步骤，最后统一汇总 ---
FAILED_STEPS=()

# 运行一个步骤；失败只记录，不中断后面的步骤
run_step() {
  local label="$1"
  shift
  if ! "$@"; then
    FAILED_STEPS+=("$label")
  fi
}

# --- 让 sudo 在整个安装过程中保持有效（只问一次密码）---
SUDO_KEEPALIVE_PID=""
start_sudo_keepalive() {
  if [ ! -t 0 ] || ! command -v sudo &> /dev/null; then
    return 0
  fi

  echo "››› Some steps need administrator access. You may be asked for your password once."
  if ! sudo -v; then
    echo "  sudo unavailable; steps that need it will be skipped."
    return 0
  fi

  ( while true; do sudo -n true 2> /dev/null || exit; sleep 50; done ) &
  SUDO_KEEPALIVE_PID=$!
  trap 'stop_sudo_keepalive' EXIT
}

stop_sudo_keepalive() {
  if [ -n "$SUDO_KEEPALIVE_PID" ]; then
    kill "$SUDO_KEEPALIVE_PID" &> /dev/null || true
    SUDO_KEEPALIVE_PID=""
  fi
}

# --- macOS: Xcode Command Line Tools（git / clang 等，Homebrew 依赖它）---
ensure_xcode_clt() {
  if xcode-select -p &> /dev/null; then
    return 0
  fi

  echo -e "\n››› Installing Xcode Command Line Tools..."
  # 通过 softwareupdate 无交互安装，避免弹出 GUI 窗口
  local marker="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  touch "$marker"
  local label
  label="$(softwareupdate -l 2> /dev/null | grep -E '^\* Label: Command Line Tools' | sed 's/^\* Label: //' | sort -V | tail -n 1)"
  if [ -n "$label" ]; then
    sudo softwareupdate -i "$label" --verbose
  fi
  rm -f "$marker"

  if ! xcode-select -p &> /dev/null; then
    echo "  Falling back to the GUI installer. Finish it, then re-run this script."
    xcode-select --install
    return 1
  fi
}

# --- macOS: Homebrew 本体 ---
load_homebrew_env() {
  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$brew_bin" ]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done
  return 1
}

ensure_homebrew() {
  load_homebrew_env || true
  if command -v brew &> /dev/null; then
    return 0
  fi

  echo -e "\n››› Installing Homebrew..."
  if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    echo "  ❌ Homebrew installation failed."
    return 1
  fi

  load_homebrew_env
}


# --- 安装 Homebrew 软件包和字体 ---
install_homebrew_packages() {
  echo -e "\n››› Installing Homebrew packages..."

  if ! ensure_homebrew; then
    echo "  Homebrew is unavailable. Skipping package installation."
    return 1
  fi

  if ! brew bundle --help &> /dev/null; then
    echo "  Homebrew Bundle is unavailable. Skipping package installation."
    return 1
  fi

  local brewfile="$DOTFILES_DIR/Brewfile"
  if [ ! -f "$brewfile" ]; then
    echo "  Brewfile not found: $brewfile"
    return 1
  fi

  # 较新的 Homebrew 需要先信任第三方 tap；旧版本没有 `brew trust`，直接跳过
  if grep -Eq '^[[:space:]]*tap "abue-ammar/tinycast"' "$brewfile" && brew trust --help &> /dev/null; then
    echo "  Trusting the Tinycast Homebrew tap..."
    if ! brew trust --tap abue-ammar/tinycast; then
      echo "  ❌ Could not trust the Tinycast Homebrew tap."
      return 1
    fi
  fi

  echo "  Installing packages from $brewfile"
  if ! brew bundle install --file="$brewfile"; then
    echo "  ❌ Homebrew package installation failed."
    return 1
  fi

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
    ffmpeg
    p7zip-full
    jq
    poppler-utils
    fd-find
    ripgrep
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

  prepare_hammerspoon_local_config() {
      local config_path="$DOTFILES_DIR/config/hammerspoon/config.lua"
      local example_path="$DOTFILES_DIR/config/hammerspoon/config.example.lua"

      if [ -f "$config_path" ]; then
          return
      fi

      if [ -f "$example_path" ]; then
          cp "$example_path" "$config_path"
          echo "    Created local Hammerspoon config: $config_path"
          echo "    Edit it before enabling Wi-Fi or Tailscale automation."
      fi
  }

  install_tinycast_config() {
      local source_dir="$DOTFILES_DIR/macos/tinycast/Snippets"
      local app_support="$HOME/Library/Application Support/com.tinycast.app"
      local quicklinks_sql="$DOTFILES_DIR/macos/tinycast/quicklinks.sql"
      local settings_script="$DOTFILES_DIR/macos/tinycast/apply-settings.sh"

      if [ ! -d "$source_dir" ]; then
          return
      fi

      if pgrep -x "Tinycast" &> /dev/null; then
          echo "    Tinycast is running; skipped config sync. Re-run after quitting it."
          return
      fi

      mkdir -p "$app_support"
      link_path "$source_dir" "$app_support/Snippets"

      if command -v sqlite3 &> /dev/null && [ -f "$quicklinks_sql" ]; then
          sqlite3 "$app_support/quicklinks.sqlite3" < "$quicklinks_sql"
          echo "    Synced Tinycast quicklinks."
      fi

      if [ -x "$settings_script" ]; then
          "$settings_script"
          echo "    Applied tracked Tinycast preferences."
      fi
  }

  install_vorssaint_config() {
      local settings_script="$DOTFILES_DIR/macos/vorssaint/apply-settings.sh"

      if [ ! -x "$settings_script" ]; then
          return
      fi

      if pgrep -x "Vorssaint" &> /dev/null; then
          echo "    Vorssaint is running; skipped preference sync. Re-run after quitting it."
          return
      fi

      "$settings_script"
      echo "    Applied tracked Vorssaint preferences."
  }

  install_iterm2_config() {
      local settings_script="$DOTFILES_DIR/macos/iterm2/apply-settings.sh"

      if [ ! -x "$settings_script" ]; then
          return
      fi

      if pgrep -x "iTerm2" &> /dev/null; then
          echo "    iTerm2 is running; skipped preference sync. Re-run from another terminal after quitting it."
          return
      fi

      "$settings_script"
      echo "    Applied tracked iTerm2 preferences."
  }

  install_macos_app_configs() {
      install_tinycast_config
      install_vorssaint_config
      install_iterm2_config
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
          gh) command -v gh &> /dev/null ;;
          nvim) command -v nvim &> /dev/null ;;
          starship.toml) command -v starship &> /dev/null ;;
          tmux) command -v tmux &> /dev/null ;;
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

  link_ubuntu_bash_profile() {
      link_path "$DOTFILES_DIR/profiles/ubuntu-bash/bashrc.snippet.sh" "$HOME/.config/dotfiles-ubuntu-bash.sh"
      ensure_bashrc_source
  }

  link_ubuntu_tmux_profile() {
      local tmux_dest_dir="$HOME/.config/tmux"
      prepare_real_dir "$tmux_dest_dir"
      link_path "$DOTFILES_DIR/profiles/tmux-ubuntu/tmux.conf" "$tmux_dest_dir/tmux.conf"
      link_path "$DOTFILES_DIR/profiles/tmux-ubuntu/tmux.conf" "$HOME/.tmux.conf"
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

  if is_macos; then
      prepare_hammerspoon_local_config
      install_macos_app_configs
  fi

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
# 配置文件链接之后的环境初始化 (Post-link environment setup)
# ==============================================================================

# --- 日常 Python 环境：~/.global-env ---
setup_python_env() {
  echo -e "\n››› Setting up the shared Python environment (~/.global-env)..."

  if ! command -v uv &> /dev/null; then
    echo "  uv not found. Skipping."
    return 1
  fi

  local env_dir="$HOME/.global-env"
  if [ ! -f "$env_dir/bin/activate" ]; then
    uv venv --python 3.13 "$env_dir" || return 1
  else
    echo "  $env_dir already exists."
  fi

  local requirements="$DOTFILES_DIR/python/global-requirements.txt"
  if [ -f "$requirements" ]; then
    uv pip install --python "$env_dir/bin/python" -r "$requirements" || return 1
  fi

  echo "  ✅ Python environment ready."
}

# --- tmux：TPM、插件，以及 tmux-thumbs 的本地编译 ---
setup_tmux() {
  echo -e "\n››› Setting up tmux plugins..."

  if ! command -v tmux &> /dev/null; then
    echo "  tmux not found. Skipping."
    return 0
  fi

  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ ! -d "$tpm_dir" ]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" || return 1
  fi

  "$tpm_dir/bin/install_plugins" || return 1

  # tmux-thumbs 在 Apple Silicon 上没有预编译二进制，需要用 rustup 编译
  local thumbs_dir="$HOME/.tmux/plugins/tmux-thumbs"
  if [ -d "$thumbs_dir" ] && [ ! -x "$thumbs_dir/target/release/thumbs" ]; then
    if is_macos && command -v brew &> /dev/null && [ -d "$(brew --prefix rustup 2> /dev/null)/bin" ]; then
      export PATH="$(brew --prefix rustup)/bin:$HOME/.cargo/bin:$PATH"
    fi

    if ! command -v rustup &> /dev/null && ! command -v cargo &> /dev/null; then
      echo "  rustup/cargo not found. Skipping tmux-thumbs build."
      return 1
    fi

    if command -v rustup &> /dev/null && ! rustup show active-toolchain &> /dev/null; then
      rustup default stable || return 1
    fi

    echo "  Compiling tmux-thumbs (this takes a minute)..."
    ( cd "$thumbs_dir" && cargo build --release --target-dir=target ) || return 1
  fi

  echo "  ✅ tmux plugins ready."
}

# --- Neovim：按 lazy-lock.json 还原插件，安装 treesitter 解析器和 LSP ---
setup_neovim() {
  echo -e "\n››› Setting up Neovim plugins, parsers and language servers..."

  if ! command -v nvim &> /dev/null; then
    echo "  nvim not found. Skipping."
    return 0
  fi

  # 1. 按 lazy-lock.json 安装插件
  nvim --headless "+Lazy! restore" +qa || return 1

  # 2. treesitter 解析器（需要 tree-sitter-cli 和 C 编译器）
  nvim --headless \
    '+lua local p = require("lazy.core.config").plugins["nvim-treesitter"]; local o = require("lazy.core.plugin").values(p, "opts", false); require("nvim-treesitter").install(o.languages):wait(600000)' \
    +qa || return 1

  # 3. Mason：LSP（lsp.lua 里 vim.lsp.enable 的那几个）
  nvim --headless \
    '+lua local r = require("mason-registry"); local want = { "pyright", "marksman", "lua-language-server" }; local queued = false; r.refresh(function() for _, n in ipairs(want) do local ok, pkg = pcall(r.get_package, n); if ok and not pkg:is_installed() then pkg:install() end end; queued = true end); vim.wait(600000, function() if not queued then return false end; for _, n in ipairs(want) do local ok, pkg = pcall(r.get_package, n); if ok and pkg:is_installing() then return false end end; return true end, 500)' \
    +qa || return 1

  echo "  ✅ Neovim ready."
}

# --- macOS 系统偏好 ---
apply_macos_defaults() {
  echo -e "\n››› Applying macOS system preferences..."
  "$DOTFILES_DIR/macos/system/defaults.sh"
}

# --- 无法脚本化的步骤：最后打印成清单 ---
print_manual_steps() {
  echo -e "\n››› Manual steps that cannot be automated:"
  if is_macos; then
    cat << 'EOF'
  1. System Settings → Privacy & Security:
       Accessibility:      Hammerspoon, Karabiner-Elements, Tinycast, Vorssaint
       Input Monitoring:   Karabiner-Elements, Karabiner-EventViewer
       Location Services:  Hammerspoon (only for the Wi-Fi automation)
     Karabiner also asks you to allow its system/driver extension.
  2. Log out and back in once so input sources and keyboard shortcuts apply.
  3. Log in:
       gh auth login
       Tailscale (accounts used by the Hammerspoon module)
  4. Restore secrets that are intentionally not in this repository:
       ~/.ssh keys (a config template was copied only if none existed)
       ~/.private (environment variables)
       ~/.config/zsh/aliases.local, ~/.config/zsh/paths.local (if you use them)
       ~/.hammerspoon/config.lua (Wi-Fi / Tailscale accounts; starts disabled)
       Tinycast AI connection (use Tinycast's own Backup export)
  5. Open a new iTerm2 window; pick up the font "JetBrainsMono Nerd Font" if prompted.
EOF
  else
    echo "  Restart your shell, then run: gh auth login"
  fi
}


# ==============================================================================
# 主函数 (Main Function)
# ==============================================================================

main() {
  echo "🚀 Starting dotfiles setup..."

  if is_macos; then
    start_sudo_keepalive
    run_step "Xcode Command Line Tools" ensure_xcode_clt
  fi

  # 推荐的执行顺序：先安装好工具和环境，再部署依赖这些工具的配置文件
  run_step "Package installation" install_packages
  run_step "Dotfile linking" link_dotfiles

  if is_macos; then
    # 后续步骤依赖 brew 装好的 uv / tmux / nvim
    load_homebrew_env || true
    run_step "Python environment" setup_python_env
    run_step "tmux plugins" setup_tmux
    run_step "Neovim setup" setup_neovim
    run_step "macOS system preferences" apply_macos_defaults
  fi

  print_manual_steps

  if [ "${#FAILED_STEPS[@]}" -gt 0 ]; then
    echo -e "\n⚠️  Finished, but these steps failed (see output above; the script is safe to re-run):"
    printf '   - %s\n' "${FAILED_STEPS[@]}"
    exit 1
  fi

  echo -e "\n🎉 All tasks complete! Please restart your shell or reload your shell config."
}

# --- 执行主函数 ---
main
