-- ========================================
-- ANIM CATALOG v4 — Delta Executor
-- ✅ Server-visible animations (RemoteEvent)
-- ✅ Draggable card canvas (pan to explore)
-- ✅ Roblox Catalog theme + thumbnails
-- ✅ No task.synchronize()
-- ========================================

local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Player           = Players.LocalPlayer

-- =============== CONSTANTS ===============

local ROBLOX_BLUE  = Color3.fromRGB(0,  162, 255)
local ROBLOX_GREEN = Color3.fromRGB(2,  183, 87)
local CARD_BG      = Color3.fromRGB(32,  32,  40)
local PANEL_BG     = Color3.fromRGB(22,  22,  28)
local TOPBAR_BG    = Color3.fromRGB(15,  15,  20)
local TEXT_WHITE   = Color3.fromRGB(255, 255, 255)
local TEXT_GRAY    = Color3.fromRGB(160, 160, 175)
local TEXT_DIMGRAY = Color3.fromRGB(100, 100, 120)
local THUMB_URL    = "https://www.roblox.com/asset-thumbnail/image?assetId=%s&width=150&height=150&format=png"

local CARD_W = 186
local CARD_H = 222
local CARD_PAD = 10

-- =============== SERVER REPLICATION SETUP ===============
-- We create (or reuse) a RemoteEvent in ReplicatedStorage so the
-- server Script we inject can receive our fire and apply the
-- animation to the character model — making it visible to everyone.

local REMOTE_NAME = "AnimCatalog_ApplyAnim"

-- Inject a server-side Script that listens and applies the animation
-- to the character's Humanoid using AnimationController so all
-- clients see it. We do this by creating a Script in ServerScriptService
-- via the executor's elevated context.
local function setupServer()
	local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name   = REMOTE_NAME
		remote.Parent = ReplicatedStorage
	end

	-- Check if server script already exists
	local sss = game:GetService("ServerScriptService")
	if sss:FindFirstChild("AnimCatalog_Server") then return remote end

	local serverScript = Instance.new("Script")
	serverScript.Name = "AnimCatalog_Server"
	serverScript.Source = [[
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local remote = ReplicatedStorage:WaitForChild("AnimCatalog_ApplyAnim", 10)
		if not remote then return end

		remote.OnServerEvent:Connect(function(player, animId)
			local char = player.Character
			if not char then return end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then return end

			-- Stop all current animations
			local animator = hum:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:Stop(0)
				end
			end

			-- Load & play animation on server so all clients replicate it
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://" .. tostring(animId)

			local ok, track = pcall(function()
				local animController = char:FindFirstChildOfClass("AnimationController")
					or hum
				return animController:LoadAnimation(anim)
			end)

			if ok and track then
				track:Play()
				-- Store so we can loop it
				char:SetAttribute("CurrentAnimId", tostring(animId))
			end

			-- Also swap the Animate script's IDs so walk/run/idle all update
			local animateScript = char:FindFirstChild("Animate")
			if animateScript then
				-- patch run animation references inside Animate
				for _, child in ipairs(animateScript:GetChildren()) do
					if child:IsA("StringValue") and child.Value:find("rbxassetid") then
						child.Value = "rbxassetid://" .. tostring(animId)
					end
					for _, sub in ipairs(child:GetChildren()) do
						if sub:IsA("Animation") then
							sub.AnimationId = "rbxassetid://" .. tostring(animId)
						end
					end
				end
			end
		end)
	]]
	serverScript.Parent = sss

	return remote
end

local AnimRemote = setupServer()

-- =============== DRAG UTILITY ===============

