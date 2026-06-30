# Sample Devcontainer

A small starter repository for running GitHub Copilot CLI inside a reusable devcontainer with a few convenience aliases.

## What this repo gives you

- A ready-to-build devcontainer setup for Copilot CLI
- A straightforward host-side secrets flow using `~/.config/dev/dev.env`
- Automatic host-path bootstrap for `~/.config/dev`, `~/.copilot`, and `~/.nuget/packages`
- A small set of aliases to make starting and entering the container faster

## Prerequisites

- Docker / Docker Desktop on Mac or Linux
- Docker CE inside WSL 2 on Windows
- Dev Containers CLI (installed by the Windows helper script)
- Host Node.js runtime (used by the host bootstrap step)
- A GitHub fine-grained PAT with `Copilot Requests`

## Windows (WSL) setup

Use this path if you are on Windows. The devcontainer runs inside WSL 2, so complete these steps once, then keep using your WSL terminal for the rest of the setup.


### Windows quick start

1. Install WSL first (PowerShell as administrator), then restart when prompted:

   ```powershell
   wsl --install
   ```

2. In an Ubuntu WSL terminal, run the helper script. It installs Docker, Node.js, Dev Containers CLI, and WSL utilities:

   ```bash
   tr -d '\r' < scripts/windows-wsl-setup.sh | bash
   ```

After the script finishes:

1. Create and edit your secrets file:

   ```bash
   mkdir -p ~/.config/dev
   cp .env.example ~/.config/dev/dev.env
   ```

   Add your GitHub fine-grained PAT with `Copilot Requests` to `~/.config/dev/dev.env`. If you use GitHub Enterprise, add the host URL too.

2. Load the aliases from [`aliases.md`](./aliases.md).
3. Run the setup preflight:

   ```bash
   scripts/doctor.sh
   ```

   This now also runs the host bootstrap script (`.devcontainer/initialize-host-paths.mjs`) and prints its full error output if it fails.

4. Start and enter the container, then launch Copilot:

   ```bash
   dev-up
   dev-bash
   copilot
   ```

If you prefer to do it manually, follow the steps below instead of running the helper script.

#### 1. Install WSL

Run this in PowerShell as administrator, then restart when prompted:

```powershell
wsl --install
```

#### 2. Install Docker CE inside WSL

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

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

#### 3. Install Node.js

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 24
corepack enable pnpm
```

#### 4. Install WSL utilities

Install `wslu` so the host bootstrap can find your Windows profile and link your Copilot folders:

```bash
sudo apt update
sudo apt install wslu
```

If `wslu` is unavailable (for example on Ubuntu 26.04 right now), install a local `wslvar` shim instead:

```bash
mkdir -p ~/.local/bin
printf '%s\n' '#!/usr/bin/env bash' 'cmd.exe /c "echo %$1%" | tr -d "\r"' > ~/.local/bin/wslvar
chmod +x ~/.local/bin/wslvar
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

When that finishes, run the **Windows quick start** steps above (create `~/.config/dev/dev.env`, load aliases, run `scripts/doctor.sh`, then run `dev-up`, `dev-bash`, and `copilot`).

## Mac/Linux setup

If you are on Mac or Linux, you do not need WSL. Install the shared prerequisites, then create the host directories once before starting the container.

### 1. Install the shared prerequisites

- Docker / Docker Desktop
- Dev Containers CLI
- Node.js 24 or newer

Enable `pnpm` after installing Node.js:

```bash
corepack enable pnpm
```

### 2. Create the host paths

Run the host bootstrap once to create the required directories:

```bash
node .devcontainer/initialize-host-paths.mjs
```

### 3. Create your secrets file

The tracked `.env.example` file is only a template. Your real secrets file should live outside the repository at `~/.config/dev/dev.env`:

```bash
mkdir -p ~/.config/dev
cp .env.example ~/.config/dev/dev.env
```

Edit `~/.config/dev/dev.env` and add your token. If you use GitHub Enterprise, add the host URL too.

After that:

