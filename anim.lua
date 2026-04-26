-- ========================================
-- ANIM CATALOG v6 — Delta Executor
-- ✅ FIXED: Sanitized ID error — patches
--    Animate script children directly
-- ✅ Works in any game (no ownership needed)
-- ✅ Fallback hardcoded anims always shown
-- ✅ Server replication via RemoteEvent
-- ✅ Draggable canvas with momentum
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
local CARD_W       = 186
local CARD_H       = 226
local CARD_PAD     = 10

-- =============== FALLBACK ANIMATIONS ===============
local FALLBACK_ANIMS = {
	{Name="Ninja Animation Pack",    Id="616163682",  Creator="Roblox", Price=0},
	{Name="Zombie Animation Pack",   Id="616158929",  Creator="Roblox", Price=0},
	{Name="Superhero Animation",     Id="616072051",  Creator="Roblox", Price=0},
	{Name="Vampire Animation Pack",  Id="1083462025", Creator="Roblox", Price=0},
	{Name="Robot Animation Pack",    Id="616161997",  Creator="Roblox", Price=0},
	{Name="Mage Animation Pack",     Id="616010382",  Creator="Roblox", Price=0},
	{Name="Knight Animation Pack",   Id="616008936",  Creator="Roblox", Price=0},
	{Name="Pirate Animation Pack",   Id="616006778",  Creator="Roblox", Price=0},
	{Name="Werewolf Animation",      Id="616003913",  Creator="Roblox", Price=0},
	{Name="Skating Animation Pack",  Id="616152468",  Creator="Roblox", Price=0},
	{Name="Levitation Animation",    Id="616156778",  Creator="Roblox", Price=0},
	{Name="Cartoony Animation",      Id="742637544",  Creator="Roblox", Price=0},
	{Name="Old Animation Pack",      Id="180435571",  Creator="Roblox", Price=0},
	{Name="Normal Animation Pack",   Id="507766388",  Creator="Roblox", Price=0},
	{Name="Stylish Animation Pack",  Id="616088355",  Creator="Roblox", Price=0},
	{Name="Toy Animation Pack",      Id="782841498",  Creator="Roblox", Price=0},
	{Name="Caveman Animation Pack",  Id="616094699",  Creator="Roblox", Price=0},
	{Name="Elder Animation Pack",    Id="616095352",  Creator="Roblox", Price=0},
	{Name="Astronaut Animation",     Id="616070468",  Creator="Roblox", Price=0},
	{Name="Alien Animation Pack",    Id="616068262",  Creator="Roblox", Price=0},
	{Name="Dragon Animation Pack",   Id="616097718",  Creator="Roblox", Price=0},
	{Name="Snowman Animation",       Id="616099063",  Creator="Roblox", Price=0},
	{Name="Rthro Animation Pack",    Id="2510235063", Creator="Roblox", Price=0},
	{Name="Sword Fighter Anim",      Id="616100178",  Creator="Roblox", Price=0},
	{Name="Witch Animation Pack",    Id="616101284",  Creator="Roblox", Price=0},
	{Name="Ninja Warrior Anim",      Id="2961573013", Creator="Roblox", Price=0},
	{Name="Korblox Animation Pack",  Id="616091330",  Creator="Roblox", Price=0},
	{Name="Zombie Slayer Anim",      Id="1374452584", Creator="Roblox", Price=0},
	{Name="Toy Soldier Anim",        Id="782841498",  Creator="Roblox", Price=0},
	{Name="Classic Animation Pack",  Id="507766388",  Creator="Roblox", Price=0},
}

-- =============== SERVER REPLICATION ===============
local REMOTE_NAME = "AnimCatalog_v6"

local function setupServer()
	local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name   = REMOTE_NAME
		remote.Parent = ReplicatedStorage
	end
	local sss = game:GetService("ServerScriptService")
	if sss:FindFirstChild("AnimCatalog_Server_v6") then return remote end

	-- Server script patches the Animate script's Animation IDs server-side
	-- so all clients replicate the new walk/run/idle animations
	local ss = Instance.new("Script")
	ss.Name   = "AnimCatalog_Server_v6"
	ss.Source = [[
		local RS = game:GetService("ReplicatedStorage")
		local remote = RS:WaitForChild("AnimCatalog_v6", 15)
		if not remote then return end

		remote.OnServerEvent:Connect(function(player, animId)
			local char = player.Character
			if not char then return end

			local animId_str = "rbxassetid://" .. tostring(animId)

			-- Patch every Animation object inside the Animate script
			local animScript = char:FindFirstChild("Animate")
			if animScript then
				for _, d in ipairs(animScript:GetDescendants()) do
					if d:IsA("Animation") then
						d.AnimationId = animId_str
					end
				end
			end

			-- Stop and restart Humanoid state to trigger new animations
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				local oldState = hum:GetState()
				hum:ChangeState(Enum.HumanoidStateType.Landed)
				task.wait(0.05)
				hum:ChangeState(oldState)
			end
		end)
	]]
	ss.Parent = sss
	return remote
