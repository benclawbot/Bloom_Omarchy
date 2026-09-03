#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const root = path.resolve(__dirname, "../..");

function load(relative) {
  const context = {};
  const source = fs.readFileSync(path.join(root, relative), "utf8").replace(/^\.pragma library\s*/m, "");
  vm.runInNewContext(source, context, {
    filename: relative
  });
  return context;
}

const scenes = load("models/Scenes.js");
const agents = load("models/AgentStore.js");
const wallpapers = load("models/WallpaperIndex.js");

if (scenes.all().length !== 5) throw new Error("expected five Bloom scenes");
if (!scenes.contains("orbit") || scenes.contains("unknown")) throw new Error("scene lookup failed");

const normalized = agents.normalize({
  id: "a1",
  provider: "claude",
  project: "atlas",
  status: "attention",
  attention: true,
  progress: 1.4
});
if (normalized.providerLabel !== "Claude" || normalized.progress !== 1 || !normalized.attention)
  throw new Error("agent normalization failed");

const rows = wallpapers.forScene([
  { path: "/tmp/forge-a.webp", sceneId: "forge" },
  { path: "/tmp/neutral.webp", sceneId: "" },
  { path: "/tmp/orbit-a.webp", sceneId: "orbit" }
], "forge");
if (rows.map(row => row.path).join(",") !== "/tmp/forge-a.webp,/tmp/neutral.webp")
  throw new Error("wallpaper scene filtering failed");

console.log("Bloom model checks passed");
