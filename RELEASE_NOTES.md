# 用默认浏览器打开chatGPT桌面端网页的插件

> A plugin that opens web links from the ChatGPT desktop app in your default browser

**v0.1.0-preview.1 · Windows**

## 下载选择

- [完整 Windows 项目包](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/chatgpt-default-browser-windows-v0.1.0-preview.1.zip)：含双击启用、检查和恢复入口，以及中英文说明。
- [独立技能包](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/default-browser-skill-v0.1.0-preview.1.zip)：独立技能目录，含 `SKILL.md` 和执行脚本。
- [SHA256SUMS.txt](https://github.com/ssym-Tsai/-/blob/main/downloads/SHA256SUMS.txt)：用于核对两个 ZIP 文件的 SHA-256。

## 开始使用

完整项目解压后运行 `Enable.cmd`，完全退出并重开桌面客户端，然后测试普通 HTTPS 链接。运行 `Status.cmd` 检查保存的设置；运行 `Restore.cmd` 恢复之前的设置。

独立技能 ZIP 解压后，将其中的 `default-browser` 文件夹放入 `%USERPROFILE%/.codex/skills/`（自定义 `CODEX_HOME` 时使用该目录下的 `skills/`），重启后使用 `$default-browser` 调用。安装技能本身不会自动修改偏好。

## 验证范围

五项隔离集成测试验证了配置启用和恢复行为。此预览版操作 Windows 桌面端 Codex 环境的原生偏好，不包含全局点击拦截。实际重启后的点击效果与 ChatGPT 其他聊天界面尚未验证；如仍打开边栏，请结合客户端版本反馈问题。

## English

Download the Windows project ZIP for the double-click entry points, or the skill ZIP for a standalone `default-browser` skill folder. Verify downloads with `SHA256SUMS.txt`.

Fully quit and reopen the desktop app after enabling preferences. This is a configuration preview for the local Codex environment; actual link-click behavior after restart and other ChatGPT chat surfaces are unverified.
