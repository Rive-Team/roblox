-- ═══════════════════════════════════════════════════════════
-- Kingdom World | Super Edition (Final Fix)
-- Optimized for Arceus X, Delta, and PC Executors
-- Features: Embedded Lightweight UI, Robust Auto Farm, Anti-AFK, Full Features
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
local _identifyexecutor = identifyexecutor or identifyExecutor or function() return "Unknown", "?" end

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

-- Global feature toggles (for internal use and UI state)
_G.AutoDriveFarmEnabled = false
_G.AntiFineEnabled = false
_G.AutoPaycheckEnabled = false
_G.WalkSpeedEnabled = false
_G.JumpPowerEnabled = false
_G.NoclipEnabled = false
_G.PlayerESPEnabled = false
_G.CarSpeed = 80
_G.WalkSpeed = 16
_G.JumpPower = 50

-- Anti-AFK (using VirtualUser for broad compatibility)
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ═════════════════════ 🎨 EMBEDDED LIGHTWEIGHT UI ═════════════════════
-- Re-implementing a very basic, embedded UI to avoid external library issues
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KingdomWorldSuperEdition"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = Player:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 450) -- Increased height for more features
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "👑 Kingdom World Super Edition"
TitleText.TextColor3 = Color3.fromRGB(255, 215, 0)
TitleText.TextSize = 14
TitleText.Font = Enum.Font.GothamBold
TitleText.Parent = TitleBar

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -10, 1, -40)
ContentFrame.Position = UDim2.new(0, 5, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Adjusted by UIListLayout
ContentFrame.ScrollBarThickness = 4
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
ContentFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout", ContentFrame)
UIList.Padding = UDim.new(0, 5)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.AutomaticSize = Enum.AutomaticSize.Y

-- ═════════════════════ 🛠️ UI Helpers ═════════════════════
local function CreateSection(text)
    local Section = Instance.new("TextLabel")
    Section.Size = UDim2.new(1, 0, 0, 20)
    Section.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Section.Text = "◆ " .. text
    Section.TextColor3 = Color3.fromRGB(255, 215, 0)
    Section.TextSize = 12
    Section.Font = Enum.Font.GothamBold
    Section.TextXAlignment = Enum.TextXAlignment.Left
    Section.TextWrapped = true
    Section.Parent = ContentFrame
    return Section
end

local function CreateToggle(name, description, globalVarName, callback)
    local toggled = _G[globalVarName] or false
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 25)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Frame.Parent = ContentFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -35, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 220, 240)
    Label.TextSize = 11
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 30, 0, 15)
    ToggleBtn.Position = UDim2.new(1, -32, 0.5, -7.5)
    ToggleBtn.BackgroundColor3 = toggled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    ToggleBtn.Text = toggled and "ON" or "OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 9
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.Parent = Frame
    
    ToggleBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        ToggleBtn.Text = toggled and "ON" or "OFF"
        ToggleBtn.BackgroundColor3 = toggled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        _G[globalVarName] = toggled
        if callback then pcall(callback, toggled) end
    end)
    return Frame -- Return the frame for potential future use (e.g., adding description tooltip)
end

local function CreateSlider(name, description, globalVarName, min, max, default, callback)
    local currentVal = _G[globalVarName] or default
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Frame.Parent = ContentFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0.5, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. tostring(math.floor(currentVal))
    Label.TextColor3 = Color3.fromRGB(220, 220, 240)
    Label.TextSize = 11
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Slider = Instance.new("Slider")
    Slider.Size = UDim2.new(1, -10, 0, 15)
    Slider.Position = UDim2.new(0, 5, 0.5, 0)
    Slider.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Slider.BorderColor3 = Color3.fromRGB(255, 215, 0)
    Slider.Value = (currentVal - min) / (max - min)
    Slider.Parent = Frame

    Slider.Changed:Connect(function()
        local newValue = min + Slider.Value * (max - min)
        _G[globalVarName] = newValue
        Label.Text = name .. ": " .. tostring(math.floor(newValue))
        if callback then pcall(callback, newValue) end
    end)
    return Frame
end

local function CreateButton(name, description, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 25)
    Button.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamBold
    Button.Parent = ContentFrame

    Button.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
    return Button
end

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
    -- Try to find the car model by looking for a model ancestor of the seat
    local car = seat and seat:FindFirstAncestorOfClass("Model")
    if not car then
        -- Fallback: sometimes the car is the parent of the seat
        car = seat and seat.Parent
        if car and not car:IsA("Model") then car = nil end
    end
    return car
end

