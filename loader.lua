local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- ═══════════════════════════════════════════════════════════
-- SNAPSHOT DE FUNÇÕES ORIGINAIS (antes de qualquer hook)
-- ═══════════════════════════════════════════════════════════
local _ls          = loadstring
local _pcall       = pcall
local _tostring    = tostring
local _type        = type
local _rawget      = rawget
local _rawset      = rawset
local _rawequal    = rawequal
local _setmetatable= setmetatable
local _getmetatable= getmetatable
local _pairs       = pairs
local _ipairs      = ipairs
local _select      = select
local _unpack      = unpack or table.unpack
local _require     = require
local _print       = print
local _warn        = warn
local _error       = error
local _writefile   = writefile or function() end
local _readfile    = readfile or function() end
local _isfile      = isfile or function() return false end
local _appendfile  = appendfile or function() end
local _delfile     = delfile or function() end

-- ═══════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════
local API_URL      = "https://hwid-api-production.up.railway.app/verify"
local SECRET_TOKEN = "k8X2z9F4j7W1q5M3n6P0rT"
local SCRIPT_NAME  = "lefa"

-- URL cifrada via XOR (chave: 42)
local ENCODED_URL = {66,94,94,90,89,16,5,5,88,75,93,4,77,67,94,66,95,72,95,89,79,88,73,69,68,94,79,68,94,4,73,69,71,5,70,95,75,94,90,90,5,126,122,5,88,79,76,89,5,66,79,75,78,89,5,71,75,67,68,5,94,90,4,70,95,75}
local KEY_XOR = 42

local function decodeUrl()
    local result = {}
    for i, v in _ipairs(ENCODED_URL) do
        result[i] = string.char(bit32.bxor(v, KEY_XOR))
    end
    return table.concat(result)
end
local SCRIPT_URL = decodeUrl()

-- ═══════════════════════════════════════════════════════════
-- DETECTOR DE EXECUTOR
-- ═══════════════════════════════════════════════════════════
local httpRequest =
    (syn and syn.request) or
    (http and http.request) or
    (http_request) or
    (request) or
    nil

if not httpRequest then
    _error("[AUTH] Executor not supported.")
    return
end

-- Snapshot da request original
local _httpRequest = httpRequest

-- ═══════════════════════════════════════════════════════════
-- BLOQUEAR WRITEFILE IMEDIATAMENTE
-- ═══════════════════════════════════════════════════════════
if writefile then
    writefile = function(name, content)
        -- Só permitir config do próprio script
        if name and _tostring(name):find("XiUtils") then
            return _writefile(name, content)
        end
    end
end

-- Bloquear appendfile (spy usa para acumular código)
if appendfile then
    appendfile = function() end
end

-- ═══════════════════════════════════════════════════════════
-- PROTEÇÃO CONTRA TODOS OS VETORES CONHECIDOS
-- ═══════════════════════════════════════════════════════════
local KICK_MSG = "[SECURITY] Unauthorized activity detected. Rejoin to play."

local function kickPlayer()
    _pcall(function()
        Players.LocalPlayer:Kick(KICK_MSG)
    end)
end

