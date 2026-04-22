# claude-code-statusline

Zero-dependency, single-file bash statusline for [Claude Code](https://docs.claude.com/en/docs/claude-code). Renders working directory, git branch, Claude model with effort level, 5-hour session usage, and 7-day weekly usage — each percentage colored on a continuous blue→green→yellow→orange→red gradient, with reset countdowns in faint paired tones. One file, no installs, runs in every terminal that runs Claude Code.

![deps](https://img.shields.io/badge/deps-zero-blue) ![bash](https://img.shields.io/badge/shell-bash-brightgreen) ![license](https://img.shields.io/badge/license-MIT-lightgrey)

```
~/dir   @branch   model effort   h27% >1h   w74% >1d
```

- `~/dir` — working directory basename, faint pale cyan
- `@branch` — current git branch, pale cyan
- `model effort` — Claude model name with reasoning-effort level, in Anthropic brand terracotta; effort dimmed
- `h27% >1h` — 5-hour session quota, colored on the gradient, with reset countdown
- `w74% >1d` — 7-day weekly quota, same treatment

Percentage color follows a 5-stop gradient calibrated so weekly quota pulls your eye the moment it crosses the warning band.

## Install

Pick the script up and wire it into your Claude Code settings:

```bash
mkdir -p ~/.claude/terminal
curl -fsSL https://raw.githubusercontent.com/mandriao84/claude-code-statusline/main/statusline.sh \
  -o ~/.claude/terminal/statusline.sh
chmod +x ~/.claude/terminal/statusline.sh
```

Then merge this into `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "LC_ALL=C LANG=C bash \"$HOME/.claude/terminal/statusline.sh\""
  }
}
```

Restart your Claude Code session. Done.

For a project-scoped install, put the script under `<project>/.claude/terminal/statusline.sh` and point the command at `$CLAUDE_PROJECT_DIR` instead of `$HOME`.

## Why

Claude Code's built-in statusline exposes context-window tokens but not the numbers that actually matter on Pro/Max plans: the rolling 5-hour session usage and 7-day weekly quota, plus when each resets. Those fields are present in the statusline input JSON. This script renders them, with color calibrated so the critical one catches your eye.

## Features

- **Single file, zero dependencies.** Pure bash. No `jq`, no `curl`, no Python, no Node runtime. Runs wherever Claude Code runs.
- **Fast.** Extraction is done with bash regex and parameter expansion; no subshells in the hot path. Render cost sits near the bash fork-and-exec floor.
- **True 24-bit color.** ANSI truecolor foregrounds with faint-intensity styling. No Unicode icons needed. Identical render in iTerm2, Ghostty, Kitty, Alacritty, WezTerm, Terminal.app, Windows Terminal, VS Code terminal.
- **Safe reset-time caching.** When bash lacks a builtin epoch, the script reads a cached timestamp and refreshes it in a detached background job — no blocking fork per render.
- **Graceful degradation.** Missing rate-limit fields → percentages hidden. Missing git repo → branch hidden. Missing effort setting → bare model name. Nothing ever breaks the line.

## Architecture

Everything lives in [`statusline.sh`](./statusline.sh). Per render the script:

1. Slurps stdin with a bash builtin read.
2. Extracts fields via `BASH_REMATCH` against the Claude Code statusline JSON.
3. Reads `.git/HEAD` directly — no git subprocess.
4. Scans `settings.json` line-by-line, breaking on the first match.
5. Acquires epoch time only when a countdown will actually be drawn.
6. Composes the line with a 5-stop gradient function, a relative-time humanize function, and a single final `printf`.

## Configuration

All user-facing choices — colors, gradient stops, separator width, segment labels — are plain constants at the top of the file. No config file, no env vars. Grep and edit.

## Compatibility

- **macOS** — works on the shell shipped with the OS.
- **Linux** — works on any modern distribution's bash.
- **Windows** — works under WSL.
- **tmux / screen** — needs truecolor passthrough enabled in your multiplexer config.

## Keywords

`claude-code` · `claude-code-statusline` · `statusline` · `status-line` · `anthropic` · `claude` · `claude-cli` · `rate-limit` · `usage-tracker` · `5-hour-limit` · `weekly-quota` · `session-quota` · `context-window` · `pro` · `max` · `terminal` · `ansi` · `truecolor` · `gradient` · `bash` · `zero-dependency` · `dotfiles` · `developer-tools`

## License

MIT