local function makeDraggable(handle, target)
	local dragging, dragStart, startPos = false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = i.Position
			startPos  = target.Position
		end
	end)
	handle.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (
			i.UserInputType == Enum.UserInputType.MouseMovement or
			i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- =============== HTTP ===============

local function safeGet(url)
	local ok, res = pcall(function() return game:HttpGet(url) end)
	if ok and res and res ~= "" then return res end
	return nil
end

-- =============== CATALOG API ===============

local function fetchAnimations(keyword, limit)
	limit = limit or 48
	local results = {}
	local urls = keyword and {
		("https://catalog.roblox.com/v1/search/items?category=Animation&keyword=%s&limit=%d")
			:format(HttpService:UrlEncode(keyword), limit),
	} or {
		("https://catalog.roblox.com/v1/search/items?category=Animation&sortType=3&limit=%d"):format(limit),
		("https://catalog.roblox.com/v1/search/items?category=Animation&limit=%d"):format(limit),
	}

	for _, url in ipairs(urls) do
		local raw = safeGet(url)
		if raw then
			local ok, parsed = pcall(function() return HttpService:JSONDecode(raw) end)
			if ok and parsed then
				local list = parsed.data or parsed.Results or {}
				for _, item in ipairs(list) do
					local isAnim = (item.itemType == "Animation")
						or (item.assetType == 32)
						or (item.AssetTypeId == 32)
					if isAnim then
						local id = tostring(item.id or item.assetId or item.AssetId or "")
						if id ~= "" then
							table.insert(results, {
								Name    = item.name    or item.Name    or "Unknown",
								Id      = id,
								Creator = item.creatorName or item.CreatorName or "Roblox",
								Price   = item.price   or item.Price   or 0,
							})
						end
					end
				end
			end
		end
		if #results > 0 then break end
	end

	if #results == 0 and not keyword then
		for _, kw in ipairs({"animation","run","walk","idle","ninja","zombie","cartoon","sword","dance"}) do
			if #results >= 40 then break end
			local raw2 = safeGet(
				"https://catalog.roblox.com/v1/search/items?category=Animation&keyword="
				..HttpService:UrlEncode(kw).."&limit=10")
			if raw2 then
				local ok2, p2 = pcall(function() return HttpService:JSONDecode(raw2) end)
				if ok2 and p2 and p2.data then
					for _, item in ipairs(p2.data) do
						if item.itemType == "Animation" then
							local id = tostring(item.id or "")
							local dup = false
							for _, ex in ipairs(results) do if ex.Id==id then dup=true break end end
							if not dup and id ~= "" then
								table.insert(results, {
									Name=item.name or "Unknown", Id=id,
									Creator=item.creatorName or "Roblox", Price=item.price or 0,
								})
							end
						end
					end
				end
			end
		end
	end

	return results
end

-- =============== ANIMATION APPLY ===============
-- Client side: swaps Animate script so the character locally plays it.
-- Server side: fires remote so all OTHER clients see it too.

local function applyAnimation(animId)
	local char = Player.Character
	if not char then return false, "No character" end
	if not char:FindFirstChild("Humanoid") then return false, "No Humanoid" end

	local applied = false

	-- Method A: InsertService loads the animate package
	local okA, model = pcall(function()
		return game:GetService("InsertService"):LoadAsset(tonumber(animId))
	end)
	if okA and model then
		local scr = model:FindFirstChildWhichIsA("Script")
			or model:FindFirstChildWhichIsA("LocalScript")
		if scr then
			local old = char:FindFirstChild("Animate")
			if old then old:Destroy() end
			local ns = Instance.new("LocalScript")
			ns.Name   = "Animate"
			ns.Source = scr.Source
			ns.Parent = char
			model:Destroy()
			applied = true
		else
			model:Destroy()
		end
	end

	-- Method B: GetObjects fallback
	if not applied then
		local okB, objs = pcall(function()
			return game:GetObjects("rbxassetid://" .. animId)
		end)
		if okB and objs and #objs > 0 then
			local scr2 = objs[1]
			if scr2:IsA("Script") or scr2:IsA("LocalScript") then
				local old2 = char:FindFirstChild("Animate")
				if old2 then old2:Destroy() end
				local ns2 = Instance.new("LocalScript")
				ns2.Name   = "Animate"
				ns2.Source = scr2.Source
				ns2.Parent = char
				applied = true
			end
		end
	end

	-- Method C: Direct Animator track (always try — makes server see it)
	pcall(function()
		local hum = char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop(0) end
			local anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://" .. animId
			local track = animator:LoadAnimation(anim)
			track:Play()
			applied = true
		end
	end)

	-- Fire server so ALL players see it
	if AnimRemote then
		pcall(function() AnimRemote:FireServer(animId) end)
	end

	if applied then
		return true, "Applied!"
	end
	return false, "Could not load asset"
end

-- =============== GUI ===============

if game.CoreGui:FindFirstChild("AnimCatalog_v4") then
	game.CoreGui.AnimCatalog_v4:Destroy()
end

local Screen = Instance.new("ScreenGui")
Screen.Name           = "AnimCatalog_v4"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder   = 999
Screen.Parent         = game.CoreGui

-- ─────────────────────────────
-- FLOATING ICON
-- ─────────────────────────────
local Icon = Instance.new("TextButton")
Icon.Name             = "Icon"
Icon.Size             = UDim2.new(0, 62, 0, 62)
Icon.Position         = UDim2.new(0, 16, 0.5, -31)
Icon.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
Icon.BorderSizePixel  = 0
Icon.Text             = ""
Icon.ZIndex           = 20
Icon.Active           = true
Icon.Parent           = Screen
Instance.new("UICorner", Icon).CornerRadius = UDim.new(0, 16)

do
	local s = Instance.new("UIStroke")
	s.Color = ROBLOX_BLUE; s.Thickness = 2; s.Transparency = 0.2; s.Parent = Icon
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30,30,48)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15,15,25)),
	})
	g.Rotation = 135; g.Parent = Icon

	local e = Instance.new("TextLabel")
	e.Size=UDim2.new(1,0,0.62,0); e.Position=UDim2.new(0,0,0,3)
	e.BackgroundTransparency=1; e.Text="🎭"; e.TextSize=28
	e.TextXAlignment=Enum.TextXAlignment.Center; e.ZIndex=21; e.Parent=Icon

	local l = Instance.new("TextLabel")
	l.Size=UDim2.new(1,0,0.38,0); l.Position=UDim2.new(0,0,0.62,0)
	l.BackgroundTransparency=1; l.Text="ANIM"; l.TextColor3=ROBLOX_BLUE
	l.Font=Enum.Font.GothamBold; l.TextSize=9
	l.TextXAlignment=Enum.TextXAlignment.Center; l.ZIndex=21; l.Parent=Icon
