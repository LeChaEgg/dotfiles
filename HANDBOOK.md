# Dotfiles Handbook

这份文档补充 `README.md`，目标不是解释“仓库是什么”，而是回答下面这些日常问题：

- 这个仓库到底管了哪些软件？
- 某个行为是在哪个配置文件里定义的？
- 常用快捷键是什么？
- 忘了怎么操作时，应该先看哪里？

## 1. 配置是怎么生效的

这个仓库的核心原则很简单：repo 里的文件就是 source of truth。

- `install.sh` 会把 `zshrc`、`zprofile`、`gitconfig` 链接到 home 目录。
- `config/` 下的内容会被整体链接到 `~/.config/`。
- 所以你平时改 `~/.config/...`，本质上就是在改这个仓库里的文件。
- `ssh/config.example` 不会被软链接，只会在本地缺失时复制成 `~/.ssh/config` 模板。

最常用的装载链路如下：

1. login shell 先读 `zprofile`
2. interactive zsh 再读 `zshrc`
3. `zshrc` 继续加载：
   - `config/zsh/aliases`
   - `config/zsh/fzf.zsh`
   - `config/zim/zimrc`
   - `config/starship.toml`

## 2. 软件总览

| 软件 | 主要用途 | 主要配置文件 | 你最常会改什么 |
| --- | --- | --- | --- |
| Zsh | shell 本体 | `zshrc`, `zprofile` | 环境变量、启动加载顺序 |
| Zim | zsh 插件管理 | `config/zim/zimrc` | autosuggestion、completion、zoxide、starship |
| Starship | prompt | `config/starship.toml` | 提示符显示内容 |
| Aliases | 命令别名 | `config/zsh/aliases` | 日常快捷命令 |
| fzf | 模糊搜索/补全 | `config/zsh/fzf.zsh` | 搜索体验 |
| tmux | 终端分屏/会话管理 | `config/tmux/tmux.conf` | 分屏、切 pane、窗口管理 |
| Neovim | 编辑器 | `config/nvim/` | 快捷键、插件、LSP |
| Yazi | 终端文件管理器 | `config/yazi/` | 键位、预览器、插件 |
| gh | GitHub CLI | `config/gh/config.yml` | gh aliases |
| Git | Git 用户级设置 | `gitconfig` | 用户名、邮箱、默认编辑器 |
| Ghostty | 第三方终端 | `config/ghostty/config` | 字体、快速终端、标题栏 |
| Karabiner | 键盘改键 | `config/karabiner/` | Hyper、语言切换、窗口管理 |
| btop | 系统监控 | `config/btop/btop.conf` | 界面布局、颜色、采样行为 |
| SSH | SSH 模板 | `ssh/config.example` | Host 模板、代理、认证方式 |

## 3. Shell：Zsh / Zim / Starship / Aliases

### 3.1 入口文件怎么分工

- `zprofile`
  - 放 login shell 环境准备，例如 Homebrew、OrbStack、pipx PATH。
- `zshrc`
  - 放交互式 shell 行为。
  - 会加载 alias、fzf、私有环境变量、Zim、Yazi wrapper、gcloud PATH 等。
- `config/zim/zimrc`
  - 管理 Zim 模块，比如 completion、autosuggestions、zoxide、starship。
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
| 上一个/下一个窗口 | `Ctrl-[` / `Ctrl-]` |
| 打开 session/window 树 | `Ctrl-s` |

### 4.3 prefix 和其他说明

- tmux prefix 被改成了 `Ctrl-Space`
- reload 配置：`prefix` 后按 `r`
- 鼠标已开启，可以直接点 pane、滚动、选中
- pane/window 编号从 1 开始

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

## 6. Yazi 速查

Yazi 是你的终端文件管理器，配置在 `config/yazi/`。

如果是 Ubuntu 服务器，不要直接照搬 `config/yazi/`；仓库里单独提供了一份更保守的服务器版 profile：`profiles/yazi-ubuntu/`。

### 6.1 最重要的启动方式

不要只记 `yazi`，更推荐记 `y`。

在 `zshrc` 里定义了一个 `y()` 函数，它会在你退出 Yazi 后把 shell 当前目录同步到你最后停留的目录。也就是说：

- `y`
  - 打开 Yazi
  - 退出后 shell 会自动 `cd` 到你刚才浏览的位置

### 6.2 当前配置特点

- 默认显示隐藏文件
- 目录优先排序
- 按修改时间逆序
- 预览面板比例偏大
- Markdown / Python / JSON / CSV / Notebook 预览用了 `rich`
- 目录预览用了 `eza-preview`
- 集成了 Git 状态、书签、项目、相对跳转、starship

