### Picking models for subagents and delegated work

Rankings are 1-10, higher is better, with the exception of cost where lower is better. **Cost** reflects what I actually pay under my plans, not list price. **Intelligence** is how hard a problem the model can be handed unsupervised. **Taste** covers UI/UX, code quality, API design and copy. These are starting estimates; tune them as experience accumulates.

| Model | Cost | Intelligence | Taste | How to reach it |
|-------|------|--------------|-------|-----------------|
| Haiku 4.5 | 1 | 2 | 3 | `Agent` with `model: "haiku"` |
| Sonnet 5 | 3 | 5 | 6 | `Agent` with `model: "sonnet"` |
| Opus 5 | 6 | 7 | 8 | `Agent` with `model: "opus"` |
| Fable 5.1 | 9 | 10 | 9 | `Agent` with `model: "fable"`, or the main session |
| GPT-5.6 Sol via Codex | 6 | 7 | 5 | `codex exec` through Bash, **only when `codex` is on PATH** |
| GPT-6 Astra via Codex | 10 | 9 | 7 | `codex exec` through Bash, **only when `codex` is on PATH** |

### How to apply

- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output does not meet the bar, rerun or redo with a smarter one without asking. Judge the output, not the price tag. Escalating costs less than shipping something mediocre.
- Cost should not be the primary motivator for chosing the right model. Take advantage of low cost models for low risk, low complexity work, or to gain information, or to experiment before moving on to more expensive models for higher impact work.
- **Bulk mechanical work** (implementing an approved plan phase against a clear spec, migrations, data transformation, test scaffolding): the cheapest model with intelligence >= 7. Codex when available, otherwise Sonnet.
- **Anything user-facing** (UI, copy, API shape, error messages): taste >= 8.
- **Reviews** come from a **different model** than the one that wrote the code. Use a cheaper model for reviewing smaller changes only. Prefer Fable or Opus when shipping meaningful changes. Add Codex as a second, independent opinion when it is available; disagreement between reviewers is signal.
- **Search and summarise** (find the files, read the logs, condense a long document): Haiku or the built-in `Explore` agent. Never Haiku for code that ships.
- **Design decisions, spec writing, plan design, anything ambiguous**: the main session, Fable or Opus.

### Mechanics

- Claude models: the `Agent` tool's `model` parameter. Independent agents go in one message so they run in parallel.
- Codex: `codex exec "<self-contained prompt>"` via Bash from the working directory. For review or investigation use `codex exec -s read-only "<prompt>"`. Codex has none of this session's context, so the prompt must carry the spec, the constraints and the acceptance criteria.
- Keep Codex output out of the main context: spawn a thin `Agent` (`model: "sonnet"`, `effort "low"`) whose job is to write the self-contained prompt, run `codex exec`. Use `schema` on the prompt wrapper to get structured output.
- Always label these agents with `gpt-5.6:` or `gpt-6:` prefix (as appropriate for the task) so that it is clear that the real agent is codex rather than the wrapper's claude model
- Confirm the result compiles and tests pass, and return a short summary.
- If `codex` is not on PATH, skip the Codex rows silently and use the Claude alternative. Do not attempt to install it.

### Context hygiene

- Anything that reads across many files goes to a subagent; keep only the conclusion.
- Never paste large tool output into the main conversation. Save it to the scratchpad and read the parts you need.
- Parallel implementation happens in separate git worktrees, one agent each. Never two agents in one working tree.