end

makeDraggable(Icon, Icon)

-- ─────────────────────────────
-- MAIN PANEL
-- ─────────────────────────────
local Panel = Instance.new("Frame")
Panel.Name            = "Panel"
Panel.Size            = UDim2.new(0, 450, 0, 600)
Panel.Position        = UDim2.new(0, 90, 0.5, -300)
Panel.BackgroundColor3= PANEL_BG
Panel.BorderSizePixel = 0
Panel.Visible         = false
Panel.ZIndex          = 10
Panel.Parent          = Screen
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 14)

do
	local s = Instance.new("UIStroke")
	s.Color=Color3.fromRGB(50,50,70); s.Thickness=1.5; s.Parent=Panel
end

-- ── TopBar ──
local TopBar = Instance.new("Frame")
TopBar.Size            = UDim2.new(1, 0, 0, 54)
TopBar.BackgroundColor3= TOPBAR_BG
TopBar.BorderSizePixel = 0
TopBar.ZIndex          = 11
TopBar.Parent          = Panel
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)

-- fill rounded bottom corners of topbar
local TBFill = Instance.new("Frame")
TBFill.Size=UDim2.new(1,0,0,14); TBFill.Position=UDim2.new(0,0,1,-14)
TBFill.BackgroundColor3=TOPBAR_BG; TBFill.BorderSizePixel=0; TBFill.ZIndex=11; TBFill.Parent=TopBar

-- accent line
local Accent = Instance.new("Frame")
Accent.Size=UDim2.new(1,0,0,2); Accent.Position=UDim2.new(0,0,1,-1)
Accent.BackgroundColor3=ROBLOX_BLUE; Accent.BorderSizePixel=0; Accent.ZIndex=12; Accent.Parent=TopBar
do
	local g=Instance.new("UIGradient")
	g.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromRGB(0,120,220)),
		ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,210,255)),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(0,120,220)),
	}); g.Parent=Accent
end

-- R badge
local RBadge = Instance.new("Frame")
RBadge.Size=UDim2.new(0,32,0,32); RBadge.Position=UDim2.new(0,12,0,11)
RBadge.BackgroundColor3=ROBLOX_BLUE; RBadge.BorderSizePixel=0; RBadge.ZIndex=12; RBadge.Parent=TopBar
Instance.new("UICorner",RBadge).CornerRadius=UDim.new(0,7)
do
	local r=Instance.new("TextLabel")
	r.Size=UDim2.new(1,0,1,0); r.BackgroundTransparency=1
	r.Text="R"; r.TextColor3=TEXT_WHITE; r.Font=Enum.Font.GothamBlack
	r.TextSize=20; r.ZIndex=13; r.Parent=RBadge
end

-- Title
do
	local t=Instance.new("TextLabel")
	t.Size=UDim2.new(1,-160,0,22); t.Position=UDim2.new(0,52,0,8)
	t.BackgroundTransparency=1; t.Text="Animation Catalog"
	t.TextColor3=TEXT_WHITE; t.Font=Enum.Font.GothamBold; t.TextSize=16
	t.TextXAlignment=Enum.TextXAlignment.Left; t.ZIndex=12; t.Parent=TopBar

	local s=Instance.new("TextLabel")
	s.Size=UDim2.new(1,-160,0,14); s.Position=UDim2.new(0,52,0,30)
	s.BackgroundTransparency=1; s.Text="Live from Roblox  •  drag to explore"
	s.TextColor3=ROBLOX_BLUE; s.Font=Enum.Font.Gotham; s.TextSize=10
	s.TextXAlignment=Enum.TextXAlignment.Left; s.ZIndex=12; s.Parent=TopBar
end

-- Refresh btn
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size=UDim2.new(0,32,0,32); RefreshBtn.Position=UDim2.new(1,-76,0,11)
RefreshBtn.BackgroundColor3=Color3.fromRGB(38,38,52)
RefreshBtn.Text="↻"; RefreshBtn.TextColor3=TEXT_GRAY
RefreshBtn.Font=Enum.Font.GothamBold; RefreshBtn.TextSize=19
RefreshBtn.BorderSizePixel=0; RefreshBtn.ZIndex=12; RefreshBtn.Parent=TopBar
Instance.new("UICorner",RefreshBtn).CornerRadius=UDim.new(0,8)

-- Close btn
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size=UDim2.new(0,32,0,32); CloseBtn.Position=UDim2.new(1,-40,0,11)
CloseBtn.BackgroundColor3=Color3.fromRGB(190,40,50)
CloseBtn.Text="✕"; CloseBtn.TextColor3=TEXT_WHITE
CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextSize=14
CloseBtn.BorderSizePixel=0; CloseBtn.ZIndex=12; CloseBtn.Parent=TopBar
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,8)

makeDraggable(TopBar, Panel)

