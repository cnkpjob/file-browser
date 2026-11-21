# DietPi 手动部署 File Browser (x86_64)

![Platform](https://img.shields.io/badge/Platform-DietPi%20%2F%20Debian-blue)
![Architecture](https://img.shields.io/badge/Arch-x86__64-lightgrey)
![Version](https://img.shields.io/badge/File%20Browser-v2.63.23-green)

## 📖 项目简介

在 DietPi 上使用 `dietpi-software install 198` 安装 File Browser 时，由于脚本请求 GitHub API 检测最新版本时会被拦截（返回 403 错误），导致安装失败。

此外，File Browser 官方项目已于 2026 年 9 月归档（Archived），不再提供安全更新。但作为轻量级的本地 Web 文件管理器，它依然非常适合用来管理个人服务器上的特定目录（如音乐库 `/music`）。

本指南记录了在 **x86_64 (amd64)** 架构的 DietPi 上，手动下载、部署并配置 File Browser 作为 Systemd 后台服务的完整过程。

## 🛠️ 部署步骤

### 1. 手动下载二进制包

由于官方脚本请求会触发 403 错误，我们需要手动下载最后一个可用版本 `v2.63.23` 的 amd64 包。通过添加 `-A "Mozilla/5.0"` 伪装请求头，绕过 GitHub 的拦截。

```bash
cd /tmp
curl -L -A "Mozilla/5.0" https://github.com/filebrowser/filebrowser/releases/download/v2.63.23/linux-amd64-filebrowser.tar.gz -o linux-amd64-filebrowser.tar.gz
```

> 📌 原文在「1. 手动下载二进制包」处结束。解压、配置与 Systemd 后台服务章节待补充。
