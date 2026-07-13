# bbpr — Bitbucket PR review

## When to use

Invoke `bbpr` whenever the user:
- Pastes a Bitbucket PR URL (`https://bitbucket.org/workspace/repo/pull-requests/123`)
- Says "review PR 123", "look at PR 123", "what's in PR 123", "check this PR"
- Asks about a pull request, diff, or code review on Bitbucket
- Explicitly says "bbpr"

## Verify it's installed first

```
bbpr --help
```

If the command is not found, tell the user to run `./install.sh` from the bbpr repo.

## Commands

```
bbpr <pr-url-or-number> [section]
```

| Section | What it returns |
|---------|-----------------|
| `info` | PR title, state, author, branches, description, reviewers, approvals |
| `files` | Changed files with line add/remove counts |
| `comments` | All review comments (inline and general) with file/line context |
| `activity` | Timeline of approvals, change requests, and updates |
| `diff` | Full unified diff |
| `all` | Everything above (default) |

### Write actions

**Post through `bbpr`, not the API directly.** Do not read
`~/.config/bbpr/credentials` or call the Bitbucket REST API yourself — `bbpr`
already holds the auth and handles inline anchoring. Just run the commands below.

Require the `write:pullrequest:bitbucket` token scope.

```
bbpr <target> comment "text"                    # general PR comment
bbpr <target> comment "text" <path> <new-line>  # inline comment on a new-file line
bbpr <target> approve
bbpr <target> request-changes
bbpr <target> unapprove
```

For inline comments, `<new-line>` is the line number **in the new version of the
file** — read it straight off the `+`/context lines in the `diff` output (the
`@@ -old,n +new,m @@` hunk header gives the starting new-file line). Don't check
out the branch; the diff already carries the line numbers.

## Recommended review workflow

1. `bbpr <target> info` — understand scope, author, description, who's reviewing
2. `bbpr <target> files` — see what changed at a glance before diving in
3. `bbpr <target> diff` — read the actual code changes
4. `bbpr <target> comments` — check existing feedback before adding your own
5. Synthesize: write a summary of changes, flag key concerns, suggest improvements

For large PRs, fetch sections individually to avoid overwhelming context.

## PR number vs full URL

- **Number only** (e.g. `bbpr 123`): auto-detects workspace/repo from `git remote origin`
  in the **current working directory**. Only works if you're inside the relevant repo.
- **Full URL**: always works regardless of working directory. Prefer this when unsure.

## Handling auth errors

If `bbpr` exits with:
```
error: credentials not found.
Run 'bbpr setup' to configure...
```

Tell the user to run:
```
bbpr setup
```

This launches an interactive wizard that:
1. Prompts for Atlassian email + API token (input is hidden)
2. Verifies the credentials against the Bitbucket API before saving
3. Writes to `~/.config/bbpr/credentials` with `chmod 600`

**Token creation:** https://id.atlassian.com/manage-profile/security/api-tokens
Click **"Create API token with scopes"** (not the plain one). Required scopes: `read:user:bitbucket`, `read:pullrequest:bitbucket`. Add `write:pullrequest:bitbucket` for the write actions above.
