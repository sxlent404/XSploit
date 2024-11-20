-- coded by sxlent404

local gui = Instance.new("RSPY")
gui.Name = game:GetService("HttpService"):GenerateGUID(false)
if syn and syn.protect_gui then
    syn.protect_gui(gui)
    gui.Parent = game:GetService("CoreGui")
elseif gethui then
    gui.Parent = gethui()
else
    gui.Parent = game:GetService("CoreGui")
end

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local main = Instance.new("Frame")
main.Name = "MainFrame"
main.Size = UDim2.new(0, 400, 0, 300)
main.Position = UDim2.new(0.5, -200, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
main.BorderSizePixel = 0
main.Parent = gui

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
topBar.BorderSizePixel = 0
topBar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Remote Spy"
title.TextSize = 16
title.Font = Enum.Font.SourceSansBold
title.Parent = topBar

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -60)
scrollFrame.Position = UDim2.new(0, 0, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = main

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = scrollFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 100, 0, 20)
toggleBtn.Position = UDim2.new(0, 10, 0, 35)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Text = "Enable Spy"
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.SourceSans
toggleBtn.Parent = main

local dragToggle, dragStart, startPos = nil, nil, nil
local dragSpeed = 0.25

local function updateInput(input)
    local delta = input.Position - dragStart
    local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(main, TweenInfo.new(dragSpeed), {Position = position}):Play()
end

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragToggle then
            updateInput(input)
        end
    end
end)

local spyEnabled = false
local remoteCounts = {}
local remoteLabels = {}

local function convertTableToString(args)
    local function valueToString(v)
        if type(v) == "string" then return string.format("%q", v)
        elseif typeof(v) == "Instance" then return v:GetFullName()
        elseif type(v) == "table" then
            local result = "{"
            for key, value in pairs(v) do
                result = result .. string.format("[%s] = %s, ", 
                    type(key) == "string" and string.format("%q", key) or tostring(key),
                    valueToString(value))
            end
            return result:sub(1, -3) .. "}"
        end
        return tostring(v)
    end
    local result = "{"
    for i, v in ipairs(args) do result = result .. valueToString(v) .. ", " end
    return result:sub(1, -3) .. "}"
end

toggleBtn.MouseButton1Click:Connect(function()
    spyEnabled = not spyEnabled
    toggleBtn.BackgroundColor3 = spyEnabled and Color3.fromRGB(0, 170, 127) or Color3.fromRGB(50, 50, 50)
end)

local function createRemoteEntry(remote, code, args)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 110)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = remote.Name
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = frame
    
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -10, 0, 40)
    codeBox.Position = UDim2.new(0, 5, 0, 30)
    codeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    codeBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    codeBox.Text = code
    codeBox.TextSize = 12
    codeBox.Font = Enum.Font.Code
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.TextWrapped = true
    codeBox.ClearTextOnFocus = false
    codeBox.Parent = frame
    
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 70, 0, 25)
    copyBtn.Position = UDim2.new(0, 5, 0, 80)
    copyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.Text = "Copy"
    copyBtn.TextSize = 14
    copyBtn.Font = Enum.Font.SourceSans
    copyBtn.Parent = frame
    
    local executeBtn = Instance.new("TextButton")
    executeBtn.Size = UDim2.new(0, 70, 0, 25)
    executeBtn.Position = UDim2.new(0, 80, 0, 80)
    executeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeBtn.Text = "Execute"
    executeBtn.TextSize = 14
    executeBtn.Font = Enum.Font.SourceSans
    executeBtn.Parent = frame
    
    copyBtn.MouseButton1Click:Connect(function()
        setclipboard(code)
    end)
    
    executeBtn.MouseButton1Click:Connect(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(unpack(args))
        else
            remote:InvokeServer(unpack(args))
        end
    end)
    
    frame.Parent = scrollFrame
    return frame
end

local function handleRemote(remote, ...)
    if not spyEnabled then return end
    
    local args = {...}
    local code = string.format("game.%s:%sServer(%s)",
        remote:GetFullName(),
        remote:IsA("RemoteEvent") and "Fire" or "Invoke",
        convertTableToString(args))
    
    if not remoteCounts[remote] then
        remoteCounts[remote] = 1
        remoteLabels[remote] = createRemoteEntry(remote, code, args)
    else
        remoteCounts[remote] = remoteCounts[remote] + 1
        local label = remoteLabels[remote]:FindFirstChild("TextLabel")
        if label then
            label.Text = string.format("%s (%d)", remote.Name, remoteCounts[remote])
        end
    end
end

local function hookRemote(remote)
    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(...)
            handleRemote(remote, ...)
        end)
    elseif remote:IsA("RemoteFunction") then
        remote.OnClientInvoke = function(...)
            handleRemote(remote, ...)
            return "Spy Active"
        end
    end
end

game.DescendantAdded:Connect(hookRemote)
for _, desc in ipairs(game:GetDescendants()) do hookRemote(desc) end
