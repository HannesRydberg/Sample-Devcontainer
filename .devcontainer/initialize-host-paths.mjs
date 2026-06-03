#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const home = os.homedir();
const requiredPaths = [
  path.join(home, ".config", "dev"),
  path.join(home, ".copilot", "skills"),
  path.join(home, ".agents", "skills"),
  path.join(home, ".config", "copilot-dev-skills"),
];

for (const p of requiredPaths) {
  fs.mkdirSync(p, { recursive: true });
}

console.log("[devcontainer:init] ensured host paths:");
for (const p of requiredPaths) {
  console.log(`- ${p}`);
}
