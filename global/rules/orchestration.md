### Picking models for subagents and delegated work

Rankings are 1-10, higher is better, with the exception of cost where lower is better. **Cost** reflects what I actually pay under my plans, not list price. **Intelligence** is how hard a problem the model can be handed unsupervised. **Taste** covers UI/UX, code quality, API design and copy. These are starting estimates; tune them as experience accumulates.

| Model | Cost | Intelligence | Taste | How to reach it |
|-------|------|--------------|-------|-----------------|
| Haiku 4.5 | 1 | 2 | 3 | `Agent` with `model: "haiku"` |
| Sonnet 5 | 3 | 5 | 6 | `Agent` with `model: "sonnet"` |
| Opus 5.5 | 5 | 9 | 8 | `Agent` with `model: "opus"`, or the main session |
| Fable 5.1 | 9 | 10 | 9 | `Agent` with `model: "fable"` |
| GPT-5.6 Sol via Codex | 6 | 7 | 5 | `codex exec` through Bash, **only when `codex` is on PATH** |
| GPT-6 Astra via Codex | 10 | 9 | 7 (9 for SVG) | `codex exec` through Bash, **only when `codex` is on PATH** |

### Roles

Skills and agents name a role, never a model. This table is the only place a role is mapped to a model, so changing a route is an edit here and nowhere else.

| Role | Work | Model | Escalation or fallback |
|------|------|-------|------------------------|
| **Lead** | Design decisions, specs, plan design, anything ambiguous, and checking what other roles return | The main session (Opus) | Fable when Opus has not got there or the problem is hard enough to justify the cost |
| **Explorer** | Find the files, count, read the logs, condense a long document, gather facts | Haiku, or the built-in `Explore` agent | None. Never Haiku for code that ships |
| **Executor** | An approved plan phase against a clear brief, migrations, data transformation, test scaffolding | Sonnet | Opus where the plan leaves real decisions open. Not Codex: the briefing costs more than the phase |
| **UI builder** | Anything user-facing: UI, copy, API shape, error messages | Opus | Fable when Opus's output misses the bar |
| **Prose writer** | Documentation: guides, docs fixes, a README, anything a person reads cold | Opus | Fable for a README or another document newcomers read cold, and whenever Opus's output misses the bar |
| **Illustrator** | Drawing an SVG, static or animated | Astra via Codex | Fable, then Opus, saying first that Codex is unavailable |
| **Checker** | Comparison jobs: is this document still true, which scenarios have tests | Sonnet at low or medium effort | None. It reports; it never rewrites |
| **Reviewer** | Independent review of a diff against its specs | Keyed on this session's model: Opus if this session is Fable or Sonnet, Fable if it is Opus | None |
| **Second opinion** | An independent review from a different lineage, alongside the reviewer | Codex, briefed and run by a thin Sonnet agent at low effort | Skipped when `codex` is not on PATH |

The agents with a model in their frontmatter follow this table: `flow:docs-checker` and `flow:spec-checker` are checkers; `flow:reviewer` defaults to Opus but `/flow:review` always launches it with the reviewer role's model.

### Claude by default

Delegate to a Claude model unless you can say what Codex buys that a Claude model cannot. That it is installed is not a reason.

The table understates what Codex costs. It arrives with none of this session's context, so every call needs a self-contained brief, a wrapper agent to write it, and a result read back and verified: two model calls and a full restatement of the problem for one unit of work. A Claude subagent inherits the repo and the conversation and starts on the problem. Spend Codex on independence, not on throughput.

Codex earns its place when:

- **Reviewing.** A different lineage disagrees for different reasons, and that disagreement is what you are buying. This is the routine case, and usually the only one.
- **Two Claude attempts have failed.** A different prior beats a third go with the same one.
- **The change is load-bearing.** Migrations, security-sensitive work, architectural commitments: an independent opinion is cheap next to being wrong.
- **The artefact is an SVG.** Astra draws better SVG than any Claude model, static or animated. This is a capability gap, not a preference.

Anything else goes to Claude. If you find yourself briefing Codex because the work is large rather than because it is contested, use the executor.

### How to apply

- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output does not meet the bar, rerun or redo with a smarter one without asking. Judge the output, not the price tag. Escalating costs less than shipping something mediocre.
- Cost should not be the primary motivator for choosing the right model. Take advantage of low cost models for low risk, low complexity work, or to gain information, or to experiment before moving on to more expensive models for higher impact work.
- **Illustrator over UI builder.** An icon, an illustration, a diagram or a motion piece goes to the illustrator even though it is UI, whether it ships as a file or inline in markup. Brief it with the dimensions, the palette, the theming rules and whether motion is wanted. If the result misses the brief, re-brief it rather than patching it by hand; wiring it into the markup is not patching. Changing an SVG that already exists, whether a fill, a size, a `viewBox` or an `aria-` attribute, is an ordinary code change and goes where it otherwise would, as does code that emits SVG at runtime, such as a chart component.
- **Imagery nobody asked for**: ask first, in any format, SVG included. Do not decide on the user's behalf that a deliverable wants a picture: propose it in one line and wait. Once it has been asked for, it follows the roles above. A raster image needs a tool that can generate one; if the session has none, say so rather than substituting something else.
- **Reviews** come from a **different model** than the one that wrote the code. Use a cheaper model for reviewing smaller changes only. Prefer Fable or Opus when shipping meaningful changes. Add the second opinion when it is available; disagreement between reviewers is signal.
- **Writing in your own model.** When the prose writer or UI builder role maps to the model this session is running, do the work here rather than launching an agent for it. Every other role is always delegated.

### Mechanics

- Claude models: the `Agent` tool's `model` parameter. Independent agents go in one message so they run in parallel.
- Codex: `codex exec "<self-contained prompt>"` via Bash from the working directory. For review or investigation use `codex exec -s read-only "<prompt>"`. Which model that reaches is whatever Codex is configured to default to; where the choice matters, pin it with `-m`, e.g. `-m gpt-6-astra`. Codex has none of this session's context, so the prompt must carry the spec, the constraints and the acceptance criteria.
- Keep Codex output out of the main context: spawn the second opinion role's thin wrapper agent, whose job is to write the self-contained prompt, run `codex exec`. Use `schema` on the prompt wrapper to get structured output.
- Always label these agents with `gpt-5.6:` or `gpt-6:` prefix (as appropriate for the task) so that it is clear that the real agent is codex rather than the wrapper's claude model
- Codex runs on plan credits until they are gone, then `codex exec --profile api` bills the card. One more reason not to spend it on work the executor would have done.
- Confirm the result compiles and tests pass, and return a short summary.
- If `codex` is not on PATH, skip the Codex routes silently and use the Claude alternative. Do not attempt to install it. The exception is the illustrator: say that Codex is unavailable before falling back, since the drop in quality is visible.

### Context hygiene

- Anything that reads across many files goes to a subagent; keep only the conclusion.
- Never paste large tool output into the main conversation. Save it to the scratchpad and read the parts you need.
- Parallel implementation happens in separate git worktrees, one agent each. Never two agents in one working tree.
