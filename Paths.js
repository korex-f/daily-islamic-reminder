// XDG path resolution is kept pure so it can be checked without Quickshell.
function dataHome(envValue, home) {
  return envValue && String(envValue).length > 0 ? String(envValue) : String(home || "") + "/.local/state"
}

function cacheHome(envValue, home) {
  return envValue && String(envValue).length > 0 ? String(envValue) : String(home || "") + "/.cache"
}

function pluginPaths(cacheEnv, stateEnv, home) {
  var id = "dki.quran-verse-of-the-day"
  var cache = cacheHome(cacheEnv, home) + "/" + id
  var state = dataHome(stateEnv, home) + "/" + id
  return {
    cacheDir: cache + "/",
    stateDir: state + "/",
    statePath: state + "/state.json",
    itemsPath: cache + "/items.json",
    editionsPath: cache + "/editions.json",
    migrationMarker: state + "/.legacy-cache-migrated"
  }
}

function migrationCommand(paths, legacyDir) {
  var script = "set -e; mkdir -p \"$1\" \"$2\"; if [ ! -e \"$3\" ]; then " +
    "for pair in \"$4/state.json:$2/state.json\" \"$4/items.json:$1/items.json\" \"$4/editions.json:$1/editions.json\"; do " +
    "src=${pair%%:*}; dst=${pair#*:}; if [ -f \"$src\" ] && [ ! -e \"$dst\" ]; then cp \"$src\" \"$dst\"; fi; done; " +
    "touch \"$3\"; fi"
  return ["sh", "-c", script, "--", paths.cacheDir, paths.stateDir, paths.migrationMarker, legacyDir]
}

// Exports for Qt's .pragma library and Node's CommonJS test runner.
if (typeof module !== "undefined") {
  module.exports = { dataHome: dataHome, cacheHome: cacheHome, pluginPaths: pluginPaths, migrationCommand: migrationCommand }
}
