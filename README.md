# Sample Devcontainer

A small starter repository for running GitHub Copilot CLI inside a reusable devcontainer with a few convenience aliases.

## What this repo gives you

- A ready-to-build devcontainer setup for Copilot CLI
- A straightforward host-side secrets flow using `~/.config/dev/dev.env`
- Automatic host-path bootstrap for `~/.config/dev`, `~/.copilot`, and `~/.nuget/packages`
- A small set of aliases to make starting and entering the container faster

## Quick start

1. Create a GitHub fine-grained personal access token with the `Copilot Requests` permission.
2. Create the host config directory and copy the example secrets file:

   ```bash
   mkdir -p ~/.config/dev
   cp .env.example ~/.config/dev/dev.env
   ```

   The host bootstrap auto-creates the directories needed for secrets, Copilot data, and the shared NuGet cache before the container starts.

3. Edit `~/.config/dev/dev.env` and add your token. If you use GitHub Enterprise, add the host URL too.
4. Install the [Dev Containers CLI](https://github.com/devcontainers/cli).
5. Load the aliases from [`aliases.md`](./aliases.md).
6. Start the container:

   ```bash
   dev-up
   ```

7. Enter the container:

   ```bash
   dev-bash
   ```

8. Start Copilot CLI:

   ```bash
   copilot
   ```

## Prerequisites

- Docker / Docker Desktop (Mac/Linux) — or Docker CE inside WSL 2 (Windows, see below)
- Dev Containers CLI
- Host Node.js runtime available (used by the devcontainer host bootstrap step)
- A GitHub fine-grained PAT with `Copilot Requests`

## Windows (WSL) setup

On Windows the devcontainer runs inside WSL 2. Complete the steps below **once** before following the Quick start guide, then run all commands from your WSL terminal.

A convenience script is provided that runs steps 2–4 for you:

```bash
tr -d '\r' < scripts/windows-wsl-setup.sh | bash
```

Or follow the steps manually:

### 1. Install WSL

Run the following in PowerShell (as administrator) and restart when prompted:

```powershell
wsl --install
```

### 2. Install Docker CE inside WSL

```bash
# Add Docker's official GPG key
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker apt repository
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 3. Install Node.js

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash

# Load nvm without restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Install Node.js 24
nvm install 24

# Enable pnpm
corepack enable pnpm
```

### 4. Install WSL utilities

`wslu` provides `wslvar` and `wslpath`, which the init script uses to locate your Windows user profile and link your Copilot skills and agents into the WSL home directory.

```bash
sudo apt install wslu
```

After completing these steps, continue with the **Quick start** guide above.

### How skills and agents work on Windows

On Mac/Linux, `~/.copilot/skills` and `~/.copilot/agents` on the host are bind-mounted directly into the container.

On Windows, those directories live in your Windows user profile (`%USERPROFILE%\.copilot\`). The `initialize-host-paths.mjs` script automatically detects WSL and creates symlinks in your WSL home that point to the Windows-side paths, so the same bind mounts work transparently without any changes to `devcontainer.json`:

```
~/.copilot/skills  →  /mnt/c/Users/<you>/.copilot/skills
~/.copilot/agents  →  /mnt/c/Users/<you>/.copilot/agents
```

This requires `wslu` to be installed (step 4 above). If the script cannot find `wslvar` it will print an error and exit — install `wslu` and re-run `dev-up`.

## Setup notes

The tracked `.env.example` file is only a template. Your real secrets file should live outside the repository at `~/.config/dev/dev.env`.

Before the container starts, bind-mounted host paths must exist. The host bootstrap creates the needed directories automatically.

If `~/.config/dev/dev.env` exists but does not contain a token yet, the container still starts, and you can authenticate Copilot CLI manually inside it.

Opening this devcontainer executes `.devcontainer/initialize-host-paths.mjs` on the host via `initializeCommand`.
Because this executes repository code on your host with your user permissions, only use this devcontainer setup with trusted code/branches.

If host bootstrap cannot run, create these paths manually and retry:
- `~/.config/dev`
- `~/.copilot`
- `~/.nuget/packages`

## Daily workflow

For the common flow, run `dev-up` once to build and start the container, then `dev-bash` to open a shell inside it, and finally `copilot` to start the CLI.

## Command reference

See [`aliases.md`](./aliases.md) for the available convenience aliases.
