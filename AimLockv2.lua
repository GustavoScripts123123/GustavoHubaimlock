local _0x={
    [1]="HttpService",
    [2]="Players",
    [3]="CoreGui",
    [4]="PlayerGui",
    [5]="GustavoHubKey",
    [6]="GTZ HUB",
    [7]="Introduz a tua key...",
    [8]="VALIDAR KEY",
    [9]="A validar...",
    [10]="Introduz uma key.",
    [11]="https://gustavo-hub-api.errpila.workers.dev",
    [12]="application/json",
    [13]="no-cache",
    [14]="GET",
    [15]="POST",
    [16]="/validate?key=",
    [17]="/script",
    [18]="key",
    [19]="token",
    [20]="valid",
    [21]="success",
    [22]="script",
    [23]="server_error",
    [24]="missing_key",
    [25]="invalid_session",
    [26]="GUSTAVO_HUB_KEY",
    [27]="GUSTAVO_HUB_TOKEN"
}

local function _s(n)
    return _0x[n]
end

local _g=game
local _pc=pcall
local _ts=tostring
local _ty=type

-- Logo do GTZ HUB: substitui pelo ID da imagem enviada para o Roblox.
local _LOGO="rbxassetid://125548024440666"

local _H=_g:GetService(_s(1))
local _P=_g:GetService(_s(2))

local _A=_s(11)

local function _rq()
    if _ty(request)=="function" then
        return request
    end

    if _ty(http_request)=="function" then
        return http_request
    end

    if syn and _ty(syn.request)=="function" then
        return syn.request
    end

    if fluxus and _ty(fluxus.request)=="function" then
        return fluxus.request
    end

    return nil
end

local _r=_rq()

if not _r then
    warn("GTZ HUB: HTTP indisponível.")
    return
end

local function _http(_m,_u,_b)
    local _o={
        Url=_u,
        Method=_m,
        Headers={
            ["Accept"]=_s(12),
            ["Cache-Control"]=_s(13)
        }
    }

    if _b then
        _o.Headers["Content-Type"]=_s(12)
        _o.Body=_H:JSONEncode(_b)
    end

    local _ok,_res=_pc(function()
        return _r(_o)
    end)

    if not _ok or not _res then
        return nil
    end

    local _st=
        tonumber(
            _res.StatusCode or
            _res.Status or
            0
        )

    local _body=
        _res.Body or
        _res.body

    if _st<200 or _st>=300 or not _body then
        return nil
    end

    local _dok,_data=_pc(function()
        return _H:JSONDecode(_body)
    end)

    if not _dok or _ty(_data)~="table" then
        return nil
    end

    return _data
end

local function _key()
    if getgenv then
        local _v=getgenv()[_s(26)]

        if _ty(_v)=="string" and _v~="" then
            return _v
        end
    end

    return nil
end

