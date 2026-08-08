local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- SETTINGS
local WALL_DISTANCE = 3
local WALL_ANGLE = 15
local TURN_TIME = 0.12
local COOLDOWN = 0.35

local enabled = false
local jumping = false
local cooldown = false

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "WallhopGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(220, 120)
main.Position = UDim2.new(1, -240, 1, -150)
main.BackgroundColor3 = Color3.fromRGB(25,25,25)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-70,0,35)
title.Position = UDim2.fromOffset(10,0)
title.BackgroundTransparency = 1
title.Text = "Wallhop"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Active = true
title.Parent = main

-- Minimize
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(28,28)
minimize.Position = UDim2.new(1,-62,0,4)
minimize.Text = "−"
minimize.TextSize = 20
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundColor3 = Color3.fromRGB(50,50,50)
minimize.Parent = main

Instance.new("UICorner", minimize).CornerRadius = UDim.new(0,6)

-- Close
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28,28)
close.Position = UDim2.new(1,-32,0,4)
close.Text = "X"
close.TextSize = 14
close.TextColor3 = Color3.new(1,1,1)
close.BackgroundColor3 = Color3.fromRGB(50,50,50)
close.Parent = main

Instance.new("UICorner", close).CornerRadius = UDim.new(0,6)

-- Toggle
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1,-20,0,50)
toggle.Position = UDim2.fromOffset(10,55)
toggle.Text = "WALLHOP: OFF"
toggle.TextSize = 17
toggle.Font = Enum.Font.GothamBold
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
toggle.Parent = main

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

-- Minimized bubble
local bubble = Instance.new("TextButton")
bubble.Size = UDim2.fromOffset(55,55)
bubble.Position = UDim2.new(1,-75,1,-75)
bubble.Text = "WH"
bubble.TextSize = 15
bubble.Font = Enum.Font.GothamBold
bubble.TextColor3 = Color3.new(1,1,1)
bubble.BackgroundColor3 = Color3.fromRGB(25,25,25)
bubble.Visible = false
bubble.Active = true
bubble.Parent = gui

Instance.new("UICorner", bubble).CornerRadius = UDim.new(1,0)

-- Dragging
local function draggable(object, moveObject)
	local dragging = false
	local dragStart
	local startPosition

	object.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPosition = moveObject.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then

			local delta = input.Position - dragStart

			moveObject.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

draggable(title, main)
draggable(bubble, bubble)

-- Minimize
minimize.MouseButton1Click:Connect(function()
	main.Visible = false
	bubble.Visible = true
end)

-- Restore
bubble.MouseButton1Click:Connect(function()
	main.Visible = true
	bubble.Visible = false
end)

-- Close
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- Toggle
toggle.MouseButton1Click:Connect(function()
	enabled = not enabled

	if enabled then
		toggle.Text = "WALLHOP: ON"
	else
		toggle.Text = "WALLHOP: OFF"
	end
end)

-- Detect jumping
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.StateChanged:Connect(function(_, newState)
		jumping = (
			newState == Enum.HumanoidStateType.Jumping
			or newState == Enum.HumanoidStateType.Freefall
		)
	end)
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

-- Wall detection
local function detectWall(character)
	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local directions = {
		root.CFrame.LookVector,
		(root.CFrame * CFrame.Angles(0, math.rad(15), 0)).LookVector,
		(root.CFrame * CFrame.Angles(0, math.rad(-15), 0)).LookVector
	}

	local hits = 0

	for _, direction in ipairs(directions) do
		local result = workspace:Raycast(
			root.Position,
			direction * WALL_DISTANCE,
			params
		)

		if result then
			hits += 1
		end
	end

	-- Two nearby rays must hit the wall,
	-- giving the "two lines meet" behavior.
	return hits >= 2
end

-- Wallhop
RunService.Heartbeat:Connect(function()
	if not enabled or not jumping or cooldown then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	if detectWall(character) then
		cooldown = true

		-- Turn exactly 90 degrees right
		local original = root.CFrame

		root.CFrame =
			CFrame.new(root.Position)
			* CFrame.Angles(0, math.rad(90), 0)

		task.wait(TURN_TIME)

		-- Return to flat/forward orientation
		local look = original.LookVector
		look = Vector3.new(look.X, 0, look.Z)

		if look.Magnitude > 0 then
			root.CFrame =
				CFrame.lookAt(
					root.Position,
					root.Position + look.Unit
				)
		end

		task.wait(COOLDOWN)
		cooldown = false
	end
end)