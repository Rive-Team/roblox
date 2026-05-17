-- ══════════════════════════════════════════════
-- Rive Hub | Kingdom World Console Edition
-- Optimized for Arceus X & Weak Devices (No UI)
-- ══════════════════════════════════════════════

-- ═══ Global Configuration (Edit these values before executing) ═══
_G.RiveHub_AutoDriveFarmEnabled = false -- Set to true to enable Auto Drive Farm
_G.RiveHub_CarSpeed = 100             -- Desired car speed for Auto Drive Farm (e.g., 80-150)
_G.RiveHub_AntiFineEnabled = false    -- Set to true to enable Anti-Fine (Radar Bypass + Plate Hide)
_G.RiveHub_AutoPaycheckEnabled = false -- Set to true to enable Auto Paycheck
_G.RiveHub_WalkSpeed = 16             -- Desired walk speed (default is 16)
_G.RiveHub_JumpPower = 50             -- Desired jump power (default is 50)
_G.RiveHub_InfiniteJumpEnabled = false -- Set to true for Infinite Jump
_G.RiveHub_NoclipEnabled = false      -- Set to true for Noclip
_G.RiveHub_PlayerESPEnabled = false   -- Set to true for Player ESP
_G.RiveHub_AntiAFKEnabled = false     -- Set to true for Anti-AFK
_G.RiveHub_CarFlyEnabled = false      -- Set to true for Car Fly (Use Space to go up, Ctrl to go down)

-- ══════════════════════════════════════════════
-- Universal Executor Compatibility Layer
-- ══════════════════════════════════════════════
local _getgenv = getgenv or function()
    if shared and type(shared) == "table" then return shared end
    return _G
end

local _firetouchinterest = firetouchinterest or fireTouchInterest or fire_touch_interest or function(p1,p2,v) end
local _fireproximityprompt = fireproximityprompt or fireProximityPrompt or fire_proximity_prompt or function(p) if p and p.Triggered then p:Trigger() end end
local _hookmetamethod = hookmetamethod or hookMetaMethod or hook_metamethod
local _getrawmetatable = getrawmetatable or getRawMetatable or get_raw_metatable
local _setreadonly = setreadonly or setReadOnly or set_readonly or function() end
local _newcclosure = newcclosure or newCClosure or new_c_closure or function(f) return f end

firetouchinterest = _firetouchinterest
fireproximityprompt = _fireproximityprompt

-- ══════════════════════════════════════════════════════════════
-- 🛡️ Anti-Detection / Anti-Ban Layer (Simplified & Robust)
-- ══════════════════════════════════════════════════════════════
do
    pcall(function()
        if hookfunction then
            -- Attempt to hook Kick function to prevent being kicked
            hookfunction(game.Players.LocalPlayer.Kick, function() return task.wait(9e9) end)
        end
    end)

    pcall(function()
        if _hookmetamethod and _getrawmetatable then
            local plr = game:GetService("Players").LocalPlayer
            local mt = _getrawmetatable(game)
            if mt and mt.__namecall then
                _setreadonly(mt, false)
                local oldNamecall = mt.__namecall
                mt.__namecall = _newcclosure(function(self, ...)
                    local method = (getnamecallmethod and getnamecallmethod()) or ""
                    if method == "Kick" and self == plr then return nil end
                    return oldNamecall(self, ...)
                end)
                _setreadonly(mt, true)
            end
        end
    end)
end

if not game:IsLoaded() then game.Loaded:Wait() end

-- ── Mobile movement cleanup ──
do
    local plr = game:GetService("Players").LocalPlayer
    local function cleanChar(char)
        if not char then return end
        pcall(function()
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BodyVelocity") or p:IsA("BodyGyro") or p:IsA("BodyMover") or p:IsA("BodyForce") then
                    p:Destroy()
                end
                if p:IsA("BasePart") then p.Anchored = false p.CanCollide = true end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = _G.RiveHub_WalkSpeed hum.JumpPower = _G.RiveHub_JumpPower hum.AutoRotate = true hum.PlatformStand = false hum.Sit = false end
        end)
    end
    cleanChar(plr.Character)
    plr.CharacterAdded:Connect(cleanChar)
