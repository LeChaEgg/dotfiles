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

- macOS：用 Homebrew 安装常用 CLI 工具和字体
- macOS：安装 Hammerspoon、Karabiner Elements 等配置对应的软件
- macOS：安装 Tinycast、Vorssaint，并恢复它们的可迁移配置
- Ubuntu：用 `apt` 安装常用工具
- macOS：链接 `zshrc`、`zprofile`、Hammerspoon、Karabiner 等配置
- Ubuntu：不安装 Zsh，不切换默认 shell，只给 bash 加一份轻量 alias
- 链接可用的 `~/.config/*` 配置；不可用的软件直接跳过
- Ubuntu 的 tmux 使用 `profiles/tmux-ubuntu/` 精简配置
- macOS 默认使用 `~/.global-env` 作为日常 Python 虚拟环境（需先创建）
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

macOS 安装 `uv` 后创建一次共享环境：

```bash
uv venv ~/.global-env
source ~/.zshrc
uv pip install <包名>
```

打开新终端后会自动进入该环境。进入项目自己的 `.venv` 后，配置会保留项目环境。

## 注意

不要提交私钥、token、真实主机信息或机器本地缓存。新增配置前先看一眼 `.gitignore`。
