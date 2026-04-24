local HttpService = game:GetService("HttpService")

local API_URL     = "https://hwid-api-production.up.railway.app/verify"
local HMAC_SECRET = "k8X2z9F4j7W1q5M3n6P0rT"
local SCRIPT_URL  = "https://raw.githubusercontent.com/lefahub/lefatp11/refs/heads/main/lefatp11"

local httpRequest = syn.request
local unpack = unpack or table.unpack

local function band(a,b) local r=0 for i=0,31 do local x=a%2 local y=b%2 if x==1 and y==1 then r=r+2^i end a=(a-x)/2 b=(b-y)/2 end return r end
local function bxor(a,b) local r=0 for i=0,31 do local x=a%2 local y=b%2 if x~=y then r=r+2^i end a=(a-x)/2 b=(b-y)/2 end return r end
local function bor(a,b) local r=0 for i=0,31 do local x=a%2 local y=b%2 if x==1 or y==1 then r=r+2^i end a=(a-x)/2 b=(b-y)/2 end return r end
local function rrot(x,n) return bor(math.floor(x/2^n),(x%(2^n))*2^(32-n)) end
local function add32(...) local s=0 for _,v in ipairs({...}) do s=s+v end return s%(2^32) end

local function sha256(msg)
    local K={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
    local H={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
    local msgLen=#msg local bits=msgLen*8
    msg=msg.."\128"
    while #msg%64~=56 do msg=msg.."\0" end
    msg=msg..string.char(0,0,0,0,math.floor(bits/2^24)%256,math.floor(bits/2^16)%256,math.floor(bits/2^8)%256,bits%256)
    for i=1,#msg,64 do
        local w={}
        for j=1,16 do local b=i+(j-1)*4 w[j]=((msg:byte(b) or 0)*2^24)+((msg:byte(b+1) or 0)*2^16)+((msg:byte(b+2) or 0)*2^8)+(msg:byte(b+3) or 0) end
        for j=17,64 do local s0=bxor(bxor(rrot(w[j-15],7),rrot(w[j-15],18)),math.floor(w[j-15]/2^3)) local s1=bxor(bxor(rrot(w[j-2],17),rrot(w[j-2],19)),math.floor(w[j-2]/2^10)) w[j]=add32(w[j-16],s0,w[j-7],s1) end
        local a,b,c,d,e,f,g,h=unpack(H)
        for j=1,64 do local S1=bxor(bxor(rrot(e,6),rrot(e,11)),rrot(e,25)) local ch=bxor(band(e,f),band(bxor(e,0xffffffff),g)) local temp1=add32(h,S1,ch,K[j],w[j]) local S0=bxor(bxor(rrot(a,2),rrot(a,13)),rrot(a,22)) local maj=bxor(bxor(band(a,b),band(a,c)),band(b,c)) local temp2=add32(S0,maj) h=g g=f f=e e=add32(d,temp1) d=c c=b b=a a=add32(temp1,temp2) end
        H[1]=add32(H[1],a) H[2]=add32(H[2],b) H[3]=add32(H[3],c) H[4]=add32(H[4],d) H[5]=add32(H[5],e) H[6]=add32(H[6],f) H[7]=add32(H[7],g) H[8]=add32(H[8],h)
    end
    local hex="" for _,v in ipairs(H) do hex=hex..string.format("%08x",v) end
    return hex
end

local function hmac_sha256(key,msg)
    if #key>64 then key=sha256(key) else while #key<64 do key=key.."\0" end end
    local ipad="" local opad=""
    for i=1,64 do local b=key:byte(i) ipad=ipad..string.char(bxor(b,0x36)) opad=opad..string.char(bxor(b,0x5c)) end
    return sha256(opad..sha256(ipad..msg))
end

local function generateNonce()
    local chars="abcdefghijklmnopqrstuvwxyz0123456789"
    local nonce="" for i=1,16 do local r=math.random(1,#chars) nonce=nonce..chars:sub(r,r) end
    return nonce
end

local function getHWID()
    local player=game.Players.LocalPlayer
    local uid=tostring(player.UserId)
    local age=tostring(player.AccountAge)
    local extra=""
    pcall(function() extra=tostring(game:GetService("RbxAnalyticsService"):GetClientId()) end)
    return uid.."_"..age.."_"..extra
end

local function verificar(key)
    local hwid=getHWID()
    local timestamp=tostring(math.floor(os.time()))
    local nonce=generateNonce()
    local body=HttpService:JSONEncode({key=key,hwid=hwid})
    local assinatura=hmac_sha256(HMAC_SECRET,body..":"..timestamp)

    local ok,response=pcall(function()
        return httpRequest({
            Url=API_URL,
            Method="POST",
            Headers={["Content-Type"]="application/json",["x-signature"]=assinatura,["x-timestamp"]=timestamp,["x-nonce"]=nonce},
            Body=body
        })
    end)

    if not ok then error("[AUTH] Falha na conexão.") return end
    local data
    pcall(function() data=HttpService:JSONDecode(response.Body) end)
    if not data then error("[AUTH] Resposta inválida.") return end
    if not data.success then error("[AUTH] "..(data.reason or "Negado.")) return end
    return true
end

local key=getenv and getenv().key or ""
if key=="" then error("[AUTH] Key não fornecida.") return end

local ok,err=pcall(function()
    if verificar(key) then
        loadstring(game:HttpGet(SCRIPT_URL))()
    end
end)

if not ok then warn(err) end
