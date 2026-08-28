--[[ 
    GUSTAVO HUB

    Feito por: Gustavo Santos

    FUNÇÕES:
    - Aim-Lock
    - Smoothness do Aim-Lock
    - FOV ajustável
    - FOV visível/invisível
    - Aim Key configurável
    - Head / Body
    - Aim Team Check
    - Wall Check
    - ESP Box
    - ESP Health
    - ESP Distance
    - ESP Name opcional
    - ESP Team Check
    - Exclude players
    - Pesquisa de players
    - Selecionar/Deselecionar todos
    - GUI movível
    - GUI transparente 50/60%
    - GUI Key configurável
    - Minimize Key configurável
    - Minimizado não abre ao clicar
    - Quadrado mantém a posição do GUI
    - Animações
    - Botão para desligar o script

    DEFAULT:
    - Todas as opções começam OFF
    - Aim Key: Right Click (configurável: teclado/Left/Right/Middle/Mouse 4/Mouse 5)
    - Aim-Lock Toggle: None
    - ESP Toggle: None
    - GUI Key: V
    - Minimize Key: B
]]

--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local ScriptEnabled = true

-- Todas as opções começam OFF
local AimEnabled = false
local Aiming = false
local LockedTarget = nil

local ESPEnabled = false
local ESPName = false
local ESPHealth = false
local ESPDistance = false

local FOVVisible = false

local AimTeamCheck = false
local ESPTeamCheck = false
local WallCheck = false

-- Smoothness começa OFF/0
local SmoothEnabled = false
local Smoothness = 0

local AimKey = Enum.UserInputType.MouseButton2
local AimToggleKey = nil
local ESPToggleKey = nil
local GuiKey = Enum.KeyCode.V
local MinimizeKey = Enum.KeyCode.B

local FOVSize = 100
local MinFOV = 50
local MaxFOV = 300

local AimPart = "Head"

-- Transparência começa OFF
local GUITransparent = false

local ExcludedPlayers = {}
local SearchText = ""

local CurrentTab = "Aim"

local ChangingAimKey = false
local ChangingAimToggleKey = false
local ChangingESPToggleKey = false
local ChangingGuiKey = false
local ChangingMinimizeKey = false

local IsMinimized = false
local IsGuiOpen = true
local IsAnimating = false

--------------------------------------------------
-- COLORS
--------------------------------------------------

local BG = Color3.fromRGB(10, 11, 16)
local PANEL = Color3.fromRGB(16, 18, 25)
local PANEL2 = Color3.fromRGB(22, 24, 33)
local PANEL3 = Color3.fromRGB(30, 33, 44)

local TEXT = Color3.fromRGB(242, 244, 250)
local MUTED = Color3.fromRGB(135, 141, 155)

local ACCENT = Color3.fromRGB(95, 115, 255)
local ACCENT_DARK = Color3.fromRGB(65, 80, 190)

local GREEN = Color3.fromRGB(53, 190, 105)

--------------------------------------------------
-- TWEENS
--------------------------------------------------

local TweenFast = TweenInfo.new(
    0.15,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out
)

local TweenSmooth = TweenInfo.new(
    0.25,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out
)

local TweenOpen = TweenInfo.new(
    0.3,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out
)

local TweenClose = TweenInfo.new(
    0.22,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.In
)

local function Tween(Object, Properties, Info)
    pcall(function()
        TweenService:Create(
            Object,
            Info or TweenSmooth,
            Properties
        ):Play()
    end)
end

--------------------------------------------------
-- FOV CIRCLE
--------------------------------------------------

local FOVCircle = Drawing.new("Circle")

FOVCircle.Position = Vector2.new(
    Camera.ViewportSize.X / 2,
    Camera.ViewportSize.Y / 2
)

FOVCircle.Radius = FOVSize
FOVCircle.Color = Color3.fromRGB(120, 135, 255)
FOVCircle.Thickness = 1
FOVCircle.Transparency = 0.7
FOVCircle.Filled = false
FOVCircle.Visible = false

--------------------------------------------------
-- EXCLUDE
--------------------------------------------------

local function IsExcluded(Player)

    if not Player then
        return true
    end

    return ExcludedPlayers[Player] == true
end

--------------------------------------------------
-- TEAM CHECK
--------------------------------------------------

local function IsAimEnemy(Player)

    if not Player or Player == LocalPlayer then
        return false
    end

    if IsExcluded(Player) then
        return false
    end

    if not AimTeamCheck then
        return true
    end

    return Player.Team ~= LocalPlayer.Team
end

local function IsESPEnemy(Player)

    if not Player or Player == LocalPlayer then
        return false
    end

    if IsExcluded(Player) then
        return false
    end

    if not ESPTeamCheck then
        return true
    end

    return Player.Team ~= LocalPlayer.Team
end

--------------------------------------------------
-- WALL CHECK
--------------------------------------------------

local function CanSeeTarget(Part)

    if not WallCheck then
        return true
    end

    if not Part then
        return false
    end

    local Character = Part.Parent
    local MyCharacter = LocalPlayer.Character

    if not Character or not MyCharacter then
        return false
    end

    local MyHead = MyCharacter:FindFirstChild("Head")

    if not MyHead then
        return false
    end

    local Params = RaycastParams.new()

    Params.FilterType =
        Enum.RaycastFilterType.Exclude

    Params.FilterDescendantsInstances = {
        MyCharacter
    }

    Params.IgnoreWater = true

    local Direction =
        Part.Position - MyHead.Position

    local Result =
        workspace:Raycast(
            MyHead.Position,
            Direction,
            Params
        )

    if not Result then
        return true
    end

    return Result.Instance:IsDescendantOf(Character)
end

--------------------------------------------------
-- GET TARGET
--------------------------------------------------

local function GetClosestTarget()

    local Closest = nil
    local ShortestDistance = math.huge

    for _, Player in ipairs(
        Players:GetPlayers()
    ) do

        if IsAimEnemy(Player) then

            local Character = Player.Character

            if Character then

                local Humanoid =
                    Character:FindFirstChildOfClass(
                        "Humanoid"
                    )

                if Humanoid and Humanoid.Health > 0 then

                    local Part

                    if AimPart == "Head" then

                        Part =
                            Character:FindFirstChild(
                                "Head"
                            )

                    else

                        Part =
                            Character:FindFirstChild(
                                "HumanoidRootPart"
                            )
                    end

                    if Part then

                        local ScreenPosition, OnScreen =
                            Camera:WorldToViewportPoint(
                                Part.Position
                            )

                        if OnScreen then

                            local ScreenPoint =
                                Vector2.new(
                                    ScreenPosition.X,
                                    ScreenPosition.Y
                                )

                            local CenterDistance =
                                (
                                    ScreenPoint -
                                    FOVCircle.Position
                                ).Magnitude

                            if CenterDistance <= FOVSize then

                                if CanSeeTarget(Part) then

                                    local MyCharacter =
                                        LocalPlayer.Character

                                    local MyRoot =
                                        MyCharacter
                                        and
                                        MyCharacter:FindFirstChild(
                                            "HumanoidRootPart"
                                        )

                                    local Distance3D =
                                        math.huge

                                    if MyRoot then

                                        Distance3D =
                                            (
                                                Part.Position -
                                                MyRoot.Position
                                            ).Magnitude
                                    end

                                    if Distance3D <
                                        ShortestDistance then

                                        ShortestDistance =
                                            Distance3D

                                        Closest =
                                            Part
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return Closest
end

--------------------------------------------------
-- GUI
--------------------------------------------------

local GUI = Instance.new("ScreenGui")

GUI.Name = "GustavoHub"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    GUI.Parent = game:GetService("CoreGui")
end)

if not GUI.Parent then

    GUI.Parent =
        LocalPlayer:WaitForChild(
            "PlayerGui"
        )
end

--------------------------------------------------
-- MAIN
--------------------------------------------------

local Main = Instance.new("Frame")

Main.Name = "Main"

Main.Size =
    UDim2.new(
        0,
        520,
        0,
        630
    )

Main.Position =
    UDim2.new(
        0.5,
        -260,
        0.5,
        -315
    )

Main.BackgroundColor3 = BG
Main.BackgroundTransparency = 0
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI

local MainCorner =
    Instance.new("UICorner")

MainCorner.CornerRadius =
    UDim.new(0, 16)

MainCorner.Parent = Main

local MainStroke =
    Instance.new("UIStroke")

MainStroke.Color =
    Color3.fromRGB(45, 48, 62)

MainStroke.Thickness = 1
MainStroke.Transparency = 0.15
MainStroke.Parent = Main

--------------------------------------------------
-- TOP BAR
--------------------------------------------------

local Top = Instance.new("Frame")

Top.Name = "TopBar"

Top.Size =
    UDim2.new(
        1,
        0,
        0,
        78
    )

Top.BackgroundColor3 = PANEL
Top.BorderSizePixel = 0
Top.Active = true
Top.Parent = Main