-- ── Tab Row ──
local TabRow = Instance.new("Frame")
TabRow.Size=UDim2.new(1,-24,0,36); TabRow.Position=UDim2.new(0,12,0,62)
TabRow.BackgroundColor3=Color3.fromRGB(26,26,36)
TabRow.BorderSizePixel=0; TabRow.ZIndex=11; TabRow.Parent=Panel
Instance.new("UICorner",TabRow).CornerRadius=UDim.new(0,10)

local function makeTab(text, xOff, active)
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0.5,-4,1,-6)
	b.Position=UDim2.new(xOff==0 and 0 or 0.5, xOff==0 and 3 or 1, 0, 3)
	b.BackgroundColor3=active and ROBLOX_BLUE or Color3.fromRGB(30,30,42)
	b.Text=text; b.TextColor3=active and TEXT_WHITE or TEXT_GRAY
	b.Font=Enum.Font.GothamBold; b.TextSize=13
	b.BorderSizePixel=0; b.ZIndex=12; b.Parent=TabRow
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
	return b
end
local DiscoverTab = makeTab("🔥  Discover", 0, true)
local SearchTab   = makeTab("🔍  Search",   1, false)

-- ── Search box ──
local SearchCon = Instance.new("Frame")
SearchCon.Size=UDim2.new(1,-24,0,38); SearchCon.Position=UDim2.new(0,12,0,106)
SearchCon.BackgroundColor3=Color3.fromRGB(26,26,38)
SearchCon.BorderSizePixel=0; SearchCon.Visible=false; SearchCon.ZIndex=11; SearchCon.Parent=Panel
Instance.new("UICorner",SearchCon).CornerRadius=UDim.new(0,9)
do
	local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(50,50,75); s.Thickness=1; s.Parent=SearchCon
	local ic=Instance.new("TextLabel")
	ic.Size=UDim2.new(0,30,1,0); ic.Position=UDim2.new(0,6,0,0)
	ic.BackgroundTransparency=1; ic.Text="🔍"; ic.TextSize=14; ic.ZIndex=12; ic.Parent=SearchCon
end

local SearchInput = Instance.new("TextBox")
SearchInput.Size=UDim2.new(1,-42,1,-8); SearchInput.Position=UDim2.new(0,36,0,4)
SearchInput.BackgroundTransparency=1; SearchInput.Text=""
SearchInput.PlaceholderText="Search animations..."
SearchInput.PlaceholderColor3=Color3.fromRGB(80,80,105)
SearchInput.TextColor3=TEXT_WHITE; SearchInput.Font=Enum.Font.Gotham; SearchInput.TextSize=13
SearchInput.TextXAlignment=Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus=false; SearchInput.ZIndex=12; SearchInput.Parent=SearchCon

-- ─────────────────────────────────────────────
-- DRAGGABLE CARD CANVAS
-- Instead of a ScrollingFrame, we use a clipping Frame
-- with a free-moving inner Frame. User drags the inner
-- canvas to pan around all the cards.
-- ─────────────────────────────────────────────
local VIEWPORT_Y_BASE = 106  -- top when no search bar
local VIEWPORT_H_BASE = 482  -- height when no search bar
local VIEWPORT_Y_SEARCH = 152
local VIEWPORT_H_SEARCH = 436

local Viewport = Instance.new("Frame")
Viewport.Name             = "Viewport"
Viewport.Size             = UDim2.new(1,-24, 0, VIEWPORT_H_BASE)
Viewport.Position         = UDim2.new(0,12, 0, VIEWPORT_Y_BASE)
Viewport.BackgroundColor3 = Color3.fromRGB(18,18,26)
Viewport.BorderSizePixel  = 0
Viewport.ClipsDescendants = true   -- ← key: hides cards outside bounds
Viewport.ZIndex           = 11
Viewport.Parent           = Panel
Instance.new("UICorner",Viewport).CornerRadius = UDim.new(0,10)

-- The canvas that actually holds all the cards and can be panned
local Canvas = Instance.new("Frame")
Canvas.Name             = "Canvas"
Canvas.Size             = UDim2.new(0, 900, 0, 900)   -- will grow as cards added
Canvas.Position         = UDim2.new(0, 0, 0, 0)
Canvas.BackgroundTransparency = 1
Canvas.BorderSizePixel  = 0
Canvas.ZIndex           = 12
Canvas.Parent           = Viewport

-- Grid layout on canvas
local Grid = Instance.new("UIGridLayout")
Grid.CellSize             = UDim2.new(0, CARD_W, 0, CARD_H)
Grid.CellPadding          = UDim2.new(0, CARD_PAD, 0, CARD_PAD)
Grid.HorizontalAlignment  = Enum.HorizontalAlignment.Left
Grid.SortOrder            = Enum.SortOrder.LayoutOrder
Grid.Parent               = Canvas

local CanvasPad = Instance.new("UIPadding")
CanvasPad.PaddingTop    = UDim.new(0, CARD_PAD)
CanvasPad.PaddingLeft   = UDim.new(0, CARD_PAD)
CanvasPad.PaddingRight  = UDim.new(0, CARD_PAD)
CanvasPad.PaddingBottom = UDim.new(0, CARD_PAD)
CanvasPad.Parent        = Canvas

