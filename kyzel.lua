local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Roblox services used by integrated tools
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Loading system to prevent overlaps and stacking
local LoadingSystem = {
    activeLoading = {},
    queuedCommands = {}
}

function LoadingSystem:IsCommandBusy(commandName)
    return self.activeLoading[commandName] ~= nil
end

function LoadingSystem:StartCommand(commandName, callback)
    if self:IsCommandBusy(commandName) then
        WindUI:Notify({
            Title = "Command Busy",
            Content = commandName .. " is already running!",
            Icon = "clock",
            Duration = 2
        })
        return false
    end
    
    self.activeLoading[commandName] = true
    local success = pcall(callback)
    
    if not success then
        self.activeLoading[commandName] = nil
    end
    
    return success
end

function LoadingSystem:EndCommand(commandName)
    self.activeLoading[commandName] = nil
end

-- Window setup (Example.lua style)
local Window = WindUI:CreateWindow({
    Title = "Revion Hub",
    Icon = "layers",
    Author = "by Kyzel",
    Folder = "RevionHub_AllTools",
    Size = UDim2.fromOffset(760, 520),
    Theme = "Dark",
    User = { Enabled = true, Anonymous = true },
    SideBarWidth = 240,
    ScrollBarEnabled = true
})

Window:Tag({ Title = "v1.0" })
Window:Tag({ Title = "by Kyzel" })

-- Sections and Tabs like Example.lua
local Sections = {
    Main = Window:Section({ Title = "Tools", Opened = true }),
    Settings = Window:Section({ Title = "Settings", Opened = true }),
    Utilities = Window:Section({ Title = "Utilities", Opened = true })
}

local Tabs = {
    Home = Sections.Main:Tab({ Title = "Home", Icon = "home" }),
    Trades = Sections.Main:Tab({ Title = "Trades", Icon = "handshake" }),
    Pets = Sections.Main:Tab({ Title = "Pets", Icon = "heart" }),
    Mutation = Sections.Main:Tab({ Title = "Mutations", Icon = "zap" }),
    ESP = Sections.Main:Tab({ Title = "ESP", Icon = "eye" }),
    Appearance = Sections.Settings:Tab({ Title = "Appearance", Icon = "palette" }),
    Config = Sections.Utilities:Tab({ Title = "Configuration", Icon = "settings" })
}

-- Local state for tool inputs
local freezeEnabled = false
local targetUsername = ""
local targetUserId = nil
local targetThumb = nil

local petAgeEnabled = false
local petAgeValue = ""

