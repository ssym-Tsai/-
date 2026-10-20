---
name: default-browser
description: Configure, inspect, or restore where Windows Codex desktop opens ordinary web and localhost links. Use when the user wants links in the system default browser instead of the side panel.
---

# 用默认浏览器打开chatGPT桌面端网页的插件

> A plugin that opens web links from the ChatGPT desktop app in your default browser

The display title is separate from the technical skill name `default-browser`. The current Windows implementation targets the desktop app's local Codex configuration; other ChatGPT chat surfaces are unverified.

Use the bundled `scripts/Set-CodexLinkTarget.ps1` with Windows PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '<absolute skill directory>/scripts/Set-CodexLinkTarget.ps1' -Action Enable
```

Choose `Status` for inspection and `Restore` to undo an earlier Enable. Resolve the script relative to this skill's installed directory; never assume the development checkout path. Optional `-CodexExecutable` selects a specific installed codex.exe; `-CodexHome` selects a nondefault config directory.

The execution-policy option applies only to this PowerShell process. It does not change the user's persistent execution policy.

Enable sets only `desktop.open-link-in-target-preference` and `desktop.open-local-url-in-target-preference` to `external-browser` using Codex's native config API. It saves only the original values in a backup beside config.toml. Restore edits those two keys instead of replacing the entire configuration. Permissions required for the user's Codex home still apply.

Explain that restarting the desktop app may be needed; do not terminate the user's running app. After restart, verify one ordinary HTTPS link and one localhost link by clicking them. A Status result verifies saved preferences, not end-to-end click behavior.

This is a settings plugin, not a global UI click hook. An explicit request to open an in-app preview can still open the side panel. Some app builds ignore the saved preference for inline links (https://github.com/openai/codex/issues/50722). If ordinary links still open in-app after restart, report that the intended behavior is not yet verified; do not repeatedly change the same settings or claim the app bug is fixed.
