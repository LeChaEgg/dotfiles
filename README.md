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
- Ubuntu：用 `apt` 安装常用工具；Yazi 会额外尝试 `apt` 和 Snap
- macOS：链接 `zshrc`、`zprofile`、Hammerspoon、Karabiner 等配置
- Ubuntu：不安装 Zsh，不切换默认 shell，只给 bash 加一份轻量 alias
- 链接可用的 `~/.config/*` 配置；不可用的软件直接跳过
- Ubuntu 的 Yazi 使用 `profiles/yazi-ubuntu/` 精简配置
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

- `config/`：macOS 主配置，包含 nvim、tmux、yazi、zsh、starship 等
- `profiles/ubuntu-bash/`：Ubuntu bash alias 和工具初始化
- `profiles/tmux-ubuntu/`：Ubuntu tmux 配置
- `profiles/yazi-ubuntu/`：Ubuntu/服务器用的 Yazi 配置
- `ssh/config.example`：SSH 配置模板
- `install.sh`：安装和软链接脚本
- `HANDBOOK.md`：更细的使用说明和快捷键索引

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
