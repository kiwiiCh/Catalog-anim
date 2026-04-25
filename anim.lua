-- ========================================
-- DELTA EXECUTOR COMPATIBLE SCRIPT
-- Live Roblox Catalog Animation Search
-- Collapsible Icon → GUI with drag support
-- Execute this ENTIRE script in Delta Executor
-- ========================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- =============== CATALOG FETCH METHODS ===============

local function fetchDefaultAnimations()
	local results = {}

	local endpoints = {
		"https://catalog.roblox.com/v1/search/items?category=Animation&sortType=3&limit=50",
		"https://catalog.roblox.com/v1/search/items?category=Animation&limit=40",
		"https://search.roblox.com/catalog/json?Category=6&SortType=3&ResultsPerPage=50",
	}

	for _, endpoint in ipairs(endpoints) do
		local success, data = pcall(function()
			return game:HttpGet(endpoint)
		end)

		if success and data then
			local success2, parsed = pcall(function()
				return HttpService:JSONDecode(data)
			end)

			if success2 and parsed then
				if parsed.data then
					for _, item in ipairs(parsed.data) do
						if item.itemType == "Animation" or item.assetType == 32 then
							table.insert(results, {
								Name = item.name,
								Id = tostring(item.id or item.assetId),
								Creator = item.creatorName or "Unknown",
								Price = item.price or 0
							})
						end
					end
				elseif parsed.Results then
					for _, item in ipairs(parsed.Results) do
						if item.AssetTypeId == 32 then
							table.insert(results, {
								Name = item.Name,
								Id = tostring(item.AssetId),
								Creator = item.CreatorName or "Unknown",
								Price = item.Price or 0
							})
						end
					end
				end
			end
		end

		if #results > 0 then break end
	end

	if #results == 0 then
		local commonSearches = {"animation", "run", "walk", "ninja", "zombie", "cartoon"}
		for _, keyword in ipairs(commonSearches) do
			if #results >= 30 then break end

			local success, data = pcall(function()
				return game:HttpGet("https://catalog.roblox.com/v1/search/items?category=Animation&keyword=" .. keyword .. "&limit=10")
			end)

			if success and data then
				local success2, parsed = pcall(function()
					return HttpService:JSONDecode(data)
				end)

				if success2 and parsed and parsed.data then
					for _, item in ipairs(parsed.data) do
						if item.itemType == "Animation" then
							local isDuplicate = false
							for _, existing in ipairs(results) do
								if existing.Id == tostring(item.id) then
									isDuplicate = true
									break
								end
							end
							if not isDuplicate then
								table.insert(results, {
									Name = item.name,
									Id = tostring(item.id),
									Creator = item.creatorName or "Unknown",
									Price = item.price or 0
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

local function searchCatalogAPI(keyword, pageLimit)
	local results = {}

	local endpoints = {
		"https://catalog.roblox.com/v1/search/items?category=Animation&keyword=" .. HttpService:UrlEncode(keyword) .. "&limit=" .. tostring(pageLimit or 30),
		"https://search.roblox.com/catalog/json?Category=6&Keyword=" .. HttpService:UrlEncode(keyword) .. "&ResultsPerPage=" .. tostring(pageLimit or 30),
	}

	for _, endpoint in ipairs(endpoints) do
		local success, data = pcall(function()
			return game:HttpGet(endpoint)
		end)

		if success and data then
			local success2, parsed = pcall(function()
				return HttpService:JSONDecode(data)
			end)

			if success2 and parsed then
				if parsed.data then
					for _, item in ipairs(parsed.data) do
						if item.itemType == "Animation" or item.assetType == 32 then
							table.insert(results, {
								Name = item.name,
								Id = tostring(item.id or item.assetId),
								Creator = item.creatorName or "Unknown",
								Price = item.price or 0
							})
						end
					end
				elseif parsed.Results then
					for _, item in ipairs(parsed.Results) do
						if item.AssetTypeId == 32 then
							table.insert(results, {
								Name = item.Name,
								Id = tostring(item.AssetId),
								Creator = item.CreatorName or "Unknown",
								Price = item.Price or 0
							})
						end
					end
				end
			end
		end

		if #results > 0 then break end
	end

	return results
end

-- =============== DRAG UTILITY ===============

local function makeDraggable(dragHandle, dragTarget)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = dragTarget.Position
		end
	end)

	dragHandle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
			local delta = input.Position - dragStart
			dragTarget.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- =============== GUI CREATION ===============

local function createGUI()
	if game.CoreGui:FindFirstChild("AnimCatalog_Delta") then
		game.CoreGui.AnimCatalog_Delta:Destroy()
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AnimCatalog_Delta"
	ScreenGui.Parent = game.CoreGui
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 999

	-- ========================
	-- FLOATING ICON (collapsed state)
	-- ========================
	local IconBtn = Instance.new("TextButton")
	IconBtn.Name = "IconBtn"
	IconBtn.Size = UDim2.new(0, 58, 0, 58)
	IconBtn.Position = UDim2.new(0, 20, 0.5, -29)
	IconBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
	IconBtn.BorderSizePixel = 0
	IconBtn.Text = ""
	IconBtn.ZIndex = 10
	IconBtn.Parent = ScreenGui
	IconBtn.Active = true

	Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(0, 14)

	-- Icon glow stroke
	local IconStroke = Instance.new("UIStroke")
	IconStroke.Color = Color3.fromRGB(80, 200, 120)
	IconStroke.Thickness = 2
	IconStroke.Transparency = 0.3
	IconStroke.Parent = IconBtn

	-- Gradient on icon
	local IconGrad = Instance.new("UIGradient")
	IconGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 35))
	})
	IconGrad.Rotation = 135
	IconGrad.Parent = IconBtn

	-- Icon emoji label
	local IconEmoji = Instance.new("TextLabel")
	IconEmoji.Size = UDim2.new(1, 0, 0.65, 0)
	IconEmoji.Position = UDim2.new(0, 0, 0, 4)
	IconEmoji.BackgroundTransparency = 1
	IconEmoji.Text = "🎭"
	IconEmoji.TextSize = 26
	IconEmoji.TextXAlignment = Enum.TextXAlignment.Center
	IconEmoji.TextYAlignment = Enum.TextYAlignment.Center
	IconEmoji.ZIndex = 11
	IconEmoji.Parent = IconBtn

	-- Icon sub-label
	local IconSub = Instance.new("TextLabel")
	IconSub.Size = UDim2.new(1, 0, 0.38, 0)
	IconSub.Position = UDim2.new(0, 0, 0.62, 0)
	IconSub.BackgroundTransparency = 1
	IconSub.Text = "ANIM"
	IconSub.TextColor3 = Color3.fromRGB(80, 200, 120)
	IconSub.Font = Enum.Font.GothamBold
	IconSub.TextSize = 9
	IconSub.TextXAlignment = Enum.TextXAlignment.Center
	IconSub.ZIndex = 11
	IconSub.Parent = IconBtn

	-- Make icon draggable
	makeDraggable(IconBtn, IconBtn)

	-- ========================
	-- MAIN GUI FRAME (expanded state)
	-- ========================
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 430, 0, 560)
	MainFrame.Position = UDim2.new(0, 20, 0.5, -280)
	MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	MainFrame.BorderSizePixel = 0
	MainFrame.Visible = false
	MainFrame.ZIndex = 5
	MainFrame.Parent = ScreenGui

	Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

	-- Outer stroke/border on main frame
	local FrameStroke = Instance.new("UIStroke")
	FrameStroke.Color = Color3.fromRGB(55, 55, 80)
	FrameStroke.Thickness = 1.5
	FrameStroke.Transparency = 0
	FrameStroke.Parent = MainFrame

	-- Background gradient
	local BgGrad = Instance.new("UIGradient")
	BgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 22))
	})
	BgGrad.Rotation = 160
	BgGrad.Parent = MainFrame

	-- ── Title Bar ──
	local TitleBar = Instance.new("Frame")
	TitleBar.Size = UDim2.new(1, 0, 0, 50)
	TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	TitleBar.BorderSizePixel = 0
	TitleBar.ZIndex = 6
	TitleBar.Parent = MainFrame

	Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

	-- Fix bottom corners of title bar
	local TitleBarFix = Instance.new("Frame")
	TitleBarFix.Size = UDim2.new(1, 0, 0, 14)
	TitleBarFix.Position = UDim2.new(0, 0, 1, -14)
	TitleBarFix.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	TitleBarFix.BorderSizePixel = 0
	TitleBarFix.ZIndex = 6
	TitleBarFix.Parent = TitleBar

	-- Title accent line
	local AccentLine = Instance.new("Frame")
	AccentLine.Size = UDim2.new(1, 0, 0, 2)
	AccentLine.Position = UDim2.new(0, 0, 1, -1)
	AccentLine.BackgroundColor3 = Color3.fromRGB(70, 200, 110)
	AccentLine.BorderSizePixel = 0
	AccentLine.ZIndex = 7
	AccentLine.Parent = TitleBar

	local AccentLineGrad = Instance.new("UIGradient")
	AccentLineGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 200, 110)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 220, 180)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 200, 110))
	})
	AccentLineGrad.Parent = AccentLine

	-- Title icon + text
	local TitleIconLabel = Instance.new("TextLabel")
	TitleIconLabel.Size = UDim2.new(0, 34, 1, 0)
	TitleIconLabel.Position = UDim2.new(0, 14, 0, 0)
	TitleIconLabel.BackgroundTransparency = 1
	TitleIconLabel.Text = "🎭"
	TitleIconLabel.TextSize = 22
	TitleIconLabel.TextXAlignment = Enum.TextXAlignment.Center
	TitleIconLabel.ZIndex = 7
	TitleIconLabel.Parent = TitleBar

	local TitleText = Instance.new("TextLabel")
	TitleText.Size = UDim2.new(1, -130, 1, 0)
	TitleText.Position = UDim2.new(0, 52, 0, 0)
	TitleText.BackgroundTransparency = 1
	TitleText.Text = "Anim Catalog"
	TitleText.TextColor3 = Color3.fromRGB(240, 240, 255)
	TitleText.Font = Enum.Font.GothamBold
	TitleText.TextSize = 17
	TitleText.TextXAlignment = Enum.TextXAlignment.Left
	TitleText.ZIndex = 7
	TitleText.Parent = TitleBar

	local TitleSub = Instance.new("TextLabel")
	TitleSub.Size = UDim2.new(1, -130, 0, 14)
	TitleSub.Position = UDim2.new(0, 52, 0, 29)
	TitleSub.BackgroundTransparency = 1
	TitleSub.Text = "Live Roblox Catalog"
	TitleSub.TextColor3 = Color3.fromRGB(80, 200, 120)
	TitleSub.Font = Enum.Font.Gotham
	TitleSub.TextSize = 10
	TitleSub.TextXAlignment = Enum.TextXAlignment.Left
	TitleSub.ZIndex = 7
	TitleSub.Parent = TitleBar

	-- Refresh button
	local RefreshBtn = Instance.new("TextButton")
	RefreshBtn.Size = UDim2.new(0, 32, 0, 32)
	RefreshBtn.Position = UDim2.new(1, -77, 0, 9)
	RefreshBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
	RefreshBtn.Text = "↻"
	RefreshBtn.TextColor3 = Color3.fromRGB(180, 180, 210)
	RefreshBtn.Font = Enum.Font.GothamBold
	RefreshBtn.TextSize = 18
	RefreshBtn.BorderSizePixel = 0
	RefreshBtn.ZIndex = 8
	RefreshBtn.Parent = TitleBar

	Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 8)

	-- Close (X) button — collapses back to icon
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.new(0, 32, 0, 32)
	CloseBtn.Position = UDim2.new(1, -40, 0, 9)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 55)
	CloseBtn.Text = "✕"
	CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 14
	CloseBtn.BorderSizePixel = 0
	CloseBtn.ZIndex = 8
	CloseBtn.Parent = TitleBar

	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

	-- Make the main frame draggable via its title bar
	makeDraggable(TitleBar, MainFrame)

	-- ── Tab Row ──
	local TabFrame = Instance.new("Frame")
	TabFrame.Size = UDim2.new(1, -24, 0, 36)
	TabFrame.Position = UDim2.new(0, 12, 0, 58)
	TabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
	TabFrame.BorderSizePixel = 0
	TabFrame.ZIndex = 6
	TabFrame.Parent = MainFrame

	Instance.new("UICorner", TabFrame).CornerRadius = UDim.new(0, 8)

	local DiscoverTab = Instance.new("TextButton")
	DiscoverTab.Size = UDim2.new(0.5, -4, 1, -6)
	DiscoverTab.Position = UDim2.new(0, 3, 0, 3)
	DiscoverTab.BackgroundColor3 = Color3.fromRGB(55, 170, 90)
	DiscoverTab.Text = "🔥  Discover"
	DiscoverTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	DiscoverTab.Font = Enum.Font.GothamBold
	DiscoverTab.TextSize = 13
	DiscoverTab.BorderSizePixel = 0
	DiscoverTab.ZIndex = 7
	DiscoverTab.Parent = TabFrame

	Instance.new("UICorner", DiscoverTab).CornerRadius = UDim.new(0, 6)

	local SearchTab = Instance.new("TextButton")
	SearchTab.Size = UDim2.new(0.5, -4, 1, -6)
	SearchTab.Position = UDim2.new(0.5, 1, 0, 3)
	SearchTab.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
	SearchTab.Text = "🔍  Search"
	SearchTab.TextColor3 = Color3.fromRGB(160, 160, 185)
	SearchTab.Font = Enum.Font.GothamBold
	SearchTab.TextSize = 13
	SearchTab.BorderSizePixel = 0
	SearchTab.ZIndex = 7
	SearchTab.Parent = TabFrame

	Instance.new("UICorner", SearchTab).CornerRadius = UDim.new(0, 6)

	-- ── Search Box (hidden until Search tab) ──
	local SearchContainer = Instance.new("Frame")
	SearchContainer.Size = UDim2.new(1, -24, 0, 38)
	SearchContainer.Position = UDim2.new(0, 12, 0, 102)
	SearchContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	SearchContainer.BorderSizePixel = 0
	SearchContainer.Visible = false
	SearchContainer.ZIndex = 6
	SearchContainer.Parent = MainFrame

	Instance.new("UICorner", SearchContainer).CornerRadius = UDim.new(0, 8)

	local SearchStroke = Instance.new("UIStroke")
	SearchStroke.Color = Color3.fromRGB(55, 55, 80)
	SearchStroke.Thickness = 1
	SearchStroke.Parent = SearchContainer

	local SearchIcon = Instance.new("TextLabel")
	SearchIcon.Size = UDim2.new(0, 30, 1, 0)
	SearchIcon.Position = UDim2.new(0, 6, 0, 0)
	SearchIcon.BackgroundTransparency = 1
	SearchIcon.Text = "🔍"
	SearchIcon.TextSize = 14
	SearchIcon.TextXAlignment = Enum.TextXAlignment.Center
	SearchIcon.ZIndex = 8
	SearchIcon.Parent = SearchContainer

	local SearchBox = Instance.new("TextBox")
	SearchBox.Size = UDim2.new(1, -44, 1, -8)
	SearchBox.Position = UDim2.new(0, 36, 0, 4)
	SearchBox.BackgroundTransparency = 1
	SearchBox.Text = ""
	SearchBox.PlaceholderText = "Type animation name..."
	SearchBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 115)
	SearchBox.TextColor3 = Color3.fromRGB(220, 220, 240)
	SearchBox.Font = Enum.Font.Gotham
	SearchBox.TextSize = 13
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	SearchBox.ClearTextOnFocus = false
	SearchBox.ZIndex = 8
	SearchBox.Parent = SearchContainer

	-- ── Results Scroll ──
	local ResultsScroll = Instance.new("ScrollingFrame")
	ResultsScroll.Size = UDim2.new(1, -24, 0, 360)
	ResultsScroll.Position = UDim2.new(0, 12, 0, 102)
	ResultsScroll.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
	ResultsScroll.BorderSizePixel = 0
	ResultsScroll.ScrollBarThickness = 4
	ResultsScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 170, 100)
	ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ResultsScroll.ZIndex = 6
	ResultsScroll.Parent = MainFrame

	Instance.new("UICorner", ResultsScroll).CornerRadius = UDim.new(0, 8)

	local ResultsList = Instance.new("UIListLayout")
	ResultsList.Padding = UDim.new(0, 5)
	ResultsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ResultsList.SortOrder = Enum.SortOrder.LayoutOrder
	ResultsList.Parent = ResultsScroll

	local ResultsPadding = Instance.new("UIPadding")
	ResultsPadding.PaddingTop = UDim.new(0, 6)
	ResultsPadding.PaddingBottom = UDim.new(0, 6)
	ResultsPadding.Parent = ResultsScroll

	-- ── Status Bar ──
	local StatusBar = Instance.new("Frame")
	StatusBar.Size = UDim2.new(1, -24, 0, 32)
	StatusBar.Position = UDim2.new(0, 12, 0, 472)
	StatusBar.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
	StatusBar.BorderSizePixel = 0
	StatusBar.ZIndex = 6
	StatusBar.Parent = MainFrame

	Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 8)

	local StatusLabel = Instance.new("TextLabel")
	StatusLabel.Size = UDim2.new(1, -12, 1, 0)
	StatusLabel.Position = UDim2.new(0, 6, 0, 0)
	StatusLabel.BackgroundTransparency = 1
	StatusLabel.Text = "Loading catalog..."
	StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 175)
	StatusLabel.Font = Enum.Font.Gotham
	StatusLabel.TextSize = 11
	StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
	StatusLabel.ZIndex = 7
	StatusLabel.Parent = StatusBar

	-- ── Loading Overlay ──
	local LoadingOverlay = Instance.new("Frame")
	LoadingOverlay.Size = UDim2.new(1, -24, 0, 360)
	LoadingOverlay.Position = UDim2.new(0, 12, 0, 102)
	LoadingOverlay.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	LoadingOverlay.BackgroundTransparency = 0.25
	LoadingOverlay.BorderSizePixel = 0
	LoadingOverlay.Visible = false
	LoadingOverlay.ZIndex = 9
	LoadingOverlay.Parent = MainFrame

	Instance.new("UICorner", LoadingOverlay).CornerRadius = UDim.new(0, 8)

	local LoadingLabel = Instance.new("TextLabel")
	LoadingLabel.Size = UDim2.new(1, 0, 1, 0)
	LoadingLabel.BackgroundTransparency = 1
	LoadingLabel.Text = "⏳\nFetching from Roblox..."
	LoadingLabel.TextColor3 = Color3.fromRGB(80, 200, 130)
	LoadingLabel.Font = Enum.Font.GothamBold
	LoadingLabel.TextSize = 16
	LoadingLabel.TextWrapped = true
	LoadingLabel.ZIndex = 10
	LoadingLabel.Parent = LoadingOverlay

	return {
		GUI = ScreenGui,
		IconBtn = IconBtn,
		MainFrame = MainFrame,
		TitleBar = TitleBar,
		CloseBtn = CloseBtn,
		RefreshBtn = RefreshBtn,
		DiscoverTab = DiscoverTab,
		SearchTab = SearchTab,
		SearchContainer = SearchContainer,
		SearchBox = SearchBox,
		ResultsScroll = ResultsScroll,
		StatusLabel = StatusLabel,
		LoadingOverlay = LoadingOverlay,
	}