local TopCorner =
    Instance.new("UICorner")

TopCorner.CornerRadius =
    UDim.new(0, 16)

TopCorner.Parent = Top

--------------------------------------------------
-- DRAG MAIN
--------------------------------------------------

local Dragging = false
local DragStart = nil
local StartPosition = nil

Top.InputBegan:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        Dragging = true
        DragStart = Input.Position
        StartPosition = Main.Position

        local Connection

        Connection =
            Input.Changed:Connect(function()

                if Input.UserInputState ==
                    Enum.UserInputState.End then

                    Dragging = false

                    if Connection then
                        Connection:Disconnect()
                    end
                end
            end)
    end
end)

UserInputService.InputChanged:Connect(function(Input)

    if not Dragging then
        return
    end

    if Input.UserInputType ~=
        Enum.UserInputType.MouseMovement then
        return
    end

    if not StartPosition or not DragStart then
        return
    end

    local Delta =
        Input.Position - DragStart

    Main.Position =
        UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
end)

--------------------------------------------------
-- TOP CONTENT
--------------------------------------------------

local AccentLine = Instance.new("Frame")

AccentLine.Size =
    UDim2.new(
        0,
        4,
        0,
        48
    )

AccentLine.Position =
    UDim2.new(
        0,
        18,
        0,
        15
    )

AccentLine.BackgroundColor3 = ACCENT
AccentLine.BorderSizePixel = 0
AccentLine.Parent = Top

local AccentCorner =
    Instance.new("UICorner")

AccentCorner.CornerRadius =
    UDim.new(1, 0)

AccentCorner.Parent = AccentLine

local Title =
    Instance.new("TextLabel")

Title.Size =
    UDim2.new(
        1,
        -80,
        0,
        28
    )

Title.Position =
    UDim2.new(
        0,
        34,
        0,
        13
    )

Title.BackgroundTransparency = 1
Title.Text = "GUSTAVO HUB"
Title.TextColor3 = TEXT
Title.TextSize = 21
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment =
    Enum.TextXAlignment.Left
Title.Parent = Top

local Subtitle =
    Instance.new("TextLabel")

Subtitle.Size =
    UDim2.new(
        1,
        -80,
        0,
        20
    )

Subtitle.Position =
    UDim2.new(
        0,
        34,
        0,
        41
    )

Subtitle.BackgroundTransparency = 1
Subtitle.Text =
    "Aim • ESP • Configuration"
Subtitle.TextColor3 = MUTED
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment =
    Enum.TextXAlignment.Left
Subtitle.Parent = Top

local StatusDot =
    Instance.new("Frame")

StatusDot.Size =
    UDim2.new(
        0,
        9,
        0,
        9
    )

StatusDot.Position =
    UDim2.new(
        1,
        -32,
        0,
        20
    )

StatusDot.BackgroundColor3 = GREEN
StatusDot.BorderSizePixel = 0
StatusDot.Parent = Top

local StatusCorner =
    Instance.new("UICorner")

StatusCorner.CornerRadius =
    UDim.new(1, 0)

StatusCorner.Parent = StatusDot

--------------------------------------------------
-- SIDEBAR
--------------------------------------------------

local Sidebar =
    Instance.new("Frame")

Sidebar.Size =
    UDim2.new(
        0,
        145,
        1,
        -98
    )

Sidebar.Position =
    UDim2.new(
        0,
        12,
        0,
        88
    )

Sidebar.BackgroundColor3 = PANEL
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarCorner =
    Instance.new("UICorner")

SidebarCorner.CornerRadius =
    UDim.new(0, 12)

SidebarCorner.Parent = Sidebar

local SideTitle =
    Instance.new("TextLabel")

SideTitle.Size =
    UDim2.new(
        1,
        -24,
        0,
        24
    )

SideTitle.Position =
    UDim2.new(
        0,
        12,
        0,
        12
    )

SideTitle.BackgroundTransparency = 1
SideTitle.Text = "MENU"
SideTitle.TextColor3 = MUTED
SideTitle.TextSize = 10
SideTitle.Font = Enum.Font.GothamBold
SideTitle.TextXAlignment =
    Enum.TextXAlignment.Left
SideTitle.Parent = Sidebar

--------------------------------------------------
-- CONTENT
--------------------------------------------------

local Content =
    Instance.new("Frame")

Content.Size =
    UDim2.new(
        1,
        -170,
        1,
        -98
    )

Content.Position =
    UDim2.new(
        0,
        157,
        0,
        88
    )

Content.BackgroundColor3 = PANEL
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.Parent = Main

local ContentCorner =
    Instance.new("UICorner")

ContentCorner.CornerRadius =
    UDim.new(0, 12)

ContentCorner.Parent = Content

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function CreatePage()

    local Page =
        Instance.new("Frame")

    Page.Size =
        UDim2.new(
            1,
            -24,
            1,
            -24
        )

    Page.Position =
        UDim2.new(
            0,
            12,
            0,
            12
        )

    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.Parent = Content

    return Page
end

local function CreateLabel(
    Parent,
    TextValue,
    Position,
    Size,
    TextSize
)

    local Label =
        Instance.new("TextLabel")

    Label.Size = Size
    Label.Position = Position
    Label.BackgroundTransparency = 1
    Label.Text = TextValue
    Label.TextColor3 = TEXT
    Label.TextSize = TextSize or 13
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment =
        Enum.TextXAlignment.Left
    Label.Parent = Parent

    return Label
end

local function CreateButton(
    Parent,
    TextValue,
    Position,
    Size
)

    local Button =
        Instance.new("TextButton")

    Button.Size = Size
    Button.Position = Position
    Button.BackgroundColor3 = PANEL2
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Text = TextValue
    Button.TextColor3 = TEXT
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamSemibold
    Button.Parent = Parent

    local Corner =
        Instance.new("UICorner")

    Corner.CornerRadius =
        UDim.new(0, 9)

    Corner.Parent = Button

    local Stroke =
        Instance.new("UIStroke")

    Stroke.Color =
        Color3.fromRGB(43, 46, 58)

    Stroke.Transparency = 0.35
    Stroke.Thickness = 1
    Stroke.Parent = Button

    Button.MouseEnter:Connect(function()

        if Button:GetAttribute("Active") then

            Tween(
                Button,
                {
                    BackgroundColor3 = ACCENT
                },
                TweenFast
            )

        else

            Tween(
                Button,
                {
                    BackgroundColor3 = PANEL3
                },
                TweenFast
            )
        end
    end)

    Button.MouseLeave:Connect(function()

        if Button:GetAttribute("Active") then

            Tween(
                Button,
                {
                    BackgroundColor3 =
                        ACCENT_DARK
                },
                TweenFast
            )

        else

            Tween(
                Button,
                {
                    BackgroundColor3 =
                        PANEL2
                },
                TweenFast
            )
        end
    end)

    return Button
end

local function SetToggle(
    Button,
    Enabled,
    TextValue
)

    Button:SetAttribute(
        "Active",
        Enabled
    )

    if Enabled then

        Button.Text =
            TextValue .. ": ON"

        Tween(
            Button,
            {
                BackgroundColor3 =
                    ACCENT_DARK
            },
            TweenFast
        )

    else

        Button.Text =
            TextValue .. ": OFF"

        Tween(
            Button,
            {
                BackgroundColor3 =
                    PANEL2
            },
            TweenFast
        )
    end
end

--------------------------------------------------
-- PAGES
--------------------------------------------------

local AimPage = CreatePage()
local ESPPage = CreatePage()
local ExcludePage = CreatePage()
local SettingsPage = CreatePage()

--------------------------------------------------
-- AIM PAGE
--------------------------------------------------

CreateLabel(
    AimPage,
    "Aim-Lock",
    UDim2.new(0, 6, 0, 4),
    UDim2.new(1, -12, 0, 30),
    19
)

local AimSubtitle =
    CreateLabel(
        AimPage,
        "Target configuration",
        UDim2.new(0, 6, 0, 34),
        UDim2.new(1, -12, 0, 22),
        11
    )

AimSubtitle.TextColor3 = MUTED

local AimToggle =
    CreateButton(
        AimPage,
        "AIM-LOCK: OFF",
        UDim2.new(0, 6, 0, 68),
        UDim2.new(1, -12, 0, 40)
    )

--------------------------------------------------
-- FOV
--------------------------------------------------

local FOVTitle =
    CreateLabel(
        AimPage,
        "FOV SIZE",
        UDim2.new(0, 6, 0, 123),
        UDim2.new(1, -70, 0, 22),
        11
    )

FOVTitle.TextColor3 = MUTED

local FOVLabel =
    CreateLabel(
        AimPage,
        tostring(FOVSize),
        UDim2.new(1, -66, 0, 123),
        UDim2.new(0, 60, 0, 22),
        12
    )

FOVLabel.TextXAlignment =
    Enum.TextXAlignment.Right

