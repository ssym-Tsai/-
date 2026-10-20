# A plugin that opens web links from the ChatGPT desktop app in your default browser

[简体中文](README.md) · Windows

## Why use it?

Web links in the desktop app's Codex chat keep opening in the side panel? This plugin changes the preferred destination to your system default browser.

## Download and use

**Run directly**

1. [Download the Windows ZIP](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/chatgpt-default-browser-windows-v0.1.0-preview.1.zip) and extract it.
2. Double-click `Enable.cmd`.
3. **Fully quit and reopen the ChatGPT desktop app**, then click a web link.

**Use as a skill**

1. [Download the skill ZIP](https://github.com/ssym-Tsai/-/raw/refs/heads/main/downloads/default-browser-skill-v0.1.0-preview.1.zip) and extract it.
2. Put the `default-browser` folder in `%USERPROFILE%/.codex/skills/` and reopen the client.
3. Send this to Codex:

   ```text
   Use $default-browser to enable opening web links in my default browser.
   ```

   Fully quit and reopen the client again after enabling the preference.

**or:** Send [this skill link](https://github.com/ssym-Tsai/-/tree/main/plugins/default-browser/skills/default-browser) to Codex and ask it to download and install the skill for you.

## Expected result

**Click a web link → open it in your default browser.**

To restore the previous behavior, double-click `Restore.cmd`.

> Preview version. Actual link clicks after restarting the app remain unverified.