end

-- =============== ANIMATION APPLICATION ===============

local function applyAnimationFE(assetId, animName)
	local character = Player.Character
	if not character then return false, "No character found" end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return false, "No humanoid found" end

	-- Method 1: InsertService
	local success, result = pcall(function()
		return game:GetService("InsertService"):LoadAsset(tonumber(assetId))
	end)

	if success and result then
		local oldAnimate = character:FindFirstChild("Animate")
		if oldAnimate then oldAnimate:Destroy() end

		local animScript = result:FindFirstChildWhichIsA("Script") or result:FindFirstChildWhichIsA("LocalScript")
		if animScript then
			local newScript = Instance.new("Script")
			newScript.Name = "Animate"
			newScript.Source = animScript.Source
			newScript.Parent = character
			result:Destroy()
			return true, "Applied"
		end
		result:Destroy()
	end

	-- Method 2: GetObjects
	local success2, result2 = pcall(function()
		return game:GetObjects("rbxassetid://" .. assetId)
	end)

	if success2 and result2 and #result2 > 0 then
		local oldAnimate = character:FindFirstChild("Animate")
		if oldAnimate then oldAnimate:Destroy() end

		local animScript = result2[1]
		if animScript:IsA("Script") or animScript:IsA("LocalScript") then
			local newScript = Instance.new("Script")
			newScript.Name = "Animate"
			newScript.Source = animScript.Source
			newScript.Parent = character
			return true, "Applied"
		end
	end

	return false, "Failed to load"
