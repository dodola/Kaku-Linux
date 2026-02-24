#!/bin/bash

# Kaku Linux 安装脚本
# 基于 LINUX_README.md 中的安装步骤自动执行

set -e

echo "🚀 开始安装 Kaku for Linux..."
echo "================================================="

# # 1. 检查和安装依赖
# echo "📦 步骤 1: 检查系统依赖..."
# if command -v apt &> /dev/null; then
#     echo "检测到 APT (Ubuntu/Debian). 将请求 sudo 权限安装依赖..."
#     sudo apt update
#     sudo apt install -y build-essential pkg-config libfontconfig1-dev libxcb-render0-dev libxcb-shape0-dev libxcb-xfixes0-dev
# elif command -v dnf &> /dev/null; then
#     echo "检测到 DNF (Fedora). 将请求 sudo 权限安装依赖..."
#     sudo dnf install -y gcc pkg-config fontconfig-devel libxcb-devel
# elif command -v pacman &> /dev/null; then
#     echo "检测到 Pacman (Arch Linux). 将请求 sudo 权限安装依赖..."
#     sudo pacman -S --needed --noconfirm base-devel fontconfig libxcb
# else
#     echo "⚠️ 无法自动识别当前系统的包管理器。"
#     echo "请根据 LINUX_README.md 手动安装 fontconfig 和 libxcb 等相关开发包依赖。"
# fi

# 检查 Rust
if ! command -v cargo &> /dev/null; then
    echo "❌ 错误: 未检测到 Rust/Cargo。请先安装 Rust (例如: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh) 并重启终端。"
    exit 1
fi

# 确保在项目根目录
if [ ! -f "Cargo.toml" ] || [ ! -f "LINUX_README.md" ]; then
    echo "❌ 错误: 找不到 Cargo.toml 或 LINUX_README.md。"
    echo "请确保你在 Kaku 的项目根目录下运行此脚本: bash install.sh"
    exit 1
fi

# 2. 下载 vendor 依赖
echo -e "\n📥 步骤 2: 下载 vendor 依赖..."
if [ -f "scripts/download_vendor.sh" ]; then
    bash scripts/download_vendor.sh
else
    echo "⚠️ 警告: 找不到 scripts/download_vendor.sh，跳过此步骤。"
fi

# 3. 编译
echo -e "\n🔨 步骤 3: 编译 Kaku (这可能需要一些时间，请耐心等待)..."
cargo build --release -p kaku -p kaku-gui

# 4. 安装
echo -e "\n📂 步骤 4: 安装 Kaku..."
mkdir -p ~/.local/bin ~/.local/share/kaku ~/.config/kaku

echo "复制二进制文件到 ~/.local/bin/ ..."
rm -f ~/.local/bin/kaku ~/.local/bin/kaku-gui
cp target/release/kaku target/release/kaku-gui ~/.local/bin/

echo "复制资源文件到 ~/.local/share/kaku/ ..."
cp assets/shell-integration/*.sh ~/.local/share/kaku/ 2>/dev/null || true
if [ -d "assets/vendor" ]; then
    cp -r assets/vendor ~/.local/share/kaku/
fi
cp assets/linux/kaku.lua ~/.local/share/kaku/ 2>/dev/null || true
echo "应用 Linux 优化配置到 ~/.config/kaku/kaku.lua ..."
if [ -f "assets/linux/kaku.lua" ]; then
    cp assets/linux/kaku.lua ~/.config/kaku/
fi

# 5. 将 bin 添加到 PATH
echo -e "\n🔧 步骤 5: 配置环境变量 PATH..."
SHELL_RC=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "$HOME/.local/bin" "$SHELL_RC" && ! grep -q "\~/.local/bin" "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo '# Kaku bin path' >> "$SHELL_RC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        echo "✅ 已将 ~/.local/bin 添加到 $SHELL_RC。"
    else
        echo "ℹ️ ~/.local/bin 已经在您的 PATH 中。"
    fi
else
    echo "⚠️ 无法确定您的 Shell。请手动将 ~/.local/bin 添加到您的 PATH 中。"
fi

echo -e "\n🎉 Kaku for Linux 安装完成！"
echo "================================================="
echo "下一步操作建议："
if [ -n "$SHELL_RC" ]; then
    echo "1. 执行源命令使其生效: source $SHELL_RC"
else
    echo "1. 重新启动终端或执行当前 shell 的源命令"
fi
echo "2. 初始化环境: kaku init"
echo "3. 运行 Kaku: kaku"
echo "================================================="
