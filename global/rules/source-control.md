- Conventional Commits: `type(scope): subject`. `scope` is a code area (`auth`, `api`, `ui`), not a ticket. The body names the specs: `Implements auth/sign-in`.
- Types: `feat`, `fix`, `test`, `reg` (regression tests capturing existing behaviour), `refactor`, `docs`, `chore`, `build`, `ci`, `style`.
- Commit only when asked, or at a plan phase gate the user has just approved. Never commit as a side effect of another request.
- Never push, force-push, rewrite shared history, or open a PR without being asked.
- A PR to `main` carries a documentation review. Before opening one, run `/flow:review`, which checks the README and every document it links for statements the change made untrue, broken paths and missing entries. Fix what it finds, and record the outcome in the PR body under a `Docs:` line: what was checked, what changed, or that nothing needed to.
- Do not commit on `main` or `master` unless the user explicitly says to for this commit.
- Small commits: a guide is under 10 files and around 200 lines. If a change is bigger, it is probably two commits.
- `git status --short` first, then stage paths by name. Never `git add -A` or `git add .`.
- Lint and the full test suite are green before any commit. If they are not, say so and stop.
- Never commit secrets. Before the first commit in a repo, check `.gitignore` covers `.env*`, key files and local settings.
- Co-author trailers: use whatever the harness supplies. Do not add or alter them.
- `reg` commits (backfilling tests for existing behaviour) ship separately from the change they protect.

### Branches and worktrees

- The first job on any piece of work is its branch and worktree, before the first change to the repository. Design happens on the issue and needs neither.
- These rules apply to new branches. Work already in flight keeps its branch name and its worktree, wherever that is, until it merges.
- Non-trivial work starts from an issue; create one if there is none. A trivial change, as defined in `CLAUDE.md`, is exempt.
- The branch and the worktree folder share one name: `<issue>-<short-title>`, the issue number and two to four words of its title, lower case and hyphenated, e.g. `123-update-url`. Exempt work drops the number: `fix-readme-typo`.
- Worktrees live in the main clone at `.claude/worktrees/<name>`, where the desktop app and `EnterWorktree` put theirs. Never beside it (`../repo--slug`) and never inside another worktree. Find the main clone from git's common directory, because a relative path run from inside a worktree nests the new one there.
- Branch from the latest default branch. Branch from somewhere else only for a reason you state, such as a sub-issue that builds on a sibling's open PR: it branches from that PR's branch and opens its own PR against it.

  ```
  COMMON=$(git rev-parse --path-format=absolute --git-common-dir)
  ROOT=$(dirname "$COMMON")
  grep -qxF '.claude/worktrees/' "$COMMON/info/exclude" || echo '.claude/worktrees/' >> "$COMMON/info/exclude"
  git fetch origin
  git worktree add "$ROOT/.claude/worktrees/<name>" -b <name> --no-track origin/<default branch>
  ```

  Then `EnterWorktree` with that path. The exclude line keeps worktrees out of `git status` without touching the project's `.gitignore`. `--no-track` stops `git pull` merging the default branch into the work; the first `git push -u origin <name>` sets the upstream. The git guard hook refuses any other location.
- To resume work whose branch is already checked out somewhere (`git worktree list`), move into that worktree with `EnterWorktree` rather than checking the branch out again, which git refuses. A branch with no worktree, local or only on the remote, gets one with `git worktree add "$ROOT/.claude/worktrees/<name>" <name>`; never check it out in the main clone.
- A session the app started in a worktree of its own (a generated name on a `claude/` branch) creates the named worktree as above and switches into it before changing anything. Leave the app's worktree to the app.
- Once the PR merges, remove the worktree and its branch from the main clone: `git worktree remove "$ROOT/.claude/worktrees/<name>"`, then `git branch -d <name>`. If either refuses, because of uncommitted work or a squash merge git cannot see, report it and ask; never force.
