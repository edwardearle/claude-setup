### Picking models for subagents and delegated work

Rankings are 1-10, higher is better, with the exception of cost where lower is better. **Cost** reflects what I actually pay under my plans, not list price. **Intelligence** is how hard a problem the model can be handed unsupervised. **Taste** covers UI/UX, code quality, API design and copy. These are starting estimates; tune them as experience accumulates.

| Model | Cost | Intelligence | Taste | How to reach it |
|-------|------|--------------|-------|-----------------|
| Haiku 4.5 | 1 | 4 | 3 | `Agent` with `model: "haiku"` |
| Sonnet 5 | 4 | 7 | 7 | `Agent` with `model: "sonnet"` |
| Opus 5 | 7 | 8 | 8 | `Agent` with `model: "opus"` |
| Fable 5.1 | 9 | 9 | 9 | `Agent` with `model: "fable"`, or the main session |
| GPT-5.5 via Codex | 2 | 8 | 5 | `codex exec` through Bash, **only when `codex` is on PATH** |

### How to apply

- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output does not meet the bar, rerun or redo with a smarter one without asking. Judge the output, not the price tag. Escalating costs less than shipping something mediocre.
- Cost is a tie-breaker only. For anything that ships, intelligence > taste > cost.
- **Bulk mechanical work** (implementing an approved plan phase against a clear spec, migrations, data transformation, test scaffolding): the cheapest model with intelligence >= 7. Codex when available, otherwise Sonnet.
- **Anything user-facing** (UI, copy, API shape, error messages): taste >= 7.
- **Reviews** come from a **different model** than the one that wrote the code. Prefer Fable or Opus. Add Codex as a second, independent opinion when it is available; disagreement between reviewers is signal.
- **Search and summarise** (find the files, read the logs, condense a long document): Haiku or the built-in `Explore` agent. Never Haiku for code that ships.
- **Design decisions, spec writing, plan design, anything ambiguous**: the main session, Fable or Opus.

### Mechanics

- Claude models: the `Agent` tool's `model` parameter. Independent agents go in one message so they run in parallel.
- Codex: `codex exec "<self-contained prompt>"` via Bash from the working directory. For review or investigation use `codex exec -s read-only "<prompt>"`. Codex has none of this session's context, so the prompt must carry the spec, the constraints and the acceptance criteria.
- Keep Codex output out of the main context: spawn a thin `Agent` (`model: "sonnet"`) whose job is to write the self-contained prompt, run `codex exec`, confirm the result compiles and tests pass, and return a short summary.
- If `codex` is not on PATH, skip the Codex rows silently and use the Claude alternative. Do not attempt to install it.

### Context hygiene

- Anything that reads across many files goes to a subagent; keep only the conclusion.
- Never paste large tool output into the main conversation. Save it to the scratchpad and read the parts you need.
- Parallel implementation happens in separate git worktrees, one agent each. Never two agents in one working tree.
