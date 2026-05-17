-- ══════════════════════════════════════════════
-- Bo.Sqr | Kingdom World Ultimate Farm Edition
-- Universal Executor Support (Arceus X, Delta, etc.)
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
-- 🛡️ Anti-Detection / Anti-Ban Layer (From Working Script)
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

-- Safe GUI parent
local function _safeGuiParent(gui)
    local ok = pcall(function()
        if gethui then gui.Parent = gethui() else gui.Parent = game:GetService("CoreGui") end
    end)
    if not ok or not gui.Parent then
        gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
end
_G._safeGuiParent = _safeGuiParent

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
-- Load Fluent UI (Exact same method as working script)
-- ══════════════════════════════════════════════
local Fluent, SaveManager, InterfaceManager
local _fluentOk = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not _fluentOk or not Fluent then
    warn("Failed to load Fluent UI")
    return
end

local Window = Fluent:CreateWindow({
    Title = "Bo.Sqr | Kingdom World Ultimate",
    SubTitle = "Auto Farm Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Farm = Window:AddTab({ Title = "تجميع فلوس", Icon = "coins" }),
    Player = Window:AddTab({ Title = "اللاعب", Icon = "user" }),
    Misc = Window:AddTab({ Title = "أخرى", Icon = "wrench" })
}

-- ══════════════════════════════════════════════
-- Variables & Services
-- ══════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

-- Global States
local AutoFarmDriveActive = false
local AutoFarmSpeed = 80
local AutoFarmConn = nil
local AntiFineActive = false
local AutoPaycheckActive = false

-- ══════════════════════════════════════════════
-- Functions
-- ══════════════════════════════════════════════

local function StartAutoFarmDrive(speed)
    if AutoFarmDriveActive then AutoFarmSpeed = speed return true end
    local seat = GetSeat() 
    if not seat or not seat:IsA("VehicleSeat") then 
        Fluent:Notify({Title = "تنبيه", Content = "يجب أن تكون راكب سيارة أولاً!", Duration = 3})
        return false 
    end
    
    AutoFarmDriveActive = true 
    AutoFarmSpeed = speed
    Fluent:Notify({Title = "تجميع تلقائي", Content = "السيارة تمشي بسرعة "..speed.." وتجمع الفلوس!", Duration = 4})
    
    AutoFarmConn = RunService.Heartbeat:Connect(function()
        if not AutoFarmDriveActive or not Character or not Humanoid then return end
        local cs = Humanoid.SeatPart 
        if not cs or not cs:IsA("VehicleSeat") then 
            AutoFarmDriveActive = false 
            if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn = nil end 
            return 
        end
        
        -- Direct velocity manipulation (from working script)
        cs.Throttle = 1 
        cs.Steer = math.sin(tick()*0.5)*0.3 
        cs.MaxSpeed = AutoFarmSpeed 
        cs.AssemblyLinearVelocity = cs.CFrame.LookVector * AutoFarmSpeed
        
        -- Auto Collect
        if HRP then
            for _,obj in pairs(workspace:GetDescendants()) do 
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
    end) 
    return true
end

local function StopAutoFarmDrive()
    AutoFarmDriveActive = false 
    if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn = nil end
    local seat = GetSeat() 
    if seat and seat:IsA("VehicleSeat") then seat.Throttle = 0 seat.Steer = 0 seat.MaxSpeed = 50 end
    Fluent:Notify({Title = "توقف", Content = "تم إيقاف التجميع التلقائي", Duration = 3})
end

-- ══════════════════════════════════════════════
-- UI Elements
-- ══════════════════════════════════════════════

-- Farm Tab
Tabs.Farm:AddParagraph({ Title = "تجميع الفلوس", Content = "اركب سيارة ثم فعل التجميع التلقائي." })

local FarmToggle = Tabs.Farm:AddToggle("AutoFarmToggle", {Title = "🚗 قيادة وتجميع تلقائي", Default = false})
FarmToggle:OnChanged(function(state)
    if state then
        local success = StartAutoFarmDrive(AutoFarmSpeed)
        if not success then FarmToggle:SetValue(false) end
    else
        StopAutoFarmDrive()
    end
end)

Tabs.Farm:AddSlider("FarmSpeedSlider", {
    Title = "⚡ سرعة السيارة",
    Description = "تحكم في سرعة التجميع",
    Default = 80,
    Min = 20,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        AutoFarmSpeed = Value
    end
})

local AntiFineToggle = Tabs.Farm:AddToggle("AntiFineToggle", {Title = "🛡️ إخفاء اللوحة (Anti-Fine)", Default = false})
AntiFineToggle:OnChanged(function(state)
    AntiFineActive = state
    task.spawn(function()
        while AntiFineActive do
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
        -- Restore
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
    end)
end)

local PaycheckToggle = Tabs.Farm:AddToggle("PaycheckToggle", {Title = "💰 جمع الرواتب تلقائياً", Default = false})
PaycheckToggle:OnChanged(function(state)
    AutoPaycheckActive = state
    task.spawn(function()
        while AutoPaycheckActive do
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
end)

-- Player Tab
Tabs.Player:AddSlider("WalkSpeedSlider", {
    Title = "سرعة المشي",
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        if Humanoid then Humanoid.WalkSpeed = Value end
    end
})

Tabs.Player:AddSlider("JumpPowerSlider", {
    Title = "قوة القفز",
    Default = 50,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        if Humanoid then Humanoid.JumpPower = Value end
    end
})

-- Misc Tab
Tabs.Misc:AddButton({
    Title = "إغلاق السكربت",
    Description = "يغلق الواجهة ويوقف جميع الميزات",
    Callback = function()
        StopAutoFarmDrive()
        AntiFineActive = false
        AutoPaycheckActive = false
        Window:Destroy()
    end
})

Window:SelectTab(1)
Fluent:Notify({
    Title = "Bo.Sqr Edition",
    Content = "تم تحميل السكربت بنجاح!",
    Duration = 5
})
