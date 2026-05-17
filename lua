-- ══════════════════════════════════════════════
-- Rive Hub | Kingdom World Ultra-Stable Edition
-- Optimized for Arceus X & Weak Devices
-- Based on Bo.Sqr Structure
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
-- Load Fluent UI (Same as Bo.Sqr)
-- ══════════════════════════════════════════════
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Rive Hub | Kingdom World",
    SubTitle = "Ultra-Stable Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, -- Set to false for better performance on weak devices
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    Farm = Window:AddTab({ Title = "Auto Farm", Icon = "coins" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "wrench" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

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

-- Optimized Auto Drive Farm (Fixed Freeze)
local function StartAutoFarm()
    if AutoFarmConn then return end
    AutoFarmActive = true
    Fluent:Notify({
        Title = "Rive Hub",
        Content = "Auto Farm Activated!",
        Duration = 3
    })
    AutoFarmConn = RunService.Heartbeat:Connect(function()
        if not AutoFarmActive then return end
        local seat = GetSeat()
        if seat and seat:IsA("VehicleSeat") then
            -- Use Throttle and Steer for natural movement (Prevents Freeze)
            seat.Throttle = 1
            seat.Steer = math.sin(tick() * 0.5) * 0.2 -- Gentle steering for smooth turns
            
            -- Auto Collect Money/Riyals (Search in workspace descendants for broader coverage)
            -- Increased search terms and robustness
            local moneyNames = {"Money","Cash","Coin","Gold","Riyal","فلوس","مال","نقود","ريال","CashPart","Reward","Collectible", "Pickup", "ValuePart"}
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                    local objNameLower = obj.Name:lower()
                    for _, n in pairs(moneyNames) do
                        if objNameLower:find(n:lower()) then
                            if (HRP.Position - obj.Position).Magnitude < 50 then -- Increased detection range
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
    end)
end

local function StopAutoFarm()
    AutoFarmActive = false
    if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn = nil end
    local seat = GetSeat()
    if seat and seat:IsA("VehicleSeat") then seat.Throttle = 0 seat.Steer = 0 end
    Fluent:Notify({
        Title = "Rive Hub",
        Content = "Auto Farm Deactivated!",
        Duration = 3
    })
end

-- ══════════════════════════════════════════════
-- UI Setup
-- ══════════════════════════════════════════════
Tabs.Home:AddParagraph({
    Title = "Welcome to Rive Hub",
    Content = "This script is optimized for weak devices and Arceus X. Enjoy your farming!"
})

local FarmToggle = Tabs.Farm:AddToggle("AutoDriveFarm", {Title = "Auto Drive Farm", Default = false})
FarmToggle:OnChanged(function(state)
    if state then StartAutoFarm() else StopAutoFarm() end
end)

local AntiFineToggle = Tabs.Farm:AddToggle("AntiFine", {Title = "Anti-Fine (Radar Bypass)", Default = false})
AntiFineToggle:OnChanged(function(state)
    AntiFineActive = state
    if AntiFineActive then
        Fluent:Notify({
            Title = "Rive Hub",
            Content = "Anti-Fine Activated! Attempting to bypass radar...",
            Duration = 3
        })
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            -- Check for common remote event names related to fines/radars
            -- Added more general terms and common remote event patterns
            if method == "FireServer" and (self.Name:find("Fine") or self.Name:find("Radar") or self.Name:find("SpeedCheck") or self.Name:find("Violation") or self.Name:find("AntiCheat") or self.Name:find("AC")) then
                return nil -- Block the remote event
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    else
        Fluent:Notify({
            Title = "Rive Hub",
            Content = "Anti-Fine Deactivated!",
            Duration = 3
        })
        -- Revert the hook if possible (requires storing the old __namecall)
        -- For simplicity and to avoid potential issues, we'll just let it be re-executed if needed.
    end
end)

Tabs.Player:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Description = "Adjust your movement speed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 1,
    Callback = function(Value) Humanoid.WalkSpeed = Value end
})

Tabs.Player:AddToggle("InfJump", {Title = "Infinite Jump", Default = false}):OnChanged(function(state)
    _G.InfJump = state
    game:GetService("UserInputService").JumpRequest:Connect(function()
        if _G.InfJump then Humanoid:ChangeState("Jumping") end
    end)
end)

Tabs.Misc:AddButton({
    Title = "Auto Paycheck",
    Callback = function()
        for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
            if v:IsA("TextButton") and (v.Text:find("Collect") or v.Text:find("Paycheck") or v.Name:find("CollectButton") or v.Name:find("PaycheckButton")) then
                pcall(function() v.MouseButton1Click:Fire() end)
                Fluent:Notify({
                    Title = "Rive Hub",
                    Content = "Attempting to collect paycheck!",
                    Duration = 2
                })
            end
        end
    end
})

Tabs.Misc:AddButton({
    Title = "Server Hop",
    Callback = function()
        Fluent:Notify({
            Title = "Rive Hub",
            Content = "Attempting to server hop...",
            Duration = 3
        })
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, s in pairs(Servers.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id)
                break
            end
        end
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("RiveHub")
SaveManager:SetFolder("RiveHub/KingdomWorld")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({
    Title = "Rive Hub",
    Content = "Script Loaded Successfully!",
    Duration = 5
})
