local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== Functions to get closest player =====
local AIMBOT_MAX_DISTANCE = 150 -- Maximum distance for aimbot to activate

local function getClosestGuard()
    local closest = nil
    local shortestDistance = math.huge
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
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
            if dist < shortestDistance and dist <= AIMBOT_MAX_DISTANCE then
                shortestDistance = dist
                closest = player
            end
        end
    end

    return closest
end

local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
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
            if dist < shortestDistance and dist <= AIMBOT_MAX_DISTANCE then
                shortestDistance = dist
                closest = player
            end
        end
    end

    return closest
end

local function getClosestFrontman()
    local closest = nil
    local shortestDistance = math.huge
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, player in pairs(Players:GetPlayers()) do
        if player.Team and player.Team.Name == "Front man"
            and player.Character
            and player.Character:FindFirstChild("Head")
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
        then
            local dist = (player.Character.Head.Position - myPos).Magnitude
            if dist < shortestDistance and dist <= AIMBOT_MAX_DISTANCE then
                shortestDistance = dist
                closest = player
            end
        end
    end

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
            elseif filter == "Frontman" then
                if player.Team and player.Team.Name == "Front man" then
                    shouldShow = true
                    color = Color3.fromRGB(255, 165, 0) -- Orange for Front man
                end
            elseif filter == "Player" then
                shouldShow = true
                if player.Team and player.Team.Name == "Guard" then
                    color = Color3.fromRGB(255, 0, 0) -- Red for guards
                elseif player.Team and player.Team.Name == "Front man" then
                    color = Color3.fromRGB(255, 165, 0) -- Orange for Front man
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

-- AIMBOT TOGGLES
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

local AimbotFrontmanConnection = nil
Tab:AddToggle({
    Name = "Aimbot Front man",
    Default = false,
    Callback = function(state)
        if state then
            AimbotFrontmanConnection = RunService.RenderStepped:Connect(function()
                local closestFrontman = getClosestFrontman()
                if closestFrontman and closestFrontman.Character and closestFrontman.Character:FindFirstChild("Head") then
                    local targetPos = closestFrontman.Character.Head.Position
                    local cameraPos = Camera.CFrame.Position
                    local newCFrame = CFrame.new(cameraPos, targetPos)
                    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.2)
                end
            end)
        else
            if AimbotFrontmanConnection then
                AimbotFrontmanConnection:Disconnect()
                AimbotFrontmanConnection = nil
            end
        end
    end
})

-- ESP TOGGLES
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

local ESPFrontmanConnection = nil
Tab:AddToggle({
    Name = "ESP Front man",
    Default = false,
    Callback = function(state)
        if state then
            updateESP("Frontman")
            ESPFrontmanConnection = RunService.RenderStepped:Connect(function()
                updateESP("Frontman")
            end)
        else
            if ESPFrontmanConnection then
                ESPFrontmanConnection:Disconnect()
                ESPFrontmanConnection = nil
            end
            -- Remove ESP of Front man when disabling
            for player, _ in pairs(ESP_Boxes) do
                if player.Team and player.Team.Name == "Front man" then
                    removeESP(player)
                end
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

-- ===== Hitbox Expander Toggle =====
local HitboxConnection = nil
local originalSizes = {}

Tab:AddToggle({
    Name = "Expand Hitboxes (Enemy Players)",
    Default = false,
    Callback = function(state)
        if state then
            HitboxConnection = RunService.Heartbeat:Connect(function()
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = player.Character.HumanoidRootPart
                        -- Store original size if not stored yet
                        if not originalSizes[hrp] then
                            originalSizes[hrp] = hrp.Size
                        end
                        -- Expand HumanoidRootPart hitbox significantly
                        hrp.Size = Vector3.new(8, 8, 8)
                        hrp.Transparency = 0 -- Keep it invisible like normal
                        hrp.CanCollide = false
                    end
                end
            end)
        else
            if HitboxConnection then
                HitboxConnection:Disconnect()
                HitboxConnection = nil
            end
            -- Restore original hitboxes
            for hrp, originalSize in pairs(originalSizes) do
                if hrp and hrp.Parent then
                    hrp.Size = originalSize
                    hrp.Transparency = 1 -- Back to invisible
                    hrp.CanCollide = false -- HumanoidRootPart should never collide
                end
            end
            originalSizes = {}
        end
    end
})

-- ===== Fling Toggle =====
local FlingConnection = nil
local FlingForce = 50000 -- Adjust this value for more/less fling power

Tab:AddToggle({
    Name = "Fling Players (Touch to Launch)",
    Default = false,
    Callback = function(state)
        if state then
            FlingConnection = RunService.Heartbeat:Connect(function()
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local myHRP = character.HumanoidRootPart
                    
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local theirHRP = player.Character.HumanoidRootPart
                            local distance = (myHRP.Position - theirHRP.Position).Magnitude
                            
                            -- If close enough to touch
                            if distance <= 8 then
                                -- Create fling force
                                local bodyVelocity = theirHRP:FindFirstChild("FlingForce")
                                if not bodyVelocity then
                                    bodyVelocity = Instance.new("BodyVelocity")
                                    bodyVelocity.Name = "FlingForce"
                                    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                    bodyVelocity.Parent = theirHRP
                                end
                                
                                -- Calculate fling direction (up and away from you)
                                local direction = (theirHRP.Position - myHRP.Position).Unit
                                direction = direction + Vector3.new(0, 1, 0) -- Add upward force
                                bodyVelocity.Velocity = direction * FlingForce
                                
                                -- Remove the force after a short time
                                game:GetService("Debris"):AddItem(bodyVelocity, 0.5)
                            end
                        end
                    end
                end
            end)
        else
            if FlingConnection then
                FlingConnection:Disconnect()
                FlingConnection = nil
            end
            -- Remove any remaining fling forces
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local flingForce = player.Character.HumanoidRootPart:FindFirstChild("FlingForce")
                    if flingForce then
                        flingForce:Destroy()
                    end
                end
            end
        end
    end
})

-- ===== Cleanup when player leaves =====
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    -- Clean up hitbox data for disconnected players
    for part, _ in pairs(originalSizes) do
        if part and part.Parent and part.Parent.Parent == player then
            originalSizes[part] = nil
        end
    end
end)

-- ===== Prints =====
print("Rebelion-HUB loaded successfully!")
print("Guards ESP & Aimbot: Loaded")
print("Players ESP & Aimbot: Loaded") 
print("Front man ESP & Aimbot: Loaded")
print("Hitbox Expander: Ready")
print("Fling System: Ready")

-- Debug function to check teams
spawn(function()
    wait(3)
    print("=== TEAM DEBUG ===")
    for _, player in pairs(Players:GetPlayers()) do
        if player.Team then
            print(player.Name .. " is on team: " .. player.Team.Name)
        else
            print(player.Name .. " has no team")
        end
    end
    print("=== END DEBUG ===")
end)
