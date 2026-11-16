---
name: mini
description: Use when the user asks to run, start, check on, watch, or stop work on their always-on Mac Mini. Typical requests are "have my Mini do X", "run this on the Mini", "check on my Mini", "what is the Mini doing", "is the Mini task done".
---

# Run work on the Mac Mini

The user has an always-on Mac Mini that this laptop reaches with `ssh mini` over Tailscale (a private network between their devices). The Mini has its own Claude Code, its own memory, and its own files. It knows nothing from this conversation, so every task you send must carry its full instructions.

Do the steps yourself. The user is not a programmer. Report in plain words what you did and how they can watch.

## Rules for every command

- Use `ssh -T mini '...'` for commands. The `-T` stops SSH from asking for a screen it does not need.
- If `ssh -T -o ConnectTimeout=8 mini true` fails, stop and tell the user: check that Tailscale is connected on the laptop (menu bar icon) and that the Mini is powered on. Do not retry in a loop.
- Never send patient information or other confidential data to the Mini unless the user has said this machine is approved for it.
- Do not use `--dangerously-skip-permissions`. Tasks run in auto mode, where a second model screens each action.

## Start a task

1. Pick a short task name: lowercase letters, digits, hyphens (for example `tailscale-explainer`). The Mini works in `~/Desktop/Claude Code Projects/<name>`, a folder the user can see on the Mini's Desktop. The path contains spaces, so keep the quotes exactly as shown in the commands below.
2. Write a brief to a temporary file on the laptop. Use the template below. Fill in every section from what the user asked and from this conversation. If the task depends on files that exist only on the laptop, copy them in step 3.
3. Copy the brief, and any input files, to the Mini:

   ```bash
   ssh -T mini 'mkdir -p "$HOME/Desktop/Claude Code Projects/<name>"'
   scp -q /path/to/brief.md "mini:Desktop/Claude Code Projects/<name>/BRIEF.md"
   ```

4. Start it:

   ```bash
   ssh -T mini 'start-task <name> "$HOME/Desktop/Claude Code Projects/<name>/BRIEF.md"'
   ```

5. Wait 15 seconds, then look at the screen:

   ```bash
   ssh -T mini 'tmux capture-pane -p -t <name> | tail -30'
   ```

   `start-task` answers the "trust this folder" question itself. If the screen still shows that question, the cursor is on "No, exit": move down to "Yes, I trust this folder" and confirm:

   ```bash
   ssh -T mini 'tmux send-keys -t <name> Down Enter'
   ```

   Look again after 20 seconds. Confirm that Claude on the Mini has started working (it shows tool activity or text). If the screen shows a sign-in problem, tell the user to run `ssh mini`, then `claude auth login`, and follow the link.
6. Tell the user, in three lines: the task is running on the Mini, they can close the laptop, and how to follow it (see "What to tell the user").

## Brief template

```markdown
# Task: <one line>

You are running unattended on a Mac Mini. Nobody is watching this session and nobody can answer questions. Make reasonable choices, write them down, and keep going.

## What to do
<the request, with every detail the user gave; name files and formats exactly>

## Context you need
<who the result is for, preferences, anything from the laptop conversation that matters>

## Done means
<a check you can run yourself: the file exists and opens, the page loads, the numbers add up>

## When you finish
Write REPORT.md in this folder: what you did, where the results are (full paths), anything you were unsure about. If you cannot finish, write REPORT.md saying what blocked you, then stop.
```

## Check on a task

```bash
ssh -T mini 'dev -l'                                        # which sessions exist
ssh -T mini 'tmux capture-pane -p -t <name> | tail -40'     # what the screen shows now
ssh -T mini 'cat "$HOME/Desktop/Claude Code Projects/<name>/REPORT.md"'   # present only when finished
```

Summarize for the user: still working, finished (give the report's main points), or stuck (say on what).

## Check the setup

When the user says "run the Mini check", or when a connection problem needs diagnosing, run the read-only check from the setup kit and explain each `TODO` line in plain words:

```bash
bash ~/claude-mini-hub/scripts/check.sh
```

If that folder is missing, download the kit first with the command in [the kit's README](https://github.com/ZackGoldblum/claude-mini-hub).

## Bring results back

Copy the results to the laptop and open them:

```bash
scp -rq "mini:Desktop/Claude Code Projects/<name>" ~/Downloads/<name>
open ~/Downloads/<name>
```

## Add an instruction to a running task

```bash
ssh -T mini 'tmux send-keys -t <name> "your one-line instruction here" Enter'
```

The Mini's Claude reads it when its current step ends.

## Stop a task

Ask the user first, then:

```bash
ssh -T mini 'tmux kill-session -t <name>'
```

## What to tell the user

- Watch live: open a Terminal window and type `ssh mini dev <name>`. To leave without stopping it, press Ctrl+b, release, then press d.
- Ask later: "check on my Mini" in any Claude Code session on the laptop.
- The task keeps running with the laptop closed or off.