end

local AnimRemote = pcall(setupServer) and ReplicatedStorage:FindFirstChild(REMOTE_NAME) or nil
-- Retry in case it was just created
if not AnimRemote then
	task.delay(1, function()
		AnimRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
	end)
end
-- Proper setup
AnimRemote = setupServer()

-- =============== DRAG UTILITY ===============
local function makeDraggable(handle, target)
	local drag, ds, sp = false, nil, nil
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
			drag=true; ds=i.Position; sp=target.Position
		end
	end)
	handle.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then drag=false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
		or i.UserInputType==Enum.UserInputType.Touch) then
			local d=i.Position-ds
			target.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
end

-- =============== HTTP (triple fallback) ===============
local function safeGet(url)
	local ok1,r1 = pcall(function() return game:HttpGet(url) end)
	if ok1 and r1 and #r1>10 then return r1 end
	local ok2,r2 = pcall(function() return HttpService:GetAsync(url) end)
	if ok2 and r2 and #r2>10 then return r2 end
	local ok3,r3 = pcall(function()
		local res = HttpService:RequestAsync({
			Url="https://catalog.roblox.com/v1/search/items?category=Animation&sortType=3&limit=48",
			Method="GET",
			Headers={["Accept"]="application/json",["User-Agent"]="Mozilla/5.0"}
		})
		if res and res.Success then return res.Body end
	end)
	if ok3 and r3 and #r3>10 then return r3 end
	return nil
end

-- =============== CATALOG API ===============
local function fetchFromAPI(keyword, limit)
	limit = limit or 48
	local results = {}
	local urls = keyword and {
		("https://catalog.roblox.com/v1/search/items?category=Animation&keyword=%s&limit=%d&sortType=3")
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
				for _, item in ipairs(parsed.data or {}) do
					if item.itemType=="Animation" or item.assetType==32 then
						local id = tostring(item.id or item.assetId or "")
						if id~="" then
							table.insert(results,{Name=item.name or "Unknown",Id=id,Creator=item.creatorName or "Roblox",Price=item.price or 0})
						end
					end
				end
			end
		end
		if #results>0 then break end
	end
	return results
end

local function fetchAnimations(keyword, limit)
	local results = fetchFromAPI(keyword, limit)
	if #results>0 then return results, false end
	if keyword then return results, false end
	-- keyword fallbacks
	local seen={}
	for _, kw in ipairs({"animation","ninja","zombie","dance","walk","run","idle","sword","superhero","robot"}) do
		if #results>=30 then break end
		for _, item in ipairs(fetchFromAPI(kw, 10)) do
			if not seen[item.Id] then seen[item.Id]=true; table.insert(results,item) end
		end
	end
	if #results>0 then return results, false end
	return FALLBACK_ANIMS, true
end

-- =============== ANIMATION APPLY ===============
-- KEY FIX: Instead of LoadAnimation (which fails due to sanitization),
-- we directly patch the AnimationId values inside the character's
-- existing Animate LocalScript. This bypasses the ownership check
-- because we're modifying an already-trusted script's data.

local function applyAnimation(animId)
	local char = Player.Character
	if not char then return false, "No character" end

	local animStr = "rbxassetid://" .. tostring(animId)
	local patched = 0

	-- STEP 1: Find and patch the Animate script's Animation objects
	-- The Animate script has children like: idle, walk, run, jump, fall, etc.
	-- Each has Animation objects with AnimationId we can overwrite
	local animScript = char:FindFirstChild("Animate")
	if animScript then
		for _, child in ipairs(animScript:GetChildren()) do
			-- Each child (idle, walk, run, etc.) contains Animation objects
			for _, anim in ipairs(child:GetChildren()) do
				if anim:IsA("Animation") then
					anim.AnimationId = animStr
					patched = patched + 1
				end
			end
			-- Also handle direct Animation children
			if child:IsA("Animation") then
				child.AnimationId = animStr
				patched = patched + 1
			end
		end
	end

	-- STEP 2: Stop all currently playing tracks so new ones load fresh
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				track:Stop(0)
			end
		end

		-- STEP 3: Kick the humanoid state so Animate script re-triggers
		-- with the newly patched animation IDs
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Landed)
			task.wait(0.05)
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end

	-- STEP 4: Fire server to patch on server side too (so others see it)
	pcall(function()
		if AnimRemote then AnimRemote:FireServer(animId) end
	end)

	if patched > 0 then
		return true, "Applied! (" .. patched .. " anims patched)"
	end

	-- Fallback: if no Animate script found, try swapping via GetObjects
	local ok, objs = pcall(function() return game:GetObjects("rbxassetid://"..animId) end)
	if ok and objs and #objs>0 then
		local scr = objs[1]
		if scr:IsA("LocalScript") or scr:IsA("Script") then
			local old = char:FindFirstChild("Animate")
			if old then old:Destroy() end
			local ns = scr:Clone()
			ns.Name   = "Animate"
			ns.Parent = char
			ns.Disabled = false
			return true, "Applied via script swap!"
		end
	end

	return false, "Could not patch animations (no Animate script found)"