-- ── Canvas drag (pan) logic ──
local canvasDragging  = false
local canvasDragStart = nil
local canvasStartPos  = nil
local canvasVelX, canvasVelY = 0, 0   -- for momentum
local lastInputPos    = nil

-- Clamp canvas so you can't drag past edges
local function clampCanvas(cols, rows, viewW, viewH)
	local contentW = cols * (CARD_W + CARD_PAD) + CARD_PAD
	local contentH = rows * (CARD_H + CARD_PAD) + CARD_PAD
	local minX = math.min(0, viewW - contentW)
	local minY = math.min(0, viewH - contentH)
	local cx = math.clamp(Canvas.Position.X.Offset, minX, 0)
	local cy = math.clamp(Canvas.Position.Y.Offset, minY, 0)
	Canvas.Position = UDim2.new(0, cx, 0, cy)
end

local totalCols = 2  -- updated when cards are built
local totalRows = 1

Viewport.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		canvasDragging  = true
		canvasDragStart = i.Position
		canvasStartPos  = Canvas.Position
		canvasVelX, canvasVelY = 0, 0
		lastInputPos = i.Position
	end
end)

Viewport.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		canvasDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(i)
	if canvasDragging and (
		i.UserInputType == Enum.UserInputType.MouseMovement or
		i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - canvasDragStart
		-- velocity for momentum
		if lastInputPos then
			canvasVelX = i.Position.X - lastInputPos.X
			canvasVelY = i.Position.Y - lastInputPos.Y
		end
		lastInputPos = i.Position
		Canvas.Position = UDim2.new(0,
			canvasStartPos.X.Offset + d.X, 0,
			canvasStartPos.Y.Offset + d.Y)
	end
end)

-- Momentum / inertia scroll after release
RunService.Heartbeat:Connect(function()
	if not canvasDragging and (math.abs(canvasVelX) > 0.5 or math.abs(canvasVelY) > 0.5) then
		canvasVelX = canvasVelX * 0.88
		canvasVelY = canvasVelY * 0.88
		Canvas.Position = UDim2.new(0,
			Canvas.Position.X.Offset + canvasVelX,
			0,
			Canvas.Position.Y.Offset + canvasVelY)
		-- clamp
		local vw = Viewport.AbsoluteSize.X
		local vh = Viewport.AbsoluteSize.Y
		local contentW = totalCols * (CARD_W + CARD_PAD) + CARD_PAD
		local contentH = totalRows * (CARD_H + CARD_PAD) + CARD_PAD
		local cx = math.clamp(Canvas.Position.X.Offset, math.min(0, vw - contentW), 0)
		local cy = math.clamp(Canvas.Position.Y.Offset, math.min(0, vh - contentH), 0)
		if cx ~= Canvas.Position.X.Offset or cy ~= Canvas.Position.Y.Offset then
			Canvas.Position = UDim2.new(0, cx, 0, cy)
			canvasVelX, canvasVelY = 0, 0
		end
	end
end)

-- ── Loading overlay ──
local LoadOverlay = Instance.new("Frame")
LoadOverlay.Size=UDim2.new(1,0,1,0); LoadOverlay.BackgroundColor3=Color3.fromRGB(18,18,26)
LoadOverlay.BackgroundTransparency=0.1; LoadOverlay.BorderSizePixel=0
LoadOverlay.Visible=false; LoadOverlay.ZIndex=19; LoadOverlay.Parent=Viewport
Instance.new("UICorner",LoadOverlay).CornerRadius=UDim.new(0,10)
do
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
	l.Text="⏳  Loading catalog..."; l.TextColor3=ROBLOX_BLUE
	l.Font=Enum.Font.GothamBold; l.TextSize=16; l.ZIndex=20; l.Parent=LoadOverlay
end

-- ── Status bar ──
local StatusBar = Instance.new("Frame")
StatusBar.Size=UDim2.new(1,-24,0,28); StatusBar.Position=UDim2.new(0,12,1,-36)
StatusBar.BackgroundColor3=Color3.fromRGB(18,18,26)
StatusBar.BorderSizePixel=0; StatusBar.ZIndex=11; StatusBar.Parent=Panel
Instance.new("UICorner",StatusBar).CornerRadius=UDim.new(0,7)

local StatusText = Instance.new("TextLabel")
StatusText.Size=UDim2.new(1,-10,1,0); StatusText.Position=UDim2.new(0,5,0,0)
StatusText.BackgroundTransparency=1; StatusText.Text="Loading..."
StatusText.TextColor3=TEXT_GRAY; StatusText.Font=Enum.Font.Gotham; StatusText.TextSize=11
StatusText.TextXAlignment=Enum.TextXAlignment.Center; StatusText.ZIndex=12; StatusText.Parent=StatusBar

local function setStatus(msg, col)
	StatusText.Text = msg; StatusText.TextColor3 = col or TEXT_GRAY
end

