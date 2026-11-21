#!/bin/bash
# 构建 File Browser v2.63.23 的 Debian 安装包（适用于 DietPi / Debian x86_64）
# 用法：sudo bash build-deb.sh
# 可选：通过 FB_PASSWORD 环境变量指定初始管理员密码；
#       未指定时自动生成随机密码并写入 initial-password 文件（权限 600）。

set -euo pipefail

# 确保以 root 运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

PKG_NAME="filebrowser"
PKG_VERSION="2.63.23"
ARCH="amd64"
DEB_DIR="${PKG_NAME}_${PKG_VERSION}_${ARCH}"

echo "==> 1. 下载二进制文件..."
cd /tmp
curl -L -A "Mozilla/5.0" "https://github.com/filebrowser/filebrowser/releases/download/v${PKG_VERSION}/linux-${ARCH}-filebrowser.tar.gz" -o filebrowser.tar.gz

echo "==> 2. 构建 DEB 目录结构..."
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN" \
         "$DEB_DIR/opt/filebrowser" \
         "$DEB_DIR/mnt/dietpi_userdata/filebrowser" \
         "$DEB_DIR/etc/systemd/system"

echo "==> 3. 解压二进制并设置权限..."
tar -xzf filebrowser.tar.gz -C "$DEB_DIR/opt/filebrowser"
chmod +x "$DEB_DIR/opt/filebrowser/filebrowser"

echo "==> 4. 创建 Systemd 服务文件..."
cat <<'EOF' > "$DEB_DIR/etc/systemd/system/filebrowser.service"
[Unit]
Description=File Browser
After=network.target

[Service]
User=root
ExecStart=/opt/filebrowser/filebrowser -d /mnt/dietpi_userdata/filebrowser/filebrowser.db
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "==> 5. 创建 DEBIAN/control 文件..."
cat <<EOF > "$DEB_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: $PKG_VERSION
Architecture: $ARCH
Maintainer: File Browser Builder <noreply@example.com>
Description: Web based file manager (Custom DietPi build)
 A custom .deb package for File Browser v2.63.23, configured for DietPi.
EOF

echo "==> 6. 创建安装后脚本 (postinst)..."
cat <<'EOF' > "$DEB_DIR/DEBIAN/postinst"
#!/bin/bash
set -e

mkdir -p /mnt/dietpi_userdata/filebrowser

if [ ! -f /mnt/dietpi_userdata/filebrowser/filebrowser.db ]; then
    /opt/filebrowser/filebrowser config init -d /mnt/dietpi_userdata/filebrowser/filebrowser.db
    /opt/filebrowser/filebrowser config set -d /mnt/dietpi_userdata/filebrowser/filebrowser.db -r /music
    /opt/filebrowser/filebrowser config set -d /mnt/dietpi_userdata/filebrowser/filebrowser.db -a 0.0.0.0 -p 8084
    /opt/filebrowser/filebrowser config set -d /mnt/dietpi_userdata/filebrowser/filebrowser.db --tokenExpirationTime "720h"

    # 优先使用安装时传入的 FB_PASSWORD，否则生成 16 位随机密码
    if [ -n "${FB_PASSWORD:-}" ]; then
        _pw="$FB_PASSWORD"
    else
        _pw="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)"
    fi
    /opt/filebrowser/filebrowser users add dietpi "$_pw" --perm.admin -d /mnt/dietpi_userdata/filebrowser/filebrowser.db
    printf '%s\n' "$_pw" > /mnt/dietpi_userdata/filebrowser/initial-password
    chmod 600 /mnt/dietpi_userdata/filebrowser/initial-password
    echo "管理员初始密码已写入 /mnt/dietpi_userdata/filebrowser/initial-password（请登录后立即修改）"
    unset _pw
fi

systemctl daemon-reload
systemctl enable filebrowser.service
systemctl start filebrowser.service
exit 0
EOF
chmod 755 "$DEB_DIR/DEBIAN/postinst"

echo "==> 7. 创建卸载脚本 (prerm)..."
cat <<'EOF' > "$DEB_DIR/DEBIAN/prerm"
#!/bin/bash
set -e
systemctl stop filebrowser.service || true
systemctl disable filebrowser.service || true
exit 0
EOF
chmod 755 "$DEB_DIR/DEBIAN/prerm"

echo "==> 8. 打包为 .deb..."
dpkg-deb --build "$DEB_DIR"

echo "==> 完成！安装包路径：/tmp/${DEB_DIR}.deb"
echo "安装命令：sudo FB_PASSWORD='你的密码' dpkg -i /tmp/${DEB_DIR}.deb"
echo "（不设 FB_PASSWORD 时会自动生成随机密码，写入 initial-password 文件）"
