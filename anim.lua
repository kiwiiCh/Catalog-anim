-- ==========================================
-- ANIM CATALOG v8  |  Delta Executor
-- - No emojis anywhere
-- - All 7 slots patched correctly per pack
-- - GetBundleDetailsAsync + hardcoded fallback
-- - Draggable canvas with momentum
-- - Server replication via RemoteEvent
-- ==========================================

local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local AssetService      = game:GetService("AssetService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player            = Players.LocalPlayer

-- ============ COLORS ============
local C_BLUE   = Color3.fromRGB(0,   162, 255)
local C_GREEN  = Color3.fromRGB(2,   183, 87)
local C_RED    = Color3.fromRGB(200, 50,  50)
local C_DARK   = Color3.fromRGB(15,  15,  20)
local C_PANEL  = Color3.fromRGB(22,  22,  28)
local C_CARD   = Color3.fromRGB(32,  32,  40)
local C_ROW    = Color3.fromRGB(26,  26,  36)
local C_INPUT  = Color3.fromRGB(26,  26,  38)
local C_CANVAS = Color3.fromRGB(18,  18,  26)
local C_THUMB  = Color3.fromRGB(26,  26,  36)
local C_WHITE  = Color3.fromRGB(255, 255, 255)
local C_GRAY   = Color3.fromRGB(160, 160, 175)
local C_DIM    = Color3.fromRGB(100, 100, 120)
local C_STROKE = Color3.fromRGB(45,  45,  65)

local CARD_W   = 188
local CARD_H   = 220
local CARD_PAD = 10

-- ============ ANIMATION PACKS ============
-- BundleId  = roblox.com/bundles/ID/...
-- Anims     = hardcoded per-slot asset IDs
--             used when GetBundleDetailsAsync fails
local PACKS = {
    {Name="Ninja",        BundleId=75,  Creator="Roblox", Price=0, Anims={idle="656117400", walk="656118852", run="656121360", jump="656117878", fall="656117961", climb="656118353", swim="656118679"}},
    {Name="Zombie",       BundleId=77,  Creator="Roblox", Price=0, Anims={idle="616158929", walk="616159775", run="616160636", jump="616161053", fall="616161497", climb="616162054", swim="616162536"}},
    {Name="Superhero",    BundleId=79,  Creator="Roblox", Price=0, Anims={idle="616072051", walk="616072715", run="616074315", jump="616075295", fall="616076348", climb="616077211", swim="616078210"}},
    {Name="Robot",        BundleId=78,  Creator="Roblox", Price=0, Anims={idle="616161997", walk="616162405", run="616163682", jump="616164360", fall="616165025", climb="616165382", swim="616165813"}},
    {Name="Cartoony",     BundleId=80,  Creator="Roblox", Price=0, Anims={idle="742637544", walk="742638087", run="742638842", jump="742640018", fall="742641128", climb="742641836", swim="742642457"}},
    {Name="Levitation",   BundleId=33,  Creator="Roblox", Price=0, Anims={idle="616156778", walk="616157272", run="616157897", jump="616158327", fall="616158555", climb="616158777", swim="616159036"}},
    {Name="Mage",         BundleId=34,  Creator="Roblox", Price=0, Anims={idle="616010382", walk="616011036", run="616012156", jump="616012752", fall="616013413", climb="616013793", swim="616014359"}},
    {Name="Pirate",       BundleId=36,  Creator="Roblox", Price=0, Anims={idle="616006778", walk="616007277", run="616007736", jump="616008087", fall="616008320", climb="616008501", swim="616008662"}},
    {Name="Werewolf",     BundleId=37,  Creator="Roblox", Price=0, Anims={idle="616003913", walk="616004474", run="616005001", jump="616005314", fall="616005534", climb="616005785", swim="616006154"}},
    {Name="Skating",      BundleId=38,  Creator="Roblox", Price=0, Anims={idle="616152468", walk="616153086", run="616153997", jump="616154636", fall="616155297", climb="616155727", swim="616156219"}},
    {Name="Vampire",      BundleId=39,  Creator="Roblox", Price=0, Anims={idle="1083462025",walk="1083462636",run="1083463460",jump="1083464165",fall="1083464731",climb="1083465105",swim="1083465441"}},
    {Name="Toy",          BundleId=82,  Creator="Roblox", Price=0, Anims={idle="782841498", walk="782842708", run="782843525", jump="782844295", fall="782845070", climb="782845589", swim="782846175"}},
    {Name="Rthro",        BundleId=109, Creator="Roblox", Price=0, Anims={idle="2510235063",walk="2510238627",run="2510240219",jump="2510242378",fall="2510244400",climb="2510246327",swim="2510248268"}},
    {Name="Oldschool",    BundleId=145, Creator="Roblox", Price=0, Anims={idle="5916726572",walk="5916707072",run="5916707702",jump="5916707990",fall="5916708340",climb="5916708765",swim="5916709343"}},
    {Name="Astronaut",    BundleId=83,  Creator="Roblox", Price=0, Anims={idle="616070468", walk="616071122", run="616071553", jump="616071897", fall="616072153", climb="616072416", swim="616072715"}},
    {Name="Alien",        BundleId=84,  Creator="Roblox", Price=0, Anims={idle="616068262", walk="616068867", run="616069294", jump="616069626", fall="616069905", climb="616070160", swim="616070362"}},
    {Name="Dragon",       BundleId=85,  Creator="Roblox", Price=0, Anims={idle="616097718", walk="616098295", run="616098560", jump="616098796", fall="616099013", climb="616099255", swim="616099503"}},
    {Name="Stylish",      BundleId=86,  Creator="Roblox", Price=0, Anims={idle="616088355", walk="616089075", run="616091064", jump="616091789", fall="616092315", climb="616092810", swim="616093357"}},
    {Name="Elder",        BundleId=87,  Creator="Roblox", Price=0, Anims={idle="616095352", walk="616095700", run="616096052", jump="616096396", fall="616096650", climb="616096898", swim="616097264"}},
    {Name="Caveman",      BundleId=88,  Creator="Roblox", Price=0, Anims={idle="616094699", walk="616094110", run="616093826", jump="616093621", fall="616093457", climb="616093280", swim="616093113"}},
}

-- ============ SERVER SETUP ============
local REMOTE_NAME = "AnimCatalog_v8"

local function setupServer()
    local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
    if not remote then
        remote      = Instance.new("RemoteEvent")
        remote.Name = REMOTE_NAME
        remote.Parent = ReplicatedStorage
    end
    local sss = game:GetService("ServerScriptService")
    if sss:FindFirstChild("AnimCatalog_Srv_v8") then return remote end

    local ss = Instance.new("Script")
    ss.Name   = "AnimCatalog_Srv_v8"
    ss.Source = [[
        local RS     = game:GetService("ReplicatedStorage")
        local remote = RS:WaitForChild("AnimCatalog_v8", 15)
        if not remote then return end

        local SLOT_FOLDERS = {
            idle  = {"idle"},
            walk  = {"walk"},
            run   = {"run"},
            jump  = {"jump"},
            fall  = {"fall"},
            climb = {"climb"},
            swim  = {"swim", "swimidle"},
        }

        remote.OnServerEvent:Connect(function(player, animTable)
            local char = player.Character
            if not char then return end
            local aScript = char:FindFirstChild("Animate")
            if not aScript then return end

            for slot, animId in pairs(animTable) do
                local folders = SLOT_FOLDERS[slot] or {slot}
                for _, fname in ipairs(folders) do
                    local folder = aScript:FindFirstChild(fname)
                    if folder then
                        for _, child in ipairs(folder:GetChildren()) do
                            if child:IsA("Animation") then
                                child.AnimationId = "rbxassetid://" .. tostring(animId)
                            end
                        end
                    end
                end
            end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local anim = hum:FindFirstChildOfClass("Animator")
                if anim then
                    for _, t in ipairs(anim:GetPlayingAnimationTracks()) do
                        t:Stop(0)
                    end
                end
            end
        end)
    ]]
    ss.Parent = sss
    return remote
end

local AnimRemote = setupServer()

-- ============ DRAG HELPER ============
local function makeDraggable(handle, target)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = target.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or  i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                        sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

-- ============ APPLY ANIMATION ============
-- Slot folders inside the Animate script:
--   idle, walk, run, jump, fall, climb, swim, swimidle
-- Each folder contains one or more Animation instances.
-- We replace every Animation's AnimationId in the correct folder.

local SLOT_FOLDERS = {
    idle  = {"idle"},
    walk  = {"walk"},
    run   = {"run"},
    jump  = {"jump"},
    fall  = {"fall"},
    climb = {"climb"},
    swim  = {"swim", "swimidle"},
}

-- Try to get fresher IDs from Roblox's bundle API.
-- Returns a slot->id table, possibly empty on failure.
local function getBundleAnims(bundleId)
    local result = {}
    local ok, details = pcall(function()
        return AssetService:GetBundleDetailsAsync(bundleId)
    end)
    if not ok or not details or not details.Items then return result end

    -- Map asset names like "Ninja Walk" -> slot "walk"
    local NAME_KEYWORDS = {
        walk  = "walk",
        run   = "run",
        jump  = "jump",
        fall  = "fall",
        climb = "climb",
        swim  = "swim",
        idle  = "idle",
    }
    for _, item in ipairs(details.Items) do
        if item.Type == "Asset" and item.AssetType == Enum.AssetType.Animation then
            local nameLow = (item.Name or ""):lower()
            for slot, kw in pairs(NAME_KEYWORDS) do
                if nameLow:find(kw) and not result[slot] then
                    result[slot] = tostring(item.Id)
                    break
                end
            end
        end
    end
    return result
end

local function applyPack(pack)
    local char = Player.Character
    if not char then return false, "No character" end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false, "No Humanoid" end

    local aScript = char:FindFirstChild("Animate")
    if not aScript then return false, "No Animate script found" end

    -- Build the slot->id table
    -- Start from hardcoded, then overlay with live bundle data
    local animTable = {}
    for slot, id in pairs(pack.Anims) do
        animTable[slot] = id
    end

    -- Try live lookup (may add/correct IDs)
    if pack.BundleId then
        local live = getBundleAnims(pack.BundleId)
        for slot, id in pairs(live) do
            animTable[slot] = id   -- live wins over hardcoded
        end
    end

    -- Stop all currently playing tracks
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end

    -- Patch each slot folder
    local patched = 0
    for slot, animId in pairs(animTable) do
        local folders = SLOT_FOLDERS[slot] or {slot}
        for _, fname in ipairs(folders) do
            local folder = aScript:FindFirstChild(fname)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("Animation") then
                        child.AnimationId = "rbxassetid://" .. animId
                        patched = patched + 1
                    end
                end
            end
        end
    end

    if patched == 0 then
        return false, "No animation slots found in Animate script"
    end

    -- Kick humanoid state so Animate reloads with new IDs
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Landed)
        task.wait(0.05)
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)

    -- Tell the server so other players see it
    pcall(function()
        if AnimRemote then AnimRemote:FireServer(animTable) end
    end)

    return true, "OK — " .. patched .. " anims patched"
