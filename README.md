# 🚀 Kick Shell

一键初始化前端/全栈开发环境，支持 **macOS** 和 **CentOS**。

告别繁琐的环境配置，一条命令搞定所有开发工具的安装。

## ✨ Features

- **一键安装** — 执行一条命令，自动完成全部环境初始化
- **断点续装** — 自动检测已安装的工具，重复执行只安装缺失的部分
- **双系统支持** — 适配 macOS (含 Apple Silicon) 和 CentOS/RHEL 系列
- **彩色日志** — 清晰的安装进度提示，成功/失败/警告一目了然
- **前端/全栈优化** — 基于社区最佳实践，精选开发工具链

## 📦 安装的工具

| 工具 | macOS | CentOS | 说明 |
|------|:-----:|:------:|------|
| Xcode CLI Tools | ✅ | — | macOS 编译基础工具 |
| Homebrew | ✅ | ✅ (Linuxbrew) | 包管理器 |
| Git | ✅ | ✅ | 版本控制 (含全局配置) |
| Zsh | ✅ (自带) | ✅ | 现代化 Shell |
| Oh My Zsh | ✅ | ✅ | Zsh 配置框架 |
| zsh-autosuggestions | ✅ | ✅ | 命令自动建议插件 |
| zsh-syntax-highlighting | ✅ | ✅ | 命令语法高亮插件 |
| nvm (最新版) | ✅ | ✅ | Node.js 版本管理器 |
| Node.js LTS | ✅ | ✅ | JavaScript 运行时 |
| pnpm | ✅ | ✅ | 高效的包管理器 |
| yarn | ✅ | ✅ | 经典的包管理器 |
| Docker CLI | ✅ | ✅ | 容器化 CLI 工具 |
| VS Code `code` 命令 | ✅ | ✅ | 命令行打开 VS Code |

## 🚀 Quick Start

### 方式一：在线执行（推荐）

```bash
curl -o- https://raw.githubusercontent.com/CasoMemory/kick-shell/main/install.sh | bash
```

### 方式二：克隆后执行

```bash
git clone https://github.com/CasoMemory/kick-shell.git
cd kick-shell
bash install.sh
```

## ⚠️ Before Start

### macOS
请确保已安装 Xcode Command Line Tools（脚本会自动检测并安装）：
```bash
xcode-select --install
```

### CentOS
确保系统可以访问外网，且当前用户有 `sudo` 权限（或者以 root 身份运行）。

## 📁 项目结构

```
kick-shell/
├── install.sh              # 入口文件（执行此脚本）
├── lib/
│   ├── common.sh           # 公共函数库（日志、检测、通用安装）
│   ├── macos.sh            # macOS 专属安装逻辑
│   └── centos.sh           # CentOS 专属安装逻辑
├── configs/
│   └── .zshrc.template     # .zshrc 环境变量模板
├── shell.sh                # 向后兼容（重定向到 install.sh）
└── README.md
```

## 🔄 断点续装

脚本支持**安全重复执行**。每个工具安装前都会通过 `command -v` 检测是否已存在：
- 已安装的工具会显示 `[✔] xxx 已安装，跳过`
- 未安装的工具才会执行安装流程

如果安装中途失败，只需重新运行脚本，它会自动从失败的工具处继续。

## 🛠️ 自定义

### Git 配置
脚本运行时会交互式询问 Git 的 `user.name` 和 `user.email`。如果已配置过，会提示是否要重新配置。

同时会自动设置以下推荐配置：
```
init.defaultBranch = main
core.autocrlf = input
pull.rebase = true
push.autoSetupRemote = true
core.editor = code --wait
```

### 环境变量
所有环境变量配置会写入 `~/.zshrc`，以 `# >>> kick-shell managed >>>` 和 `# <<< kick-shell managed <<<` 标记包裹，方便管理和更新。

## 📝 License

MIT