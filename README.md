# Dotfiles

我的终端和常用开发工具配置。

主要给 macOS 用；Ubuntu 只装常用命令行工具，并沿用默认 bash。

## 安装

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
bash install.sh
```

macOS 装完重开终端，或执行：

```bash
source ~/.zshrc
```

Ubuntu 装完重开终端，或执行：

```bash
source ~/.bashrc
```

## 脚本会做什么

macOS 上 `bash install.sh` 依次执行（每步失败只记录，不影响后面的步骤，可重复运行）：

1. 安装 Xcode Command Line Tools 和 Homebrew（如果还没有）
2. `brew bundle`：CLI 工具、字体，以及 iTerm2、Hammerspoon、Karabiner Elements、Tinycast、Vorssaint
3. 链接 `zshrc`、`zprofile`、`~/.config/*`、Hammerspoon 等配置
4. 恢复 Tinycast、Vorssaint、iTerm2 的可迁移偏好
5. 创建 `~/.global-env`，并安装 `python/global-requirements.txt` 里的包
6. 克隆 TPM、安装 tmux 插件，并编译 tmux-thumbs
7. 按 `lazy-lock.json` 还原 Neovim 插件，安装 treesitter 解析器和 LSP（pyright、marksman、lua-language-server）
8. 应用 macOS 系统偏好（`macos/system/defaults.sh`）
9. 打印无法自动化的手动步骤（权限授权、登录、密钥）

其他：

- Ubuntu：用 `apt` 安装常用工具
- macOS：链接 `zshrc`、`zprofile`、Hammerspoon、Karabiner 等配置
- Ubuntu：不安装 Zsh，不切换默认 shell，只给 bash 加一份轻量 alias
- 链接可用的 `~/.config/*` 配置；不可用的软件直接跳过
- Ubuntu 的 tmux 使用 `profiles/tmux-ubuntu/` 精简配置
- macOS 默认使用 `~/.global-env` 作为日常 Python 虚拟环境（安装脚本会创建）
- `~/.ssh/config` 只在不存在时从模板复制，不链接私钥

## 日常怎么改

这个仓库就是配置文件本体。比如改 `~/.config/nvim`，实际改到的就是这里的 `config/nvim`。

常用流程：

```bash
git status
git add -A
git commit -m "chore: update dotfiles"
git push
```

## 目录

- `config/`：macOS 主配置，包含 nvim、tmux、zsh、starship 等
- `Brewfile`：macOS 基础工具和配置依赖清单
- `macos/tinycast/`：Tinycast 的 snippets、quicklinks 和安全偏好
- `macos/vorssaint/`：Vorssaint 的安全偏好恢复脚本
- `macos/iterm2/`：iTerm2 的 profile、快捷键等可迁移偏好
- `macos/system/`：macOS 系统偏好（`defaults.sh`）和键盘快捷键（`symbolichotkeys.plist`）
- `python/`：`~/.global-env` 的依赖清单
- `profiles/ubuntu-bash/`：Ubuntu bash alias 和工具初始化
- `profiles/tmux-ubuntu/`：Ubuntu tmux 配置
- `ssh/config.example`：SSH 配置模板
- `install.sh`：安装和软链接脚本
- `HANDBOOK.md`：更细的使用说明和快捷键索引

Hammerspoon 的 Wi‑Fi 和 Tailscale 账号配置放在本地的
`config/hammerspoon/config.lua`，不会提交到 Git。首次安装时脚本会从
`config.example.lua` 创建一个禁用状态的模板；需要时再编辑它。

Tinycast 和 Vorssaint 的安全配置会在 macOS 安装时自动恢复；AI 登录、剪贴板历史、
截图、扩展数据和机器相关显示路径不会进入仓库。

## 日常 Python 环境

安装脚本会创建 `~/.global-env` 并装好 `python/global-requirements.txt` 里的包。之后要加包：

```bash
uv pip install <包名>
```

想让新机器也带上，就把包名加进 `python/global-requirements.txt`。打开新终端后会自动进入该环境。
进入项目自己的 `.venv` 后，配置会保留项目环境。

## 系统偏好

`macos/system/defaults.sh` 恢复触控板、Dock、Finder、菜单栏时钟、输入法、键盘快捷键、
Touch ID sudo、电源设置。想先看会改什么：

```bash
DRY_RUN=1 macos/system/defaults.sh
```

Dock 里的 App 列表、壁纸、显示器布局、Control Center 图标位置等机器相关内容不会带走。

## 需要手动做的事

脚本结束时会打印清单，主要是：系统设置里给 Hammerspoon、Karabiner、Tinycast、Vorssaint
授予辅助功能/输入监控权限；`gh auth login`；恢复 SSH 密钥和 `~/.private`；
重新登录一次让输入法和快捷键生效。

## 注意

不要提交私钥、token、真实主机信息或机器本地缓存。新增配置前先看一眼 `.gitignore`。
