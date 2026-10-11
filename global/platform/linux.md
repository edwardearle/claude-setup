This machine runs Linux. The Bash tool is bash with the GNU userland, so shell commands behave as most documentation assumes. What bites is what the distribution ships, what the user is allowed to install, and the differences from the macOS and Windows machines that share these repositories.

- **No root by default.** `sudo` usually needs a password the session cannot type. Never run it; to install a system package, give the exact command and ask the user to run it as `! sudo apt install <package>`. Per-user tools go in `~/.local/bin`; check it is on PATH.
- **LTS distributions ship old tools.** Check `git --version`, `python3 --version` and `node --version` before using a recent flag. Ubuntu 20.04's git 2.25, for example, has no `git rev-parse --path-format` (added in 2.31).
- **`jq` is often missing.** `bootstrap.sh` skips the settings merge without it. Python 3's `json` module, present on most installs, does the same job.
- **The filesystem is case-sensitive.** `Readme.md` and `README.md` can coexist here and collide on macOS and Windows clones. Match the case a file already uses, and never create two paths that differ only in case.
- **Git records the executable bit.** A script committed from Windows arrives as `100644` and `./script.sh` fails with "Permission denied". Run it with `bash script.sh`, and fix the repository with `git update-index --chmod=+x <file>`. A plain `chmod` also works where `core.fileMode` is true, but goes unseen where it is false, as on WSL's `/mnt/c`.
- **GNU tools accept flags that macOS's do not.** A script that also runs on a Mac must avoid `sed -i` without a suffix (use `sed -i.bak`), `grep -P`, `date -d`, `stat -c` and `find -printf`.
- **Non-interactive processes such as hooks and MCP servers do not read `~/.bashrc`.** Tools set up there, such as `nvm`, may be missing from their PATH; use an absolute path.
- **Under WSL**, keep repositories in the Linux home directory, not under `/mnt/c`, where file access is slow and every file looks executable.
- PowerShell is absent unless `pwsh` is installed. Prefer the bash counterpart of a `.ps1` script.
