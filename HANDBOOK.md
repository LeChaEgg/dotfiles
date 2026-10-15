# Dotfiles Handbook

这份文档补充 `README.md`，目标不是解释“仓库是什么”，而是回答下面这些日常问题：

- 这个仓库到底管了哪些软件？
- 某个行为是在哪个配置文件里定义的？
- 常用快捷键是什么？
- 忘了怎么操作时，应该先看哪里？

## 1. 配置是怎么生效的

这个仓库的核心原则很简单：repo 里的文件就是 source of truth。

- `install.sh` 会把 `zshrc`、`zprofile`、`gitconfig`、`config/hammerspoon` 链接到 home 目录。
- macOS 软件安装清单在根目录 `Brewfile`，避免把某台机器的全部 App 当成迁移依赖。
- `config/` 下的内容会被整体链接到 `~/.config/`。
- Karabiner Elements 由 `Brewfile` 安装，`config/karabiner` 会链接到 `~/.config/karabiner`。
- Tinycast、Vorssaint、iTerm2 的可迁移偏好由 `macos/` 下的脚本恢复。
- macOS 系统偏好（触控板、Dock、Finder、键盘快捷键、输入法、电源等）由 `macos/system/defaults.sh` 恢复。
- 所以你平时改 `~/.config/...`，本质上就是在改这个仓库里的文件。
- `ssh/config.example` 不会被软链接，只会在本地缺失时复制成 `~/.ssh/config` 模板。

最常用的装载链路如下：

1. login shell 先读 `zprofile`
2. interactive zsh 再读 `zshrc`
3. `zshrc` 继续加载：
   - `config/zsh/aliases`
   - `config/zsh/plugins.zsh`
   - `config/starship.toml`

## 2. 软件总览

| 软件 | 主要用途 | 主要配置文件 | 你最常会改什么 |
| --- | --- | --- | --- |
| Zsh | shell 本体 | `zshrc`, `zprofile` | 环境变量、启动加载顺序 |
| Starship | prompt | `config/starship.toml` | 提示符显示内容 |
| Aliases | 命令别名 | `config/zsh/aliases` | 日常快捷命令 |
| tmux | 终端分屏/会话管理 | `config/tmux/tmux.conf` | 分屏、切 pane、窗口管理 |
| Neovim | 编辑器 | `config/nvim/` | 快捷键、插件、LSP |
| gh | GitHub CLI | `config/gh/config.yml` | gh aliases |
| Git | Git 用户级设置 | `gitconfig` | 用户名、邮箱、默认编辑器 |
| iTerm2 | 终端 | `macos/iterm2/preferences.plist` | 配色、字体、快捷键、profile |
| Hammerspoon | macOS 自动化 | `config/hammerspoon/` | 输入法、Wi-Fi、Tailscale |
| Karabiner | 键盘改键 | `config/karabiner/` | Hyper、语言切换、窗口管理 |
| mactop | 系统监控 | `config/zsh/aliases` | `top` alias |
| SSH | SSH 模板 | `ssh/config.example` | Host 模板、代理、认证方式 |

## 3. Shell：Zsh / Starship / Aliases

### 3.1 入口文件怎么分工

- `zprofile`
  - 放 login shell 环境准备，例如 Homebrew、pipx PATH。
- `zshrc`
  - 放交互式 shell 行为。
  - 会加载 alias、私有环境变量和 repo 内保留的 Zsh 插件。
  - 如果没有其他虚拟环境，会自动加载 `~/.global-env`，用于日常 Python 小任务。
- `config/zsh/plugins.zsh`
  - 加载补全、autosuggestions、历史搜索和语法高亮插件。
- `config/starship.toml`
  - 管 prompt 外观。

### 3.2 常用 alias 速查

`config/zsh/aliases` 里主要分成几类：

- 文件浏览
  - `ls` / `l` / `ll` / `lh`
  - 如果系统有 `eza`，这些 alias 会优先走 `eza`
