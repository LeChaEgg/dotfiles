# Dotfiles

个人 macOS 开发环境配置仓库，用于在新机器上快速恢复常用终端与编辑器环境。

## 适用场景

- 新电脑初始化：一次安装常用工具并挂载配置
- 日常迭代：本机改配置后可直接通过 Git 管理变更
- 公共仓库托管：保留可公开配置，排除敏感或机器本地数据

## 核心逻辑

- 这个仓库是配置的“真实文件位置（source of truth）”
- `install.sh` 会把 `~/.zshrc`、`~/.zprofile`、`~/.gitconfig` 以及 `~/.config/*` 链接到本仓库对应文件
- 所以你在 `~/.config/...` 修改时，本质是在改 repo 里的文件，`git status` 会看到改动
- `~/.ssh` 不做软链接，只在缺失时从模板复制 `ssh/config.example` 到本地 `~/.ssh/config`

更完整的日常使用说明、快捷键速查和“改哪里”的索引见 [HANDBOOK.md](./HANDBOOK.md)。

## 快速开始

1. 克隆仓库到本地（建议 `~/dotfiles`）
2. 执行：

```bash
cd ~/dotfiles
bash install.sh
```

3. 重启 shell，或执行：

```bash
source ~/.zshrc
```

## 日常更新流程

1. 正常使用软件并调整配置
2. 查看变更：

```bash
git status
```

3. 提交并推送：

```bash
git add -A
git commit -m "chore: update dotfiles"
git push
```

## 安全与公开仓库约定

- 已忽略本地/敏感数据（见 `.gitignore`），例如：
  - `config/gh/hosts.yml`
  - `config/karabiner/automatic_backups/`
  - `config/iterm2/AppSupport`
  - `config/iterm2/sockets/`
- `ssh/` 目录只保留模板文件，不存私钥、`known_hosts`、真实主机信息
- 若新增新软件配置，先确认是否包含 token、账号、机器路径，再决定是否纳入版本管理

## 主要目录

- `config/`：各软件配置（nvim、tmux、yazi、karabiner 等）
- `zshrc` / `zprofile` / `gitconfig`：用户级基础配置
- `ssh/config.example`：SSH 模板
- `install.sh`：初始化安装与软链接脚本
