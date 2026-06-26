---
name: prefer-container-tools
description: Use when searching files, finding files, viewing content, or parsing JSON — enforces use of container-installed fast CLI tools (ripgrep, fd, bat, jq, tree, ast-grep) over slower shell built-ins
---

# Prefer Container Tools

## Overview

This devcontainer ships fast CLI utilities that are significantly better than
generic shell tools. **Always prefer them.**

Ignoring this skill wastes time and produces worse results.

## Tool Reference

### `rg` — ripgrep (replaces `grep`)

Faster, `.gitignore`-aware content search.

```bash
rg "pattern"                        # search all tracked files
rg "pattern" --type ts              # TypeScript files only
rg -l "pattern"                     # list matching files only
rg -n "pattern" src/                # show line numbers
rg -A 3 -B 3 "pattern"             # context lines
```

**Never use `grep -r` when `rg` is available.**

### `fd` — fd-find (replaces `find`)

Faster, `.gitignore`-aware file finder.

```bash
fd "pattern"                        # find files matching name pattern
fd -e ts src/                       # *.ts files under src/
fd -t f -e json                     # files only, .json extension
fd -t d                             # directories only
```

**Never use `find . -name` when `fd` is available.**

### `bat` — bat (replaces `cat` / `head` / `tail`)

Syntax-highlighted file viewer. Use when showing content to a human.

```bash
bat src/main.ts
bat --style=plain src/main.ts       # plain output, safe to pipe
```

### `jq` — jq (replaces `python -c`, `awk`, `sed` for JSON)

Structured JSON processor.

```bash
cat package.json | jq '.dependencies'
curl -s https://api.example.com | jq '.items[].name'
jq -r '.scripts | keys[]' package.json
```

**Never use `grep` or `awk` to extract JSON values when `jq` is available.**

### `tree` — tree (replaces `ls -R`)

Hierarchical directory listing.

```bash
tree -I node_modules                # exclude node_modules
tree -L 2                           # limit depth to 2
tree -I "node_modules|dist|.git"    # exclude multiple
```

### `ast-grep` (`sg`) — structural code search (replaces regex search for code patterns)

AST-aware search and rewrite. More accurate than regex for code.

```bash
sg --pattern 'console.log($A)' --lang ts
sg --pattern 'useState($A)' --lang tsx
sg --rewrite 'logger.info($A)' --pattern 'console.log($A)' --lang ts
```

Use for: finding call sites, enforcing patterns, safe rename/refactor across many files.

## Quick Decision Guide

| You want to…                        | Use         |
|--------------------------------------|-------------|
| Search file contents for a pattern   | `rg`        |
| Find files by name or extension      | `fd`        |
| Read / display a file                | `bat`       |
| Extract a value from JSON            | `jq`        |
| Understand project layout            | `tree`      |
| Find/refactor a code pattern by AST  | `ast-grep`  |