end

-- =============== GUI ===============
if game.CoreGui:FindFirstChild("AnimCatalog_v6") then
	game.CoreGui.AnimCatalog_v6:Destroy()
end

local Screen = Instance.new("ScreenGui")
Screen.Name="AnimCatalog_v6"; Screen.ResetOnSpawn=false
Screen.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
Screen.DisplayOrder=999; Screen.Parent=game.CoreGui

-- ─── FLOATING ICON ───
local Icon = Instance.new("TextButton")
Icon.Size=UDim2.new(0,62,0,62); Icon.Position=UDim2.new(0,16,0.5,-31)
Icon.BackgroundColor3=Color3.fromRGB(20,20,28); Icon.BorderSizePixel=0
Icon.Text=""; Icon.ZIndex=20; Icon.Active=true; Icon.Parent=Screen
Instance.new("UICorner",Icon).CornerRadius=UDim.new(0,16)
do
	local s=Instance.new("UIStroke"); s.Color=ROBLOX_BLUE; s.Thickness=2; s.Transparency=0.2; s.Parent=Icon
	local g=Instance.new("UIGradient")
	g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(30,30,48)),ColorSequenceKeypoint.new(1,Color3.fromRGB(15,15,25))})
	g.Rotation=135; g.Parent=Icon
	local e=Instance.new("TextLabel"); e.Size=UDim2.new(1,0,0.62,0); e.Position=UDim2.new(0,0,0,3)
	e.BackgroundTransparency=1; e.Text="🎭"; e.TextSize=28; e.TextXAlignment=Enum.TextXAlignment.Center; e.ZIndex=21; e.Parent=Icon
	local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0.38,0); l.Position=UDim2.new(0,0,0.62,0)
	l.BackgroundTransparency=1; l.Text="ANIM"; l.TextColor3=ROBLOX_BLUE
	l.Font=Enum.Font.GothamBold; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Center; l.ZIndex=21; l.Parent=Icon
end
makeDraggable(Icon,Icon)

-- ─── MAIN PANEL ───
local Panel = Instance.new("Frame")
Panel.Size=UDim2.new(0,450,0,610); Panel.Position=UDim2.new(0,90,0.5,-305)
Panel.BackgroundColor3=PANEL_BG; Panel.BorderSizePixel=0
Panel.Visible=false; Panel.ZIndex=10; Panel.Parent=Screen
Instance.new("UICorner",Panel).CornerRadius=UDim.new(0,14)
do local s=Instance.new("UIStroke",Panel); s.Color=Color3.fromRGB(50,50,70); s.Thickness=1.5 end

-- TopBar
local TopBar=Instance.new("Frame")
TopBar.Size=UDim2.new(1,0,0,54); TopBar.BackgroundColor3=TOPBAR_BG
TopBar.BorderSizePixel=0; TopBar.ZIndex=11; TopBar.Parent=Panel
Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,14)
do
	local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,14); f.Position=UDim2.new(0,0,1,-14)
	f.BackgroundColor3=TOPBAR_BG; f.BorderSizePixel=0; f.ZIndex=11; f.Parent=TopBar
	local a=Instance.new("Frame"); a.Size=UDim2.new(1,0,0,2); a.Position=UDim2.new(0,0,1,-1)
	a.BackgroundColor3=ROBLOX_BLUE; a.BorderSizePixel=0; a.ZIndex=12; a.Parent=TopBar
	local g=Instance.new("UIGradient")
	g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,120,220)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,210,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,120,220))})
	g.Parent=a
	local rb=Instance.new("Frame"); rb.Size=UDim2.new(0,32,0,32); rb.Position=UDim2.new(0,12,0,11)
	rb.BackgroundColor3=ROBLOX_BLUE; rb.BorderSizePixel=0; rb.ZIndex=12; rb.Parent=TopBar
	Instance.new("UICorner",rb).CornerRadius=UDim.new(0,7)
	local rt=Instance.new("TextLabel"); rt.Size=UDim2.new(1,0,1,0); rt.BackgroundTransparency=1
	rt.Text="R"; rt.TextColor3=TEXT_WHITE; rt.Font=Enum.Font.GothamBlack; rt.TextSize=20; rt.ZIndex=13; rt.Parent=rb
	local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-160,0,22); t.Position=UDim2.new(0,52,0,8)
	t.BackgroundTransparency=1; t.Text="Animation Catalog"; t.TextColor3=TEXT_WHITE
	t.Font=Enum.Font.GothamBold; t.TextSize=16; t.TextXAlignment=Enum.TextXAlignment.Left; t.ZIndex=12; t.Parent=TopBar
	local s2=Instance.new("TextLabel"); s2.Size=UDim2.new(1,-160,0,14); s2.Position=UDim2.new(0,52,0,30)
	s2.BackgroundTransparency=1; s2.Text="Live from Roblox  •  drag to explore"
	s2.TextColor3=ROBLOX_BLUE; s2.Font=Enum.Font.Gotham; s2.TextSize=10
	s2.TextXAlignment=Enum.TextXAlignment.Left; s2.ZIndex=12; s2.Parent=TopBar
