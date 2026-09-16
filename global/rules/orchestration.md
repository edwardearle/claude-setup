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
- Weigh the options in the following order when designing and implementing shippable solutions: intelligence > taste > cost.
- **Bulk mechanical work** (implementing an approved plan phase against a clear spec, migrations, data transformation, test scaffolding): the cheapest model with intelligence >= 7. Codex when available, otherwise Opus.
- **Anything user-facing** (UI, copy, API shape, error messages): taste >= 8.
- **Reviews** come from a **different model** than the one that wrote the code. Use a cheaper model for reviewing smaller changes only. Prefer Fable or Opus when shipping meaningful changes. Add Codex as a second, independent opinion when it is available; disagreement between reviewers is signal.
- **Search and summarise** (find the files, read the logs, condense a long document): Haiku or the built-in `Explore` agent. Never Haiku for code that ships.
- **Design decisions, spec writing, plan design, anything ambiguous**: the main session, Fable or Opus.

### Effort

Effort is how much reasoning is spent before answering, chosen independently of the model. The levels are `low`, `medium`, `high` (the default), `xhigh` and `max`. Set one with `/effort <level>` for the session, with `effortLevel` in `settings.json` for a persistent default (`max` is not accepted there), or with `effort:` in a skill or agent file to pin that one component.

- **Default to high.** It is calibrated for most work and is the right starting point.
- **Drop to low or medium** when the shape of the work is already decided: applying an approved plan phase, renames, formatting, moving files, running a command and reporting what came back, drafting prose from material already in context. A long run of simple steps is the best case for dropping, because effort is paid on every step.
- **Raise to xhigh** for a problem that has already survived one attempt at high, for concurrency and ordering bugs, for a decision that is expensive to reverse (a schema, an API contract, an auth model), for security review, and for anything I will struggle to check myself.
- **Reserve max** for a single genuinely hard problem, and say why before reaching for it. It is session-only by design.
- **Raise effort before changing model.** If the model does change, reset effort to the default: the same level does not mean the same amount of work on a different model.
- Too little effort can cost more than too much. An under-powered run stops early and needs follow-up prompts to finish the job.
- Fanning out multiplies whatever level is in force. Pin `effort:` on an agent that should not follow the session, as `flow:spec-checker` does at `low` and `flow:reviewer` at `high`.

### Mechanics

- Claude models: the `Agent` tool's `model` parameter. Independent agents go in one message so they run in parallel.
- Anything that reads across many files goes to a subagent; keep only the conclusion.

### Codex

Codex is billed against an OpenAI API key, metered per token, with no subscription ceiling to absorb a mistake. Treat each `codex exec` as a purchase.

- Model identifiers for `-m`: `gpt-6-astra` and `gpt-5.6-sol` are the two rows in the table above. Two cheaper rungs exist and are not yet ranked there: `gpt-5.6-terra` for everyday work and `gpt-5.6-luna` for extraction, classification and other repeatable transformation. Add them to the table if they earn a place.
- Review or investigation: `codex exec --sandbox read-only -m <model> "<prompt>"`. Keep the sandbox flag immediately after `exec` so the permission allowlist matches without a prompt. Implementation uses `--sandbox workspace-write`, which writes to the working tree and will ask for approval. Pass `-C <path>` to set the working directory rather than relying on the shell, especially in a worktree.
- **The prompt is the entire job.** Codex sees nothing of this session: no conversation, no spec, no plan, no earlier decision. Paste the spec text, name the exact files, give the command that must pass, and say what must not change. "Implement the plan" will produce nothing useful.
- **Bound the run.** One phase, one spec, a named set of files. A Bash call is capped at ten minutes, and an open-ended "explore the repo and fix it" run is both the slowest and the dearest way to use the tool. Split anything larger.
- **Wrap it.** A thin `Agent` (`model: "sonnet"`) writes the self-contained prompt, runs the command, confirms the result compiles and the tests pass, and returns a short summary. That keeps the transcript out of the main context.
- If `codex` is not on PATH, skip the Codex rows silently and use the Claude alternative. Do not attempt to install it.

### Context hygiene

- Never paste large tool output into the main conversation. Save it to the scratchpad and read the parts you need.
- Parallel implementation happens in separate git worktrees, one agent each. Never two agents in one working tree.
