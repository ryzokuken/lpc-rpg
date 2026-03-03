#!/usr/bin/env node
/**
 * Static file server with COOP/COEP headers for Godot web exports.
 *
 * Godot's web export uses SharedArrayBuffer for threading, which browsers
 * only allow when these headers are present on every response:
 *   Cross-Origin-Opener-Policy: same-origin
 *   Cross-Origin-Embedder-Policy: require-corp
 *
 * Usage: node .agent/scripts/serve.mjs [port] [directory]
 * Defaults: port=8080, directory=exports/web
 */

import { createServer } from "node:http";
import { createReadStream, existsSync, statSync } from "node:fs";
import { join, extname, resolve } from "node:path";

const MIME = {
  ".html": "text/html",
  ".js":   "application/javascript",
  ".mjs":  "application/javascript",
  ".wasm": "application/wasm",
  ".pck":  "application/octet-stream",
  ".png":  "image/png",
  ".ico":  "image/x-icon",
  ".css":  "text/css",
  ".json": "application/json",
};

const port = parseInt(process.argv[2] ?? "8080", 10);
const dir  = resolve(process.argv[3] ?? "exports/web");

if (!existsSync(dir)) {
  console.error(`error: directory not found: ${dir}`);
  console.error("run the build first: bash .agent/scripts/build-web.sh");
  process.exit(1);
}

createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${port}`);
  let filePath = join(dir, url.pathname === "/" ? "index.html" : url.pathname);

  if (!existsSync(filePath) || statSync(filePath).isDirectory()) {
    filePath = join(dir, "index.html");
  }

  if (!existsSync(filePath)) {
    res.writeHead(404);
    res.end("Not found");
    return;
  }

  const mime = MIME[extname(filePath)] ?? "application/octet-stream";

  res.writeHead(200, {
    "Content-Type": mime,
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
  });

  createReadStream(filePath).pipe(res);
}).listen(port, "0.0.0.0", () => {
  console.log(`serving Godot web export at http://localhost:${port}`);
});