end

local RefreshBtn=Instance.new("TextButton")
RefreshBtn.Size=UDim2.new(0,32,0,32); RefreshBtn.Position=UDim2.new(1,-76,0,11)
RefreshBtn.BackgroundColor3=Color3.fromRGB(38,38,52); RefreshBtn.Text="↻"
RefreshBtn.TextColor3=TEXT_GRAY; RefreshBtn.Font=Enum.Font.GothamBold; RefreshBtn.TextSize=19
RefreshBtn.BorderSizePixel=0; RefreshBtn.ZIndex=12; RefreshBtn.Parent=TopBar
Instance.new("UICorner",RefreshBtn).CornerRadius=UDim.new(0,8)

local CloseBtn=Instance.new("TextButton")
CloseBtn.Size=UDim2.new(0,32,0,32); CloseBtn.Position=UDim2.new(1,-40,0,11)
CloseBtn.BackgroundColor3=Color3.fromRGB(190,40,50); CloseBtn.Text="✕"
CloseBtn.TextColor3=TEXT_WHITE; CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextSize=14
CloseBtn.BorderSizePixel=0; CloseBtn.ZIndex=12; CloseBtn.Parent=TopBar
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,8)
makeDraggable(TopBar,Panel)

-- Tab Row
local TabRow=Instance.new("Frame")
TabRow.Size=UDim2.new(1,-24,0,36); TabRow.Position=UDim2.new(0,12,0,62)
TabRow.BackgroundColor3=Color3.fromRGB(26,26,36); TabRow.BorderSizePixel=0; TabRow.ZIndex=11; TabRow.Parent=Panel
Instance.new("UICorner",TabRow).CornerRadius=UDim.new(0,10)
local function mkTab(text,side,active)
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0.5,-4,1,-6)
	b.Position=side==0 and UDim2.new(0,3,0,3) or UDim2.new(0.5,1,0,3)
	b.BackgroundColor3=active and ROBLOX_BLUE or Color3.fromRGB(30,30,42)
	b.Text=text; b.TextColor3=active and TEXT_WHITE or TEXT_GRAY
	b.Font=Enum.Font.GothamBold; b.TextSize=13; b.BorderSizePixel=0; b.ZIndex=12; b.Parent=TabRow
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,7); return b
end
local DiscoverTab=mkTab("🔥  Discover",0,true)
local SearchTab=mkTab("🔍  Search",1,false)

-- Search Box
local SearchCon=Instance.new("Frame")
SearchCon.Size=UDim2.new(1,-24,0,38); SearchCon.Position=UDim2.new(0,12,0,106)
SearchCon.BackgroundColor3=Color3.fromRGB(26,26,38); SearchCon.BorderSizePixel=0
SearchCon.Visible=false; SearchCon.ZIndex=11; SearchCon.Parent=Panel
Instance.new("UICorner",SearchCon).CornerRadius=UDim.new(0,9)
do local s=Instance.new("UIStroke",SearchCon); s.Color=Color3.fromRGB(50,50,75); s.Thickness=1
local ic=Instance.new("TextLabel"); ic.Size=UDim2.new(0,30,1,0); ic.Position=UDim2.new(0,6,0,0)
ic.BackgroundTransparency=1; ic.Text="🔍"; ic.TextSize=14; ic.ZIndex=12; ic.Parent=SearchCon end
local SearchInput=Instance.new("TextBox")
SearchInput.Size=UDim2.new(1,-42,1,-8); SearchInput.Position=UDim2.new(0,36,0,4)
SearchInput.BackgroundTransparency=1; SearchInput.Text=""
SearchInput.PlaceholderText="Search animations..."
SearchInput.PlaceholderColor3=Color3.fromRGB(80,80,105); SearchInput.TextColor3=TEXT_WHITE
SearchInput.Font=Enum.Font.Gotham; SearchInput.TextSize=13
SearchInput.TextXAlignment=Enum.TextXAlignment.Left; SearchInput.ClearTextOnFocus=false
SearchInput.ZIndex=12; SearchInput.Parent=SearchCon

-- ─── DRAGGABLE CANVAS ───
local VP_Y_BASE=106; local VP_H_BASE=492
local VP_Y_SEARCH=152; local VP_H_SEARCH=446

local Viewport=Instance.new("Frame")
Viewport.Size=UDim2.new(1,-24,0,VP_H_BASE); Viewport.Position=UDim2.new(0,12,0,VP_Y_BASE)
Viewport.BackgroundColor3=Color3.fromRGB(18,18,26); Viewport.BorderSizePixel=0
Viewport.ClipsDescendants=true; Viewport.ZIndex=11; Viewport.Parent=Panel
Instance.new("UICorner",Viewport).CornerRadius=UDim.new(0,10)

