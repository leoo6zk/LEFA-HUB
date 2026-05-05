local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- ═══════════════════════════════════════════════════════════
-- SNAPSHOT DE FUNÇÕES ORIGINAIS (antes de qualquer hook)
-- ═══════════════════════════════════════════════════════════
local _ls          = loadstring
local _pcall       = pcall
local _tostring    = tostring
local _type        = type
local _rawget      = rawget or function(t,k) return t[k] end
local _rawset      = rawset or function(t,k,v) t[k]=v end
local _rawequal    = rawequal or function(a,b) return a==b end
local _setmetatable= setmetatable
local _getmetatable= getmetatable
local _pairs       = pairs
local _ipairs      = ipairs
local _select      = select
local _unpack      = unpack or table.unpack
local _require     = require
local _print       = print or function() end
local _warn        = warn or print or function() end
local _error       = error or function(e) end
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

