<div align="center">

# claude-code-statusline

**Zero-dependency bash statusline for [Claude Code](https://docs.claude.com/en/docs/claude-code).**
One file. No installs. True-color gradients. Live context, session, and weekly usage at a glance.

![deps](https://img.shields.io/badge/deps-zero-blue)
![bash](https://img.shields.io/badge/shell-bash-brightgreen)
![license](https://img.shields.io/badge/license-MIT-lightgrey)

</div>

---

```text
~/dir   @feat/branch/path   model/effort   s42%/200k   h27%>1h   w74%>1d
```

<table>
<tr><th align="left">Segment</th><th align="left">Meaning</th></tr>
<tr><td><code>~/dir</code></td><td>Working directory basename</td></tr>
<tr><td><code>@branch</code></td><td>Current git branch — slashes preserved in full</td></tr>
<tr><td><code>model/effort</code></td><td>Claude model with reasoning-effort level</td></tr>
<tr><td><code>s%/cap</code></td><td>Live <strong>session context window</strong> usage. Cap auto-detects (200k / 1M)</td></tr>
<tr><td><code>h%&gt;t</code></td><td>5-hour session quota with reset countdown</td></tr>
<tr><td><code>w%&gt;t</code></td><td>7-day weekly quota with reset countdown</td></tr>
</table>

All percentages share a single blue → green → yellow → orange → red gradient, calibrated so the number that deserves your attention pulls your eye first.

---

## Install

```bash
mkdir -p ~/.claude/terminal
curl -fsSL https://raw.githubusercontent.com/mandriao84/claude-code-statusline/main/statusline.sh \
  -o ~/.claude/terminal/statusline.sh
chmod +x ~/.claude/terminal/statusline.sh
```

Merge into `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "LC_ALL=C LANG=C bash \"$HOME/.claude/terminal/statusline.sh\""
  }
}
```

Restart Claude Code. Done.

> **Project-scoped install:** drop the script at `<project>/.claude/terminal/statusline.sh` and point the command at `$CLAUDE_PROJECT_DIR`.

---

## Why

Claude Code's built-in statusline omits the numbers that actually govern your day on Pro/Max plans:

- How much of the **context window** the current session is burning, updated **mid-turn** as tools stream output.
- The rolling **5-hour** and **7-day** usage percentages — and when each resets.

This script renders all three, colored so the critical one is the one you see.

---

## Features

- **Single file, zero dependencies.** Pure bash. No `jq`, no `curl`, no Python, no Node. Runs wherever Claude Code runs.
- **Authoritative context tracking.** Reads `context_window.used_percentage` and `context_window.context_window_size` directly from Claude Code's statusline input. No transcript scraping, no tokenizer heuristic, no model-name guessing — the number is exactly what Claude Code reports.
- **Dynamic context cap.** Whatever cap Claude Code exposes gets rendered, formatted as `k`/`M`.
- **True 24-bit color.** ANSI truecolor with faint-intensity pairings. No Unicode icons. Identical render in iTerm2, Ghostty, Kitty, Alacritty, WezTerm, Terminal.app, Windows Terminal, VS Code terminal.
- **Branch paths, intact.** `feat/scope/thing` renders fully — no last-segment truncation.
- **Graceful degradation.** Missing rate-limit fields → percentages hidden. Missing git repo → branch hidden. Missing transcript → context hidden. Nothing ever breaks the line.
- **Fork-floor fast.** Hot path is bash built-ins and a single bounded `grep`/`wc` on the transcript.

---

## Architecture

Everything lives in [`statusline.sh`](./statusline.sh). Per render:

1. Slurp stdin with a bash built-in read.
2. Extract fields via `BASH_REMATCH` against the Claude Code statusline JSON.
3. Read `.git/HEAD` directly — no git subprocess; strip the `refs/heads/` prefix so slashes survive.
4. Scan project/user `settings.json` line-by-line, break on first match, for the effort level.
5. Extract authoritative context-window fields (`context_window_size`, `current_usage.{input,cache_read,cache_creation}_tokens`) straight from the statusline input JSON.
6. Acquire epoch time only if a countdown will actually be drawn.
7. Compose with a 5-stop gradient function, a relative-time humanizer, and one final `printf`.

---

## Configuration

All user-facing choices — colors, gradient stops, separator width, segment labels, context caps — are plain constants at the top of the file. No config file, no env vars. Grep and edit.

---

## Compatibility

| Platform | Status |
|---|---|
| macOS | Ships-shell ready |
| Linux | Any modern distribution's bash |
| Windows | Under WSL |
| tmux / screen | Requires truecolor passthrough in your multiplexer config |

---

## Keywords

`claude-code` · `statusline` · `anthropic` · `context-window` · `rate-limit` · `5-hour-limit` · `weekly-quota` · `session-quota` · `pro` · `max` · `terminal` · `ansi` · `truecolor` · `gradient` · `bash` · `zero-dependency` · `dotfiles`

---

## License

MIT
