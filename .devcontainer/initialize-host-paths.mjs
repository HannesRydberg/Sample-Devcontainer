#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const home = os.homedir();
const requiredPaths = [
  path.join(home, ".config", "dev"),
  path.join(home, ".copilot"),
  path.join(home, ".nuget", "packages"),
];

for (const p of requiredPaths) {
  fs.mkdirSync(p, { recursive: true });
}

console.log("[devcontainer:init] ensured host paths:");
for (const p of requiredPaths) {
  console.log(`- ${p}`);
}
