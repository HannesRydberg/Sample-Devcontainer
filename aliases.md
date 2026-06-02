# Alias Reference

These aliases are optional, but they make the devcontainer workflow much quicker to use from the repository root.

| Alias | Command | What it does |
| --- | --- | --- |
| `dev-up` | `devcontainer up --workspace-folder .` | Builds and starts the devcontainer for the current repository. |
| `dev-up-rm` | `devcontainer up --workspace-folder . --remove-existing-container` | Rebuilds the container from scratch by removing any existing container first. |
| `dev-bash` | `devcontainer exec --workspace-folder . bash` | Opens a Bash shell inside the running devcontainer. |

## Loading the aliases

Copy these aliases into your shell profile, or save them in a small shell file and source that file before working with this repo.

```bash
alias dev-up='devcontainer up --workspace-folder .'
alias dev-up-rm='devcontainer up --workspace-folder . --remove-existing-container'
alias dev-bash='devcontainer exec --workspace-folder . bash'
```
