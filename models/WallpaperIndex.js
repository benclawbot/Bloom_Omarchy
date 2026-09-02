.pragma library

var extensions = ["png", "jpg", "jpeg", "webp", "avif"]

function isSupported(path) {
  var value = String(path || "").toLowerCase()
  for (var i = 0; i < extensions.length; i++)
    if (value.slice(-(extensions[i].length + 1)) === "." + extensions[i]) return true
  return false
}

function basename(path) {
  var parts = String(path || "").split("/")
  return parts.length ? parts[parts.length - 1] : ""
}

function titleFor(path) {
  var name = basename(path).replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ")
  return name.replace(/\b\w/g, function(letter) { return letter.toUpperCase() })
}

function sceneFor(path) {
  var value = String(path || "").toLowerCase()
  var ids = ["forge", "hush", "library", "afterglow", "orbit"]
  for (var i = 0; i < ids.length; i++)
    if (value.indexOf("/" + ids[i] + "/") >= 0 || value.indexOf(ids[i] + "-") >= 0) return ids[i]
  return ""
}

function fromLines(raw) {
  var rows = []
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var path = lines[i].trim()
    if (!path || !isSupported(path)) continue
    rows.push({
      path: path,
      url: path,
      title: titleFor(path),
      sceneId: sceneFor(path),
      source: "user"
    })
  }
  return rows
}

function forScene(items, sceneId) {
  var exact = []
  var neutral = []
  var other = []
  for (var i = 0; i < (items || []).length; i++) {
    if (items[i].sceneId === sceneId) exact.push(items[i])
    else if (!items[i].sceneId) neutral.push(items[i])
    else other.push(items[i])
  }
  return exact.concat(neutral, other)
}