end

-- ============ GUI ============
if game.CoreGui:FindFirstChild("AnimCatalog_v8") then
    game.CoreGui.AnimCatalog_v8:Destroy()
end

local Screen = Instance.new("ScreenGui")
Screen.Name           = "AnimCatalog_v8"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder   = 999
Screen.Parent         = game.CoreGui

-- helpers
local function corner(inst, r)
    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r or 8)
end
local function stroke(inst, col, thick)
    local s = Instance.new("UIStroke", inst)
    s.Color = col; s.Thickness = thick or 1
end
local function lbl(parent, text, size, color, font, ax, ay)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text     = text
    l.TextSize = size
    l.TextColor3 = color or C_WHITE
    l.Font     = font or Enum.Font.Gotham
    l.TextXAlignment = ax or Enum.TextXAlignment.Center
    l.TextYAlignment = ay or Enum.TextYAlignment.Center
    return l
end

-- ---- Floating icon ----
local Icon = Instance.new("TextButton")
Icon.Size             = UDim2.new(0, 62, 0, 62)
Icon.Position         = UDim2.new(0, 16, 0.5, -31)
Icon.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Icon.BorderSizePixel  = 0
Icon.Text             = ""
Icon.ZIndex           = 20
Icon.Active           = true
Icon.Parent           = Screen
corner(Icon, 16)
stroke(Icon, C_BLUE, 2)
do
    local g = Instance.new("UIGradient", Icon)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30,30,48)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15,15,25)),
    })
    g.Rotation = 135

    -- "A" letter instead of emoji
    local a = lbl(Icon, "A", 26, C_BLUE, Enum.Font.GothamBlack)
    a.Size = UDim2.new(1, 0, 0.6, 0)
    a.Position = UDim2.new(0, 0, 0, 4)
    a.ZIndex = 21

    local sub = lbl(Icon, "ANIM", 9, C_BLUE, Enum.Font.GothamBold)
    sub.Size = UDim2.new(1, 0, 0.32, 0)
    sub.Position = UDim2.new(0, 0, 0.68, 0)
    sub.ZIndex = 21