local function Notify(title, content, duration)
    -- Simple notification system (can be expanded)
    local NotificationFrame = Instance.new("Frame")
    NotificationFrame.Size = UDim2.new(0, 200, 0, 50)
    NotificationFrame.Position = UDim2.new(0.5, -100, 1, -60)
    NotificationFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    NotificationFrame.BorderSizePixel = 0
    NotificationFrame.Parent = ScreenGui
    NotificationFrame.ZIndex = 10

    Instance.new("UICorner", NotificationFrame).CornerRadius = UDim.new(0, 8)

    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, 0, 0.4, 0)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = title
    NotifTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    NotifTitle.TextSize = 14
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.Parent = NotificationFrame

    local NotifContent = Instance.new("TextLabel")
    NotifContent.Size = UDim2.new(1, 0, 0.6, 0)
    NotifContent.Position = UDim2.new(0, 0, 0.4, 0)
    NotifContent.BackgroundTransparency = 1
    NotifContent.Text = content
    NotifContent.TextColor3 = Color3.fromRGB(220, 220, 240)
    NotifContent.TextSize = 10
    NotifContent.Font = Enum.Font.Gotham
    NotifContent.Parent = NotificationFrame

    -- Tween in and out
    NotificationFrame:TweenPosition(UDim2.new(0.5, -100, 1, -60), "Out", "Quad", 0.5, true)
    task.delay(duration or 3, function()
        NotificationFrame:TweenPosition(UDim2.new(0.5, -100, 1, 50), "In", "Quad", 0.5, true, function()
            NotificationFrame:Destroy()
        end)
    end)
end

-- ═════════════════════ ⚙️ FEATURES ═════════════════════

-- Auto Farm Tab
CreateSection("💸 تجميع فلوس")

CreateToggle("🚗 قيادة تلقائية (Auto Drive)", "تجميع فلوس عن طريق قطع المسافات", "AutoDriveFarmEnabled", function(state)
    if state then
        task.spawn(function()
            while _G.AutoDriveFarmEnabled do
                pcall(function()
                    local seat = GetSeat()
                    local car = GetCarModel()
                    if seat and car and car.PrimaryPart then
                        -- Direct velocity manipulation for universal compatibility and to avoid 'call pack' errors
                        local targetSpeed = _G.CarSpeed -- Use global speed variable
                        local currentVelocity = car.PrimaryPart.AssemblyLinearVelocity
                        local targetVelocity = car.PrimaryPart.CFrame.LookVector * targetSpeed
                        
                        -- Smoothly interpolate towards target velocity
                        car.PrimaryPart.AssemblyLinearVelocity = currentVelocity:Lerp(targetVelocity, 0.1)
                        
                        -- Add slight random steering to simulate human-like driving
                        seat.Steer = math.sin(tick() * 0.5) * 0.3 -- Smooth, continuous steering

                        -- Keep car upright (BodyGyro is generally stable and helps with control)
                        local gyro = car.PrimaryPart:FindFirstChild("FarmGyro") or Instance.new("BodyGyro")
                        gyro.Name = "FarmGyro"
                        gyro.MaxTorque = Vector3.new(400000, 0, 400000)
                        gyro.P = 10000
                        gyro.CFrame = CFrame.new(car.PrimaryPart.Position)
                        gyro.Parent = car.PrimaryPart
                    end
                end)
                task.wait(0.1) -- Frequent updates for smooth movement
            end
            -- Cleanup after disabling
            pcall(function()
                local car = GetCarModel()
                local seat = GetSeat()
                if seat then seat.Steer = 0 end
                if car and car.PrimaryPart then
                    local gyro = car.PrimaryPart:FindFirstChild("FarmGyro")
                    if gyro then gyro:Destroy() end
                    car.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0,0,0) -- Stop the car
                end
            end)
        end)
    else
        -- Immediate cleanup on toggle off
        pcall(function()
            local car = GetCarModel()
            local seat = GetSeat()
            if seat then seat.Steer = 0 end
            if car and car.PrimaryPart then
                local gyro = car.PrimaryPart:FindFirstChild("FarmGyro")
                if gyro then gyro:Destroy() end
                car.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0,0,0) -- Stop the car
            end
        end)
    end
end)

CreateSlider("⚡ سرعة السيارة", "تحكم في سرعة السيارة أثناء التجميع", "CarSpeed", 20, 250, 80, function(value)
    _G.CarSpeed = value
    if _G.AutoDriveFarmEnabled then
        -- If auto drive is active, update speed immediately
        local seat = GetSeat()
        if seat and seat:IsA("VehicleSeat") then
            seat.MaxSpeed = value
        end
    end
end)

