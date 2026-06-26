<!-- devcontainer:prefer-container-tools -->
# Agent Instructions

## Tool Preferences

This devcontainer ships specialized CLI tools optimized for AI agent workflows.
Prefer them over generic shell equivalents whenever applicable.

### Search file contents → `rg` (ripgrep)

Use `rg` instead of `grep`. It is faster, respects `.gitignore` automatically,
and supports richer output modes.

```bash
rg "pattern"                   # search all tracked files
rg "pattern" --type ts         # restrict to TypeScript files
rg -l "pattern"                # list matching files only
rg -n "pattern" src/           # show line numbers in a subtree
```

### Find files → `fd`

Use `fd` instead of `find`. It respects `.gitignore` and has a simpler syntax.

```bash
fd "pattern"                   # find files matching pattern
fd -e ts src/                  # find *.ts files under src/
fd -t f -e json                # files only, .json extension
```

### View file contents → `bat`

Use `bat` instead of `cat` / `head` / `tail` when producing human-readable
output. `bat` adds syntax highlighting, line numbers, and paging.

```bash
bat src/main.ts
bat --style=plain src/main.ts  # no decorations (good for piping)
```

### Parse / filter JSON → `jq`

Use `jq` for any JSON manipulation instead of `python -c`, `awk`, or `sed`.

```bash
cat package.json | jq '.dependencies'
curl -s https://api.example.com/data | jq '.items[].name'
```

### Directory structure → `tree`

Use `tree` instead of `ls -R` for exploring project layout.

```bash
tree -I node_modules            # exclude node_modules
tree -L 2                       # limit depth
```

### Structural code search / refactor → `ast-grep` (`sg`)

Use `ast-grep` for pattern-based code search and rewrites that operate on the
AST rather than raw text. Ideal for finding usages, renaming, or enforcing
patterns across many files.

```bash
sg --pattern 'console.log($A)' --lang ts          # find all console.log calls
sg --pattern 'useState($A)' --lang tsx             # React hook usages
sg --rewrite 'logger.info($A)' --pattern 'console.log($A)' --lang ts  # rewrite
```

## Summary table

| Task                     | Use         | Avoid              |
|--------------------------|-------------|--------------------|
| Search file contents     | `rg`        | `grep`             |
| Find files by name       | `fd`        | `find`             |
| View file contents       | `bat`       | `cat` / `head`     |
| Parse / filter JSON      | `jq`        | `python -c`, `awk` |
| List directory tree      | `tree`      | `ls -R`            |
| Structural code search   | `ast-grep`  | regex-only search  |