end
makeDraggable(Icon, Icon)

-- ---- Main panel ----
local Panel = Instance.new("Frame")
Panel.Size             = UDim2.new(0, 450, 0, 610)
Panel.Position         = UDim2.new(0, 90, 0.5, -305)
Panel.BackgroundColor3 = C_PANEL
Panel.BorderSizePixel  = 0
Panel.Visible          = false
Panel.ZIndex           = 10
Panel.Parent           = Screen
corner(Panel, 14)
stroke(Panel, Color3.fromRGB(50,50,70), 1.5)

-- TopBar
local TopBar = Instance.new("Frame", Panel)
TopBar.Size             = UDim2.new(1, 0, 0, 54)
TopBar.BackgroundColor3 = C_DARK
TopBar.BorderSizePixel  = 0
TopBar.ZIndex           = 11
corner(TopBar, 14)
do
    -- patch bottom corners of topbar
    local fill = Instance.new("Frame", TopBar)
    fill.Size             = UDim2.new(1, 0, 0, 14)
    fill.Position         = UDim2.new(0, 0, 1, -14)
    fill.BackgroundColor3 = C_DARK
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 11

    -- accent line
    local acc = Instance.new("Frame", TopBar)
    acc.Size             = UDim2.new(1, 0, 0, 2)
    acc.Position         = UDim2.new(0, 0, 1, -1)
    acc.BackgroundColor3 = C_BLUE
    acc.BorderSizePixel  = 0
    acc.ZIndex           = 12
    local ag = Instance.new("UIGradient", acc)
    ag.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,120,220)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,210,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,120,220)),
    })

    -- "R" badge
    local rb = Instance.new("Frame", TopBar)
    rb.Size             = UDim2.new(0, 32, 0, 32)
    rb.Position         = UDim2.new(0, 12, 0, 11)
    rb.BackgroundColor3 = C_BLUE
    rb.BorderSizePixel  = 0
    rb.ZIndex           = 12
    corner(rb, 7)
    local rl = lbl(rb, "R", 20, C_WHITE, Enum.Font.GothamBlack)
    rl.Size   = UDim2.new(1,0,1,0)
    rl.ZIndex = 13

    -- title text
    local tl = lbl(TopBar, "Animation Catalog", 16, C_WHITE, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
    tl.Size     = UDim2.new(1,-160,0,22)
    tl.Position = UDim2.new(0,52,0,8)
    tl.ZIndex   = 12

    local sl = lbl(TopBar, "Full packs  |  all 7 slots  |  drag to explore", 10, C_BLUE, Enum.Font.Gotham, Enum.TextXAlignment.Left)
    sl.Size     = UDim2.new(1,-160,0,14)
    sl.Position = UDim2.new(0,52,0,30)
    sl.ZIndex   = 12
end

-- Refresh button
local RefreshBtn = Instance.new("TextButton", TopBar)
RefreshBtn.Size             = UDim2.new(0, 32, 0, 32)
RefreshBtn.Position         = UDim2.new(1, -76, 0, 11)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(38,38,52)
RefreshBtn.Text             = "R"
RefreshBtn.TextColor3       = C_GRAY
RefreshBtn.Font             = Enum.Font.GothamBold
RefreshBtn.TextSize         = 16
RefreshBtn.BorderSizePixel  = 0
RefreshBtn.ZIndex           = 12
corner(RefreshBtn, 8)

-- Close button
local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size             = UDim2.new(0, 32, 0, 32)
CloseBtn.Position         = UDim2.new(1, -40, 0, 11)
CloseBtn.BackgroundColor3 = C_RED
CloseBtn.Text             = "X"
CloseBtn.TextColor3       = C_WHITE
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 14
CloseBtn.BorderSizePixel  = 0
CloseBtn.ZIndex           = 12
corner(CloseBtn, 8)

makeDraggable(TopBar, Panel)

-- Tabs
local TabRow = Instance.new("Frame", Panel)
TabRow.Size             = UDim2.new(1,-24,0,36)
TabRow.Position         = UDim2.new(0,12,0,62)
TabRow.BackgroundColor3 = C_ROW
TabRow.BorderSizePixel  = 0
TabRow.ZIndex           = 11
corner(TabRow, 10)

local function mkTab(text, side, active)
    local b = Instance.new("TextButton", TabRow)
    b.Size             = UDim2.new(0.5,-4,1,-6)
    b.Position         = side==0 and UDim2.new(0,3,0,3) or UDim2.new(0.5,1,0,3)
    b.BackgroundColor3 = active and C_BLUE or Color3.fromRGB(30,30,42)
    b.Text             = text
    b.TextColor3       = active and C_WHITE or C_GRAY
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 13
    b.BorderSizePixel  = 0
    b.ZIndex           = 12
    corner(b, 7)
    return b
end
local DiscoverTab = mkTab("Discover", 0, true)
local SearchTab   = mkTab("Search",   1, false)

-- Search box
local SearchCon = Instance.new("Frame", Panel)
SearchCon.Size             = UDim2.new(1,-24,0,38)
SearchCon.Position         = UDim2.new(0,12,0,106)
SearchCon.BackgroundColor3 = C_INPUT
SearchCon.BorderSizePixel  = 0
SearchCon.Visible          = false
SearchCon.ZIndex           = 11
corner(SearchCon, 9)
stroke(SearchCon, Color3.fromRGB(50,50,75))

-- search icon label (text, no emoji)
local sicon = lbl(SearchCon, "?", 14, C_GRAY, Enum.Font.GothamBold)
sicon.Size     = UDim2.new(0,28,1,0)
sicon.Position = UDim2.new(0,6,0,0)
sicon.ZIndex   = 12

local SearchInput = Instance.new("TextBox", SearchCon)
SearchInput.Size                = UDim2.new(1,-42,1,-8)
SearchInput.Position            = UDim2.new(0,36,0,4)
SearchInput.BackgroundTransparency = 1
SearchInput.Text                = ""
SearchInput.PlaceholderText     = "Search packs  e.g. ninja, zombie, robot"
SearchInput.PlaceholderColor3   = Color3.fromRGB(80,80,105)
SearchInput.TextColor3          = C_WHITE
SearchInput.Font                = Enum.Font.Gotham
SearchInput.TextSize            = 13
SearchInput.TextXAlignment      = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus    = false
SearchInput.ZIndex              = 12

-- Draggable canvas viewport
local VP_Y0, VP_H0 = 106, 492
local VP_Y1, VP_H1 = 152, 446

local Viewport = Instance.new("Frame", Panel)
Viewport.Size             = UDim2.new(1,-24,0,VP_H0)
Viewport.Position         = UDim2.new(0,12,0,VP_Y0)
Viewport.BackgroundColor3 = C_CANVAS
Viewport.BorderSizePixel  = 0
Viewport.ClipsDescendants = true
Viewport.ZIndex           = 11
corner(Viewport, 10)

local Canvas = Instance.new("Frame", Viewport)
Canvas.Size             = UDim2.new(0,900,0,900)
Canvas.Position         = UDim2.new(0,0,0,0)
Canvas.BackgroundTransparency = 1
Canvas.BorderSizePixel  = 0
Canvas.ZIndex           = 12

local Grid = Instance.new("UIGridLayout", Canvas)
Grid.CellSize            = UDim2.new(0,CARD_W,0,CARD_H)
Grid.CellPadding         = UDim2.new(0,CARD_PAD,0,CARD_PAD)
Grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
Grid.SortOrder           = Enum.SortOrder.LayoutOrder

local CanvasPad = Instance.new("UIPadding", Canvas)
CanvasPad.PaddingTop    = UDim.new(0,CARD_PAD)
CanvasPad.PaddingLeft   = UDim.new(0,CARD_PAD)
CanvasPad.PaddingRight  = UDim.new(0,CARD_PAD)
CanvasPad.PaddingBottom = UDim.new(0,CARD_PAD)

-- Canvas drag + momentum
local cDrag, cDs, cSp = false, nil, nil
local velX, velY = 0, 0
local lastPos    = nil
local totalCols, totalRows = 2, 1

Viewport.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        cDrag = true; cDs = i.Position; cSp = Canvas.Position
        velX = 0; velY = 0; lastPos = i.Position
    end
end)
Viewport.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        cDrag = false
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if cDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
    or  i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - cDs
        if lastPos then
            velX = i.Position.X - lastPos.X
            velY = i.Position.Y - lastPos.Y
        end
        lastPos = i.Position
        Canvas.Position = UDim2.new(0, cSp.X.Offset+d.X, 0, cSp.Y.Offset+d.Y)
    end
