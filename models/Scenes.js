.pragma library

var sceneRows = [
  {
    id: "forge",
    name: "Forge",
    eyebrow: "BUILD",
    tagline: "Make the hard thing feel possible.",
    description: "A high-voltage workroom for shipping, debugging, and the next decisive move.",
    accent: "#F3A45D",
    accentSoft: "#6B3F2D",
    atmosphere: "ember",
    defaultWallpapers: ["forge-emberline.webp", "forge-nightshift.webp"],
    shortcut: "1"
  },
  {
    id: "hush",
    name: "Hush",
    eyebrow: "DEEP WORK",
    tagline: "Lower the noise. Keep the signal.",
    description: "Soft focus, low contrast, and a calm visual field for long-form concentration.",
    accent: "#91D7C8",
    accentSoft: "#285B5D",
    atmosphere: "mist",
    defaultWallpapers: ["hush-mistgarden.webp", "hush-slowwater.webp"],
    shortcut: "2"
  },
  {
    id: "library",
    name: "Library",
    eyebrow: "RESEARCH",
    tagline: "Let the threads find each other.",
    description: "A collected desk for notes, references, reading trails, and ideas with a pulse.",
    accent: "#E8C773",
    accentSoft: "#6C542A",
    atmosphere: "paper",
    defaultWallpapers: ["library-quietstacks.webp", "library-goldleaf.webp"],
    shortcut: "3"
  },
  {
    id: "afterglow",
    name: "Afterglow",
    eyebrow: "REFLECT",
    tagline: "Close the loop gently.",
    description: "A warm landing place for review, journaling, loose ends, and the last five percent.",
    accent: "#F28E9A",
    accentSoft: "#6D344D",
    atmosphere: "rose",
    defaultWallpapers: ["afterglow-rosehour.webp", "afterglow-latewindow.webp"],
    shortcut: "4"
  },
  {
    id: "orbit",
    name: "Orbit",
    eyebrow: "OVERVIEW",
    tagline: "See the whole system at once.",
    description: "A cool command deck for coordinating projects, agents, and the shape of the day.",
    accent: "#9FBCFF",
    accentSoft: "#354E86",
    atmosphere: "cosmos",
    defaultWallpapers: ["orbit-bluehour.webp", "orbit-constellation.webp"],
    shortcut: "5"
  }
]

function copy(value) {
  return JSON.parse(JSON.stringify(value))
}

function all() {
  return sceneRows.map(copy)
}

function get(id) {
  var key = String(id || "")
  for (var i = 0; i < sceneRows.length; i++) {
    if (sceneRows[i].id === key) return copy(sceneRows[i])
  }
  return copy(sceneRows[0])
}

function contains(id) {
  for (var i = 0; i < sceneRows.length; i++)
    if (sceneRows[i].id === String(id || "")) return true
  return false
}

function next(id, direction) {
  var index = 0
  for (var i = 0; i < sceneRows.length; i++) {
    if (sceneRows[i].id === String(id || "")) {
      index = i
      break
    }
  }
  var step = Number(direction || 1)
  var nextIndex = (index + step) % sceneRows.length
  if (nextIndex < 0) nextIndex += sceneRows.length
  return sceneRows[nextIndex].id
}
