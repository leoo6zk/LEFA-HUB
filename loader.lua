local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local API_URL      = "https://hwid-api-production.up.railway.app/verify"
local SECRET_TOKEN = "k8X2z9F4j7W1q5M3n6P0rT"
local SCRIPT_URL   = "https://raw.githubusercontent.com/luatpp/TP/refs/heads/main/tp.lua"

-- Auto detectar função de request do executor
local httpRequest = 
    (syn and syn.request) or           -- Synapse X
    (http and http.request) or         -- Antigos
    (http_request) or                  -- Fluxus, Delta
    (request) or                       -- Volt, Wave, Macsploit
    (KRNL_LOADED and http_request) or  -- Krnl
    nil

if not httpRequest then
    error("[AUTH] Executor not supported.")
    return
end

local unpack = unpack or table.unpack

local function getHWID()
    local player = Players.LocalPlayer
    local uid = tostring(player.UserId)
    local age = tostring(player.AccountAge)
    local extra = ""
    pcall(function() extra = tostring(game:GetService("RbxAnalyticsService"):GetClientId()) end)
    return uid.."_"..age.."_"..extra
end

local function verificar(key)
    local hwid = getHWID()
    local body = HttpService:JSONEncode({ key=key, hwid=hwid, secret=SECRET_TOKEN })
    local ok, response = pcall(function()
        return httpRequest({
            Url = API_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
    end)
    if not ok then error("[AUTH] Connection failed.") return end
    local data
    pcall(function() data = HttpService:JSONDecode(response.Body) end)
    if not data then error("[AUTH] Invalid response.") return end
    if not data.success then error("[AUTH] "..(data.reason or "Denied.")) return end
    return true
end

local function main()
    local key = ""
    if getenv then key = getenv().key or "" end
    if key == "" and _G and _G.key then key = tostring(_G.key) end
    if key == "" then error("[AUTH] No key provided.") return end
    local player = Players.LocalPlayer
    if not player then player = Players.PlayerAdded:Wait() end
    if verificar(key) then
        loadstring(game:HttpGet(SCRIPT_URL))()
    end
end

local ok, err = pcall(main)
if not ok then warn(err) end
