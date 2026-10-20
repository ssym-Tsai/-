简体中文 | [English](README.en.md)

# 用默认浏览器打开chatGPT桌面端网页的插件

> A plugin that opens web links from the ChatGPT desktop app in your default browser

设置网页链接的默认打开位置，并提供检查和恢复操作。

**Windows 首版 · 无第三方运行库依赖 · 原设置可恢复**

**预览版下载：** [完整 Windows 包](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/chatgpt-default-browser-windows-v0.1.0-preview.1.zip) · [独立 skill 包](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/default-browser-skill-v0.1.0-preview.1.zip) · [SHA-256 校验值](https://github.com/ssym-Tsai/-/blob/main/downloads/SHA256SUMS.txt)

[快速开始](#快速开始) · [独立技能包](#独立技能包) · [安装为插件](#安装为插件) · [使用技能](#使用技能) · [兼容性与验证](#兼容性与验证)

| 项目 | 当前状态 |
| --- | --- |
| 支持系统 | Windows |
| 当前实现范围 | ChatGPT 桌面端中的 Codex 本地环境；其他聊天界面尚未验证 |
| 实现方式 | 保存客户端原生链接打开偏好 |
| 配置测试 | 5 项隔离集成测试通过 |
| 实际点击效果 | 待完全退出并重开客户端后验证 |

## 快速开始

需要已安装桌面客户端及其 `codex.exe`。下载并解压项目后：

1. 双击 **`Enable.cmd`**，将网页及 localhost 链接的默认打开位置设为系统默认浏览器。
2. 从托盘或应用菜单**完全退出客户端，再重新打开**；仅关闭窗口可能仍保留后台进程。
3. 普通左键点击回复中的 HTTPS 链接，确认网页在系统默认浏览器中打开。

| 文件 | 用途 |
| --- | --- |
| [`Enable.cmd`](Enable.cmd) | 启用默认浏览器打开偏好 |
| [`Status.cmd`](Status.cmd) | 查看已保存的设置 |
| [`Restore.cmd`](Restore.cmd) | 恢复首次启用前的设置 |

以上入口可直接使用。希望通过对话调用时，再安装插件。

## 独立技能包

分发时提供完整 Windows 项目 ZIP 和独立技能 ZIP。独立技能包解压后，将 `default-browser` 文件夹放入 `%USERPROFILE%/.codex/skills/`；如果设置了 `CODEX_HOME`，则放入该目录下的 `skills/`。

重启客户端后，用 `$default-browser` 调用。仅安装技能不会自动启用链接偏好。具体文件名、校验方式和首版限制见[预览版说明](RELEASE_NOTES.md)。

也可以让 Codex 的 `$skill-installer` 安装仓库中的独立技能目录：

```text
使用 $skill-installer 安装 https://github.com/ssym-Tsai/-/tree/main/plugins/default-browser/skills/default-browser
```

## 安装为插件

在 PowerShell 中进入项目目录，然后运行：

```powershell
codex plugin marketplace add .
codex plugin add default-browser@codex-link-tools
```

如果 `codex` 不在 PATH 中，请用本机 `codex.exe` 的绝对路径执行上述命令。重启客户端后，插件中的 `default-browser` 技能可被发现。安装后调用技能启用，或运行 `Enable.cmd`。

技术标识与展示名称分开使用：

| 位置 | 名称 |
| --- | --- |
| 中文展示名 | 用默认浏览器打开chatGPT桌面端网页的插件 |
| 英文副标题 | A plugin that opens web links from the ChatGPT desktop app in your default browser |
| 技能调用 | `$default-browser` |
| 插件安装标识 | `default-browser@codex-link-tools` |

## 使用技能

安装后，可在 Codex 对话中使用以下示例：

```text
使用 $default-browser，启用默认浏览器打开网页链接。
```

```text
使用 $default-browser，检查当前链接打开位置。
```

```text
使用 $default-browser，恢复之前的链接打开设置。
```

技能入口位于 [`SKILL.md`](plugins/default-browser/skills/default-browser/SKILL.md)。运行脚本时仍需具备用户配置目录的写入权限。

## 恢复设置

双击 `Restore.cmd`，或通过技能请求恢复。脚本仅恢复两项链接设置，保留之后修改的其他配置。

首次启用时，原值保存在 `$CODEX_HOME/.default-browser-plugin-backup.json`；默认目录为 `%USERPROFILE%/.codex`。重复启用会保留首次备份。如果链接设置后来被手动修改，恢复操作会检查冲突，避免覆盖新的选择。

需要撤销设置并卸载时，先执行恢复，再卸载插件：

```powershell
codex plugin remove default-browser@codex-link-tools
```

单独禁用或卸载插件不会撤销已保存的客户端设置。

## 兼容性与验证

当前脚本通过 Codex 自身的 `config/read`、`config/batchWrite` 接口保存以下设置：

```toml
[desktop]
open-link-in-target-preference = "external-browser"
open-local-url-in-target-preference = "external-browser"
```

这是原生偏好设置，不包含全局点击拦截。主动打开应用内网页预览的操作仍可能打开边栏。部分版本存在忽略行内链接偏好的报告：[openai/codex#50722](https://github.com/openai/codex/issues/50722)、[openai/codex#36601](https://github.com/openai/codex/issues/36601)。

**配置读回成功只能确认设置已保存。** 如果完全重启后，普通网页链接仍在边栏打开，需要继续诊断；当前版本不能据此标记为点击功能已验证。

现有五项测试覆盖启用与恢复、保留无关配置和后续编辑、重复启用、无效 TOML、恢复冲突。它们使用隔离目录，不访问用户实际配置。开发者可使用 Python 3.11+ 运行：

```powershell
python ./tests/test_integration.py 'C:/path/to/codex.exe'
```

使用 `python ./scripts/build_release.py` 可从明确的文件清单重新生成两个 ZIP 和 `SHA256SUMS.txt`；构建不会收集本地配置、备份或 `.work/` 下的调研文件。

<details>
<summary>手动运行脚本与参数</summary>

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./plugins/default-browser/skills/default-browser/scripts/Set-CodexLinkTarget.ps1 -Action Enable
```

`-Action` 支持 `Enable`、`Status`、`Restore`。可使用 `-CodexHome` 指定配置目录，使用 `-CodexExecutable` 指定 `codex.exe`。执行策略参数仅作用于当前 PowerShell 进程，不修改用户的持久执行策略。

</details>

<details>
<summary>打包依据与 GitHub 检索记录</summary>

插件结构参考 [OpenAI 本地插件文档](https://developers.openai.com/plugins/build/plugins)。

2026-10-20 检索了 `codex default browser`、`codex external browser`、`codex link redirect` 和 `open-link-in-target-preference`。未找到符合本机用途的可直接安装插件；相关结果主要是 dotfiles 配置和客户端实现。该结果不代表 GitHub 上绝对不存在同类项目。

</details>
