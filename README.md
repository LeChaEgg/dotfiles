# Dotfiles

我的终端和常用开发工具配置。

主要给 macOS 用；Ubuntu 也可以跑，脚本会跳过不可用的软件和 macOS 专用配置。

## 安装

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
bash install.sh
```

装完重开终端，或执行：

```bash
source ~/.zshrc
```

## 脚本会做什么

- macOS：用 Homebrew 安装常用 CLI 工具和字体
- Ubuntu：用 `apt` 安装能找到的工具，找不到就跳过
- 链接 `zshrc`、`zprofile`、`gitconfig`
- 链接可用的 `~/.config/*` 配置
- macOS 才链接 Hammerspoon、Karabiner 等桌面配置
- Ubuntu 的 Yazi 使用 `profiles/yazi-ubuntu/` 精简配置
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

- `config/`：nvim、tmux、yazi、zsh、starship 等配置
- `profiles/yazi-ubuntu/`：Ubuntu/服务器用的 Yazi 配置
- `ssh/config.example`：SSH 配置模板
- `install.sh`：安装和软链接脚本
- `HANDBOOK.md`：更细的使用说明和快捷键索引

## 注意

不要提交私钥、token、真实主机信息或机器本地缓存。新增配置前先看一眼 `.gitignore`。