end

-- =============== RESULTS DISPLAY ===============

local function clearResults(scrollFrame)
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function displayResults(results, scrollFrame, statusLabel, isSearch)
	if #results == 0 then
		statusLabel.Text = isSearch and "No results found — try different keywords." or "Couldn't load catalog. Try refreshing."
		statusLabel.TextColor3 = Color3.fromRGB(200, 120, 80)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	for i, anim in ipairs(results) do
		local ItemFrame = Instance.new("Frame")
		ItemFrame.Size = UDim2.new(1, -14, 0, 66)
		ItemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
		ItemFrame.BorderSizePixel = 0
		ItemFrame.ZIndex = 7
		ItemFrame.Parent = scrollFrame

		Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 8)

		local ItemStroke = Instance.new("UIStroke")
		ItemStroke.Color = Color3.fromRGB(45, 45, 68)
		ItemStroke.Thickness = 1
		ItemStroke.Parent = ItemFrame

		-- Left accent bar
		local AccentBar = Instance.new("Frame")
		AccentBar.Size = UDim2.new(0, 3, 1, -16)
		AccentBar.Position = UDim2.new(0, 0, 0, 8)
		AccentBar.BackgroundColor3 = Color3.fromRGB(60, 185, 100)
		AccentBar.BorderSizePixel = 0
		AccentBar.ZIndex = 8
		AccentBar.Parent = ItemFrame

		Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(1, 0)

		-- Name
		local NameLabel = Instance.new("TextLabel")
		NameLabel.Size = UDim2.new(1, -108, 0, 22)
		NameLabel.Position = UDim2.new(0, 16, 0, 8)
		NameLabel.BackgroundTransparency = 1
		NameLabel.Text = anim.Name
		NameLabel.TextColor3 = Color3.fromRGB(230, 230, 250)
		NameLabel.Font = Enum.Font.GothamBold
		NameLabel.TextSize = 13
		NameLabel.TextXAlignment = Enum.TextXAlignment.Left
		NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		NameLabel.ZIndex = 8
		NameLabel.Parent = ItemFrame

		-- Creator
		local CreatorLabel = Instance.new("TextLabel")
		CreatorLabel.Size = UDim2.new(1, -108, 0, 15)
		CreatorLabel.Position = UDim2.new(0, 16, 0, 30)
		CreatorLabel.BackgroundTransparency = 1
		CreatorLabel.Text = "👤  " .. (anim.Creator or "Roblox")
		CreatorLabel.TextColor3 = Color3.fromRGB(100, 100, 135)
		CreatorLabel.Font = Enum.Font.Gotham
		CreatorLabel.TextSize = 10
		CreatorLabel.TextXAlignment = Enum.TextXAlignment.Left
		CreatorLabel.ZIndex = 8
		CreatorLabel.Parent = ItemFrame

		-- ID
		local IDLabel = Instance.new("TextLabel")
		IDLabel.Size = UDim2.new(1, -108, 0, 14)
		IDLabel.Position = UDim2.new(0, 16, 0, 46)
		IDLabel.BackgroundTransparency = 1
		IDLabel.Text = "ID: " .. anim.Id
		IDLabel.TextColor3 = Color3.fromRGB(70, 70, 100)
		IDLabel.Font = Enum.Font.Gotham
		IDLabel.TextSize = 9
		IDLabel.TextXAlignment = Enum.TextXAlignment.Left
		IDLabel.ZIndex = 8
		IDLabel.Parent = ItemFrame

		-- Apply button
		local ApplyBtn = Instance.new("TextButton")
		ApplyBtn.Size = UDim2.new(0, 82, 0, 46)
		ApplyBtn.Position = UDim2.new(1, -93, 0, 10)
		ApplyBtn.BackgroundColor3 = Color3.fromRGB(48, 168, 88)
		ApplyBtn.Text = "APPLY"
		ApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		ApplyBtn.Font = Enum.Font.GothamBold
		ApplyBtn.TextSize = 12
		ApplyBtn.BorderSizePixel = 0
		ApplyBtn.ZIndex = 8
		ApplyBtn.Parent = ItemFrame

		Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 7)

		ApplyBtn.MouseEnter:Connect(function()
			TweenService:Create(ApplyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 200, 110)}):Play()
		end)

		ApplyBtn.MouseLeave:Connect(function()
			TweenService:Create(ApplyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(48, 168, 88)}):Play()
		end)

		ApplyBtn.MouseButton1Click:Connect(function()
			statusLabel.Text = "⏳  Applying " .. anim.Name .. "..."
			statusLabel.TextColor3 = Color3.fromRGB(220, 180, 60)

			local success, message = applyAnimationFE(anim.Id, anim.Name)

			if success then
				statusLabel.Text = "✅  " .. message .. ": " .. anim.Name
				statusLabel.TextColor3 = Color3.fromRGB(80, 220, 110)
			else
				statusLabel.Text = "❌  " .. message
				statusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
			end

			task.delay(4, function()
				statusLabel.Text = "Ready"
				statusLabel.TextColor3 = Color3.fromRGB(150, 150, 175)
			end)
		end)

		-- Item hover
		ItemFrame.MouseEnter:Connect(function()
			TweenService:Create(ItemFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(38, 38, 58)}):Play()
			TweenService:Create(ItemStroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(60, 185, 100)}):Play()
		end)

		ItemFrame.MouseLeave:Connect(function()
			TweenService:Create(ItemFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 30, 46)}):Play()
			TweenService:Create(ItemStroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(45, 45, 68)}):Play()
		end)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, (72 * #results) + 16)
	statusLabel.Text = "✅  " .. #results .. " animations loaded"
	statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
end

-- =============== MAIN LOGIC ===============

local lastApplied = { ID = nil, Name = nil }
local isSearchMode = false

Player.CharacterAdded:Connect(function(character)
	if lastApplied.ID then
		task.wait(0.5)
		applyAnimationFE(lastApplied.ID, lastApplied.Name)
	end
end)

local UI = createGUI()
local currentAnimations = {}

-- ── Open / Close toggle ──
local function openGUI()
	-- Sync icon and main frame positions so GUI appears near icon
	local iconPos = UI.IconBtn.Position
	UI.MainFrame.Position = UDim2.new(
		iconPos.X.Scale,
		iconPos.X.Offset + 68,
		iconPos.Y.Scale,
		iconPos.Y.Offset - 10
	)
	UI.IconBtn.Visible = false
	UI.MainFrame.Visible = true
	UI.MainFrame.BackgroundTransparency = 1
	TweenService:Create(UI.MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
end

local function closeGUI()
	-- Move icon to wherever the main frame currently is
	local mPos = UI.MainFrame.Position
	UI.IconBtn.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset - 68, mPos.Y.Scale, mPos.Y.Offset + 10)

	TweenService:Create(UI.MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
	task.delay(0.18, function()
		UI.MainFrame.Visible = false
		UI.IconBtn.Visible = true
	end)
end

UI.IconBtn.MouseButton1Click:Connect(openGUI)
UI.CloseBtn.MouseButton1Click:Connect(closeGUI)

-- Icon hover
UI.IconBtn.MouseEnter:Connect(function()
	TweenService:Create(UI.IconBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 55)}):Play()
end)