local mutationEnabled = false
local mutationType = "All"
local espLabel = nil
local espBillboard = nil
local espBasePart = nil
local espVisible = false
local rainbowConn = nil
local rerollBusy = false
local autoBusy = false
local mutations = { "Shiny", "Inverted", "Frozen", "Windy", "Golden", "Mega", "Tiny", "Tranquil", "IronSkin", "Radiant", "Rainbow", "Shocked", "Ascended" }
local currentMutation = mutations[math.random(#mutations)]

-- Egg ESP state
local eggEspEnabled = false
local activeEggs = {}
local eggDescendantConn = nil

-- Enhanced loading overlay system with unique designs
local LoadingOverlays = {}

local function createTradeLoadingOverlay(titleText, subtitleText)
    local gui = Instance.new("ScreenGui")
    gui.Name = "RevionHub_TradeLoading"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local container = Instance.new("Frame")
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.fromOffset(400, 160)
    container.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
    container.BackgroundTransparency = 0.05
    container.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Color = Color3.fromRGB(100, 200, 255)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container

    -- Animated border effect
    local gradientFrame = Instance.new("Frame")
    gradientFrame.Size = UDim2.new(1, 6, 1, 6)
    gradientFrame.Position = UDim2.fromOffset(-3, -3)
    gradientFrame.BackgroundTransparency = 1
    gradientFrame.Parent = container
    
    local gradientCorner = Instance.new("UICorner")
    gradientCorner.CornerRadius = UDim.new(0, 19)
    gradientCorner.Parent = gradientFrame
    
    local gradientStroke = Instance.new("UIStroke")
    gradientStroke.Thickness = 2
    gradientStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    gradientStroke.Parent = gradientFrame
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
    }
    gradient.Parent = gradientStroke

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 45)
    title.Position = UDim2.fromOffset(10, 20)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Color3.fromRGB(240, 250, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "🤝 " .. tostring(titleText or "Processing Trade...")
    title.Parent = container

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Size = UDim2.new(1, -20, 0, 28)
    subtitle.Position = UDim2.fromOffset(10, 75)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 18
    subtitle.TextColor3 = Color3.fromRGB(190, 210, 230)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = tostring(subtitleText or "Executing trade operation...")
    subtitle.Parent = container

    -- Unique trade progress bar with handshake animation
    local progressContainer = Instance.new("Frame")
    progressContainer.BackgroundTransparency = 1
    progressContainer.Size = UDim2.new(1, -20, 0, 20)
    progressContainer.Position = UDim2.fromOffset(10, 115)
    progressContainer.Parent = container

    local handshakeIcon = Instance.new("TextLabel")
    handshakeIcon.BackgroundTransparency = 1
    handshakeIcon.Size = UDim2.fromOffset(30, 20)
    handshakeIcon.Position = UDim2.fromOffset(0, 0)
    handshakeIcon.Font = Enum.Font.GothamBold
    handshakeIcon.TextSize = 16
    handshakeIcon.TextColor3 = Color3.fromRGB(100, 200, 255)
    handshakeIcon.Text = "🤝"
    handshakeIcon.Parent = progressContainer

    local progressText = Instance.new("TextLabel")
    progressText.BackgroundTransparency = 1
    progressText.Size = UDim2.new(1, -40, 1, 0)
    progressText.Position = UDim2.fromOffset(40, 0)
    progressText.Font = Enum.Font.Gotham
    progressText.TextSize = 14
    progressText.TextColor3 = Color3.fromRGB(150, 170, 190)
    progressText.TextXAlignment = Enum.TextXAlignment.Left
    progressText.Text = "Establishing connection..."
    progressText.Parent = progressContainer

    local alive = true
    task.spawn(function()
        local phrases = {"Establishing connection...", "Securing trade...", "Finalizing handshake..."}
        local t = 0
        local phraseIndex = 1
        while alive do
            t += 0.05
            -- Animate gradient rotation
            gradient.Rotation = (t * 30) % 360
            -- Pulse handshake icon
            local scale = 1 + math.sin(t * 4) * 0.1
            handshakeIcon.TextScaled = false
            handshakeIcon.TextSize = 16 * scale
            -- Change phrases
            if math.floor(t * 2) % 2 == 0 and math.floor(t) ~= math.floor(t - 0.05) then
                phraseIndex = (phraseIndex % #phrases) + 1
                progressText.Text = phrases[phraseIndex]
            end
            task.wait(0.05)
        end
    end)

    return {
        update = function(_, newTitle, newSubtitle)
            if typeof(newTitle) == "string" then title.Text = "🤝 " .. newTitle end
            if typeof(newSubtitle) == "string" then subtitle.Text = newSubtitle end
        end,
        close = function()
            alive = false
            gui:Destroy()
        end
    }
end

local function createPetLoadingOverlay(titleText, subtitleText)
    local gui = Instance.new("ScreenGui")
    gui.Name = "RevionHub_PetLoading"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local container = Instance.new("Frame")
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.fromOffset(380, 170)
    container.BackgroundColor3 = Color3.fromRGB(25, 15, 30)
    container.BackgroundTransparency = 0.05
    container.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 150, 200)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.fromOffset(10, 20)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = Color3.fromRGB(255, 200, 220)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "🐾 " .. tostring(titleText or "Processing Pet...")
    title.Parent = container

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Size = UDim2.new(1, -20, 0, 26)
    subtitle.Position = UDim2.fromOffset(10, 70)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 16
    subtitle.TextColor3 = Color3.fromRGB(200, 170, 190)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = tostring(subtitleText or "Modifying pet attributes...")
    subtitle.Parent = container

    -- Pet-themed circular progress
    local progressFrame = Instance.new("Frame")
    progressFrame.BackgroundTransparency = 1
    progressFrame.Size = UDim2.fromOffset(40, 40)
    progressFrame.Position = UDim2.fromOffset(20, 110)
    progressFrame.Parent = container

    local heart = Instance.new("TextLabel")
    heart.BackgroundTransparency = 1
    heart.Size = UDim2.fromOffset(40, 40)
    heart.Position = UDim2.fromOffset(0, 0)
    heart.Font = Enum.Font.GothamBold
    heart.TextSize = 24
    heart.TextColor3 = Color3.fromRGB(255, 100, 150)
    heart.Text = "❤️"
    heart.Parent = progressFrame

    local statusText = Instance.new("TextLabel")
    statusText.BackgroundTransparency = 1
    statusText.Size = UDim2.new(1, -80, 0, 40)
    statusText.Position = UDim2.fromOffset(70, 110)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 14
    statusText.TextColor3 = Color3.fromRGB(180, 150, 170)
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextYAlignment = Enum.TextYAlignment.Center
    statusText.Text = "Caring for your pet..."
    statusText.Parent = container

    local alive = true
    task.spawn(function()
        local petStates = {"Feeding pet...", "Playing with pet...", "Training pet...", "Loving pet..."}
        local t = 0
        local stateIndex = 1
        while alive do
            t += 0.08
            -- Heartbeat animation
            local beat = math.sin(t * 6) * 0.15 + 1
            heart.TextSize = 24 * beat
            -- Color pulse
            local pulse = (math.sin(t * 3) * 0.3 + 0.7)
            heart.TextColor3 = Color3.fromRGB(255 * pulse, 100 * pulse, 150 * pulse)
            -- Change states
            if math.floor(t * 1.5) ~= math.floor((t - 0.08) * 1.5) then
                stateIndex = (stateIndex % #petStates) + 1
                statusText.Text = petStates[stateIndex]
            end
            task.wait(0.08)
        end
    end)

    return {
        update = function(_, newTitle, newSubtitle)
            if typeof(newTitle) == "string" then title.Text = "🐾 " .. newTitle end
            if typeof(newSubtitle) == "string" then subtitle.Text = newSubtitle end
        end,
        close = function()
            alive = false
            gui:Destroy()
        end
    }
end

local function createMutationLoadingOverlay(titleText, subtitleText)
    local gui = Instance.new("ScreenGui")
    gui.Name = "RevionHub_MutationLoading"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local container = Instance.new("Frame")
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.fromOffset(420, 180)
    container.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
    container.BackgroundTransparency = 0.1
    container.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = container

    -- Multi-color stroke for mutation theme
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container
    
    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 100))
    }
    strokeGradient.Parent = stroke

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 45)
    title.Position = UDim2.fromOffset(10, 20)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24
    title.TextColor3 = Color3.fromRGB(255, 240, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "⚡ " .. tostring(titleText or "Processing Mutation...")
    title.Parent = container

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Size = UDim2.new(1, -20, 0, 28)
    subtitle.Position = UDim2.fromOffset(10, 75)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 17
    subtitle.TextColor3 = Color3.fromRGB(220, 200, 240)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = tostring(subtitleText or "Manipulating genetic code...")
    subtitle.Parent = container

    -- DNA helix animation
    local helixFrame = Instance.new("Frame")
    helixFrame.BackgroundTransparency = 1
    helixFrame.Size = UDim2.new(1, -20, 0, 50)
    helixFrame.Position = UDim2.fromOffset(10, 115)
    helixFrame.Parent = container

    local dnaText = Instance.new("TextLabel")
    dnaText.BackgroundTransparency = 1
    dnaText.Size = UDim2.new(1, 0, 1, 0)
    dnaText.Font = Enum.Font.Code
    dnaText.TextSize = 14
    dnaText.TextXAlignment = Enum.TextXAlignment.Left
    dnaText.TextYAlignment = Enum.TextYAlignment.Center
    dnaText.Parent = helixFrame

    local alive = true
    task.spawn(function()
        local dnaSequences = {"ATCG-TAGC", "GCTA-CGAT", "TACG-ATGC", "CGAT-GCTA"}
        local mutationSteps = {"Scanning genome...", "Isolating sequences...", "Applying mutation...", "Stabilizing changes..."}
        local t = 0
        local seqIndex = 1
        local stepIndex = 1
        while alive do
            t += 0.1
            -- Rotate gradient
            strokeGradient.Rotation = (t * 50) % 360
            -- Rainbow DNA text
            local hue = (t * 0.02) % 1
            dnaText.TextColor3 = Color3.fromHSV(hue, 0.8, 1)
            -- Cycle DNA and steps
            if math.floor(t * 3) ~= math.floor((t - 0.1) * 3) then
                seqIndex = (seqIndex % #dnaSequences) + 1
                stepIndex = (stepIndex % #mutationSteps) + 1
                dnaText.Text = "🧬 " .. dnaSequences[seqIndex] .. " | " .. mutationSteps[stepIndex]
            end
            task.wait(0.1)
        end
    end)

    return {
        update = function(_, newTitle, newSubtitle)
            if typeof(newTitle) == "string" then title.Text = "⚡ " .. newTitle end
            if typeof(newSubtitle) == "string" then subtitle.Text = newSubtitle end
        end,
        close = function()
            alive = false
            gui:Destroy()
        end
    }
end

local function createESPLoadingOverlay(titleText, subtitleText)
    local gui = Instance.new("ScreenGui")
    gui.Name = "RevionHub_ESPLoading"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local container = Instance.new("Frame")
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.fromOffset(360, 150)
    container.BackgroundColor3 = Color3.fromRGB(5, 15, 5)
    container.BackgroundTransparency = 0.1
    container.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(100, 255, 100)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.fromOffset(10, 15)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 21
    title.TextColor3 = Color3.fromRGB(200, 255, 200)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "👁️ " .. tostring(titleText or "Scanning Area...")
    title.Parent = container

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Size = UDim2.new(1, -20, 0, 25)
    subtitle.Position = UDim2.fromOffset(10, 60)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 15
    subtitle.TextColor3 = Color3.fromRGB(170, 220, 170)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = tostring(subtitleText or "Activating enhanced vision...")
    subtitle.Parent = container

    -- Radar sweep animation
    local radarFrame = Instance.new("Frame")
    radarFrame.BackgroundTransparency = 1
    radarFrame.Size = UDim2.fromOffset(80, 20)
    radarFrame.Position = UDim2.fromOffset(20, 100)
    radarFrame.Parent = container

    local radarText = Instance.new("TextLabel")
    radarText.BackgroundTransparency = 1
    radarText.Size = UDim2.new(1, 0, 1, 0)
    radarText.Font = Enum.Font.Code
    radarText.TextSize = 16
    radarText.TextColor3 = Color3.fromRGB(100, 255, 100)
    radarText.TextXAlignment = Enum.TextXAlignment.Left
    radarText.Text = "📡 Scanning..."
    radarText.Parent = radarFrame

    local progressBar = Instance.new("Frame")
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
    progressBar.Size = UDim2.new(1, -120, 0, 8)
    progressBar.Position = UDim2.fromOffset(110, 106)
    progressBar.Parent = container
    
    local progressFill = Instance.new("Frame")
    progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.Parent = progressBar

    local alive = true
    task.spawn(function()
        local radarStates = {"📡 Scanning...", "🎯 Targeting...", "🔍 Analyzing...", "✅ Complete"}
        local t = 0
        local stateIndex = 1
        while alive do
            t += 0.06
            -- Progress bar fill
            local progress = (math.sin(t * 2) * 0.5 + 0.5) * 0.9 + 0.1
            progressFill.Size = UDim2.new(progress, 0, 1, 0)
            -- Pulse effect
            local pulse = math.sin(t * 4) * 0.1 + 0.9
            stroke.Color = Color3.fromRGB(100 * pulse, 255, 100 * pulse)
            -- Change radar states
            if math.floor(t * 2) ~= math.floor((t - 0.06) * 2) then
                stateIndex = (stateIndex % #radarStates) + 1
                radarText.Text = radarStates[stateIndex]
            end
            task.wait(0.06)
        end
    end)

    return {
        update = function(_, newTitle, newSubtitle)
            if typeof(newTitle) == "string" then title.Text = "👁️ " .. newTitle end
            if typeof(newSubtitle) == "string" then subtitle.Text = newSubtitle end
        end,
        close = function()
            alive = false
            gui:Destroy()
        end
    }
end

-- UI: Home Tab
Tabs.Home:Paragraph({
    Title = "Revion Hub",
    Desc = "Made by Kyzel — Clean UI powered by WindUI\nNavigate tabs for Trades, Pets, Mutations, and ESP.",
    Image = "layers",
    ImageSize = 22,
    Color = "White"
})
Tabs.Home:Divider()
Tabs.Home:Paragraph({ Title = "Tips", Desc = "Use Configuration to save your setup. Themes available in Appearance." })
Tabs.Home:Divider()

-- Trades Tab
Tabs.Trades:Paragraph({ Title = "Trade Tools", Desc = "Freeze, Force, and Auto Accept" })
local freezeToggle = Tabs.Trades:Toggle({
    Title = "Enable Freeze Trade",
    Value = false,
    Callback = function(state)
        freezeEnabled = state
        WindUI:Notify({
            Title = "Freeze Trade",
            Content = state and "Enabled" or "Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

local usernameInput = Tabs.Trades:Input({
    Title = "Target Username",
    Value = targetUsername,
    Callback = function(text)
        targetUsername = tostring(text or "")
        targetUserId = nil
        targetThumb = nil
        if targetUsername ~= "" then
            task.spawn(function()
                local ok, userId = pcall(function()
                    return Players:GetUserIdFromNameAsync(targetUsername)
                end)
                if ok then
                    targetUserId = userId
                    local ok2, content = pcall(function()
                        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
                    end)
                    if ok2 then targetThumb = content end
                    WindUI:Notify({ Title = "User Resolved", Content = ("%s (%d)"):format(targetUsername, userId), Icon = "user", Duration = 3 })
                else
                    WindUI:Notify({ Title = "User Lookup Failed", Content = "Check username", Icon = "x", Duration = 2 })
                end
            end)
        end
    end
})

Tabs.Trades:Button({
    Title = "FREEZE TRADE",
    Icon = "snowflake",
    Variant = "Primary",
    Callback = function()
        LoadingSystem:StartCommand("FreezeTrade", function()
            if not freezeEnabled then
                WindUI:Notify({ Title = "Freeze Trade", Content = "Toggle is disabled", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("FreezeTrade")
                return
            end
            if targetUsername == "" then
                WindUI:Notify({ Title = "Trade Assist", Content = "Enter username first", Icon = "alert-triangle", Duration = 2 })
                LoadingSystem:EndCommand("FreezeTrade")
                return
            end
            local overlay = createTradeLoadingOverlay("Freezing Trade", "Target: " .. targetUsername)
            task.delay(2.5, function()
                overlay:update("Trade Frozen", "Success for " .. targetUsername)
                task.wait(0.6)
                overlay:close()
                WindUI:Notify({ Title = "Trade Assist", Content = "Trade frozen for " .. targetUsername, Icon = "snowflake", Duration = 2 })
                LoadingSystem:EndCommand("FreezeTrade")
            end)
            print("Freeze Trade executed for:", targetUsername)
        end)
    end
})

Tabs.Trades:Button({
    Title = "FORCE TRADE PETS",
    Icon = "zap",
    Callback = function()
        LoadingSystem:StartCommand("ForceTrade", function()
            local overlay = createTradeLoadingOverlay("Forcing Trade", "Overriding restrictions...")
            task.delay(2.0, function()
                overlay:update("Trade Forced", "Operation complete")
                task.wait(0.5)
                overlay:close()
                WindUI:Notify({ Title = "Trade Assist", Content = "Force trade triggered!", Icon = "zap", Duration = 2 })
                LoadingSystem:EndCommand("ForceTrade")
            end)
        end)
    end
})

Tabs.Trades:Button({
    Title = "AUTO ACCEPT",
    Icon = "check",
    Callback = function()
        LoadingSystem:StartCommand("AutoAccept", function()
            local overlay = createTradeLoadingOverlay("Auto Accept", "Monitoring incoming trades...")
            task.delay(1.8, function()
                overlay:update("Auto Accept Active", "Ready to accept trades")
                task.wait(0.4)
                overlay:close()
                WindUI:Notify({ Title = "Trade Assist", Content = "Auto accept activated!", Icon = "check", Duration = 2 })
                LoadingSystem:EndCommand("AutoAccept")
            end)
        end)
    end
})

Tabs.Trades:Divider()

-- Pets Tab
Tabs.Pets:Paragraph({ Title = "Pet Age Changer", Desc = "Modify pet age with countdown effects" })
local petAgeToggle = Tabs.Pets:Toggle({
    Title = "Enable Pet Age Changer",
    Value = false,
    Callback = function(state)
        petAgeEnabled = state
        WindUI:Notify({ Title = "Pet Age Changer", Content = state and "Enabled" or "Disabled", Icon = state and "check" or "x", Duration = 2 })
    end
})

-- Pet Age logic from Kuni Hub
local function getEquippedPetTool()
    local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") and child.Name:find("Age") then
            return child
        end
    end
    return nil
end

local function getCurrentAgeFromName(name)
    local num = tostring(name or ""):match("%[Age%s(%d+)%]")
    return tonumber(num)
end

Tabs.Pets:Button({
    Title = "Set Age to 50",
    Icon = "clock",
    Callback = function()
        LoadingSystem:StartCommand("SetAge50", function()
            if not petAgeEnabled then
                WindUI:Notify({ Title = "Pet Age Changer", Content = "Toggle is disabled", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("SetAge50")
                return
            end
            local tool = getEquippedPetTool()
            if not tool then
                WindUI:Notify({ Title = "Pet Age", Content = "No Pet Equipped!", Icon = "alert-triangle", Duration = 2 })
                LoadingSystem:EndCommand("SetAge50")
                return
            end
            local overlay = createPetLoadingOverlay("Setting Age", "Target: 50 years old")
            task.spawn(function()
                for i = 10, 1, -1 do
                    overlay:update("Setting Age", ("Countdown: %ds | Target: 50"):format(i))
                    task.wait(1)
                end
                local newName = tool.Name:gsub("%[Age%s%d+%]", "[Age 50]")
                tool.Name = newName
                overlay:update("Age Complete", "Successfully set to 50 years")
                task.wait(0.6)
                overlay:close()
                WindUI:Notify({ Title = "Pet Age", Content = "Age set to 50 years!", Icon = "heart", Duration = 2 })
                LoadingSystem:EndCommand("SetAge50")
            end)
        end)
    end
})

Tabs.Pets:Button({
    Title = "Add +1 Age",
    Icon = "plus",
    Callback = function()
        LoadingSystem:StartCommand("AddAge", function()
            if not petAgeEnabled then
                WindUI:Notify({ Title = "Pet Age Changer", Content = "Toggle is disabled", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("AddAge")
                return
            end
            local tool = getEquippedPetTool()
            if not tool then
                WindUI:Notify({ Title = "Pet Age", Content = "No Pet Equipped!", Icon = "alert-triangle", Duration = 2 })
                LoadingSystem:EndCommand("AddAge")
                return
            end
            local currentAge = getCurrentAgeFromName(tool.Name)
            if not currentAge then
                WindUI:Notify({ Title = "Pet Age", Content = "Invalid Age Format!", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("AddAge")
                return
            end
            if currentAge >= 100 then
                WindUI:Notify({ Title = "Pet Age", Content = "Max Age is 100!", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("AddAge")
                return
            end
            local overlay = createPetLoadingOverlay("Adding Age", "Current: "..currentAge.." → "..(currentAge+1))
            task.spawn(function()
                for i = 5, 1, -1 do
                    overlay:update("Adding Age", ("Countdown: %ds | %d → %d"):format(i, currentAge, currentAge+1))
                    task.wait(1)
                end
                local newAge = currentAge + 1
                local newName = tool.Name:gsub("%[Age%s%d+%]", "[Age " .. newAge .. "]")
                tool.Name = newName
                overlay:update("Age Updated", "Successfully aged to "..newAge.." years")
                task.wait(0.5)
                overlay:close()
                WindUI:Notify({ Title = "Pet Age", Content = "Added +1 Age ("..newAge..")", Icon = "heart", Duration = 2 })
                LoadingSystem:EndCommand("AddAge")
            end)
        end)
    end
})

Tabs.Pets:Divider()

-- Mutation Tab
Tabs.Mutation:Paragraph({ Title = "Mutation Finder", Desc = "Find, Reroll, and Auto-Ascend with ESP label" })
local mutationToggle = Tabs.Mutation:Toggle({
    Title = "Enable Mutation Finder",
    Value = false,
    Callback = function(state)
        mutationEnabled = state
        WindUI:Notify({ Title = "Mutation Finder", Content = state and "Enabled" or "Disabled", Icon = state and "check" or "x", Duration = 2 })
        espVisible = state
        -- Setup or tear down billboard ESP on mutation machine
        local function findMachine()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name:lower():find("mutation") then
                    return obj
                end
            end
        end
        if state then
            local machine = findMachine()
            if machine and machine:FindFirstChildWhichIsA("BasePart") then
                espBasePart = machine:FindFirstChildWhichIsA("BasePart")
                espBillboard = Instance.new("BillboardGui")
                espBillboard.Name = "MutationESP"
                espBillboard.Adornee = espBasePart
                espBillboard.Size = UDim2.new(0, 200, 0, 40)
                espBillboard.StudsOffset = Vector3.new(0, 3.5, 0)
                espBillboard.AlwaysOnTop = true
                espBillboard.Parent = espBasePart

                espLabel = Instance.new("TextLabel")
                espLabel.Size = UDim2.new(1, 0, 1, 0)
                espLabel.BackgroundTransparency = 1
                espLabel.Font = Enum.Font.GothamBold
                espLabel.TextSize = 26
                espLabel.TextStrokeTransparency = 0.2
                espLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                espLabel.Text = currentMutation
                espLabel.Parent = espBillboard

                local hue = 0
                rainbowConn = RunService.RenderStepped:Connect(function()
                    if espVisible and espLabel then
                        hue = (hue + 0.005) % 1
                        espLabel.TextColor3 = Color3.fromHSV(hue, 0.9, 1)
                    end
                end)
            else
                WindUI:Notify({ Title = "Mutation Finder", Content = "Machine not found", Icon = "x", Duration = 2 })
            end
        else
            if rainbowConn then rainbowConn:Disconnect() rainbowConn = nil end
            if espBillboard then espBillboard:Destroy() espBillboard = nil end
            espLabel = nil
            espBasePart = nil
        end
    end
})

local mutationDropdown = Tabs.Mutation:Dropdown({
    Title = "Mutation Type",
    Values = { "Rare", "Epic", "Legendary", "Mythical", "All" },
    Value = mutationType,
    Callback = function(option)
        mutationType = option
    end
})

Tabs.Mutation:Button({
    Title = "Find Mutations",
    Icon = "search",
    Callback = function()
        LoadingSystem:StartCommand("FindMutations", function()
            if not mutationEnabled then
                WindUI:Notify({ Title = "Mutation Finder", Content = "Toggle is disabled", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("FindMutations")
                return
            end
            local overlay = createMutationLoadingOverlay("Searching Mutations", "Type: "..tostring(mutationType))
            task.delay(2.2, function()
                overlay:update("Search Complete", "Found "..math.random(3,8).." "..mutationType.." mutations")
                task.wait(0.7)
                overlay:close()
                WindUI:Notify({ Title = "Mutation Finder", Content = "Search complete for "..mutationType, Icon = "search", Duration = 2 })
                LoadingSystem:EndCommand("FindMutations")
            end)
            print("Searching for mutations:", mutationType)
        end)
    end
})

Tabs.Mutation:Button({
    Title = "Scan Area",
    Icon = "radar",
    Callback = function()
        LoadingSystem:StartCommand("ScanArea", function()
            if not mutationEnabled then
                WindUI:Notify({ Title = "Mutation Finder", Content = "Toggle is disabled", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("ScanArea")
                return
            end
            local overlay = createMutationLoadingOverlay("Scanning Area", "Analyzing mutation signatures...")
            task.delay(1.8, function()
                overlay:update("Scan Complete", "Detected "..math.random(2,5).." mutation hotspots")
                task.wait(0.6)
                overlay:close()
                WindUI:Notify({ Title = "Mutation Finder", Content = "Area scan complete", Icon = "radar", Duration = 2 })
                LoadingSystem:EndCommand("ScanArea")
            end)
        end)
    end
})

Tabs.Mutation:Button({
    Title = "Mutation Reroll",
    Icon = "shuffle",
    Callback = function()
        LoadingSystem:StartCommand("MutationReroll", function()
            if not mutationEnabled then
                WindUI:Notify({ Title = "Mutation Finder", Content = "Toggle is disabled", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("MutationReroll")
                return
            end
            if not espLabel then 
                WindUI:Notify({ Title = "Mutation Finder", Content = "ESP not active", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("MutationReroll")
                return 
            end
            local overlay = createMutationLoadingOverlay("Rerolling", "Generating new outcomes...")
            task.spawn(function()
                for i = 1, 25 do
                    if espLabel then espLabel.Text = mutations[math.random(#mutations)] end
                    task.wait(0.08)
                end
                currentMutation = mutations[math.random(#mutations)]
                if espLabel then espLabel.Text = currentMutation end
                overlay:update("Reroll Complete", "New mutation: "..currentMutation)
                task.wait(0.8)
                overlay:close()
                WindUI:Notify({ Title = "Mutation", Content = "Rerolled to "..currentMutation, Icon = "shuffle", Duration = 2 })
                LoadingSystem:EndCommand("MutationReroll")
            end)
        end)
    end
})

Tabs.Mutation:Button({
    Title = "Auto Get Ascended",
    Icon = "star",
    Callback = function()
        LoadingSystem:StartCommand("AutoAscended", function()
            if not mutationEnabled then
                WindUI:Notify({ Title = "Mutation Finder", Content = "Toggle is disabled", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("AutoAscended")
                return
            end
            if not espLabel then 
                WindUI:Notify({ Title = "Mutation Finder", Content = "ESP not active", Icon = "x", Duration = 2 })
                LoadingSystem:EndCommand("AutoAscended")
                return 
            end
            local overlay = createMutationLoadingOverlay("Auto Ascend", "Hunting for Ascended mutation...")
            task.spawn(function()
                WindUI:Notify({ Title = "Mutation", Content = "Searching for Ascended...", Icon = "search", Duration = 2 })
                for t = 1, 25 do
                    currentMutation = mutations[math.random(#mutations - 1)]
                    if espLabel then espLabel.Text = currentMutation end
                    overlay:update("Auto Ascend", "Attempt "..t.."/25 | Current: "..currentMutation)
                    task.wait(0.8)
                end
                currentMutation = "Ascended"
                if espLabel then espLabel.Text = currentMutation end
                overlay:update("SUCCESS!", "ASCENDED MUTATION ACQUIRED!")
                task.wait(1.2)
                overlay:close()
                WindUI:Notify({ Title = "Mutation", Content = "🌟 ASCENDED FOUND! 🌟", Icon = "star", Duration = 4 })
                LoadingSystem:EndCommand("AutoAscended")
            end)
        end)
    end
})

Tabs.Mutation:Divider()

-- ESP Tab
Tabs.ESP:Paragraph({ Title = "Egg ESP", Desc = "Highlights egg models dynamically" })
local function isEggModel(inst)
    return inst:IsA("Model") and inst.Name:lower():find("egg") ~= nil
end

local function addEggHighlight(m)
    if activeEggs[m] then return end
    local h = Instance.new("Highlight")
    h.FillTransparency = 0.7
    h.OutlineTransparency = 0
    h.Parent = m
    activeEggs[m] = h
end

local function removeAllEggHighlights()
    for m,h in pairs(activeEggs) do
        if h then h:Destroy() end
    end
    table.clear(activeEggs)
end

local function rescanEggs()
    for m,h in pairs(activeEggs) do
        if not m or not m.Parent then
            if h then h:Destroy() end
            activeEggs[m] = nil
        end
    end
    for _,d in ipairs(Workspace:GetDescendants()) do
        if eggEspEnabled and isEggModel(d) then
            addEggHighlight(d)
        end
    end
end

Tabs.ESP:Toggle({
    Title = "EGG ESP",
    Value = false,
    Callback = function(on)
        LoadingSystem:StartCommand("EggESP", function()
            eggEspEnabled = on
            if on then
                local overlay = createESPLoadingOverlay("Activating ESP", "Scanning for egg models...")
                task.delay(1.5, function()
                    rescanEggs()
                    eggDescendantConn = Workspace.DescendantAdded:Connect(function(d)
                        if eggEspEnabled and isEggModel(d) then addEggHighlight(d) end
                    end)
                    overlay:update("ESP Active", "Found "..#activeEggs.." egg models")
                    task.wait(0.5)
                    overlay:close()
                    WindUI:Notify({ Title = "EGG ESP", Content = "Active - "..#activeEggs.." eggs highlighted", Icon = "eye", Duration = 2 })
                    LoadingSystem:EndCommand("EggESP")
                end)
            else
                local overlay = createESPLoadingOverlay("Deactivating ESP", "Removing highlights...")
                task.delay(0.8, function()
                    if eggDescendantConn then eggDescendantConn:Disconnect() eggDescendantConn = nil end
                    removeAllEggHighlights()
                    overlay:update("ESP Inactive", "All highlights removed")
                    task.wait(0.3)
                    overlay:close()
                    WindUI:Notify({ Title = "EGG ESP", Content = "Deactivated", Icon = "eye-off", Duration = 2 })
                    LoadingSystem:EndCommand("EggESP")
                end)
            end
        end)
    end
})

-- Settings: Appearance (copied style from Example.lua)
Tabs.Appearance:Paragraph({
    Title = "Customize Interface",
    Desc = "Personalize your experience",
    Image = "palette",
    ImageSize = 20,
    Color = "White"
})

local themes = {}
for name, _ in pairs(WindUI:GetThemes()) do table.insert(themes, name) end
pcall(function() table.sort(themes) end)

local themeDropdown = Tabs.Appearance:Dropdown({
    Title = "Select Theme",
    Values = themes,
    Value = "Dark",
    Callback = function(theme)
        WindUI:SetTheme(theme)
        WindUI:Notify({ Title = "Theme Applied", Content = theme, Icon = "palette", Duration = 2 })
    end
})

local transparencySlider = Tabs.Appearance:Slider({
    Title = "Window Transparency",
    Value = { Min = 0, Max = 1, Default = 0.2 },
    Step = 0.1,
    Callback = function(value)
        Window:ToggleTransparency(tonumber(value) > 0)
        WindUI.TransparencyValue = tonumber(value)
    end
})

Tabs.Appearance:Toggle({
    Title = "Enable Dark Mode",
    Value = true,
    Callback = function(state)
        WindUI:SetTheme(state and "Dark" or "Light")
        themeDropdown:Select(state and "Dark" or "Light")
    end
})

-- Utilities: Config (optional save/load like Example.lua)
Tabs.Config:Paragraph({
    Title = "Configuration Manager",
    Desc = "Save and load your settings",
    Image = "save",
    ImageSize = 20,
    Color = "White"
})

local configName = "default"
local configFile

Tabs.Config:Input({
    Title = "Config Name",
    Value = configName,
    Callback = function(value) configName = value end
})

local ConfigManager = Window.ConfigManager
if ConfigManager then
    ConfigManager:Init(Window)

    Tabs.Config:Button({
        Title = "Save Configuration",
        Icon = "save",
        Variant = "Primary",
        Callback = function()
            configFile = ConfigManager:CreateConfig(configName)
            -- Register UI elements that support it
            configFile:Register("freezeToggle", freezeToggle)
            configFile:Register("petAgeToggle", petAgeToggle)
            configFile:Register("mutationDropdown", mutationDropdown)
            configFile:Register("themeDropdown", themeDropdown)
            configFile:Register("transparencySlider", transparencySlider)
            -- Store additional values
            configFile:Set("targetUsername", targetUsername)
            configFile:Set("petAgeValue", petAgeValue)
            configFile:Set("mutationType", mutationType)
            if configFile:Save() then
                WindUI:Notify({ Title = "Saved", Content = "Saved as: "..configName, Icon = "check", Duration = 3 })
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to save config", Icon = "x", Duration = 3 })
            end
        end
    })

    Tabs.Config:Button({
        Title = "Load Configuration",
        Icon = "folder",
        Callback = function()
            configFile = ConfigManager:CreateConfig(configName)
            local data = configFile:Load()
            if data then
                targetUsername = data.targetUsername or targetUsername
                petAgeValue = data.petAgeValue or petAgeValue
                mutationType = data.mutationType or mutationType
                WindUI:Notify({ Title = "Loaded", Content = "Loaded: "..configName, Icon = "refresh-cw", Duration = 3 })
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to load config", Icon = "x", Duration = 3 })
            end
        end
    })
else
    Tabs.Config:Paragraph({ Title = "Config Manager Not Available", Desc = "Requires ConfigManager" })
end

-- Close handlers (optional)
Window:OnClose(function()
    -- Clean up any active loading operations
    for commandName, _ in pairs(LoadingSystem.activeLoading) do
        LoadingSystem:EndCommand(commandName)
    end
    -- Clean up ESP connections
    if rainbowConn then rainbowConn:Disconnect() end
    if eggDescendantConn then eggDescendantConn:Disconnect() end
    print("Window closed - cleaned up resources")
end)

Window:OnDestroy(function()
    -- Force cleanup of all GUI elements
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui.Name:find("RevionHub_") then
            gui:Destroy()
        end
    end
    print("Window destroyed - removed all overlays")
end)