local SliderBack =
    Instance.new("Frame")

SliderBack.Size =
    UDim2.new(
        1,
        -12,
        0,
        7
    )

SliderBack.Position =
    UDim2.new(
        0,
        6,
        0,
        154
    )

SliderBack.BackgroundColor3 =
    Color3.fromRGB(43, 46, 58)

SliderBack.BorderSizePixel = 0
SliderBack.Active = true
SliderBack.Parent = AimPage

local SliderBackCorner =
    Instance.new("UICorner")

SliderBackCorner.CornerRadius =
    UDim.new(1, 0)

SliderBackCorner.Parent =
    SliderBack

local Slider =
    Instance.new("TextButton")

Slider.Size =
    UDim2.new(
        0,
        16,
        0,
        16
    )

local InitialPercent =
    (FOVSize - MinFOV) /
    (MaxFOV - MinFOV)

Slider.Position =
    UDim2.new(
        InitialPercent,
        -8,
        0.5,
        -8
    )

Slider.BackgroundColor3 =
    Color3.fromRGB(
        225,
        228,
        240
    )

Slider.BorderSizePixel = 0
Slider.Text = ""
Slider.AutoButtonColor = false
Slider.Parent = SliderBack

local SliderCorner =
    Instance.new("UICorner")

SliderCorner.CornerRadius =
    UDim.new(1, 0)

SliderCorner.Parent = Slider

local DraggingSlider = false

local function UpdateFOVSlider(X)

    local Width =
        SliderBack.AbsoluteSize.X

    if Width <= 0 then
        return
    end

    local Relative =
        math.clamp(
            X -
            SliderBack.AbsolutePosition.X,
            0,
            Width
        )

    local Percent =
        Relative / Width

    FOVSize =
        math.floor(
            MinFOV +
            (
                MaxFOV -
                MinFOV
            ) * Percent
        )

    Slider.Position =
        UDim2.new(
            Percent,
            -8,
            0.5,
            -8
        )

    FOVLabel.Text =
        tostring(FOVSize)
end

SliderBack.InputBegan:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        UpdateFOVSlider(
            Input.Position.X
        )

        DraggingSlider = true
    end
end)

Slider.InputBegan:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        DraggingSlider = true
    end
end)

UserInputService.InputChanged:Connect(function(Input)

    if not DraggingSlider then
        return
    end

    if Input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        UpdateFOVSlider(
            Input.Position.X
        )
    end
end)

UserInputService.InputEnded:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        DraggingSlider = false
    end
end)

--------------------------------------------------
-- FOV BUTTON
--------------------------------------------------

local FOVButton =
    CreateButton(
        AimPage,
        "FOV CIRCLE: OFF",
        UDim2.new(0, 6, 0, 180),
        UDim2.new(1, -12, 0, 38)
    )

--------------------------------------------------
-- AIM KEY
--------------------------------------------------

local AimKeyButton =
    CreateButton(
        AimPage,
        "AIM KEY: RIGHT CLICK",
        UDim2.new(0, 6, 0, 227),
        UDim2.new(1, -12, 0, 38)
    )

--------------------------------------------------
-- AIM PART
--------------------------------------------------

local HeadButton =
    CreateButton(
        AimPage,
        "HEAD",
        UDim2.new(0, 6, 0, 274),
        UDim2.new(0.5, -9, 0, 38)
    )

local BodyButton =
    CreateButton(
        AimPage,
        "BODY",
        UDim2.new(0.5, 3, 0, 274),
        UDim2.new(0.5, -9, 0, 38)
    )

--------------------------------------------------
-- CHECKS
--------------------------------------------------

local AimTeamButton =
    CreateButton(
        AimPage,
        "TEAM CHECK: OFF",
        UDim2.new(0, 6, 0, 321),
        UDim2.new(0.5, -9, 0, 38)
    )

local WallButton =
    CreateButton(
        AimPage,
        "WALL CHECK: OFF",
        UDim2.new(0.5, 3, 0, 321),
        UDim2.new(0.5, -9, 0, 38)
    )

--------------------------------------------------
-- SMOOTHNESS
--------------------------------------------------

local SmoothTitle =
    CreateLabel(
        AimPage,
        "SMOOTHNESS",
        UDim2.new(0, 6, 0, 370),
        UDim2.new(1, -70, 0, 22),
        11
    )

SmoothTitle.TextColor3 = MUTED

local SmoothLabel =
    CreateLabel(
        AimPage,
        "OFF",
        UDim2.new(1, -66, 0, 370),
        UDim2.new(0, 60, 0, 22),
        12
    )

SmoothLabel.TextXAlignment =
    Enum.TextXAlignment.Right

local SmoothBack =
    Instance.new("Frame")

SmoothBack.Size =
    UDim2.new(
        1,
        -12,
        0,
        7
    )

SmoothBack.Position =
    UDim2.new(
        0,
        6,
        0,
        401
    )

SmoothBack.BackgroundColor3 =
    Color3.fromRGB(43, 46, 58)

SmoothBack.BorderSizePixel = 0
SmoothBack.Active = true
SmoothBack.Parent = AimPage

local SmoothBackCorner =
    Instance.new("UICorner")

SmoothBackCorner.CornerRadius =
    UDim.new(1, 0)

SmoothBackCorner.Parent =
    SmoothBack

local SmoothSlider =
    Instance.new("TextButton")

SmoothSlider.Size =
    UDim2.new(
        0,
        16,
        0,
        16
    )

SmoothSlider.Position =
    UDim2.new(
        0,
        -8,
        0.5,
        -8
    )

SmoothSlider.BackgroundColor3 =
    Color3.fromRGB(
        225,
        228,
        240
    )

SmoothSlider.BorderSizePixel = 0
SmoothSlider.Text = ""
SmoothSlider.AutoButtonColor = false
SmoothSlider.Parent = SmoothBack

local SmoothCorner =
    Instance.new("UICorner")

SmoothCorner.CornerRadius =
    UDim.new(1, 0)

SmoothCorner.Parent =
    SmoothSlider

local SmoothDragging = false

local function UpdateSmoothSlider(X)

    local Width =
        SmoothBack.AbsoluteSize.X

    if Width <= 0 then
        return
    end

    local Relative =
        math.clamp(
            X -
            SmoothBack.AbsolutePosition.X,
            0,
            Width
        )

    local Percent =
        Relative / Width

    -- 0 = sem smooth
    -- 1 = muito smooth

    Smoothness = Percent

    if Percent <= 0.01 then

        SmoothEnabled = false
        SmoothLabel.Text = "OFF"

    else

        SmoothEnabled = true

        SmoothLabel.Text =
            tostring(
                math.floor(
                    Percent * 100
                )
            ) .. "%"
    end

    SmoothSlider.Position =
        UDim2.new(
            Percent,
            -8,
            0.5,
            -8
        )
end

SmoothBack.InputBegan:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        SmoothDragging = true

        UpdateSmoothSlider(
            Input.Position.X
        )
    end
end)

SmoothSlider.InputBegan:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        SmoothDragging = true
    end
end)

UserInputService.InputChanged:Connect(function(Input)

    if not SmoothDragging then
        return
    end

    if Input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        UpdateSmoothSlider(
            Input.Position.X
        )
    end
end)

UserInputService.InputEnded:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        SmoothDragging = false
    end
end)

--------------------------------------------------
-- AIM EVENTS
--------------------------------------------------

AimToggle.MouseButton1Click:Connect(function()

    AimEnabled =
        not AimEnabled

    if not AimEnabled then

        Aiming = false
        LockedTarget = nil
    end

    SetToggle(
        AimToggle,
        AimEnabled,
        "AIM-LOCK"
    )
end)

FOVButton.MouseButton1Click:Connect(function()

    FOVVisible =
        not FOVVisible

    SetToggle(
        FOVButton,
        FOVVisible,
        "FOV CIRCLE"
    )
end)

AimKeyButton.MouseButton1Click:Connect(function()

    ChangingAimKey = true
    ChangingGuiKey = false
    ChangingMinimizeKey = false

    AimKeyButton.Text =
        "AIM KEY: PRESS KEY..."
end)

HeadButton.MouseButton1Click:Connect(function()

    AimPart = "Head"

    Aiming = false
    LockedTarget = nil

    HeadButton:SetAttribute(
        "Active",
        true
    )

    BodyButton:SetAttribute(
        "Active",
        false
    )

    Tween(
        HeadButton,
        {
            BackgroundColor3 =
                ACCENT_DARK
        },
        TweenFast
    )

    Tween(
        BodyButton,
        {
            BackgroundColor3 =
                PANEL2
        },
        TweenFast
    )
end)

BodyButton.MouseButton1Click:Connect(function()

    AimPart = "Body"

    Aiming = false
    LockedTarget = nil

    HeadButton:SetAttribute(
        "Active",
        false
    )

    BodyButton:SetAttribute(
        "Active",
        true
    )

    Tween(
        HeadButton,
        {
            BackgroundColor3 =
                PANEL2
        },
        TweenFast
    )

    Tween(
        BodyButton,
        {
            BackgroundColor3 =
                ACCENT_DARK
        },
        TweenFast
    )
end)

