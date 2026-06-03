# Sample Devcontainer

A small starter repository for running GitHub Copilot CLI inside a reusable devcontainer with a few convenience aliases.

## What this repo gives you

- A ready-to-build devcontainer setup for Copilot CLI
- A straightforward host-side secrets flow using `~/.config/dev/dev.env`
- A small set of aliases to make starting and entering the container faster

## Quick start

1. Create a GitHub fine-grained personal access token with the `Copilot Requests` permission.
2. Create the required host directories and copy the example secrets file:

   ```bash
   mkdir -p ~/.copilot/skills ~/.agents/skills ~/.config/copilot-dev-skills ~/.config/dev
   cp .env.example ~/.config/dev/dev.env
   ```

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
- A GitHub fine-grained PAT with `Copilot Requests`

## Setup notes

The tracked `.env.example` file is only a template. Your real secrets file should live outside the repository at `~/.config/dev/dev.env`.

Before the container starts, the bind-mounted host paths must exist: `~/.copilot/skills`, `~/.agents/skills`, `~/.config/copilot-dev-skills`, and `~/.config/dev/dev.env`.

If `~/.config/dev/dev.env` exists but does not contain a token yet, the container still starts, and you can authenticate Copilot CLI manually inside it.

Host skills and dev skill staging paths are treated as read-only inputs. The container loads active skill copies into container-local directories during setup. If you change host skills or related config and want those changes reflected inside the container, rebuild the devcontainer.

## Daily workflow

For the common flow, run `dev-up` once to build and start the container, then `dev-bash` to open a shell inside it, and finally `copilot` to start the CLI.

## Command reference

See [`aliases.md`](./aliases.md) for the available convenience aliases.