1. Load the aliases from [`aliases.md`](./aliases.md).
2. Run the setup preflight:

   ```bash
   scripts/doctor.sh
   ```

3. Start and enter the container, then launch Copilot:

   ```bash
   dev-up
   dev-bash
   copilot
   ```

## Setup notes

`~/.copilot/skills` and `~/.copilot/agents` are shared between the host and the container.

- On Mac/Linux, they are bind-mounted directly from your home directory.
- On Windows, they live under your Windows profile (`%USERPROFILE%\.copilot\`) and the host bootstrap creates WSL symlinks that point to those locations.

Before the container starts, bind-mounted host paths must exist. The host bootstrap creates the needed directories automatically.

If `~/.config/dev/dev.env` exists but does not contain a token yet, the container still starts, and you can authenticate Copilot CLI manually inside it.

Opening this devcontainer executes `.devcontainer/initialize-host-paths.mjs` on the host via `initializeCommand`. Because this runs repository code on your host with your user permissions, only use this devcontainer setup with trusted code or branches.

If host bootstrap cannot run, create these paths manually and retry:

- `~/.config/dev`
- `~/.copilot`
- `~/.nuget/packages`

## Daily workflow

For the common flow, run `dev-up` once to build and start the container, then `dev-bash` to open a shell inside it, and finally `copilot` to start the CLI.

## Command reference

See [`aliases.md`](./aliases.md) for the available convenience aliases.

## Disclaimer

By accessing, cloning, forking, copying, modifying, executing, or otherwise interacting with this repository in any way—including but not limited to curiously opening it in an editor—you acknowledge and agree that you are doing so entirely at your own risk and discretion. This repository is provided on an “as is,” “as available,” and occasionally “as inexplicably behaving” basis, without warranties of any kind, whether express or implied. You are explicitly free to use this repository however you see fit; however, any outcomes, consequences, or side effects of such use are solely and entirely your responsibility.

The author disclaims all liability for any direct, indirect, incidental, consequential, or existential damages arising from the use of this repository. This includes, but is not limited to, broken builds, corrupted environments, lost code, delayed deadlines, production incidents, or uncomfortable conversations beginning with “so… quick question.” If something fails, misbehaves, or works in a way that inspires unjustified confidence, that remains your responsibility alone.

Nothing in this repository constitutes or should be interpreted as legal, financial, medical, culinary, architectural, career, or life advice, nor as authoritative guidance on software engineering practices. Any resemblance to best practices is purely coincidental, aspirational, or the result of optimistic copy-pasting from more reputable sources. Users are strongly encouraged to apply independent judgment, critical thinking, and basic sanity checks before relying on anything contained herein.

No guarantee is made that the repository functions correctly, consistently, or at all. In the unlikely event that something works perfectly, this should be considered a fortunate accident rather than an implicit promise. Conversely, if it does not work, that outcome should be considered fully compliant with the terms of this disclaimer.
Use of this repository may result in side effects including, but not limited to, confusion, overconfidence, underconfidence, curiosity, frustration, or an increased tendency to say “it works on my machine.” The author assumes no responsibility for any such conditions, temporary or otherwise.

By continuing, you represent that you are a consenting and reasonably capable individual engaging voluntarily with development tooling and agree to assume full responsibility for your actions and their consequences. If you are unsure what you are doing, that is entirely normal—but still not the author’s responsibility. If you are certain what you are doing, that is commendable—and still not the author’s responsibility.

You further acknowledge that no support, maintenance, updates, or explanations are guaranteed, implied, or secretly planned. Any improvements, fixes, or clarifications that do occur should be regarded as acts of goodwill rather than obligation.

This repository may be used, modified, redistributed, or ignored at your discretion, provided that you accept that all resulting outcomes—good, bad, or impressively strange—remain entirely your own.

Finally, no representation or warranty is made that this repository adheres to any standards, conventions, design principles, architectural patterns, or even its own apparent internal logic. Any such alignment, if observed, should be treated as coincidental and not indicative of intent.
