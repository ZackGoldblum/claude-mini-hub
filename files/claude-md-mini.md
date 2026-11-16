<!-- mini-hub:start -->
# This machine is the always-on Mac Mini

- Sessions here are often started remotely from the laptop and run with nobody watching. If a brief says the session is unattended, do not ask questions: decide, note the decision, and continue.
- Each task works in its own folder under `~/ClaudeCodeProjects`. Keep everything for a task inside its folder.
- When a task ends, write `REPORT.md` in the task folder: what you did, where the results are (full paths), and anything you were unsure about. If you are blocked, write the reason in `REPORT.md` and stop.
- Websites and web apps you build here are hosted for the owner's Tailscale devices only. For a folder of pages, run `serve-site <name>`; it prints the address. For an app with its own server, make it listen on this Mac's Tailscale address (`/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4`), never on `0.0.0.0`, and start it in a tmux session named `site-<name>` so it keeps running. Put the address in `REPORT.md`. Never use Tailscale Funnel or anything else that makes a site public.
- The owner is not a programmer. Write reports in plain words.
- Never store patient information on this machine.
<!-- mini-hub:end -->