UI.IconBtn.MouseLeave:Connect(function()
	TweenService:Create(UI.IconBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(25, 25, 38)}):Play()
end)

-- ── Load defaults ──
local function loadDefaultAnimations()
	clearResults(UI.ResultsScroll)
	UI.LoadingOverlay.Visible = true
	UI.StatusLabel.Text = "Fetching latest from Roblox..."
	UI.StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 175)

	task.spawn(function()
		currentAnimations = fetchDefaultAnimations()
		task.synchronize()
		UI.LoadingOverlay.Visible = false
		displayResults(currentAnimations, UI.ResultsScroll, UI.StatusLabel, false)
	end)
end

-- ── Tabs ──
local function setScrollPosition(withSearch)
	if withSearch then
		UI.SearchContainer.Visible = true
		UI.ResultsScroll.Position = UDim2.new(0, 12, 0, 148)
		UI.ResultsScroll.Size = UDim2.new(1, -24, 0, 314)
		UI.LoadingOverlay.Position = UDim2.new(0, 12, 0, 148)
		UI.LoadingOverlay.Size = UDim2.new(1, -24, 0, 314)
	else
		UI.SearchContainer.Visible = false
		UI.ResultsScroll.Position = UDim2.new(0, 12, 0, 102)
		UI.ResultsScroll.Size = UDim2.new(1, -24, 0, 360)
		UI.LoadingOverlay.Position = UDim2.new(0, 12, 0, 102)
		UI.LoadingOverlay.Size = UDim2.new(1, -24, 0, 360)
	end