- 编辑器
  - `v` = `nvim`
  - `vo` = 左右并排打开
  - `vd` = diff 模式
- 工具
  - `p` = `python3`
  - `b` = `bat`
  - `rp` = `realpath`
- 资源查看
  - `listsize`
  - `dirsize`
  - `cpu`
  - `mem`
- tmux
  - `tm` = 附着或创建 `main` session
  - `tn` = 新建 `main` session
  - `ta` = attach
  - `tls` = `tmux ls`
- 导航
  - `cf` = 回到 `~/dotfiles`
  - `..` / `...` / `....` / `.....`
  - `zz` = `z -`
- Git
  - `gco`, `gcm`, `gg`, `gdiff`, `gpull`, `gpush`, `gbr`
- 配置编辑
  - `vv` = 打开 nvim 配置
  - `va` = 打开 alias 文件
  - `vs` = 打开 SSH 配置
  - `vt` = 打开 tmux 配置
- 重载
  - `sz` = `source ~/.zshrc`
  - `reload` = `exec zsh`

### 3.3 日常 Python 环境

macOS 上用 `uv` 创建一次共享环境即可：

```bash
uv venv ~/.global-env
source ~/.zshrc
uv pip install <包名>
```

项目已有 `.venv` 时，`zshrc` 不会覆盖它。

### 3.3 日常建议

- 改完 alias、Zsh、Starship 后，优先执行 `sz`。
- 如果 shell 状态有点乱，直接 `reload`。
- 想编辑这个 repo 本身，用 `cf` 快速回仓库。

## 4. tmux 速查

如果你用的是 macOS 自带 Terminal，分屏主要靠 tmux，不是靠 Terminal.app 本身。

### 4.1 怎么进入

- `tm`
  - 最推荐。存在 `main` session 就附着，不存在就创建。
- `tn`
  - 明确新建 `main` session。
- `ta`
  - 重新附着已有 session。

### 4.2 你当前配置里的常用快捷键

下面这些都不需要 prefix：

