#!/usr/bin/env node

import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const defaultOutput = join(
  repositoryRoot,
  "src",
  "primitives",
  "canvas",
  "testdata",
  "ui_library_inventory_receipt.json",
);

const references = [
  {
    source: "zed_ui",
    repository: "https://github.com/zed-industries/zed",
    revision: "7960b2a7c9568e90fbe0727332149e5b2a5fd57a",
    authoritativePath: "crates/ui/src/components.rs",
    expectedCount: 42,
    rootOptions: ["zed-root"],
    rootEnvironments: ["ZED_UI_REFERENCE_ROOT"],
    extract(source) {
      const declared = [...source.matchAll(/^mod\s+([a-z_][a-z0-9_]*)\s*;/gm)].map(
        (match) => match[1],
      );
      const reexported = new Set(
        [...source.matchAll(/^pub use\s+([a-z_][a-z0-9_]*)::\*\s*;/gm)].map(
          (match) => match[1],
        ),
      );
      const modules = declared.filter((module) => reexported.has(module));
      if (modules.length !== declared.length || modules.length !== reexported.size) {
        throw new Error(
          "Zed components.rs module declarations and public re-exports do not match",
        );
      }
      return modules;
    },
  },
  {
    source: "gpui_component",
    repository: "https://github.com/longbridge/gpui-kit",
    revision: "c33bfebf03f5f7a1751d0395b40c786b869a9f50",
    authoritativePath: "crates/component/src/lib.rs",
    expectedCount: 65,
    rootOptions: ["gpui-kit-root", "gpui-component-root"],
    rootEnvironments: ["GPUI_KIT_REFERENCE_ROOT", "GPUI_COMPONENT_REFERENCE_ROOT"],
    extract(source) {
      return [...source.matchAll(/^pub mod\s+([a-z_][a-z0-9_]*)\s*(?:;|\{)/gm)].map(
        (match) => match[1],
      );
    },
  },
];

function parseArguments(argv) {
  const options = { check: false, output: defaultOutput };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--check") {
      options.check = true;
      continue;
    }
    if (!argument.startsWith("--")) throw new Error(`unexpected argument: ${argument}`);
    const name = argument.slice(2);
    const value = argv[index + 1];
    if (!value || value.startsWith("--")) throw new Error(`missing value for ${argument}`);
    options[name] = value;
    index += 1;
  }
  return options;
}

function gitRevision(checkout) {
  return execFileSync("git", ["-C", checkout, "rev-parse", "HEAD"], {
    encoding: "utf8",
  }).trim();
}

function gitBlob(checkout, revision, path) {
  return execFileSync("git", ["-C", checkout, "show", `${revision}:${path}`]);
}

function sha256(source) {
  return createHash("sha256").update(source).digest("hex");
}

function assertUnique(reference, modules) {
  const unique = new Set(modules);
  if (unique.size !== modules.length) {
    throw new Error(`${reference.source}: duplicate modules in authoritative source`);
  }
  if (modules.length !== reference.expectedCount) {
    throw new Error(
      `${reference.source}: expected ${reference.expectedCount} modules, found ${modules.length}`,
    );
  }
}

function buildSourceReceipt(reference, options) {
  const configuredRoot =
    reference.rootOptions.map((name) => options[name]).find(Boolean) ||
    reference.rootEnvironments.map((name) => process.env[name]).find(Boolean);
  if (!configuredRoot) {
    throw new Error(
      `missing --${reference.rootOptions[0]} (or ${reference.rootEnvironments[0]}) for ${reference.source}`,
    );
  }

  const checkout = resolve(configuredRoot);
  const revision = gitRevision(checkout);
  if (revision !== reference.revision) {
    throw new Error(
      `${reference.source}: expected revision ${reference.revision}, found ${revision}`,
    );
  }

  const source = gitBlob(checkout, reference.revision, reference.authoritativePath);
  const modules = reference.extract(source.toString("utf8"));
  assertUnique(reference, modules);

  return {
    source: reference.source,
    repository: reference.repository,
    revision,
    authoritative_path: reference.authoritativePath,
    source_sha256: sha256(source),
    modules,
  };
}

const options = parseArguments(process.argv.slice(2));
const receipt = {
  schema_version: 1,
  generated_by: "scripts/update-ui-library-inventory.mjs",
  sources: references.map((reference) => buildSourceReceipt(reference, options)),
};
const rendered = `${JSON.stringify(receipt, null, 2)}\n`;
const output = resolve(options.output);

if (options.check) {
  if (!existsSync(output) || readFileSync(output, "utf8") !== rendered) {
    throw new Error(`${output} is stale; regenerate it with this script`);
  }
  process.stdout.write(`verified ${output}\n`);
} else {
  writeFileSync(output, rendered);
  process.stdout.write(`wrote ${output}\n`);
}
