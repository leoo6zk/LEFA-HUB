local HttpService = game:GetService("HttpService")

local API_URL      = "https://hwid-api-production.up.railway.app/verify"
local SECRET_TOKEN = "k8X2z9F4j7W1q5M3n6P0rT"
local SCRIPT_URL   = "https://raw.githubusercontent.com/lefahub/lefatp11/refs/heads/main/lefatp11"

local function getHWID()
    local player = game.Players.LocalPlayer
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
        return syn.request({
            Url    = API_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body   = body
        })
    end)

    if not ok then error("[AUTH] Falha na conexão.") return end
    local data
    pcall(function() data = HttpService:JSONDecode(response.Body) end)
    if not data then error("[AUTH] Resposta inválida.") return end
    if not data.success then error("[AUTH] "..(data.reason or "Negado.")) return end
    return true
end

local key = ""
if getenv then key = getenv().key or "" end
if key == "" and _G and _G.key then key = tostring(_G.key) end
if key == "" then error("[AUTH] Key não fornecida.") return end

local ok, err = pcall(function()
    if verificar(key) then
        loadstring(game:HttpGet(SCRIPT_URL))()
    end
end)

if not ok then warn(err) end