end

UI.DiscoverTab.MouseButton1Click:Connect(function()
	isSearchMode = false
	UI.DiscoverTab.BackgroundColor3 = Color3.fromRGB(55, 170, 90)
	UI.DiscoverTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	UI.SearchTab.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
	UI.SearchTab.TextColor3 = Color3.fromRGB(160, 160, 185)
	setScrollPosition(false)

	if #currentAnimations > 0 then
		clearResults(UI.ResultsScroll)
		displayResults(currentAnimations, UI.ResultsScroll, UI.StatusLabel, false)
	else
		loadDefaultAnimations()
	end
end)

UI.SearchTab.MouseButton1Click:Connect(function()
	isSearchMode = true
	UI.SearchTab.BackgroundColor3 = Color3.fromRGB(55, 170, 90)
	UI.SearchTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	UI.DiscoverTab.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
	UI.DiscoverTab.TextColor3 = Color3.fromRGB(160, 160, 185)
	setScrollPosition(true)
	UI.SearchBox.Text = ""

	if #currentAnimations > 0 then
		clearResults(UI.ResultsScroll)
		displayResults(currentAnimations, UI.ResultsScroll, UI.StatusLabel, false)
	end
end)

-- ── Live search ──
UI.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if not isSearchMode then return end

	local text = UI.SearchBox.Text

	if text == "" then
		clearResults(UI.ResultsScroll)
		if #currentAnimations > 0 then
			displayResults(currentAnimations, UI.ResultsScroll, UI.StatusLabel, false)
		else
			UI.StatusLabel.Text = "Type to search animations"
			UI.StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 175)
		end
		return
	end

	if #text < 2 then
		clearResults(UI.ResultsScroll)
		UI.StatusLabel.Text = "Type at least 2 characters..."
		UI.StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 175)
		UI.ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	clearResults(UI.ResultsScroll)
	UI.LoadingOverlay.Visible = true
	UI.StatusLabel.Text = "Searching..."
	UI.StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 175)

	task.spawn(function()
		local results = searchCatalogAPI(text, 40)
		task.synchronize()
		UI.LoadingOverlay.Visible = false
		displayResults(results, UI.ResultsScroll, UI.StatusLabel, true)
	end)
end)

-- ── Refresh ──
UI.RefreshBtn.MouseButton1Click:Connect(function()
	TweenService:Create(UI.RefreshBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(55, 170, 90)}):Play()
	task.delay(0.2, function()
		TweenService:Create(UI.RefreshBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 58)}):Play()
	end)

	if isSearchMode and UI.SearchBox.Text ~= "" then
		clearResults(UI.ResultsScroll)
		UI.LoadingOverlay.Visible = true

		task.spawn(function()
			local results = searchCatalogAPI(UI.SearchBox.Text, 40)
			task.synchronize()
			UI.LoadingOverlay.Visible = false
			displayResults(results, UI.ResultsScroll, UI.StatusLabel, true)
		end)
	else
		loadDefaultAnimations()
	end
end)

-- ── Initial load ──
loadDefaultAnimations()

print("✅ AnimCatalog loaded!")
print("🎭 Click the floating icon to open the GUI")
print("✕  Use the X button to collapse back to icon")
print("🔍 Search tab for keyword search")
