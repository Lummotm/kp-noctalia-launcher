--!nonstrict
-- KeePass launcher: lista de entradas -> acciones (usuario / contraseña / TOTP).
-- Habla con kp-daemon (repositorio aparte) por socket Unix.

-- Ruta del binario del demonio (ver `make install` en kp-daemon).
local DAEMON = "/usr/local/bin/kp-daemon"
-- Ruta de tu base .kdbx. La expande el shell, así que $HOME funciona.
local DB = "$HOME/Documents/Keepass/Personal-Vault.kdbx"
-- Máximo de filas que se muestran en la lista.
local RESULT_LIMIT = 100

local CURL = `curl -sS -m 5 --unix-socket "$XDG_RUNTIME_DIR/kp.sock"`

local entries = {} -- { id, title, user, url, totp }, sin contraseñas
local loaded = false

local function row(id, title, subtitle, glyph)
  return { id = id, title = title, subtitle = subtitle or "", glyph = glyph or "key" }
end

local function api(path, onDone, timeout)
  noctalia.runAsync(`{CURL} http://kp{path}`, function(r)
    onDone(r.exitCode == 0, r.stdout or "")
  end, timeout or 6000)
end

local function loadEntries(done)
  api("/list", function(ok, body)
    entries, loaded = {}, false
    if ok then
      local data = noctalia.json.decode(body)
      if type(data) == "table" then
        entries, loaded = data, true
      end
    end
    done()
  end)
end

local function matches(e, text)
  if text == "" then
    return true
  end
  local hay = string.lower((e.title or "") .. " " .. (e.user or "") .. " " .. (e.url or ""))
  return string.find(hay, string.lower(text), 1, true) ~= nil
end

local function showList(query, text)
  local rows = {}

  if not loaded then
    table.insert(rows, row("action:start", "Base bloqueada", "Enter para abrir KeePass e introducir la contraseña", "lock"))
    launcher.setResults(query, rows)
    return
  end

  -- Primero la opción de cerrar la base (si no hay filtro de texto)
  if text == "" then
    table.insert(rows, row("action:lock", "Cerrar la base", "Cierra la base y borra la memoria", "lock"))
  end

  -- Entradas de la base
  for i, e in entries do
    if #rows >= RESULT_LIMIT then
      break
    end
    if type(e) == "table" and matches(e, text) then
      table.insert(rows, row("entry:" .. i, e.title or "(sin título)", e.user or "", "key"))
    end
  end

  if #rows == 0 then
    table.insert(rows, row("", "Sin resultados", text, "search-off"))
  end

  launcher.setResults(query, rows)
end

local function showEntry(query, idx)
  local e = entries[idx]
  if e == nil then
    launcher.setResults(query, { row("", "Entrada no encontrada", "", "alert-triangle") })
    return
  end
  local rows = {
    row("copy:username:" .. idx, "Copiar usuario", e.user or "", "user"),
    row("copy:password:" .. idx, "Copiar contraseña", e.title or "", "password"),
  }
  if e.totp == true then
    table.insert(rows, row("copy:totp:" .. idx, "Copiar TOTP", "Código de un solo uso", "clock"))
  end
  table.insert(rows, row("back", "Volver", "", "arrow-left"))
  launcher.setResults(query, rows)
end

function onQuery(query)
  local text = noctalia.string.trim(query)
  local idx = string.match(text, "^#(%d+)")
  local function render()
    if idx ~= nil then
      showEntry(query, tonumber(idx))
    else
      showList(query, text)
    end
  end

  -- Recarga si la consulta está vacía o si la base aún no se ha cargado
  if text == "" or not loaded then
    loadEntries(render)
  else
    render()
  end
end

function onActivate(id)
  if id == "back" then
    launcher.setQuery("")
    return
  end

  if id == "action:start" then
    noctalia.runAsync(`setsid -f {DAEMON} "{DB}" >>"$XDG_RUNTIME_DIR/kp-daemon.log" 2>&1`)
    noctalia.notify("KeePass", "Introduce la contraseña en la ventana")
    return
  end

  if id == "action:lock" then
    noctalia.runAsync(`{CURL} -X POST http://kp/lock`, function()
      entries, loaded = {}, false
      launcher.setQuery("")
    end, 5000)
    return
  end

  local n = string.match(id, "^entry:(%d+)$")
  if n ~= nil then
    launcher.setQuery("#" .. n .. " ")
    return
  end

  local field, i = string.match(id, "^copy:(%a+):(%d+)$")
  if field == nil then
    return
  end
  local e = entries[tonumber(i)]
  if e == nil or type(e.id) ~= "string" or string.match(e.id, "^[%w%-]+$") == nil then
    return
  end

  api(`/entry/{e.id}/{field}`, function(ok, value)
    if ok and value ~= "" then
      noctalia.copyToClipboard(value, "text/plain;charset=utf-8")
      noctalia.notify("KeePass", (e.title or "Entrada") .. ": " .. field .. " copiado")
    else
      noctalia.notifyError("KeePass", "No se pudo leer el campo (¿base bloqueada?)")
    end
  end)
end
