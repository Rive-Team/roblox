-- ═══════════════════════════════════════════════════════════
-- Kingdom World | Raw Script (Ultimate Compatibility)
-- No UI - All features controlled via global variables
-- Optimized for Arceus X, Delta, and PC Executors
-- ═══════════════════════════════════════════════════════════

-- ═══ Universal Executor Compatibility Layer ═══
-- Some executors don't provide getgenv() or it's named differently
local _getgenv = getgenv or function()
    if shared and type(shared) == "table" then return shared end
    return _G
end

-- Function compatibility shims for common executor functions
local _firetouchinterest = firetouchinterest or fireTouchInterest or fire_touch_interest or function(p1,p2,v) end -- no-op fallback
local _fireproximityprompt = fireproximityprompt or fireProximityPrompt or fire_proximity_prompt or function(p) if p and p.Triggered then p:Trigger() end end
local _hookmetamethod = hookmetamethod or hookMetaMethod or hook_metamethod or function() end
local _getrawmetatable = getrawmetatable or getRawMetatable or get_raw_metatable or function() return {} end
local _setreadonly = setreadonly or setReadOnly or set_readonly or function() end
local _newcclosure = newcclosure or newCClosure or new_c_closure or function(f) return f end

-- Make these globally accessible for easier use in features
firetouchinterest = _firetouchinterest
fireproximityprompt = _fireproximityprompt

-- ══════════════════════════════════════════════════════════════
-- 🛡️ Anti-Detection / Anti-Ban Layer (Robust & Compatible)
-- ══════════════════════════════════════════════════════════════
do
    -- 1. Block Kick (Direct method - hookfunction if available)
    pcall(function()
        if hookfunction then
            hookfunction(game.Players.LocalPlayer.Kick, function()
                return task.wait(9e9) -- Effectively blocks kick by waiting indefinitely
            end)
        end
    end)

    -- 2. Anti-Kick via __namecall (Fallback/Additional Layer)
    pcall(function()
        if _hookmetamethod and _getrawmetatable then
            local plr = game:GetService("Players").LocalPlayer
            local mt = _getrawmetatable(game)
            if mt and mt.__namecall then
                _setreadonly(mt, false)
                local oldNamecall = mt.__namecall
                mt.__namecall = _newcclosure(function(self, ...)
                    local method = (getnamecallmethod and getnamecallmethod()) or ""
                    if method == "Kick" and self == plr then
                        return nil -- Block the kick call
                    end
                    return oldNamecall(self, ...)
                end)
                _setreadonly(mt, true)
            end
        end
    end)

    -- 3. Basic Anti-Cheat Bypass (Avoids common detection patterns)
    -- This part is more about avoiding detection rather than direct hooking
    -- We'll rely on safe farming methods that don't trigger server-side checks
end

-- ═══════════════════════════════════════════════════════════
-- Services & Variables
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

-- Global feature toggles (User controls these directly)
_G.AutoDriveFarmEnabled = false -- Set to true to enable auto drive farm
_G.CarSpeed = 80               -- Adjust car speed (e.g., 100, 150, 200)
_G.AntiFineEnabled = false     -- Set to true to hide license plate
_G.AutoPaycheckEnabled = false -- Set to true to auto collect paychecks
_G.WalkSpeed = 16              -- Adjust walk speed (e.g., 30, 60, 100)
_G.InfiniteJumpEnabled = false -- Set to true for infinite jump
_G.NoclipEnabled = false       -- Set to true for noclip
_G.PlayerESPEnabled = false    -- Set to true for player ESP

-- Anti-AFK (using VirtualUser for broad compatibility)
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ═════════════════════ Helper Functions ═════════════════════
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end)

local function GetSeat() 
    return Humanoid and Humanoid.SeatPart 
end

local function GetCarModel() 
    local seat = GetSeat()
    local car = seat and seat:FindFirstAncestorOfClass("Model")
    if not car then
        car = seat and seat.Parent
        if car and not car:IsA("Model") then car = nil end
    end
    return car
end

-- ═════════════════════ ⚙️ FEATURES IMPLEMENTATION ═════════════════════