AimTeamButton.MouseButton1Click:Connect(function()

    AimTeamCheck =
        not AimTeamCheck

    Aiming = false
    LockedTarget = nil

    SetToggle(
        AimTeamButton,
        AimTeamCheck,
        "TEAM CHECK"
    )
end)

WallButton.MouseButton1Click:Connect(function()

    WallCheck =
        not WallCheck

    Aiming = false
    LockedTarget = nil

    SetToggle(
        WallButton,
        WallCheck,
        "WALL CHECK"
    )
end)

--------------------------------------------------
-- ESP PAGE
--------------------------------------------------

CreateLabel(
    ESPPage,
    "ESP",
    UDim2.new(0, 6, 0, 4),
    UDim2.new(1, -12, 0, 30),
    19
)

local ESPSubtitle =
    CreateLabel(
        ESPPage,
        "Player visual information",
        UDim2.new(0, 6, 0, 34),
        UDim2.new(1, -12, 0, 22),
        11
    )

ESPSubtitle.TextColor3 = MUTED

local ESPButton =
    CreateButton(
        ESPPage,
        "ESP BOX: OFF",
        UDim2.new(0, 6, 0, 68),
        UDim2.new(1, -12, 0, 40)
    )

local NameButton =
    CreateButton(
        ESPPage,
        "NAME: OFF",
        UDim2.new(0, 6, 0, 119),
        UDim2.new(0.5, -9, 0, 38)
    )

local HealthButton =
    CreateButton(
        ESPPage,
        "HEALTH: OFF",
        UDim2.new(0.5, 3, 0, 119),
        UDim2.new(0.5, -9, 0, 38)
    )

local DistanceButton =
    CreateButton(
        ESPPage,
        "DISTANCE: OFF",
        UDim2.new(0, 6, 0, 166),
        UDim2.new(0.5, -9, 0, 38)
    )

local ESPTeamButton =
    CreateButton(
        ESPPage,
        "TEAM CHECK: OFF",
        UDim2.new(0.5, 3, 0, 166),
        UDim2.new(0.5, -9, 0, 38)
    )

ESPButton.MouseButton1Click:Connect(function()

    ESPEnabled =
        not ESPEnabled

    SetToggle(
        ESPButton,
        ESPEnabled,
        "ESP BOX"
    )
end)

NameButton.MouseButton1Click:Connect(function()

    ESPName =
        not ESPName

    SetToggle(
        NameButton,
        ESPName,
        "NAME"
    )
end)

HealthButton.MouseButton1Click:Connect(function()

    ESPHealth =
        not ESPHealth

    SetToggle(
        HealthButton,
        ESPHealth,
        "HEALTH"
    )
end)

DistanceButton.MouseButton1Click:Connect(function()

    ESPDistance =
        not ESPDistance

    SetToggle(
        DistanceButton,
        ESPDistance,
        "DISTANCE"
    )
end)

ESPTeamButton.MouseButton1Click:Connect(function()

    ESPTeamCheck =
        not ESPTeamCheck

    SetToggle(
        ESPTeamButton,
        ESPTeamCheck,
        "TEAM CHECK"
    )
end)

--------------------------------------------------
-- ESP DRAWINGS
--------------------------------------------------

local ESPObjects = {}

local function RemoveESP(Player)

    local Data =
        ESPObjects[Player]

    if not Data then
        return
    end

    for _, Object in pairs(Data) do

        pcall(function()
            Object:Remove()
        end)
    end

    ESPObjects[Player] = nil
end

local function CreateESP(Player)

    if Player == LocalPlayer then
        return
    end

    RemoveESP(Player)

    local Box =
        Drawing.new("Square")

    Box.Thickness = 1
    Box.Filled = false
    Box.Color =
        Color3.fromRGB(
            255,
            255,
            255
        )
    Box.Visible = false

    local Name =
        Drawing.new("Text")

    Name.Size = 13
    Name.Center = true
    Name.Outline = true
    Name.Color =
        Color3.fromRGB(
            255,
            255,
            255
        )
    Name.Visible = false

    local Info =
        Drawing.new("Text")

    Info.Size = 13
    Info.Center = true
    Info.Outline = true
    Info.Color =
        Color3.fromRGB(
            255,
            255,
            255
        )
    Info.Visible = false

    ESPObjects[Player] = {
        Box = Box,
        Name = Name,
        Info = Info
    }
end

for _, Player in ipairs(
    Players:GetPlayers()
) do

    CreateESP(Player)
end

Players.PlayerAdded:Connect(function(Player)

    CreateESP(Player)
end)

Players.PlayerRemoving:Connect(function(Player)

    RemoveESP(Player)

    ExcludedPlayers[Player] = nil
end)

--------------------------------------------------
-- ESP UPDATE
--------------------------------------------------

local function UpdateESP()

    for Player, Data in pairs(
        ESPObjects
    ) do

        local Box = Data.Box
        local Name = Data.Name
        local Info = Data.Info

        Box.Visible = false
        Name.Visible = false
        Info.Visible = false

        if not ScriptEnabled
            or not ESPEnabled then
            continue
        end

        if not IsESPEnemy(Player) then
            continue
        end

        local Character =
            Player.Character

        if not Character then
            continue
        end

        local Humanoid =
            Character:FindFirstChildOfClass(
                "Humanoid"
            )

        local Root =
            Character:FindFirstChild(
                "HumanoidRootPart"
            )

        local Head =
            Character:FindFirstChild(
                "Head"
            )

        if not Humanoid
            or Humanoid.Health <= 0
            or not Root
            or not Head then
            continue
        end

        local TopPosition, TopVisible =
            Camera:WorldToViewportPoint(
                Head.Position +
                Vector3.new(
                    0,
                    0.5,
                    0
                )
            )

        local BottomPosition, BottomVisible =
            Camera:WorldToViewportPoint(
                Root.Position -
                Vector3.new(
                    0,
                    3,
                    0
                )
            )

        if not TopVisible
            and not BottomVisible then
            continue
        end

        local Height =
            math.abs(
                BottomPosition.Y -
                TopPosition.Y
            )

        local Width =
            Height * 0.55

        if Height <= 0 then
            continue
        end

        Box.Position =
            Vector2.new(
                TopPosition.X -
                Width / 2,
                TopPosition.Y
            )

        Box.Size =
            Vector2.new(
                Width,
                Height
            )

        Box.Visible = true

        if ESPName then

            Name.Position =
                Vector2.new(
                    TopPosition.X,
                    TopPosition.Y - 18
                )

            Name.Text =
                Player.Name

            Name.Visible = true
        end

        local InfoText = ""

        if ESPHealth then

            InfoText =
                "HP: "
                ..
                math.floor(
                    Humanoid.Health
                )
                ..
                "/"
                ..
                math.floor(
                    Humanoid.MaxHealth
                )
        end

        if ESPDistance then

            local MyCharacter =
                LocalPlayer.Character

            local MyRoot =
                MyCharacter
                and
                MyCharacter:FindFirstChild(
                    "HumanoidRootPart"
                )

            if MyRoot then

                local Distance =
                    math.floor(
                        (
                            Root.Position -
                            MyRoot.Position
                        ).Magnitude
                    )

                if InfoText ~= "" then

                    InfoText =
                        InfoText ..
                        "  |  "
                end

                InfoText =
                    InfoText ..
                    Distance ..
                    " studs"
            end
        end

        if InfoText ~= "" then

            Info.Position =
                Vector2.new(
                    TopPosition.X,
                    BottomPosition.Y + 3
                )

            Info.Text =
                InfoText

            if ESPHealth then

                local Percentage =
                    math.clamp(
                        Humanoid.Health /
                        math.max(
                            Humanoid.MaxHealth,
                            1
                        ),
                        0,
                        1
                    )

                if Percentage > 0.6 then

                    Info.Color =
                        Color3.fromRGB(
                            80,
                            255,
                            100
                        )

                elseif Percentage > 0.3 then

                    Info.Color =
                        Color3.fromRGB(
                            255,
                            220,
                            70
                        )

                else

                    Info.Color =
                        Color3.fromRGB(
                            255,
                            70,
                            70
                        )
                end

            else

                Info.Color =
                    Color3.fromRGB(
                        255,
                        255,
                        255
                    )
            end

            Info.Visible = true
        end
    end
end

--------------------------------------------------
-- EXCLUDE PAGE
--------------------------------------------------

CreateLabel(
    ExcludePage,
    "Exclude Players",
    UDim2.new(0, 6, 0, 4),
    UDim2.new(1, -12, 0, 30),
    19
)

local ExcludeSubtitle =
    CreateLabel(
        ExcludePage,
        "Players excluded from Aim-Lock and ESP",
        UDim2.new(0, 6, 0, 34),
        UDim2.new(1, -12, 0, 22),
        11
    )