local function verificarSeguranca()
    local lp = Players.LocalPlayer

    -- ── 1. Anti-loadstring Hook ────────────────────────────
    if _tostring(loadstring) ~= _tostring(_ls) then
        kickPlayer(); return false
    end

    -- ── 2. Anti-HTTP Request Hook ─────────────────────────
    local curRequest = (syn and syn.request) or (http and http.request) or (http_request) or (request)
    if _tostring(curRequest) ~= _tostring(_httpRequest) then
        kickPlayer(); return false
    end

    -- ── 3. Anti-Spy variáveis globais ─────────────────────
    local spyVars = {
        "SPY_ACTIVE","HTTP_SPY","LS_HOOK","HOOK_ACTIVE",
        "spy","Spy","hookLS","hookloadstring","spyActive",
        "httpSpy","loadstringSpy","ls_original","origLS",
        "PASSIVE_SPY","passiveSpy","scriptSpy","codeSpy",
        "reqHook","requestHook","lsHook","writefileSpy",
        "captureLS","captureLoadstring","hookReq"
    }
    local genv = getgenv and getgenv() or _G
    for _, v in _ipairs(spyVars) do
        if genv[v] then
            kickPlayer(); return false
        end
    end

    -- ── 4. Anti-getgenv Hook ──────────────────────────────
    if getgenv then
        local ok = _pcall(getgenv)
        if not ok then
            kickPlayer(); return false
        end
    end

    -- ── 5. Anti-debug Hook ────────────────────────────────
    if debug then
        -- Remover qualquer hook de debug ativo
        _pcall(function()
            if debug.sethook then debug.sethook() end
        end)
        -- Verificar se debug.getinfo foi hookado
        if debug.getinfo then
            local ok = _pcall(debug.getinfo, 1)
            if not ok then
                kickPlayer(); return false
            end
        end
    end

    -- ── 6. Anti-rawget/rawset Hook ────────────────────────
    if _tostring(rawget) ~= _tostring(_rawget) then
        kickPlayer(); return false
    end
    if _tostring(rawset) ~= _tostring(_rawset) then
        kickPlayer(); return false
    end

    -- ── 7. Anti-pcall Hook ────────────────────────────────
    if _tostring(pcall) ~= _tostring(_pcall) then
        kickPlayer(); return false
    end

    -- ── 8. Anti-print/warn Hook (spy usa para logar) ──────
    if _tostring(print) ~= _tostring(_print) then
        print = _print -- restaurar silenciosamente
    end
    if _tostring(warn) ~= _tostring(_warn) then
        warn = _warn -- restaurar silenciosamente
    end

    -- ── 9. Anti-require Hook ──────────────────────────────
    if _tostring(require) ~= _tostring(_require) then
        kickPlayer(); return false
    end

    -- ── 10. Anti-HttpGet Hook ─────────────────────────────
    local curHttpGet = _tostring(game.HttpGet)
    if curHttpGet == "nil" or curHttpGet == "" then
        kickPlayer(); return false
    end

    -- ── 11. Verificar integridade de funções base ─────────
    if not _rawequal(_type, type) then
        kickPlayer(); return false
    end

    -- ── 12. Anti-metatable spy ────────────────────────────
    -- Alguns spys colocam __index nos serviços para interceptar
    local mt = _getmetatable(game)
    if mt and _rawget(mt, "__newindex") then
        _pcall(function() _rawset(mt, "__newindex", nil) end)
    end

    -- ── 13. Anti-filesystem spy ───────────────────────────
    -- Verificar se writefile ainda está bloqueado
    if _tostring(writefile) == _tostring(_writefile) then
        -- writefile foi restaurado por alguém — bloquear novamente
        writefile = function(name, content)
            if name and _tostring(name):find("XiUtils") then
                return _writefile(name, content)
            end
        end
    end

    -- ── 14. Anti-environment injection ────────────────────
    if getfenv then
        local env = getfenv(0)
        if env and env["__spy__"] then
            kickPlayer(); return false
        end
    end

    return true
end

local function restaurarAmbiente()
    -- Restaurar writefile original após execução segura
    if _writefile then
        writefile = _writefile
    end
    if _appendfile then
        appendfile = _appendfile
    end
end

-- ═══════════════════════════════════════════════════════════
-- HWID
-- ═══════════════════════════════════════════════════════════
local function getHWID()
    local player = Players.LocalPlayer
    if not player then
        player = Players.PlayerAdded:Wait()
    end
    return _tostring(player.UserId)
end

-- ═══════════════════════════════════════════════════════════
-- VERIFICAÇÃO HWID NA API
-- ═══════════════════════════════════════════════════════════
local function verificar(key)
    local hwid = getHWID()
    local body = HttpService:JSONEncode({
        key    = key,
        hwid   = hwid,
        secret = SECRET_TOKEN,
        script = SCRIPT_NAME
    })
    local ok, response = _pcall(function()
        return _httpRequest({
            Url    = API_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body   = body
        })
    end)
    if not ok then _error("[AUTH] Connection failed.") return end
    local data
    _pcall(function() data = HttpService:JSONDecode(response.Body) end)
    if not data then _error("[AUTH] Invalid response.") return end
    if not data.success then _error("[AUTH] "..(data.reason or "Denied.")) return end
    return true