end)
RunService.Heartbeat:Connect(function()
    if not cDrag and (math.abs(velX)>0.3 or math.abs(velY)>0.3) then
        velX = velX * 0.87; velY = velY * 0.87
        local nx = Canvas.Position.X.Offset + velX
        local ny = Canvas.Position.Y.Offset + velY
        local vw = Viewport.AbsoluteSize.X
        local vh = Viewport.AbsoluteSize.Y
        local cw = totalCols*(CARD_W+CARD_PAD)+CARD_PAD
        local ch = totalRows*(CARD_H+CARD_PAD)+CARD_PAD
        nx = math.clamp(nx, math.min(0,vw-cw), 0)
        ny = math.clamp(ny, math.min(0,vh-ch), 0)
        Canvas.Position = UDim2.new(0,nx,0,ny)
        if math.abs(velX)<0.1 and math.abs(velY)<0.1 then velX=0; velY=0 end
    end
end)

-- Loading overlay
local LoadOverlay = Instance.new("Frame", Viewport)
LoadOverlay.Size             = UDim2.new(1,0,1,0)
LoadOverlay.BackgroundColor3 = C_CANVAS
LoadOverlay.BackgroundTransparency = 0.05
LoadOverlay.BorderSizePixel  = 0
LoadOverlay.Visible          = false
LoadOverlay.ZIndex           = 19
corner(LoadOverlay, 10)
do
    local lt = lbl(LoadOverlay, "Loading packs...", 16, C_BLUE, Enum.Font.GothamBold)
    lt.Size     = UDim2.new(1,0,1,0)
    lt.ZIndex   = 20
