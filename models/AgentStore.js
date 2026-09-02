.pragma library

var providers = {
  codex: { label: "Codex", color: "#E9F4FF", orbit: 0 },
  claude: { label: "Claude", color: "#E78A64", orbit: 1 },
  gemini: { label: "Gemini", color: "#A7B9FF", orbit: 2 },
  opencode: { label: "OpenCode", color: "#9FE0C5", orbit: 3 },
  copilot: { label: "Copilot", color: "#D6B4F7", orbit: 4 },
  pi: { label: "Pi", color: "#F4CD7A", orbit: 5 },
  crush: { label: "Crush", color: "#F49DB3", orbit: 6 }
}

function providerKey(value) {
  var text = String(value || "").toLowerCase()
  if (text.indexOf("claude") >= 0) return "claude"
  if (text.indexOf("gemini") >= 0) return "gemini"
  if (text.indexOf("opencode") >= 0) return "opencode"
  if (text.indexOf("copilot") >= 0) return "copilot"
  if (text.indexOf("crush") >= 0) return "crush"
  if (text === "pi" || text.indexOf("/pi") >= 0) return "pi"
  return "codex"
}

function providerMeta(value) {
  var key = providerKey(value)
  return providers[key] || providers.codex
}

function isAgentCommand(value) {
  var key = String(value || "").toLowerCase().replace(/^.*\//, "")
  return ["codex", "claude", "gemini", "opencode", "copilot", "pi", "crush"].indexOf(key) >= 0
}

function titleCase(value) {
  var text = String(value || "")
  return text.length ? text.charAt(0).toUpperCase() + text.slice(1) : text
}

function normalize(raw) {
  var input = raw || {}
  var provider = providerMeta(input.provider || input.name || input.command)
  var status = String(input.status || "working").toLowerCase()
  if (["working", "waiting", "attention", "paused", "offline"].indexOf(status) < 0)
    status = "working"
  var id = String(input.id || input.pid || (providerKey(input.provider) + "-" + String(input.project || "session")))
  var project = String(input.project || input.projectName || "Local session")
  return {
    id: id,
    provider: providerKey(input.provider || input.name || input.command),
    providerLabel: provider.label,
    providerColor: provider.color,
    project: project,
    branch: String(input.branch || ""),
    status: status,
    summary: String(input.summary || input.message || "Working nearby"),
    detail: String(input.detail || ""),
    pid: Number(input.pid || 0),
    progress: Math.max(0, Math.min(1, Number(input.progress === undefined ? 0.42 : input.progress))),
    updatedAt: Number(input.updatedAt || Date.now()),
    attention: input.attention === true || status === "attention",
    orbit: Number(input.orbit === undefined ? provider.orbit : input.orbit)
  }
}

function fromProcess(pid, command, args) {
  var provider = providerMeta(command)
  return normalize({
    id: String(pid),
    pid: Number(pid),
    provider: command,
    project: "Local session",
    status: "working",
    summary: "Process detected",
    detail: String(args || "").slice(0, 96),
    progress: 0.38,
    updatedAt: Date.now(),
    orbit: provider.orbit
  })
}

function merge(existing, incoming) {
  var byId = {}
  var out = []
  var i
  for (i = 0; i < (existing || []).length; i++) {
    var item = normalize(existing[i])
    byId[item.id] = item
    out.push(item)
  }
  for (i = 0; i < (incoming || []).length; i++) {
    var next = normalize(incoming[i])
    if (byId[next.id]) {
      var old = byId[next.id]
      for (var key in next) {
        if (next[key] !== "" && next[key] !== undefined) old[key] = next[key]
      }
    } else {
      byId[next.id] = next
      out.push(next)
    }
  }
  return sort(out)
}

function sort(items) {
  return (items || []).slice().sort(function(a, b) {
    var attention = (b.attention ? 1 : 0) - (a.attention ? 1 : 0)
    if (attention !== 0) return attention
    return Number(b.updatedAt || 0) - Number(a.updatedAt || 0)
  })
}

function attentionCount(items) {
  var count = 0
  for (var i = 0; i < (items || []).length; i++)
    if (items[i].attention === true || items[i].status === "attention") count++
  return count
}

function statusLabel(status) {
  var key = String(status || "working")
  return {
    working: "Working",
    waiting: "Waiting",
    attention: "Needs you",
    paused: "Paused",
    offline: "Offline"
  }[key] || titleCase(key)
}

function statusColor(status, accent) {
  var key = String(status || "working")
  if (key === "attention") return "#FF8DA1"
  if (key === "waiting") return "#F0CF79"
  if (key === "paused") return "#9DA9BC"
  if (key === "offline") return "#6F7A8B"
  return accent || "#91D7C8"
}
