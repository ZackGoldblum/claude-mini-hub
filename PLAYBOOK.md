# Playbook: connect a MacBook to an always-on Mac Mini

This playbook has 7 steps. Steps 1 and 2 are done by hand, partly at the Mini. From step 3 on, everything happens on the laptop and Claude runs the commands. `bash scripts/check.sh` shows which steps are done.

Who does each step:

| Step | Where | Who | Time |
| --- | --- | --- | --- |
| 1. Tailscale on both Macs | both | person | 5 min |
| 2. Three switches on the Mini | Mini | person | 5 min |
| 3. SSH key and the `mini` shortcut | laptop | Claude, one pasted line by the person | 5 min |
| 4. Prepare the Mini | laptop | Claude, Homebrew line by the person | 5 to 20 min |
| 5. Sign Claude in on the Mini | laptop | person | 3 min |
| 6. Teach Claude about the Mini | laptop | Claude | 1 min |
| 7. First task | laptop | person | 5 min |

## Step 1: put both Macs on one private network (Tailscale)

Tailscale creates a private network between your own devices. Each device gets an address that starts with `100.` and that only your devices can reach, from any Wi-Fi.

On each Mac:

1. Open [the Tailscale download page](https://tailscale.com/download/mac) and install the app.
2. Open Tailscale. Its icon appears in the menu bar at the top right of the screen.
3. Sign in. Use the same account on both Macs.

Done when: the Tailscale menu on the laptop lists the Mini under your devices.

One setting for later: in the [Tailscale admin console](https://login.tailscale.com/admin/machines), open the menu next to the Mini and choose **Disable key expiry**. Without it the Mini drops off the network after 180 days until someone signs in again.

## Step 2: three switches on the Mini

Do this at the Mini's own keyboard and screen.

1. Open **System Settings > General > Sharing**. Turn on **Remote Login**. This lets another computer open a terminal on the Mini.
2. On the same page, turn on **Screen Sharing**. This lets the laptop show the Mini's screen later, so you won't need to walk to it.
3. Open **System Settings > Energy**. Turn on **Prevent automatic sleeping when the display is off**, **Wake for network access**, and **Start up automatically after a power failure**.
4. Open Terminal on the Mini and type `whoami`. Write down the answer. It is your username on the Mini.

Done when: the three settings are on and you know the Mini's username.

## Step 3: SSH key and the `mini` shortcut (laptop)

Secure Shell (SSH) opens a terminal on another computer. A key is a pair of files that replaces the password: the private half stays on the laptop, the public half goes on the Mini.

1. Find the Mini's Tailscale address. Run the check and read the "Other devices" line, or run:

   ```bash
   /Applications/Tailscale.app/Contents/MacOS/Tailscale status
   ```

2. Create the key and the shortcut. Replace the two values with the Mini's username and address:

   ```bash
   bash scripts/laptop-ssh.sh mini_username 100.101.102.103
   ```

3. The person pastes the line the script prints into a second Terminal window (Cmd+N). It looks like this, asks "Are you sure you want to continue connecting", (type `yes`), then asks for the Mini's login password once:

   ```bash
   ssh-copy-id -i ~/.ssh/id_mini.pub mini_username@100.101.102.103
   ```

4. Verify. This must print the Mini's name without asking for a password:

   ```bash
   ssh -T mini 'scutil --get ComputerName'
   ```

Then have the person try it themselves in the second window: `ssh mini`, then `hostname`, then `exit`. The prompt changes while they are on the Mini.

## Step 4: prepare the Mini (laptop)

This step creates the projects folder `~/ClaudeCodeProjects` on the Mini, installs Claude Code there, and copies two helper commands: `dev` (open a session) and `start-task` (start an unattended Claude session).

```bash
bash scripts/prepare-mini.sh
```

If the script reports that tmux and Homebrew are missing, the person runs the two lines it prints in the second Terminal window. Homebrew is the standard installer for command-line tools on a Mac, and tmux is the tool that keeps a terminal session running after you disconnect. The Homebrew installer asks for the Mini's password and takes 5 to 15 minutes. Continue with step 5 in the meantime, then run `prepare-mini.sh` again to install tmux.

## Step 5: sign Claude in on the Mini (person, from the laptop)

Sign in over SSH, even if Claude Code was already signed in at the Mini's own screen. A sign-in made at the Mini's screen is stored in the macOS Keychain, which sessions arriving over SSH cannot open. A sign-in made over SSH is stored in a file that they can read.

In the second Terminal window:

```bash
ssh mini
cd ~/ClaudeCodeProjects
claude
```

1. Claude Code shows a sign-in link. Press `c` to copy it, paste it into the laptop's browser, approve, and paste the code it shows back into the terminal.
2. When it asks whether you trust the folder `ClaudeCodeProjects`, press the Down arrow to reach "Yes, I trust this folder" and press Return. The cursor starts on "No, exit".
3. Type `/exit`, then `exit` to come back to the laptop.

Verify from the laptop:

```bash
ssh -T mini 'claude auth status --text'
```

## Step 6: teach Claude about the Mini (laptop)

```bash
bash scripts/install-notes.sh
```

This installs three things:

- **The `mini` skill** on the laptop (`~/.claude/skills/mini/SKILL.md`): the step-by-step method for starting, checking, and stopping tasks on the Mini. Claude opens it when a request mentions the Mini.
- **A section in the laptop's `~/.claude/CLAUDE.md`**: four lines, loaded in every session, saying the Mini exists and to use the skill.
- **A section in the Mini's `~/.claude/CLAUDE.md`**: how to behave when nobody is watching, and to leave a `REPORT.md`.

Run `bash scripts/check.sh`. It should print "All set".

## Step 7: first task

The person opens a new Terminal window, goes to any folder, starts `claude`, and types:

```text
Have my Mini build a one-page website that explains Tailscale, SSH and tmux to a beginner. Tell me how to watch it work.
```

Expected: Claude on the laptop writes a brief, starts a session on the Mini, and reports the session name. Then:

1. Watch it: `ssh mini dev task_name` in another window. Leave with Ctrl+b, then d.
2. Close the laptop lid for a minute, open it, and ask: "Check on my Mini."
3. When it reports finished, ask: "Bring the result back and open it."

Setup is complete when the page opens on the laptop.

## Troubleshooting

- **`ssh mini` hangs or says "Operation timed out"**: Tailscale is off on one side. Check the menu bar icon on the laptop, then check the Mini is powered on and signed in to Tailscale.
- **`ssh mini` says "Connection refused"**: Remote Login is off on the Mini (step 2).
- **`ssh mini` asks for a password**: the public key did not reach the Mini. Run the `ssh-copy-id` line from step 3 again.
- **`ssh-copy-id` says "Permission denied"**: wrong username or password. The username is what `whoami` prints on the Mini; the password is the one that unlocks the Mini.
- **`command not found: claude` (or `tmux`) over SSH**: run `bash scripts/prepare-mini.sh` again; it adds the PATH lines to `~/.zshenv` on the Mini.
- **Check says Claude is not signed in on the Mini, though it works at the Mini's screen**: the sign-in is in the Keychain. Do step 5 from the laptop.
- **The Mini's task sits at a "trust this folder" question**: say "check on my Mini"; the skill answers it. Or attach with `ssh mini dev task_name`, press the Down arrow to reach "Yes, I trust this folder", and press Return.
- **The Mini vanished from Tailscale after a restart or power cut**: someone must log in at the Mini once; Tailscale starts when the user logs in. Screen Sharing does not work until then.
- **A warning "Pseudo-terminal will not be allocated"**: harmless. Use `ssh -T mini '...'` for one-off commands to silence it.

## Undo

Each piece can be removed on its own:

- Laptop: delete the `Host mini` block from `~/.ssh/config`, the files `~/.ssh/id_mini` and `~/.ssh/id_mini.pub`, the folder `~/.claude/skills/mini`, and the marked section in `~/.claude/CLAUDE.md`.
- Mini: delete the line containing `laptop-to-mini` from `~/.ssh/authorized_keys`, the files `~/.local/bin/dev` and `~/.local/bin/start-task`, and the marked section in `~/.claude/CLAUDE.md`. Your task folders stay in `~/ClaudeCodeProjects` until you delete them. Turn off Remote Login in System Settings.