ExcludeSubtitle.TextColor3 = MUTED

local SearchBox =
    Instance.new("TextBox")

SearchBox.Size =
    UDim2.new(
        1,
        -12,
        0,
        38
    )

SearchBox.Position =
    UDim2.new(
        0,
        6,
        0,
        68
    )

SearchBox.BackgroundColor3 = PANEL2
SearchBox.BorderSizePixel = 0
SearchBox.PlaceholderText =
    "🔎  Pesquisar player..."
SearchBox.PlaceholderColor3 = MUTED
SearchBox.Text = ""
SearchBox.TextColor3 = TEXT
SearchBox.TextSize = 12
SearchBox.Font = Enum.Font.Gotham
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = ExcludePage

local SearchCorner =
    Instance.new("UICorner")

SearchCorner.CornerRadius =
    UDim.new(0, 9)

SearchCorner.Parent = SearchBox

local SearchStroke =
    Instance.new("UIStroke")

SearchStroke.Color =
    Color3.fromRGB(
        43,
        46,
        58
    )

SearchStroke.Transparency = 0.35
SearchStroke.Parent = SearchBox

local SelectAllButton =
    CreateButton(
        ExcludePage,
        "☑  SELECIONAR TODOS",
        UDim2.new(0, 6, 0, 116),
        UDim2.new(0.5, -9, 0, 37)
    )

local DeselectAllButton =
    CreateButton(
        ExcludePage,
        "☐  DESELECIONAR",
        UDim2.new(0.5, 3, 0, 116),
        UDim2.new(0.5, -9, 0, 37)
    )

local RefreshButton =
    CreateButton(
        ExcludePage,
        "↻  ATUALIZAR PLAYERS",
        UDim2.new(0, 6, 0, 162),
        UDim2.new(1, -12, 0, 37)
    )

local PlayerList =
    Instance.new("ScrollingFrame")

PlayerList.Size =
    UDim2.new(
        1,
        -12,
        0,
        360
    )

PlayerList.Position =
    UDim2.new(
        0,
        6,
        0,
        210
    )

PlayerList.BackgroundColor3 =
    Color3.fromRGB(
        13,
        15,
        21
    )

PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 3
PlayerList.ScrollBarImageColor3 = ACCENT
PlayerList.CanvasSize =
    UDim2.new(
        0,
        0,
        0,
        0
    )

PlayerList.Parent = ExcludePage

local PlayerListCorner =
    Instance.new("UICorner")

PlayerListCorner.CornerRadius =
    UDim.new(0, 9)

PlayerListCorner.Parent =
    PlayerList

local ListLayout =
    Instance.new("UIListLayout")

ListLayout.Padding =
    UDim.new(0, 5)

ListLayout.SortOrder =
    Enum.SortOrder.Name

ListLayout.Parent =
    PlayerList

--------------------------------------------------
-- UPDATE PLAYER LIST
--------------------------------------------------

local function UpdatePlayerList()

    for _, Child in ipairs(
        PlayerList:GetChildren()
    ) do

        if Child:IsA("TextButton") then
            Child:Destroy()
        end
    end

    local Count = 0

    local LowerSearch =
        string.lower(SearchText)

    for _, Player in ipairs(
        Players:GetPlayers()
    ) do

        if Player ~= LocalPlayer then

            local Name =
                string.lower(
                    Player.Name
                )

            local DisplayName =
                string.lower(
                    Player.DisplayName
                )

            local Match =
                LowerSearch == ""
                or
                string.find(
                    Name,
                    LowerSearch,
                    1,
                    true
                )
                or
                string.find(
                    DisplayName,
                    LowerSearch,
                    1,
                    true
                )

            if Match then

                Count += 1

                local Excluded =
                    IsExcluded(Player)

                local Button =
                    Instance.new("TextButton")

                Button.Size =
                    UDim2.new(
                        1,
                        -10,
                        0,
                        40
                    )

                Button.BackgroundColor3 =
                    Excluded
                    and
                    Color3.fromRGB(
                        80,
                        36,
                        45
                    )
                    or
                    PANEL2

                Button.BorderSizePixel = 0
                Button.AutoButtonColor = false

                Button.Text =
                    Excluded
                    and
                    "🚫  "
                    ..
                    Player.Name
                    ..
                    "   [EXCLUDED]"
                    or
                    "✓  "
                    ..
                    Player.Name

                Button.TextColor3 = TEXT
                Button.TextSize = 11
                Button.Font =
                    Enum.Font.GothamSemibold

                Button.TextXAlignment =
                    Enum.TextXAlignment.Left

                Button.Parent = PlayerList

                local Padding =
                    Instance.new("UIPadding")

                Padding.PaddingLeft =
                    UDim.new(0, 12)

                Padding.Parent = Button

                local Corner =
                    Instance.new("UICorner")

                Corner.CornerRadius =
                    UDim.new(0, 8)

                Corner.Parent = Button

                Button.MouseEnter:Connect(
                    function()

                        Tween(
                            Button,
                            {
                                BackgroundColor3 =
                                    IsExcluded(Player)
                                    and
                                    Color3.fromRGB(
                                        100,
                                        42,
                                        52
                                    )
                                    or
                                    PANEL3
                            },
                            TweenFast
                        )
                    end
                )

                Button.MouseLeave:Connect(
                    function()

                        Tween(
                            Button,
                            {
                                BackgroundColor3 =
                                    IsExcluded(Player)
                                    and
                                    Color3.fromRGB(
                                        80,
                                        36,
                                        45
                                    )
                                    or
                                    PANEL2
                            },
                            TweenFast
                        )
                    end
                )

                Button.MouseButton1Click:Connect(
                    function()

                        if ExcludedPlayers[Player] then

                            ExcludedPlayers[Player] =
                                nil

                        else

                            ExcludedPlayers[Player] =
                                true

                            if LockedTarget
                                and
                                Player.Character
                                and
                                LockedTarget:IsDescendantOf(
                                    Player.Character
                                ) then

                                LockedTarget = nil
                                Aiming = false
                            end
                        end

                        UpdatePlayerList()
                    end
                )
            end
        end
    end

    PlayerList.CanvasSize =
        UDim2.new(
            0,
            0,
            0,
            Count * 45 + 5
        )
end

SearchBox:GetPropertyChangedSignal(
    "Text"
):Connect(function()

    SearchText =
        SearchBox.Text

    UpdatePlayerList()
end)

SelectAllButton.MouseButton1Click:Connect(
    function()

        for _, Player in ipairs(
            Players:GetPlayers()
        ) do

            if Player ~= LocalPlayer then
                ExcludedPlayers[Player] = true
            end
        end

        LockedTarget = nil
        Aiming = false

        UpdatePlayerList()
    end
)

DeselectAllButton.MouseButton1Click:Connect(
    function()

        ExcludedPlayers = {}

        UpdatePlayerList()
    end
)

RefreshButton.MouseButton1Click:Connect(
    function()

        UpdatePlayerList()
    end
)

--------------------------------------------------
-- SETTINGS PAGE
--------------------------------------------------

CreateLabel(
    SettingsPage,
    "Settings",
    UDim2.new(0, 6, 0, 4),
    UDim2.new(1, -12, 0, 30),
    19
)

local SettingsSubtitle =
    CreateLabel(
        SettingsPage,
        "Interface configuration",
        UDim2.new(0, 6, 0, 34),
        UDim2.new(1, -12, 0, 22),
        11
    )

SettingsSubtitle.TextColor3 = MUTED

--------------------------------------------------
-- GUI KEY
--------------------------------------------------

local GUIKeyButton =
    CreateButton(
        SettingsPage,
        "GUI KEY: V",
        UDim2.new(0, 6, 0, 68),
        UDim2.new(1, -12, 0, 40)
    )

--------------------------------------------------
-- MINIMIZE KEY
--------------------------------------------------

local MinimizeKeyButton =
    CreateButton(
        SettingsPage,
        "MINIMIZE KEY: B",
        UDim2.new(0, 6, 0, 116),
        UDim2.new(1, -12, 0, 40)
    )

--------------------------------------------------
-- AIM-LOCK TOGGLE KEY
--------------------------------------------------

local AimToggleKeyButton =
    CreateButton(
        SettingsPage,
        "AIM-LOCK TOGGLE: NONE",
        UDim2.new(0, 6, 0, 164),
        UDim2.new(1, -12, 0, 40)
    )

--------------------------------------------------
-- ESP TOGGLE KEY
--------------------------------------------------

local ESPToggleKeyButton =
    CreateButton(
        SettingsPage,
        "ESP TOGGLE: NONE",
        UDim2.new(0, 6, 0, 212),
        UDim2.new(1, -12, 0, 40)
    )

--------------------------------------------------
-- GUI TRANSPARENCY
--------------------------------------------------