local function _gui()
    local _pl=_P.LocalPlayer

    if not _pl then
        return nil
    end

    local _old

    _pc(function()
        _old=_g:GetService(_s(3)):FindFirstChild(_s(5))
    end)

    if _old then
        _old:Destroy()
    end

    local _q=Instance.new("ScreenGui")
    _q.Name=_s(5)
    _q.ResetOnSpawn=false
    _q.IgnoreGuiInset=true

    local _parent

    _pc(function()
        _parent=_g:GetService(_s(3))
    end)

    if not _parent then
        _parent=_pl:WaitForChild(_s(4))
    end

    _q.Parent=_parent

    local _f=Instance.new("Frame")
    _f.Size=UDim2.fromOffset(420,420)
    _f.Position=UDim2.new(.5,-210,.5,-210)
    _f.BackgroundColor3=Color3.fromRGB(20,20,20)
    _f.BorderSizePixel=0
    _f.Parent=_q

    local _background=Instance.new("ImageLabel")
    _background.Name="GTZHubLogoBackground"
    _background.Size=UDim2.fromScale(1,1)
    _background.Position=UDim2.fromOffset(0,0)
    _background.BackgroundTransparency=1
    _background.Image=_LOGO
    _background.ScaleType=Enum.ScaleType.Crop
    _background.ZIndex=0
    _background.Parent=_f

    local _overlay=Instance.new("Frame")
    _overlay.Name="Overlay"
    _overlay.Size=UDim2.fromScale(1,1)
    _overlay.BackgroundColor3=Color3.fromRGB(8,4,12)
    _overlay.BackgroundTransparency=0.45
    _overlay.BorderSizePixel=0
    _overlay.ZIndex=1
    _overlay.Parent=_f

    local _fc=Instance.new("UICorner")
    _fc.CornerRadius=UDim.new(0,12)
    _fc.Parent=_f

    local _logo=Instance.new("ImageLabel")
    _logo.Name="GTZLogo"
    _logo.Size=UDim2.fromOffset(72,72)
    _logo.Position=UDim2.new(0.5,-36,0,18)
    _logo.BackgroundTransparency=1
    _logo.Image=_LOGO
    _logo.ScaleType=Enum.ScaleType.Fit
    _logo.ZIndex=2
    _logo.Parent=_f

    local _t=Instance.new("TextLabel")
    _t.Size=UDim2.new(1,-40,0,40)
    _t.Position=UDim2.fromOffset(20,92)
    _t.BackgroundTransparency=1
    _t.Text=_s(6)
    _t.TextColor3=Color3.fromRGB(255,255,255)
    _t.Font=Enum.Font.GothamBold
    _t.TextSize=24
    _t.ZIndex=2
    _t.Parent=_f

    local _b=Instance.new("TextBox")
    _b.Size=UDim2.new(1,-40,0,45)
    _b.Position=UDim2.fromOffset(20,150)
    _b.BackgroundColor3=Color3.fromRGB(35,35,35)
    _b.BorderSizePixel=0
    _b.PlaceholderText=_s(7)
    _b.Text=""
    _b.TextColor3=Color3.fromRGB(255,255,255)
    _b.PlaceholderColor3=Color3.fromRGB(150,150,150)
    _b.Font=Enum.Font.Gotham
    _b.TextSize=15
    _b.ClearTextOnFocus=false
    _b.ZIndex=2
    _b.Parent=_f

    local _bc=Instance.new("UICorner")
    _bc.CornerRadius=UDim.new(0,8)
    _bc.Parent=_b

    local _x=Instance.new("TextButton")
    _x.Size=UDim2.new(1,-40,0,42)
    _x.Position=UDim2.fromOffset(20,210)
    _x.BackgroundColor3=Color3.fromRGB(150,45,235)
    _x.BorderSizePixel=0
    _x.Text=_s(8)
    _x.TextColor3=Color3.fromRGB(255,255,255)
    _x.Font=Enum.Font.GothamBold
    _x.TextSize=15
    _x.ZIndex=2
    _x.Parent=_f

    local _xc=Instance.new("UICorner")
    _xc.CornerRadius=UDim.new(0,8)
    _xc.Parent=_x

    local _z=Instance.new("TextLabel")
    _z.Size=UDim2.new(1,-40,0,25)
    _z.Position=UDim2.fromOffset(20,260)
    _z.BackgroundTransparency=1
    _z.Text=""
    _z.TextColor3=Color3.fromRGB(255,255,255)
    _z.Font=Enum.Font.Gotham
    _z.TextSize=13
    _z.ZIndex=2
    _z.Parent=_f

    local _result

    _x.MouseButton1Click:Connect(function()
        local _v=tostring(_b.Text or "")
            :gsub("^%s+","")
            :gsub("%s+$","")

        if _v=="" then
            _z.Text=_s(10)
            return
        end

        _z.Text=_s(9)
        _result=_v
    end)

    while not _result do
        task.wait()
    end

    _q:Destroy()

    return _result
end

local _k=_key()

if not _k then
    _k=_gui()
end

if not _k then
    warn("GTZ HUB: key não encontrada.")
    return
end

_k=tostring(_k)
    :gsub("^%s+","")
    :gsub("%s+$","")
    :upper()

local _v=_http(
    _s(14),
    _A.._s(16).._H:UrlEncode(_k)
)

if not _v or _v[_s(20)]~=true then
    warn(
        "GTZ HUB: key recusada ("..
        tostring(_v and _v.reason or _s(23))..
        ")."
    )

    return
end

local _token=_v[_s(19)]

if _ty(_token)~="string" or _token=="" then
    warn("GTZ HUB: sessão inválida.")
    return
end

local _payload=_http(
    _s(15),
    _A.._s(17),
    {
        token=_token
    }
)

if not _payload or _payload[_s(21)]~=true then
    warn(
        "GTZ HUB: não foi possível obter o script ("..
        tostring(
            _payload and
            _payload.reason or
            _s(23)
        )..
        ")."
    )

    return
end

local _code=_payload[_s(22)]

if _ty(_code)~="string" or _code=="" then
    warn("GTZ HUB: script vazio.")
    return
end

if getgenv then
    getgenv()[_s(26)]=_k
    getgenv()[_s(27)]=_token
end

local _load=loadstring

if _ty(_load)~="function" then
    warn("GTZ HUB: loadstring indisponível.")
    return
end

local _fn,_err=_load(_code)

if not _fn then
    warn(
        "GTZ HUB: erro ao carregar o script: "..
        tostring(_err)
    )

    return
end

local _ok,_runtime=_pc(_fn)

if not _ok then
    warn(
        "GTZ HUB: erro ao executar o script: "..
        tostring(_runtime)
    )
end
