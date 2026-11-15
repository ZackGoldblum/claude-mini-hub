# Send work from your MacBook to an always-on Mac Mini with Claude Code

This kit connects a MacBook and a Mac Mini so that you can say "have my Mini do X" in Claude Code on the laptop, close the lid, and find the result later. You give the folder to Claude Code and it walks you through the setup, one step at a time. Plan for 30 to 45 minutes.

## What you end up with

- **A private network** between your devices (Tailscale), so the laptop reaches the Mini from any Wi-Fi
- **A one-word connection**: `ssh mini` opens a terminal on the Mini, with a key file in place of a password
- **Sessions that keep running** on the Mini after you disconnect (tmux)
- **A Claude that knows the Mini exists**: a skill and a few standing notes, so "have my Mini…" works in any session

## What you need

- A MacBook with Claude Code installed and signed in
- A Mac Mini that stays powered on, with its screen and keyboard available for the first 10 minutes
- The login password for each Mac
- A Tailscale account (free for personal use; you can sign in with Google, Microsoft, or Apple)

## Start

1. On the laptop, open Terminal and start Claude Code:

   ```bash
   claude
   ```

2. Paste this line:

   ```text
   Set up my Mini with https://github.com/ZackGoldblum/claude-mini-hub. Start with the check.
   ```

Claude downloads the kit into `~/claude-mini-hub`, reads `CLAUDE.md` and `PLAYBOOK.md` there, runs a read-only check, and takes you through each step that is left. It asks your permission before it downloads or runs anything. Two steps happen at the Mini itself (installing Tailscale and flipping three switches in System Settings). Everything after that happens from the laptop.

To come back to the setup later, start `claude` and say "Run the check in ~/claude-mini-hub".

## If you are Claude Code and you were given this link

The person wants you to run this setup with them. Do these three things in order:

1. Download the kit into `~/claude-mini-hub`. This command needs no git and no GitHub account. Skip it if the folder already contains `PLAYBOOK.md`.

   ```bash
   mkdir -p ~/claude-mini-hub && curl -fsSL https://github.com/ZackGoldblum/claude-mini-hub/archive/refs/heads/main.tar.gz | tar -xz --strip-components 1 -C ~/claude-mini-hub
   ```

2. Read `~/claude-mini-hub/CLAUDE.md` and `~/claude-mini-hub/PLAYBOOK.md` in full, and follow them. `CLAUDE.md` says how to guide this person and what you must not do.
3. Run the check and show the result:

   ```bash
   bash ~/claude-mini-hub/scripts/check.sh
   ```

The playbook writes commands as `bash scripts/name.sh`. Run each one by its full path, `bash ~/claude-mini-hub/scripts/name.sh`. The scripts find their own files from any working directory.

## What is in the folder

| File | Purpose |
| --- | --- |
| `PLAYBOOK.md` | The 7 steps, with troubleshooting and how to undo each piece |
| `CLAUDE.md` | Instructions Claude reads when started here: how to guide you, what it must not do |
| `scripts/check.sh` | Read-only status check; run it any time |
| `scripts/laptop-ssh.sh` | Creates the SSH key and the `mini` shortcut on the laptop |
| `scripts/prepare-mini.sh` | Prepares the Mini over SSH: folders, Claude Code, helper commands |
| `scripts/install-notes.sh` | Installs the `mini` skill and the standing notes on both Macs |
| `files/` | What gets installed: the skill, the notes, `dev`, `start-task`, tmux settings |

## What it changes on your Macs

Every change is additive and listed under "Undo" in `PLAYBOOK.md`. Nothing is exposed to the public internet: the Mini is reachable only from devices signed in to your Tailscale account.

- **Laptop**: `~/.ssh/id_mini` (a new key), one block in `~/.ssh/config`, `~/.claude/skills/mini/`, one section in `~/.claude/CLAUDE.md`
- **Mini**: one line in `~/.ssh/authorized_keys`, PATH lines in `~/.zshenv`, `~/dev/`, `~/.local/bin/dev` and `start-task`, `~/.tmux.conf` if none exists, one section in `~/.claude/CLAUDE.md`, plus Claude Code, Homebrew, and tmux if they are missing

## Day-to-day use

Say these in any Claude Code session on the laptop:

- "Have my Mini …" starts a task there and tells you its name
- "Check on my Mini" reports whether tasks are working, finished, or stuck
- "Bring the result back and open it" copies the task folder to `~/Downloads`

To watch a task live, type `ssh mini dev task_name` in Terminal. Press Ctrl+b, then d, to leave without stopping it.
