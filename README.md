# 用默认浏览器打开chatGPT桌面端网页的插件

[English](README.en.md) · Windows

## 使用背景

在 ChatGPT 桌面端的 Codex 聊天里，点击网页链接却总在右侧边栏打开？这个插件用于把链接的打开位置改为系统默认浏览器。

## 下载和调用

**直接使用**

1. [下载 Windows 版](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/chatgpt-default-browser-windows-v0.1.0-preview.1.zip)，解压。
2. 双击 `Enable.cmd` 启用。
3. **完全退出并重新打开 ChatGPT 桌面端**，然后点击网页链接。

**作为 skill 调用**

1. [下载 skill](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/default-browser-skill-v0.1.0-preview.1.zip)，解压。
2. 将里面的 `default-browser` 文件夹放到 `%USERPROFILE%/.codex/skills/`，重新打开客户端。
3. 发给 Codex：

   ```text
   使用 $default-browser，启用默认浏览器打开网页链接。
   ```

   启用后，再完全退出并重新打开客户端，让设置生效。

## 使用效果

预期：**点击网页链接 → 在你的默认浏览器中打开。**

想恢复原来的打开方式，双击 `Restore.cmd` 即可。

> 当前为预览版，重启后的实际点击效果仍待验证。
