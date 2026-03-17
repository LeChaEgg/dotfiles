# Ubuntu Yazi Profile

这是一份给 Ubuntu 服务器用的 Yazi 配置，不是桌面机配置的完整镜像。

目标：

- 保留常用浏览习惯
- 避免依赖 `nvim`、`eza`、`rich`、`ffmpeg`、`jq` 这类服务器上未必有的工具
- 不带会和新版 Yazi API 冲突的插件
- 便于复制到多台服务器

## 包含内容

- `yazi.toml`
  - 排序、显示、预览等基础行为
  - 编辑器默认走 `vim`
  - Linux 上 `open` 优先走 `xdg-open`，没有则回退到 `vim`
- `shell.snippet.sh`
  - `export EDITOR=vim`
  - `y()` 函数，退出 Yazi 后同步 shell 当前目录

## 推荐部署方式

只同步这个目录里的两个文件，不要把本机的 `config/yazi/` 整个搬过去。

服务器上目标路径：

- `~/.config/yazi/yazi.toml`
- `~/.config/yazi-ubuntu-shell.sh`

然后在 `~/.bashrc` 或 `~/.zshrc` 里加一行：

```bash
source ~/.config/yazi-ubuntu-shell.sh
```