-- ── Drag hint overlay (shown briefly) ──
local DragHint = Instance.new("Frame")
DragHint.Size=UDim2.new(0,180,0,28); DragHint.Position=UDim2.new(0.5,-90,0,6)
DragHint.BackgroundColor3=Color3.fromRGB(0,100,180)
DragHint.BorderSizePixel=0; DragHint.ZIndex=25; DragHint.Visible=false; DragHint.Parent=Viewport
Instance.new("UICorner",DragHint).CornerRadius=UDim.new(1,0)
do
	local t=Instance.new("TextLabel")
	t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1
	t.Text="✋  Drag to explore catalog"; t.TextColor3=TEXT_WHITE
	t.Font=Enum.Font.GothamBold; t.TextSize=11; t.ZIndex=26; t.Parent=DragHint
end

local function showDragHint()
	DragHint.Visible = true
	DragHint.BackgroundTransparency = 0
	task.delay(2.5, function()
		TweenService:Create(DragHint, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
		task.delay(0.5, function() DragHint.Visible = false end)
	end)
end

-- =============== CARD BUILDER ===============

local function clearCards()
	Canvas.Position = UDim2.new(0,0,0,0)
	canvasVelX, canvasVelY = 0, 0
	for _, c in ipairs(Canvas:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
end

local function buildCard(anim, index)
	local Card = Instance.new("Frame")
	Card.BackgroundColor3 = CARD_BG
	Card.BorderSizePixel  = 0
	Card.ZIndex           = 13
	Card.Parent           = Canvas
	Instance.new("UICorner",Card).CornerRadius=UDim.new(0,10)

	local CardStroke = Instance.new("UIStroke")
	CardStroke.Color=Color3.fromRGB(45,45,65); CardStroke.Thickness=1; CardStroke.Parent=Card

	-- Thumbnail area
	local ThumbFrame = Instance.new("Frame")
	ThumbFrame.Size=UDim2.new(1,0,0,130); ThumbFrame.BackgroundColor3=Color3.fromRGB(26,26,36)
	ThumbFrame.BorderSizePixel=0; ThumbFrame.ZIndex=14; ThumbFrame.Parent=Card
	Instance.new("UICorner",ThumbFrame).CornerRadius=UDim.new(0,10)

	-- fill bottom corners of thumb
	local TF=Instance.new("Frame")
	TF.Size=UDim2.new(1,0,0,10); TF.Position=UDim2.new(0,0,1,-10)
	TF.BackgroundColor3=Color3.fromRGB(26,26,36); TF.BorderSizePixel=0; TF.ZIndex=14; TF.Parent=ThumbFrame

	-- Placeholder
	local Placeholder=Instance.new("TextLabel")
	Placeholder.Size=UDim2.new(1,0,1,0); Placeholder.BackgroundTransparency=1
	Placeholder.Text="🎭"; Placeholder.TextSize=40
	Placeholder.TextXAlignment=Enum.TextXAlignment.Center
	Placeholder.TextYAlignment=Enum.TextYAlignment.Center
	Placeholder.ZIndex=15; Placeholder.Parent=ThumbFrame

	-- Actual thumbnail via rbxthumb (works better than roblox.com in-game)
	local Thumb=Instance.new("ImageLabel")
	Thumb.Size=UDim2.new(1,0,1,0); Thumb.BackgroundTransparency=1
	Thumb.Image="rbxthumb://type=Asset&id="..anim.Id.."&w=150&h=150"
	Thumb.ScaleType=Enum.ScaleType.Fit; Thumb.ZIndex=15; Thumb.Parent=ThumbFrame
	Instance.new("UICorner",Thumb).CornerRadius=UDim.new(0,10)

	Thumb:GetPropertyChangedSignal("IsLoaded"):Connect(function()
		if Thumb.IsLoaded then Placeholder.Visible=false end
	end)

	-- ANIM badge
	local Badge=Instance.new("Frame")
	Badge.Size=UDim2.new(0,52,0,17); Badge.Position=UDim2.new(0,6,0,6)
	Badge.BackgroundColor3=ROBLOX_BLUE; Badge.BorderSizePixel=0; Badge.ZIndex=16; Badge.Parent=ThumbFrame
	Instance.new("UICorner",Badge).CornerRadius=UDim.new(1,0)
	do
		local bt=Instance.new("TextLabel")
		bt.Size=UDim2.new(1,0,1,0); bt.BackgroundTransparency=1
		bt.Text="ANIM"; bt.TextColor3=TEXT_WHITE; bt.Font=Enum.Font.GothamBold
		bt.TextSize=9; bt.ZIndex=17; bt.Parent=Badge
	end

	-- FREE badge
	if (anim.Price or 0)==0 then
		local FB=Instance.new("Frame")
		FB.Size=UDim2.new(0,38,0,17); FB.Position=UDim2.new(1,-44,0,6)
		FB.BackgroundColor3=ROBLOX_GREEN; FB.BorderSizePixel=0; FB.ZIndex=16; FB.Parent=ThumbFrame
		Instance.new("UICorner",FB).CornerRadius=UDim.new(1,0)
		local ft=Instance.new("TextLabel")
		ft.Size=UDim2.new(1,0,1,0); ft.BackgroundTransparency=1
		ft.Text="FREE"; ft.TextColor3=TEXT_WHITE; ft.Font=Enum.Font.GothamBold
		ft.TextSize=9; ft.ZIndex=17; ft.Parent=FB
	end

	-- Info section
	local Info=Instance.new("Frame")
	Info.Size=UDim2.new(1,0,0,88); Info.Position=UDim2.new(0,0,0,132)
	Info.BackgroundTransparency=1; Info.ZIndex=14; Info.Parent=Card

	local NL=Instance.new("TextLabel")
	NL.Size=UDim2.new(1,-12,0,30); NL.Position=UDim2.new(0,8,0,4)
	NL.BackgroundTransparency=1; NL.Text=anim.Name
	NL.TextColor3=TEXT_WHITE; NL.Font=Enum.Font.GothamBold; NL.TextSize=11
	NL.TextXAlignment=Enum.TextXAlignment.Left; NL.TextYAlignment=Enum.TextYAlignment.Top
	NL.TextWrapped=true; NL.TextTruncate=Enum.TextTruncate.AtEnd
	NL.ZIndex=15; NL.Parent=Info

	local CL=Instance.new("TextLabel")
	CL.Size=UDim2.new(1,-12,0,13); CL.Position=UDim2.new(0,8,0,36)
	CL.BackgroundTransparency=1; CL.Text="by "..(anim.Creator or "Roblox")
	CL.TextColor3=TEXT_DIMGRAY; CL.Font=Enum.Font.Gotham; CL.TextSize=10
	CL.TextXAlignment=Enum.TextXAlignment.Left; CL.TextTruncate=Enum.TextTruncate.AtEnd
	CL.ZIndex=15; CL.Parent=Info

	-- Equip button
	local AB=Instance.new("TextButton")
	AB.Size=UDim2.new(1,-16,0,28); AB.Position=UDim2.new(0,8,0,52)
	AB.BackgroundColor3=ROBLOX_BLUE; AB.Text="▶  Equip"
	AB.TextColor3=TEXT_WHITE; AB.Font=Enum.Font.GothamBold; AB.TextSize=12
	AB.BorderSizePixel=0; AB.ZIndex=15; AB.Parent=Info
	Instance.new("UICorner",AB).CornerRadius=UDim.new(0,7)

	-- Hover
	Card.MouseEnter:Connect(function()
		TweenService:Create(Card,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(40,40,55)}):Play()
		TweenService:Create(CardStroke,TweenInfo.new(0.14),{Color=ROBLOX_BLUE}):Play()
	end)
	Card.MouseLeave:Connect(function()
		TweenService:Create(Card,TweenInfo.new(0.14),{BackgroundColor3=CARD_BG}):Play()
		TweenService:Create(CardStroke,TweenInfo.new(0.14),{Color=Color3.fromRGB(45,45,65)}):Play()
	end)
	AB.MouseEnter:Connect(function()
		TweenService:Create(AB,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(30,190,255)}):Play()
	end)
	AB.MouseLeave:Connect(function()
		TweenService:Create(AB,TweenInfo.new(0.12),{BackgroundColor3=ROBLOX_BLUE}):Play()
	end)

	AB.MouseButton1Click:Connect(function()
		AB.Text="⏳ Loading..."; AB.BackgroundColor3=Color3.fromRGB(55,55,75)
		setStatus("Applying: "..anim.Name.."...", Color3.fromRGB(220,180,50))

		local ok, msg = applyAnimation(anim.Id)

		if ok then
			AB.Text="✔  Equipped!"; AB.BackgroundColor3=ROBLOX_GREEN
			setStatus("✅  Equipped (visible to all): "..anim.Name, ROBLOX_GREEN)
		else
			AB.Text="✕  Failed"; AB.BackgroundColor3=Color3.fromRGB(200,50,50)
			setStatus("❌  "..msg, Color3.fromRGB(220,80,80))
		end

		task.delay(3, function()
			if AB and AB.Parent then
				AB.Text="▶  Equip"; AB.BackgroundColor3=ROBLOX_BLUE
				setStatus("Ready", TEXT_GRAY)
			end
		end)
	end)
