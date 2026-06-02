# bbpr distribution design — 2026-06-03

## Problem

`bbpr` is a working CLI that fetches Bitbucket Cloud PR data for AI agent review.
It exists on one machine with credentials hard-coded in `.zshrc`. Teammates can't
use it without manual setup steps that aren't documented anywhere.

## Goals

- One command to install (`./install.sh`)
- Guided credential setup (no manual env-var wrangling)
- Agent skill file auto-installed to whatever agent the teammate uses
- Works as a universal shell tool (Claude Code, Cursor, Codex CLI, OpenCode, anything with shell access)

## Chosen approach: install script + skill file

A single Git repo with two outputs:
1. **The CLI** — installed to `~/.local/bin/bbpr` backed by a private venv
2. **A skill file** — installed to the teammate's agent skill directory (their choice)

The CLI is the universal layer. The skill file is the Claude Code bonus that makes
the agent *know* about bbpr without the user having to explain it.

## Repo structure

```
bbpr/
├── bbpr              # Python CLI (setup subcommand added)
├── install.sh        # one-shot installer
├── uninstall.sh      # cleanup
├── skill.md          # agent skill (Claude Code, OpenCode, Codex CLI)
├── skill.mdc         # Cursor variant (same content + frontmatter)
├── README.md
└── docs/plans/
    └── 2026-06-03-bbpr-distribution-design.md
```

## install.sh flow

1. Check Python 3.8+ exists
2. Create `~/.local/bitbucket-review/.venv`, `pip install requests`
3. Copy `bbpr` to `~/.local/bin/bbpr`, rewrite shebang to venv python, `chmod +x`
4. Check if `~/.local/bin` is in PATH; offer to add to `~/.zshrc` if not
5. Skill installation:
   - Scan known locations: `~/.claude/skills/`, `~/.cursor/rules/`, `~/.config/opencode/`, `~/.codex/`
   - Show found locations; ask y/n per location
   - Offer a custom path
6. Run `bbpr setup` wizard (or skip if credentials already exist)

## bbpr setup subcommand

- Prompt for email + API token (hidden input)
- Show link to create Atlassian API token
- Verify credentials against `GET /2.0/user` before saving
- Write `~/.config/bbpr/credentials` with `chmod 600`

## Skill file content

Teaches agents:
- Trigger phrases ("review PR 123", Bitbucket URLs)
- Which subcommand to use for what
- Recommended review workflow (info → files → diff → comments → synthesize)
- How to handle auth errors (tell user to run `bbpr setup`)
- When to use PR number vs full URL

## Considered alternatives

**pipx package** — cleaner packaging but requires pipx, no skill file story, more overhead.
Rejected: overkill for an internal team tool.

**Homebrew tap** — gold standard for Mac distribution.
Rejected: too much infra overhead for a first internal tool; revisit if the team grows.
