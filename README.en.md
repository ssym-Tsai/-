[简体中文](README.md) | English

# A plugin that opens web links from the ChatGPT desktop app in your default browser

> 用默认浏览器打开chatGPT桌面端网页的插件

Configure the default destination for web links, inspect saved settings, and restore previous preferences.

**Windows v1 · No third-party runtime dependencies · Restorable preferences**

**Preview downloads:** [Windows project ZIP](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/chatgpt-default-browser-windows-v0.1.0-preview.1.zip) · [Standalone skill ZIP](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/default-browser-skill-v0.1.0-preview.1.zip) · [SHA-256 checksums](https://github.com/ssym-Tsai/-/blob/main/downloads/SHA256SUMS.txt)

| Item | Current status |
| --- | --- |
| Platform | Windows |
| Implementation scope | The desktop app's local Codex environment; other ChatGPT chat surfaces are unverified |
| Mechanism | Native link destination preferences |
| Configuration tests | Five isolated integration tests passed |
| Actual link clicks | Awaiting verification after fully quitting and reopening the desktop app |

## Quick start

The desktop app and its `codex.exe` must already be installed. Download and extract this project, then:

1. Run **`Enable.cmd`** to select the system default browser for web and localhost links.
2. **Fully quit and reopen the desktop app.** Closing its window may leave the process running.
3. Left-click an ordinary HTTPS link in a response and check that it opens in your system default browser.

| Entry point | Action |
| --- | --- |
| [`Enable.cmd`](Enable.cmd) | Enable the default browser preference |
| [`Status.cmd`](Status.cmd) | Inspect saved preferences |
| [`Restore.cmd`](Restore.cmd) | Restore preferences saved before the first Enable |

These entry points work directly. Install the plugin below to use its skill through a conversation.

## Standalone skill package

Extract the skill ZIP and place its `default-browser` folder in `%USERPROFILE%/.codex/skills/`, or the `skills/` directory under a custom `CODEX_HOME`. Restart the client and invoke `$default-browser`. Installing the skill does not automatically change link preferences.

See the [preview release notes](RELEASE_NOTES.md) for archive names, checksums, and limitations. Developers can run `python ./scripts/build_release.py` to generate both ZIPs and `SHA256SUMS.txt` from an explicit file list.

Alternatively, ask Codex's `$skill-installer` to install `https://github.com/ssym-Tsai/-/tree/main/plugins/default-browser/skills/default-browser`, then restart to discover the skill.

## Install and use the skill

In PowerShell, change to this project's directory and run:

```powershell
codex plugin marketplace add .
codex plugin add default-browser@codex-link-tools
```

If `codex` is unavailable on PATH, invoke the installed `codex.exe` using its absolute path. Restart the desktop app to discover the skill. Installing the plugin does not automatically enable the preference; use the skill or run `Enable.cmd` afterward.

The display title is separate from the technical identifiers: the skill is `default-browser`, and the plugin is `default-browser@codex-link-tools`.

Example requests:

```text
Use $default-browser to open web links in my system default browser.
Use $default-browser to inspect my current link destination settings.
Use $default-browser to restore my previous link destination settings.
```

The skill entry point is [`SKILL.md`](plugins/default-browser/skills/default-browser/SKILL.md). Configuration changes require write access to the user's Codex home.

## Restore and uninstall

Run `Restore.cmd` or ask the skill to restore settings. Only the two link preferences are restored; unrelated later configuration changes are preserved.

The initial values are saved in `$CODEX_HOME/.default-browser-plugin-backup.json`, under `%USERPROFILE%/.codex` by default. Repeated Enable calls preserve the initial backup. Restore checks for later manual changes to the link preferences before overwriting them.

To undo the preferences and uninstall, restore first, then run:

```powershell
codex plugin remove default-browser@codex-link-tools
```

Disabling or uninstalling the plugin alone does not revert saved preferences.

## Compatibility and verification

The script uses Codex's native `config/read` and `config/batchWrite` APIs to save:

```toml
[desktop]
open-link-in-target-preference = "external-browser"
open-local-url-in-target-preference = "external-browser"
```

The implementation configures native preferences; it does not install a global click interceptor. Explicit in-app preview actions may still open the side panel. Some client versions have been reported to ignore the inline link preference: [openai/codex#50722](https://github.com/openai/codex/issues/50722) and [openai/codex#36601](https://github.com/openai/codex/issues/36601).

**Reading preferences back verifies saved configuration only.** If ordinary web links still open in the side panel after a full restart, further diagnosis is required; actual click behavior has not been verified for that environment.

Five isolated integration tests cover enable/restore, preserving unrelated settings and later edits, repeated Enable calls, invalid TOML, and restore conflicts. They do not access the user's real configuration. Run them with Python 3.11+:

```powershell
python ./tests/test_integration.py 'C:/path/to/codex.exe'
```

<details>
<summary>Run the script manually</summary>

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./plugins/default-browser/skills/default-browser/scripts/Set-CodexLinkTarget.ps1 -Action Enable
```

`-Action` accepts `Enable`, `Status`, or `Restore`. Use `-CodexHome` for a custom configuration directory and `-CodexExecutable` for a specific executable. The execution-policy option applies only to that PowerShell process.

</details>

Packaging follows the [OpenAI local plugin documentation](https://developers.openai.com/plugins/build/plugins).