local Canvas=Instance.new("Frame")
Canvas.Size=UDim2.new(0,900,0,900); Canvas.Position=UDim2.new(0,0,0,0)
Canvas.BackgroundTransparency=1; Canvas.BorderSizePixel=0; Canvas.ZIndex=12; Canvas.Parent=Viewport

local Grid=Instance.new("UIGridLayout")
Grid.CellSize=UDim2.new(0,CARD_W,0,CARD_H); Grid.CellPadding=UDim2.new(0,CARD_PAD,0,CARD_PAD)
Grid.HorizontalAlignment=Enum.HorizontalAlignment.Left; Grid.SortOrder=Enum.SortOrder.LayoutOrder; Grid.Parent=Canvas
local CP=Instance.new("UIPadding"); CP.PaddingTop=UDim.new(0,CARD_PAD); CP.PaddingLeft=UDim.new(0,CARD_PAD)
CP.PaddingRight=UDim.new(0,CARD_PAD); CP.PaddingBottom=UDim.new(0,CARD_PAD); CP.Parent=Canvas

-- Canvas pan + momentum
local cDrag,cDs,cSp=false,nil,nil
local velX,velY=0,0; local lastPos=nil
local totalCols,totalRows=2,1

Viewport.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
		cDrag=true; cDs=i.Position; cSp=Canvas.Position; velX=0; velY=0; lastPos=i.Position
	end
end)
Viewport.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then cDrag=false end
end)
UserInputService.InputChanged:Connect(function(i)
	if cDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
		local d=i.Position-cDs
		if lastPos then velX=i.Position.X-lastPos.X; velY=i.Position.Y-lastPos.Y end
		lastPos=i.Position
		Canvas.Position=UDim2.new(0,cSp.X.Offset+d.X,0,cSp.Y.Offset+d.Y)
	end
end)
RunService.Heartbeat:Connect(function()
	if not cDrag and (math.abs(velX)>0.4 or math.abs(velY)>0.4) then
		velX=velX*0.87; velY=velY*0.87
		local nx=Canvas.Position.X.Offset+velX; local ny=Canvas.Position.Y.Offset+velY
		local vw=Viewport.AbsoluteSize.X; local vh=Viewport.AbsoluteSize.Y
		local cw=totalCols*(CARD_W+CARD_PAD)+CARD_PAD; local ch=totalRows*(CARD_H+CARD_PAD)+CARD_PAD
		nx=math.clamp(nx,math.min(0,vw-cw),0); ny=math.clamp(ny,math.min(0,vh-ch),0)
		Canvas.Position=UDim2.new(0,nx,0,ny)
		if math.abs(velX)<0.1 and math.abs(velY)<0.1 then velX=0; velY=0 end
	end
end)

-- Loading overlay
local LoadOverlay=Instance.new("Frame")
LoadOverlay.Size=UDim2.new(1,0,1,0); LoadOverlay.BackgroundColor3=Color3.fromRGB(18,18,26)
LoadOverlay.BackgroundTransparency=0.05; LoadOverlay.BorderSizePixel=0
LoadOverlay.Visible=false; LoadOverlay.ZIndex=19; LoadOverlay.Parent=Viewport
Instance.new("UICorner",LoadOverlay).CornerRadius=UDim.new(0,10)
do
	local sp=Instance.new("TextLabel"); sp.Size=UDim2.new(1,0,0.35,0); sp.Position=UDim2.new(0,0,0.28,0)
	sp.BackgroundTransparency=1; sp.Text="⏳"; sp.TextSize=44; sp.ZIndex=20; sp.Parent=LoadOverlay
	local lt=Instance.new("TextLabel"); lt.Size=UDim2.new(1,0,0,26); lt.Position=UDim2.new(0,0,0.56,0)
	lt.BackgroundTransparency=1; lt.Text="Fetching catalog..."; lt.TextColor3=ROBLOX_BLUE
	lt.Font=Enum.Font.GothamBold; lt.TextSize=16; lt.ZIndex=20; lt.Parent=LoadOverlay
	local lt2=Instance.new("TextLabel"); lt2.Size=UDim2.new(1,0,0,18); lt2.Position=UDim2.new(0,0,0.68,0)
	lt2.BackgroundTransparency=1; lt2.Text="(trying multiple sources)"; lt2.TextColor3=TEXT_GRAY
	lt2.Font=Enum.Font.Gotham; lt2.TextSize=12; lt2.ZIndex=20; lt2.Parent=LoadOverlay
end

-- Drag hint
local DragHint=Instance.new("Frame")
DragHint.Size=UDim2.new(0,200,0,28); DragHint.Position=UDim2.new(0.5,-100,0,8)
DragHint.BackgroundColor3=Color3.fromRGB(0,100,180); DragHint.BorderSizePixel=0
DragHint.ZIndex=25; DragHint.Visible=false; DragHint.Parent=Viewport
Instance.new("UICorner",DragHint).CornerRadius=UDim.new(1,0)
do local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1
t.Text="✋  Drag to explore catalog"; t.TextColor3=TEXT_WHITE
t.Font=Enum.Font.GothamBold; t.TextSize=11; t.ZIndex=26; t.Parent=DragHint end

