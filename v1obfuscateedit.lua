local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== Functions to get closest player =====
local currentGuardTarget = nil
local currentPlayerTarget = nil

local function getClosestGuard()
    local closest = nil
    local shortestDistance = math.huge
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    -- Check if current target is still alive and valid
    if currentGuardTarget and currentGuardTarget.Character 
        and currentGuardTarget.Character:FindFirstChild("Humanoid")
        and currentGuardTarget.Character.Humanoid.Health > 0
        and currentGuardTarget.Team and currentGuardTarget.Team.Name == "Guard" then
        return currentGuardTarget
    else
        currentGuardTarget = nil
    end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player.Team and player.Team.Name == "Guard"
            and player.Character
            and player.Character:FindFirstChild("Head")
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
        then
            local dist = (player.Character.Head.Position - myPos).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closest = player
            end
        end
    end

    currentGuardTarget = closest
    return closest
end

local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    -- Check if current target is still alive and valid
    if currentPlayerTarget and currentPlayerTarget.Character 
        and currentPlayerTarget.Character:FindFirstChild("Humanoid")
        and currentPlayerTarget.Character.Humanoid.Health > 0 then
        return currentPlayerTarget
    else
        currentPlayerTarget = nil
    end

    local myPos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild("Head")
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
        then
            local dist = (player.Character.Head.Position - myPos).Magnitude
            if dist < shortestDistance then
                shortestDistance = dist
                closest = player
            end
        end
    end

    currentPlayerTarget = closest
    return closest
end

-- ===== ESP Functions =====
local ESP_Boxes = {}

local function createESP(player, color)
    if player.Character and player.Character:FindFirstChild("Head") then
        local head = player.Character.Head

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPBox"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 120, 0, 50)
        billboard.AlwaysOnTop = true

        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = color
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 0.3
        frame.Size = UDim2.fromScale(1, 1)
        frame.Parent = billboard

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextScaled = true
        label.Text = player.Name .. " (" .. (player.Team and player.Team.Name or "NoTeam") .. ")"
        label.Parent = billboard

        -- Protection against errors when adding to CoreGui
        local success, err = pcall(function()
            billboard.Parent = game.CoreGui
        end)
        
        if not success then
            billboard.Parent = LocalPlayer.PlayerGui
        end
        
        ESP_Boxes[player] = billboard
    end
end

local function removeESP(player)
    if ESP_Boxes[player] then
        ESP_Boxes[player]:Destroy()
        ESP_Boxes[player] = nil
    end
end

local function updateESP(filter)
    -- Remove ESP from players that no longer exist
    for player, _ in pairs(ESP_Boxes) do
        if not Players:FindFirstChild(player.Name) then
            removeESP(player)
        end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild("Head")
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
        then
            local shouldShow = false
            local color = Color3.fromRGB(0, 255, 0) -- Default green
            
            if filter == "Guard" then
                if player.Team and player.Team.Name == "Guard" then
                    shouldShow = true
                    color = Color3.fromRGB(255, 0, 0) -- Red for guards
                end
            elseif filter == "Player" then
                shouldShow = true
                if player.Team and player.Team.Name == "Guard" then
                    color = Color3.fromRGB(255, 0, 0) -- Red for guards
                else
                    color = Color3.fromRGB(0, 255, 0) -- Green for other players
                end
            end
            
            if shouldShow then
                if not ESP_Boxes[player] then
                    createESP(player, color)
                end
            else
                removeESP(player)
            end
        else
            removeESP(player)
        end
    end
end

-- ===== OrionLib =====
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

local Window = OrionLib:MakeWindow({
    Name = "Rebelion-HUB", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "RebelionConfig"
})

local Tab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