CreateToggle("🛡️ إخفاء اللوحة (Anti-Fine)", "يخفي اللوحة لتجنب المخالفات", "AntiFineEnabled", function(state)
    if state then
        task.spawn(function()
            while _G.AntiFineEnabled do
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
                task.wait(2)
            end
            -- Cleanup
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
end)

CreateToggle("💰 جمع الرواتب (Auto Paycheck)", "يجمع الرواتب تلقائياً فور ظهورها", "AutoPaycheckEnabled", function(state)
    if state then
        task.spawn(function()
            while _G.AutoPaycheckEnabled do
                pcall(function()
                    for _, gui in pairs(Player.PlayerGui:GetDescendants()) do
                        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                            local text = ""
                            if gui:IsA("TextButton") then text = gui.Text:lower() end
                            if gui:FindFirstChildOfClass("TextLabel") then text = text .. " " .. gui:FindFirstChildOfClass("TextLabel").Text:lower() end
                            
                            if text:match("claim") or text:match("paycheck") or text:match("collect") or text:match("استلام") or text:match("راتب") then
                                -- Simulate click using firetouchinterest on the GUI element if possible, or direct click
                                -- Direct click is generally safer for UI elements
                                if gui.Active and gui.Visible and gui.Parent and gui.Parent.Visible then
                                    gui:Click()
                                end
                            end
                        end
                    end
                end)
                task.wait(5)
            end
        end)
    end
end)

-- Player Tab
CreateSection("🏃 تعديلات اللاعب")

CreateSlider("⚡ السرعة (WalkSpeed)", "تغيير سرعة المشي", "WalkSpeed", 16, 100, 16, function(value)
    _G.WalkSpeed = value
    if Humanoid then Humanoid.WalkSpeed = value end
end)

CreateToggle("🦘 قفز لا نهائي (Infinite Jump)", "يسمح لك بالقفز بشكل مستمر", "JumpPowerEnabled", function(state)
    _G.JumpPowerEnabled = state
    if state then
        UserInputService.JumpRequest:Connect(function()
            if _G.JumpPowerEnabled and Humanoid then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

CreateToggle("👻 اختراق الجدران (Noclip)", "يسمح لك بالمرور عبر الجدران", "NoclipEnabled", function(state)
    if state then
        task.spawn(function()
            while _G.NoclipEnabled and Character do
                pcall(function()
                    for _, part in pairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end)
                task.wait(0.1)
            end
            -- Cleanup
            pcall(function()
                if Character then
                    for _, part in pairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = true end
                    end
                end
            end)
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
end)

-- Teleport Tab
CreateSection("🗺️ التنقل")

local TeleportLocations = {
    {"Spawn", Vector3.new(0, 10, 0)}, -- Example: Adjust coordinates as needed
    {"City Center", Vector3.new(1000, 10, 500)},
    {"Farming Zone 1", Vector3.new(-500, 10, -1000)},
}

for _, loc in pairs(TeleportLocations) do
    CreateButton("🚀 " .. loc[1], "الانتقال إلى " .. loc[1], function()
        if HRP then
            HRP.CFrame = CFrame.new(loc[2])
            Notify("✅", "تم الانتقال إلى " .. loc[1])
        else
            Notify("⚠️", "لا يمكن الانتقال، الشخصية غير موجودة.")
        end
    end)
end

-- Trolling Tab
CreateSection("😈 التخريب")

CreateButton("💥 رمي اللاعبين (Fling All)", "يرمي جميع اللاعبين بعيداً", function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = p.Character.HumanoidRootPart
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(math.random(-500, 500), 500, math.random(-500, 500))
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Parent = targetHRP
            task.delay(2, function() bv:Destroy() end)
        end
    end
    Notify("😈", "تم رمي جميع اللاعبين!")
end)

CreateButton("🧊 تجميد اللاعبين (Freeze All)", "يجمد جميع اللاعبين في مكانهم", function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            for _, part in pairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = true end
            end
        end
    end
    Notify("🧊", "تم تجميد جميع اللاعبين!")
end)

CreateButton("🔓 إلغاء تجميد اللاعبين (Unfreeze All)", "يلغي تجميد جميع اللاعبين", function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            for _, part in pairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = false end
            end
        end
    end
    Notify("🔓", "تم إلغاء تجميد جميع اللاعبين!")
end)

-- Visuals Tab
CreateSection("👁️ كشف اللاعبين (ESP)")

CreateToggle("👁️ تفعيل ESP", "يكشف أماكن اللاعبين وأسمائهم", "PlayerESPEnabled", function(state)
    if state then
        task.spawn(function()
            while _G.PlayerESPEnabled do
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
                                box.Adornee = head -- Adorn to head for better visibility

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
                task.wait(0.5)
            end
            -- Cleanup
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
            end)
        end)
    end
end)

-- Other Tab
CreateSection("❌ أخرى")

CreateButton("❌ إغلاق السكربت", "يغلق واجهة السكربت", function()
    ScreenGui:Destroy()
    -- Also clean up any active features
    _G.AutoDriveFarmEnabled = false
    _G.AntiFineEnabled = false
    _G.AutoPaycheckEnabled = false
    _G.WalkSpeedEnabled = false
    _G.JumpPowerEnabled = false
    _G.NoclipEnabled = false
    _G.PlayerESPEnabled = false
end)

print("Kingdom World Super Edition Loaded!")
Notify("✅ تم التحميل", "سكربت Kingdom World Super Edition جاهز للعمل!", 5)