local TransparencyButton =
    CreateButton(
        SettingsPage,
        "GUI TRANSPARENCY: OFF",
        UDim2.new(0, 6, 0, 260),
        UDim2.new(1, -12, 0, 40)
    )

local TransparencyInfo =
    CreateLabel(
        SettingsPage,
        "50/60% transparency • Disabled while minimized",
        UDim2.new(0, 6, 0, 303),
        UDim2.new(1, -12, 0, 22),
        10
    )

TransparencyInfo.TextColor3 = MUTED

--------------------------------------------------
-- STATUS
--------------------------------------------------

local StatusLabel =
    CreateLabel(
        SettingsPage,
        "●  Script Status: ACTIVE",
        UDim2.new(0, 6, 0, 342),
        UDim2.new(1, -12, 0, 25),
        12
    )

StatusLabel.TextColor3 = GREEN

--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

local ShutdownButton =
    CreateButton(
        SettingsPage,
        "⏻  DESLIGAR SCRIPT",
        UDim2.new(0, 6, 0, 384),
        UDim2.new(1, -12, 0, 42)
    )

ShutdownButton.BackgroundColor3 =
    Color3.fromRGB(
        88,
        30,
        38
    )

ShutdownButton.MouseEnter:Connect(function()

    Tween(
        ShutdownButton,
        {
            BackgroundColor3 =
                Color3.fromRGB(
                    135,
                    38,
                    48
                )
        },
        TweenFast
    )
end)

ShutdownButton.MouseLeave:Connect(function()

    Tween(
        ShutdownButton,
        {
            BackgroundColor3 =
                Color3.fromRGB(
                    88,
                    30,
                    38
                )
        },
        TweenFast
    )
end)

--------------------------------------------------
-- CREDIT
--------------------------------------------------

local Credit =
    CreateLabel(
        SettingsPage,
        "Feito por: Gustavo Santos",
        UDim2.new(
            0,
            6,
            1,
            -38
        ),
        UDim2.new(
            1,
            -12,
            0,
            25
        ),
        10
    )

Credit.TextColor3 = MUTED

--------------------------------------------------
-- TRANSPARENCY
--------------------------------------------------

local function ApplyGUITransparency()

    if GUITransparent and not IsMinimized then

        -- Cerca de 55% transparente.
        -- O conteúdo continua relativamente legível.

        Main.BackgroundTransparency = 0.55
        Top.BackgroundTransparency = 0.55
        Sidebar.BackgroundTransparency = 0.55
        Content.BackgroundTransparency = 0.55

    else

        Main.BackgroundTransparency = 0
        Top.BackgroundTransparency = 0
        Sidebar.BackgroundTransparency = 0
        Content.BackgroundTransparency = 0
    end
end

TransparencyButton.MouseButton1Click:Connect(
    function()

        GUITransparent =
            not GUITransparent

        SetToggle(
            TransparencyButton,
            GUITransparent,
            "GUI TRANSPARENCY"
        )

        ApplyGUITransparency()
    end
)

--------------------------------------------------
-- MINI BUTTON
--------------------------------------------------

local MiniButton =
    Instance.new("TextButton")

MiniButton.Name =
    "MiniButton"

MiniButton.Size =
    UDim2.new(
        0,
        150,
        0,
        48
    )

MiniButton.Position =
    Main.Position

MiniButton.BackgroundColor3 = BG
MiniButton.BorderSizePixel = 0
MiniButton.AutoButtonColor = false

MiniButton.Text = "GUSTAVO HUB"
MiniButton.TextColor3 = TEXT
MiniButton.TextSize = 13
MiniButton.Font = Enum.Font.GothamBold

MiniButton.Visible = false
MiniButton.Parent = GUI

local MiniCorner =
    Instance.new("UICorner")

MiniCorner.CornerRadius =
    UDim.new(0, 12)

MiniCorner.Parent = MiniButton

local MiniStroke =
    Instance.new("UIStroke")

MiniStroke.Color = ACCENT
MiniStroke.Thickness = 1.5
MiniStroke.Parent = MiniButton

--------------------------------------------------
-- MINI DRAG
--------------------------------------------------

local MiniDragging = false
local MiniDragStart = nil
local MiniStartPosition = nil

MiniButton.InputBegan:Connect(function(Input)

    if Input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        MiniDragging = true

        MiniDragStart =
            Input.Position

        MiniStartPosition =
            MiniButton.Position

        local Connection

        Connection =
            Input.Changed:Connect(
                function()

                    if Input.UserInputState ==
                        Enum.UserInputState.End then

                        MiniDragging = false

                        if Connection then
                            Connection:Disconnect()
                        end
                    end
                end
            )
    end
end)

UserInputService.InputChanged:Connect(function(Input)

    if not MiniDragging then
        return
    end

    if Input.UserInputType ~=
        Enum.UserInputType.MouseMovement then
        return
    end

    if not MiniStartPosition
        or not MiniDragStart then
        return
    end

    local Delta =
        Input.Position -
        MiniDragStart

    local NewPosition =
        UDim2.new(
            MiniStartPosition.X.Scale,
            MiniStartPosition.X.Offset +
                Delta.X,
            MiniStartPosition.Y.Scale,
            MiniStartPosition.Y.Offset +
                Delta.Y
        )

    MiniButton.Position =
        NewPosition

    -- O GUI principal acompanha a posição
    -- enquanto o quadrado é movido.
    Main.Position =
        NewPosition
end)

MiniButton.MouseEnter:Connect(function()

    Tween(
        MiniButton,
        {
            BackgroundColor3 =
                Color3.fromRGB(
                    25,
                    28,
                    42
                )
        },
        TweenFast
    )
end)

MiniButton.MouseLeave:Connect(function()

    Tween(
        MiniButton,
        {
            BackgroundColor3 = BG
        },
        TweenFast
    )
end)

--------------------------------------------------
-- TABS
--------------------------------------------------

local TabButtons = {}

local function SelectTab(Tab)

    CurrentTab = Tab

    local Pages = {
        Aim = AimPage,
        ESP = ESPPage,
        Exclude = ExcludePage,
        Settings = SettingsPage
    }

    for Name, Page in pairs(Pages) do

        if Name == Tab then

            Page.Visible = true

            Page.Position =
                UDim2.new(
                    0,
                    18,
                    0,
                    12
                )

            Tween(
                Page,
                {
                    Position =
                        UDim2.new(
                            0,
                            12,
                            0,
                            12
                        )
                },
                TweenSmooth
            )

        else

            Page.Visible = false
        end
    end

    for Name, Data in pairs(TabButtons) do

        if Name == Tab then

            Data.Indicator.Visible = true

            Tween(
                Data.Button,
                {
                    BackgroundColor3 =
                        Color3.fromRGB(
                            29,
                            34,
                            52
                        ),
                    TextColor3 = TEXT
                },
                TweenFast
            )

        else

            Data.Indicator.Visible = false

            Tween(
                Data.Button,
                {
                    BackgroundColor3 = PANEL,
                    TextColor3 = MUTED
                },
                TweenFast
            )
        end
    end

    if Tab == "Exclude" then
        UpdatePlayerList()
    end
end

local function CreateTab(
    TextValue,
    Icon,
    Y,
    TabName
)

    local Button =
        Instance.new("TextButton")

    Button.Size =
        UDim2.new(
            1,
            -16,
            0,
            45
        )

    Button.Position =
        UDim2.new(
            0,
            8,
            0,
            Y
        )

    Button.BackgroundColor3 = PANEL
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false

    Button.Text =
        Icon ..
        "   " ..
        TextValue

    Button.TextColor3 = MUTED
    Button.TextSize = 11
    Button.Font = Enum.Font.GothamSemibold
    Button.TextXAlignment =
        Enum.TextXAlignment.Left

    Button.Parent = Sidebar

    local Padding =
        Instance.new("UIPadding")

    Padding.PaddingLeft =
        UDim.new(0, 12)

    Padding.Parent = Button

    local Corner =
        Instance.new("UICorner")

    Corner.CornerRadius =
        UDim.new(0, 9)

    Corner.Parent = Button

    local Indicator =
        Instance.new("Frame")

    Indicator.Size =
        UDim2.new(
            0,
            3,
            0,
            22
        )

    Indicator.Position =
        UDim2.new(
            0,
            0,
            0.5,
            -11
        )

    Indicator.BackgroundColor3 = ACCENT
    Indicator.BorderSizePixel = 0
    Indicator.Visible = false
    Indicator.Parent = Button

    local IndicatorCorner =
        Instance.new("UICorner")

    IndicatorCorner.CornerRadius =
        UDim.new(1, 0)

    IndicatorCorner.Parent = Indicator

    Button.MouseEnter:Connect(function()

        if CurrentTab ~= TabName then

            Tween(
                Button,
                {
                    BackgroundColor3 = PANEL2,
                    TextColor3 = TEXT
                },
                TweenFast
            )
        end
    end)

    Button.MouseLeave:Connect(function()

        if CurrentTab ~= TabName then

            Tween(
                Button,
                {
                    BackgroundColor3 = PANEL,
                    TextColor3 = MUTED
                },
                TweenFast
            )
        end
    end)

    Button.MouseButton1Click:Connect(
        function()
            SelectTab(TabName)
        end
    )

    TabButtons[TabName] = {
        Button = Button,
        Indicator = Indicator
    }

    return Button