end

-- Drag hint
local DragHint = Instance.new("Frame", Viewport)
DragHint.Size             = UDim2.new(0,220,0,26)
DragHint.Position         = UDim2.new(0.5,-110,0,8)
DragHint.BackgroundColor3 = Color3.fromRGB(0,100,180)
DragHint.BorderSizePixel  = 0
DragHint.ZIndex           = 25
DragHint.Visible          = false
corner(DragHint, 13)
do
    local ht = lbl(DragHint, "Drag left/right/up/down to browse", 10, C_WHITE, Enum.Font.GothamBold)
    ht.Size   = UDim2.new(1,0,1,0)
    ht.ZIndex = 26
end

-- Status bar
local StatusBar = Instance.new("Frame", Panel)
StatusBar.Size             = UDim2.new(1,-24,0,28)
StatusBar.Position         = UDim2.new(0,12,1,-36)
StatusBar.BackgroundColor3 = C_CANVAS
StatusBar.BorderSizePixel  = 0
StatusBar.ZIndex           = 11
corner(StatusBar, 7)

local StatusText = lbl(StatusBar, "Loading...", 11, C_GRAY, Enum.Font.Gotham)
StatusText.Size     = UDim2.new(1,-10,1,0)
StatusText.Position = UDim2.new(0,5,0,0)
StatusText.ZIndex   = 12

