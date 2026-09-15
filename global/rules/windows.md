Primary machines run Windows 11. The Bash tool is git-bash; PowerShell is Windows PowerShell 5.1 unless `pwsh` is present.

- Prefer the Bash tool with forward-slash paths (`/c/code/...`). Reach for PowerShell only when a cmdlet is the point.
- PowerShell 5.1 has no `&&`, `||`, `?:` or `??`. Native `2>&1` redirects wrap stderr in ErrorRecords and set `$?` false. Check `$LASTEXITCODE` after native calls.
- Writing files from PowerShell: `[System.IO.File]::WriteAllText($absPath, $text, (New-Object System.Text.UTF8Encoding($false)))` for UTF-8 without BOM. `Out-File` and `>` default to UTF-16.
- Keep generated `.ps1` files ASCII-only. 5.1 reads them as Windows-1252 without a BOM, and one curly quote or dash breaks parsing with a misleading error on a different line.
- `Get-Content | ConvertFrom-Json` needs `-Raw`. `ConvertFrom-Json` has no `-AsHashtable` in 5.1.
- Long paths fail in git with "Filename too long". Clone reference material to a short path such as `%LOCALAPPDATA%\Temp\<name>`, not the session scratchpad.
- MCP servers launched via npm need `cmd /c npx ...` because npm shims are batch files.
- `bash.exe.stackdump` files appear after some Bash calls; a hook removes them. Never commit them.
- Symlinks need Developer Mode or admin. Directory junctions (`mklink /J`, `New-Item -ItemType Junction`) do not.