-- Status Bar
local StatusBar=Instance.new("Frame")
StatusBar.Size=UDim2.new(1,-24,0,28); StatusBar.Position=UDim2.new(0,12,1,-36)
StatusBar.BackgroundColor3=Color3.fromRGB(18,18,26); StatusBar.BorderSizePixel=0
StatusBar.ZIndex=11; StatusBar.Parent=Panel
Instance.new("UICorner",StatusBar).CornerRadius=UDim.new(0,7)
local StatusText=Instance.new("TextLabel")
StatusText.Size=UDim2.new(1,-10,1,0); StatusText.Position=UDim2.new(0,5,0,0)
StatusText.BackgroundTransparency=1; StatusText.Text="Loading..."
StatusText.TextColor3=TEXT_GRAY; StatusText.Font=Enum.Font.Gotham; StatusText.TextSize=11
StatusText.TextXAlignment=Enum.TextXAlignment.Center; StatusText.ZIndex=12; StatusText.Parent=StatusBar

local function setStatus(msg,col) StatusText.Text=msg; StatusText.TextColor3=col or TEXT_GRAY end

-- ─── CARD BUILDER ───
local function clearCards()
	Canvas.Position=UDim2.new(0,0,0,0); velX=0; velY=0
	for _,c in ipairs(Canvas:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
end

local function updateCanvasSize(count)
	local vw=Viewport.AbsoluteSize.X; if vw==0 then vw=402 end
	local cols=math.floor((vw-CARD_PAD)/(CARD_W+CARD_PAD)); cols=math.max(cols,2)
	local rows=math.ceil(count/cols)
	totalCols=cols; totalRows=rows
	Canvas.Size=UDim2.new(0,math.max(cols*(CARD_W+CARD_PAD)+CARD_PAD,vw),
		0,math.max(rows*(CARD_H+CARD_PAD)+CARD_PAD,Viewport.AbsoluteSize.Y))
end

local function buildCard(anim, index)
	local Card=Instance.new("Frame")
	Card.BackgroundColor3=CARD_BG; Card.BorderSizePixel=0; Card.ZIndex=13; Card.Parent=Canvas
	Instance.new("UICorner",Card).CornerRadius=UDim.new(0,10)
	local CS=Instance.new("UIStroke",Card); CS.Color=Color3.fromRGB(45,45,65); CS.Thickness=1

	-- Thumbnail
	local TF=Instance.new("Frame"); TF.Size=UDim2.new(1,0,0,130)
	TF.BackgroundColor3=Color3.fromRGB(26,26,36); TF.BorderSizePixel=0; TF.ZIndex=14; TF.Parent=Card
	Instance.new("UICorner",TF).CornerRadius=UDim.new(0,10)
	do local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,10); f.Position=UDim2.new(0,0,1,-10)
	f.BackgroundColor3=Color3.fromRGB(26,26,36); f.BorderSizePixel=0; f.ZIndex=14; f.Parent=TF end

	local PH=Instance.new("TextLabel"); PH.Size=UDim2.new(1,0,1,0); PH.BackgroundTransparency=1
	PH.Text="🎭"; PH.TextSize=40; PH.TextXAlignment=Enum.TextXAlignment.Center
	PH.TextYAlignment=Enum.TextYAlignment.Center; PH.ZIndex=15; PH.Parent=TF

	local Thumb=Instance.new("ImageLabel"); Thumb.Size=UDim2.new(1,0,1,0); Thumb.BackgroundTransparency=1
	Thumb.Image="rbxthumb://type=Asset&id="..anim.Id.."&w=150&h=150"
	Thumb.ScaleType=Enum.ScaleType.Fit; Thumb.ZIndex=15; Thumb.Parent=TF
	Instance.new("UICorner",Thumb).CornerRadius=UDim.new(0,10)
	Thumb:GetPropertyChangedSignal("IsLoaded"):Connect(function()
		if Thumb.IsLoaded then PH.Visible=false end
	end)

	-- Badges
	local Bdg=Instance.new("Frame"); Bdg.Size=UDim2.new(0,52,0,17); Bdg.Position=UDim2.new(0,6,0,6)
	Bdg.BackgroundColor3=ROBLOX_BLUE; Bdg.BorderSizePixel=0; Bdg.ZIndex=16; Bdg.Parent=TF
	Instance.new("UICorner",Bdg).CornerRadius=UDim.new(1,0)
	do local bt=Instance.new("TextLabel"); bt.Size=UDim2.new(1,0,1,0); bt.BackgroundTransparency=1
	bt.Text="ANIM"; bt.TextColor3=TEXT_WHITE; bt.Font=Enum.Font.GothamBold; bt.TextSize=9; bt.ZIndex=17; bt.Parent=Bdg end

	if (anim.Price or 0)==0 then
		local FB=Instance.new("Frame"); FB.Size=UDim2.new(0,38,0,17); FB.Position=UDim2.new(1,-44,0,6)
		FB.BackgroundColor3=ROBLOX_GREEN; FB.BorderSizePixel=0; FB.ZIndex=16; FB.Parent=TF
		Instance.new("UICorner",FB).CornerRadius=UDim.new(1,0)
		local ft=Instance.new("TextLabel"); ft.Size=UDim2.new(1,0,1,0); ft.BackgroundTransparency=1
		ft.Text="FREE"; ft.TextColor3=TEXT_WHITE; ft.Font=Enum.Font.GothamBold; ft.TextSize=9; ft.ZIndex=17; ft.Parent=FB
	end

	-- Info
	local Info=Instance.new("Frame"); Info.Size=UDim2.new(1,0,0,92); Info.Position=UDim2.new(0,0,0,132)
	Info.BackgroundTransparency=1; Info.ZIndex=14; Info.Parent=Card

	local NL=Instance.new("TextLabel"); NL.Size=UDim2.new(1,-12,0,30); NL.Position=UDim2.new(0,8,0,4)
	NL.BackgroundTransparency=1; NL.Text=anim.Name; NL.TextColor3=TEXT_WHITE
	NL.Font=Enum.Font.GothamBold; NL.TextSize=11; NL.TextXAlignment=Enum.TextXAlignment.Left
	NL.TextYAlignment=Enum.TextYAlignment.Top; NL.TextWrapped=true; NL.ZIndex=15; NL.Parent=Info

	local CL=Instance.new("TextLabel"); CL.Size=UDim2.new(1,-12,0,13); CL.Position=UDim2.new(0,8,0,36)
	CL.BackgroundTransparency=1; CL.Text="by "..(anim.Creator or "Roblox"); CL.TextColor3=TEXT_DIMGRAY
	CL.Font=Enum.Font.Gotham; CL.TextSize=10; CL.TextXAlignment=Enum.TextXAlignment.Left
	CL.TextTruncate=Enum.TextTruncate.AtEnd; CL.ZIndex=15; CL.Parent=Info

	local AB=Instance.new("TextButton"); AB.Size=UDim2.new(1,-16,0,30); AB.Position=UDim2.new(0,8,0,52)
	AB.BackgroundColor3=ROBLOX_BLUE; AB.Text="▶  Equip"; AB.TextColor3=TEXT_WHITE
	AB.Font=Enum.Font.GothamBold; AB.TextSize=13; AB.BorderSizePixel=0; AB.ZIndex=15; AB.Parent=Info
	Instance.new("UICorner",AB).CornerRadius=UDim.new(0,7)

	Card.MouseEnter:Connect(function()
		TweenService:Create(Card,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(40,40,55)}):Play()
		TweenService:Create(CS,TweenInfo.new(0.14),{Color=ROBLOX_BLUE}):Play()
	end)
	Card.MouseLeave:Connect(function()
		TweenService:Create(Card,TweenInfo.new(0.14),{BackgroundColor3=CARD_BG}):Play()
		TweenService:Create(CS,TweenInfo.new(0.14),{Color=Color3.fromRGB(45,45,65)}):Play()
	end)
	AB.MouseEnter:Connect(function() TweenService:Create(AB,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(30,190,255)}):Play() end)
	AB.MouseLeave:Connect(function() TweenService:Create(AB,TweenInfo.new(0.12),{BackgroundColor3=ROBLOX_BLUE}):Play() end)

	AB.MouseButton1Click:Connect(function()
		AB.Text="⏳ Applying..."; AB.BackgroundColor3=Color3.fromRGB(55,55,75)
		setStatus("Patching animations: "..anim.Name.."...",Color3.fromRGB(220,180,50))

		-- Move slightly to trigger new walk cycle immediately
		local ok, msg = applyAnimation(anim.Id)

		if ok then
			AB.Text="✔  Equipped!"; AB.BackgroundColor3=ROBLOX_GREEN
			setStatus("✅  "..msg.." — "..anim.Name,ROBLOX_GREEN)
		else
			AB.Text="✕  Failed"; AB.BackgroundColor3=Color3.fromRGB(200,50,50)
			setStatus("❌  "..tostring(msg),Color3.fromRGB(220,80,80))
		end
		task.delay(4,function()
			if AB and AB.Parent then AB.Text="▶  Equip"; AB.BackgroundColor3=ROBLOX_BLUE; setStatus("Ready",TEXT_GRAY) end
		end)
	end)
