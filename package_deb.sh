#!/bin/bash

# Kaku .deb 打包脚本
# 用于在 Linux 环境下将编译好的 Kaku 项目封装成 deb 安装包

set -e

echo "📦 开始打包 Kaku 的 deb 安装包..."
echo "================================================="

# 1. 检查必备工具
if ! command -v dpkg-deb &> /dev/null; then
    echo "❌ 错误: 当前系统未安装 dpkg-deb 工具。请先安装 dpkg，例如: sudo apt install dpkg"
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    echo "❌ 错误: 未检测到 Rust/Cargo，请先安装 Rust 工具链。"
    exit 1
fi

# 2. 确定配置和版本信息
# 从 Cargo.toml 中获取版本号
VERSION=$(grep -m1 '^version *=' kaku/Cargo.toml | awk -F '"' '{print $2}')
if [ -z "$VERSION" ]; then
    VERSION="0.5.0"
fi

# 获取当前架构，并映射到 Debian 架构命名规则
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  DEB_ARCH="amd64" ;;
    aarch64) DEB_ARCH="arm64" ;;
    armv7l)  DEB_ARCH="armhf" ;;
    i686)    DEB_ARCH="i386" ;;
    *)       DEB_ARCH="$ARCH" ;;
esac

PACKAGE_NAME="kaku"
BUILD_DIR="${PACKAGE_NAME}_${VERSION}_${DEB_ARCH}"

echo "ℹ️ 版本: $VERSION"
echo "ℹ️ 平台架构: $DEB_ARCH ($ARCH)"
echo "ℹ️ 构建目录: target/deb/$BUILD_DIR"

# 3. 准备构建环境
echo -e "\n🔨 步骤 1: 编译 release 版本 Kaku..."
# 确保 vendor 下载了
if [ -f "scripts/download_vendor.sh" ]; then
    bash scripts/download_vendor.sh
fi
cargo build --release -p kaku -p kaku-gui

# 4. 创建 DEB 目录结构
echo -e "\n📂 步骤 2: 生成软件包目录结构..."
mkdir -p "target/deb/$BUILD_DIR/DEBIAN"
mkdir -p "target/deb/$BUILD_DIR/usr/bin"
mkdir -p "target/deb/$BUILD_DIR/usr/share/kaku"
mkdir -p "target/deb/$BUILD_DIR/usr/share/applications"
mkdir -p "target/deb/$BUILD_DIR/usr/share/pixmaps"

# 复制可执行文件
cp target/release/kaku target/release/kaku-gui "target/deb/$BUILD_DIR/usr/bin/"
chmod 755 "target/deb/$BUILD_DIR/usr/bin/kaku" "target/deb/$BUILD_DIR/usr/bin/kaku-gui"

# 复制资源文件
cp assets/shell-integration/*.sh "target/deb/$BUILD_DIR/usr/share/kaku/" 2>/dev/null || true
if [ -d "assets/vendor" ]; then
    cp -r assets/vendor "target/deb/$BUILD_DIR/usr/share/kaku/"
fi
cp assets/linux/kaku.lua "target/deb/$BUILD_DIR/usr/share/kaku/" 2>/dev/null || true

# 复制图标
if [ -f "assets/logo.png" ]; then
    cp -f "assets/logo.png" "target/deb/$BUILD_DIR/usr/share/pixmaps/kaku.png"
fi

# 5. 生成 DESKTOP 文件
echo -e "\n✍️ 步骤 3: 写入描述和配置文件..."
cat <<EOF > "target/deb/$BUILD_DIR/usr/share/applications/kaku.desktop"
[Desktop Entry]
Name=Kaku
Comment=A fast, out-of-the-box terminal emulator designed for AI coding.
Exec=kaku
Icon=kaku
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
Keywords=terminal;prompt;ai;
EOF
chmod 644 "target/deb/$BUILD_DIR/usr/share/applications/kaku.desktop"

# 生成打包说明文件 DEBIAN/control
cat <<EOF > "target/deb/$BUILD_DIR/DEBIAN/control"
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Architecture: ${DEB_ARCH}
Maintainer: Tw93 <hitw93@gmail.com>
Depends: libfontconfig1, libxcb-render0, libxcb-shape0, libxcb-xfixes0
Section: x11
Priority: optional
Description: Kaku - Terminal Emulator for AI coding
 A fast, out-of-the-box terminal emulator designed for AI coding.
 Supported out of the box with macOS and Linux.
EOF

# 生成 postinst 安装后自动更新桌面图标缓存 (可选，但推荐)
cat <<EOF > "target/deb/$BUILD_DIR/DEBIAN/postinst"
#!/bin/sh
set -e
if [ -x "\$(command -v update-desktop-database)" ]; then
  update-desktop-database -q || true
fi
EOF
chmod 755 "target/deb/$BUILD_DIR/DEBIAN/postinst"

# 生成 prerm 删除前清理脚本 (可选)
cat <<EOF > "target/deb/$BUILD_DIR/DEBIAN/prerm"
#!/bin/sh
set -e
EOF
chmod 755 "target/deb/$BUILD_DIR/DEBIAN/prerm"

# 6. 生成 deb 包
echo -e "\n📦 步骤 4: 执行打包 (dpkg-deb)..."
cd target/deb
dpkg-deb --build "$BUILD_DIR"
cd ../..

echo -e "\n🎉 成功! .deb 安装包已生成在 target/deb 下："
ls -lh "target/deb/${BUILD_DIR}.deb"

echo "================================================="
echo "您可以通过以下命令在本地安装此 deb 包："
echo "sudo dpkg -i target/deb/${BUILD_DIR}.deb"
echo "如果不满足依赖问题，请接着运行: sudo apt install -f"