| 动作 | 快捷键 |
| --- | --- |
| 左右分屏 | `Ctrl-\` |
| 上下分屏 | `Ctrl--` |
| 切到左/下/上/右 pane | `Ctrl-h` / `Ctrl-j` / `Ctrl-k` / `Ctrl-l` |
| 调整 pane 大小 | `Shift + 方向键` |
| 关闭当前 pane | `Ctrl-w` |
| 把当前 pane 拆到新窗口 | `Ctrl-n` |
| 新建窗口 | `Ctrl-t` |
| 上一个/下一个窗口 | `Ctrl-Left` / `Ctrl-Right` |
| 打开 session/window 树 | `Ctrl-s` |

### 4.3 prefix 和其他说明

- tmux prefix 被改成了 `Ctrl-Space`
- reload 配置：`prefix` 后按 `r`
- 鼠标已开启，可以直接点 pane、滚动、选中
- pane/window 编号从 1 开始
- `Ctrl-[` 不再用于切窗口，因为终端里它和 `Esc` 是同一个输入
- `Ctrl-p` / `Ctrl-]` 仍保留为窗口切换 fallback
- 如果 `Ctrl-Left` / `Ctrl-Right` 没反应，先检查 macOS 的 Mission Control 里是否把它们占用为切换 Spaces

### 4.4 忘了以后看哪里

- 改快捷键：`config/tmux/tmux.conf`
- 进 tmux：`tm`
- 找配置：`vt`

## 5. Neovim 速查

Neovim 配置集中在 `config/nvim/`。

### 5.1 结构怎么分

- `config/nvim/init.lua`
  - 总入口，加载 options、keymaps、autocmd、LSP、lazy.nvim
- `config/nvim/lua/custom/options.lua`
  - 编辑器基础行为
- `config/nvim/lua/custom/keymaps.lua`
  - 你手写的核心快捷键
- `config/nvim/lua/custom/plugins/`
  - 各插件声明
- `config/nvim/lua/custom/config/`
  - 插件细项配置

### 5.2 最重要的约定

- `<leader>` 是空格
- 支持 Nerd Font
- `splitright` / `splitbelow` 打开
- 相对行号开启
- 系统剪贴板开启
- `autochdir` 开启

### 5.3 常用快捷键

| 动作 | 快捷键 |
| --- | --- |
| 插入模式返回普通模式 | `jk` |
| 进入命令模式 | `;` |
| 保存 | `S` |
| 退出 | `Q` |
| 清除搜索高亮 | `Esc` |
| 水平分屏 | `\` |
| 垂直分屏 | `|` |
| 窗口切换 | `Ctrl-h/j/k/l` |
| 当前窗口最大化 | `+` |
| 窗口均分 | `=` |
| 退出终端模式 | `Esc Esc` |
| 上下移动当前行/选区 | `<leader>k` / `<leader>j` |
| 打开诊断列表 | `<leader>q` |
| Quickfix 前后跳转 | `[q` / `]q` |
| 重新 source 当前文件 | `<leader>R` |

### 5.4 搜索和发现

因为装了 Telescope 和 which-key，忘了快捷键时优先这样查：

- `<leader>sk` 搜 keymaps
- `<leader>sf` 搜文件
- `<leader>sg` 全局 grep
- `<leader><leader>` 查 buffer

## 6. Git / gh / SSH

### 6.1 Git

`gitconfig` 目前比较轻，只做了两件事：

- 设置用户信息
- 设置默认编辑器为 `nvim`

### 6.2 GitHub CLI

`config/gh/config.yml` 目前只有一个 alias：

- `gh co`
  - 等价于 `gh pr checkout`

### 6.3 SSH

`ssh/config.example` 是模板，不是最终线上配置。

用法建议：

1. 把模板复制成 `~/.ssh/config`
2. 把真实主机、用户名、域名只写在本地
3. 这个仓库里只保留：
   - 默认认证策略
   - Cloudflare tunnel 示例
   - Host 模板结构

## 7. iTerm2 / Karabiner / Hammerspoon / 系统监控

这几项不是每天必改，但属于“改了以后效果很明显”的配置。

### 7.1 iTerm2

iTerm2 的偏好保存在 macOS 的 `defaults` 里，不是普通配置文件。仓库里只跟踪可迁移的部分：

- `macos/iterm2/preferences.plist`：profile（字体、配色、透明度）、全局快捷键、鼠标手势、标签栏/分屏行为
- `macos/iterm2/apply-settings.sh`：把上面的内容合并进 iTerm2 当前偏好；AI 设置、窗口位置、更新状态等机器本地项不会被覆盖

安装脚本会在 iTerm2 未运行时自动执行它。如果在 iTerm2 里改了设置，想存回仓库，需要重新导出对应的键
（做法见 `apply-settings.sh` 和 `preferences.plist` 里的键名）。

### 7.2 Karabiner

`config/karabiner/karabiner.json` 和 `assets/complex_modifications/` 里能看出当前主要在做：

- `Right Command + e/c/j` 切换英文 / 中文 / 日文
- `Left Shift` 双击触发 `Option-t`
- `Fn` 映射为 Hyper 组合键
- 按住 `Space` 进入 SpaceFN / Hyper 风格导航
- 通过 Hyper 组合做 1/4 窗口管理

如果你经常忘，优先去看：

- `config/karabiner/karabiner.json`
- `config/karabiner/assets/complex_modifications/`

安装脚本会自动安装 Karabiner Elements 并同步当前 `karabiner.json`。首次运行时，
Karabiner 仍需要在系统设置里重新授予输入监控/辅助功能权限；这些权限不属于配置文件。

### 7.3 Hammerspoon

Hammerspoon 入口是 `config/hammerspoon/init.lua`，功能拆在：

- `modules/input_source.lua`：按 App 记忆和切换输入法，需要 `macism`
- `modules/wifi.lua`：指定 SSID 使用静态网络配置，其他 Wi-Fi 使用 DHCP
- `modules/tailscale.lua`：按时间切换两个 Tailscale 账号

设备和账号相关配置只放在 `config/hammerspoon/config.lua`。它已被 Git 忽略，
模板是 `config/hammerspoon/config.example.lua`。新机器上先复制并编辑模板，
再打开 Hammerspoon。

额外要求：

- Hammerspoon 需要辅助功能/自动化权限；Wi-Fi SSID 读取可能需要定位服务权限
- Wi-Fi 静态配置默认通过 `sudo -n networksetup` 执行，需要配置免密码 sudo 规则
- Tailscale 两个账号必须已经在 CLI 中登录；当前只按 Apple Silicon Homebrew 路径查找
- Hammerspoon 重载后，输入法记忆和 Tailscale 日期状态保存在 Hammerspoon settings 中，
  不属于仓库配置

### 7.4 系统监控

安装 `mactop` 后，`top` 命令会映射到它。

## 8. 依赖与常见坑

macOS 的 `install.sh` 会安装配置直接依赖的常用工具，包括 `bat`、`gh`、
`lazygit`、`macism`、`tmux`、`mactop` 和 `uv`，以及 Hammerspoon、Karabiner Elements、
Tinycast、Vorssaint。

下面这些仍然是按需安装或需要登录/初始化的外部状态：

- `tailscale`
- `docker` / `docker compose` / OrbStack
- `mpv`
- `mediainfo`
- `exiftool`
- `cloudflared`

Tinycast 的仓库配置位于 `macos/tinycast/`；其中 `Snippets/` 是软链接到应用数据目录，
因此日常新增 snippet 会直接回到 repo。完整 Tinycast Backup 可能包含剪贴板、截图或登录信息，
请放在仓库外保存。

Vorssaint 的配置脚本只恢复可迁移偏好；显示器 IO 路径、窗口尺寸、更新状态和 token 不恢复。

如果 alias 存在但命令不可用，先检查工具本体和当前机器架构是否正确。

## 9. 忘了时的最短路径

如果你只是忘了某个操作，不想翻完整文档，可以按下面顺序找：

1. Shell/命令问题：看 `config/zsh/aliases`
2. 分屏/会话问题：看 `config/tmux/tmux.conf`
3. 编辑器快捷键：看 `config/nvim/lua/custom/keymaps.lua`
4. 键盘改键：看 `config/karabiner/karabiner.json`
5. 不确定入口文件：回来看本手册第 2 节的软件总览

## 10. 新 Mac 迁移清单

推荐顺序：

1. 在旧 Mac 上提交并推送 dotfiles 的最新改动，并做一次最新 Time Machine 备份。
2. 新 Mac 完成公司 MDM/账户设置后，用迁移助理导入个人账户和文件。
3. 克隆仓库并运行 `bash install.sh`，安装工具并建立软链接。
4. 检查 Tinycast 的 snippets/quicklinks，以及 Vorssaint 的偏好是否已恢复。
5. 从 `config/hammerspoon/config.example.lua` 创建本地配置，填入本机网络和账号信息。
6. 登录 Tailscale、GitHub CLI、Docker/OrbStack；授予 Hammerspoon、Karabiner 所需权限。
7. 检查 Homebrew、`macism`、Node/Python、Neovim、tmux 和 SSH，再删除或降权临时管理员。

不要把下面这些当作可直接提交的配置：

- `config/hammerspoon/config.lua`
- `~/.private`、SSH 私钥、`~/.ssh/known_hosts`
- Tailscale/GitHub/Docker 登录状态
- Homebrew 安装目录中的二进制文件

## 11. 建议的后续维护方式

为了避免以后又忘，建议继续按下面的方式维护：

- README 只保留仓库定位、安装、原则
- `HANDBOOK.md` 专门放使用说明和速查表
- 每次改快捷键时，顺手同步更新对应章节
- 如果某个软件已经不用了，就把对应章节删掉，不要让文档比配置更“老”
