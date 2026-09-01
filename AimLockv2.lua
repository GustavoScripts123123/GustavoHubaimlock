local S = {
    HttpService = "HttpService",
    Players = "Players",
    CoreGui = "CoreGui",
    PlayerGui = "PlayerGui",
    GuiName = "GustavoHubKey",
    Title = "GUSTAVO HUB",
    Placeholder = "Enter your key...",
    Validate = "VALIDATE KEY",
    Validating = "Validating...",
    MissingKey = "Enter a key.",
    Api = "https://gustavo-hub-api.errpila.workers.dev",
    Json = "application/json",
    NoCache = "no-cache",
    GET = "GET",
    POST = "POST",
    ValidatePath = "/validate?key=",
    ScriptPath = "/script",
    KeyField = "key",
    TokenField = "token",
    ValidField = "valid",
    SuccessField = "success",
    ScriptField = "script",
    ServerError = "server_error",
    MissingKeyReason = "missing_key",
    InvalidSession = "invalid_session"
}

local gameRef = game
local pcallRef = pcall
local tostringRef = tostring
local typeRef = type

local HttpService = gameRef:GetService(S.HttpService)
local Players = gameRef:GetService(S.Players)

local API = S.Api

local function getRequest()
    if typeRef(request) == "function" then
        return request
    end

    if typeRef(http_request) == "function" then
        return http_request
    end

    if syn and typeRef(syn.request) == "function" then
        return syn.request
    end

    if fluxus and typeRef(fluxus.request) == "function" then
        return fluxus.request
    end

    return nil
end

local httpRequest = getRequest()

if not httpRequest then
    warn("GUSTAVO HUB: HTTP requests are unavailable.")
    return
end

local function http(method, url, body)
    local options = {
        Url = url,
        Method = method,
        Headers = {
            ["Accept"] = S.Json,
            ["Cache-Control"] = S.NoCache
        }
    }

    if body ~= nil then
        options.Headers["Content-Type"] = S.Json
        options.Body = HttpService:JSONEncode(body)
    end

    local success, response = pcallRef(function()
        return httpRequest(options)
    end)

    if not success or not response then
        return nil
    end

    local status = tonumber(
        response.StatusCode
        or response.Status
        or 0
    )

    local responseBody =
        response.Body
        or response.body

    if status < 200 or status >= 300 or not responseBody then
        return nil
    end

    local decoded, data = pcallRef(function()
        return HttpService:JSONDecode(responseBody)
    end)

    if not decoded or typeRef(data) ~= "table" then
        return nil
    end

    return data
end

local function getStoredKey()
    if typeRef(getgenv) == "function" then
        local environment = getgenv()

        local value = environment.GUSTAVO_HUB_KEY

        if typeRef(value) == "string" and value ~= "" then
            return value
        end
    end

    return nil
end

local function createKeyGui()
    local player = Players.LocalPlayer

    if not player then
        return nil
    end

    local oldGui

    pcallRef(function()
        oldGui = gameRef:GetService(S.CoreGui):FindFirstChild(S.GuiName)
    end)

    if oldGui then
        oldGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = S.GuiName
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true

    local parent

    pcallRef(function()
        parent = gameRef:GetService(S.CoreGui)
    end)

    if not parent then
        parent = player:WaitForChild(S.PlayerGui)
    end

    screenGui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(420, 210)
    frame.Position = UDim2.new(0.5, -210, 0.5, -105)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 40)
    title.Position = UDim2.fromOffset(15, 12)
    title.BackgroundTransparency = 1
    title.Text = S.Title
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.Parent = frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -40, 0, 45)
    input.Position = UDim2.fromOffset(20, 65)
    input.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    input.BorderSizePixel = 0
    input.PlaceholderText = S.Placeholder
    input.Text = ""
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    input.Font = Enum.Font.Gotham
    input.TextSize = 15
    input.ClearTextOnFocus = false
    input.Parent = frame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = input

    local validateButton = Instance.new("TextButton")
    validateButton.Size = UDim2.new(1, -40, 0, 42)
    validateButton.Position = UDim2.fromOffset(20, 125)
    validateButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    validateButton.BorderSizePixel = 0
    validateButton.Text = S.Validate
    validateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    validateButton.Font = Enum.Font.GothamBold
    validateButton.TextSize = 15
    validateButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = validateButton

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 25)
    status.Position = UDim2.fromOffset(20, 172)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.Parent = frame

    local result

    validateButton.MouseButton1Click:Connect(function()
        local value = tostringRef(input.Text or "")
            :gsub("^%s+", "")
            :gsub("%s+$", "")

        if value == "" then
            status.Text = S.MissingKey
            return
        end

        status.Text = S.Validating
        result = value
    end)

    while not result do
        task.wait()
    end

    screenGui:Destroy()

    return result
end

local key = getStoredKey()

if not key then
    key = createKeyGui()
end

if not key then
    warn("GUSTAVO HUB: No key was provided.")
    return
end

key = tostringRef(key)
    :gsub("^%s+", "")
    :gsub("%s+$", "")
    :upper()

local validation = http(
    S.GET,
    API .. S.ValidatePath .. HttpService:UrlEncode(key)
)

if not validation or validation[S.ValidField] ~= true then
    warn(
        "GUSTAVO HUB: Key rejected (" ..
        tostringRef(
            validation and validation.reason
            or S.ServerError
        ) ..
        ")."
    )

    return
end

local token = validation[S.TokenField]

if typeRef(token) ~= "string" or token == "" then
    warn("GUSTAVO HUB: Invalid session.")
    return
end

local payload = http(
    S.POST,
    API .. S.ScriptPath,
    {
        [S.TokenField] = token
    }
)

if not payload or payload[S.SuccessField] ~= true then
    warn(
        "GUSTAVO HUB: Unable to obtain the script (" ..
        tostringRef(
            payload and payload.reason
            or S.ServerError
        ) ..
        ")."
    )

    return
end

local code = payload[S.ScriptField]

if typeRef(code) ~= "string" or code == "" then
    warn("GUSTAVO HUB: Empty script received.")
    return
end

local load = loadstring

if typeRef(load) ~= "function" then
    warn("GUSTAVO HUB: loadstring is unavailable.")
    return
end

local compiled, compileError = load(code)

if not compiled then
    warn(
        "GUSTAVO HUB: Script compilation failed: " ..
        tostringRef(compileError)
    )

    return
end

local executed, runtimeError = pcallRef(compiled)

if not executed then
    warn(
        "GUSTAVO HUB: Script execution failed: " ..
        tostringRef(runtimeError)
    )
end
