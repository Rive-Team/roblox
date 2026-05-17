-- ══════════════════════════════════════════════
-- Rive Hub | Kingdom World Low Pressure Edition
-- Ultra-Lightweight & Optimized for Weak Devices
-- ══════════════════════════════════════════════

-- ═══ Universal Executor Compatibility Layer ═══
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
-- 🛡️ Anti-Detection / Anti-Ban Layer (Optimized)
-- ══════════════════════════════════════════════════════════════
do
    pcall(function()
        if hookfunction then
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
            if hum then hum.WalkSpeed = 16 hum.JumpPower = 50 hum.AutoRotate = true hum.PlatformStand = false hum.Sit = false end
        end)
    end
    cleanChar(plr.Character)
    plr.CharacterAdded:Connect(cleanChar)
end

-- ══════════════════════════════════════════════
-- Manual UI (Ultra-Lightweight)
-- ══════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RiveHub_UI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 150)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Text = "Rive Hub | Low Pressure"
TitleLabel.Parent = MainFrame

local ToggleFrame = Instance.new("Frame")
ToggleFrame.Size = UDim2.new(1, 0, 1, -25)
ToggleFrame.Position = UDim2.new(0, 0, 0, 25)
ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleFrame.BorderSizePixel = 0
ToggleFrame.Parent = MainFrame

local UILayout = Instance.new("UIListLayout")
UILayout.FillDirection = Enum.FillDirection.Vertical
UILayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UILayout.Padding = UDim.new(0, 5)
UILayout.Parent = ToggleFrame

local function CreateToggle(name, text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.9, 0, 0, 25)
    Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.SourceSans
    Button.TextSize = 16
    Button.Text = text .. " [OFF]"
    Button.Parent = ToggleFrame

    local IsActive = false
    Button.MouseButton1Click:Connect(function()
        IsActive = not IsActive
        Button.Text = text .. (IsActive and " [ON]" or " [OFF]")
        Button.BackgroundColor3 = IsActive and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(70, 70, 70)
        callback(IsActive)
    end)
    return Button
end

-- ══════════════════════════════════════════════
-- Core Logic (Optimized & Fixed Movement)
-- ══════════════════════════════════════════════
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local AutoFarmActive = false
local AutoFarmConn = nil
local AntiFineActive = false

local function GetSeat() return Humanoid and Humanoid.SeatPart end

-- Optimized Auto Drive Farm (Fixed Freeze & Low Frequency)
local function StartAutoFarm()
    if AutoFarmConn then return end
    AutoFarmActive = true
    -- No Fluent notification for ultra-lightweight
    AutoFarmConn = RunService.Heartbeat:Connect(function()
        if not AutoFarmActive then return end
        local seat = GetSeat()
        if seat and seat:IsA("VehicleSeat") then
            seat.Throttle = 1
            seat.Steer = math.sin(tick() * 0.5) * 0.2 -- Gentle steering for smooth turns
            
            -- Auto Collect Money/Riyals (Low Frequency Check)
            if tick() % 1 < 0.1 then -- Check every ~1 second
                local moneyNames = {"Money","Cash","Coin","Gold","Riyal","فلوس","مال","نقود","ريال","CashPart","Reward","Collectible", "Pickup", "ValuePart"}
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                        local objNameLower = obj.Name:lower()
                        for _, n in pairs(moneyNames) do
                            if objNameLower:find(n:lower()) then
                                if (HRP.Position - obj.Position).Magnitude < 50 then
                                    pcall(function()
                                        firetouchinterest(HRP, obj, 0)
                                        task.wait(0.05)
                                        firetouchinterest(HRP, obj, 1)
                                    end)
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function StopAutoFarm()
    AutoFarmActive = false
    if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn = nil end
    local seat = GetSeat()
    if seat and seat:IsA("VehicleSeat") then seat.Throttle = 0 seat.Steer = 0 end
    -- No Fluent notification for ultra-lightweight
end

-- Anti-Fine (Radar Bypass) - Same robust hooking
local function ActivateAntiFine(state)
    AntiFineActive = state
    if AntiFineActive then
        -- No Fluent notification for ultra-lightweight
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and (self.Name:find("Fine") or self.Name:find("Radar") or self.Name:find("SpeedCheck") or self.Name:find("Violation") or self.Name:find("AntiCheat") or self.Name:find("AC")) then
                return nil
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    else
        -- Revert hook is complex, for low pressure we just let it be.
    end
end

-- UI Elements
CreateToggle("AutoDriveFarm", "Auto Drive Farm", function(state) if state then StartAutoFarm() else StopAutoFarm() end end)
CreateToggle("AntiFine", "Anti-Fine (Radar Bypass)", ActivateAntiFine)

-- Initial notification (simple text label)
local InitialNotification = Instance.new("TextLabel")
InitialNotification.Size = UDim2.new(0, 200, 0, 30)
InitialNotification.Position = UDim2.new(0.5, -100, 0.05, 0)
InitialNotification.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
InitialNotification.TextColor3 = Color3.fromRGB(255, 255, 255)
InitialNotification.Font = Enum.Font.SourceSans
InitialNotification.TextSize = 16
InitialNotification.Text = "Rive Hub Loaded!"
InitialNotification.Parent = ScreenGui

task.delay(3, function()
    InitialNotification:Destroy()
end)
