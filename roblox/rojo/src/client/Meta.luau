--!strict
-- Start menu: nightmare toggle, chapter/practice, archive, play again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Lines = require(ReplicatedStorage.Shared.Lines)

local Meta = {}

function Meta.start(
	setMenuVisible: (boolean) -> (),
	setNightmareLabel: (string, boolean) -> (),
	setArchiveText: (string) -> (),
	setArchiveVisible: (boolean) -> (),
	againButton: TextButton
)
	local ride = ReplicatedStorage:WaitForChild("Ride")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local startRemote = remotes:WaitForChild("MetaStart") :: RemoteEvent
	local againRemote = remotes:WaitForChild("MetaAgain") :: RemoteEvent

	local nightmare = false
	local archiveOpen = false
	local sent = false

	local function menuOn(): boolean
		return ride:GetAttribute("Phase") == "menu"
	end

	local function reportOn(): boolean
		return ride:GetAttribute("ReportReady") == true
	end

	local function unlocked(): boolean
		return ride:GetAttribute("NightmareUnlocked") == true
	end

	local function refresh()
		local on = menuOn()
		setMenuVisible(on)
		if on then
			sent = false
		end
		if unlocked() then
			setNightmareLabel(
				"[N]  " .. Lines.META_NIGHTMARE .. if nightmare then " · ON" else " · off",
				true
			)
		else
			setNightmareLabel("[N]  " .. Lines.META_NIGHTMARE_LOCKED, false)
			nightmare = false
		end
		local arch = ride:GetAttribute("MetaArchive")
		if typeof(arch) == "string" then
			setArchiveText(arch)
		else
			setArchiveText("")
		end
		setArchiveVisible(on and archiveOpen)
		againButton.Visible = reportOn()
	end

	local function fireStart(chapter: number)
		if not menuOn() or sent then
			return
		end
		if chapter > 1 and not unlocked() then
			return
		end
		sent = true
		startRemote:FireServer(unlocked() and nightmare, chapter)
	end

	againButton.MouseButton1Click:Connect(function()
		if reportOn() then
			againRemote:FireServer()
		end
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if menuOn() then
			if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
				fireStart(1)
			elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
				fireStart(2)
			elseif input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
				fireStart(3)
			elseif input.KeyCode == Enum.KeyCode.N then
				if unlocked() then
					nightmare = not nightmare
					refresh()
				end
			elseif input.KeyCode == Enum.KeyCode.Tab then
				archiveOpen = not archiveOpen
				refresh()
			end
		elseif
			reportOn()
			and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter)
		then
			againRemote:FireServer()
		end
	end)

	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LastLocalHud")
	local menu = gui:WaitForChild("MetaMenu")
	menu:WaitForChild("StartCh1").MouseButton1Click:Connect(function()
		fireStart(1)
	end)
	menu:WaitForChild("StartCh2").MouseButton1Click:Connect(function()
		fireStart(2)
	end)
	menu:WaitForChild("StartCh3").MouseButton1Click:Connect(function()
		fireStart(3)
	end)
	menu:WaitForChild("Nightmare").MouseButton1Click:Connect(function()
		if unlocked() then
			nightmare = not nightmare
			refresh()
		end
	end)
	menu:WaitForChild("Archive").MouseButton1Click:Connect(function()
		archiveOpen = not archiveOpen
		refresh()
	end)

	ride.AttributeChanged:Connect(function(name: string)
		if
			name == "Phase"
			or name == "NightmareUnlocked"
			or name == "MetaArchive"
			or name == "ReportReady"
		then
			refresh()
		end
	end)
	refresh()
end

return Meta
