--!strict
-- Polaroid viewfinder, shutter, and minimal album strip.
-- Server owns film, framed catches, and flash suspicion; this draws UI and fires remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Polaroid = {}

local function corner(parent: Instance, radius: number)
	local ui = Instance.new("UICorner")
	ui.CornerRadius = UDim.new(0, radius)
	ui.Parent = parent
end

local function parseAlbum(raw: string): { { id: string, stop: string } }
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or typeof(data) ~= "table" then
		return {}
	end
	local out = {}
	for _, item in data do
		if typeof(item) == "table" and typeof(item.id) == "string" then
			table.insert(out, {
				id = item.id,
				stop = if typeof(item.stop) == "string" then item.stop else "",
			})
		end
	end
	return out
end

function Polaroid.start(cameraButton: TextButton, albumButton: TextButton)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local toggleRemote = remotes:WaitForChild("PolaroidToggle") :: RemoteEvent
	local snapRemote = remotes:WaitForChild("PolaroidSnap") :: RemoteEvent
	local albumRemote = remotes:WaitForChild("PolaroidAlbum") :: RemoteEvent

	local gui = playerGui:WaitForChild("LastLocalHud") :: ScreenGui

	local viewfinder = Instance.new("Frame")
	viewfinder.Name = "PolaroidViewfinder"
	viewfinder.Size = UDim2.fromScale(1, 1)
	viewfinder.BackgroundTransparency = 1
	viewfinder.BorderSizePixel = 0
	viewfinder.Visible = false
	viewfinder.Parent = gui

	local vignette = Instance.new("Frame")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.new(0, 0, 0)
	vignette.BackgroundTransparency = 0.55
	vignette.BorderSizePixel = 0
	vignette.Parent = viewfinder

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.48)
	frame.Size = UDim2.fromScale(0.42, 0.55)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = viewfinder

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(230, 220, 200)
	stroke.Transparency = 0.15
	stroke.Parent = frame

	local filmLabel = Instance.new("TextLabel")
	filmLabel.Name = "Film"
	filmLabel.AnchorPoint = Vector2.new(0.5, 1)
	filmLabel.Position = UDim2.new(0.5, 0, 1, -18)
	filmLabel.Size = UDim2.fromOffset(160, 22)
	filmLabel.BackgroundTransparency = 1
	filmLabel.Font = Enum.Font.Code
	filmLabel.Text = "FILM 8"
	filmLabel.TextSize = 14
	filmLabel.TextColor3 = Constants.COLOR.cream
	filmLabel.Parent = viewfinder

	local snapHint = Instance.new("TextLabel")
	snapHint.BackgroundTransparency = 1
	snapHint.Font = Enum.Font.Gotham
	snapHint.Text = "SPACE · SNAP"
	snapHint.TextSize = 12
	snapHint.TextColor3 = Color3.fromRGB(200, 196, 186)
	snapHint.AnchorPoint = Vector2.new(0.5, 1)
	snapHint.Position = UDim2.new(0.5, 0, 1, -42)
	snapHint.Size = UDim2.fromOffset(160, 18)
	snapHint.Parent = viewfinder

	local flashOverlay = Instance.new("Frame")
	flashOverlay.Name = "Flash"
	flashOverlay.Size = UDim2.fromScale(1, 1)
	flashOverlay.BackgroundColor3 = Color3.fromRGB(255, 248, 230)
	flashOverlay.BackgroundTransparency = 1
	flashOverlay.BorderSizePixel = 0
	flashOverlay.ZIndex = 20
	flashOverlay.Parent = gui

	local albumPanel = Instance.new("Frame")
	albumPanel.Name = "PolaroidAlbum"
	albumPanel.AnchorPoint = Vector2.new(0.5, 1)
	albumPanel.Position = UDim2.new(0.5, 0, 1, -140)
	albumPanel.Size = UDim2.fromOffset(420, 88)
	albumPanel.BackgroundColor3 = Color3.fromRGB(16, 14, 12)
	albumPanel.BackgroundTransparency = 0.08
	albumPanel.BorderSizePixel = 0
	albumPanel.Visible = false
	albumPanel.Parent = gui
	corner(albumPanel, 8)

	local albumTitle = Instance.new("TextLabel")
	albumTitle.BackgroundTransparency = 1
	albumTitle.Font = Enum.Font.GothamBold
	albumTitle.Text = "ALBUM"
	albumTitle.TextSize = 11
	albumTitle.TextColor3 = Color3.fromRGB(180, 176, 166)
	albumTitle.Position = UDim2.fromOffset(12, 6)
	albumTitle.Size = UDim2.new(1, -24, 0, 16)
	albumTitle.TextXAlignment = Enum.TextXAlignment.Left
	albumTitle.Parent = albumPanel

	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.Position = UDim2.fromOffset(10, 28)
	strip.Size = UDim2.new(1, -20, 0, 50)
	strip.BackgroundTransparency = 1
	strip.Parent = albumPanel

	local stripLayout = Instance.new("UIListLayout")
	stripLayout.FillDirection = Enum.FillDirection.Horizontal
	stripLayout.Padding = UDim.new(0, 8)
	stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
	stripLayout.Parent = strip

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "Empty"
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Font = Enum.Font.Gotham
	emptyLabel.Text = "No prints yet."
	emptyLabel.TextSize = 12
	emptyLabel.TextColor3 = Color3.fromRGB(150, 146, 136)
	emptyLabel.Size = UDim2.fromScale(1, 1)
	emptyLabel.Parent = strip

	local function cameraRaised(): boolean
		return ride:GetAttribute("CameraRaised") == true
	end

	local function albumOpen(): boolean
		return ride:GetAttribute("AlbumOpen") == true
	end

	local function refreshFilm()
		local left = ride:GetAttribute("FilmLeft")
		local n = if typeof(left) == "number" then left else 0
		filmLabel.Text = string.format("FILM %d", n)
		cameraButton.Text = if cameraRaised() then "CAM·" else "CAM"
	end

	local function refreshAlbum()
		local raw = ride:GetAttribute("PolaroidAlbum")
		local photos = parseAlbum(if typeof(raw) == "string" then raw else "[]")
		for _, child in strip:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		emptyLabel.Visible = #photos == 0
		for i, photo in photos do
			if i > 6 then
				break
			end
			local cell = Instance.new("Frame")
			cell.Name = photo.id
			cell.Size = UDim2.fromOffset(44, 48)
			cell.BackgroundColor3 = Color3.fromRGB(210, 200, 180)
			cell.BackgroundTransparency = 0.15
			cell.BorderSizePixel = 0
			cell.LayoutOrder = i
			cell.Parent = strip
			corner(cell, 2)
			local undeveloped = Instance.new("Frame")
			undeveloped.Size = UDim2.new(1, -6, 1, -10)
			undeveloped.Position = UDim2.fromOffset(3, 3)
			undeveloped.BackgroundColor3 = Color3.fromRGB(40, 38, 34)
			undeveloped.BorderSizePixel = 0
			undeveloped.Parent = cell
		end
	end

	local function refresh()
		viewfinder.Visible = cameraRaised()
		albumPanel.Visible = albumOpen()
		refreshFilm()
		refreshAlbum()
		cameraButton.Visible = true
		albumButton.Visible = true
	end

	local function fireSnap()
		if not cameraRaised() then
			return
		end
		local camera = workspace.CurrentCamera
		if camera == nil then
			return
		end
		local look = camera.CFrame.LookVector
		local pos = camera.CFrame.Position
		snapRemote:FireServer(pos.X, pos.Y, pos.Z, look.X, look.Y, look.Z)
	end

	cameraButton.MouseButton1Click:Connect(function()
		toggleRemote:FireServer()
	end)
	albumButton.MouseButton1Click:Connect(function()
		albumRemote:FireServer()
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.C then
			toggleRemote:FireServer()
		elseif input.KeyCode == Enum.KeyCode.P then
			albumRemote:FireServer()
		elseif cameraRaised() and (input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return) then
			fireSnap()
		end
	end)

	local flashUntil = 0
	ride.AttributeChanged:Connect(function(name: string)
		if name == "PolaroidFlash" then
			local stamp = ride:GetAttribute("PolaroidFlash")
			if typeof(stamp) == "number" and stamp > 0 then
				flashUntil = os.clock() + 0.22
				flashOverlay.BackgroundTransparency = 0.15
			end
		elseif
			name == "CameraRaised"
			or name == "AlbumOpen"
			or name == "FilmLeft"
			or name == "PolaroidAlbum"
		then
			refresh()
		end
	end)

	RunService.RenderStepped:Connect(function()
		if os.clock() < flashUntil then
			local u = (flashUntil - os.clock()) / 0.22
			flashOverlay.BackgroundTransparency = 0.15 + (1 - math.clamp(u, 0, 1)) * 0.85
		else
			flashOverlay.BackgroundTransparency = 1
		end
	end)

	refresh()
end

return Polaroid