end

CreateTab(
    "AIM-LOCK",
    "◈",
    45,
    "Aim"
)

CreateTab(
    "ESP",
    "◇",
    98,
    "ESP"
)

CreateTab(
    "EXCLUDE",
    "⊘",
    151,
    "Exclude"
)

CreateTab(
    "SETTINGS",
    "⚙",
    204,
    "Settings"
)

--------------------------------------------------
-- OPEN / CLOSE
--------------------------------------------------

local function OpenGUI()

    if IsGuiOpen or IsAnimating then
        return
    end

    IsAnimating = true
    IsGuiOpen = true

    MiniButton.Visible = false
    Main.Visible = true

    Main.Size =
        UDim2.new(
            0,
            470,
            0,
            570
        )

    ApplyGUITransparency()

    Tween(
        Main,
        {
            Size =
                UDim2.new(
                    0,
                    520,
                    0,
                    630
                )
        },
        TweenOpen
    )

    task.delay(
        0.3,
        function()
            IsAnimating = false
        end
    )
end

local function CloseGUI()

    if not IsGuiOpen or IsAnimating then
        return
    end

    IsAnimating = true

    Tween(
        Main,
        {
            Size =
                UDim2.new(
                    0,
                    470,
                    0,
                    570
                ),
            BackgroundTransparency = 1
        },
        TweenClose
    )

    task.delay(
        0.22,
        function()

            Main.Visible = false

            Main.Size =
                UDim2.new(
                    0,
                    520,
                    0,
                    630
                )

            ApplyGUITransparency()

            IsGuiOpen = false
            IsAnimating = false
        end
    )
end

local function ToggleGUI()

    if IsAnimating then
        return
    end

    if IsGuiOpen then
        CloseGUI()
    else
        OpenGUI()
    end
end

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

local NormalSize =
    UDim2.new(
        0,
        520,
        0,
        630
    )

local function MinimizeGUI()

    if IsMinimized
        or IsAnimating
        or not IsGuiOpen then
        return
    end

    IsAnimating = true
    IsMinimized = true

    -- Guarda exatamente a posição atual.
    local SavedPosition =
        Main.Position

    MiniButton.Position =
        SavedPosition

    -- O quadrado nunca fica transparente.
    MiniButton.BackgroundTransparency = 0

    Tween(
        Main,
        {
            Size =
                UDim2.new(
                    0,
                    170,
                    0,
                    55
                )
        },
        TweenSmooth
    )

    task.delay(
        0.24,
        function()

            Main.Visible = false

            MiniButton.Position =
                SavedPosition

            MiniButton.Size =
                UDim2.new(
                    0,
                    0,
                    0,
                    0
                )

            MiniButton.Visible = true

            Tween(
                MiniButton,
                {
                    Size =
                        UDim2.new(
                            0,
                            150,
                            0,
                            48
                        )
                },
                TweenSmooth
            )

            IsGuiOpen = false
            IsAnimating = false
        end
    )
end

local function RestoreFromMinimized()

    if not IsMinimized
        or IsAnimating then
        return
    end

    IsAnimating = true

    -- Mantém exatamente o local onde
    -- o quadrado foi deixado.
    Main.Position =
        MiniButton.Position

    Tween(
        MiniButton,
        {
            Size =
                UDim2.new(
                    0,
                    0,
                    0,
                    0
                )
        },
        TweenClose
    )

    task.delay(
        0.22,
        function()

            MiniButton.Visible = false

            Main.Visible = true

            Main.Size =
                UDim2.new(
                    0,
                    170,
                    0,
                    55
                )

            -- Sai do estado minimizado ANTES de reaplicar a
            -- transparência, porque ApplyGUITransparency não aplica
            -- transparência enquanto IsMinimized estiver true.
            IsMinimized = false
            IsGuiOpen = true

            ApplyGUITransparency()

            Tween(
                Main,
                {
                    Size = NormalSize
                },
                TweenOpen
            )

            task.delay(
                0.3,
                function()
                    IsAnimating = false
                end
            )
        end
    )
end

--------------------------------------------------
-- SETTINGS EVENTS
--------------------------------------------------

GUIKeyButton.MouseButton1Click:Connect(
    function()
        ChangingGuiKey = true
        ChangingAimKey = false
        ChangingAimToggleKey = false
        ChangingESPToggleKey = false
        ChangingMinimizeKey = false
        GUIKeyButton.Text = "GUI KEY: PRESS KEY..."
    end
)

MinimizeKeyButton.MouseButton1Click:Connect(
    function()
        ChangingMinimizeKey = true
        ChangingGuiKey = false
        ChangingAimKey = false
        ChangingAimToggleKey = false
        ChangingESPToggleKey = false
        MinimizeKeyButton.Text = "MINIMIZE KEY: PRESS KEY..."
    end
)

AimToggleKeyButton.MouseButton1Click:Connect(
    function()
        ChangingAimToggleKey = true
        ChangingESPToggleKey = false
        ChangingGuiKey = false
        ChangingAimKey = false
        ChangingMinimizeKey = false
        AimToggleKeyButton.Text = "AIM-LOCK TOGGLE: PRESS KEY..."
    end
)

ESPToggleKeyButton.MouseButton1Click:Connect(
    function()
        ChangingESPToggleKey = true
        ChangingAimToggleKey = false
        ChangingGuiKey = false
        ChangingAimKey = false
        ChangingMinimizeKey = false
        ESPToggleKeyButton.Text = "ESP TOGGLE: PRESS KEY..."
    end
)

--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

ShutdownButton.MouseButton1Click:Connect(
    function()

        ScriptEnabled = false
        AimEnabled = false
        Aiming = false
        LockedTarget = nil

        pcall(function()

            FOVCircle.Visible = false
            FOVCircle:Remove()

        end)

        for _, Data in pairs(
            ESPObjects
        ) do

            for _, Object in pairs(Data) do

                pcall(function()
                    Object:Remove()
                end)
            end
        end

        ESPObjects = {}

        pcall(function()
            GUI:Destroy()
        end)
    end
)

--------------------------------------------------
-- INPUT BEGAN
--------------------------------------------------

local function GetInputName(InputType, KeyCode)
    if InputType == Enum.UserInputType.MouseButton1 then return "LEFT CLICK" end
    if InputType == Enum.UserInputType.MouseButton2 then return "RIGHT CLICK" end
    if InputType == Enum.UserInputType.MouseButton3 then return "MIDDLE CLICK" end
    if InputType == Enum.UserInputType.MouseButton4 then return "MOUSE 4" end
    if InputType == Enum.UserInputType.MouseButton5 then return "MOUSE 5" end
    if KeyCode and KeyCode ~= Enum.KeyCode.Unknown then return KeyCode.Name end
    return "NONE"
end

local function IsMouseButton(InputType)
    return InputType == Enum.UserInputType.MouseButton1
        or InputType == Enum.UserInputType.MouseButton2
        or InputType == Enum.UserInputType.MouseButton3
        or InputType == Enum.UserInputType.MouseButton4
        or InputType == Enum.UserInputType.MouseButton5
end

local function CaptureKeybind(Input, Button, Label, SetKey, SetChanging)
    if Input.UserInputType == Enum.UserInputType.Keyboard then
        if Input.KeyCode == Enum.KeyCode.Backspace
            or Input.KeyCode == Enum.KeyCode.Delete then
            SetKey(nil)
            Button.Text = Label .. ": NONE"
            SetChanging(false)
            return true
        end

        if Input.KeyCode ~= Enum.KeyCode.Unknown then
            SetKey(Input.KeyCode)
            Button.Text = Label .. ": " .. GetInputName(nil, Input.KeyCode)
            SetChanging(false)
            return true
        end
    elseif IsMouseButton(Input.UserInputType) then
        SetKey(Input.UserInputType)
        Button.Text = Label .. ": " .. GetInputName(Input.UserInputType)
        SetChanging(false)
        return true
    end

    return false
end