end

-- ══════════════════════════════════════════════
-- Services & Variables
-- ══════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end)

local function GetSeat() return Humanoid and Humanoid.SeatPart end
local function GetCarModel() 
    local seat = GetSeat()
    local car = seat and seat:FindFirstAncestorOfClass("Model")
    if not car then car = seat and seat.Parent if car and not car:IsA("Model") then car = nil end end
    return car
end

-- ══════════════════════════════════════════════
-- Core Functions (Optimized for Console-Based Execution)
-- ══════════════════════════════════════════════

-- Auto Drive Farm Logic (Fixed Car Movement & Optimized)
local AutoFarmDriveLoop = nil
local function StartAutoDriveFarm()
    if AutoFarmDriveLoop then return end -- Already running
    local seat = GetSeat() 
    if not seat or not seat:IsA("VehicleSeat") then 
        warn("Rive Hub: Auto Drive Farm requires you to be in a car!")
        return 
    end
    
    AutoFarmDriveLoop = RunService.Heartbeat:Connect(function()
        if not _G.RiveHub_AutoDriveFarmEnabled or not Character or not Humanoid then 
            if AutoFarmDriveLoop then AutoFarmDriveLoop:Disconnect() AutoFarmDriveLoop = nil end
            return 
        end
        local cs = Humanoid.SeatPart 
        if not cs or not cs:IsA("VehicleSeat") then 
            warn("Rive Hub: Exited car, stopping Auto Drive Farm.")
            _G.RiveHub_AutoDriveFarmEnabled = false -- Disable toggle
            if AutoFarmDriveLoop then AutoFarmDriveLoop:Disconnect() AutoFarmDriveLoop = nil end 
            return 
        end
        
        -- Apply throttle and gentle steering to simulate driving
        cs.Throttle = 1 
        cs.Steer = math.sin(tick()*0.5)*0.3 -- Gentle steering for movement
        cs.MaxSpeed = _G.RiveHub_CarSpeed 
        
        -- Auto Collect (Less frequent checks, direct touch)
        if HRP then
            if RunService.Heartbeat:Wait() % 0.5 < 0.1 then 
                for _,obj in pairs(Workspace:GetChildren()) do 
                    if obj:IsA("BasePart") then
                        local d = (HRP.Position - obj.Position).Magnitude 
                        if d <= 30 then
                            local mn = {"Money","Cash","Coin","Gold","Riyal","فلوس","مال","نقود","ريال","CashPart","Reward","Collectible"}
                            for _,n in pairs(mn) do 
                                if obj.Name:lower():find(n:lower()) then
                                    pcall(function() firetouchinterest(HRP,obj,0) task.wait(0.05) firetouchinterest(HRP,obj,1) end) 
                                    break 
                                end 
                            end
                        end 
                    end 
                end
            end
        end
    end)
    print("Rive Hub: Auto Drive Farm started at speed " .. _G.RiveHub_CarSpeed .. "!")
end

local function StopAutoDriveFarm()
    if AutoFarmDriveLoop then AutoFarmDriveLoop:Disconnect() AutoFarmDriveLoop = nil end
    local seat = GetSeat() 
    if seat and seat:IsA("VehicleSeat") then seat.Throttle = 0 seat.Steer = 0 seat.MaxSpeed = 50 end
    print("Rive Hub: Auto Drive Farm stopped.")
end

