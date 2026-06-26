#!/usr/bin/env node
import { execSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const home = os.homedir();

// Base directories that must always exist on the host
const basePaths = [
  path.join(home, ".config", "dev"),
  path.join(home, ".copilot"),
  path.join(home, ".nuget", "packages"),
];

for (const p of basePaths) {
  fs.mkdirSync(p, { recursive: true });
}

console.log("[devcontainer:init] ensured host paths:");
for (const p of basePaths) {
  console.log(`  - ${p}`);
}

// Detect WSL by checking /proc/version for the Microsoft kernel signature
function isWSL() {
  try {
    return fs
      .readFileSync("/proc/version", "utf8")
      .toLowerCase()
      .includes("microsoft");
  } catch {
    return false;
  }
}

// Resolve the Windows user profile directory as a WSL path (requires wslu)
function windowsUserProfile() {
  return execSync('wslpath "$(wslvar USERPROFILE)"', {
    shell: "/bin/bash",
    encoding: "utf8",
  }).trim();
}

// Subdirectories of ~/.copilot that are bind-mounted into the container
const copilotSubdirs = ["skills", "agents"];

if (isWSL()) {
  // On Windows/WSL the devcontainer CLI runs inside the WSL distro, so
  // ${localEnv:HOME} resolves to the WSL home (~).  The user's Copilot
  // skills and agents, however, live in the Windows user profile
  // (%USERPROFILE%\.copilot\).  We create symlinks inside the WSL home
  // that point to the Windows-side paths so the existing bind mounts in
  // devcontainer.json work without any changes.
  console.log(
    "\n[devcontainer:init] WSL detected — linking Copilot skills/agents from Windows profile"
  );

  let winProfile;
  try {
    winProfile = windowsUserProfile();
  } catch {
    console.error(
      "[devcontainer:init] ERROR: could not resolve Windows user profile.\n" +
        "  Install wslu (`sudo apt install wslu`) and re-run `dev-up`."
    );
    process.exit(1);
  }

  for (const subdir of copilotSubdirs) {
    const winPath = path.join(winProfile, ".copilot", subdir);
    const wslPath = path.join(home, ".copilot", subdir);

    // Ensure the Windows-side source directory exists
    fs.mkdirSync(winPath, { recursive: true });

    const stat = fs.lstatSync(wslPath, { throwIfNoEntry: false });
    if (stat?.isSymbolicLink()) {
      console.log(`  - already linked: ${wslPath}`);
    } else {
      // Remove a plain directory created by the base-path loop (if present)
      if (stat?.isDirectory()) {
        fs.rmSync(wslPath, { recursive: true });
      }
      fs.symlinkSync(winPath, wslPath);
      console.log(`  - linked: ${wslPath} -> ${winPath}`);
    }
  }
} else {
  // Mac / Linux: just ensure the subdirectories exist
  for (const subdir of copilotSubdirs) {
    const p = path.join(home, ".copilot", subdir);
    fs.mkdirSync(p, { recursive: true });
    console.log(`  - ensured: ${p}`);
  }
}