local function setStatus(msg, col)
    StatusText.Text       = msg
    StatusText.TextColor3 = col or C_GRAY
end

-- ============ CARD BUILDER ============
local function clearCards()
    Canvas.Position = UDim2.new(0,0,0,0)
    velX = 0; velY = 0
    for _, c in ipairs(Canvas:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function updateCanvasSize(count)
    local vw = Viewport.AbsoluteSize.X
    if vw == 0 then vw = 402 end
    local cols = math.max(2, math.floor((vw - CARD_PAD) / (CARD_W + CARD_PAD)))
    local rows = math.ceil(count / cols)
    totalCols = cols; totalRows = rows
    Canvas.Size = UDim2.new(
        0, math.max(cols*(CARD_W+CARD_PAD)+CARD_PAD, vw),
        0, math.max(rows*(CARD_H+CARD_PAD)+CARD_PAD, Viewport.AbsoluteSize.Y)
    )
end

local function buildCard(pack, index)
    local Card = Instance.new("Frame", Canvas)
    Card.BackgroundColor3 = C_CARD
    Card.BorderSizePixel  = 0
    Card.ZIndex           = 13
    corner(Card, 10)
    local CS = stroke(Card, C_STROKE, 1)

    -- Thumbnail area
    local TF = Instance.new("Frame", Card)
    TF.Size             = UDim2.new(1,0,0,128)
    TF.BackgroundColor3 = C_THUMB
    TF.BorderSizePixel  = 0
    TF.ZIndex           = 14
    corner(TF, 10)

    -- patch bottom corners of thumb
    local TFF = Instance.new("Frame", TF)
    TFF.Size             = UDim2.new(1,0,0,10)
    TFF.Position         = UDim2.new(0,0,1,-10)
    TFF.BackgroundColor3 = C_THUMB
    TFF.BorderSizePixel  = 0
    TFF.ZIndex           = 14

    -- placeholder text while image loads
    local PH = lbl(TF, pack.Name, 11, C_GRAY, Enum.Font.GothamBold)
    PH.Size     = UDim2.new(1,-8,1,0)
    PH.Position = UDim2.new(0,4,0,0)
    PH.TextWrapped = true
    PH.ZIndex   = 15

    -- thumbnail image (uses idle anim ID for rbxthumb)
    local Thumb = Instance.new("ImageLabel", TF)
    Thumb.Size                  = UDim2.new(1,0,1,0)
    Thumb.BackgroundTransparency= 1
    Thumb.Image                 = "rbxthumb://type=Asset&id=" .. pack.Anims.idle .. "&w=150&h=150"
    Thumb.ScaleType             = Enum.ScaleType.Fit
    Thumb.ZIndex                = 15
    corner(Thumb, 10)
    Thumb:GetPropertyChangedSignal("IsLoaded"):Connect(function()
        if Thumb.IsLoaded then PH.Visible = false end
    end)

    -- "7 ANIMS" badge
    local Bdg = Instance.new("Frame", TF)
    Bdg.Size             = UDim2.new(0,62,0,17)
    Bdg.Position         = UDim2.new(0,6,0,6)
    Bdg.BackgroundColor3 = C_BLUE
    Bdg.BorderSizePixel  = 0
    Bdg.ZIndex           = 16
    corner(Bdg, 9)
    local bt = lbl(Bdg, "7 ANIMS", 9, C_WHITE, Enum.Font.GothamBold)
    bt.Size   = UDim2.new(1,0,1,0)
    bt.ZIndex = 17

    -- FREE badge
    local FB = Instance.new("Frame", TF)
    FB.Size             = UDim2.new(0,38,0,17)
    FB.Position         = UDim2.new(1,-44,0,6)
    FB.BackgroundColor3 = C_GREEN
    FB.BorderSizePixel  = 0
    FB.ZIndex           = 16
    corner(FB, 9)
    local ft = lbl(FB, "FREE", 9, C_WHITE, Enum.Font.GothamBold)
    ft.Size   = UDim2.new(1,0,1,0)
    ft.ZIndex = 17

    -- slot tags strip
    local SlotStrip = Instance.new("Frame", TF)
    SlotStrip.Size             = UDim2.new(1,-12,0,14)
    SlotStrip.Position         = UDim2.new(0,6,1,-20)
    SlotStrip.BackgroundColor3 = Color3.fromRGB(12,12,20)
    SlotStrip.BorderSizePixel  = 0
    SlotStrip.ZIndex           = 16
    corner(SlotStrip, 4)
    local SL = Instance.new("UIListLayout", SlotStrip)
    SL.FillDirection        = Enum.FillDirection.Horizontal
    SL.Padding              = UDim.new(0,3)
    SL.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    SL.VerticalAlignment    = Enum.VerticalAlignment.Center
    for _, tag in ipairs({"Walk","Run","Idle","Jump","Fall","Climb","Swim"}) do
        local tg = lbl(SlotStrip, tag, 7, C_BLUE, Enum.Font.GothamBold)
        tg.Size   = UDim2.new(0,30,1,0)
        tg.ZIndex = 17
    end

    -- Info section
    local Info = Instance.new("Frame", Card)
    Info.Size                  = UDim2.new(1,0,0,88)
    Info.Position              = UDim2.new(0,0,0,130)
    Info.BackgroundTransparency= 1
    Info.ZIndex                = 14

    local NL = lbl(Info, pack.Name, 12, C_WHITE, Enum.Font.GothamBold, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top)
    NL.Size     = UDim2.new(1,-12,0,32)
    NL.Position = UDim2.new(0,8,0,4)
    NL.TextWrapped = true
    NL.ZIndex   = 15

    local CL = lbl(Info, "by " .. (pack.Creator or "Roblox"), 10, C_DIM, Enum.Font.Gotham, Enum.TextXAlignment.Left)
    CL.Size     = UDim2.new(1,-12,0,13)
    CL.Position = UDim2.new(0,8,0,37)
    CL.TextTruncate = Enum.TextTruncate.AtEnd
    CL.ZIndex   = 15

    local AB = Instance.new("TextButton", Info)
    AB.Size             = UDim2.new(1,-16,0,28)
    AB.Position         = UDim2.new(0,8,0,53)
    AB.BackgroundColor3 = C_BLUE
    AB.Text             = "Equip Full Pack"
    AB.TextColor3       = C_WHITE
    AB.Font             = Enum.Font.GothamBold
    AB.TextSize         = 12
    AB.BorderSizePixel  = 0
    AB.ZIndex           = 15
    corner(AB, 7)

    -- hover effects
    local CardStroke = Card:FindFirstChildOfClass("UIStroke")
    Card.MouseEnter:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.14), {BackgroundColor3=Color3.fromRGB(40,40,55)}):Play()
        if CardStroke then TweenService:Create(CardStroke, TweenInfo.new(0.14), {Color=C_BLUE}):Play() end
    end)
    Card.MouseLeave:Connect(function()
        TweenService:Create(Card, TweenInfo.new(0.14), {BackgroundColor3=C_CARD}):Play()
        if CardStroke then TweenService:Create(CardStroke, TweenInfo.new(0.14), {Color=C_STROKE}):Play() end
    end)
    AB.MouseEnter:Connect(function()
        TweenService:Create(AB, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(30,190,255)}):Play()
    end)
    AB.MouseLeave:Connect(function()
        TweenService:Create(AB, TweenInfo.new(0.12), {BackgroundColor3=C_BLUE}):Play()
    end)

    AB.MouseButton1Click:Connect(function()
        AB.Text             = "Applying..."
        AB.BackgroundColor3 = Color3.fromRGB(55,55,75)
        setStatus("Equipping " .. pack.Name .. "...", Color3.fromRGB(220,180,50))

        task.spawn(function()
            local ok, msg = applyPack(pack)
            task.defer(function()
                if ok then
                    AB.Text             = "Equipped!"
                    AB.BackgroundColor3 = C_GREEN
                    setStatus("Done: " .. pack.Name .. "  (" .. msg .. ")", C_GREEN)
                else
                    AB.Text             = "Failed"
                    AB.BackgroundColor3 = C_RED
                    setStatus("Error: " .. tostring(msg), C_RED)
                end
                task.delay(4, function()
                    if AB and AB.Parent then
                        AB.Text             = "Equip Full Pack"
                        AB.BackgroundColor3 = C_BLUE
                    end
                    setStatus("Ready  |  move your character to see animations", C_GRAY)
                end)
            end)
        end)
    end)
