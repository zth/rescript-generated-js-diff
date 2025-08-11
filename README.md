## rescript-generated-js-diff

Small CLI to zip the generated JS files of a ReScript project. Useful for sharing or inspecting diffs of compiler output.

### How it works

- **Config discovery**: reads `rescript.json` or `bsconfig.json` to find `sources`.
- **File selection**: collects files with the configured `suffix` (default: `.bs.js`; respects `suffix` if set, e.g. `.res.mjs`).
- **Output**: creates a zip archive in the target project directory.

### Install

```sh
npm install
```

### Run

```sh
node src/RescriptGeneratedJsDiff.res.mjs <base-dir> [out-file]
```

Examples:

```sh
# Zip generated JS in the current project (writes ./diff.zip)
node src/RescriptGeneratedJsDiff.res.mjs .

# Custom output path
node src/RescriptGeneratedJsDiff.res.mjs . ./out/generated.zip
```

### Notes

- Exits with code 1 if no files with the target suffix are found.
- To rebuild `.res.mjs` from source, use: `npm run res:build` (and `npm run res:dev` to watch).
