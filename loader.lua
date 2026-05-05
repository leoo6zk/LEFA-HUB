local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local API_URL      = "https://hwid-api-production.up.railway.app/verify"
local SECRET_TOKEN = "k8X2z9F4j7W1q5M3n6P0rT"
local SCRIPT_NAME  = "lefa"

-- URL do script cifrada com XOR
local ENCODED_URL = {66,94,94,90,89,16,5,5,88,75,93,4,77,67,94,66,95,72,95,89,79,88,73,69,68,94,79,68,94,4,73,69,71,5,70,95,75,94,90,90,5,126,122,5,88,79,76,89,5,66,79,75,78,89,5,71,75,67,68,5,94,90,4,70,95,75}

local function bxor(a, b)
    local r, m = 0, 1
    for i = 1, 24 do
        local x = a % 2
        local y = b % 2
        if x ~= y then r = r + m end
        a = (a - x) / 2
        b = (b - y) / 2
        m = m * 2
    end
    return r
end

local function decodeUrl()
    local result = {}
    for i, v in ipairs(ENCODED_URL) do
        result[i] = string.char(bxor(v, 42))
    end
    return table.concat(result)
end

local SCRIPT_URL = decodeUrl()

-- Detector de executor
local httpRequest =
    (syn and syn.request) or
    (http and http.request) or
    (http_request) or
    (request) or
    nil

if not httpRequest then
    warn("[AUTH] Executor not supported.")
    return
end

-- Proteções básicas
local _ls = loadstring
local _wf = writefile or function() end

if writefile then
    writefile = function(n, d)
        if n and tostring(n):find("XiUtils") then
            return _wf(n, d)
        end
    end
end

if appendfile then
    appendfile = function() end
end

-- Anti-spy básico
local function checkSpy()
    local spyVars = {
        "SPY_ACTIVE","HTTP_SPY","LS_HOOK","HOOK_ACTIVE",
        "hookLS","spyActive","PASSIVE_SPY","passiveSpy"
    }
    local genv = getgenv and getgenv() or _G
    for _, v in ipairs(spyVars) do
        if genv[v] then
            pcall(function() Players.LocalPlayer:Kick("[SECURITY] Spy detected.") end)
            return false
        end
    end
    if tostring(loadstring) ~= tostring(_ls) then
        pcall(function() Players.LocalPlayer:Kick("[SECURITY] Hook detected.") end)
        return false
    end
    return true
end

-- HWID
local function getHWID()
    local player = Players.LocalPlayer
    if not player then
        player = Players.PlayerAdded:Wait()
    end
    return tostring(player.UserId)
end

-- Verificar HWID na API
local function verificar(key)
    local hwid = getHWID()
    local body = HttpService:JSONEncode({
        key    = key,
        hwid   = hwid,
        secret = SECRET_TOKEN,
        script = SCRIPT_NAME
    })
    local ok, response = pcall(function()
        return httpRequest({
            Url    = API_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body   = body
        })
    end)
    if not ok then warn("[AUTH] Connection failed.") return end
    local data
    pcall(function() data = HttpService:JSONDecode(response.Body) end)
    if not data then warn("[AUTH] Invalid response.") return end
    if not data.success then warn("[AUTH] " .. (data.reason or "Denied.")) return end
    return true
end

-- Main
local function main()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local player = Players.LocalPlayer
    if not player then
        player = Players.PlayerAdded:Wait()
    end

    local key = ""
    if _G and _G.lefa_key then
        key = tostring(_G.lefa_key)
    elseif getenv then
        key = getenv().key or ""
    end

    if key == "" then
        warn("[AUTH] No key provided. Use _G.lefa_key = 'YOUR-KEY'")
        return
    end

    if not checkSpy() then return end

    if verificar(key) then
        -- Restaurar writefile antes de executar o script
        if _wf then writefile = _wf end
        if appendfile then appendfile = nil end

        local content = game:HttpGet(SCRIPT_URL)
        local fn, err = loadstring(content)
        content = nil

        if not fn then
            warn("[AUTH] Failed to load script: " .. tostring(err))
            return
        end

        fn()
    end
end

local ok, err = pcall(main)
if not ok then warn(err) end
