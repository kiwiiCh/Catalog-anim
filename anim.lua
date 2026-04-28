-- ==========================================
-- ANIM CATALOG v9  |  Delta Executor
-- - White/transparent glass UI
-- - Spinning Roblox R logo while loading
-- - Reset button restores original anims
-- - Safe switching: stops old tracks first
-- - No emojis
-- ==========================================

local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local AssetService      = game:GetService("AssetService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player            = Players.LocalPlayer

-- ============ COLORS (glass / white theme) ============
local C_WHITE    = Color3.fromRGB(255, 255, 255)
local C_OFFWHITE = Color3.fromRGB(245, 246, 250)
local C_BLUE     = Color3.fromRGB(0,   120, 215)   -- Roblox blue
local C_BLUE_LT  = Color3.fromRGB(50,  160, 255)
local C_GREEN    = Color3.fromRGB(0,   170, 80)
local C_RED      = Color3.fromRGB(210, 50,  50)
local C_DARK     = Color3.fromRGB(30,  30,  40)
local C_TEXT     = Color3.fromRGB(20,  20,  30)    -- near-black text on white
local C_SUBTEXT  = Color3.fromRGB(100, 100, 120)
local C_CARD     = C_WHITE
local C_STROKE   = Color3.fromRGB(210, 215, 228)
local C_TOPBAR   = Color3.fromRGB(0,   120, 215)   -- solid blue topbar
local C_TAB_ACT  = Color3.fromRGB(0,   120, 215)
local C_TAB_IDLE = Color3.fromRGB(230, 232, 240)
local C_CANVAS   = Color3.fromRGB(240, 242, 248)

local CARD_W   = 188
local CARD_H   = 222
local CARD_PAD = 10

-- ============ ANIMATION PACKS ============
local PACKS = {
    {Name="Ninja",      BundleId=75,  Creator="Roblox", Anims={idle="656117400", walk="656118852", run="656121360", jump="656117878", fall="656117961", climb="656118353", swim="656118679"}},
    {Name="Zombie",     BundleId=77,  Creator="Roblox", Anims={idle="616158929", walk="616159775", run="616160636", jump="616161053", fall="616161497", climb="616162054", swim="616162536"}},
    {Name="Superhero",  BundleId=79,  Creator="Roblox", Anims={idle="616072051", walk="616072715", run="616074315", jump="616075295", fall="616076348", climb="616077211", swim="616078210"}},
    {Name="Robot",      BundleId=78,  Creator="Roblox", Anims={idle="616161997", walk="616162405", run="616163682", jump="616164360", fall="616165025", climb="616165382", swim="616165813"}},
    {Name="Cartoony",   BundleId=80,  Creator="Roblox", Anims={idle="742637544", walk="742638087", run="742638842", jump="742640018", fall="742641128", climb="742641836", swim="742642457"}},
    {Name="Levitation", BundleId=33,  Creator="Roblox", Anims={idle="616156778", walk="616157272", run="616157897", jump="616158327", fall="616158555", climb="616158777", swim="616159036"}},
    {Name="Mage",       BundleId=34,  Creator="Roblox", Anims={idle="616010382", walk="616011036", run="616012156", jump="616012752", fall="616013413", climb="616013793", swim="616014359"}},
    {Name="Pirate",     BundleId=36,  Creator="Roblox", Anims={idle="616006778", walk="616007277", run="616007736", jump="616008087", fall="616008320", climb="616008501", swim="616008662"}},
    {Name="Werewolf",   BundleId=37,  Creator="Roblox", Anims={idle="616003913", walk="616004474", run="616005001", jump="616005314", fall="616005534", climb="616005785", swim="616006154"}},
    {Name="Skating",    BundleId=38,  Creator="Roblox", Anims={idle="616152468", walk="616153086", run="616153997", jump="616154636", fall="616155297", climb="616155727", swim="616156219"}},
    {Name="Vampire",    BundleId=39,  Creator="Roblox", Anims={idle="1083462025",walk="1083462636",run="1083463460",jump="1083464165",fall="1083464731",climb="1083465105",swim="1083465441"}},
    {Name="Toy",        BundleId=82,  Creator="Roblox", Anims={idle="782841498", walk="782842708", run="782843525", jump="782844295", fall="782845070", climb="782845589", swim="782846175"}},
    {Name="Rthro",      BundleId=109, Creator="Roblox", Anims={idle="2510235063",walk="2510238627",run="2510240219",jump="2510242378",fall="2510244400",climb="2510246327",swim="2510248268"}},
    {Name="Oldschool",  BundleId=145, Creator="Roblox", Anims={idle="5916726572",walk="5916707072",run="5916707702",jump="5916707990",fall="5916708340",climb="5916708765",swim="5916709343"}},
    {Name="Astronaut",  BundleId=83,  Creator="Roblox", Anims={idle="616070468", walk="616071122", run="616071553", jump="616071897", fall="616072153", climb="616072416", swim="616072715"}},
    {Name="Alien",      BundleId=84,  Creator="Roblox", Anims={idle="616068262", walk="616068867", run="616069294", jump="616069626", fall="616069905", climb="616070160", swim="616070362"}},
    {Name="Dragon",     BundleId=85,  Creator="Roblox", Anims={idle="616097718", walk="616098295", run="616098560", jump="616098796", fall="616099013", climb="616099255", swim="616099503"}},
    {Name="Stylish",    BundleId=86,  Creator="Roblox", Anims={idle="616088355", walk="616089075", run="616091064", jump="616091789", fall="616092315", climb="616092810", swim="616093357"}},
    {Name="Elder",      BundleId=87,  Creator="Roblox", Anims={idle="616095352", walk="616095700", run="616096052", jump="616096396", fall="616096650", climb="616096898", swim="616097264"}},
    {Name="Caveman",    BundleId=88,  Creator="Roblox", Anims={idle="616094699", walk="616094110", run="616093826", jump="616093621", fall="616093457", climb="616093280", swim="616093113"}},
}

-- ============ ORIGINAL ANIMATION BACKUP ============
-- Saved ONCE when the script runs (before any changes).
-- Reset button restores exactly these IDs.

local SLOT_FOLDERS = {
    idle  = {"idle"},
    walk  = {"walk"},
    run   = {"run"},
    jump  = {"jump"},
    fall  = {"fall"},
    climb = {"climb"},
    swim  = {"swim", "swimidle"},
}

local originalAnims = nil   -- {slot = {folderName = {animIndex = id}}}

local function snapshotOriginalAnims()
    -- Deep-save every Animation ID from the Animate script
    -- so we can restore it perfectly later.
    local char = Player.Character or Player.CharacterAdded:Wait()
    -- Wait for Animate to be present
    local aScript = char:FindFirstChild("Animate")
    if not aScript then return end

    local snap = {}
    for slot, folders in pairs(SLOT_FOLDERS) do
        snap[slot] = {}
        for _, fname in ipairs(folders) do
            local folder = aScript:FindFirstChild(fname)
            if folder then
                snap[slot][fname] = {}
                for idx, child in ipairs(folder:GetChildren()) do
                    if child:IsA("Animation") then
                        snap[slot][fname][idx] = child.AnimationId
                    end
                end
            end
        end
    end
    return snap
end

-- Take snapshot as soon as character/Animate is ready
local function initSnapshot()
    local char = Player.Character
    if char then
        local aScript = char:FindFirstChild("Animate")
        if aScript then
            originalAnims = snapshotOriginalAnims()
            return
        end
    end
    -- Wait for character if not ready yet
    Player.CharacterAdded:Connect(function(c)
        -- Animate loads slightly after character
        task.wait(0.5)
        if not originalAnims then
            originalAnims = snapshotOriginalAnims()
        end
    end)
end
initSnapshot()

-- ============ SERVER SETUP ============
local REMOTE_NAME = "AnimCatalog_v9"

local function setupServer()
    local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
    if not remote then
        remote      = Instance.new("RemoteEvent")
        remote.Name = REMOTE_NAME
        remote.Parent = ReplicatedStorage
    end
    local sss = game:GetService("ServerScriptService")
    if sss:FindFirstChild("AnimCatalog_Srv_v9") then return remote end

    local ss = Instance.new("Script")
    ss.Name   = "AnimCatalog_Srv_v9"
    ss.Source = [[
        local RS     = game:GetService("ReplicatedStorage")
        local remote = RS:WaitForChild("AnimCatalog_v9", 15)
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

            -- Stop all tracks first
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                        t:Stop(0)
                    end
                end
            end

            -- Patch slots
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

-- ============ CORE ANIMATION PATCHER ============
-- Safe switching: always stop all tracks before patching,
-- then kick state to reload.

local isApplying = false   -- guard against simultaneous applies

local function stopAllTracks(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(function() track:Stop(0) end)
        end
    end
end

local function kickHumanoidState(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            local state = hum:GetState()
            hum:ChangeState(Enum.HumanoidStateType.Landed)
            task.wait(0.04)
            hum:ChangeState(state ~= Enum.HumanoidStateType.None and state or Enum.HumanoidStateType.Running)
        end)
    end
end

local function patchSlots(aScript, slotTable)
    -- slotTable: { slot = "animId" }
    local patched = 0
    for slot, animId in pairs(slotTable) do
        local folders = SLOT_FOLDERS[slot] or {slot}
        for _, fname in ipairs(folders) do
            local folder = aScript:FindFirstChild(fname)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("Animation") then
                        child.AnimationId = "rbxassetid://" .. tostring(animId)
                        patched = patched + 1
                    end
                end
            end
        end
    end
    return patched
end

local function getBundleAnims(bundleId)
    local result = {}
    local ok, details = pcall(function()
        return AssetService:GetBundleDetailsAsync(bundleId)
    end)
    if not (ok and details and details.Items) then return result end
    local KEYWORDS = {walk="walk",run="run",jump="jump",fall="fall",climb="climb",swim="swim",idle="idle"}
    for _, item in ipairs(details.Items) do
        if item.Type == "Asset" then
            local nl = (item.Name or ""):lower()
            for slot, kw in pairs(KEYWORDS) do
                if nl:find(kw) and not result[slot] then
                    result[slot] = tostring(item.Id)
                    break
                end
            end
        end
    end
    return result
end

-- last equipped pack reference for respawn reapply
local lastPack = nil

local function applyPack(pack)
    if isApplying then return false, "Already applying, please wait" end
    isApplying = true

    local char = Player.Character
    if not char then isApplying=false; return false, "No character" end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then isApplying=false; return false, "No Humanoid" end

    local aScript = char:FindFirstChild("Animate")
    if not aScript then isApplying=false; return false, "No Animate script" end

    -- Build slot table: start with hardcoded, overlay live bundle data
    local slotTable = {}
    for slot, id in pairs(pack.Anims) do slotTable[slot] = id end

    if pack.BundleId then
        local live = getBundleAnims(pack.BundleId)
        for slot, id in pairs(live) do slotTable[slot] = id end
    end

    -- STEP 1: stop all tracks cleanly
    stopAllTracks(char)
    task.wait(0.05)

    -- STEP 2: patch the Animate script
    local patched = patchSlots(aScript, slotTable)
    if patched == 0 then isApplying=false; return false, "No animation slots found" end

    -- STEP 3: reload via state kick
    kickHumanoidState(char)

    -- STEP 4: tell server
    pcall(function()
        if AnimRemote then AnimRemote:FireServer(slotTable) end
    end)

    lastPack = pack
    isApplying = false
    return true, patched .. " slots applied"
end

local function resetAnims()
    if isApplying then return false, "Already applying, please wait" end
    if not originalAnims then return false, "Original anims not saved yet" end

    isApplying = true
    local char = Player.Character
    if not char then isApplying=false; return false, "No character" end

    local aScript = char:FindFirstChild("Animate")
    if not aScript then isApplying=false; return false, "No Animate script" end

    stopAllTracks(char)
    task.wait(0.05)

    -- Restore exactly the original IDs, per folder, per Animation child order
    local patched = 0
    for slot, folders in pairs(originalAnims) do
        for fname, idxMap in pairs(folders) do
            local folder = aScript:FindFirstChild(fname)
            if folder then
                local children = folder:GetChildren()
                for idx, child in ipairs(children) do
                    if child:IsA("Animation") and idxMap[idx] then
                        child.AnimationId = idxMap[idx]
                        patched = patched + 1
                    end
                end
            end
        end
    end

    kickHumanoidState(char)

    -- Tell server to reset too (send original IDs as flat table)
    pcall(function()
        if AnimRemote then
            local flat = {}
            for slot, folders in pairs(originalAnims) do
                for fname, idxMap in pairs(folders) do
                    if idxMap[1] then flat[slot] = idxMap[1]:gsub("rbxassetid://","") end
                end
            end
            AnimRemote:FireServer(flat)
        end
    end)

    lastPack = nil
    isApplying = false
    return true, "Restored " .. patched .. " original animations"
end

-- ============ GUI ============
if game.CoreGui:FindFirstChild("AnimCatalog_v9") then
    game.CoreGui.AnimCatalog_v9:Destroy()
end

local Screen = Instance.new("ScreenGui")
Screen.Name           = "AnimCatalog_v9"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder   = 999
Screen.Parent         = game.CoreGui

-- ---- helpers ----
local function mkCorner(inst, r)
    Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r or 8)
end
local function mkStroke(inst, col, thick)
    local s = Instance.new("UIStroke", inst)
    s.Color = col or C_STROKE; s.Thickness = thick or 1
    return s
end
local function mkLabel(parent, text, size, color, font, ax)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.Text       = text
    l.TextSize   = size or 14
    l.TextColor3 = color or C_TEXT
    l.Font       = font  or Enum.Font.Gotham
    l.TextXAlignment = ax or Enum.TextXAlignment.Center
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextScaled = false
    return l
end
local function mkBtn(parent, text, size, bgCol, textCol, font)
    local b = Instance.new("TextButton", parent)
    b.BackgroundColor3 = bgCol or C_BLUE
    b.Text             = text
    b.TextSize         = size or 13
    b.TextColor3       = textCol or C_WHITE
    b.Font             = font or Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    return b
end

-- ============ FLOATING ICON ============
local Icon = Instance.new("TextButton")
Icon.Size             = UDim2.new(0, 60, 0, 60)
Icon.Position         = UDim2.new(0, 16, 0.5, -30)
Icon.BackgroundColor3 = C_WHITE
Icon.BorderSizePixel  = 0
Icon.Text             = ""
Icon.ZIndex           = 20
Icon.Active           = true
Icon.Parent           = Screen
mkCorner(Icon, 16)
mkStroke(Icon, C_BLUE, 2)

do
    -- Roblox-style R inside a blue circle
    local circle = Instance.new("Frame", Icon)
    circle.Size             = UDim2.new(0,38,0,38)
    circle.Position         = UDim2.new(0.5,-19,0,5)
    circle.BackgroundColor3 = C_BLUE
    circle.BorderSizePixel  = 0
    circle.ZIndex           = 21
    mkCorner(circle, 19)
    local rl = mkLabel(circle, "R", 22, C_WHITE, Enum.Font.GothamBlack)
    rl.Size   = UDim2.new(1,0,1,0)
    rl.ZIndex = 22

    local sub = mkLabel(Icon, "ANIM", 8, C_BLUE, Enum.Font.GothamBold)
    sub.Size     = UDim2.new(1,0,0,14)
    sub.Position = UDim2.new(0,0,1,-16)
    sub.ZIndex   = 21
end
makeDraggable(Icon, Icon)

-- ============ MAIN PANEL ============
local Panel = Instance.new("Frame")
Panel.Size                  = UDim2.new(0, 452, 0, 618)
Panel.Position              = UDim2.new(0, 90, 0.5, -309)
Panel.BackgroundColor3      = C_OFFWHITE
Panel.BackgroundTransparency= 0.08       -- slightly transparent / glassy
Panel.BorderSizePixel       = 0
Panel.Visible               = false
Panel.ZIndex                = 10
Panel.Parent                = Screen
mkCorner(Panel, 14)
mkStroke(Panel, C_STROKE, 1)

-- ── TopBar (solid blue) ──
local TopBar = Instance.new("Frame", Panel)
TopBar.Size             = UDim2.new(1,0,0,52)
TopBar.BackgroundColor3 = C_TOPBAR
TopBar.BorderSizePixel  = 0
TopBar.ZIndex           = 11
mkCorner(TopBar, 14)

-- fill bottom corners of topbar so they're square
local TBFix = Instance.new("Frame", TopBar)
TBFix.Size             = UDim2.new(1,0,0,14)
TBFix.Position         = UDim2.new(0,0,1,-14)
TBFix.BackgroundColor3 = C_TOPBAR
TBFix.BorderSizePixel  = 0
TBFix.ZIndex           = 11

-- White "R" badge in topbar
local TBBadge = Instance.new("Frame", TopBar)
TBBadge.Size             = UDim2.new(0,30,0,30)
TBBadge.Position         = UDim2.new(0,12,0,11)
TBBadge.BackgroundColor3 = C_WHITE
TBBadge.BorderSizePixel  = 0
TBBadge.ZIndex           = 12
mkCorner(TBBadge, 8)
do
    local r = mkLabel(TBBadge, "R", 18, C_BLUE, Enum.Font.GothamBlack)
    r.Size   = UDim2.new(1,0,1,0)
    r.ZIndex = 13
end

local TBTitle = mkLabel(TopBar, "Animation Catalog", 16, C_WHITE, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
TBTitle.Size     = UDim2.new(1,-180,0,22)
TBTitle.Position = UDim2.new(0,50,0,7)
TBTitle.ZIndex   = 12

local TBSub = mkLabel(TopBar, "Full packs  |  all 7 slots", 10, Color3.fromRGB(180,215,255), Enum.Font.Gotham, Enum.TextXAlignment.Left)
TBSub.Size     = UDim2.new(1,-180,0,14)
TBSub.Position = UDim2.new(0,50,0,29)
TBSub.ZIndex   = 12

-- Reset button (in topbar)
local ResetBtn = mkBtn(TopBar, "Reset", 11, Color3.fromRGB(255,255,255), C_BLUE, Enum.Font.GothamBold)
ResetBtn.Size     = UDim2.new(0,46,0,28)
ResetBtn.Position = UDim2.new(1,-124,0,12)
ResetBtn.ZIndex   = 12
mkCorner(ResetBtn, 7)

-- Refresh button
local RefreshBtn = mkBtn(TopBar, "R", 16, Color3.fromRGB(255,255,255), C_BLUE, Enum.Font.GothamBold)
RefreshBtn.Size     = UDim2.new(0,28,0,28)
RefreshBtn.Position = UDim2.new(1,-74,0,12)
RefreshBtn.ZIndex   = 12
mkCorner(RefreshBtn, 7)

-- Close button
local CloseBtn = mkBtn(TopBar, "X", 13, Color3.fromRGB(230,60,60), C_WHITE, Enum.Font.GothamBold)
CloseBtn.Size     = UDim2.new(0,28,0,28)
CloseBtn.Position = UDim2.new(1,-40,0,12)
CloseBtn.ZIndex   = 12
mkCorner(CloseBtn, 7)

makeDraggable(TopBar, Panel)

-- ── Tab Row ──
local TabRow = Instance.new("Frame", Panel)
TabRow.Size             = UDim2.new(1,-24,0,36)
TabRow.Position         = UDim2.new(0,12,0,60)
TabRow.BackgroundColor3 = Color3.fromRGB(228,230,240)
TabRow.BackgroundTransparency = 0
TabRow.BorderSizePixel  = 0
TabRow.ZIndex           = 11
mkCorner(TabRow, 10)
mkStroke(TabRow, C_STROKE, 1)

local function mkTab(text, side, active)
    local b = mkBtn(TabRow, text, 13,
        active and C_TAB_ACT or C_TAB_IDLE,
        active and C_WHITE    or C_SUBTEXT,
        Enum.Font.GothamBold)
    b.Size     = UDim2.new(0.5,-4,1,-6)
    b.Position = side==0 and UDim2.new(0,3,0,3) or UDim2.new(0.5,1,0,3)
    b.ZIndex   = 12
    mkCorner(b, 7)
    return b
end
local DiscoverTab = mkTab("Discover", 0, true)
local SearchTab   = mkTab("Search",   1, false)

-- ── Search Box ──
local SearchCon = Instance.new("Frame", Panel)
SearchCon.Size             = UDim2.new(1,-24,0,36)
SearchCon.Position         = UDim2.new(0,12,0,104)
SearchCon.BackgroundColor3 = C_WHITE
SearchCon.BackgroundTransparency = 0
SearchCon.BorderSizePixel  = 0
SearchCon.Visible          = false
SearchCon.ZIndex           = 11
mkCorner(SearchCon, 9)
mkStroke(SearchCon, C_STROKE, 1)

local SLbl = mkLabel(SearchCon, "Search:", 11, C_SUBTEXT, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
SLbl.Size     = UDim2.new(0,52,1,0)
SLbl.Position = UDim2.new(0,8,0,0)
SLbl.ZIndex   = 12

local SearchInput = Instance.new("TextBox", SearchCon)
SearchInput.Size                   = UDim2.new(1,-66,1,-8)
SearchInput.Position               = UDim2.new(0,62,0,4)
SearchInput.BackgroundTransparency = 1
SearchInput.Text                   = ""
SearchInput.PlaceholderText        = "e.g. ninja, zombie, robot..."
SearchInput.PlaceholderColor3      = Color3.fromRGB(180,180,195)
SearchInput.TextColor3             = C_TEXT
SearchInput.Font                   = Enum.Font.Gotham
SearchInput.TextSize               = 13
SearchInput.TextXAlignment         = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus       = false
SearchInput.ZIndex                 = 12

-- ── Draggable Canvas Viewport ──
local VP_Y0, VP_H0 = 104, 498
local VP_Y1, VP_H1 = 148, 454

local Viewport = Instance.new("Frame", Panel)
Viewport.Size                  = UDim2.new(1,-24,0,VP_H0)
Viewport.Position              = UDim2.new(0,12,0,VP_Y0)
Viewport.BackgroundColor3      = C_CANVAS
Viewport.BackgroundTransparency= 0
Viewport.BorderSizePixel       = 0
Viewport.ClipsDescendants      = true
Viewport.ZIndex                = 11
mkCorner(Viewport, 10)
mkStroke(Viewport, C_STROKE, 1)

local Canvas = Instance.new("Frame", Viewport)
Canvas.Size                  = UDim2.new(0,900,0,900)
Canvas.Position              = UDim2.new(0,0,0,0)
Canvas.BackgroundTransparency= 1
Canvas.BorderSizePixel       = 0
Canvas.ZIndex                = 12

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

-- Canvas pan + momentum
local cDrag,cDs,cSp = false,nil,nil
local velX,velY     = 0,0
local lastMPos      = nil
local totalCols,totalRows = 2,1

Viewport.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        cDrag=true; cDs=i.Position; cSp=Canvas.Position
        velX=0; velY=0; lastMPos=i.Position
    end
end)
Viewport.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        cDrag=false
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if cDrag and (i.UserInputType==Enum.UserInputType.MouseMovement
    or  i.UserInputType==Enum.UserInputType.Touch) then
        local d = i.Position-cDs
        if lastMPos then velX=i.Position.X-lastMPos.X; velY=i.Position.Y-lastMPos.Y end
        lastMPos = i.Position
        Canvas.Position = UDim2.new(0,cSp.X.Offset+d.X,0,cSp.Y.Offset+d.Y)
    end
end)
RunService.Heartbeat:Connect(function()
    if not cDrag and (math.abs(velX)>0.3 or math.abs(velY)>0.3) then
        velX=velX*0.87; velY=velY*0.87
        local nx=Canvas.Position.X.Offset+velX
        local ny=Canvas.Position.Y.Offset+velY
        local vw=Viewport.AbsoluteSize.X
        local vh=Viewport.AbsoluteSize.Y
        local cw=totalCols*(CARD_W+CARD_PAD)+CARD_PAD
        local ch=totalRows*(CARD_H+CARD_PAD)+CARD_PAD
        nx=math.clamp(nx,math.min(0,vw-cw),0)
        ny=math.clamp(ny,math.min(0,vh-ch),0)
        Canvas.Position=UDim2.new(0,nx,0,ny)
        if math.abs(velX)<0.1 and math.abs(velY)<0.1 then velX=0;velY=0 end
    end
end)

-- ── Loading Overlay (spinning R) ──
local LoadOverlay = Instance.new("Frame", Viewport)
LoadOverlay.Size                  = UDim2.new(1,0,1,0)
LoadOverlay.BackgroundColor3      = C_WHITE
LoadOverlay.BackgroundTransparency= 0.15
LoadOverlay.BorderSizePixel       = 0
LoadOverlay.Visible               = false
LoadOverlay.ZIndex                = 19
mkCorner(LoadOverlay, 10)

-- Spinning R circle
local SpinCircle = Instance.new("Frame", LoadOverlay)
SpinCircle.Size             = UDim2.new(0,64,0,64)
SpinCircle.Position         = UDim2.new(0.5,-32,0.5,-52)
SpinCircle.BackgroundColor3 = C_BLUE
SpinCircle.BorderSizePixel  = 0
SpinCircle.ZIndex           = 20
mkCorner(SpinCircle, 32)
do
    local rl = mkLabel(SpinCircle, "R", 34, C_WHITE, Enum.Font.GothamBlack)
    rl.Size   = UDim2.new(1,0,1,0)
    rl.ZIndex = 21
end

local LoadText = mkLabel(LoadOverlay, "Fetching...", 15, C_BLUE, Enum.Font.GothamBold)
LoadText.Size     = UDim2.new(1,0,0,24)
LoadText.Position = UDim2.new(0,0,0.5,22)
LoadText.ZIndex   = 20

-- Spin the circle
local spinAngle = 0
RunService.Heartbeat:Connect(function(dt)
    if LoadOverlay.Visible then
        spinAngle = (spinAngle + dt * 180) % 360
        SpinCircle.Rotation = spinAngle
    end
end)

-- ── Drag Hint ──
local DragHint = Instance.new("Frame", Viewport)
DragHint.Size             = UDim2.new(0,220,0,26)
DragHint.Position         = UDim2.new(0.5,-110,0,8)
DragHint.BackgroundColor3 = C_BLUE
DragHint.BackgroundTransparency = 0
DragHint.BorderSizePixel  = 0
DragHint.ZIndex           = 25
DragHint.Visible          = false
mkCorner(DragHint, 13)
do
    local ht = mkLabel(DragHint, "Drag left / right / up / down to browse", 10, C_WHITE, Enum.Font.GothamBold)
    ht.Size   = UDim2.new(1,0,1,0)
    ht.ZIndex = 26
end

-- ── Status Bar ──
local StatusBar = Instance.new("Frame", Panel)
StatusBar.Size             = UDim2.new(1,-24,0,26)
StatusBar.Position         = UDim2.new(0,12,1,-34)
StatusBar.BackgroundColor3 = C_WHITE
StatusBar.BackgroundTransparency = 0
StatusBar.BorderSizePixel  = 0
StatusBar.ZIndex           = 11
mkCorner(StatusBar, 7)
mkStroke(StatusBar, C_STROKE, 1)

local StatusText = mkLabel(StatusBar, "Loading...", 11, C_SUBTEXT, Enum.Font.Gotham)
StatusText.Size     = UDim2.new(1,-10,1,0)
StatusText.Position = UDim2.new(0,5,0,0)
StatusText.ZIndex   = 12

local function setStatus(msg, col)
    StatusText.Text       = msg
    StatusText.TextColor3 = col or C_SUBTEXT
end

-- ============ CARD BUILDER ============
local function clearCards()
    Canvas.Position = UDim2.new(0,0,0,0)
    velX=0; velY=0
    for _, c in ipairs(Canvas:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function updateCanvasSize(count)
    local vw = Viewport.AbsoluteSize.X
    if vw==0 then vw=404 end
    local cols = math.max(2, math.floor((vw-CARD_PAD)/(CARD_W+CARD_PAD)))
    local rows = math.ceil(count/cols)
    totalCols=cols; totalRows=rows
    Canvas.Size = UDim2.new(
        0, math.max(cols*(CARD_W+CARD_PAD)+CARD_PAD, vw),
        0, math.max(rows*(CARD_H+CARD_PAD)+CARD_PAD, Viewport.AbsoluteSize.Y)
    )
end

-- track which card is "active" so we can mark it
local activeCardRef = nil

local function buildCard(pack, index)
    local Card = Instance.new("Frame", Canvas)
    Card.BackgroundColor3      = C_CARD
    Card.BackgroundTransparency= 0
    Card.BorderSizePixel       = 0
    Card.ZIndex                = 13
    mkCorner(Card, 10)
    local CS = mkStroke(Card, C_STROKE, 1)

    -- Thumbnail
    local TF = Instance.new("Frame", Card)
    TF.Size             = UDim2.new(1,0,0,126)
    TF.BackgroundColor3 = Color3.fromRGB(235,238,248)
    TF.BorderSizePixel  = 0
    TF.ZIndex           = 14
    mkCorner(TF, 10)

    local TFF = Instance.new("Frame", TF)
    TFF.Size             = UDim2.new(1,0,0,10)
    TFF.Position         = UDim2.new(0,0,1,-10)
    TFF.BackgroundColor3 = Color3.fromRGB(235,238,248)
    TFF.BorderSizePixel  = 0
    TFF.ZIndex           = 14

    -- placeholder text
    local PH = mkLabel(TF, pack.Name, 11, C_SUBTEXT, Enum.Font.GothamBold)
    PH.Size        = UDim2.new(1,-8,1,0)
    PH.Position    = UDim2.new(0,4,0,0)
    PH.TextWrapped = true
    PH.ZIndex      = 15

    local Thumb = Instance.new("ImageLabel", TF)
    Thumb.Size                   = UDim2.new(1,0,1,0)
    Thumb.BackgroundTransparency = 1
    Thumb.Image                  = "rbxthumb://type=Asset&id=" .. pack.Anims.idle .. "&w=150&h=150"
    Thumb.ScaleType              = Enum.ScaleType.Fit
    Thumb.ZIndex                 = 15
    mkCorner(Thumb, 10)
    Thumb:GetPropertyChangedSignal("IsLoaded"):Connect(function()
        if Thumb.IsLoaded then PH.Visible = false end
    end)

    -- "7 ANIMS" blue badge
    local Bdg = Instance.new("Frame", TF)
    Bdg.Size             = UDim2.new(0,62,0,17)
    Bdg.Position         = UDim2.new(0,6,0,6)
    Bdg.BackgroundColor3 = C_BLUE
    Bdg.BorderSizePixel  = 0
    Bdg.ZIndex           = 16
    mkCorner(Bdg, 9)
    do
        local bt = mkLabel(Bdg, "7 ANIMS", 9, C_WHITE, Enum.Font.GothamBold)
        bt.Size=UDim2.new(1,0,1,0); bt.ZIndex=17
    end

    -- slot name strip at bottom of thumb
    local SS = Instance.new("Frame", TF)
    SS.Size             = UDim2.new(1,-12,0,14)
    SS.Position         = UDim2.new(0,6,1,-20)
    SS.BackgroundColor3 = Color3.fromRGB(220,225,240)
    SS.BorderSizePixel  = 0
    SS.ZIndex           = 16
    mkCorner(SS, 4)
    local SLayout = Instance.new("UIListLayout", SS)
    SLayout.FillDirection       = Enum.FillDirection.Horizontal
    SLayout.Padding             = UDim.new(0,2)
    SLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    for _, tag in ipairs({"Walk","Run","Idle","Jump","Fall","Climb","Swim"}) do
        local tg = mkLabel(SS, tag, 7, C_BLUE, Enum.Font.GothamBold)
        tg.Size=UDim2.new(0,30,1,0); tg.ZIndex=17
    end

    -- Info
    local Info = Instance.new("Frame", Card)
    Info.Size                  = UDim2.new(1,0,0,92)
    Info.Position              = UDim2.new(0,0,0,128)
    Info.BackgroundTransparency= 1
    Info.ZIndex                = 14

    local NL = mkLabel(Info, pack.Name, 12, C_TEXT, Enum.Font.GothamBold, Enum.TextXAlignment.Left)
    NL.Size=UDim2.new(1,-12,0,30); NL.Position=UDim2.new(0,8,0,4)
    NL.TextWrapped=true; NL.TextYAlignment=Enum.TextYAlignment.Top; NL.ZIndex=15

    local CL = mkLabel(Info, "by " .. (pack.Creator or "Roblox"), 10, C_SUBTEXT, Enum.Font.Gotham, Enum.TextXAlignment.Left)
    CL.Size=UDim2.new(1,-12,0,13); CL.Position=UDim2.new(0,8,0,35)
    CL.TextTruncate=Enum.TextTruncate.AtEnd; CL.ZIndex=15

    local AB = mkBtn(Info, "Equip Full Pack", 12, C_BLUE, C_WHITE, Enum.Font.GothamBold)
    AB.Size=UDim2.new(1,-16,0,28); AB.Position=UDim2.new(0,8,0,52); AB.ZIndex=15
    mkCorner(AB, 7)

    -- hover
    Card.MouseEnter:Connect(function()
        TweenService:Create(Card,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(240,244,255)}):Play()
        TweenService:Create(CS,  TweenInfo.new(0.12),{Color=C_BLUE}):Play()
    end)
    Card.MouseLeave:Connect(function()
        -- keep blue border if this is the active card
        if activeCardRef ~= Card then
            TweenService:Create(Card,TweenInfo.new(0.12),{BackgroundColor3=C_CARD}):Play()
            TweenService:Create(CS,  TweenInfo.new(0.12),{Color=C_STROKE}):Play()
        end
    end)
    AB.MouseEnter:Connect(function()
        TweenService:Create(AB,TweenInfo.new(0.1),{BackgroundColor3=C_BLUE_LT}):Play()
    end)
    AB.MouseLeave:Connect(function()
        if AB.Text == "Equip Full Pack" then
            TweenService:Create(AB,TweenInfo.new(0.1),{BackgroundColor3=C_BLUE}):Play()
        end
    end)

    AB.MouseButton1Click:Connect(function()
        if isApplying then return end

        AB.Text             = "Applying..."
        AB.BackgroundColor3 = C_SUBTEXT
        setStatus("Equipping " .. pack.Name .. "...", C_BLUE)

        task.spawn(function()
            local ok, msg = applyPack(pack)
            task.defer(function()
                if ok then
                    AB.Text             = "Equipped!"
                    AB.BackgroundColor3 = C_GREEN
                    -- mark this card active
                    if activeCardRef and activeCardRef ~= Card then
                        -- reset previous card's stroke
                        local prevStroke = activeCardRef:FindFirstChildOfClass("UIStroke")
                        if prevStroke then prevStroke.Color = C_STROKE end
                        activeCardRef.BackgroundColor3 = C_CARD
                    end
                    activeCardRef = Card
                    CS.Color = C_BLUE
                    setStatus("Equipped: " .. pack.Name .. "  (" .. msg .. ")", C_GREEN)
                else
                    AB.Text             = "Failed"
                    AB.BackgroundColor3 = C_RED
                    setStatus("Error: " .. tostring(msg), C_RED)
                end
                task.delay(3, function()
                    if AB and AB.Parent then
                        AB.Text             = "Equip Full Pack"
                        AB.BackgroundColor3 = C_BLUE
                    end
                end)
            end)
        end)
    end)
end

-- ============ DISPLAY ============
local cachedList   = {}
local isSearchMode = false

local function showDragHint()
    DragHint.Visible=true; DragHint.BackgroundTransparency=0
    task.delay(3, function()
        TweenService:Create(DragHint,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
        task.delay(0.5, function() DragHint.Visible=false end)
    end)
end

local function showList(list)
    clearCards()
    activeCardRef = nil
    for i, pack in ipairs(list) do buildCard(pack, i) end
    updateCanvasSize(#list)
    setStatus(#list .. " packs  |  drag to browse", C_SUBTEXT)
    showDragHint()
end

local function filterPacks(kw)
    if not kw or kw=="" then return PACKS end
    local k = kw:lower()
    local out = {}
    for _, p in ipairs(PACKS) do
        if p.Name:lower():find(k,1,true) then table.insert(out,p) end
    end
    return out
end

local function loadPacks(keyword)
    clearCards()
    LoadOverlay.Visible = true
    setStatus("Fetching...", C_BLUE)
    task.defer(function()
        local list = filterPacks(keyword)
        LoadOverlay.Visible = false
        if #list==0 then
            setStatus("No packs match that search.", C_RED); return
        end
        if not keyword then cachedList = list end
        showList(list)
    end)
end

local function setVP(searchOn)
    SearchCon.Visible = searchOn
    Viewport.Position = UDim2.new(0,12,0, searchOn and VP_Y1 or VP_Y0)
    Viewport.Size     = UDim2.new(1,-24,0, searchOn and VP_H1 or VP_H0)
end

-- ============ OPEN / CLOSE ============
local function openPanel()
    local ip = Icon.Position
    Panel.Position = UDim2.new(ip.X.Scale,ip.X.Offset+70,ip.Y.Scale,ip.Y.Offset-10)
    Icon.Visible   = false
    Panel.Visible  = true
    Panel.BackgroundTransparency = 1
    TweenService:Create(Panel,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundTransparency=0.08}):Play()
end
local function closePanel()
    local pp = Panel.Position
    Icon.Position = UDim2.new(pp.X.Scale,pp.X.Offset-70,pp.Y.Scale,pp.Y.Offset+10)
    TweenService:Create(Panel,TweenInfo.new(0.15,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play()
    task.delay(0.16,function() Panel.Visible=false; Icon.Visible=true end)
end

Icon.MouseButton1Click:Connect(openPanel)
CloseBtn.MouseButton1Click:Connect(closePanel)

Icon.MouseEnter:Connect(function() TweenService:Create(Icon,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(240,244,255)}):Play() end)
Icon.MouseLeave:Connect(function() TweenService:Create(Icon,TweenInfo.new(0.12),{BackgroundColor3=C_WHITE}):Play() end)

-- Refresh
RefreshBtn.MouseButton1Click:Connect(function()
    TweenService:Create(RefreshBtn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(220,235,255)}):Play()
    task.delay(0.15,function() TweenService:Create(RefreshBtn,TweenInfo.new(0.08),{BackgroundColor3=C_WHITE}):Play() end)
    loadPacks(isSearchMode and SearchInput.Text~="" and SearchInput.Text or nil)
end)

-- Reset
ResetBtn.MouseButton1Click:Connect(function()
    if isApplying then return end
    TweenService:Create(ResetBtn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(220,235,255)}):Play()
    setStatus("Resetting to original animations...", C_BLUE)

    task.spawn(function()
        local ok, msg = resetAnims()
        task.defer(function()
            if ok then
                -- clear active card highlight
                if activeCardRef then
                    local prevStroke = activeCardRef:FindFirstChildOfClass("UIStroke")
                    if prevStroke then prevStroke.Color = C_STROKE end
                    activeCardRef.BackgroundColor3 = C_CARD
                    activeCardRef = nil
                end
                setStatus("Reset done: " .. msg, C_GREEN)
            else
                setStatus("Reset failed: " .. tostring(msg), C_RED)
            end
            task.delay(3,function()
                TweenService:Create(ResetBtn,TweenInfo.new(0.08),{BackgroundColor3=C_WHITE}):Play()
                setStatus("Ready  |  move to see animations", C_SUBTEXT)
            end)
        end)
    end)
end)

-- Tabs
DiscoverTab.MouseButton1Click:Connect(function()
    isSearchMode=false
    DiscoverTab.BackgroundColor3=C_TAB_ACT; DiscoverTab.TextColor3=C_WHITE
    SearchTab.BackgroundColor3=C_TAB_IDLE;  SearchTab.TextColor3=C_SUBTEXT
    setVP(false)
    if #cachedList>0 then showList(cachedList) else loadPacks(nil) end
end)

SearchTab.MouseButton1Click:Connect(function()
    isSearchMode=true
    SearchTab.BackgroundColor3=C_TAB_ACT;   SearchTab.TextColor3=C_WHITE
    DiscoverTab.BackgroundColor3=C_TAB_IDLE; DiscoverTab.TextColor3=C_SUBTEXT
    setVP(true); SearchInput.Text=""
    if #cachedList>0 then showList(cachedList) end
end)

local debounce=nil
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    if not isSearchMode then return end
    local txt=SearchInput.Text
    if txt=="" then if #cachedList>0 then showList(cachedList) end; return end
    if debounce then task.cancel(debounce) end
    debounce=task.delay(0.3,function() showList(filterPacks(txt)) end)
end)

-- Respawn: re-snapshot originals, then reapply last pack if any
Player.CharacterAdded:Connect(function(char)
    task.wait(0.8)
    -- always re-snapshot fresh original for new character
    originalAnims = snapshotOriginalAnims()
    -- reapply last chosen pack
    if lastPack then
        task.wait(0.4)
        applyPack(lastPack)
    end
end)

-- ============ BOOT ============
loadPacks(nil)
print("AnimCatalog v9 | " .. #PACKS .. " packs | Reset saves your originals")