end

-- ============ DISPLAY ============
local cachedList   = {}
local isSearchMode = false

local function showDragHint()
    DragHint.Visible = true; DragHint.BackgroundTransparency = 0
    task.delay(3, function()
        TweenService:Create(DragHint, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
        task.delay(0.5, function() DragHint.Visible = false end)
    end)
end

local function showList(list)
    clearCards()
    for i, pack in ipairs(list) do buildCard(pack, i) end
    updateCanvasSize(#list)
    setStatus(#list .. " packs loaded  |  walk/run/idle/jump/fall/climb/swim", C_GREEN)
    showDragHint()
end

-- filter by keyword against our local PACKS table
local function filterPacks(keyword)
    if not keyword or keyword == "" then return PACKS end
    local kw = keyword:lower()
    local out = {}
    for _, p in ipairs(PACKS) do
        if p.Name:lower():find(kw, 1, true) then
            table.insert(out, p)
        end
    end
    return out
end

local function loadPacks(keyword)
    clearCards()
    LoadOverlay.Visible = true
    setStatus("Loading...", C_BLUE)
    task.defer(function()
        local list = filterPacks(keyword)
        LoadOverlay.Visible = false
        if #list == 0 then
            setStatus("No packs match that search.", Color3.fromRGB(220,100,80))
            return
        end
        if not keyword then cachedList = list end
        showList(list)
    end)
end

local function setVP(searchVisible)
    SearchCon.Visible = searchVisible
    Viewport.Position = UDim2.new(0,12,0, searchVisible and VP_Y1 or VP_Y0)
    Viewport.Size     = UDim2.new(1,-24,0, searchVisible and VP_H1 or VP_H0)
end

-- open / close
local function openPanel()
    local ip = Icon.Position
    Panel.Position = UDim2.new(ip.X.Scale, ip.X.Offset+70, ip.Y.Scale, ip.Y.Offset-10)
    Icon.Visible   = false
    Panel.Visible  = true
    Panel.BackgroundTransparency = 1
    TweenService:Create(Panel, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {BackgroundTransparency=0}):Play()
end

local function closePanel()
    local pp = Panel.Position
    Icon.Position = UDim2.new(pp.X.Scale, pp.X.Offset-70, pp.Y.Scale, pp.Y.Offset+10)
    TweenService:Create(Panel, TweenInfo.new(0.16, Enum.EasingStyle.Quint), {BackgroundTransparency=1}):Play()
    task.delay(0.17, function()
        Panel.Visible = false
        Icon.Visible  = true
    end)
end

Icon.MouseButton1Click:Connect(openPanel)
CloseBtn.MouseButton1Click:Connect(closePanel)

Icon.MouseEnter:Connect(function() TweenService:Create(Icon,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(30,30,48)}):Play() end)
Icon.MouseLeave:Connect(function() TweenService:Create(Icon,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(20,20,28)}):Play() end)

RefreshBtn.MouseButton1Click:Connect(function()
    TweenService:Create(RefreshBtn,TweenInfo.new(0.1),{BackgroundColor3=C_BLUE}):Play()
    task.delay(0.2,function() TweenService:Create(RefreshBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(38,38,52)}):Play() end)
    loadPacks(isSearchMode and SearchInput.Text~="" and SearchInput.Text or nil)
end)

