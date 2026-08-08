local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local enabled = false
local cooldown = false

local DISTANCE = 4
local CORNER_ANGLE = 35
local COOLDOWN = 0.4

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "WallhopGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local box = Instance.new("Frame")
box.Size = UDim2.fromOffset(220, 100)
box.Position = UDim2.new(1, -240, 0, 30)
box.BackgroundColor3 = Color3.fromRGB(25,25,25)
box.Active = true
box.Parent = gui

Instance.new("UICorner", box).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-70,0,35)
title.Position = UDim2.fromOffset(10,0)
title.BackgroundTransparency = 1
title.Text = "WALLHOP"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Active = true
title.Parent = box

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(28,28)
minimize.Position = UDim2.new(1,-62,0,4)
minimize.Text = "-"
minimize.TextSize = 20
minimize.Parent = box

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(28,28)
close.Position = UDim2.new(1,-32,0,4)
close.Text = "X"
close.TextSize = 14
close.Parent = box

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1,-20,0,45)
toggle.Position = UDim2.fromOffset(10,45)
toggle.Text = "WALLHOP: OFF"
toggle.TextSize = 17
toggle.Font = Enum.Font.GothamBold
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(50,50,50)
toggle.Parent = box

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,8)

-- Small restore button
local restore = Instance.new("TextButton")
restore.Size = UDim2.fromOffset(55,55)
restore.Position = UDim2.new(1,-75,0,30)
restore.Text = "WH"
restore.TextSize = 15
restore.Font = Enum.Font.GothamBold
restore.TextColor3 = Color3.new(1,1,1)
restore.BackgroundColor3 = Color3.fromRGB(25,25,25)
restore.Visible = false
restore.Active = true
restore.Parent = gui

Instance.new("UICorner", restore).CornerRadius = UDim.new(1,0)

-- Dragging
local function drag(object, target)
	local dragging = false
	local start
	local startPos

	object.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			start = input.Position
			startPos = target.Position

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

			local delta = input.Position - start

			target.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

drag(title, box)
drag(restore, restore)

minimize.MouseButton1Click:Connect(function()
	box.Visible = false
	restore.Visible = true
end)

restore.MouseButton1Click:Connect(function()
	box.Visible = true
	restore.Visible = false
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

toggle.MouseButton1Click:Connect(function()
	enabled = not enabled
	toggle.Text = enabled and "WALLHOP: ON" or "WALLHOP: OFF"
end)

-- Check whether two surfaces form a corner
local function findCorner(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local forward = root.CFrame.LookVector
	local right = root.CFrame.RightVector

	-- Two separate rays:
	-- one slightly left and one slightly right.
	local leftResult = workspace:Raycast(
		root.Position,
		(forward - right * 0.35).Unit * DISTANCE,
		params
	)

	local rightResult = workspace:Raycast(
		root.Position,
		(forward + right * 0.35).Unit * DISTANCE,
		params
	)

	if not leftResult or not rightResult then
		return nil
	end

	-- Compare the two surface normals.
	local dot = math.clamp(
		leftResult.Normal:Dot(rightResult.Normal),
		-1,
		1
	)

	local angle = math.deg(math.acos(dot))

	-- The two detected surfaces must be different enough
	-- to count as a corner.
	if angle >= CORNER_ANGLE then
		return leftResult, rightResult
	end

	return nil
end

local function wallhop()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then return end

	local leftHit, rightHit = findCorner(character)

	if not leftHit or not rightHit then
		return
	end

	cooldown = true

	-- Turn 90 degrees right.
	local position = root.Position

	root.CFrame =
		CFrame.new(position) *
		CFrame.Angles(0, math.rad(90), 0)

	-- Give the character a little upward/forward movement.
	root.AssemblyLinearVelocity =
		root.CFrame.LookVector * 35 +
		Vector3.new(0, 28, 0)

	task.wait(0.12)

	cooldown = false
end

RunService.Heartbeat:Connect(function()
	if not enabled or cooldown then
		return
	end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		local state = humanoid:GetState()

		if state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Freefall then

			wallhop()
		end
	end
end)