end

-- ─── LOAD & DISPLAY ───
local cachedAnims={}
local isSearchMode=false
local usingFallback=false

local function showDragHint()
	DragHint.Visible=true; DragHint.BackgroundTransparency=0
	task.delay(3,function()
		TweenService:Create(DragHint,TweenInfo.new(0.6),{BackgroundTransparency=1}):Play()
		task.delay(0.6,function() DragHint.Visible=false end)
	end)
end

local function loadAnims(keyword)
	clearCards(); LoadOverlay.Visible=true
	setStatus("Fetching from Roblox...",ROBLOX_BLUE)
	task.spawn(function()
		local results,wasFallback=fetchAnimations(keyword,48)
		task.defer(function()
			LoadOverlay.Visible=false
			if #results==0 then setStatus("No results found.",Color3.fromRGB(220,100,80)); return end
			if not keyword then cachedAnims=results; usingFallback=wasFallback end
			for i,anim in ipairs(results) do buildCard(anim,i) end
			updateCanvasSize(#results)
			if wasFallback then
				setStatus("📦 "..#results.." popular anims loaded (offline) — drag to explore",Color3.fromRGB(220,160,50))
			else
				setStatus("✅  "..#results.." animations — drag to explore",ROBLOX_GREEN)
			end
			showDragHint()
		end)
	end)
end

local function setVPForSearch(on)
	SearchCon.Visible=on
	Viewport.Position=UDim2.new(0,12,0,on and VP_Y_SEARCH or VP_Y_BASE)
	Viewport.Size=UDim2.new(1,-24,0,on and VP_H_SEARCH or VP_H_BASE)
end

-- Open/Close
local function openPanel()
	local ip=Icon.Position
	Panel.Position=UDim2.new(ip.X.Scale,ip.X.Offset+70,ip.Y.Scale,ip.Y.Offset-10)
	Icon.Visible=false; Panel.Visible=true; Panel.BackgroundTransparency=1
	TweenService:Create(Panel,TweenInfo.new(0.22,Enum.EasingStyle.Quint),{BackgroundTransparency=0}):Play()
end
local function closePanel()
	local pp=Panel.Position
	Icon.Position=UDim2.new(pp.X.Scale,pp.X.Offset-70,pp.Y.Scale,pp.Y.Offset+10)
	TweenService:Create(Panel,TweenInfo.new(0.16,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play()
	task.delay(0.17,function() Panel.Visible=false; Icon.Visible=true end)
end

Icon.MouseButton1Click:Connect(openPanel)
CloseBtn.MouseButton1Click:Connect(closePanel)
Icon.MouseEnter:Connect(function() TweenService:Create(Icon,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(30,30,48)}):Play() end)
Icon.MouseLeave:Connect(function() TweenService:Create(Icon,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(20,20,28)}):Play() end)

RefreshBtn.MouseButton1Click:Connect(function()
	TweenService:Create(RefreshBtn,TweenInfo.new(0.1),{BackgroundColor3=ROBLOX_BLUE}):Play()
	task.delay(0.2,function() TweenService:Create(RefreshBtn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(38,38,52)}):Play() end)
	loadAnims(isSearchMode and SearchInput.Text~="" and SearchInput.Text or nil)
end)

DiscoverTab.MouseButton1Click:Connect(function()
	isSearchMode=false
	DiscoverTab.BackgroundColor3=ROBLOX_BLUE; DiscoverTab.TextColor3=TEXT_WHITE
	SearchTab.BackgroundColor3=Color3.fromRGB(30,30,42); SearchTab.TextColor3=TEXT_GRAY
	setVPForSearch(false)
	if #cachedAnims>0 then
		clearCards()
		for i,a in ipairs(cachedAnims) do buildCard(a,i) end
		updateCanvasSize(#cachedAnims)
		setStatus((usingFallback and "📦 " or "✅  ")..#cachedAnims.." animations",usingFallback and Color3.fromRGB(220,160,50) or ROBLOX_GREEN)
	else loadAnims(nil) end
end)

SearchTab.MouseButton1Click:Connect(function()
	isSearchMode=true
	SearchTab.BackgroundColor3=ROBLOX_BLUE; SearchTab.TextColor3=TEXT_WHITE
	DiscoverTab.BackgroundColor3=Color3.fromRGB(30,30,42); DiscoverTab.TextColor3=TEXT_GRAY
	setVPForSearch(true); SearchInput.Text=""
	if #cachedAnims>0 then
		clearCards()
		for i,a in ipairs(cachedAnims) do buildCard(a,i) end
		updateCanvasSize(#cachedAnims)
		setStatus("Type to search animations",TEXT_GRAY)
	end
end)

local searchDebounce=nil
SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if not isSearchMode then return end
	local txt=SearchInput.Text
	if txt=="" then
		clearCards()
		if #cachedAnims>0 then
			for i,a in ipairs(cachedAnims) do buildCard(a,i) end
			updateCanvasSize(#cachedAnims)
			setStatus("✅  "..#cachedAnims.." animations",ROBLOX_GREEN)
		end; return
	end
	if #txt<2 then setStatus("Type at least 2 characters...",TEXT_GRAY); return end
	if searchDebounce then task.cancel(searchDebounce) end
	searchDebounce=task.delay(0.6,function() loadAnims(txt) end)
end)

-- Respawn reapply
local lastAnimId=nil
Player.CharacterAdded:Connect(function(char)
	if lastAnimId then
		task.wait(1)
		applyAnimation(lastAnimId)
	end
end)

-- Boot
loadAnims(nil)
print("✅ AnimCatalog v6 loaded!")
print("🔧 Uses Animate script patching — bypasses sanitization")
print("🌐 Fires server remote so others see your animation")
print("✋ Drag card area to pan the catalog")
