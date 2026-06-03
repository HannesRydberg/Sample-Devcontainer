# Sample Devcontainer

A small starter repository for running GitHub Copilot CLI inside a reusable devcontainer with a few convenience aliases.

## What this repo gives you

- A ready-to-build devcontainer setup for Copilot CLI
- A straightforward host-side secrets flow using `~/.config/dev/dev.env`
- A small set of aliases to make starting and entering the container faster

## Quick start

1. Create a GitHub fine-grained personal access token with the `Copilot Requests` permission.
2. Create the host config directory and copy the example secrets file:

   ```bash
   mkdir -p ~/.config/dev
   cp .env.example ~/.config/dev/dev.env
   ```

   The devcontainer host bootstrap auto-creates the skill-folder paths before startup. If that bootstrap cannot run, create `~/.copilot/skills`, `~/.agents/skills`, and `~/.config/copilot-dev-skills` manually as a fallback.

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

- Docker / Docker Desktop
- Dev Containers CLI
- Host Node.js runtime available (used by the devcontainer host bootstrap step)
- A GitHub fine-grained PAT with `Copilot Requests`

## Setup notes

The tracked `.env.example` file is only a template. Your real secrets file should live outside the repository at `~/.config/dev/dev.env`.

Before the container starts, bind-mounted host paths must exist. The host bootstrap attempts to create missing skill-related paths automatically.

If `~/.config/dev/dev.env` exists but does not contain a token yet, the container still starts, and you can authenticate Copilot CLI manually inside it.

Host skills and dev skill staging paths are treated as read-only inputs. The container loads active skill copies into container-local directories during setup. If you change host skills or related config and want those changes reflected inside the container, rebuild the devcontainer.

Skill folders are optional from a manual setup perspective because the host bootstrap auto-creates them.

Opening this devcontainer executes `.devcontainer/initialize-host-paths.mjs` on the host via `initializeCommand`.
Because this executes repository code on your host with your user permissions, only use this devcontainer setup with trusted code/branches.

If host bootstrap cannot run, create these paths manually and retry:
- `~/.copilot/skills`
- `~/.agents/skills`
- `~/.config/copilot-dev-skills`
- `~/.config/dev`

## Per-repo dev skill loading

This setup supports testing skill changes in a specific repository without polluting your host-level global Copilot skills.

How it works:

1. Host skill sources are mounted read-only into the container under `/mnt/host-inputs/...`.
2. `postCreate.sh` copies active skill sets into container-local skill directories.
3. Repo-selected sets are read from `.copilot-skills` (one set name per line) and resolved under:
   `~/.config/copilot-dev-skills/<set>/<skill>/SKILL.md`

Because copied skills are container-local, host/global skills are not modified by repo-specific testing.

If you change skill folders or `.copilot-skills` and want those copied-in versions refreshed, rebuild the devcontainer.

## Daily workflow

For the common flow, run `dev-up` once to build and start the container, then `dev-bash` to open a shell inside it, and finally `copilot` to start the CLI.

## Command reference

See [`aliases.md`](./aliases.md) for the available convenience aliases.
