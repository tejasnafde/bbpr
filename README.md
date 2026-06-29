# bbpr

Fetch Bitbucket Cloud pull requests for AI agent review.

```
bbpr 605                                              # review PR from current repo
bbpr https://bitbucket.org/ws/repo/pull-requests/605 # review any PR by URL
bbpr 605 diff                                         # just the diff
bbpr 605 comments                                     # just the comments
bbpr setup                                            # configure credentials
```

Works with Claude Code, Cursor, Codex CLI, OpenCode — any agent that can run shell commands.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tejasnafde/bbpr/main/install.sh)
```

Or clone if you prefer:

```bash
git clone https://github.com/tejasnafde/bbpr.git && cd bbpr && ./install.sh
```

The installer:
1. Creates a Python venv at `~/.local/bitbucket-review/`
2. Installs `bbpr` to `~/.local/bin/`
3. Installs the agent skill file to your agent's skills directory (you choose where)
4. Walks you through setting up Bitbucket credentials

## Auth

You'll need an Atlassian API token with these scopes:
- `read:pullrequest:bitbucket`
- `read:repository:bitbucket`
- `read:account`

**Create one at:** https://id.atlassian.com/manage-profile/security/api-tokens

Then run the setup wizard:

```bash
bbpr setup
```

Or set env vars directly:

```bash
export BITBUCKET_EMAIL=you@company.com
export BITBUCKET_API_TOKEN=your-token
```

Or write them to `~/.config/bbpr/credentials`:

```
BITBUCKET_EMAIL=you@company.com
BITBUCKET_API_TOKEN=your-token
```

(The file should be `chmod 600`. `bbpr setup` handles this automatically.)

## Usage

```
bbpr <pr-url-or-number> [section]
```

| Section | Output |
|---------|--------|
| `info` | PR title, state, author, branches, description, reviewers |
| `files` | Changed files with +/- line counts |
| `diff` | Full unified diff |
| `comments` | All review comments with file/line context |
| `activity` | Approval/update timeline |
| `all` | Everything (default) |

## Agent skill file

`install.sh` installs `skill.md` (or `skill.mdc` for Cursor) to your agent's skills
directory. This teaches the agent:
- When to call `bbpr` (trigger phrases, Bitbucket URLs)
- Which section to fetch for a given task
- How to synthesize a review from the output
- What to tell you if credentials are missing

Supported agent locations detected automatically:

| Agent | Skill path |
|-------|-----------|
| Claude Code | `~/.claude/skills/bbpr.md` |
| Cursor | `~/.cursor/rules/bbpr.mdc` |
| OpenCode | `~/.config/opencode/bbpr.md` |
| Codex CLI | `~/.codex/bbpr.md` |
| Custom | any path you enter during install |

## Uninstall

```bash
./uninstall.sh
```

Removes the binary, venv, credentials, and any installed skill files.

## Requirements

- macOS or Linux
- Python 3.8+
- Internet access to `api.bitbucket.org`
