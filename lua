-- ══════════════════════════════════════════════
-- Kingdom World | Lite Edition (Optimized for Weak Devices)
-- Based on Bo.Sqr / HM HUB structure with Orion UI
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
-- 🛡️ Anti-Detection / Anti-Ban Layer (From User's Working Script)
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
-- Language Selection (From User's Working Script)
-- ══════════════════════════════════════════════
local v1 = {
    ar = {
        KickMessage = 'هذا السكربت يعمل فقط في لعبة Kingdom World!',
        WindowName = 'HM HUB|KINGDOM WORLD V2',
        IntroText = 'HM HUB|KINGDOM WORLD V2',
        MainTab = 'الرئيسي',
        PlacesESP = 'Places ESP',
        EnablePlacesESP = 'تفعيل Places ESP',
        TeleportPlaces = 'التنقل إلى الأماكن',
        Teleport = 'الذهاب إلى: ',
        RandomTeleport = 'نقل عشوائي',
        AutoReal = 'Auto Real',
        Speed = 'سرعة المشي',
        Jump = 'قوة القفزة',
        InputCustom = 'ادخال سرعة وقفزة يدوياً',
        Combat = 'القتال',
        EscapePolice = 'الهروب من الشرطة',
        TeamESP = 'Team ESP (كل فريق بلون)',
        EnableTeamESP = 'تفعيل Team ESP',
        CriminalTP = 'التنقل إلى مجرم عشوائي',
        Creators = 'المطورون',
        FollowYoutube = 'تابع قناتنا على يوتيوب',
        Copied = 'تم النسخ ✅',
        Loading = 'تم التحديث! تابع قناتنا على يوتيوب لمزيد من الأدوات: hazarobloxscripts',
        TerrorizeTab = 'تخريب',
        AnnoyPlayers = 'ازعاج اللاعبين',
        FarmTab = 'تجميع فلوس',
        AutoDrive = 'قيادة تلقائية',
        CarSpeed = 'سرعة السيارة',
        AntiFine = 'إخفاء اللوحة (Anti-Fine)',
        AutoPaycheck = 'جمع الرواتب تلقائياً',
        Noclip = 'اختراق الجدران (Noclip)',
        InfiniteJump = 'قفز لا نهائي',
        PlayerESP = 'كشف اللاعبين (ESP)',
        FlingPlayers = 'رمي اللاعبين (Fling All)',
        FreezePlayers = 'تجميد اللاعبين (Freeze All)',
        UnfreezePlayers = 'إلغاء تجميد اللاعبين (Unfreeze All)',
        CloseScript = 'إغلاق السكربت',
    },
    en = {
        KickMessage = 'This script only works in Kingdom World!',
        WindowName = 'HM HUB|KINGDOM WORLD V2',
        IntroText = 'HM HUB|KINGDOM WORLD V2',
        MainTab = 'Main',
        PlacesESP = 'Places ESP',
        EnablePlacesESP = 'Enable Places ESP',
        TeleportPlaces = 'Teleport to Places',
        Teleport = 'Go to: ',
        RandomTeleport = 'Random Teleport',
        AutoReal = 'Auto Real',
        Speed = 'Walk Speed',
        Jump = 'Jump Power',
        InputCustom = 'Enter Speed & Jump Manually',
        Combat = 'Combat',
        EscapePolice = 'Escape Police',
        TeamESP = 'Team ESP (Colored Teams)',
        EnableTeamESP = 'Enable Team ESP',
        CriminalTP = 'Teleport to Random Criminal',
        Creators = 'Creators',
        FollowYoutube = 'Follow us on YouTube',
        Copied = 'Copied ✅',
        Loading = 'Updated! Follow our YouTube channel for more tools: hazarobloxscripts',
        TerrorizeTab = 'Terrorize',
        AnnoyPlayers = 'Annoy Players',
        FarmTab = 'Money Farm',
        AutoDrive = 'Auto Drive',
        CarSpeed = 'Car Speed',
        AntiFine = 'Hide Plate (Anti-Fine)',
        AutoPaycheck = 'Auto Paycheck',
        Noclip = 'Noclip',
        InfiniteJump = 'Infinite Jump',
        PlayerESP = 'Player ESP',
        FlingPlayers = 'Fling All Players',
        FreezePlayers = 'Freeze All Players',
        UnfreezePlayers = 'Unfreeze All Players',
        CloseScript = 'Close Script',
    },
}
local u2 = nil

(function()
    local _ScreenGui = Instance.new('ScreenGui', game.Players.LocalPlayer:WaitForChild('PlayerGui'))
    local _Frame = Instance.new('Frame', _ScreenGui)

    _Frame.Size = UDim2.new(0, 250, 0, 150)
    _Frame.Position = UDim2.new(0.5, -125, 0.5, -75)
    _Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    _Frame.BorderSizePixel = 2
    _Frame.BorderColor3 = Color3.fromRGB(0, 170, 255)

    local _TextLabel = Instance.new('TextLabel', _Frame)

    _TextLabel.Size = UDim2.new(1, 0, 0.3, 0)
    _TextLabel.Position = UDim2.new(0, 0, 0.1, 0)
    _TextLabel.Text = 'اختر لغتك | Choose Language'
    _TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    _TextLabel.BackgroundTransparency = 1
    _TextLabel.Font = Enum.Font.SourceSansBold
    _TextLabel.TextScaled = true
    _TextLabel.TextWrapped = true

    local _TextButton = Instance.new('TextButton', _Frame)

    _TextButton.Size = UDim2.new(0.4, 0, 0.3, 0)
    _TextButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    _TextButton.Text = 'العربية'
    _TextButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    _TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    _TextButton.Font = Enum.Font.SourceSansBold
    _TextButton.BorderSizePixel = 0

    local _TextButton2 = Instance.new('TextButton', _Frame)

    _TextButton2.Size = UDim2.new(0.4, 0, 0.3, 0)
    _TextButton2.Position = UDim2.new(0.55, 0, 0.5, 0)
    _TextButton2.Text = 'English'
    _TextButton2.BackgroundColor3 = Color3.fromRGB(0, 85, 170)
    _TextButton2.TextColor3 = Color3.fromRGB(255, 255, 255)
    _TextButton2.Font = Enum.Font.SourceSansBold
    _TextButton2.BorderSizePixel = 0

    _TextButton.MouseButton1Click:Connect(function()
        u2 = 'ar'
        _ScreenGui:Destroy()
    end)
    _TextButton2.MouseButton1Click:Connect(function()
        u2 = 'en'
        _ScreenGui:Destroy()
    end)
end)()

repeat
    task.wait()
until u2 ~= nil

local u8 = v1[u2]

if game.PlaceId ~= 96796259580891 then
    local _ScreenGui = Instance.new('ScreenGui', game.Players.LocalPlayer:WaitForChild('PlayerGui'))
    local _Frame = Instance.new('Frame', _ScreenGui)
    _Frame.Size = UDim2.new(0, 250, 0, 100)
    _Frame.Position = UDim2.new(0.5, -125, 0.5, -50)
    _Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    _Frame.BorderSizePixel = 2
    _Frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    local _TextLabel = Instance.new('TextLabel', _Frame)
    _TextLabel.Size = UDim2.new(1, 0, 1, 0)
    _TextLabel.Text = u8.KickMessage
    _TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    _TextLabel.BackgroundTransparency = 1
    _TextLabel.Font = Enum.Font.SourceSansBold
    _TextLabel.TextScaled = true
    _TextLabel.TextWrapped = true
    task.wait(5)
    game.Players.LocalPlayer:Kick(u8.KickMessage)
    return
end

-- ══════════════════════════════════════════════
-- Load Orion UI (from user's working script)
-- ══════════════════════════════════════════════
local Orion = loadstring(game:HttpGet('https://raw.githubusercontent.com/jensonhirst/Orion/main/source'))()

local Window = Orion:MakeWindow({
    Name = u8.WindowName,
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = 'HMHUB',
    IntroEnabled = true,
    IntroText = u8.IntroText,
    IntroIcon = 'http://www.roblox.com/asset/?id=82795327169782',
})

-- ══════════════════════════════════════════════
-- Services & Variables
-- ══════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

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
local NoclipActive = false
local InfiniteJumpActive = false
local PlayerESPActive = false

-- ══════════════════════════════════════════════
-- Functions (Optimized for performance)
-- ══════════════════════════════════════════════

-- Auto Drive Farm Logic (Optimized)
local function StartAutoFarmDrive(speed)
    if AutoFarmDriveActive then AutoFarmSpeed = speed return true end
    local seat = GetSeat() 
    if not seat or not seat:IsA("VehicleSeat") then 
        Orion:MakeNotification({Name = "تنبيه", Content = "يجب أن تكون راكب سيارة أولاً!", Time = 3})
        return false 
    end
    
    AutoFarmDriveActive = true 
    AutoFarmSpeed = speed
    Orion:MakeNotification({Name = "تجميع تلقائي", Content = "السيارة تمشي بسرعة "..speed.." وتجمع الفلوس!", Time = 4})
    
    AutoFarmConn = RunService.Heartbeat:Connect(function()
        if not AutoFarmDriveActive or not Character or not Humanoid then return end
        local cs = Humanoid.SeatPart 
        if not cs or not cs:IsA("VehicleSeat") then 
            AutoFarmDriveActive = false 
            if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn = nil end 
            return 
        end
        
        -- Direct velocity manipulation (from working script, optimized)
        cs.Throttle = 1 
        cs.Steer = math.sin(tick()*0.5)*0.3 
        cs.MaxSpeed = AutoFarmSpeed 
        cs.AssemblyLinearVelocity = cs.CFrame.LookVector * AutoFarmSpeed
        
        -- Auto Collect (Optimized: less frequent checks, direct touch)
        if HRP then
            -- Only check for money objects every 0.5 seconds to reduce lag
            if RunService.Heartbeat:Wait() % 0.5 < 0.1 then 
                for _,obj in pairs(workspace:GetChildren()) do -- Check only direct children for common money spawns
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
    return true
end

local function StopAutoFarmDrive()
    AutoFarmDriveActive = false 
    if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn = nil end
    local seat = GetSeat() 
    if seat and seat:IsA("VehicleSeat") then seat.Throttle = 0 seat.Steer = 0 seat.MaxSpeed = 50 end
    Orion:MakeNotification({Name = "توقف", Content = "تم إيقاف التجميع التلقائي", Time = 3})
end

-- Anti-Fine Logic (Optimized)
local AntiFineLoop = nil
local function StartAntiFine()
    AntiFineActive = true
    AntiFineLoop = task.spawn(function()
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
            task.wait(2) -- Check less frequently
        end
    end)
end

local function StopAntiFine()
    AntiFineActive = false
    if AntiFineLoop then task.cancel(AntiFineLoop) AntiFineLoop = nil end
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
end

-- Auto Paycheck Logic (Optimized)
local AutoPaycheckLoop = nil
local function StartAutoPaycheck()
    AutoPaycheckActive = true
    AutoPaycheckLoop = task.spawn(function()
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
            task.wait(5) -- Check less frequently
        end
    end)
end

local function StopAutoPaycheck()
    AutoPaycheckActive = false
    if AutoPaycheckLoop then task.cancel(AutoPaycheckLoop) AutoPaycheckLoop = nil end
end

-- Noclip Logic
local NoclipLoop = nil
local function StartNoclip()
    NoclipActive = true
    NoclipLoop = task.spawn(function()
        while NoclipActive and Character do
            pcall(function()
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
            task.wait(0.1)
        end
    end)
end

local function StopNoclip()
    NoclipActive = false
    if NoclipLoop then task.cancel(NoclipLoop) NoclipLoop = nil end
    pcall(function()
        if Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end)
end

-- Infinite Jump Logic
local InfiniteJumpConn = nil
local function StartInfiniteJump()
    InfiniteJumpActive = true
    InfiniteJumpConn = UserInputService.JumpRequest:Connect(function()
        if InfiniteJumpActive and Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function StopInfiniteJump()
    InfiniteJumpActive = false
    if InfiniteJumpConn then InfiniteJumpConn:Disconnect() InfiniteJumpConn = nil end
end

-- Player ESP Logic
local PlayerESPLoop = nil
local PlayerESPObjects = {}
local function StartPlayerESP()
    PlayerESPActive = true
    PlayerESPLoop = task.spawn(function()
        while PlayerESPActive do
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
                    elseif PlayerESPObjects[p.Name] then -- Cleanup if player leaves or character disappears
                        PlayerESPObjects[p.Name].Box:Destroy()
                        PlayerESPObjects[p.Name].NameTag:Destroy()
                        PlayerESPObjects[p.Name] = nil
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

local function StopPlayerESP()
    PlayerESPActive = false
    if PlayerESPLoop then task.cancel(PlayerESPLoop) PlayerESPLoop = nil end
    pcall(function()
        for _, obj in pairs(PlayerESPObjects) do
            if obj.Box then obj.Box:Destroy() end
            if obj.NameTag then obj.NameTag:Destroy() end
        end
        PlayerESPObjects = {}
    end)
end

-- Teleport Locations (Example, adjust as needed)
local TeleportLocations = {
    {"Spawn", Vector3.new(0, 10, 0)},
    {"City Center", Vector3.new(1000, 10, 500)},
    {"Farming Zone 1", Vector3.new(-500, 10, -1000)},
}

local function TeleportToLocation(pos)
    if HRP then
        HRP.CFrame = CFrame.new(pos)
        Orion:MakeNotification({Name = "✅", Content = "تم الانتقال!", Time = 3})
    else
        Orion:MakeNotification({Name = "⚠️", Content = "لا يمكن الانتقال، الشخصية غير موجودة.", Time = 3})
    end
end

-- Trolling Functions
local function FlingPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local targetHRP = targetPlayer.Character.HumanoidRootPart
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(math.random(-500, 500), 500, math.random(-500, 500))
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = targetHRP
    task.delay(2, function() bv:Destroy() end)
    Orion:MakeNotification({Name = "😈", Content = "تم رمي "..targetPlayer.Name.."!", Time = 3})
end

local function FreezePlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    for _,p in pairs(targetPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true end end
    Orion:MakeNotification({Name = "🧊", Content = "تم تجميد "..targetPlayer.Name.."!", Time = 3})
end

local function UnfreezePlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    for _,p in pairs(targetPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=false end end
    Orion:MakeNotification({Name = "🔓", Content = "تم إلغاء تجميد "..targetPlayer.Name.."!", Time = 3})
end

-- ══════════════════════════════════════════════
-- UI Tabs and Elements
-- ══════════════════════════════════════════════

local MainTab = Window:MakeTab({
    Name = u8.MainTab,
    Icon = 'rbxassetid://4483345998',
    PremiumOnly = false,
})

-- Farm Tab
local FarmTab = Window:MakeTab({
    Name = u8.FarmTab,
    Icon = 'rbxassetid://4483345998',
    PremiumOnly = false,
})

FarmTab:AddSection({Name = u8.FarmTab})

FarmTab:AddToggle({
    Name = u8.AutoDrive,
    Default = false,
    Callback = function(state)
        if state then StartAutoFarmDrive(AutoFarmSpeed) else StopAutoFarmDrive() end
    end,
})

FarmTab:AddSlider({
    Name = u8.CarSpeed,
    Default = 80,
    Min = 20,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        AutoFarmSpeed = Value
    end
})

FarmTab:AddToggle({
    Name = u8.AntiFine,
    Default = false,
    Callback = function(state)
        if state then StartAntiFine() else StopAntiFine() end
    end,
})

FarmTab:AddToggle({
    Name = u8.AutoPaycheck,
    Default = false,
    Callback = function(state)
        if state then StartAutoPaycheck() else StopAutoPaycheck() end
    end,
})

-- Player Tab
local PlayerTab = Window:MakeTab({
    Name = u8.PlayerTab,
    Icon = 'rbxassetid://4483345998',
    PremiumOnly = false,
})

PlayerTab:AddSection({Name = u8.PlayerTab})

PlayerTab:AddSlider({
    Name = u8.Speed,
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        if Humanoid then Humanoid.WalkSpeed = Value end
    end
})

PlayerTab:AddSlider({
    Name = u8.Jump,
    Default = 50,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        if Humanoid then Humanoid.JumpPower = Value end
    end
})

PlayerTab:AddToggle({
    Name = u8.Noclip,
    Default = false,
    Callback = function(state)
        if state then StartNoclip() else StopNoclip() end
    end,
})

PlayerTab:AddToggle({
    Name = u8.InfiniteJump,
    Default = false,
    Callback = function(state)
        if state then StartInfiniteJump() else StopInfiniteJump() end
    end,
})

-- Teleport Tab
local TeleportTab = Window:MakeTab({
    Name = u8.TeleportPlaces,
    Icon = 'rbxassetid://4483345998',
    PremiumOnly = false,
})

TeleportTab:AddSection({Name = u8.TeleportPlaces})

for _, loc in pairs(TeleportLocations) do
    TeleportTab:AddButton({
        Name = u8.Teleport .. loc[1],
        Callback = function()
            TeleportToLocation(loc[2])
        end,
    })
end

-- Trolling Tab
local TrollingTab = Window:MakeTab({
    Name = u8.TerrorizeTab,
    Icon = 'rbxassetid://4483345998',
    PremiumOnly = false,
})

TrollingTab:AddSection({Name = u8.TerrorizeTab})

TrollingTab:AddButton({
    Name = u8.FlingPlayers,
    Callback = function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player then FlingPlayer(p) end
        end
    end,
})

TrollingTab:AddButton({
    Name = u8.FreezePlayers,
    Callback = function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player then FreezePlayer(p) end
        end
    end,
})

TrollingTab:AddButton({
    Name = u8.UnfreezePlayers,
    Callback = function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Player then UnfreezePlayer(p) end
        end
    end,
})

-- Visuals Tab
local VisualsTab = Window:MakeTab({
    Name = u8.PlayerESP,
    Icon = 'rbxassetid://4483345998',
    PremiumOnly = false,
})

VisualsTab:AddSection({Name = u8.PlayerESP})

VisualsTab:AddToggle({
    Name = u8.EnableTeamESP,
    Default = false,
    Callback = function(state)
        if state then StartPlayerESP() else StopPlayerESP() end
    end,
})

-- Misc Tab
local MiscTab = Window:MakeTab({
    Name = u8.Misc,
    Icon = 'rbxassetid://4483345998',
    PremiumOnly = false,
})

MiscTab:AddSection({Name = u8.Misc})

MiscTab:AddButton({
    Name = u8.CloseScript,
    Callback = function()
        StopAutoFarmDrive()
        StopAntiFine()
        StopAutoPaycheck()
        StopNoclip()
        StopInfiniteJump()
        StopPlayerESP()
        Window:Destroy()
    end
})

Orion:MakeNotification({
    Name = "Kingdom World Lite Edition",
    Content = "تم تحميل السكربت بنجاح!",
    Time = 5
})