-- Anti-Fine Logic (Enhanced: RemoteEvent Hooking + Plate Hiding)
local AntiFineHook = nil
local AntiFinePlateLoop = nil
local function StartAntiFine()
    if AntiFineHook then return end -- Already running
    -- RemoteEvent Hooking to prevent fine events from reaching server
    if _hookmetamethod and _getrawmetatable then
        local mt = _getrawmetatable(game)
        if mt and mt.__namecall then
            _setreadonly(mt, false)
            local oldNamecall = mt.__namecall
            AntiFineHook = oldNamecall -- Store original for unhooking
            mt.__namecall = _newcclosure(function(self, ...)
                local method = (getnamecallmethod and getnamecallmethod()) or ""
                if method == "FireServer" then
                    local args = {...}
                    local fineEvents = {"SendFine", "ReportViolation", "TrafficViolation", "PoliceReport", "FinePlayer", "RadarEvent"} -- Added RadarEvent
                    for _, eventName in pairs(fineEvents) do
                        if typeof(self) == "Instance" and self:IsA("RemoteEvent") and self.Name == eventName then
                            return nil -- Block the RemoteEvent
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)
            _setreadonly(mt, true)
        end
    end

    -- Plate Hiding
    AntiFinePlateLoop = task.spawn(function()
        while _G.RiveHub_AntiFineEnabled do
            pcall(function()
                local car = GetCarModel()
                if car then
                    for _, part in pairs(car:GetDescendants()) do
                        if part:IsA("BasePart") and (part.Name:lower():match("plate") or part.Name:lower():match("لوحة")) then
                            part.Transparency = 1
                            if part:FindFirstChildOfClass("SurfaceGui") then part:FindFirstChildOfClass("SurfaceGui").Enabled = false end
                        end
                    end
                end
            end)
            task.wait(2) 
        end
    end)
    print("Rive Hub: Anti-Fine Protection activated!")
end

local function StopAntiFine()
    if AntiFineHook and _getrawmetatable then 
        local mt = _getrawmetatable(game) 
        pcall(_setreadonly, mt, false) 
        mt.__namecall = AntiFineHook 
        _setreadonly(mt, true)
        AntiFineHook = nil
    end
    if AntiFinePlateLoop then task.cancel(AntiFinePlateLoop) AntiFinePlateLoop = nil end
    pcall(function()
        local car = GetCarModel()
        if car then
            for _, part in pairs(car:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():match("plate") or part.Name:lower():match("لوحة")) then
                    part.Transparency = 0
                    if part:FindFirstChildOfClass("SurfaceGui") then part:FindFirstChildOfClass("SurfaceGui").Enabled = true end
                end
            end
        end
    end)
    print("Rive Hub: Anti-Fine Protection deactivated.")
end

-- Auto Paycheck Logic
local AutoPaycheckLoop = nil
local function StartAutoPaycheck()
    if AutoPaycheckLoop then return end
    AutoPaycheckLoop = task.spawn(function()
        while _G.RiveHub_AutoPaycheckEnabled do
            pcall(function()
                for _, gui in pairs(Player.PlayerGui:GetDescendants()) do
                    if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                        local text = ""
                        if gui:IsA("TextButton") then text = gui.Text:lower() end
                        if gui:FindFirstChildOfClass("TextLabel") then text = text .. " " .. gui:FindFirstChildOfClass("TextLabel").Text:lower() end
                        if text:match("claim") or text:match("paycheck") or text:match("collect") or text:match("استلام") or text:match("راتب") then
                            if gui.Active and gui.Visible and gui.Parent and gui.Parent.Visible then gui:Click() end
                        end
                    end
                end
            end)
            task.wait(5) 
        end
    end)
    print("Rive Hub: Auto Paycheck activated!")
end

local function StopAutoPaycheck()
    if AutoPaycheckLoop then task.cancel(AutoPaycheckLoop) AutoPaycheckLoop = nil end
    print("Rive Hub: Auto Paycheck deactivated.")
end

