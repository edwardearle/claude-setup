This machine runs macOS on Apple Silicon. The Bash tool is bash; the interactive shell is zsh. The differences that actually bite, coming from Windows or Linux, are the BSD userland and the case-insensitive filesystem.

- **The filesystem is case-insensitive but case-preserving** (APFS default). `git mv claude.md CLAUDE.md` is a no-op or an error: rename through a temporary name in two steps. Two files differing only in case cannot coexist, and git may see a case-only rename as no change at all.
- **The userland is BSD, not GNU.** `sed -i` requires a backup suffix, so it is `sed -i '' 's/a/b/' f` here and `sed -i 's/a/b/' f` on Linux; `sed -i.bak` works on both. `grep` has no `-P`, use `-E`. `date -v-1d` replaces `date -d '1 day ago'`. `stat -f%z` replaces `stat -c%s`. `find` has no `-printf`. Check a flag before assuming Linux behaviour, and prefer the Read, Edit and Write tools over stream editors.
- **`/bin/bash` is 3.2**, held back by licensing. No associative arrays, `${var^^}`, `mapfile` or `globstar`. Confirm with `bash --version` before using anything from bash 4. `brew install bash` puts 5.x at `/opt/homebrew/bin/bash`.
- **Homebrew is at `/opt/homebrew` on Apple Silicon**, `/usr/local` on Intel. Non-interactive processes such as hooks and MCP servers may not have it on PATH, so use an absolute path there rather than assuming `brew` resolves. `brew install coreutils gnu-sed` provides GNU behaviour as `gsed`, `gdate`, `gstat`.
- **Quote every path.** Application data lives under `~/Library/Application Support/`, which contains spaces.
- Symlinks need no special privilege, so `ln -s` is the idiomatic way to link configuration. There is no junction equivalent to reach for.
- `xcode-select --install` provides git, clang and make. Nothing builds before that.
- A downloaded binary carries a quarantine attribute. If Gatekeeper blocks one, `xattr -d com.apple.quarantine <file>`.
- `.DS_Store` files appear in any folder Finder opens. Cover them in the global gitignore and never commit them.
- PowerShell is absent. `brew install --cask powershell` provides `pwsh` if a script genuinely needs it; prefer rewriting the script in bash.