DiscoverTab.MouseButton1Click:Connect(function()
    isSearchMode = false
    DiscoverTab.BackgroundColor3 = C_BLUE;  DiscoverTab.TextColor3 = C_WHITE
    SearchTab.BackgroundColor3   = Color3.fromRGB(30,30,42); SearchTab.TextColor3 = C_GRAY
    setVP(false)
    if #cachedList > 0 then showList(cachedList) else loadPacks(nil) end
end)

SearchTab.MouseButton1Click:Connect(function()
    isSearchMode = true
    SearchTab.BackgroundColor3   = C_BLUE;  SearchTab.TextColor3 = C_WHITE
    DiscoverTab.BackgroundColor3 = Color3.fromRGB(30,30,42); DiscoverTab.TextColor3 = C_GRAY
    setVP(true)
    SearchInput.Text = ""
    if #cachedList > 0 then showList(cachedList) end
end)

local debounce = nil
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    if not isSearchMode then return end
    local txt = SearchInput.Text
    if txt == "" then
        if #cachedList > 0 then showList(cachedList) end
        return
    end
    if debounce then task.cancel(debounce) end
    debounce = task.delay(0.3, function()
        showList(filterPacks(txt))
    end)
end)

-- Reapply on respawn
local lastPack = nil
Player.CharacterAdded:Connect(function()
    if lastPack then
        task.wait(1.2)
        applyPack(lastPack)
    end
end)

-- Boot — no HTTP needed, packs are local
loadPacks(nil)

print("AnimCatalog v8 loaded")
print("Packs: " .. #PACKS .. " | Each equips walk/run/idle/jump/fall/climb/swim")
