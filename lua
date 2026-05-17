-- ═══════════════════════════════════════════════════════════
-- Kingdom World | Bo.Sqr + Pro Bypass (Final Fix)
-- Optimized for Arceus X, Delta, and PC Executors
-- Combined with the structure of the script you provided
-- ═══════════════════════════════════════════════════════════

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
local _identifyexecutor = identifyexecutor or identifyExecutor or function() return "Unknown", "?" end

-- ══════════════════════════════════════════════════════════════
-- 🛡️ Anti-Detection / Anti-Ban Layer
-- ══════════════════════════════════════════════════════════════
do
    pcall(function()
        if hookfunction then
            hookfunction(game.Players.LocalPlayer.Kick, function()
                return task.wait(9e9)
            end)
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
                    if method == "Kick" and self == plr then
                        return nil
                    end
                    return oldNamecall(self, ...)
                end)
                _setreadonly(mt, true)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- Load Fluent UI (Same as your working script)
-- ═══════════════════════════════════════════════════════════
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Kingdom World | Pro Bypass",
    SubTitle = "by Bo.Sqr & Manus AI",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- ═══════════════════════════════════════════════════════════
-- Variables & Services
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local AutoFarmDriveActive = false
local AutoFarmSpeed = 80
local AutoFarmConn = nil
local AntiFineActive = false
local AutoPaycheckActive = false

-- Anti-AFK
Player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ═════════════════════ ⚙️ FUNCTIONS ═════════════════════

local function GetSeat() 
    return Humanoid and Humanoid.SeatPart 
end

local function GetCarModel() 
    local seat = GetSeat()
    return seat and seat:FindFirstAncestorOfClass("Model") 
end

local function Notify(title, content, duration)
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 5
    })
end

local function StartAutoFarmDrive(speed)
    if AutoFarmDriveActive then AutoFarmSpeed = speed return end
    local seat = GetSeat()
    if not seat or not seat:IsA("VehicleSeat") then 
        Notify("⚠️ تنبيه", "يجب أن تكون راكب سيارة أولاً!") 
        return 
    end
    
    AutoFarmDriveActive = true
    AutoFarmSpeed = speed
    Notify("🤖 تجميع تلقائي", "السيارة تمشي بسرعة " .. speed .. " وتجمع الفلوس!")
    
    AutoFarmConn = RunService.Heartbeat:Connect(function()
        if not AutoFarmDriveActive then return end
        local cs = Humanoid.SeatPart
        if not cs or not cs:IsA("VehicleSeat") then 
            AutoFarmDriveActive = false 
            if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn = nil end 
            return 
        end
        
        cs.Throttle = 1
        cs.Steer = math.sin(tick() * 0.5) * 0.3
        cs.MaxSpeed = AutoFarmSpeed
        cs.AssemblyLinearVelocity = cs.CFrame.LookVector * AutoFarmSpeed
        
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
    end)
end

local function StopAutoFarmDrive()
    AutoFarmDriveActive = false
    if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn = nil end
    local seat = GetSeat()
    if seat and seat:IsA("VehicleSeat") then
        seat.Throttle = 0
        seat.Steer = 0
    end
    Notify("🛑", "تم إيقاف التجميع التلقائي")
end

-- ═════════════════════ 🎨 TABS ═════════════════════
local Tabs = {
    Main = Window:AddTab({ Title = "💸 تجميع فلوس", Icon = "dollar-sign" }),
    Player = Window:AddTab({ Title = "🏃 اللاعب", Icon = "user" }),
    Settings = Window:AddTab({ Title = "⚙️ الإعدادات", Icon = "settings" })
}

-- ── MAIN TAB ──────────────────────────────────────
Tabs.Main:AddSection("تجميع تلقائي (Auto Farm)")

local FarmToggle = Tabs.Main:AddToggle("AutoFarmDrive", { Title = "🚗 قيادة تلقائية (Auto Drive)", Default = false })
FarmToggle:OnChanged(function()
    if Options.AutoFarmDrive.Value then
        StartAutoFarmDrive(AutoFarmSpeed)
    else
        StopAutoFarmDrive()
    end
end)

Tabs.Main:AddSlider("FarmSpeed", {
    Title = "⚡ سرعة التجميع",
    Description = "تحكم في سرعة السيارة أثناء التجميع",
    Default = 80,
    Min = 20,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        AutoFarmSpeed = Value
        if AutoFarmDriveActive then StartAutoFarmDrive(Value) end
    end
})

Tabs.Main:AddSection("حماية إضافية")

Tabs.Main:AddToggle("AntiFine", { Title = "🛡️ إخفاء اللوحة (Anti-Fine)", Default = false }):OnChanged(function()
    AntiFineActive = Options.AntiFine.Value
    if AntiFineActive then
        task.spawn(function()
            while AntiFineActive do
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
        end)
    end
end)

Tabs.Main:AddToggle("AutoPaycheck", { Title = "💰 جمع الرواتب (Auto Paycheck)", Default = false }):OnChanged(function()
    AutoPaycheckActive = Options.AutoPaycheck.Value
    if AutoPaycheckActive then
        task.spawn(function()
            while AutoPaycheckActive do
                pcall(function()
                    for _, gui in pairs(Player.PlayerGui:GetDescendants()) do
                        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                            local text = ""
                            if gui:IsA("TextButton") then text = gui.Text:lower() end
                            if gui:FindFirstChildOfClass("TextLabel") then text = text .. " " .. gui:FindFirstChildOfClass("TextLabel").Text:lower() end
                            
                            if text:match("claim") or text:match("paycheck") or text:match("collect") or text:match("استلام") or text:match("راتب") then
                                local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
                                for _, event in pairs(events) do
                                    for _, connection in pairs(getconnections(gui[event])) do
                                        connection:Fire()
                                    end
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

-- ── PLAYER TAB ──────────────────────────────────────
Tabs.Player:AddSection("تعديلات اللاعب")

Tabs.Player:AddSlider("WalkSpeed", {
    Title = "⚡ السرعة",
    Default = 16,
    Min = 16,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        Humanoid.WalkSpeed = Value
    end
})

Tabs.Player:AddSlider("JumpPower", {
    Title = "🦘 القفز",
    Default = 50,
    Min = 50,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        Humanoid.JumpPower = Value
    end
})

Tabs.Player:AddToggle("Noclip", { Title = "👻 اختراق الجدران (Noclip)", Default = false }):OnChanged(function()
    _G.Noclip = Options.Noclip.Value
    if _G.Noclip then
        RunService.Stepped:Connect(function()
            if _G.Noclip and Character then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end)

-- ── SETTINGS TAB ──────────────────────────────────────
Tabs.Settings:AddButton({
    Title = "❌ إغلاق السكربت",
    Callback = function()
        Window:Destroy()
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("KingdomWorldPro")
SaveManager:SetFolder("KingdomWorldPro/main")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Notify("✅ تم التحميل", "سكربت Kingdom World جاهز للعمل!", 5)