UserInputService.InputBegan:Connect(
    function(Input, GameProcessed)
        --------------------------------------------------
        -- KEYBIND CAPTURE
        -- This intentionally runs BEFORE GameProcessed so
        -- mouse buttons and keyboard keys can be captured
        -- even when the input originated over the GUI.
        --------------------------------------------------

        if ChangingAimKey then
            if CaptureKeybind(
                Input,
                AimKeyButton,
                "AIM KEY",
                function(value) AimKey = value end,
                function(value) ChangingAimKey = value end
            ) then
                return
            end
        end

        if ChangingAimToggleKey then
            if CaptureKeybind(
                Input,
                AimToggleKeyButton,
                "AIM-LOCK TOGGLE",
                function(value) AimToggleKey = value end,
                function(value) ChangingAimToggleKey = value end
            ) then
                return
            end
        end

        if ChangingESPToggleKey then
            if CaptureKeybind(
                Input,
                ESPToggleKeyButton,
                "ESP TOGGLE",
                function(value) ESPToggleKey = value end,
                function(value) ChangingESPToggleKey = value end
            ) then
                return
            end
        end

        if ChangingGuiKey then
            if Input.UserInputType == Enum.UserInputType.Keyboard
                and Input.KeyCode ~= Enum.KeyCode.Unknown then
                GuiKey = Input.KeyCode
                GUIKeyButton.Text = "GUI KEY: " .. Input.KeyCode.Name
                ChangingGuiKey = false
                return
            end
        end

        if ChangingMinimizeKey then
            if Input.UserInputType == Enum.UserInputType.Keyboard
                and Input.KeyCode ~= Enum.KeyCode.Unknown then
                MinimizeKey = Input.KeyCode
                MinimizeKeyButton.Text = "MINIMIZE KEY: " .. Input.KeyCode.Name
                ChangingMinimizeKey = false
                return
            end
        end

        if GameProcessed then
            return
        end

        --------------------------------------------------
        -- GUI KEY
        --------------------------------------------------

        if Input.UserInputType == Enum.UserInputType.Keyboard
            and Input.KeyCode == GuiKey then
            if IsMinimized then
                RestoreFromMinimized()
            else
                ToggleGUI()
            end
            return
        end

        --------------------------------------------------
        -- MINIMIZE KEY
        --------------------------------------------------

        if Input.UserInputType == Enum.UserInputType.Keyboard
            and Input.KeyCode == MinimizeKey then
            if IsMinimized then
                RestoreFromMinimized()
            elseif IsGuiOpen then
                MinimizeGUI()
            end
            return
        end

        if not ScriptEnabled then
            return
        end

        --------------------------------------------------
        -- AIM-LOCK TOGGLE
        --------------------------------------------------

        local IsAimToggleInput =
            AimToggleKey ~= nil
            and (
                Input.UserInputType == AimToggleKey
                or Input.KeyCode == AimToggleKey
            )

        if IsAimToggleInput then
            AimEnabled = not AimEnabled

            if not AimEnabled then
                Aiming = false
                LockedTarget = nil
            end

            SetToggle(AimToggle, AimEnabled, "AIM-LOCK")
            return
        end

        --------------------------------------------------
        -- ESP TOGGLE
        --------------------------------------------------

        local IsESPToggleInput =
            ESPToggleKey ~= nil
            and (
                Input.UserInputType == ESPToggleKey
                or Input.KeyCode == ESPToggleKey
            )

        if IsESPToggleInput then
            ESPEnabled = not ESPEnabled
            SetToggle(ESPButton, ESPEnabled, "ESP BOX")
            return
        end

        --------------------------------------------------
        -- AIM HOLD
        --------------------------------------------------

        local IsAimInput =
            AimKey ~= nil
            and (
                Input.UserInputType == AimKey
                or Input.KeyCode == AimKey
            )

        if IsAimInput and AimEnabled then
            Aiming = true

            if not LockedTarget then
                LockedTarget = GetClosestTarget()
            end
        end
    end
)

--------------------------------------------------
-- INPUT ENDED
--------------------------------------------------

UserInputService.InputEnded:Connect(
    function(Input)
        local IsAimInput =
            AimKey ~= nil
            and (
                Input.UserInputType == AimKey
                or Input.KeyCode == AimKey
            )

        if IsAimInput then
            Aiming = false
            LockedTarget = nil
        end
    end
)
-- MAIN LOOP
--------------------------------------------------

RunService.RenderStepped:Connect(
    function()

        if not ScriptEnabled then
            return
        end

        --------------------------------------------------
        -- FOV
        --------------------------------------------------

        if FOVCircle then

            FOVCircle.Position =
                Vector2.new(
                    Camera.ViewportSize.X / 2,
                    Camera.ViewportSize.Y / 2
                )

            FOVCircle.Radius =
                FOVSize

            FOVCircle.Visible =
                FOVVisible
        end

        --------------------------------------------------
        -- ESP
        --------------------------------------------------

        UpdateESP()

        --------------------------------------------------
        -- AIM
        --------------------------------------------------

        if not AimEnabled
            or not Aiming then
            return
        end

        -- Se já temos um alvo, não procura outro
        -- só porque outro jogador passou à frente.
        if not LockedTarget then

            LockedTarget =
                GetClosestTarget()
        end

        if LockedTarget then

            local Character =
                LockedTarget.Parent

            local TargetPlayer =
                Character
                and
                Players:GetPlayerFromCharacter(
                    Character
                )

            local Humanoid =
                Character
                and
                Character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if TargetPlayer
                and Humanoid
                and Humanoid.Health > 0
                and IsAimEnemy(TargetPlayer)
                and LockedTarget.Parent then

                --------------------------------------------------
                -- AIM NORMAL / SMOOTH
                --------------------------------------------------

                local CameraPosition =
                    Camera.CFrame.Position

                local DesiredCFrame =
                    CFrame.new(
                        CameraPosition,
                        LockedTarget.Position
                    )

                if SmoothEnabled
                    and Smoothness > 0 then

                    -- Quanto maior o smoothness,
                    -- mais suave/lento fica o movimento.

                    local Alpha =
                        math.clamp(
                            0.08 +
                            (
                                1 -
                                Smoothness
                            ) * 0.32,
                            0.08,
                            0.40
                        )

                    Camera.CFrame =
                        Camera.CFrame:Lerp(
                            DesiredCFrame,
                            Alpha
                        )

                else

                    Camera.CFrame =
                        DesiredCFrame
                end

            else

                -- Se o alvo deixou de ser válido,
                -- fica sem alvo até encontrar outro
                -- enquanto o botão continuar pressionado.
                LockedTarget = nil

                if Aiming then

                    LockedTarget =
                        GetClosestTarget()
                end
            end
        end
    end
)

--------------------------------------------------
-- INITIALIZE ALL OPTIONS OFF
--------------------------------------------------

AimEnabled = false
Aiming = false
LockedTarget = nil

ESPEnabled = false
ESPName = false
ESPHealth = false
ESPDistance = false

FOVVisible = false

AimTeamCheck = false
ESPTeamCheck = false
WallCheck = false

SmoothEnabled = false
Smoothness = 0

GUITransparent = false

--------------------------------------------------
-- INITIAL BUTTON STATES
--------------------------------------------------

SetToggle(
    AimToggle,
    false,
    "AIM-LOCK"
)

SetToggle(
    FOVButton,
    false,
    "FOV CIRCLE"
)

SetToggle(
    AimTeamButton,
    false,
    "TEAM CHECK"
)

SetToggle(
    WallButton,
    false,
    "WALL CHECK"
)

SetToggle(
    ESPButton,
    false,
    "ESP BOX"
)

SetToggle(
    NameButton,
    false,
    "NAME"
)

SetToggle(
    HealthButton,
    false,
    "HEALTH"
)

SetToggle(
    DistanceButton,
    false,
    "DISTANCE"
)

SetToggle(
    ESPTeamButton,
    false,
    "TEAM CHECK"
)

SetToggle(
    TransparencyButton,
    false,
    "GUI TRANSPARENCY"
)

HeadButton:SetAttribute(
    "Active",
    true
)

BodyButton:SetAttribute(
    "Active",
    false
)

Tween(
    HeadButton,
    {
        BackgroundColor3 =
            ACCENT_DARK
    },
    TweenFast
)

Tween(
    BodyButton,
    {
        BackgroundColor3 =
            PANEL2
    },
    TweenFast
)

SmoothLabel.Text = "OFF"

--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

UpdatePlayerList()
SelectTab("Aim")
ApplyGUITransparency()

--------------------------------------------------
-- OPEN ANIMATION
--------------------------------------------------

Main.Size =
    UDim2.new(
        0,
        470,
        0,
        570
    )

Main.BackgroundTransparency = 1

Tween(
    Main,
    {
        Size =
            UDim2.new(
                0,
                520,
                0,
                630
            )
    },
    TweenOpen
)

task.delay(
    0.3,
    function()
        ApplyGUITransparency()
    end
)

--------------------------------------------------
-- STATUS ANIMATION
--------------------------------------------------

task.spawn(function()

    while ScriptEnabled
        and GUI.Parent do

        Tween(
            StatusDot,
            {
                BackgroundTransparency =
                    0.45
            },
            TweenInfo.new(
                0.8,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            )
        )

        task.wait(0.8)

        Tween(
            StatusDot,
            {
                BackgroundTransparency =
                    0
            },
            TweenInfo.new(
                0.8,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            )
        )

        task.wait(0.8)
    end
end)