### 6.3 自定义快捷键

| 动作 | 快捷键 |
| --- | --- |
| 目录树/列表预览开关 | `E` |
| 增加/减少树深度 | `-` / `_` |
| 预览里显示/隐藏隐藏文件 | `*` |
| 预览里切换是否跟随软链接 | `$` |
| 智能进入目录或打开文件 | `l` |
| 在当前目录开 shell | `!` |
| 跳到字符 | `f` |
| 智能过滤 | `F` |
| 保存书签 | `m` |
| 跳到书签 | `'` |
| 删除书签 | `b d` |
| 保存项目 | `P s` |
| 加载项目 | `P l` |
| 加载上次项目 | `P P` |
| 删除项目 | `P d` |
| 1 到 9 相对跳转 | `1` 到 `9` |

### 6.4 忘了以后看哪里

- 键位：`config/yazi/keymap.toml`
- 插件初始化：`config/yazi/init.lua`
- 预览器/打开器：`config/yazi/yazi.toml`

## 7. Git / gh / SSH

### 7.1 Git

`gitconfig` 目前比较轻，只做了两件事：

- 设置用户信息
- 设置默认编辑器为 `nvim`

### 7.2 GitHub CLI

`config/gh/config.yml` 目前只有一个 alias：

- `gh co`
  - 等价于 `gh pr checkout`

### 7.3 SSH

`ssh/config.example` 是模板，不是最终线上配置。

用法建议：

1. 把模板复制成 `~/.ssh/config`
2. 把真实主机、用户名、域名只写在本地
3. 这个仓库里只保留：
   - 默认认证策略
   - Cloudflare tunnel 示例
   - Host 模板结构

## 8. Ghostty / Karabiner / btop

这几项不是每天必改，但属于“改了以后效果很明显”的配置。

### 8.1 Ghostty

`config/ghostty/config` 主要做了这些事：

- 使用 `JetBrainsMono Nerd Font`
- 字体大小 `15`
- titlebar 风格为 `tabs`
- `Option-t` 绑定全局 quick terminal
- `Cmd-.` 发送 `Ctrl-C`
- `Cmd-f` 导出 scrollback 文件并打开

如果你平时主要用系统 Terminal，这部分可以先忽略。

### 8.2 Karabiner

`config/karabiner/karabiner.json` 和 `assets/complex_modifications/` 里能看出当前主要在做：

- `Right Command + e/c/j` 切换英文 / 中文 / 日文
- `Left Shift` 双击触发 `Option-t`
- `Fn` 映射为 Hyper 组合键
- 按住 `Space` 进入 SpaceFN / Hyper 风格导航
- 通过 Hyper 组合做 1/4 窗口管理

如果你经常忘，优先去看：

- `config/karabiner/karabiner.json`
- `config/karabiner/assets/complex_modifications/`

### 8.3 btop

`config/btop/btop.conf` 主要是界面与显示偏好：

- 开启 truecolor
- 圆角面板
- 图表符号偏好为 `braille`
- 电池显示开启
- 网络自动缩放开启

这个配置偏“开箱即用”，一般不需要高频修改。

## 9. 依赖与常见坑

`install.sh` 会安装一批常用工具，但不是所有配置依赖都自动安装了。

你现在这套配置中，下面这些命令被引用了，但不一定会被自动装上：

- `tmux`
- `gh`
- `bat`
- `lazygit`
- `screen`
- `docker` / `docker compose`
- `mpv`
- `mediainfo`
- `exiftool`
- `cloudflared`

如果你发现 alias 存在但命令不可用，先检查是不是工具本体没安装。

## 10. 忘了时的最短路径

如果你只是忘了某个操作，不想翻完整文档，可以按下面顺序找：

1. Shell/命令问题：看 `config/zsh/aliases`
2. 分屏/会话问题：看 `config/tmux/tmux.conf`
3. 编辑器快捷键：看 `config/nvim/lua/custom/keymaps.lua`
4. 文件管理快捷键：看 `config/yazi/keymap.toml`
5. 键盘改键：看 `config/karabiner/karabiner.json`
6. 不确定入口文件：回来看本手册第 2 节的软件总览

## 11. 建议的后续维护方式

为了避免以后又忘，建议继续按下面的方式维护：

- README 只保留仓库定位、安装、原则
- `HANDBOOK.md` 专门放使用说明和速查表
- 每次改快捷键时，顺手同步更新对应章节
- 如果某个软件已经不用了，就把对应章节删掉，不要让文档比配置更“老”