end

-- ═══════════════════════════════════════════════════════════
-- DESCRIPTOGRAFIA XOR + BASE64
-- ═══════════════════════════════════════════════════════════
-- Chave de descriptografia (multi-byte XOR)
local DEC_KEY = {0x4C,0x45,0x46,0x41,0x53,0x45,0x43,0x52,0x45,0x54,0x4B,0x45,0x59,0x21,0x40,0x23}
local DEC_KEY_LEN = #DEC_KEY

local function b64Decode(data)
    local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for i = 1, #b64chars do
        lookup[b64chars:sub(i,i)] = i - 1
    end
    local result = {}
    local padding = data:match("(=*)$")
    data = data:gsub("=", "")
    for i = 1, #data, 4 do
        local a = lookup[data:sub(i,i)] or 0
        local b = lookup[data:sub(i+1,i+1)] or 0
        local c = lookup[data:sub(i+2,i+2)] or 0
        local d = lookup[data:sub(i+3,i+3)] or 0
        local n = a * 262144 + b * 4096 + c * 64 + d
        table.insert(result, string.char(
            math.floor(n / 65536),
            math.floor(n / 256) % 256,
            n % 256
        ))
    end
    local decoded = table.concat(result)
    if #padding >= 2 then
        decoded = decoded:sub(1, -3)
    elseif #padding == 1 then
        decoded = decoded:sub(1, -2)
    end
    return decoded
end

local function xorDecrypt(data)
    local result = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        local keyByte = DEC_KEY[((i - 1) % DEC_KEY_LEN) + 1]
        result[i] = string.char(bit32.bxor(byte, keyByte))
    end
    return table.concat(result)
end

local function descriptografar(encryptedB64)
    local decoded = b64Decode(encryptedB64)
    return xorDecrypt(decoded)
end

-- ═══════════════════════════════════════════════════════════
-- EXECUTAR SCRIPT COM PROTEÇÃO MÁXIMA + DESCRIPTOGRAFIA
-- ═══════════════════════════════════════════════════════════
local function executarScript(url)
    -- Baixar conteúdo criptografado
    local encryptedContent = game:HttpGet(url)

    -- Verificar novamente antes de executar
    if not verificarSeguranca() then
        encryptedContent = nil
        return
    end

    -- Descriptografar em memória (interceptor de rede só vê dados criptografados)
    local decryptedContent = descriptografar(encryptedContent)
    encryptedContent = nil -- limpar criptografado

    -- Usar loadstring ORIGINAL salvo no início
    local fn, err = _ls(decryptedContent)

    -- Limpar conteúdo da memória imediatamente
    decryptedContent = nil
    url = nil

    if not fn then
        _error("[AUTH] Script load failed: " .. _tostring(err))
        return
    end

    -- Restaurar ambiente antes de executar o script
    restaurarAmbiente()

    -- Executar
    fn()
end

-- ═══════════════════════════════════════════════════════════
-- MAIN
-- ═══════════════════════════════════════════════════════════
local function main()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local player = Players.LocalPlayer
    if not player then
        player = Players.PlayerAdded:Wait()
    end

    -- Pegar key
    local key = ""
    if _G and _G.lefa_key then
        key = _tostring(_G.lefa_key)
    elseif getenv then
        key = getenv().key or ""
    end

    if key == "" then
        _error("[AUTH] No key provided. Use _G.lefa_key = 'YOUR-KEY'")
        return
    end

    -- Verificação de segurança completa
    if not verificarSeguranca() then return end

    -- Verificar HWID na API
    if verificar(key) then
        executarScript(SCRIPT_URL)
    end
end

-- Executar com proteção
local ok, err = _pcall(main)
if not ok then _warn(err) end
