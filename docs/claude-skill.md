# Claude Skill for TorQ

A [Claude Code skill](https://docs.claude.com/en/docs/claude-code/skills) ships with this repo under [.claude/skills/torq-developer/](../.claude/skills/torq-developer/). It teaches Claude the TorQ conventions it wouldn't otherwise know — the guard pattern for config, `.servers.*` for connections, `.timer.repeat` for scheduling, `.api.add` for public functions, the EOD lifecycle, and the two-stage workflow for adding a new process.

With the skill loaded, Claude produces code that fits a TorQ codebase instead of plausible-looking q that ignores the framework.

## What's in the skill

- `SKILL.md` — the core rules (namespace, config, logging, handlers, timers, schemas, subscriptions, connections, gateway patterns, q-language pitfalls, EOD). Always loaded.
- `torq-internals.md` — startup order, EOD sequence, gateway request lifecycle, discovery protocol.
- `torq-patterns.md` — namespace table, IPC and subscription patterns, caching, async helpers, error-trapping idioms.
- `torq-process-templates.md` — `process.csv` columns, `setenv.sh`, `torq.sh` commands, deployment checklist, and templates for minimal process, feedhandler, RDB, WDB, gateway.
- `q-language-reference.md` — general q/kdb+ reference (not TorQ-specific).
- `kdb-ecosystem.md` — integrating kdb+ with Python (PyKX/embedPy), Grafana, REST/HTTP, WebSockets, C API.

The companion files are loaded on demand when the current task matches their topic.

## Using the skill when deploying TorQ

The skill lives in `.claude/skills/torq-developer/` so that Claude Code auto-discovers it whenever it is invoked inside a clone of this repo. No setup required — open the repo and ask Claude to make a change.

When you build your own application on top of TorQ (e.g. a fork, a starter-pack-style layered repo, or a project that vendors TorQ as a submodule), you have three options for making the skill available:

1. **Per-project** — copy `.claude/skills/torq-developer/` into your downstream repo at the same path. The skill travels with the repo and every teammate who clones it gets it automatically.

2. **Per-user (global)** — copy the directory to `~/.claude/skills/torq-developer/` on your machine. The skill is then available to Claude Code in every project you open, not just TorQ ones. Useful if you work across several TorQ-based repos.

   ```bash
   mkdir -p ~/.claude/skills
   cp -r /path/to/TorQ/.claude/skills/torq-developer ~/.claude/skills/
   ```

3. **Submodule / symlink** — if you vendor TorQ as a git submodule, symlink `.claude/skills/torq-developer` in your parent repo to the path inside the submodule. The skill stays pinned to the TorQ version you're running.

## Extending the skill for your deployment

The shipped skill covers the framework. Any conventions specific to your deployment — naming, allowed ports, required process attributes, site-local EOD hooks — belong in a separate skill or in `CLAUDE.md` at the root of your downstream repo. Do not bloat `SKILL.md`: a skill that tries to encode every edge case drowns out the rules that matter most.

The blog post [Can Claude Talk TorQ?](https://www.dataintellect.com/thoughts/) walks through designing a skill and using it to build a new TorQ process end-to-end.