-- Auto Drive Farm Logic
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoDriveFarmEnabled then
            pcall(function()
                local seat = GetSeat()
                local car = GetCarModel()
                if seat and car and car.PrimaryPart then
                    local targetSpeed = _G.CarSpeed
                    local currentVelocity = car.PrimaryPart.AssemblyLinearVelocity
                    local targetVelocity = car.PrimaryPart.CFrame.LookVector * targetSpeed
                    
                    car.PrimaryPart.AssemblyLinearVelocity = currentVelocity:Lerp(targetVelocity, 0.1)
                    seat.Steer = math.sin(tick() * 0.5) * 0.3

                    local gyro = car.PrimaryPart:FindFirstChild("FarmGyro") or Instance.new("BodyGyro")
                    gyro.Name = "FarmGyro"
                    gyro.MaxTorque = Vector3.new(400000, 0, 400000)
                    gyro.P = 10000
                    gyro.CFrame = CFrame.new(car.PrimaryPart.Position)
                    gyro.Parent = car.PrimaryPart

                    -- Auto Collect Money Objects nearby
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            local d = (HRP.Position - obj.Position).Magnitude
                            if d <= 30 then
                                local mn = {"Money", "Cash", "Coin", "Gold", "Riyal", "فلوس", "مال", "نقود", "ريال", "CashPart", "Reward", "Collectible"}
                                for _, n in pairs(mn) do
                                    if obj.Name:lower():find(n:lower()) then
                                        pcall(function() 
                                            _firetouchinterest(HRP, obj, 0) 
                                            task.wait(0.05) 
                                            _firetouchinterest(HRP, obj, 1) 
                                        end)
                                        break
                                    end
                                end
                            end
                        end
                    end
                else
                    -- If not in car, disable auto drive to prevent errors
                    _G.AutoDriveFarmEnabled = false
                end
            end)
        else
            -- Cleanup when disabled
            pcall(function()
                local car = GetCarModel()
                local seat = GetSeat()
                if seat then seat.Steer = 0 end
                if car and car.PrimaryPart then
                    local gyro = car.PrimaryPart:FindFirstChild("FarmGyro")
                    if gyro then gyro:Destroy() end
                    car.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
                end
            end)
        end
    end
end)

-- Anti-Fine Logic
task.spawn(function()
    while task.wait(2) do
        if _G.AntiFineEnabled then
            pcall(function()
                local car = GetCarModel()
                if car then
                    for _, part in pairs(car:GetDescendants()) do
                        if part:IsA("BasePart") and (part.Name:lower():match("plate") or part.Name:lower():match("لوحة")) then
                            part.Transparency = 1
                            if part:FindFirstChildOfClass("SurfaceGui") then
                                part:FindFirstChildOfClass("SurfaceGui").Enabled = false
                            end
                        end
                    end
                end
            end)
        else
            pcall(function()
                local car = GetCarModel()
                if car then
                    for _, part in pairs(car:GetDescendants()) do
                        if part:IsA("BasePart") and (part.Name:lower():match("plate") or part.Name:lower():match("لوحة")) then
                            part.Transparency = 0
                            if part:FindFirstChildOfClass("SurfaceGui") then
                                part:FindFirstChildOfClass("SurfaceGui").Enabled = true
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Paycheck Logic
task.spawn(function()
    while task.wait(5) do
        if _G.AutoPaycheckEnabled then
            pcall(function()
                for _, gui in pairs(Player.PlayerGui:GetDescendants()) do
                    if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                        local text = ""
                        if gui:IsA("TextButton") then text = gui.Text:lower() end
                        if gui:FindFirstChildOfClass("TextLabel") then text = text .. " " .. gui:FindFirstChildOfClass("TextLabel").Text:lower() end
                        
                        if text:match("claim") or text:match("paycheck") or text:match("collect") or text:match("استلام") or text:match("راتب") then
                            if gui.Active and gui.Visible and gui.Parent and gui.Parent.Visible then
                                gui:Click()
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- WalkSpeed Logic
task.spawn(function()
    while task.wait(0.1) do
        if Humanoid then
            Humanoid.WalkSpeed = _G.WalkSpeed
        end
    end
end)

-- Infinite Jump Logic
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJumpEnabled and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Noclip Logic
task.spawn(function()
    while task.wait(0.1) do
        if _G.NoclipEnabled and Character then
            pcall(function()
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        else
            pcall(function()
                if Character then
                    for _, part in pairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = true end
                    end
                end
            end)
        end
    end
end)

-- Player ESP Logic
task.spawn(function()
    while task.wait(0.5) do
        if _G.PlayerESPEnabled then
            pcall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local head = p.Character:FindFirstChild("Head")
                        if head and not head:FindFirstChild("PlayerESPBox") then
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
                        end
                    end
                end
            end)
        else
            pcall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character then
                        local head = p.Character:FindFirstChild("Head")
                        if head then
                            local box = head:FindFirstChild("PlayerESPBox")
                            if box then box:Destroy() end
                            local nameTag = head:FindFirstChild("PlayerESPNameTag")
                            if nameTag then nameTag:Destroy() end
                        end
                    end
                end
            end)
        end
    end
end)

print("Kingdom World Raw Script Loaded! Control features via _G variables.")
-- Example usage in your executor console after executing this script:
-- _G.AutoDriveFarmEnabled = true
-- _G.CarSpeed = 120
-- _G.AntiFineEnabled = true
-- _G.WalkSpeed = 60
-- _G.InfiniteJumpEnabled = true
-- _G.NoclipEnabled = true
-- _G.PlayerESPEnabled = true