-- Noclip Logic
local NoclipLoop = nil
local function StartNoclip()
    if NoclipLoop then return end
    NoclipLoop = task.spawn(function()
        while _G.RiveHub_NoclipEnabled and Character do
            pcall(function()
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
            task.wait(0.1)
        end
    end)
    print("Rive Hub: Noclip activated!")
end

local function StopNoclip()
    if NoclipLoop then task.cancel(NoclipLoop) NoclipLoop = nil end
    pcall(function()
        if Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)
    print("Rive Hub: Noclip deactivated.")
end

-- Infinite Jump Logic
local InfiniteJumpConn = nil
local function StartInfiniteJump()
    if InfiniteJumpConn then return end
    InfiniteJumpConn = UserInputService.JumpRequest:Connect(function()
        if _G.RiveHub_InfiniteJumpEnabled and Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    print("Rive Hub: Infinite Jump activated!")
end

local function StopInfiniteJump()
    if InfiniteJumpConn then InfiniteJumpConn:Disconnect() InfiniteJumpConn = nil end
    print("Rive Hub: Infinite Jump deactivated.")
}

-- Player ESP Logic
local PlayerESPLoop = nil
local PlayerESPObjects = {}
local function StartPlayerESP()
    if PlayerESPLoop then return end
    PlayerESPLoop = task.spawn(function()
        while _G.RiveHub_PlayerESPEnabled do
            pcall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local head = p.Character:FindFirstChild("Head")
                        if head and not PlayerESPObjects[p.Name] then
                            local box = Instance.new("BoxHandleAdornment", head)
                            box.Name = "PlayerESPBox"
                            box.Size = Vector3.new(2, 6, 1)
                            box.Color3 = Color3.fromRGB(255, 0, 0)
                            box.AlwaysOnTop = true
                            box.ZIndex = 10
                            box.Transparency = 0.5
                            box.Adornee = head

                            local nameTag = Instance.new("BillboardGui", head)
                            nameTag.Name = "PlayerESPNameTag"
                            nameTag.Size = UDim2.new(0, 100, 0, 20)
                            nameTag.StudsOffset = Vector3.new(0, 2, 0)
                            nameTag.AlwaysOnTop = true

                            local nameLabel = Instance.new("TextLabel", nameTag)
                            nameLabel.Size = UDim2.new(1, 0, 1, 0)
                            nameLabel.BackgroundTransparency = 1
                            nameLabel.Text = p.Name .. " [" .. math.floor((HRP.Position - p.Character.HumanoidRootPart.Position).Magnitude) .. "m]"
                            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            nameLabel.TextSize = 14
                            nameLabel.Font = Enum.Font.GothamBold
                            nameLabel.Parent = nameTag
                            PlayerESPObjects[p.Name] = {Box = box, NameTag = nameTag}
                        end
                    elseif PlayerESPObjects[p.Name] then 
                        PlayerESPObjects[p.Name].Box:Destroy()
                        PlayerESPObjects[p.Name].NameTag:Destroy()
                        PlayerESPObjects[p.Name] = nil
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
    print("Rive Hub: Player ESP activated!")
end

local function StopPlayerESP()
    if PlayerESPLoop then task.cancel(PlayerESPLoop) PlayerESPLoop = nil end
    pcall(function()
        for _, obj in pairs(PlayerESPObjects) do
            if obj.Box then obj.Box:Destroy() end
            if obj.NameTag then obj.NameTag:Destroy() end
        end
        PlayerESPObjects = {}
    end)
    print("Rive Hub: Player ESP deactivated.")
end

-- Anti-AFK Logic
local AntiAFKLoop = nil
local function StartAntiAFK()
    if AntiAFKLoop then return end
    AntiAFKLoop = task.spawn(function()
        while _G.RiveHub_AntiAFKEnabled do
            pcall(function()
                if Humanoid then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
                    task.wait(0.1)
                    Humanoid:ChangeState(Enum.HumanoidStateType.Running) 
                end
            end)
            task.wait(10) 
        end
    end)
    print("Rive Hub: Anti-AFK activated!")
end

local function StopAntiAFK()
    if AntiAFKLoop then task.cancel(AntiAFKLoop) AntiAFKLoop = nil end
    print("Rive Hub: Anti-AFK deactivated.")
end

-- Car Fly Logic
local CarFlyLoop = nil
local function StartCarFly()
    if CarFlyLoop then return end
    CarFlyLoop = RunService.Heartbeat:Connect(function()
        if _G.RiveHub_CarFlyEnabled and GetSeat() and GetCarModel() then
            local car = GetCarModel()
            local seat = GetSeat()
            if car and seat then
                local bodyVelocity = car:FindFirstChild("BodyVelocity")
                if not bodyVelocity then
                    bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bodyVelocity.Parent = car.PrimaryPart or car:FindFirstChildOfClass("BasePart")
                end
                bodyVelocity.Velocity = Vector3.new(0, UserInputService:IsKeyDown(Enum.KeyCode.Space) and 50 or (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and -50 or 0), 0)
            end
        end
    end)
    print("Rive Hub: Car Fly activated! (Space to go up, Ctrl to go down)")
end

local function StopCarFly()
    if CarFlyLoop then CarFlyLoop:Disconnect() CarFlyLoop = nil end
    pcall(function()
        local car = GetCarModel()
        if car then
            local bodyVelocity = car:FindFirstChild("BodyVelocity")
            if bodyVelocity then bodyVelocity:Destroy() end
        end
    end)
    print("Rive Hub: Car Fly deactivated.")
end

-- ══════════════════════════════════════════════
-- Initialization and Toggle Management
-- ══════════════════════════════════════════════

-- Function to apply settings from _G variables
local function ApplySettings()
    if _G.RiveHub_AutoDriveFarmEnabled then StartAutoDriveFarm() else StopAutoDriveFarm() end
    if _G.RiveHub_AntiFineEnabled then StartAntiFine() else StopAntiFine() end
    if _G.RiveHub_AutoPaycheckEnabled then StartAutoPaycheck() else StopAutoPaycheck() end
    if _G.RiveHub_NoclipEnabled then StartNoclip() else StopNoclip() end
    if _G.RiveHub_InfiniteJumpEnabled then StartInfiniteJump() else StopInfiniteJump() end
    if _G.RiveHub_PlayerESPEnabled then StartPlayerESP() else StopPlayerESP() end
    if _G.RiveHub_AntiAFKEnabled then StartAntiAFK() else StopAntiAFK() end
    if _G.RiveHub_CarFlyEnabled then StartCarFly() else StopCarFly() end

    -- Apply WalkSpeed and JumpPower directly
    if Humanoid then
        Humanoid.WalkSpeed = _G.RiveHub_WalkSpeed
        Humanoid.JumpPower = _G.RiveHub_JumpPower
    end
end

-- Initial application of settings
ApplySettings()

-- Listen for changes in _G variables (for console toggling)
_G.RiveHub_ToggleFeature = function(featureName, state)
    if _G["RiveHub_" .. featureName .. "Enabled"] ~= nil then
        _G["RiveHub_" .. featureName .. "Enabled"] = state
        ApplySettings()
        print("Rive Hub: " .. featureName .. " toggled to " .. tostring(state))
    else
        warn("Rive Hub: Feature '" .. featureName .. "' not found.")
    end
end

print("══════════════════════════════════════════════")
print("Rive Hub | Kingdom World Console Edition Loaded!")
print("Edit _G.RiveHub_ variables at the top of the script or use _G.RiveHub_ToggleFeature(featureName, state) in console.")
print("Example: _G.RiveHub_ToggleFeature("AutoDriveFarm", true)")
print("══════════════════════════════════════════════")

-- Check if in correct game
if game.PlaceId ~= 96796259580891 then -- Kingdom World PlaceId
    warn("Rive Hub: This script is intended for Kingdom World (PlaceId: 96796259580891). You are in a different game.")
end