OrionLib:MakeNotification({
    Name = "Success!",
    Content = "Thanks for executing my script!",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- ===== Toggles =====
local AimbotGuardConnection = nil
Tab:AddToggle({
    Name = "Aimbot Guard",
    Default = false,
    Callback = function(state)
        if state then
            AimbotGuardConnection = RunService.RenderStepped:Connect(function()
                local closestGuard = getClosestGuard()
                if closestGuard and closestGuard.Character and closestGuard.Character:FindFirstChild("Head") then
                    local targetPos = closestGuard.Character.Head.Position
                    local cameraPos = Camera.CFrame.Position
                    local newCFrame = CFrame.new(cameraPos, targetPos)
                    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.2)
                end
            end)
        else
            if AimbotGuardConnection then
                AimbotGuardConnection:Disconnect()
                AimbotGuardConnection = nil
            end
        end
    end
})

local ESPGuardConnection = nil
Tab:AddToggle({
    Name = "ESP Guards",
    Default = false,
    Callback = function(state)
        if state then
            updateESP("Guard")
            ESPGuardConnection = RunService.RenderStepped:Connect(function()
                updateESP("Guard")
            end)
        else
            if ESPGuardConnection then
                ESPGuardConnection:Disconnect()
                ESPGuardConnection = nil
            end
            -- Remove ESP of guards when disabling
            for player, _ in pairs(ESP_Boxes) do
                if player.Team and player.Team.Name == "Guard" then
                    removeESP(player)
                end
            end
        end
    end
})

local ESPPlayerConnection = nil
Tab:AddToggle({
    Name = "ESP Players",
    Default = false,
    Callback = function(state)
        if state then
            updateESP("Player")
            ESPPlayerConnection = RunService.RenderStepped:Connect(function()
                updateESP("Player")
            end)
        else
            if ESPPlayerConnection then
                ESPPlayerConnection:Disconnect()
                ESPPlayerConnection = nil
            end
            -- Remove all ESP when disabling
            for player, _ in pairs(ESP_Boxes) do
                removeESP(player)
            end
        end
    end
})

local AimbotPlayerConnection = nil
Tab:AddToggle({
    Name = "Aimbot Player",
    Default = false,
    Callback = function(state)
        if state then
            AimbotPlayerConnection = RunService.RenderStepped:Connect(function()
                local closestPlayer = getClosestPlayer()
                if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
                    local targetPos = closestPlayer.Character.Head.Position
                    local cameraPos = Camera.CFrame.Position
                    local newCFrame = CFrame.new(cameraPos, targetPos)
                    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.2)
                end
            end)
        else
            if AimbotPlayerConnection then
                AimbotPlayerConnection:Disconnect()
                AimbotPlayerConnection = nil
            end
        end
    end
})

-- ===== Noclip Toggle =====
local NoclipConnection = nil
Tab:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(state)
        if state then
            NoclipConnection = RunService.Stepped:Connect(function()
                local character = LocalPlayer.Character
                if character then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if NoclipConnection then
                NoclipConnection:Disconnect()
                NoclipConnection = nil
            end
            -- Reactivate collision when disabling
            local character = LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

-- ===== God Mode Toggle =====
local GodModeConnection = nil
Tab:AddToggle({
    Name = "God Mode (Experimental - May not work most times)",
    Default = false,
    Callback = function(state)
        if state then
            GodModeConnection = RunService.Heartbeat:Connect(function()
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("Humanoid") then
                    local humanoid = character.Humanoid
                    if humanoid.Health < 1800 then
                        humanoid.Health = 1800
                        humanoid.MaxHealth = 1800
                    end
                end
            end)
        else
            if GodModeConnection then
                GodModeConnection:Disconnect()
                GodModeConnection = nil
            end
            -- Reset health to normal when disabling
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.MaxHealth = 100
                character.Humanoid.Health = 100
            end
        end
    end
})

-- ===== Cleanup when player leaves =====
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ===== Prints =====
print("Rebelion-HUB loaded successfully!")
print("Guards ESP & Aimbot: Loaded")
print("Players ESP & Aimbot: Loaded")
