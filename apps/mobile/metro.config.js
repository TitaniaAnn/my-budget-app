const { getDefaultConfig } = require("expo/metro-config");
const path = require("path");

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, "../..");

const config = getDefaultConfig(projectRoot);

// 1. Watch all files in the monorepo (so Metro hot-reloads shared packages)
config.watchFolders = [workspaceRoot];

// 2. Let Metro resolve modules from the workspace root first,
//    then fall back to the app's own node_modules
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules"),
];

// 3. Force single instances of these packages to avoid duplicate-module errors
config.resolver.disableHierarchicalLookup = false;

module.exports = config;
