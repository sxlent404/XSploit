local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local COLORS = {
    BACKGROUND = Color3.fromRGB(30, 30, 30),
    TOP_BAR = Color3.fromRGB(40, 40, 40),
    BUTTON = Color3.fromRGB(50, 50, 50),
    BUTTON_ACTIVE = Color3.fromRGB(0, 170, 127),
    ENTRY = Color3.fromRGB(40, 40, 40),
    TEXT = Color3.fromRGB(255, 255, 255),
    CODE = Color3.fromRGB(200, 200, 200)
}

local DEFAULTS = {
    WINDOW_SIZE = UDim2.new(0, 400, 0, 300),
    TOP_BAR_HEIGHT = 30,
    PADDING = 5,
    FONT_SIZE = {
        TITLE = 16,
        NORMAL = 14,
        CODE = 12
    }
}

local function createGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = HttpService:GenerateGUID(false)
    
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = game:GetService("CoreGui")
    elseif gethui then
        gui.Parent = gethui()
    else
        gui.Parent = game:GetService("CoreGui")
    end
    
    return gui
end

local function serializeValue(value)
    if type(value) == "string" then 
        return string.format("%q", value)
    elseif typeof(value) == "Instance" then 
        return value:GetFullName()
    elseif type(value) == "table" then
        local result = {}
        for k, v in pairs(value) do
            local keyStr = type(k) == "string" and string.format("%q", k) or tostring(k)
            table.insert(result, string.format("[%s] = %s", keyStr, serializeValue(v)))
        end
        return "{" .. table.concat(result, ", ") .. "}"
    end
    return tostring(value)
end

local RemoteSpy = {}
RemoteSpy.__index = RemoteSpy

function RemoteSpy.new()
    local self = setmetatable({}, RemoteSpy)
    self.gui = createGui()
    self.spyEnabled = false
    self.remoteCounts = {}
    self.remoteEntries = {}
    
    self:createMainWindow()
    self:setupDragging()
    self:hookRemotes()
    
    return self
end

function RemoteSpy:createMainWindow()
    self.main = Instance.new("Frame")
    self.main.Name = "MainFrame"
    self.main.Size = DEFAULTS.WINDOW_SIZE
    self.main.Position = UDim2.new(0.5, -200, 0.5, -150)
    self.main.BackgroundColor3 = COLORS.BACKGROUND
    self.main.BorderSizePixel = 0
    self.main.Parent = self.gui
    
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, DEFAULTS.TOP_BAR_HEIGHT)
    topBar.BackgroundColor3 = COLORS.TOP_BAR
    topBar.BorderSizePixel = 0
    topBar.Parent = self.main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.TextColor3 = COLORS.TEXT
    title.Text = "Silent Spy"
    title.TextSize = DEFAULTS.FONT_SIZE.TITLE
    title.Font = Enum.Font.SourceSansBold
    title.Parent = topBar
    
    self.toggleBtn = Instance.new("TextButton")
    self.toggleBtn.Size = UDim2.new(0, 100, 0, 20)
    self.toggleBtn.Position = UDim2.new(0, 10, 0, 35)
    self.toggleBtn.BackgroundColor3 = COLORS.BUTTON
    self.toggleBtn.TextColor3 = COLORS.TEXT
    self.toggleBtn.Text = "Enable Spy"
    self.toggleBtn.TextSize = DEFAULTS.FONT_SIZE.NORMAL
    self.toggleBtn.Font = Enum.Font.SourceSans
    self.toggleBtn.Parent = self.main
    
    self.scrollFrame = Instance.new("ScrollingFrame")
    self.scrollFrame.Size = UDim2.new(1, 0, 1, -60)
    self.scrollFrame.Position = UDim2.new(0, 0, 0, 60)
    self.scrollFrame.BackgroundTransparency = 1
    self.scrollFrame.ScrollBarThickness = 4
    self.scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.scrollFrame.Parent = self.main
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, DEFAULTS.PADDING)
    listLayout.Parent = self.scrollFrame
    
    self:setupCallbacks()
end

function RemoteSpy:setupCallbacks()
    self.toggleBtn.MouseButton1Click:Connect(function()
        self.spyEnabled = not self.spyEnabled
        self.toggleBtn.BackgroundColor3 = self.spyEnabled and COLORS.BUTTON_ACTIVE or COLORS.BUTTON
    end)
end

function RemoteSpy:setupDragging()
    local dragToggle, dragStart, startPos
    local dragSpeed = 0.25
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(self.main, TweenInfo.new(dragSpeed), {Position = position}):Play()
    end
    
    self.main.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = self.main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            updateDrag(input)
        end
    end)
end

function RemoteSpy:createRemoteEntry(remote, code, args)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 110)
    frame.BackgroundColor3 = COLORS.ENTRY
    frame.BorderSizePixel = 0
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = COLORS.TEXT
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = remote.Name
    nameLabel.TextSize = DEFAULTS.FONT_SIZE.NORMAL
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = frame
    
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -10, 0, 40)
    codeBox.Position = UDim2.new(0, 5, 0, 30)
    codeBox.BackgroundColor3 = COLORS.BACKGROUND
    codeBox.TextColor3 = COLORS.CODE
    codeBox.Text = code
    codeBox.TextSize = DEFAULTS.FONT_SIZE.CODE
    codeBox.Font = Enum.Font.Code
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.TextWrapped = true
    codeBox.ClearTextOnFocus = false
    codeBox.Parent = frame
    
    local function createButton(text, position)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 70, 0, 25)
        button.Position = position
        button.BackgroundColor3 = COLORS.BUTTON
        button.TextColor3 = COLORS.TEXT
        button.Text = text
        button.TextSize = DEFAULTS.FONT_SIZE.NORMAL
        button.Font = Enum.Font.SourceSans
        button.Parent = frame
        return button
    end
    
    local copyBtn = createButton("Copy", UDim2.new(0, 5, 0, 80))
    local executeBtn = createButton("Execute", UDim2.new(0, 80, 0, 80))
    
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
    
    frame.Parent = self.scrollFrame
    return frame
end

function RemoteSpy:handleRemote(remote, ...)
    if not self.spyEnabled then return end
    
    local args = {...}
    local code = string.format("game.%s:%sServer(%s)",
        remote:GetFullName(),
        remote:IsA("RemoteEvent") and "Fire" or "Invoke",
        serializeValue(args))
    
    if not self.remoteCounts[remote] then
        self.remoteCounts[remote] = 1
        self.remoteEntries[remote] = self:createRemoteEntry(remote, code, args)
    else
        self.remoteCounts[remote] = self.remoteCounts[remote] + 1
        local label = self.remoteEntries[remote]:FindFirstChild("TextLabel")
        if label then
            label.Text = string.format("%s (%d)", remote.Name, self.remoteCounts[remote])
        end
    end
end

function RemoteSpy:hookRemotes()
    local function hookRemote(remote)
        if remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...)
                self:handleRemote(remote, ...)
            end)
        elseif remote:IsA("RemoteFunction") then
            remote.OnClientInvoke = function(...)
                self:handleRemote(remote, ...)
                return "Spy Active"
            end
        end
    end
    
    game.DescendantAdded:Connect(hookRemote)
    for _, desc in ipairs(game:GetDescendants()) do 
        hookRemote(desc)
    end
end

local spy = RemoteSpy.new()
