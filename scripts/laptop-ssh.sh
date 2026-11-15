#!/bin/bash
# laptop-ssh.sh: run on the LAPTOP. Creates the SSH key and the "mini" shortcut.
# Safe to run twice: it never overwrites an existing key or shortcut.
# Usage: bash scripts/laptop-ssh.sh mini_username mini_tailscale_ip
#   e.g. bash scripts/laptop-ssh.sh jane 100.101.102.103
set -euo pipefail

USER_ON_MINI="${1:?first argument: your username on the Mini (run whoami there)}"
MINI_IP="${2:?second argument: the Tailscale address of the Mini (starts with 100.)}"
KEY="$HOME/.ssh/id_mini"
CONFIG="$HOME/.ssh/config"

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

if [ -f "$KEY" ]; then
  echo "Key already exists: $KEY (left as is)"
else
  ssh-keygen -q -t ed25519 -N "" -C "laptop-to-mini" -f "$KEY"
  echo "Created key pair: $KEY (private, stays here) and $KEY.pub (public, goes to the Mini)"
fi

if grep -qE '^Host[[:space:]]+mini([[:space:]]|$)' "$CONFIG" 2>/dev/null; then
  echo "Shortcut 'mini' already exists in $CONFIG (left as is)"
else
  cat >> "$CONFIG" <<EOF

# ---------- Mac Mini (over Tailscale) ----------
Host mini
    HostName $MINI_IP
    User $USER_ON_MINI
    IdentityFile ~/.ssh/id_mini
    IdentitiesOnly yes
    RequestTTY yes
EOF
  chmod 600 "$CONFIG"
  echo "Added shortcut 'mini' to $CONFIG"
fi

echo
echo "Next, YOU run this one line in a second Terminal window (Cmd+N)."
echo "It asks for the Mini's login password once, and copies the public key over:"
echo
echo "    ssh-copy-id -i ~/.ssh/id_mini.pub $USER_ON_MINI@$MINI_IP"
echo
