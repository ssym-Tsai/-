[CmdletBinding()]
param(
    [ValidateSet('Status', 'Enable', 'Restore')]
    [string]$Action = 'Status',
    [string]$CodexHome,
    [string]$CodexExecutable,
    [ValidateRange(1, 120)]
    [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

function Get-Field($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}

function Find-Codex {
    if ($CodexExecutable) {
        return (Get-Item -LiteralPath $CodexExecutable).FullName
    }
    $command = Get-Command codex.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    # The desktop app installs versioned binaries here; choose the newest runtime.
    $base = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    $candidates = @(Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Get-Item -LiteralPath (Join-Path $_.FullName 'codex.exe') -ErrorAction SilentlyContinue } |
        Sort-Object LastWriteTimeUtc -Descending)
    if ($candidates.Count -eq 0) { throw 'Cannot find codex.exe. Supply -CodexExecutable with its absolute path.' }
    return $candidates[0].FullName
}

$process = $null
$script:requestId = 0
function Invoke-ConfigRpc([string]$Method, $Params) {
    $script:requestId++
    $id = $script:requestId
    $request = @{ id = $id; method = $Method; params = $Params } | ConvertTo-Json -Depth 40 -Compress
    # .NET Framework's redirected stdin can use an ANSI encoding. JSON escapes
    # keep paths containing Chinese characters intact on Windows PowerShell 5.
    $request = [regex]::Replace($request, '[^\x00-\x7F]', {
        param($match)
        '\u{0:x4}' -f [int][char]$match.Value
    })
    $process.StandardInput.WriteLine($request)
    $process.StandardInput.Flush()
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ($true) {
        $remaining = [int][Math]::Max(1, ($deadline - [DateTime]::UtcNow).TotalMilliseconds)
        $pending = $process.StandardOutput.ReadLineAsync()
        if (-not $pending.Wait($remaining)) { throw "Codex timed out during $Method. No success was confirmed." }
        $line = $pending.Result
        if ($null -eq $line) { throw "Codex exited during $Method. No success was confirmed." }
        $message = $line | ConvertFrom-Json
        if ((Get-Field $message 'id') -ne $id) { continue }
        if (Get-Field $message 'error') {
            # Avoid echoing config contents or other sensitive diagnostics.
            $code = Get-Field $message.error 'code'
            throw "Codex rejected $Method (RPC error $code). Configuration was not confirmed; check config.toml syntax and permissions."
        }
        return $message.result
    }
}

function Read-UserLayer {
    $result = Invoke-ConfigRpc 'config/read' @{ includeLayers = $true }
    $layers = @($result.layers | Where-Object {
        $_.name.type -eq 'user' -and -not (Get-Field $_.name 'profile') -and
        [IO.Path]::GetFullPath($_.name.file) -eq $configPath
    })
    if ($layers.Count -ne 1) { throw 'Cannot identify the base user config layer; no configuration edits were made.' }
    return $layers[0]
}

function Get-LinkValues($Layer) {
    $desktop = Get-Field $Layer.config 'desktop'
    $values = [ordered]@{}
    foreach ($key in $keys) { $values[$key] = Get-Field $desktop $key }
    return $values
}

try {
    if (-not $CodexHome) {
        $CodexHome = $env:CODEX_HOME
        if (-not $CodexHome) { $CodexHome = Join-Path $env:USERPROFILE '.codex' }
    }
    $CodexHome = [IO.Path]::GetFullPath($CodexHome)
    if (-not (Test-Path -LiteralPath $CodexHome -PathType Container)) {
        throw 'Codex home does not exist. Open Codex first, or supply -CodexHome.'
    }
    $configPath = Join-Path $CodexHome 'config.toml'
    $backupPath = Join-Path $CodexHome '.default-browser-plugin-backup.json'
    $keys = @('open-link-in-target-preference', 'open-local-url-in-target-preference')

    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = Find-Codex
    $start.Arguments = 'app-server --stdio'
    $start.WorkingDirectory = $CodexHome
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $start.StandardErrorEncoding = New-Object System.Text.UTF8Encoding($false)
    $start.EnvironmentVariables['CODEX_HOME'] = $CodexHome
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $start
    [void]$process.Start()
    $stderr = $process.StandardError.ReadToEndAsync()
    $hello = Invoke-ConfigRpc 'initialize' @{ clientInfo = @{ name = 'default-browser-plugin'; version = '0.1.0' } }
    $process.StandardInput.WriteLine('{"method":"initialized"}')
    $layer = Read-UserLayer
    $current = Get-LinkValues $layer
    $changed = $false

    if ($Action -ne 'Status') {
        if ($Action -eq 'Enable') {
            $desired = [ordered]@{}
            foreach ($key in $keys) { $desired[$key] = 'external-browser' }
            if (-not (Test-Path -LiteralPath $backupPath)) {
                $backup = @{ schemaVersion = 1; configPath = $configPath; values = $current }
                $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes(($backup | ConvertTo-Json -Depth 10))
                # CreateNew preserves the first snapshot even across repeated Enable calls.
                $stream = [IO.File]::Open($backupPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
                try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush() } finally { $stream.Dispose() }
            }
        } else {
            if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) { throw 'No saved settings to restore.' }
            $backup = [IO.File]::ReadAllText($backupPath) | ConvertFrom-Json
            if ($backup.schemaVersion -ne 1 -or $backup.configPath -ne $configPath -or
                @($backup.values.PSObject.Properties).Count -ne 2) { throw 'Backup does not match this configuration.' }
            $desired = [ordered]@{}
            foreach ($key in $keys) {
                if ($null -eq $backup.values.PSObject.Properties[$key]) { throw 'Backup is missing a setting.' }
                $value = Get-Field $backup.values $key
                if ($null -ne $value -and $value -notin @('in-app-browser', 'external-browser')) { throw 'Backup contains an unsupported setting value.' }
                if ($current[$key] -ne 'external-browser' -and $current[$key] -ne $value) {
                    throw 'Link settings changed after Enable. Restore stopped to preserve the newer choice.'
                }
                $desired[$key] = $value
            }
        }

        $edits = @()
        foreach ($key in $keys) {
            if ($current[$key] -ne $desired[$key]) {
                $edits += @{ keyPath = "desktop.$key"; value = $desired[$key]; mergeStrategy = 'replace' }
            }
        }
        if ($edits.Count -gt 0) {
            $write = Invoke-ConfigRpc 'config/batchWrite' @{
                edits = $edits; filePath = $configPath; expectedVersion = $layer.version
            }
            if ($write.status -ne 'ok') { throw 'Codex did not confirm a successful configuration write.' }
            $changed = $true
        }
        $current = Get-LinkValues (Read-UserLayer)
        foreach ($key in $keys) {
            if ($current[$key] -ne $desired[$key]) { throw 'Saved settings do not match the requested values.' }
        }
        if ($Action -eq 'Restore') { Remove-Item -LiteralPath $backupPath }
    }

    [ordered]@{
        action = $Action
        configPath = $configPath
        webLinkTarget = $current[$keys[0]]
        localUrlTarget = $current[$keys[1]]
        changed = $changed
        backupExists = (Test-Path -LiteralPath $backupPath -PathType Leaf)
        note = 'Saved preferences only. Restart the desktop app if needed, then verify by clicking a web link. Explicit in-app previews and client bugs can override this preference.'
    } | ConvertTo-Json -Depth 5
} catch {
    Write-Verbose $_.ScriptStackTrace
    throw
} finally {
    if ($null -ne $process) {
        try { if (-not $process.HasExited) { $process.Kill(); $process.WaitForExit(5000) | Out-Null } } finally { $process.Dispose() }
    }
}