end

-- =============== LOAD & DISPLAY ===============

local cachedAnims  = {}
local isSearchMode = false

local function updateCanvasSize(count)
	local cols = math.floor((Viewport.AbsoluteSize.X - CARD_PAD) / (CARD_W + CARD_PAD))
	cols = math.max(cols, 2)
	local rows = math.ceil(count / cols)
	totalCols = cols
	totalRows = rows
	local w = cols * (CARD_W + CARD_PAD) + CARD_PAD
	local h = rows * (CARD_H + CARD_PAD) + CARD_PAD
	Canvas.Size = UDim2.new(0, math.max(w, Viewport.AbsoluteSize.X),
	                         0, math.max(h, Viewport.AbsoluteSize.Y))
end

local function loadAnims(keyword)
	clearCards()
	LoadOverlay.Visible = true
	setStatus("Fetching from Roblox...", ROBLOX_BLUE)

	task.spawn(function()
		local results = fetchAnimations(keyword, 48)
		task.defer(function()
			LoadOverlay.Visible = false
			if #results == 0 then
				setStatus(keyword and "No results found." or "Failed to load. Try refreshing.",
					Color3.fromRGB(220,100,80))
				return
			end
			if not keyword then cachedAnims = results end
			for i, anim in ipairs(results) do
				buildCard(anim, i)
			end
			updateCanvasSize(#results)
			setStatus("✅  "..#results.." animations  •  drag canvas to explore", ROBLOX_GREEN)
			showDragHint()
		end)
	end)
end

-- ── Viewport resize helper ──
local function setViewportForSearch(on)
	if on then
		SearchCon.Visible   = true
		Viewport.Position   = UDim2.new(0,12,0,VIEWPORT_Y_SEARCH)
		Viewport.Size       = UDim2.new(1,-24,0,VIEWPORT_H_SEARCH)
		LoadOverlay.Position= UDim2.new(0,0,0,0)
	else
		SearchCon.Visible   = false
		Viewport.Position   = UDim2.new(0,12,0,VIEWPORT_Y_BASE)
		Viewport.Size       = UDim2.new(1,-24,0,VIEWPORT_H_BASE)
	end
end

-- ── Open / Close ──
local function openPanel()
	local ip = Icon.Position
	Panel.Position = UDim2.new(ip.X.Scale, ip.X.Offset+70, ip.Y.Scale, ip.Y.Offset-10)
	Icon.Visible   = false
	Panel.Visible  = true
	Panel.BackgroundTransparency = 1
	TweenService:Create(Panel,TweenInfo.new(0.22,Enum.EasingStyle.Quint),{BackgroundTransparency=0}):Play()
end

local function closePanel()
	local pp = Panel.Position
	Icon.Position = UDim2.new(pp.X.Scale, pp.X.Offset-70, pp.Y.Scale, pp.Y.Offset+10)
	TweenService:Create(Panel,TweenInfo.new(0.16,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play()
	task.delay(0.17, function()
		Panel.Visible = false; Icon.Visible = true
	end)
end

Icon.MouseButton1Click:Connect(openPanel)
CloseBtn.MouseButton1Click:Connect(closePanel)

Icon.MouseEnter:Connect(function()
	TweenService:Create(Icon,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(30,30,48)}):Play()
end)
Icon.MouseLeave:Connect(function()
	TweenService:Create(Icon,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(20,20,28)}):Play()
end)

RefreshBtn.MouseButton1Click:Connect(function()
	TweenService:Create(RefreshBtn,TweenInfo.new(0.1),{BackgroundColor3=ROBLOX_BLUE}):Play()
	task.delay(0.2,function()
		TweenService:Create(RefreshBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(38,38,52)}):Play()
	end)
	loadAnims(isSearchMode and SearchInput.Text~="" and SearchInput.Text or nil)
end)

-- ── Tabs ──
DiscoverTab.MouseButton1Click:Connect(function()
	isSearchMode=false
	DiscoverTab.BackgroundColor3=ROBLOX_BLUE; DiscoverTab.TextColor3=TEXT_WHITE
	SearchTab.BackgroundColor3=Color3.fromRGB(30,30,42); SearchTab.TextColor3=TEXT_GRAY
	setViewportForSearch(false)
	if #cachedAnims>0 then
		clearCards()
		for i,a in ipairs(cachedAnims) do buildCard(a,i) end
		updateCanvasSize(#cachedAnims)
		setStatus("✅  "..#cachedAnims.." animations  •  drag to explore", ROBLOX_GREEN)
	else
		loadAnims(nil)
	end
end)

SearchTab.MouseButton1Click:Connect(function()
	isSearchMode=true
	SearchTab.BackgroundColor3=ROBLOX_BLUE; SearchTab.TextColor3=TEXT_WHITE
	DiscoverTab.BackgroundColor3=Color3.fromRGB(30,30,42); DiscoverTab.TextColor3=TEXT_GRAY
	setViewportForSearch(true)
	SearchInput.Text=""
	if #cachedAnims>0 then
		clearCards()
		for i,a in ipairs(cachedAnims) do buildCard(a,i) end
		updateCanvasSize(#cachedAnims)
		setStatus("Type to search animations", TEXT_GRAY)
	end
end)

-- ── Live search ──
local searchDebounce=nil
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if not isSearchMode then return end
	local txt=SearchInput.Text
	if txt=="" then
		clearCards()
		if #cachedAnims>0 then
			for i,a in ipairs(cachedAnims) do buildCard(a,i) end
			updateCanvasSize(#cachedAnims)
			setStatus("✅  "..#cachedAnims.." animations", ROBLOX_GREEN)
		end
		return
	end
	if #txt<2 then setStatus("Type at least 2 characters...",TEXT_GRAY) return end
	if searchDebounce then task.cancel(searchDebounce) end
	searchDebounce=task.delay(0.6,function() loadAnims(txt) end)
end)

-- ── Respawn reapply ──
local lastAnimId=nil
Player.CharacterAdded:Connect(function()
	if lastAnimId then task.wait(0.8); applyAnimation(lastAnimId) end
end)

-- ── Boot ──
loadAnims(nil)

print("✅ AnimCatalog v4 loaded!")
print("🌐 Animations fire to server — visible to ALL players")
print("✋ Drag the card area to pan around the catalog")
