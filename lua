-- ══════════════════════════════════════════════
-- Bo.Sqr | MM2 + Kingdom World
-- Universal Executor Support
-- Xeno | Delta | Arceus X | Velocity | Hydrogen | Solara | Wave
-- Discord: discord.gg/Riveteam
-- ══════════════════════════════════════════════

-- ═══ Universal Executor Compatibility Layer ═══
-- بعض الإكسيكيوترات لا توفر getgenv() أو يختلف الاسم
local _getgenv = getgenv or function()
    if shared and type(shared) == "table" then return shared end
    return _G
end

-- Function compatibility shims
local _firetouchinterest = firetouchinterest or fireTouchInterest or fire_touch_interest
    or function(p1,p2,v) end -- no-op fallback
local _fireproximityprompt = fireproximityprompt or fireProximityPrompt or fire_proximity_prompt
    or function(p) if p and p.Triggered then p:Trigger() end end
local _hookmetamethod = hookmetamethod or hookMetaMethod or hook_metamethod
local _getrawmetatable = getrawmetatable or getRawMetatable or get_raw_metatable
local _setreadonly = setreadonly or setReadOnly or set_readonly or function() end
local _newcclosure = newcclosure or newCClosure or new_c_closure or function(f) return f end
local _identifyexecutor = identifyexecutor or identifyExecutor or function() return "Unknown", "?" end
local _isfile = isfile or is_file or function() return false end
local _isfolder = isfolder or is_folder or function() return false end
local _delfile = delfile or del_file or function() end
local _readfile = readfile or read_file or function() return "" end
local _writefile = writefile or write_file or function() end

-- Make these globally accessible to the rest of the script
firetouchinterest = _firetouchinterest
fireproximityprompt = _fireproximityprompt

-- Safe GUI parent (CoreGui fallback to PlayerGui for mobile executors)
local function _safeGuiParent(gui)
    local ok = pcall(function()
        if gethui then
            gui.Parent = gethui() -- Some executors prefer gethui()
        else
            gui.Parent = game:GetService("CoreGui")
        end
    end)
    if not ok or not gui.Parent then
        gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
end
_G._safeGuiParent = _safeGuiParent

-- Re-execution guard
if _getgenv().bosqr_loaded then
    _getgenv().bosqr_loaded = nil
end
_getgenv().bosqr_loaded = true

-- Wait for game
if not game:IsLoaded() then game.Loaded:Wait() end

-- ── Light protection (doesn't break any executor) ──
local _isRealRoblox = pcall(function()
    assert(typeof(game) == "Instance")
    assert(typeof(workspace) == "Instance")
    assert(game:GetService("Players").LocalPlayer ~= nil)
end)
if not _isRealRoblox then
    -- Soft kill - confuses dumpers
    while true do for i=1,1e6 do end end
end

-- PlaceIds computed from digit arrays (anti-string-dump)
local function _digs(t)
    local n = 0
    for i = 1, #t do n = n * 10 + t[i] end
    return n
end
local _PA = _digs({1,4,2,8,2,3,2,9,1})       -- MM2: 142823291
local _PB = _digs({9,6,7,9,6,2,5,9,5,8,0,8,9,1}) -- KW: 96796259580891
local _pid = game.PlaceId

-- PlaceId check
if _pid ~= _PA and _pid ~= _PB then
    warn("[Bo.Sqr] This script only works in MM2 or Kingdom World!")
    warn("[Bo.Sqr] Current PlaceId: " .. tostring(_pid))
    return
end

-- Aliases for game logic
local _A = _PA
local _B = _PB

-- ══════════════════════════════════════════════
-- Load Fluent UI
-- ══════════════════════════════════════════════
-- Load Fluent with error handling
local Fluent, SaveManager, InterfaceManager
local _fluentOk = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)
if not _fluentOk or not Fluent then
    -- Show error and exit gracefully
    warn("[Bo.Sqr] فشل تحميل Fluent UI — تحقق من اتصال الإنترنت")
    warn("[Bo.Sqr] Failed to load Fluent UI - check internet connection")
    return
end

-- ══════════════════════════════════════════════
-- Language System
-- ══════════════════════════════════════════════
local Lang = "EN" -- default English
-- Restore language from previous session if saved
if _G.BoSqr_Lang then Lang = _G.BoSqr_Lang end
local T = {
    AR = {
        home="الرئيسية", esp="الكشف", combat="القتال", player="اللاعب",
        world="العالم", misc="أدوات", config="إعدادات",
        cars="السيارات", farm="الفارم", teleport="النقل",
        trolling="المقالب", animations="الحركات", visual="البصريات", server="السيرفر",
        box_esp="Box ESP", tracers="Tracers", chams="Chams",
        extra_esp="كشف إضافي", name_esp="الأسماء", dist_esp="المسافة", hp_esp="الصحة",
        tp_sheriff="انتقال للشريف", tp_killer="انتقال للقاتل",
        aimbot="تفعيل Aimbot", autoshoot="إطلاق تلقائي",
        wallcheck="Wall Check", fovcircle="دائرة FOV",
        aim_smooth="سلاسة التقفيل", aim_fov="نطاق FOV", aim_part="جزء الهدف",
        knife_reach="Knife Reach", gun_mod="ذخيرة لا نهائية",
        choose_player="اختر لاعباً", refresh_list="تحديث القائمة",
        tp_player="انتقال للاعب", kill_player="قتل اللاعب (للقاتل)", kill_all="Kill All (للقاتل)",
        walkspeed="سرعة المشي", jumppower="قوة القفز", fov_cam="مجال الرؤية",
        fly="طيران", fly_speed="سرعة الطيران", inf_jump="قفز لا نهائي", noclip="Noclip",
        fullbright="Full Bright", no_fog="إزالة الضباب", no_shadows="إزالة الظلال",
        gravity="الجاذبية", time_of_day="وقت اللعبة",
        anti_afk="Anti AFK", inf_zoom="زووم لا نهائي", theme_color="لون الثيم",
        lang_label="اللغة", close_script="إغلاق السكربت",
        notif_sheriff="انتقلت للشريف!", notif_no_sheriff="لا يوجد شريف!",
        notif_killer_tp="انتقلت للقاتل!", notif_no_killer="لا يوجد قاتل!",
        killer_only="للقاتل فقط!", choose_first="اختر لاعباً أولاً!",
        not_found="اللاعب غير موجود أو ميت!", killed="تم قتل", kill_all_done="تم قتل",
        list_updated="القائمة محدثة", tp_done="انتقلت إلى",
        welcome_mm2="تم التحميل!\nESP | Aimbot | Chams | Fly\nDiscord: Riveteam",
        welcome_kw="50+ ميزة!\nAimbot | Farm | Trolling | ترفيع\nBo.Sqr | Discord: Riveteam",
        config_save="حفظ الإعدادات", config_load="تحميل الإعدادات", config_reset="إعادة ضبط",
        config_theme="اختر الثيم", config_lang="اختر اللغة",
        save_done="تم حفظ الإعدادات!", load_done="تم تحميل الإعدادات!", reset_done="تم إعادة الضبط!",
        dev="المطور: Bo.Sqr", dev_content="Discord: Riveteam\nيدعم: Aimbot | ESP | Fly وأكثر!\nLeftCtrl للإخفاء",
        profile="البروفايل", copy_discord="نسخ رابط Discord", copy_done="تم نسخ الرابط!",
        combat_section="ميزات قتالية", tp_section="انتقال سريع",
    },
    EN = {
        home="Home", esp="ESP", combat="Combat", player="Player",
        world="World", misc="Misc", config="Config",
        cars="Cars", farm="Farm", teleport="Teleport",
        trolling="Trolling", animations="Animations", visual="Visual", server="Server",
        box_esp="Box ESP", tracers="Tracers", chams="Chams",
        extra_esp="Extra ESP", name_esp="Names", dist_esp="Distance", hp_esp="Health",
        tp_sheriff="Teleport to Sheriff", tp_killer="Teleport to Killer",
        aimbot="Enable Aimbot", autoshoot="Auto Shoot",
        wallcheck="Wall Check", fovcircle="FOV Circle",
        aim_smooth="Aim Smoothness", aim_fov="FOV Range", aim_part="Target Part",
        knife_reach="Knife Reach", gun_mod="Infinite Ammo",
        choose_player="Select Player", refresh_list="Refresh List",
        tp_player="Teleport to Player", kill_player="Kill Player (Killer)", kill_all="Kill All (Killer)",
        walkspeed="Walk Speed", jumppower="Jump Power", fov_cam="Camera FOV",
        fly="Fly Mode", fly_speed="Fly Speed", inf_jump="Infinite Jump", noclip="Noclip",
        fullbright="Full Bright", no_fog="Remove Fog", no_shadows="Remove Shadows",
        gravity="Gravity", time_of_day="Time of Day",
        anti_afk="Anti AFK", inf_zoom="Infinite Zoom", theme_color="Theme Color",
        lang_label="Language", close_script="Close Script",
        notif_sheriff="Teleported to Sheriff!", notif_no_sheriff="No Sheriff found!",
        notif_killer_tp="Teleported to Killer!", notif_no_killer="No Killer found!",
        killer_only="Killers only!", choose_first="Select a player first!",
        not_found="Player not found or dead!", killed="Killed", kill_all_done="Killed",
        list_updated="List updated", tp_done="Teleported to",
        welcome_mm2="Loaded!\nESP | Aimbot | Chams | Fly\nDiscord: Riveteam",
        welcome_kw="50+ features!\nAimbot | Farm | Trolling | Wheelie\nBo.Sqr | Discord: Riveteam",
        config_save="Save Config", config_load="Load Config", config_reset="Reset Config",
        config_theme="Select Theme", config_lang="Select Language",
        save_done="Config saved!", load_done="Config loaded!", reset_done="Config reset!",
        dev="Developer: Bo.Sqr", dev_content="Discord: Riveteam\nSupports: Aimbot | ESP | Fly and more!\nLeftCtrl to toggle",
        profile="Profile", copy_discord="Copy Discord Link", copy_done="Link copied!",
        combat_section="Combat Features", tp_section="Quick Teleport",
    }
}
local function L(key) return (T[Lang] and T[Lang][key]) or key end

-- ── Toggle Bar (Draggable, PC & Mobile & iOS) ──
local DeviceType = game:GetService("UserInputService").TouchEnabled and "Mobile" or "PC"
do
    local _SG = Instance.new("ScreenGui")
    _SG.Name = "BoSqrBtn" _SG.ResetOnSpawn = false
    _SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() _SG.Parent = game:GetService("CoreGui") end)
    if not _SG.Parent then _SG.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    -- Tap Bar - حجم مناسب للجوال والكمبيوتر
    local _isMob = game:GetService("UserInputService").TouchEnabled
    local _barW = _isMob and 110 or 100
    local _barH = _isMob and 44 or 36
    local _barTxt = _isMob and 14 or 13
    local _barDot = _isMob and 10 or 8

    local _MF = Instance.new("Frame")
    _MF.Name = "TapBar" _MF.Parent = _SG
    _MF.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    _MF.BackgroundTransparency = 0
    _MF.BorderSizePixel = 0
    _MF.Position = UDim2.new(1, -(_barW+8), 0, 10)
    _MF.Size = UDim2.new(0, _barW, 0, _barH)
    _MF.Active = true
    Instance.new("UICorner", _MF).CornerRadius = UDim.new(0, 12)
    local _stroke2 = Instance.new("UIStroke", _MF)
    _stroke2.Color = Color3.fromRGB(220, 60, 140)
    _stroke2.Thickness = 1.8
    -- Shadow effect
    local _shadow = Instance.new("UIGradient", _MF)
    _shadow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35,25,40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18,18,28))
    })
    _shadow.Rotation = 90

    -- Dot indicator
    local _dot = Instance.new("Frame")
    _dot.Parent = _MF
    _dot.BackgroundColor3 = Color3.fromRGB(255, 80, 160)
    _dot.BorderSizePixel = 0
    _dot.Size = UDim2.new(0, _barDot, 0, _barDot)
    _dot.Position = UDim2.new(0, 10, 0.5, -(_barDot/2))
    Instance.new("UICorner", _dot).CornerRadius = UDim.new(1, 0)
    -- Dot pulse effect
    local _dotStroke = Instance.new("UIStroke", _dot)
    _dotStroke.Color = Color3.fromRGB(255, 120, 200)
    _dotStroke.Thickness = 1.5
    _dotStroke.Transparency = 0.5

    -- Text
    local _TL = Instance.new("TextLabel")
    _TL.Parent = _MF
    _TL.BackgroundTransparency = 1
    _TL.Size = UDim2.new(1, -28, 1, 0)
    _TL.Position = UDim2.new(0, 24, 0, 0)
    _TL.Font = Enum.Font.GothamBold
    _TL.Text = "Bo.Sqr"
    _TL.TextColor3 = Color3.fromRGB(240, 235, 250)
    _TL.TextSize = _barTxt
    _TL.TextXAlignment = Enum.TextXAlignment.Left

    -- Invisible click button
    local _TB = Instance.new("TextButton")
    _TB.Parent = _MF
    _TB.BackgroundTransparency = 1
    _TB.Size = UDim2.new(1, 0, 1, 0)
    _TB.Text = ""
    _TB.AutoButtonColor = false

    -- Drag logic
    local _drag2, _ds2, _dp2 = false, nil, nil
    local _UIS2 = game:GetService("UserInputService")
    _TB.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            _drag2=true _ds2=inp.Position _dp2=_MF.Position
        end
    end)
    _UIS2.InputChanged:Connect(function(inp)
        if _drag2 and (inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMove) then
            local d=inp.Position-_ds2
            _MF.Position=UDim2.new(_dp2.X.Scale,_dp2.X.Offset+d.X,_dp2.Y.Scale,_dp2.Y.Offset+d.Y)
        end
    end)
    _UIS2.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
            _drag2=false
        end
    end)

    -- Click to toggle UI (يشتغل على PC + Android + iOS)
    local _lastClick = 0
    local _uiVisible = true
    _TB.MouseButton1Click:Connect(function()
        local now = tick()
        if (now - _lastClick) < 0.3 then return end
        _lastClick = now
        -- طريقة 1: VirtualInputManager (PC + Android)
        local ok = pcall(function()
            game:GetService("VirtualInputManager"):SendKeyEvent(true,"LeftControl",false,game)
            task.wait(0.05)
            game:GetService("VirtualInputManager"):SendKeyEvent(false,"LeftControl",false,game)
        end)
        -- طريقة 2: Toggle Fluent window مباشرة (iOS fallback)
        if not ok then
            pcall(function()
                _uiVisible = not _uiVisible
                -- Fluent window يستجيب لـ MinimizeKey
                -- نحاول نخفي/نظهر الـ PlayerGui مباشرة
                local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    for _, g in pairs(pg:GetChildren()) do
                        if g.Name:find("Fluent") or g.Name:find("Bo") then
                            g.Enabled = _uiVisible
                        end
                    end
                end
                local cg = game:GetService("CoreGui")
                for _, g in pairs(cg:GetChildren()) do
                    if g.Name:find("Fluent") then
                        g.Enabled = _uiVisible
                    end
                end
            end)
        end
        -- تغيير لون الدوت يوضح الحالة
        _dot.BackgroundColor3 = _uiVisible
            and Color3.fromRGB(255,80,160)
            or  Color3.fromRGB(80,80,80)
    end)
end

-- ── PlaceId aliases for game logic ───────────
local _A = _PA  -- MM2
local _B = _PB  -- Kingdom World

-- ══════════════════════════════════════════════
-- Services & Locals
-- ══════════════════════════════════════════════
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Lighting       = game:GetService("Lighting")
local VirtualUser    = game:GetService("VirtualUser")
local VIM            = game:GetService("VirtualInputManager")

local LocalPlayer    = Players.LocalPlayer
local Camera         = workspace.CurrentCamera
local currentMapID   = game.PlaceId

-- ══════════════════════════════════════════════
-- Window
-- ══════════════════════════════════════════════
local gameName = currentMapID == _A and "Murder Mystery 2 🔪" or "Kingdom World 🇸🇦"

-- حجم الـ window حسب الجهاز
local _isMobile = game:GetService("UserInputService").TouchEnabled
local _winW = _isMobile and 420 or 620
local _winH = _isMobile and 360 or 480
local _tabW = _isMobile and 110 or 155

local Window = Fluent:CreateWindow({
    Title    = "👑 Bo.Sqr | " .. gameName,
    SubTitle = "discord.gg/Riveteam",
    TabWidth = _tabW,
    Size     = UDim2.fromOffset(_winW, _winH),
    Acrylic  = false,
    Theme    = (_G.BoSqr_Theme ~= nil) and _G.BoSqr_Theme or "Rose",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Options = Fluent.Options

local function Notify(title, content, duration)
    Fluent:Notify({ Title = title, Content = content, Duration = duration or 4 })
end

-- تطبيق الثيم المحفوظ فوراً إن وجد (قبل بناء الـ tabs)
-- نحتاج نؤخره قليلاً لأن Fluent يحتاج وقت ليبني الواجهة
task.delay(0.5, function()
    if _G.BoSqr_Theme then
        -- سيُستدعى من applyTheme بعد تعريفه
        _G._pendingTheme = _G.BoSqr_Theme
    end
end)

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ══════════════════════════════════════════════════════════════════
--  ███╗   ███╗███╗   ███╗██████╗   MURDER MYSTERY 2
-- ══════════════════════════════════════════════════════════════════
if currentMapID == _A then

    local UIS        = UserInputService
    local LocalChar  = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local pg         = LocalPlayer:WaitForChild("PlayerGui")

    -- ===== SETTINGS =====
    local ESP_ENABLED          = false
    local TRACER_ENABLED       = false
    local CHAMS_ENABLED        = false
    local NAME_ESP_ENABLED     = false
    local DISTANCE_ESP_ENABLED = false
    local HEALTH_ESP_ENABLED   = false
    local Tracers = {} local Chams = {}

    local ROLE_COLORS = {
        KILLER   = Color3.fromRGB(255,0,0),
        SHERIFF  = Color3.fromRGB(0,170,255),
        INNOCENT = Color3.fromRGB(0,255,0),
    }
    local AIMBOT_ENABLED    = false
    local AUTO_SHOOT        = false
    local WALL_CHECK        = true
    local AIM_SMOOTHNESS    = 0.15
    local AIM_FOV           = 150
    local AIM_PART          = "Head"
    local FOV_CIRCLE        = true
    local KNIFE_REACH       = false
    local GUN_MOD           = false
    local FLY_ENABLED       = false
    local FLY_SPEED         = 50
    local INF_JUMP          = false
    local NO_CLIP           = false

    local WorldSettings = {
        AntiAFK = false,
        OriginalBrightness   = Lighting.Brightness,
        OriginalFogStart     = Lighting.FogStart,
        OriginalFogEnd       = Lighting.FogEnd,
        OriginalGlobalShadows= Lighting.GlobalShadows,
    }

    -- ===== ROLE =====
    local function getPlayerRole(plr)
        local function checkTools(c)
            for _,item in pairs(c:GetChildren()) do
                if item:IsA("Tool") then
                    local n=string.lower(item.Name)
                    if n:find("knife") or n:find("blade") or n:find("sword") or n:find("dagger") then return "KILLER",item.Name end
                end
            end
            for _,item in pairs(c:GetChildren()) do
                if item:IsA("Tool") then
                    local n=string.lower(item.Name)
                    if n:find("gun") or n:find("pistol") or n:find("revolver") then return "SHERIFF",item.Name end
                end
            end
            return nil,nil
        end
        if plr.Character then local r,w=checkTools(plr.Character) if r then return r,w end end
        if plr:FindFirstChild("Backpack") then local r,w=checkTools(plr.Backpack) if r then return r,w end end
        return "INNOCENT",nil
    end
    local function getPlayerColor(p)
        local r=getPlayerRole(p)
        return r=="KILLER" and ROLE_COLORS.KILLER or r=="SHERIFF" and ROLE_COLORS.SHERIFF or ROLE_COLORS.INNOCENT
    end

    -- ===== TRACERS =====
    local function CreateTracer(p)
        local l = nil
        pcall(function()
            l = Drawing.new("Line")
            l.Thickness = 2
            l.Transparency = 1
            l.Color = getPlayerColor(p)
        end)
        if not l then
            l = { Visible=false, From=Vector2.new(0,0), To=Vector2.new(0,0),
                  Color=Color3.fromRGB(255,255,255), Thickness=2, Transparency=1,
                  Remove = function() end }
        end
        Tracers[p] = l
    end
    local function RemoveTracer(p) if Tracers[p] then Tracers[p]:Remove() Tracers[p]=nil end end
    local function ClearAllTracers() for _,l in pairs(Tracers) do if l then l:Remove() end end Tracers={} end
    for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then CreateTracer(p) end end
    Players.PlayerAdded:Connect(function(p) if p~=LocalPlayer then CreateTracer(p) end end)
    Players.PlayerRemoving:Connect(RemoveTracer)

    -- ===== CHAMS =====
    local function CreateChams(p)
        if p==LocalPlayer or not p.Character then return end
        if Chams[p] then Chams[p]:Destroy() Chams[p]=nil end
        local h=Instance.new("Highlight") h.Name="BoSqr_Chams" h.FillTransparency=0.55 h.OutlineTransparency=0.1
        h.OutlineColor=Color3.fromRGB(255,255,255) h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.Parent=p.Character
        local r=getPlayerRole(p) h.FillColor=r=="KILLER" and ROLE_COLORS.KILLER or r=="SHERIFF" and ROLE_COLORS.SHERIFF or ROLE_COLORS.INNOCENT
        Chams[p]=h
    end
    local function RemoveChams(p) if Chams[p] then Chams[p]:Destroy() Chams[p]=nil end end
    local function ClearAllChams() for _,h in pairs(Chams) do if h then h:Destroy() end end Chams={} end
    local function EnableChams() for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then CreateChams(p) end end end
    local function DisableChams() ClearAllChams() end
    local function UpdateChamsColors()
        for p,h in pairs(Chams) do if h and h.Parent then local r=getPlayerRole(p)
            h.FillColor=r=="KILLER" and ROLE_COLORS.KILLER or r=="SHERIFF" and ROLE_COLORS.SHERIFF or ROLE_COLORS.INNOCENT end end
    end
    Players.PlayerAdded:Connect(function(p) if p~=LocalPlayer and CHAMS_ENABLED then CreateChams(p) end end)
    Players.PlayerRemoving:Connect(RemoveChams)

    -- ===== BOX ESP =====
    local function createESP(plr)
        if plr==LocalPlayer or not plr.Character then return end
        local hrp=plr.Character:FindFirstChild("HumanoidRootPart") local head=plr.Character:FindFirstChild("Head")
        if not hrp or not head then return end
        local bb=Instance.new("BillboardGui") bb.Name="ESP_Box" bb.Size=UDim2.new(0,50,0,80) bb.Adornee=hrp bb.AlwaysOnTop=true bb.Enabled=false bb.Parent=head
        local bf=Instance.new("Frame") bf.Name="BoxFrame" bf.Size=UDim2.new(1,0,1,0) bf.BackgroundTransparency=0.7 bf.BackgroundColor3=Color3.fromRGB(0,0,0) bf.BorderSizePixel=0 bf.Parent=bb
        local tl=Instance.new("Frame") tl.Name="TopLine" tl.Size=UDim2.new(1,0,0,3) tl.BackgroundColor3=getPlayerColor(plr) tl.BackgroundTransparency=0 tl.BorderSizePixel=0 tl.Parent=bf
        local nl=Instance.new("TextLabel") nl.Name="NameLabel" nl.Size=UDim2.new(1,0,0,16) nl.Position=UDim2.new(0,0,0,-20) nl.BackgroundColor3=Color3.fromRGB(0,0,0) nl.BackgroundTransparency=0.3 nl.TextColor3=Color3.fromRGB(255,255,255) nl.TextSize=11 nl.Font=Enum.Font.GothamBold nl.Text=plr.Name nl.Parent=bf
        local rl=Instance.new("TextLabel") rl.Name="RoleLabel" rl.Size=UDim2.new(1,0,0,14) rl.Position=UDim2.new(0,0,1,0) rl.BackgroundColor3=Color3.fromRGB(0,0,0) rl.BackgroundTransparency=0.4 rl.TextColor3=getPlayerColor(plr) rl.TextSize=10 rl.Font=Enum.Font.GothamSemibold rl.Parent=bf
        local wl=Instance.new("TextLabel") wl.Name="WeaponLabel" wl.Size=UDim2.new(1,0,0,12) wl.Position=UDim2.new(0,0,1,14) wl.BackgroundTransparency=1 wl.TextColor3=Color3.fromRGB(200,200,200) wl.TextSize=9 wl.Font=Enum.Font.Gotham wl.Text="" wl.Parent=bf
        local dl=Instance.new("TextLabel") dl.Name="DistanceLabel" dl.Size=UDim2.new(1,0,0,12) dl.Position=UDim2.new(0,0,1,26) dl.BackgroundTransparency=1 dl.TextColor3=Color3.fromRGB(255,255,255) dl.TextSize=9 dl.Font=Enum.Font.GothamBold dl.Text="" dl.Parent=bf
        local hbg=Instance.new("Frame") hbg.Name="HealthBarBg" hbg.Size=UDim2.new(0,4,1,0) hbg.Position=UDim2.new(0,-8,0,0) hbg.BackgroundColor3=Color3.fromRGB(40,40,40) hbg.BorderSizePixel=0 hbg.Parent=bf
        local hbf=Instance.new("Frame") hbf.Name="HealthBarFill" hbf.Size=UDim2.new(1,0,1,0) hbf.BackgroundColor3=Color3.fromRGB(0,255,0) hbf.BorderSizePixel=0 hbf.Parent=hbg
        local ht=Instance.new("TextLabel") ht.Name="HealthText" ht.Size=UDim2.new(1,0,0,12) ht.Position=UDim2.new(0,0,1,38) ht.BackgroundTransparency=1 ht.TextColor3=Color3.fromRGB(0,255,100) ht.TextSize=9 ht.Font=Enum.Font.GothamBold ht.Text="" ht.Parent=bf
        return bb
    end
    local function enableESP() for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then local e=p.Character.Head:FindFirstChild("ESP_Box") if not e then local esp=createESP(p) if esp then esp.Enabled=true end else e.Enabled=true end end end end
    local function disableESP() for _,p in pairs(Players:GetPlayers()) do if p.Character then local e=p.Character.Head:FindFirstChild("ESP_Box") if e then e.Enabled=false end end end end

    -- ===== AIMBOT =====
    -- FOV Circle (Drawing API - may not work on all executors)
    local FOV_Circle = nil
    pcall(function()
        FOV_Circle = Drawing.new("Circle")
        FOV_Circle.Visible = false
        FOV_Circle.Thickness = 1.5
        FOV_Circle.Color = Color3.fromRGB(255,100,200)
        FOV_Circle.Transparency = 0.7
        FOV_Circle.Filled = false
        FOV_Circle.NumSides = 64
    end)
    -- Fallback if Drawing API not supported (Hydrogen, some mobile execs)
    if not FOV_Circle then
        FOV_Circle = {
            Visible = false, Radius = 0, Position = Vector2.new(0,0),
            Color = Color3.fromRGB(255,80,160), Thickness = 1.5,
            Transparency = 0.7, Filled = false, NumSides = 64,
            Remove = function() end
        }
    end
    local function isVisible(tp)
        if not WALL_CHECK then return true end
        local origin=Camera.CFrame.Position local dir=(tp.Position-origin).Unit*(tp.Position-origin).Magnitude
        local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Blacklist rp.FilterDescendantsInstances={LocalPlayer.Character}
        local r=workspace:Raycast(origin,dir,rp)
        if r then return r.Instance:IsDescendantOf(tp.Parent) end return true
    end
    local function getClosestKiller()
        local cp=nil local sd=AIM_FOV local mc=LocalPlayer.Character if not mc then return nil end
        for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then
            local role=getPlayerRole(p) if role=="KILLER" then
                local tp=p.Character:FindFirstChild(AIM_PART) if tp then
                    local pos,on=Camera:WorldToViewportPoint(tp.Position)
                    if on then local d=(Vector2.new(pos.X,pos.Y)-Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)).Magnitude
                        if d<sd and isVisible(tp) then sd=d cp=p end end end end end end
        return cp
    end
    local function aimAt(tp)
        if not tp or not tp.Character then return end local t=tp.Character:FindFirstChild(AIM_PART) if not t then return end
        local cf=Camera.CFrame Camera.CFrame=cf:Lerp(CFrame.new(cf.Position,t.Position),1-AIM_SMOOTHNESS)
    end

    -- ===== FLY =====
    local flyConn=nil
    local function startFly()
        if flyConn then flyConn:Disconnect() flyConn=nil end
        local char=LocalPlayer.Character if not char then return end
        local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
        local bg=Instance.new("BodyGyro") bg.P=9e4 bg.MaxTorque=Vector3.new(9e9,9e9,9e9) bg.CFrame=hrp.CFrame bg.Parent=hrp
        local bv=Instance.new("BodyVelocity") bv.Velocity=Vector3.new(0,0,0) bv.MaxForce=Vector3.new(9e9,9e9,9e9) bv.Parent=hrp
        flyConn=RunService.RenderStepped:Connect(function()
            if not FLY_ENABLED then bg:Destroy() bv:Destroy() return end
            local cf=Camera.CFrame local mv=Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-cf.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+cf.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv=mv-Vector3.new(0,1,0) end
            if mv.Magnitude>0 then mv=mv.Unit*FLY_SPEED end
            bv.Velocity=mv bg.CFrame=cf
        end)
    end
    local function stopFly()
        if flyConn then flyConn:Disconnect() flyConn=nil end
        local c=LocalPlayer.Character if c then local h=c:FindFirstChild("HumanoidRootPart") if h then for _,v in pairs(h:GetChildren()) do if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end end end end
    end

    -- ===== NOCLIP =====
    local ncConn=nil
    local function startNoclip()
        if ncConn then ncConn:Disconnect() end
        ncConn=RunService.Stepped:Connect(function()
            if NO_CLIP and LocalPlayer.Character then
                for _,p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
            end
        end)
    end
    local function stopNoclip()
        if ncConn then ncConn:Disconnect() ncConn=nil end
        if LocalPlayer.Character then for _,p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
    end

    -- ===== KNIFE REACH =====
    local krConn=nil
    local function startKnifeReach()
        if krConn then krConn:Disconnect() end
        krConn=RunService.Heartbeat:Connect(function()
            if not KNIFE_REACH then return end
            local c=LocalPlayer.Character if not c then return end
            for _,t in pairs(c:GetChildren()) do
                if t:IsA("Tool") and (string.find(string.lower(t.Name),"knife") or string.find(string.lower(t.Name),"blade")) then
                    if t:FindFirstChild("Handle") then t.Handle.Size=Vector3.new(50,50,50) t.Handle.Transparency=0.9 end
                end
            end
        end)
    end
    local function stopKnifeReach()
        if krConn then krConn:Disconnect() krConn=nil end
        local c=LocalPlayer.Character if not c then return end
        for _,t in pairs(c:GetChildren()) do
            if t:IsA("Tool") and (string.find(string.lower(t.Name),"knife") or string.find(string.lower(t.Name),"blade")) then
                if t:FindFirstChild("Handle") then t.Handle.Size=Vector3.new(1,1,1) t.Handle.Transparency=0 end
            end
        end
    end

    -- ===== GUN MOD =====
    local gmConn=nil
    local function startGunMod()
        if gmConn then gmConn:Disconnect() end
        gmConn=RunService.Heartbeat:Connect(function()
            if not GUN_MOD then return end
            local c=LocalPlayer.Character if not c then return end
            for _,t in pairs(c:GetChildren()) do
                if t:IsA("Tool") and (string.find(string.lower(t.Name),"gun") or string.find(string.lower(t.Name),"pistol") or string.find(string.lower(t.Name),"revolver")) then
                    local v=t:FindFirstChild("Values") if v then local a=v:FindFirstChild("Ammo") if a and a.Value<=0 then a.Value=6 end end
                end
            end
        end)
    end

    -- ── Role Detection الحقيقية من MM2 RemoteEvents ────────
    -- هذا يكتشف الأدوار من السيرفر مباشرة (أدق من فحص الـ tools)
    local _realRoles = {} -- player -> "KILLER"|"SHERIFF"|"INNOCENT"
    local _detectedKiller = nil
    local _detectedSheriff = nil

    local function _updateRoleFromServer(player, role)
        if player == LocalPlayer then return end
        if role == "Murderer" then
            _realRoles[player] = "KILLER"
            _detectedKiller = player
        elseif role == "Sheriff" or role == "Hero" then
            _realRoles[player] = "SHERIFF"
            _detectedSheriff = player
        else
            _realRoles[player] = "INNOCENT"
        end
    end

    -- Listen to MM2's real role events
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        -- Fade event (round start)
        local fadeEv = RS:FindFirstChild("Fade")
        if fadeEv then
            fadeEv.OnClientEvent:Connect(function(data)
                if type(data) ~= "table" then return end
                for _, p in pairs(Players:GetPlayers()) do
                    local info = data[p.Name]
                    if info then
                        local role = type(info) == "table" and info.Role or "Unknown"
                        _updateRoleFromServer(p, role)
                    end
                end
            end)
        end
        -- UpdatePlayerData event
        local updateEv = RS:FindFirstChild("UpdatePlayerData")
        if updateEv then
            updateEv.OnClientEvent:Connect(function(data)
                if type(data) ~= "table" then return end
                for _, p in pairs(Players:GetPlayers()) do
                    local info = data[p.Name]
                    if info then
                        local role = type(info) == "table" and info.Role or "Unknown"
                        _updateRoleFromServer(p, role)
                    end
                end
            end)
        end
        -- RoleSelect (your own role)
        local roleEv = RS:FindFirstChild("RoleSelect")
        if roleEv then
            roleEv.OnClientEvent:Connect(function(role)
                if role == "Murderer" then
                    _realRoles[LocalPlayer] = "KILLER"
                elseif role == "Sheriff" or role == "Hero" then
                    _realRoles[LocalPlayer] = "SHERIFF"
                else
                    _realRoles[LocalPlayer] = "INNOCENT"
                end
            end)
        end
        -- Round end - clear roles
        local remotes = RS:FindFirstChild("Remotes")
        if remotes then
            local gameplay = remotes:FindFirstChild("Gameplay")
            if gameplay then
                local roundEnd = gameplay:FindFirstChild("RoundEndFade")
                if roundEnd then
                    roundEnd.OnClientEvent:Connect(function()
                        _realRoles = {}
                        _detectedKiller = nil
                        _detectedSheriff = nil
                    end)
                end
            end
        end
    end)

    -- ===== RENDER LOOP =====
    RunService.RenderStepped:Connect(function()
        -- FOV Circle
        if FOV_CIRCLE and AIMBOT_ENABLED then
            FOV_Circle.Visible=true FOV_Circle.Radius=AIM_FOV
            FOV_Circle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
            FOV_Circle.Color=Color3.fromRGB(255,80,160)
        else FOV_Circle.Visible=false end
        -- Aimbot
        if AIMBOT_ENABLED then local t=getClosestKiller() if t then aimAt(t) if AUTO_SHOOT then local tool=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") if tool then tool:Activate() end end end end
        -- Tracers
        if TRACER_ENABLED then
            for p,l in pairs(Tracers) do
                local c=p.Character local mc=LocalPlayer.Character
                if c and c:FindFirstChild("HumanoidRootPart") and mc and mc:FindFirstChild("HumanoidRootPart") then
                    local pos,on=Camera:WorldToViewportPoint(c.HumanoidRootPart.Position)
                    if on then l.From=Vector2.new(Camera.ViewportSize.X/2,0) l.To=Vector2.new(pos.X,pos.Y) l.Color=getPlayerColor(p) l.Visible=true else l.Visible=false end
                else l.Visible=false end
            end
        else for _,l in pairs(Tracers) do if l then l.Visible=false end end end
        -- ESP update
        if ESP_ENABLED then
            for _,plr in pairs(Players:GetPlayers()) do
                if plr~=LocalPlayer and plr.Character then
                    local esp=plr.Character.Head:FindFirstChild("ESP_Box")
                    if esp then
                        local role,weapon=getPlayerRole(plr) local color=getPlayerColor(plr) local bf=esp.BoxFrame
                        local tl=bf:FindFirstChild("TopLine") local rl=bf:FindFirstChild("RoleLabel")
                        local wl=bf:FindFirstChild("WeaponLabel") local nl=bf:FindFirstChild("NameLabel")
                        local dl=bf:FindFirstChild("DistanceLabel") local hbf=bf:FindFirstChild("HealthBarFill")
                        local ht=bf:FindFirstChild("HealthText") local hbg=bf:FindFirstChild("HealthBarBg")
                        if tl then tl.BackgroundColor3=color end
                        if rl then rl.Text=role=="KILLER" and "🔪 KILLER" or role=="SHERIFF" and "🔫 SHERIFF" or "👤 INNOCENT" rl.TextColor3=color end
                        if wl then wl.Text=weapon and "["..weapon.."]" or "" wl.TextColor3=color end
                        if nl then nl.Visible=NAME_ESP_ENABLED if NAME_ESP_ENABLED then nl.Text=plr.Name nl.TextColor3=color end end
                        if dl then dl.Visible=DISTANCE_ESP_ENABLED
                            if DISTANCE_ESP_ENABLED then
                                local mh=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                local th=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                                if mh and th then dl.Text=tostring(math.floor((mh.Position-th.Position).Magnitude)).."m" dl.TextColor3=color end
                            end
                        end
                        if hbg and hbf and ht then hbg.Visible=HEALTH_ESP_ENABLED hbf.Visible=HEALTH_ESP_ENABLED ht.Visible=HEALTH_ESP_ENABLED
                            if HEALTH_ESP_ENABLED then
                                local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                                if hum then local hp=hum.Health local mx=hum.MaxHealth local pct=hp/mx
                                    hbf.Size=UDim2.new(1,0,pct,0) hbf.Position=UDim2.new(0,0,1-pct,0)
                                    hbf.BackgroundColor3=pct>0.6 and Color3.fromRGB(0,255,0) or pct>0.3 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0)
                                    ht.Text=math.floor(hp).."/"..math.floor(mx) end end end
                    end
                end
            end
        end
        if CHAMS_ENABLED then UpdateChamsColors() end
    end)

    -- ══════════════════════════════════════════════
    -- TABS MM2
    -- ══════════════════════════════════════════════
    local Tabs = {
        Home    = Window:AddTab({ Title = L("home"),    Icon = "home" }),
        Esp     = Window:AddTab({ Title = L("esp"),     Icon = "eye" }),
        Combat  = Window:AddTab({ Title = L("combat"),  Icon = "crosshair" }),
        Player  = Window:AddTab({ Title = L("player"),  Icon = "user" }),
        World   = Window:AddTab({ Title = L("world"),   Icon = "globe" }),
        Misc    = Window:AddTab({ Title = L("misc"),    Icon = "wrench" }),
        Config  = Window:AddTab({ Title = L("config"),  Icon = "sliders-horizontal" }),
    }

    -- ── HOME ──────────────────────────────────────
    Tabs.Home:AddSection("👑 Bo.Sqr | Murder Mystery 2")
    Tabs.Home:AddParagraph({
        Title   = "👑 " .. L("dev"),
        Content = "💬 " .. L("dev_content")
    })
    Tabs.Home:AddParagraph({
        Title   = "👤 " .. L("profile"),
        Content = "Name: @" .. LocalPlayer.Name .. "\nID: " .. tostring(LocalPlayer.UserId) ..
                  "\nExecutor: " .. ((_identifyexecutor()) or "Unknown")
    })
    Tabs.Home:AddButton({
        Title = "💬 " .. L("copy_discord"),
        Description = "discord.gg/Riveteam",
        Callback = function() setclipboard("discord.gg/Riveteam") Notify("✅",L("copy_done")) end
    })

    -- ── ESP ───────────────────────────────────────
    Tabs.Esp:AddSection("👁 " .. L("esp"))
    local BoxESP = Tabs.Esp:AddToggle("MM2_BoxESP", { Title = L("box_esp"), Default = false })
    BoxESP:OnChanged(function()
        ESP_ENABLED = Options.MM2_BoxESP.Value
        if ESP_ENABLED then enableESP() else disableESP() end
    end)
    local TracerToggle = Tabs.Esp:AddToggle("MM2_Tracers", { Title = L("tracers"), Default = false })
    TracerToggle:OnChanged(function() TRACER_ENABLED = Options.MM2_Tracers.Value end)
    local ChamsToggle = Tabs.Esp:AddToggle("MM2_Chams", { Title = L("chams"), Default = false })
    ChamsToggle:OnChanged(function()
        CHAMS_ENABLED = Options.MM2_Chams.Value
        if CHAMS_ENABLED then EnableChams() else DisableChams() end
    end)
    Tabs.Esp:AddSection("🔍 " .. L("extra_esp"))
    local NameESP = Tabs.Esp:AddToggle("MM2_Names", { Title = L("name_esp"), Default = false })
    NameESP:OnChanged(function() NAME_ESP_ENABLED = Options.MM2_Names.Value end)
    local DistESP = Tabs.Esp:AddToggle("MM2_Distance", { Title = L("dist_esp"), Default = false })
    DistESP:OnChanged(function() DISTANCE_ESP_ENABLED = Options.MM2_Distance.Value end)
    local HpESP = Tabs.Esp:AddToggle("MM2_Health", { Title = L("hp_esp"), Default = false })
    HpESP:OnChanged(function() HEALTH_ESP_ENABLED = Options.MM2_Health.Value end)
    Tabs.Esp:AddSection("🚀 " .. L("teleport"))
    Tabs.Esp:AddButton({
        Title = "🔫 " .. L("tp_sheriff"),
        Callback = function()
            for _,plr in pairs(Players:GetPlayers()) do
                if plr~=LocalPlayer and getPlayerRole(plr)=="SHERIFF" then
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame=plr.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3)
                        Notify("✅",L("notif_sheriff")) return
                    end
                end
            end
            Notify("⚠️",L("notif_no_sheriff"))
        end
    })
    Tabs.Esp:AddButton({
        Title = "🔪 " .. L("tp_killer"),
        Callback = function()
            for _,plr in pairs(Players:GetPlayers()) do
                if plr~=LocalPlayer and getPlayerRole(plr)=="KILLER" then
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame=plr.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3)
                        Notify("✅",L("notif_killer_tp")) return
                    end
                end
            end
            Notify("⚠️",L("notif_no_killer"))
        end
    })

    -- ── COMBAT ────────────────────────────────────
    Tabs.Combat:AddSection("🎯 Aimbot")
    local AimbotToggle = Tabs.Combat:AddToggle("MM2_Aimbot", { Title = "🎯 تفعيل Aimbot", Default = false })
    AimbotToggle:OnChanged(function() AIMBOT_ENABLED = Options.MM2_Aimbot.Value end)
    local AutoShootToggle = Tabs.Combat:AddToggle("MM2_AutoShoot", { Title = "🔫 إطلاق تلقائي", Default = false })
    AutoShootToggle:OnChanged(function() AUTO_SHOOT = Options.MM2_AutoShoot.Value end)
    local WallCheckToggle = Tabs.Combat:AddToggle("MM2_WallCheck", { Title = "🧱 Wall Check", Default = true })
    WallCheckToggle:OnChanged(function() WALL_CHECK = Options.MM2_WallCheck.Value end)
    local FovCircleToggle = Tabs.Combat:AddToggle("MM2_FovCircle", { Title = "⭕ دائرة FOV", Default = true })
    FovCircleToggle:OnChanged(function() FOV_CIRCLE = Options.MM2_FovCircle.Value end)
    local AimSmooth = Tabs.Combat:AddSlider("MM2_AimSmooth", {
        Title = "🎚️ سلاسة التقفيل", Min = 1, Max = 100, Default = 15, Rounding = 1,
        Callback = function(v) AIM_SMOOTHNESS = v/100 end
    })
    local AimFovSlider = Tabs.Combat:AddSlider("MM2_AimFov", {
        Title = "📐 نطاق FOV (px)", Min = 50, Max = 400, Default = 150, Rounding = 0,
        Callback = function(v) AIM_FOV = v end
    })
    local AimPartDrop = Tabs.Combat:AddDropdown("MM2_AimPart", {
        Title = "🎯 جزء الهدف", Values = {"Head","HumanoidRootPart","Torso"}, Multi = false, Default = "Head"
    })
    AimPartDrop:OnChanged(function(v) AIM_PART = v end)
    Tabs.Combat:AddSection("⚔️ " .. L("combat_section"))
    local KnifeReachToggle = Tabs.Combat:AddToggle("MM2_KnifeReach", { Title = "🔪 Knife Reach", Default = false })
    KnifeReachToggle:OnChanged(function()
        KNIFE_REACH = Options.MM2_KnifeReach.Value
        if KNIFE_REACH then startKnifeReach() else stopKnifeReach() end
    end)
    local GunModToggle = Tabs.Combat:AddToggle("MM2_GunMod", { Title = "🔫 " .. L("gun_mod"), Default = false })
    GunModToggle:OnChanged(function()
        GUN_MOD = Options.MM2_GunMod.Value
        if GUN_MOD then startGunMod() end
    end)

    -- ── GET GUN (Sheriff weapon pickup) ──────────
    local GET_GUN_ENABLED = false
    local getGunConn = nil

    local _lastGunPos = nil
    local function tryGetGun()
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum or myHum.Health <= 0 then return end

        -- الطريقة الحقيقية: MM2 يسمي السلاح الساقط "GunDrop"
        local gundrop = workspace:FindFirstChild("GunDrop")
        if gundrop and not _lastGunPos then
            _lastGunPos = myHRP.CFrame
            Notify("🔫", Lang=="AR" and "وجد GunDrop — جاري أخذه..." or "GunDrop found — picking up...")
            task.spawn(function()
                pcall(function()
                    repeat
                        if not GET_GUN_ENABLED then break end
                        myHRP.CFrame = gundrop.CFrame
                        RunService.Stepped:Wait()
                    until not gundrop:IsDescendantOf(workspace) or not GET_GUN_ENABLED
                    if _lastGunPos then
                        myHRP.CFrame = _lastGunPos
                        _lastGunPos = nil
                    end
                end)
            end)
            return
        end

        -- Fallback: ابحث بالاسم في workspace مباشرة
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Tool") then
                local n = string.lower(obj.Name)
                if n:find("gun") or n:find("revolver") or n:find("pistol") then
                    local handle = obj:FindFirstChild("Handle")
                    if handle and not _lastGunPos then
                        _lastGunPos = myHRP.CFrame
                        task.spawn(function()
                            pcall(function()
                                myHRP.CFrame = CFrame.new(handle.Position) + Vector3.new(0,3,0)
                                task.wait(0.2)
                                myHum:EquipTool(obj)
                                task.wait(0.2)
                                if _lastGunPos then myHRP.CFrame = _lastGunPos _lastGunPos = nil end
                            end)
                        end)
                        Notify("🔫", (Lang=="AR" and "أخذ: " or "Got: ")..obj.Name)
                        return
                    end
                end
            end
        end
    endnd

    local GetGunToggle = Tabs.Combat:AddToggle("MM2_GetGun", {
        Title = "🔫 Get Gun — Auto",
        Description = Lang=="AR" and "يأخذ سلاح الشريف تلقائياً لما يموت" or "Auto grabs sheriff gun when dropped",
        Default = false
    })
    GetGunToggle:OnChanged(function()
        GET_GUN_ENABLED = Options.MM2_GetGun.Value
        if GET_GUN_ENABLED then
            Notify("🔫", Lang=="AR" and "Get Gun مفعل — يراقب موت الشريف" or "Get Gun ON — watching sheriff")
            if getGunConn then getGunConn:Disconnect() end

            -- Use task.spawn loop with THROTTLE (not Heartbeat = 60fps lag!)
            getGunConn = {Disconnect = function() GET_GUN_ENABLED = false end}
            task.spawn(function()
                local lastCheck = 0
                while GET_GUN_ENABLED do
                    task.wait(0.8) -- Check every 0.8s only (not every frame!)
                    if not GET_GUN_ENABLED then break end
                    -- Check if we already have a gun
                    local myChar = LocalPlayer.Character
                    if myChar then
                        local hasGun = false
                        for _, t in pairs(myChar:GetChildren()) do
                            if t:IsA("Tool") then
                                local n = string.lower(t.Name)
                                if n:find("gun") or n:find("pistol") or n:find("revolver") then
                                    hasGun = true break
                                end
                            end
                        end
                        if not hasGun then tryGetGun() end
                    end
                end
            end)

            -- Hook sheriff deaths directly (much better than polling)
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    pcall(function()
                        if plr.Character then
                            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum.Died:Connect(function()
                                    if GET_GUN_ENABLED and getPlayerRole(plr) == "SHERIFF" then
                                        Notify("🔫", Lang=="AR" and "الشريف مات — أبحث عن السلاح..." or "Sheriff died — searching for gun...")
                                        task.wait(0.5) -- Wait for gun to drop
                                        for i = 1, 5 do -- Try 5 times
                                            if not GET_GUN_ENABLED then break end
                                            tryGetGun()
                                            task.wait(0.3)
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                end
            end
            -- Also watch for new players joining
            Players.PlayerAdded:Connect(function(plr)
                if not GET_GUN_ENABLED then return end
                plr.CharacterAdded:Connect(function(char)
                    local hum = char:WaitForChild("Humanoid", 5)
                    if hum then
                        hum.Died:Connect(function()
                            if GET_GUN_ENABLED and getPlayerRole(plr) == "SHERIFF" then
                                task.wait(0.5)
                                for i = 1, 5 do
                                    if not GET_GUN_ENABLED then break end
                                    tryGetGun()
                                    task.wait(0.3)
                                end
                            end
                        end)
                    end
                end)
            end)
        else
            GET_GUN_ENABLED = false
            if getGunConn and type(getGunConn.Disconnect) == "function" then
                getGunConn:Disconnect()
            end
            getGunConn = nil
            Notify("🔫", Lang=="AR" and "Get Gun أوقف" or "Get Gun OFF")
        end
    end)

    -- قائمة اللاعبين
    -- ── Fling ─────────────────────────────────────
    Tabs.Combat:AddSection("🌪️ Fling")

    local MM2_FlingTarget = nil
    local _flingNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(_flingNames, p.Name) end
    end
    if #_flingNames == 0 then _flingNames = {"..."} end

    local MM2_FlingDrop = Tabs.Combat:AddDropdown("MM2_FlingTarget", {
        Title = Lang=="AR" and "🌪️ اختر هدف الفلنق" or "🌪️ Fling Target",
        Values = _flingNames,
        Multi = false, Default = _flingNames[1]
    })
    if _flingNames[1] ~= "..." then MM2_FlingTarget = _flingNames[1] end
    MM2_FlingDrop:OnChanged(function(v)
        if v and v ~= "-- لا يوجد لاعبون --" then MM2_FlingTarget = v end
    end)

    local function MM2_DoFling(targetName)
        local t = Players:FindFirstChild(targetName)
        if not t or not t.Character then
            Notify("⚠️", Lang=="AR" and "اللاعب غير موجود" or "Player not found") return
        end
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local tHRP   = t.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP or not tHRP or not myHum then return end

        local savedPos = myHRP.CFrame

        -- Method: Sit inside target → launch OUR body at max speed through them
        -- We control OUR character so BodyVelocity on ours WORKS and physics pushes them
        myHRP.CFrame = tHRP.CFrame  -- teleport inside them first

        -- Remove old fling objects if any
        for _, v in pairs(myHRP:GetChildren()) do
            if v.Name == "BS_FlingBV" or v.Name == "BS_FlingBG" then v:Destroy() end
        end

        local bv = Instance.new("BodyVelocity")
        bv.Name = "BS_FlingBV"
        bv.MaxForce  = Vector3.new(math.huge, math.huge, math.huge)
        bv.P         = math.huge
        -- Random diagonal upward direction for chaos
        bv.Velocity  = Vector3.new(
            math.random(-1,1) * math.random(400,900),
            math.random(300,700),
            math.random(-1,1) * math.random(400,900)
        )
        bv.Parent = myHRP

        local bg = Instance.new("BodyGyro")
        bg.Name      = "BS_FlingBG"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.D         = 0
        bg.CFrame    = myHRP.CFrame
        bg.Parent    = myHRP

        -- Spam our position inside theirs to maximize physics impact
        task.spawn(function()
            for i = 1, 6 do
                if tHRP and tHRP.Parent then
                    myHRP.CFrame = tHRP.CFrame
                end
                task.wait(0.04)
            end
        end)

        -- Clean up after 1.5s and return home
        task.delay(1.5, function()
            pcall(function()
                if myHRP:FindFirstChild("BS_FlingBV") then myHRP.BS_FlingBV:Destroy() end
                if myHRP:FindFirstChild("BS_FlingBG") then myHRP.BS_FlingBG:Destroy() end
            end)
            task.wait(0.1)
            pcall(function() myHRP.CFrame = savedPos end)
        end)

        Notify("🌪️", (Lang=="AR" and "فلنق: " or "Flung: ") .. t.Name)
    end

    Tabs.Combat:AddButton({
        Title = "🌪️ " .. (Lang=="AR" and "فلنق اللاعب المختار" or "Fling Selected Player"),
        Callback = function()
            if not MM2_FlingTarget then Notify("⚠️", Lang=="AR" and "اختر لاعباً" or "Select a player") return end
            MM2_DoFling(MM2_FlingTarget)
        end
    })
    Tabs.Combat:AddButton({
        Title = "🔄 " .. (Lang=="AR" and "تحديث قائمة الفلنق" or "Refresh Fling List"),
        Callback = function()
            local names = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then table.insert(names, p.Name) end
            end
            if #names == 0 then names = {"..."} end
            pcall(function() MM2_FlingDrop:SetValues(names) end)
            if names[1] ~= "..." then MM2_FlingTarget = names[1] end
            Notify("🔄", Lang=="AR" and "تم تحديث القائمة" or "List refreshed")
        end
    })
    Tabs.Combat:AddButton({
        Title = "🌪️ " .. (Lang=="AR" and "فلنق الجميع" or "Fling Everyone"),
        Callback = function()
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    task.spawn(function() MM2_DoFling(p.Name) end)
                    task.wait(0.1)
                end
            end
        end
    })

    Tabs.Combat:AddSection("👥 Kill / Teleport")
    local MM2_SelectedTarget = nil
    local function MM2_GetPlayerNames()
        local names = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(names, p.Name) end end
        if #names == 0 then names = {"-- لا يوجد لاعبون --"} end
        return names
    end
    local initNames = MM2_GetPlayerNames()
    if initNames[1] ~= "-- لا يوجد لاعبون --" then MM2_SelectedTarget = initNames[1] end
    local MM2_PlayerDrop = Tabs.Combat:AddDropdown("MM2_TargetPlayer", {
        Title = "🎯 " .. L("choose_player"), Values = initNames, Multi = false, Default = initNames[1]
    })
    MM2_PlayerDrop:OnChanged(function(v)
        if v ~= "-- لا يوجد لاعبون --" then MM2_SelectedTarget = v Notify("🎯 تم","تم اختيار: "..v) end
    end)
    Tabs.Combat:AddButton({
        Title = "🔄 " .. L("refresh_list"),
        Callback = function()
            local names = MM2_GetPlayerNames()
            if names[1] ~= "-- لا يوجد لاعبون --" then MM2_SelectedTarget = names[1] end
            pcall(function() MM2_PlayerDrop:SetValues(names) end)
            Notify("🔄",L("list_updated").." | "..tostring(MM2_SelectedTarget))
        end
    })
    Tabs.Combat:AddButton({
        Title = "🚀 " .. L("tp_player"),
        Callback = function()
            if not MM2_SelectedTarget or MM2_SelectedTarget=="-- لا يوجد لاعبون --" then Notify("⚠️","اختر لاعباً أولاً!") return end
            local t=Players:FindFirstChild(MM2_SelectedTarget)
            local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") and myHRP then
                myHRP.CFrame=t.Character.HumanoidRootPart.CFrame*CFrame.new(0,0,3)
                Notify("🚀",L("tp_done").." "..t.Name)
            else Notify("⚠️",L("not_found")) end
        end
    })
    Tabs.Combat:AddButton({
        Title = "💀 " .. L("kill_player"),
        Description = Lang=="AR" and "يستخدم طريقة السكين الحقيقية" or "Uses real knife method",
        Callback = function()
            if getPlayerRole(LocalPlayer)~="KILLER" then Notify("🔪",L("killer_only")) return end
            if not MM2_SelectedTarget then Notify("⚠️",L("choose_first")) return end
            local t = Players:FindFirstChild(MM2_SelectedTarget)
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not t or not t.Character or not myHRP then Notify("⚠️",L("not_found")) return end
            -- Use same DoKill method (knife reach)
            local ok = MM2_DoKill(t, myHRP)
            Notify("💀", ok and (L("killed").." "..t.Name.."!") or (Lang=="AR" and "حاول — تأكد أنك قاتل وعندك سكين" or "Tried — make sure you're killer with knife"))
        end
    })
    -- ── Kill All ──────────────────────────────────
    local MM2_KillAllActive = false

    -- Helper: check if player is actually IN the MM2 round (not lobby/spectating)
    local function MM2_IsValidTarget(p)
        if p == LocalPlayer then return false end
        if not p.Character then return false end
        -- Must be in workspace directly (not in some lobby folder)
        if p.Character.Parent ~= workspace then return false end
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        local head = p.Character:FindFirstChild("Head")
        if not hum or not hrp or not head then return false end
        -- Must be alive
        if hum.Health <= 0 or hum.MaxHealth <= 0 then return false end
        -- Must have a visible head (spectators/lobby may have transparent chars)
        if head.Transparency >= 1 then return false end
        -- Must have walkspeed > 0 (dead/spectating players usually have 0)
        if hum.WalkSpeed <= 0 then return false end
        return true
    end

    -- ── Kill helper: knife reach method ──────────
    local function MM2_GetKnife()
        local c = LocalPlayer.Character
        if not c then return nil end
        -- Check equipped first
        for _, t in pairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("sword") then
                    return t
                end
            end
        end
        -- Then backpack
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, t in pairs(bp:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("sword") then
                        return t
                    end
                end
            end
        end
        return nil
    end

    local function MM2_DoKill(p, myHRP)
        if not MM2_IsValidTarget(p) then return false end
        local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return false end

        local knife = MM2_GetKnife()
        if not knife then return false end -- لازم عندك سكين

        local handle = knife:FindFirstChild("Handle")
        if not handle then return false end

        -- الطريقة الحقيقية من السورس المفتوح:
        -- firetouchinterest(EnemyRoot, Knife.Handle, 1) ثم 0
        -- هذا يسجل hit على السيرفر بشكل صحيح

        -- Step 1: تقرب من الهدف (ضروري للـ hitbox)
        myHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, 1.5)
        task.wait(0.05)

        -- Step 2: الطريقة الحقيقية
        pcall(function()
            firetouchinterest(hrp, handle, 1) -- touch begin
            firetouchinterest(hrp, handle, 0) -- touch end
        end)
        task.wait(0.05)

        -- Step 3: كبّر الـ handle وكرر (backup method)
        local origSize = handle.Size
        handle.Size = Vector3.new(15, 15, 15)
        handle.Transparency = 1
        task.wait(0.05)
        pcall(function()
            firetouchinterest(hrp, handle, 1)
            task.wait(0.03)
            firetouchinterest(hrp, handle, 0)
        end)
        task.wait(0.08)
        pcall(function()
            handle.Size = origSize
            handle.Transparency = 0
        end)

        task.wait(0.1)
        local killed = (not hum) or (not hum.Parent) or (hum.Health <= 0)
        return killed
    end

    local MM2_KillAllToggle = Tabs.Combat:AddToggle("MM2_KillAllAuto", {
        Title = "☠️ " .. L("kill_all") .. " — Auto Loop",
        Description = Lang=="AR" and "يقتل كل الأحياء تلقائياً (للقاتل)" or "Auto kills all alive players (Killer only)",
        Default = false
    })
    MM2_KillAllToggle:OnChanged(function()
        MM2_KillAllActive = Options.MM2_KillAllAuto.Value
        if MM2_KillAllActive then
            -- Check role
            if getPlayerRole(LocalPlayer) ~= "KILLER" then
                Options.MM2_KillAllAuto:SetValue(false)
                MM2_KillAllActive = false
                Notify("🔪", L("killer_only")) return
            end
            Notify("☠️", Lang=="AR" and "Kill All تلقائي مفعل!" or "Kill All Auto ON!")
            task.spawn(function()
                while MM2_KillAllActive do
                    -- Re-check still killer (role may change)
                    if getPlayerRole(LocalPlayer) ~= "KILLER" then
                        MM2_KillAllActive = false
                        pcall(function() Options.MM2_KillAllAuto:SetValue(false) end)
                        Notify("⚠️", Lang=="AR" and "لم تعد قاتلاً!" or "You are no longer the Killer!")
                        break
                    end
                    local myChar = LocalPlayer.Character
                    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                    -- Check we are alive
                    if not myHRP or not myHum or myHum.Health <= 0 then
                        task.wait(1) -- wait for respawn
                    else
                        local targets = {}
                        for _, p in pairs(Players:GetPlayers()) do
                            if MM2_IsValidTarget(p) then
                                table.insert(targets, p)
                            end
                        end
                        if #targets == 0 then
                            task.wait(1)
                        else
                            for _, p in pairs(targets) do
                                if not MM2_KillAllActive then break end
                                myChar = LocalPlayer.Character
                                myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                                if myHRP then
                                    MM2_DoKill(p, myHRP)
                                end
                                task.wait(0.2)
                            end
                            task.wait(0.5)
                        end
                    end
                end
                Notify("☠️", Lang=="AR" and "Kill All Auto أوقف" or "Kill All Auto OFF")
            end)
        else
            Notify("☠️", Lang=="AR" and "Kill All Auto أوقف" or "Kill All Auto OFF")
        end
    end)

    Tabs.Combat:AddButton({
        Title = "☠️ " .. L("kill_all") .. " — Once",
        Description = Lang=="AR" and "اقتل جميع الأحياء مرة واحدة" or "Kill all alive players once",
        Callback = function()
            if getPlayerRole(LocalPlayer) ~= "KILLER" then Notify("🔪", L("killer_only")) return end
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            local killed = 0
            for _, p in pairs(Players:GetPlayers()) do
                if MM2_IsValidTarget(p) then
                    if MM2_DoKill(p, myHRP) then
                        killed = killed + 1
                        -- Update myHRP ref after teleport
                        myChar = LocalPlayer.Character
                        myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        if not myHRP then break end
                    end
                end
            end
            Notify("☠️", L("kill_all_done") .. " " .. killed .. (Lang=="AR" and " لاعب!" or " players!"))
        end
    })

    -- ── المزيد من ميزات القتال ──
    Tabs.Combat:AddSection("⚡ " .. (Lang=="AR" and "ميزات متقدمة" or "Advanced"))

    -- Silent Aim (يطلق على القاتل بدون تصويب)
    local SILENT_AIM = false
    Tabs.Combat:AddToggle("MM2_SilentAim", {
        Title = "🎯 " .. (Lang=="AR" and "Silent Aim للشريف" or "Silent Aim (Sheriff)"),
        Description = Lang=="AR" and "يطلق على القاتل بدون تصويب يدوي" or "Auto-aims bullets at murderer",
        Default = false
    }):OnChanged(function()
        SILENT_AIM = Options.MM2_SilentAim.Value
        if SILENT_AIM then
            local ok = pcall(function()
                -- Use compat shims (work on all executors)
                if not _getrawmetatable or not _hookmetamethod then
                    SILENT_AIM = false
                    Options.MM2_SilentAim:SetValue(false)
                    Notify("⚠️", "هذا executor لا يدعم Silent Aim")
                    return
                end
                local mt = _getrawmetatable(game)
                pcall(_setreadonly, mt, false)
                local old = mt.__namecall
                mt.__namecall = _newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    local args = {...}
                    if SILENT_AIM and method == "InvokeServer" and self.Name == "ShootGun" then
                        -- وجد القاتل
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and getPlayerRole(p) == "KILLER" then
                                if p.Character and p.Character:FindFirstChild("Head") then
                                    args[2] = p.Character.Head.Position
                                    return old(self, unpack(args))
                                end
                            end
                        end
                    end
                    return old(self, ...)
                end)
                pcall(_setreadonly, mt, true)
            end)
            if ok then
                Notify("🎯", Lang=="AR" and "Silent Aim مفعل!" or "Silent Aim ON!")
            else
                Notify("⚠️", Lang=="AR" and "هذا executor لا يدعم Silent Aim" or "Executor doesn't support Silent Aim")
                SILENT_AIM = false
                Options.MM2_SilentAim:SetValue(false)
            end
        end
    end)

    -- Auto Knife Throw (يرمي السكين تلقائياً على الشريف/الأبرياء)
    local AUTO_THROW = false
    local _throwConn = nil
    Tabs.Combat:AddToggle("MM2_AutoThrow", {
        Title = "🔪 " .. (Lang=="AR" and "رمي السكين تلقائياً" or "Auto Knife Throw"),
        Description = Lang=="AR" and "للقاتل: يرمي السكين على أقرب لاعب" or "Killer: throws knife at nearest player",
        Default = false
    }):OnChanged(function()
        AUTO_THROW = Options.MM2_AutoThrow.Value
        if AUTO_THROW then
            if getPlayerRole(LocalPlayer) ~= "KILLER" then
                Options.MM2_AutoThrow:SetValue(false)
                AUTO_THROW = false
                Notify("🔪", L("killer_only")) return
            end
            if _throwConn then _throwConn:Disconnect() end
            _throwConn = RunService.Heartbeat:Connect(function()
                if not AUTO_THROW then return end
                local c = LocalPlayer.Character
                if not c then return end
                local knife = nil
                for _, t in pairs(c:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower():find("knife") then knife = t break end
                end
                if not knife then return end
                -- ابحث عن أقرب هدف
                local myHRP = c:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local closest, minDist = nil, 30
                for _, p in pairs(Players:GetPlayers()) do
                    if MM2_IsValidTarget(p) then
                        local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                        if tHRP then
                            local d = (tHRP.Position - myHRP.Position).Magnitude
                            if d < minDist then minDist = d closest = p end
                        end
                    end
                end
                if closest then
                    pcall(function()
                        local handle = knife:FindFirstChild("Handle")
                        if handle then
                            firetouchinterest(closest.Character.HumanoidRootPart, handle, 1)
                            firetouchinterest(closest.Character.HumanoidRootPart, handle, 0)
                        end
                    end)
                end
            end)
            Notify("🔪", Lang=="AR" and "Auto Throw مفعل" or "Auto Throw ON")
        else
            if _throwConn then _throwConn:Disconnect() _throwConn = nil end
        end
    end)

    -- Kill Counter
    local _killCount = 0
    local _killCountLabel = nil
    Tabs.Combat:AddButton({
        Title = "📊 " .. (Lang=="AR" and "إظهار عداد القتلى" or "Show Kill Counter"),
        Callback = function()
            if _killCountLabel then _killCountLabel:Destroy() _killCountLabel = nil return end
            _killCountLabel = Instance.new("ScreenGui")
            _killCountLabel.Name = "BoSqr_KC"
            _killCountLabel.ResetOnSpawn = false
            pcall(function() _killCountLabel.Parent = game:GetService("CoreGui") end)
            if not _killCountLabel.Parent then _killCountLabel.Parent = LocalPlayer.PlayerGui end
            local lbl = Instance.new("TextLabel")
            lbl.Parent = _killCountLabel
            lbl.BackgroundColor3 = Color3.fromRGB(20,20,30)
            lbl.BackgroundTransparency = 0.3
            lbl.Position = UDim2.new(0,10,0,60)
            lbl.Size = UDim2.new(0,140,0,32)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextColor3 = Color3.fromRGB(255,80,160)
            lbl.TextSize = 14
            lbl.Text = "☠️ Kills: 0"
            Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,8)
            -- Hook player deaths
            task.spawn(function()
                while _killCountLabel and _killCountLabel.Parent do
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            if hum and not hum:GetAttribute("_BS_died") then
                                hum:SetAttribute("_BS_died", true)
                                hum.Died:Connect(function()
                                    if getPlayerRole(LocalPlayer) == "KILLER" then
                                        _killCount = _killCount + 1
                                        if lbl then lbl.Text = "☠️ Kills: " .. _killCount end
                                    end
                                end)
                            end
                        end
                    end
                    task.wait(2)
                end
            end)
        end
    })

    -- ── PLAYER ────────────────────────────────────
    Tabs.Player:AddSection("📊 حركة اللاعب")
    Tabs.Player:AddSlider("MM2_WalkSpeed", {
        Title = "🏃 سرعة المشي", Min = 1, Max = 200, Default = 16, Rounding = 0,
        Callback = function(v) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed=v end end
    })
    Tabs.Player:AddSlider("MM2_JumpPower", {
        Title = "🦘 قوة القفز", Min = 1, Max = 300, Default = 50, Rounding = 0,
        Callback = function(v) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.JumpPower=v end end
    })
    Tabs.Player:AddSlider("MM2_FOV_Cam", {
        Title = "👁️ مجال الرؤية (FOV)", Min = 40, Max = 120, Default = 70, Rounding = 0,
        Callback = function(v) Camera.FieldOfView=v end
    })
    Tabs.Player:AddSection("🚀 حركة إضافية")
    local FlyToggle = Tabs.Player:AddToggle("MM2_Fly", { Title = "✈️ طيران (WASD+Space/Shift)", Default = false })
    FlyToggle:OnChanged(function()
        FLY_ENABLED = Options.MM2_Fly.Value
        if FLY_ENABLED then startFly() else stopFly() end
    end)
    Tabs.Player:AddSlider("MM2_FlySpeed", {
        Title = "✈️ سرعة الطيران", Min = 10, Max = 300, Default = 50, Rounding = 0,
        Callback = function(v) FLY_SPEED=v end
    })
    local InfJumpToggle = Tabs.Player:AddToggle("MM2_InfJump", { Title = "⬆️ قفز لا نهائي", Default = false })
    InfJumpToggle:OnChanged(function()
        INF_JUMP = Options.MM2_InfJump.Value
        if INF_JUMP then
            UIS.InputBegan:Connect(function(input,gp)
                if INF_JUMP and not gp and input.KeyCode==Enum.KeyCode.Space then
                    local c=LocalPlayer.Character if c then local h=c:FindFirstChild("HumanoidRootPart") if h then h.Velocity=Vector3.new(h.Velocity.X,50,h.Velocity.Z) end end
                end
            end)
        end
    end)
    local NoclipToggle = Tabs.Player:AddToggle("MM2_Noclip", { Title = "🚫 Noclip", Default = false })
    NoclipToggle:OnChanged(function()
        NO_CLIP = Options.MM2_Noclip.Value
        if NO_CLIP then startNoclip() else stopNoclip() end
    end)

    -- ── WORLD ─────────────────────────────────────
    Tabs.World:AddSection("💡 الإضاءة والبيئة")
    local FullBrightToggle = Tabs.World:AddToggle("MM2_FullBright", { Title = "☀️ Full Bright", Default = false })
    FullBrightToggle:OnChanged(function()
        if Options.MM2_FullBright.Value then Lighting.Brightness=10 Lighting.GlobalShadows=false
        else Lighting.Brightness=WorldSettings.OriginalBrightness Lighting.GlobalShadows=WorldSettings.OriginalGlobalShadows end
    end)
    local NoFogToggle = Tabs.World:AddToggle("MM2_NoFog", { Title = "🌫️ إزالة الضباب", Default = false })
    NoFogToggle:OnChanged(function()
        if Options.MM2_NoFog.Value then Lighting.FogStart=0 Lighting.FogEnd=999999
        else Lighting.FogStart=WorldSettings.OriginalFogStart Lighting.FogEnd=WorldSettings.OriginalFogEnd end
    end)
    local NoShadowsToggle = Tabs.World:AddToggle("MM2_NoShadows", { Title = "🌑 إزالة الظلال", Default = false })
    NoShadowsToggle:OnChanged(function() Lighting.GlobalShadows = not Options.MM2_NoShadows.Value end)
    Tabs.World:AddSlider("MM2_Gravity", {
        Title = "🌍 الجاذبية", Min = 0, Max = 500, Default = 196, Rounding = 0,
        Callback = function(v) workspace.Gravity=v end
    })
    Tabs.World:AddSlider("MM2_TimeOfDay", {
        Title = "🕐 وقت اللعبة", Min = 0, Max = 24, Default = 12, Rounding = 0,
        Callback = function(v) Lighting.ClockTime=v end
    })
    Tabs.World:AddSection("📊 معلومات السيرفر")
    Tabs.World:AddParagraph({
        Title = "معلومات",
        Content = "👥 اللاعبون: "..#Players:GetPlayers().." / "..Players.MaxPlayers.."\n🆔 معرف الماب: "..tostring(game.PlaceId)
    })

    -- ── EXTRA FEATURES ────────────────────────────
    Tabs.World:AddSection("✨ " .. (Lang=="AR" and "ميزات إضافية" or "Extra Features"))

    -- Trail effect
    local _trailEnabled = false
    local _trailObj = nil
    Tabs.World:AddToggle("MM2_Trail", {
        Title = "✨ " .. (Lang=="AR" and "أثر خلفك (Trail)" or "Trail Effect"),
        Default = false
    }):OnChanged(function()
        _trailEnabled = Options.MM2_Trail.Value
        local c = LocalPlayer.Character
        if not c then return end
        if _trailEnabled then
            local attach0 = Instance.new("Attachment")
            local attach1 = Instance.new("Attachment")
            local head = c:FindFirstChild("Head")
            local foot = c:FindFirstChild("LeftFoot") or c:FindFirstChild("HumanoidRootPart")
            if not head or not foot then return end
            attach0.Parent = head
            attach1.Parent = foot
            _trailObj = Instance.new("Trail")
            _trailObj.Attachment0 = attach0
            _trailObj.Attachment1 = attach1
            _trailObj.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,80,160)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170,80,255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0,200,220)),
            })
            _trailObj.Lifetime = 0.6
            _trailObj.Parent = c
            Notify("✨", Lang=="AR" and "Trail مفعل!" or "Trail ON!")
        else
            if _trailObj then _trailObj:Destroy() _trailObj = nil end
        end
    end)

    -- Crosshair
    local _crosshair = nil
    Tabs.World:AddToggle("MM2_Crosshair", {
        Title = "🎯 " .. (Lang=="AR" and "Crosshair (تصويب وسط الشاشة)" or "Crosshair"),
        Default = false
    }):OnChanged(function()
        if Options.MM2_Crosshair.Value then
            if _crosshair then _crosshair:Destroy() end
            _crosshair = Instance.new("ScreenGui")
            _crosshair.Name = "BoSqr_Crosshair"
            _crosshair.ResetOnSpawn = false
            pcall(function() _crosshair.Parent = game:GetService("CoreGui") end)
            if not _crosshair.Parent then _crosshair.Parent = LocalPlayer:WaitForChild("PlayerGui") end
            local function mkLine(w,h,x,y)
                local f = Instance.new("Frame")
                f.Parent = _crosshair
                f.BackgroundColor3 = Color3.fromRGB(255,80,160)
                f.BorderSizePixel = 0
                f.Size = UDim2.new(0,w,0,h)
                f.AnchorPoint = Vector2.new(0.5,0.5)
                f.Position = UDim2.new(0.5,x,0.5,y)
                return f
            end
            mkLine(20,2,0,0) -- horizontal
            mkLine(2,20,0,0) -- vertical
            local dot = Instance.new("Frame")
            dot.Parent = _crosshair
            dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
            dot.BorderSizePixel = 0
            dot.Size = UDim2.new(0,3,0,3)
            dot.AnchorPoint = Vector2.new(0.5,0.5)
            dot.Position = UDim2.new(0.5,0,0.5,0)
            Instance.new("UICorner",dot).CornerRadius = UDim.new(1,0)
            Notify("🎯", Lang=="AR" and "Crosshair مفعل!" or "Crosshair ON!")
        else
            if _crosshair then _crosshair:Destroy() _crosshair = nil end
        end
    end)

    -- Camera Zoom
    Tabs.World:AddSlider("MM2_CamZoom", {
        Title = "🔍 " .. (Lang=="AR" and "تكبير الكاميرا" or "Camera Zoom"),
        Min = 30, Max = 110, Default = 70, Rounding = 0,
        Callback = function(v) Camera.FieldOfView = v end
    })

    -- Anti-Slow (إزالة الـ slow)
    local _antiSlowConn = nil
    Tabs.World:AddToggle("MM2_AntiSlow", {
        Title = "🏃 " .. (Lang=="AR" and "Anti-Slow (إزالة البطء)" or "Anti-Slow"),
        Description = Lang=="AR" and "يمنع تأثيرات الإبطاء" or "Prevents slow debuffs",
        Default = false
    }):OnChanged(function()
        if Options.MM2_AntiSlow.Value then
            if _antiSlowConn then _antiSlowConn:Disconnect() end
            _antiSlowConn = RunService.Heartbeat:Connect(function()
                local c = LocalPlayer.Character
                if not c then return end
                local h = c:FindFirstChildOfClass("Humanoid")
                if h and h.WalkSpeed < 16 then h.WalkSpeed = 16 end
            end)
            Notify("🏃", Lang=="AR" and "Anti-Slow مفعل" or "Anti-Slow ON")
        else
            if _antiSlowConn then _antiSlowConn:Disconnect() _antiSlowConn = nil end
        end
    end)

    -- Coins ESP
    local _coinsESP = {}
    local _coinsESPActive = false
    Tabs.Esp:AddSection("💰 " .. (Lang=="AR" and "كشف العملات" or "Coin ESP"))
    Tabs.Esp:AddToggle("MM2_CoinESP", {
        Title = "💰 " .. (Lang=="AR" and "كشف الكوينز" or "Coin ESP"),
        Description = Lang=="AR" and "يضوي كل الكوينز في الماب" or "Highlights all coins on map",
        Default = false
    }):OnChanged(function()
        _coinsESPActive = Options.MM2_CoinESP.Value
        if _coinsESPActive then
            local function highlightCoin(coin)
                if _coinsESP[coin] then return end
                local h = Instance.new("Highlight")
                h.FillColor = Color3.fromRGB(255,215,0)
                h.OutlineColor = Color3.fromRGB(255,255,255)
                h.FillTransparency = 0.4
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = coin
                _coinsESP[coin] = h
            end
            -- ابحث في CoinContainer
            local cc = workspace:FindFirstChild("CoinContainer", true)
            if cc then
                for _, coin in pairs(cc:GetChildren()) do
                    if coin.Name == "Coin_Server" then highlightCoin(coin) end
                end
                cc.ChildAdded:Connect(function(coin)
                    if _coinsESPActive and coin.Name == "Coin_Server" then
                        highlightCoin(coin)
                    end
                end)
            end
            Notify("💰", Lang=="AR" and "Coin ESP مفعل!" or "Coin ESP ON!")
        else
            for _, h in pairs(_coinsESP) do
                if h then h:Destroy() end
            end
            _coinsESP = {}
        end
    end)

    -- Gun ESP (يضوي GunDrop)
    local _gunESPObj = nil
    Tabs.Esp:AddToggle("MM2_GunESP", {
        Title = "🔫 " .. (Lang=="AR" and "كشف السلاح (GunDrop)" or "Gun ESP"),
        Description = Lang=="AR" and "يضوي السلاح لما يطيح من الشريف" or "Highlights dropped sheriff gun",
        Default = false
    }):OnChanged(function()
        if Options.MM2_GunESP.Value then
            task.spawn(function()
                while Options.MM2_GunESP.Value do
                    local gd = workspace:FindFirstChild("GunDrop")
                    if gd and not _gunESPObj then
                        _gunESPObj = Instance.new("Highlight")
                        _gunESPObj.FillColor = Color3.fromRGB(0,255,255)
                        _gunESPObj.OutlineColor = Color3.fromRGB(255,255,0)
                        _gunESPObj.FillTransparency = 0.3
                        _gunESPObj.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        _gunESPObj.Parent = gd
                    elseif not gd and _gunESPObj then
                        _gunESPObj:Destroy()
                        _gunESPObj = nil
                    end
                    task.wait(0.5)
                end
                if _gunESPObj then _gunESPObj:Destroy() _gunESPObj = nil end
            end)
            Notify("🔫", Lang=="AR" and "Gun ESP مفعل!" or "Gun ESP ON!")
        end
    end)

    -- ── MISC ──────────────────────────────────────
    Tabs.Misc:AddSection("🔧 أدوات متنوعة")
    local AntiAFKToggle = Tabs.Misc:AddToggle("MM2_AntiAFK", { Title = "😴 Anti AFK", Default = false })
    AntiAFKToggle:OnChanged(function()
        WorldSettings.AntiAFK = Options.MM2_AntiAFK.Value
        if WorldSettings.AntiAFK then
            local vu=game:GetService("VirtualUser")
            LocalPlayer.Idled:Connect(function()
                if WorldSettings.AntiAFK then
                    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
                end
            end)
        end
    end)
    local InfZoomToggle = Tabs.Misc:AddToggle("MM2_InfZoom", { Title = "🔍 زووم لا نهائي", Default = false })
    InfZoomToggle:OnChanged(function() LocalPlayer.CameraMaxZoomDistance = Options.MM2_InfZoom.Value and 9999 or 128 end)
    Tabs.Misc:AddSection("🎨 ثيم Rayfield")
    Tabs.Misc:AddDropdown("MM2_Theme", {
        Title = "🎨 ثيم الواجهة",
        Values = {"Rose","Dark","Darker","Light","Aqua","Amethyst"},
        Multi = false, Default = "Rose"
    })
    -- ── Auto Farm Coins (طريقة حقيقية من سورس مفتوح) ────
    Tabs.Misc:AddSection("💰 " .. (Lang=="AR" and "Auto Farm" or "Auto Farm"))
    local MM2_AutoFarmActive = false

    local function MM2_AutoFarm()
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        -- البحث في CoinContainer (الطريقة الحقيقية في MM2)
        local CoinContainer = workspace:FindFirstChild("CoinContainer", true)
        if not CoinContainer then return end

        local coin = CoinContainer:FindFirstChild("Coin_Server")
        if not coin then return end

        -- انتقل للكوين
        local savedPos = myHRP.CFrame
        repeat
            if not MM2_AutoFarmActive then break end
            -- انتقل فوق الكوين بـ 2.5 وحدة أسفل (الطريقة الصحيحة)
            myHRP.CFrame = CFrame.new(coin.Position - Vector3.new(0, 2.5, 0))
                         * CFrame.Angles(0, 0, math.rad(180))
            RunService.Stepped:Wait()
        until not coin:IsDescendantOf(workspace) or coin.Name ~= "Coin_Server" or not MM2_AutoFarmActive
        task.wait(0.3)
    end

    local MM2_AutoFarmToggle = Tabs.Misc:AddToggle("MM2_AutoFarm", {
        Title = "💰 " .. (Lang=="AR" and "Auto Farm كوينز (تلقائي)" or "Auto Farm Coins"),
        Description = Lang=="AR" and "يجمع الكوينز تلقائياً — طريقة حقيقية" or "Real coin farm method — CoinContainer",
        Default = false
    })
    MM2_AutoFarmToggle:OnChanged(function()
        MM2_AutoFarmActive = Options.MM2_AutoFarm.Value
        if MM2_AutoFarmActive then
            Notify("💰", Lang=="AR" and "Auto Farm مفعل!" or "Auto Farm ON!")
            task.spawn(function()
                while MM2_AutoFarmActive do
                    local myChar = LocalPlayer.Character
                    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                    -- تأكد أنا حي وشخصيتي موجودة
                    if myChar and myHum and myHum.Health > 0 then
                        MM2_AutoFarm()
                    end
                    task.wait(0.1)
                end
                Notify("💰", Lang=="AR" and "Auto Farm أوقف" or "Auto Farm OFF")
            end)
        else
            Notify("💰", Lang=="AR" and "Auto Farm أوقف" or "Auto Farm OFF")
        end
    end)

    -- ── Auto Callout (إعلان القاتل في الشات) ─────────────
    Tabs.Misc:AddSection("📢 " .. (Lang=="AR" and "Callout" or "Callout"))
    local MM2_CalloutMsg = "Murderer is ${murderer} | Sheriff is ${sheriff}"
    Tabs.Misc:AddButton({
        Title = "📢 " .. (Lang=="AR" and "أعلن اسم القاتل في الشات" or "Callout Murderer in Chat"),
        Description = Lang=="AR" and "يرسل رسالة في الشات بأسماء القاتل والشريف" or "Send murderer/sheriff names to chat",
        Callback = function()
            pcall(function()
                -- استخدم role detection الحقيقية
                local killerName = "Unknown"
                local sheriffName = "Unknown"
                for _, p in pairs(Players:GetPlayers()) do
                    local r = getPlayerRole(p)
                    if r == "KILLER" then killerName = p.Name end
                    if r == "SHERIFF" then sheriffName = p.Name end
                end
                local msg = "🔪 Murderer: " .. killerName .. " | 🔫 Sheriff: " .. sheriffName
                game:GetService("ReplicatedStorage")
                    .DefaultChatSystemChatEvents
                    .SayMessageRequest:FireServer(msg, "normalchat")
                Notify("📢", (Lang=="AR" and "أُعلن: " or "Called out: ") .. killerName)
            end)
        end
    })

    Tabs.Misc:AddSection("⚙️")
    Tabs.Misc:AddButton({
        Title = "⚙️ " .. L("config"),
        Description = Lang=="AR" and "اذهب لتاب الإعدادات" or "Go to Config tab",
        Callback = function()
            pcall(function() Window:SelectTab(#Window.Tabs) end)
        end
    })

    -- Welcome notification
    -- ── CONFIG ────────────────────────────────────
    Tabs.Config:AddSection("🎨 " .. L("config_theme"))
    -- Theme: change Fluent accent color live using internal Fluent.Themes
    local _themeMap = {
        Rose     = {Accent=Color3.fromRGB(255,80,160),  Dark=Color3.fromRGB(20,10,18)},
        Dark     = {Accent=Color3.fromRGB(120,120,140), Dark=Color3.fromRGB(15,15,20)},
        Darker   = {Accent=Color3.fromRGB(80,80,100),   Dark=Color3.fromRGB(10,10,14)},
        Light    = {Accent=Color3.fromRGB(100,120,200), Dark=Color3.fromRGB(220,220,230)},
        Aqua     = {Accent=Color3.fromRGB(0,200,220),   Dark=Color3.fromRGB(10,20,25)},
        Amethyst = {Accent=Color3.fromRGB(170,80,255),  Dark=Color3.fromRGB(18,10,30)},
        Green    = {Accent=Color3.fromRGB(0,200,80),    Dark=Color3.fromRGB(10,20,12)},
        Orange   = {Accent=Color3.fromRGB(255,140,0),   Dark=Color3.fromRGB(22,14,8)},
        Red      = {Accent=Color3.fromRGB(255,50,50),   Dark=Color3.fromRGB(22,8,8)},
        Blue     = {Accent=Color3.fromRGB(50,130,255),  Dark=Color3.fromRGB(8,12,24)},
    }

    -- Theme engine: يعدل كل عناصر UI في CoreGui و PlayerGui
    local function applyTheme(v)
        local t = _themeMap[v]
        if not t then return end
        _G.BoSqr_Theme = v
        task.spawn(function()
            pcall(function()
                local function recolor(obj)
                    -- Frame/ScrollingFrame/TextButton: أعد تلوين الخلفيات الداكنة فقط
                    if obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("CanvasGroup") then
                        local c = obj.BackgroundColor3
                        local r,g,b = c.R*255, c.G*255, c.B*255
                        -- نعدل فقط العناصر الداكنة (الواجهة نفسها)
                        if r < 55 and g < 55 and b < 65 and obj.BackgroundTransparency < 0.9 then
                            obj.BackgroundColor3 = t.Dark
                        end
                    end
                    -- TextButton نفس الشيء
                    if obj:IsA("TextButton") and obj.BackgroundTransparency < 0.9 then
                        local c = obj.BackgroundColor3
                        local r,g,b = c.R*255, c.G*255, c.B*255
                        if r < 55 and g < 55 and b < 65 then
                            obj.BackgroundColor3 = t.Dark
                        end
                    end
                    -- UIStroke = الخطوط الملونة (accent)
                    if obj:IsA("UIStroke") then
                        obj.Color = t.Accent
                    end
                    -- ImageLabel / ImageButton الملونة
                    if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
                        local c = obj.ImageColor3
                        local r,g,b = c.R*255, c.G*255, c.B*255
                        -- لو مش أبيض خالص = accent
                        if not (r > 250 and g > 250 and b > 250) then
                            obj.ImageColor3 = t.Accent
                        end
                    end
                    -- Frame اللي يمثل toggle/accent color
                    if obj:IsA("Frame") then
                        local c = obj.BackgroundColor3
                        local r,g,b = c.R*255, c.G*255, c.B*255
                        -- لو لونه وردي/أرجواني قريب = accent
                        if r > 100 and b > 100 and g < 100 then
                            obj.BackgroundColor3 = t.Accent
                        end
                    end
                    for _, ch in pairs(obj:GetChildren()) do recolor(ch) end
                end
                -- طبق على CoreGui (حيث يعيش Fluent)
                local cg = game:GetService("CoreGui")
                for _, ch in pairs(cg:GetChildren()) do
                    pcall(recolor, ch)
                end
                -- وعلى PlayerGui
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if pg then for _, ch in pairs(pg:GetChildren()) do pcall(recolor, ch) end end
            end)
            Notify("🎨", v .. " ✅")
        end)
    end

    -- تطبيق الثيم المحفوظ (نؤخر قليلاً لأن Fluent يحتاج وقت)
    if _G.BoSqr_Theme then
        task.delay(1, function()
            pcall(function() applyTheme(_G.BoSqr_Theme) end)
        end)
    end

    local MM2_ThemeDrop = Tabs.Config:AddDropdown("MM2_ThemeDrop", {
        Title = L("config_theme"),
        Values = {"Rose","Amethyst","Aqua","Green","Orange","Red","Blue","Dark","Darker"},
        Multi = false, Default = _G.BoSqr_Theme or "Rose"
    })
    MM2_ThemeDrop:OnChanged(function(v) applyTheme(v) end)
    Tabs.Config:AddSection("🌐 " .. L("config_lang"))
    -- Set current default based on saved lang
    local _langDefault = (_G.BoSqr_Lang == "AR") and "AR - العربية" or "EN - English"
    local MM2_LangDrop = Tabs.Config:AddDropdown("MM2_LangDrop", {
        Title = L("config_lang"),
        Description = "Changes take effect on next execution",
        Values = {"EN - English", "AR - العربية"},
        Multi = false, Default = _langDefault
    })
    MM2_LangDrop:OnChanged(function(v)
        if v:sub(1,2) == "AR" then
            Lang = "AR"
            _G.BoSqr_Lang = "AR"
        else
            Lang = "EN"
            _G.BoSqr_Lang = "EN"
        end
        -- أشعل إشعار بالتأكيد + زر إعادة التشغيل
        Notify("🌐",
            Lang=="AR"
            and "✅ تم حفظ اللغة
أعد تشغيل السكربت لتطبيقها على التبويبات"
            or  "✅ Language saved
Re-run script to apply to tabs"
        )
    end)
    -- زر إعادة تشغيل السكربت (يطبق اللغة)
    Tabs.Config:AddButton({
        Title = "🔄 " .. (Lang=="AR" and "إعادة تشغيل السكربت (لتطبيق اللغة)" or "Restart Script (Apply Language)"),
        Description = Lang=="AR" and "يغلق ويعيد تشغيل السكربت فوراً" or "Closes and re-runs script instantly",
        Callback = function()
            pcall(ClearAllTracers) pcall(disableESP) pcall(DisableChams)
            pcall(function() FOV_Circle:Remove() end)
            pcall(stopFly) pcall(stopNoclip) pcall(stopKnifeReach)
            MM2_KillAllActive = false
            GET_GUN_ENABLED = false
            _getgenv().bosqr_loaded = nil
            pcall(function() Window:Destroy() end)
            -- إعادة تشغيل نفس السكربت
            task.wait(0.3)
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/BoSqr/Script/main/main.lua"))()
            end)
        end
    })
    Tabs.Config:AddSection("💾 " .. L("config_save"))
    -- Setup SaveManager for MM2
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        SaveManager:IgnoreFields({"MM2_ThemeDrop","MM2_LangDrop"})
        SaveManager:SetFolder("BoSqr_MM2")
        InterfaceManager:SetLibrary(Fluent)
        InterfaceManager:SetFolder("BoSqr_MM2")
    end)

    Tabs.Config:AddButton({
        Title = "💾 " .. L("config_save"),
        Callback = function()
            pcall(function() SaveManager:Save() end)
            Notify("💾", L("save_done"))
        end
    })
    Tabs.Config:AddButton({
        Title = "📂 " .. L("config_load"),
        Callback = function()
            pcall(function() SaveManager:Load() end)
            Notify("📂", L("load_done"))
        end
    })
    Tabs.Config:AddButton({
        Title = "🔄 " .. L("config_reset"),
        Description = Lang=="AR" and "حذف الإعدادات المحفوظة" or "Delete saved config",
        Callback = function()
            pcall(function()
                local path = "BoSqr_MM2/config.json"
                if _isfolder("BoSqr_MM2") then
                    if _isfile(path) then _delfile(path) end
                end
            end)
            Notify("🔄", L("reset_done"))
        end
    })
    Tabs.Config:AddSection("⚙️")
    Tabs.Config:AddButton({
        Title = "❌ " .. L("close_script"),
        Callback = function()
            pcall(ClearAllTracers) pcall(disableESP) pcall(DisableChams)
            pcall(function() FOV_Circle:Remove() end)
            pcall(stopFly) pcall(stopNoclip) pcall(stopKnifeReach)
            MM2_KillAllActive = false
            GET_GUN_ENABLED = false
            if getGunConn then getGunConn:Disconnect() end
            -- Allow re-execution
            _getgenv().bosqr_loaded = nil
            pcall(function() Window:Destroy() end)
        end
    })

    task.wait(1)
    Notify("✅ Bo.Sqr | MM2", L("welcome_mm2"), 8)
    Window:SelectTab(1)
    print("✅ Bo.Sqr | MM2 - تم التحميل | Discord: Riveteam")


-- ══════════════════════════════════════════════════════════════════
-- KINGDOM WORLD
-- ══════════════════════════════════════════════════════════════════
elseif currentMapID == _B then

    local Player    = LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid  = Character:WaitForChild("Humanoid")
    local HRP       = Character:WaitForChild("HumanoidRootPart")

    Player.CharacterAdded:Connect(function(char)
        Character = char
        Humanoid  = char:WaitForChild("Humanoid")
        HRP       = char:WaitForChild("HumanoidRootPart")
    end)

    -- ===== VARIABLES =====
    local FlyActive=false local FlyConn=nil
    local NoclipActive=false local NoclipConn=nil
    local InfJumpActive=false
    local GodModeActive=false
    local AutoHealActive=false
    local ESPActive=false
    local SmartFarmActive=false
    local AutoFarmDriveActive=false local AutoFarmConn=nil local AutoFarmSpeed=120
    local DriftFarmActive=false
    local AimbotActive=false local AimbotConn=nil
    local SilentAimActive=false local SilentAimHook=nil
    local TriggerBotActive=false local TriggerBotConn=nil
    local WallBangActive=false
    local SpeedHackActive=false local SpeedHackConn=nil
    local AntiFlingActive=false local AntiFlingConn=nil
    local InfStaminaActive=false
    local ChatSpyActive=false
    local AutoClickerActive=false local AutoClickerConn=nil
    local AimbotPart="Head" local AimbotSmoothness=0.5 local AimbotFOV=200 local AimbotTeamCheck=true
    local SavedLocations={}
    local CurrentAnimation=nil
    local KW_CarSpeedVal=100

    -- ===== FUNCTIONS =====
    local function GetSeat() if not Humanoid then return nil end return Humanoid.SeatPart end
    local function GetCarModel() local s=GetSeat() if s then return s:FindFirstAncestorOfClass("Model") end return nil end

    local function BoostCarSpeed(targetSpeed)
        local seat=GetSeat() if not seat or not seat:IsA("VehicleSeat") then Notify("⚠️","يجب أن تكون راكب سيارة!") return false end
        local carModel=GetCarModel() if not carModel then Notify("⚠️","لم يتم العثور على السيارة") return false end
        seat.MaxSpeed=targetSpeed
        local oldBoost=carModel:FindFirstChild("BoostVelocity",true) if oldBoost then oldBoost:Destroy() end
        local bv=Instance.new("BodyVelocity") bv.Name="BoostVelocity" bv.MaxForce=Vector3.new(999999,0,999999) bv.P=10000 bv.Velocity=seat.CFrame.LookVector*targetSpeed bv.Parent=seat
        for _,p in pairs(carModel:GetDescendants()) do if p:IsA("BasePart") then p.CustomPhysicalProperties=PhysicalProperties.new(0.01,0.01,0.01,0.01,0.01) end end
        seat.AssemblyLinearVelocity=seat.CFrame.LookVector*targetSpeed
        local bf=Instance.new("BodyForce") bf.Name="BoostForce" bf.Force=seat.CFrame.LookVector*(targetSpeed*100) bf.Parent=seat
        Notify("🚀 تم","السرعة: "..targetSpeed.." كم/س | 5 طرق تسريع!",4) return true
    end

    local function ResetCarSpeed()
        local seat=GetSeat() if not seat then Notify("⚠️","يجب أن تكون راكب سيارة!") return end
        local carModel=GetCarModel() seat.MaxSpeed=50
        local boost=carModel and carModel:FindFirstChild("BoostVelocity",true) if boost then boost:Destroy() end
        local force=carModel and carModel:FindFirstChild("BoostForce",true) if force then force:Destroy() end
        if carModel then for _,p in pairs(carModel:GetDescendants()) do if p:IsA("BasePart") then p.CustomPhysicalProperties=nil end end end
        Notify("🛑 تم","تم إعادة السرعة للوضع الطبيعي")
    end

    local function StartDriftFarm()
        local seat=GetSeat() if not seat or not seat:IsA("VehicleSeat") then Notify("⚠️","يجب أن تكون راكب سيارة أولاً!") return false end
        DriftFarmActive=true Notify("🔥 فحط تلقائي","جاري الفحط وجمع الفلوس...")
        spawn(function()
            while DriftFarmActive do task.wait(0.03) if not Character or not Humanoid then break end
                local cs=Humanoid.SeatPart if not cs or not cs:IsA("VehicleSeat") then break end
                local dp=_G.DriftPower or 50 cs.Steer=math.sin(tick()*3) cs.Throttle=0.8
                local right=cs.CFrame.RightVector cs.AssemblyLinearVelocity=cs.AssemblyLinearVelocity+(right*dp*0.5) cs.AssemblyAngularVelocity=Vector3.new(0,dp*1.2,0)
            end
            local s=GetSeat() if s and s:IsA("VehicleSeat") then s.Steer=0 s.Throttle=0 s.AssemblyAngularVelocity=Vector3.new(0,0,0) end
        end) return true
    end

    local function ToggleFly()
        FlyActive=not FlyActive
        if FlyActive then
            local bg=Instance.new("BodyGyro") bg.Name="FlyGyro" bg.P=10000 bg.MaxTorque=Vector3.new(10000,10000,10000) bg.CFrame=HRP.CFrame bg.Parent=HRP
            local bv=Instance.new("BodyVelocity") bv.Name="FlyVelocity" bv.Velocity=Vector3.new(0,0,0) bv.MaxForce=Vector3.new(10000,10000,10000) bv.Parent=HRP
            local speed=_G.FlySpeed or 100
            FlyConn=RunService.RenderStepped:Connect(function()
                if not FlyActive then return end if not HRP then return end
                local cam=workspace.CurrentCamera local mv=Vector3.new(0,0,0) local uis=UserInputService
                if uis:IsKeyDown(Enum.KeyCode.W) then mv=mv+cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then mv=mv-cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then mv=mv-cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then mv=mv+cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftShift) then mv=mv-Vector3.new(0,1,0) end
                if mv.Magnitude>0 then mv=mv.Unit*speed end bv.Velocity=mv bg.CFrame=cam.CFrame
            end)
            Notify("✈️ طيران","WASD | Space للأعلى | Shift للأسفل",5)
        else
            if FlyConn then FlyConn:Disconnect() end
            local gyro=HRP:FindFirstChild("FlyGyro") local vel=HRP:FindFirstChild("FlyVelocity")
            if gyro then gyro:Destroy() end if vel then vel:Destroy() end Notify("⛔","تم إيقاف الطيران")
        end
    end

    local function ToggleNoclip()
        NoclipActive=not NoclipActive
        if NoclipActive then
            NoclipConn=RunService.Stepped:Connect(function()
                if not Character then return end
                for _,p in pairs(Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
            end)
            Notify("👻 Noclip","يمكنك المرور عبر الجدران!")
        else
            if NoclipConn then NoclipConn:Disconnect() end
            if Character then for _,p in pairs(Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
            Notify("🧱","تم إيقاف Noclip")
        end
    end

    local function ToggleGodMode()
        GodModeActive=not GodModeActive
        if GodModeActive then
            spawn(function() while GodModeActive do task.wait(0.1) if Humanoid then Humanoid.MaxHealth=math.huge Humanoid.Health=math.huge end end end)
            Notify("🛡️ God Mode","لا يمكنك الموت الآن!")
        else
            if Humanoid then Humanoid.MaxHealth=100 Humanoid.Health=100 end Notify("💀","تم إيقاف God Mode")
        end
    end

    local function FullBright()
        local l=game:GetService("Lighting") l.Brightness=10 l.ClockTime=14 l.FogEnd=100000 l.GlobalShadows=false l.OutdoorAmbient=Color3.fromRGB(255,255,255)
        for _,e in pairs(l:GetChildren()) do if e:IsA("Atmosphere") or e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then e.Enabled=false end end
        Notify("☀️","تم تفعيل الإضاءة الكاملة!")
    end

    local function CreateESP(player)
        if player==Player or not player.Character then return end
        local h=Instance.new("Highlight") h.Name="UltraESP" h.FillColor=Color3.fromRGB(255,0,255) h.OutlineColor=Color3.fromRGB(255,255,0) h.FillTransparency=0.5 h.OutlineTransparency=0 h.Parent=player.Character
        local bb=Instance.new("BillboardGui") bb.Name="ESPInfo" bb.Size=UDim2.new(0,200,0,50) bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true
        local tl=Instance.new("TextLabel") tl.Size=UDim2.new(1,0,1,0) tl.BackgroundTransparency=1 tl.TextColor3=Color3.fromRGB(255,255,255) tl.TextStrokeTransparency=0 tl.TextSize=14 tl.Font=Enum.Font.GothamBold tl.Parent=bb
        bb.Parent=player.Character:FindFirstChild("Head") or player.Character:WaitForChild("Head")
        spawn(function()
            while ESPActive and player.Character do task.wait(0.5) if not player.Character then break end
                local dist=0 if HRP and player.Character:FindFirstChild("HumanoidRootPart") then dist=(HRP.Position-player.Character.HumanoidRootPart.Position).Magnitude end
                local health="N/A" if player.Character:FindFirstChild("Humanoid") then health=math.floor(player.Character.Humanoid.Health) end
                tl.Text=player.Name.." | ❤️ "..health.." | 📏 "..math.floor(dist).."m"
            end
        end)
    end
    local function ToggleESP()
        ESPActive=not ESPActive
        if ESPActive then for _,p in pairs(game.Players:GetPlayers()) do if p~=Player then CreateESP(p) end end Notify("👁️ ESP","كشف محسن مع معلومات اللاعبين!")
        else
            for _,p in pairs(game.Players:GetPlayers()) do if p.Character then
                local e=p.Character:FindFirstChild("UltraESP") local i=p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("ESPInfo")
                if e then e:Destroy() end if i then i:Destroy() end
            end end Notify("👁️","تم إيقاف ESP")
        end
    end

    local function StartSmartFarm()
        SmartFarmActive=true Notify("🤖 Smart Farm","جاري البحث الذكي عن الفلوس...")
        spawn(function()
            while SmartFarmActive do task.wait(0.5) if not Character or not HRP then continue end
                local bestTarget=nil local bestScore=0
                for _,obj in pairs(workspace:GetDescendants()) do
                    if not SmartFarmActive then break end
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                        local moneyNames={"Money","Cash","Coin","Gold","Riyal","فلوس","مال","نقود","ريال","CashPart","Collectible"}
                        for _,n in pairs(moneyNames) do
                            if obj.Name:lower():find(n:lower()) then
                                local dist=(HRP.Position-obj.Position).Magnitude
                                if dist<=200 then local score=1000/(dist+1) if score>bestScore then bestScore=score bestTarget=obj end end break
                            end
                        end
                    end
                end
                if bestTarget then
                    local ti=TweenInfo.new((HRP.Position-bestTarget.Position).Magnitude/80,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
                    local tween=TweenService:Create(HRP,ti,{CFrame=bestTarget.CFrame+Vector3.new(0,2,0)}) tween:Play() tween.Completed:Wait()
                    firetouchinterest(HRP,bestTarget,0) task.wait(0.1) firetouchinterest(HRP,bestTarget,1)
                end
            end
        end)
    end

    local function StartAutoFarmDrive(speed)
        if AutoFarmDriveActive then AutoFarmSpeed=speed Notify("🤖","تم تغيير السرعة إلى: "..speed) return true end
        local seat=GetSeat() if not seat or not seat:IsA("VehicleSeat") then Notify("⚠️","يجب أن تكون راكب سيارة أولاً!") return false end
        AutoFarmDriveActive=true AutoFarmSpeed=speed
        Notify("🤖 تجميع تلقائي","السيارة تمشي بسرعة "..speed.." وتجمع الفلوس!",4)
        AutoFarmConn=RunService.Heartbeat:Connect(function()
            if not AutoFarmDriveActive then return end if not Character or not Humanoid then return end
            local cs=Humanoid.SeatPart if not cs or not cs:IsA("VehicleSeat") then AutoFarmDriveActive=false if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn=nil end return end
            cs.Throttle=1 cs.Steer=math.sin(tick()*0.5)*0.3 cs.MaxSpeed=AutoFarmSpeed cs.AssemblyLinearVelocity=cs.CFrame.LookVector*AutoFarmSpeed
            if HRP then
                for _,obj in pairs(workspace:GetDescendants()) do if obj:IsA("BasePart") then
                    local d=(HRP.Position-obj.Position).Magnitude if d<=30 then
                        local mn={"Money","Cash","Coin","Gold","Riyal","فلوس","مال","نقود","ريال","CashPart","Reward","Collectible"}
                        for _,n in pairs(mn) do if obj.Name:lower():find(n:lower()) then
                            pcall(function() firetouchinterest(HRP,obj,0) task.wait(0.05) firetouchinterest(HRP,obj,1) end) break end end
                    end end end
            end
        end) return true
    end

    local function StopAutoFarmDrive()
        AutoFarmDriveActive=false if AutoFarmConn then AutoFarmConn:Disconnect() AutoFarmConn=nil end
        local seat=GetSeat() if seat and seat:IsA("VehicleSeat") then seat.Throttle=0 seat.Steer=0 seat.MaxSpeed=50 end
        Notify("🛑","تم إيقاف التجميع التلقائي")
    end

    local function GetClosestPlayerKW()
        local cp=nil local sd=AimbotFOV local mouse=Player:GetMouse() local cam=workspace.CurrentCamera
        for _,p in pairs(game.Players:GetPlayers()) do
            if p~=Player and p.Character and p.Character:FindFirstChild(AimbotPart) then
                if AimbotTeamCheck and p.Team==Player.Team then continue end
                local pp=p.Character[AimbotPart] local sp,os=cam:WorldToViewportPoint(pp.Position)
                if os then local d=(Vector2.new(sp.X,sp.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude if d<sd then sd=d cp=p end end
            end
        end return cp
    end

    local function ToggleAimbot()
        AimbotActive=not AimbotActive
        if AimbotActive then
            Notify("🎯 Aimbot","Aimbot مفعل!")
            AimbotConn=RunService.RenderStepped:Connect(function()
                if not AimbotActive then return end
                local t=GetClosestPlayerKW() if t and t.Character and t.Character:FindFirstChild(AimbotPart) then
                    local cam=workspace.CurrentCamera cam.CFrame=cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position,t.Character[AimbotPart].Position),AimbotSmoothness) end
            end)
        else if AimbotConn then AimbotConn:Disconnect() end Notify("🎯","Aimbot معطل") end
    end

    local function ToggleSilentAim()
        SilentAimActive=not SilentAimActive
        if SilentAimActive then
            Notify("🔫 Silent Aim","Silent Aim مفعل!")
            if not _getrawmetatable then
                Notify("⚠️","هذا executor لا يدعم Silent Aim")
                SilentAimActive = false return
            end
            local mt = _getrawmetatable(game)
            pcall(_setreadonly, mt, false)
            local old = mt.__namecall
            SilentAimHook = mt.__namecall
            mt.__namecall = _newcclosure(function(self,...)
                local method=getnamecallmethod()
                if method=="FireServer" and SilentAimActive then
                    local args={...}
                    if #args>=2 and typeof(args[2])=="Vector3" then
                        local t2=GetClosestPlayerKW() -- renamed to avoid conflict
                        if t2 and t2.Character and t2.Character:FindFirstChild("Head") then
                            args[2]=t2.Character.Head.Position return old(self,unpack(args)) end end end
                return old(self,...) end)
        else if SilentAimHook and _getrawmetatable then local mt = _getrawmetatable(game) pcall(_setreadonly, mt, false) mt.__namecall = SilentAimHook end Notify("🔫","Silent Aim معطل") end
    end

    local function ServerHop()
        Notify("🌐","جاري البحث عن سيرفر جديد...")
        local ok,result=pcall(function() return game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
        if ok and result and result.data then
            local valid={} for _,s in pairs(result.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then table.insert(valid,s) end end
            if #valid>0 then Notify("🌐","جاري الانتقال...") game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,valid[math.random(1,#valid)].id,Player)
            else Notify("⚠️","لا يوجد سيرفرات متاحة!") end
        else Notify("⚠️","فشل في جلب السيرفرات!") end
    end

    local function FlingPlayer(targetName)
        local t=game.Players:FindFirstChild(targetName) if not t or not t.Character or not t.Character:FindFirstChild("HumanoidRootPart") then Notify("⚠️","اللاعب غير موجود!") return end
        local th=t.Character.HumanoidRootPart
        local bv=Instance.new("BodyVelocity") bv.Velocity=Vector3.new(math.random(-500,500),500,math.random(-500,500)) bv.MaxForce=Vector3.new(999999,999999,999999) bv.Parent=th
        local bg=Instance.new("BodyGyro") bg.MaxTorque=Vector3.new(999999,999999,999999) bg.Parent=th
        task.wait(2) bv:Destroy() bg:Destroy() Notify("😈","تم رمي "..t.Name.."!")
    end
    local function BringPlayer(targetName)
        local t=game.Players:FindFirstChild(targetName) if not t or not t.Character then Notify("⚠️","اللاعب غير موجود!") return end
        if HRP then t.Character.HumanoidRootPart.CFrame=HRP.CFrame+Vector3.new(0,3,3) Notify("😈","تم جلب "..t.Name.."!") end
    end
    local function FreezePlayer(targetName)
        local t=game.Players:FindFirstChild(targetName) if not t or not t.Character then Notify("⚠️","اللاعب غير موجود!") return end
        for _,p in pairs(t.Character:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true end end Notify("🧊","تم تجميد "..t.Name.."!")
    end
    local function UnfreezePlayer(targetName)
        local t=game.Players:FindFirstChild(targetName) if not t or not t.Character then Notify("⚠️","اللاعب غير موجود!") return end
        for _,p in pairs(t.Character:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=false end end Notify("🔓","تم إلغاء تجميد "..t.Name.."!")
    end
    local function PlayAnimation(animId)
        if CurrentAnimation then CurrentAnimation:Stop() CurrentAnimation=nil end if not Humanoid then return end
        local anim=Instance.new("Animation") anim.AnimationId="rbxassetid://"..animId
        CurrentAnimation=Humanoid:LoadAnimation(anim) CurrentAnimation:Play() Notify("🎭","تم تشغيل الحركة!")
    end

    -- ══════════════════════════════════════════════
    -- TABS KW
    -- ══════════════════════════════════════════════
    local Tabs = {
        Home       = Window:AddTab({ Title = L("home"),        Icon = "home" }),
        Player     = Window:AddTab({ Title = L("player"),      Icon = "user" }),
        Cars       = Window:AddTab({ Title = L("cars"),        Icon = "car" }),
        Farm       = Window:AddTab({ Title = L("farm"),        Icon = "coins" }),
        Combat     = Window:AddTab({ Title = L("combat"),      Icon = "crosshair" }),
        Teleport   = Window:AddTab({ Title = L("teleport"),    Icon = "map-pin" }),
        Trolling   = Window:AddTab({ Title = L("trolling"),    Icon = "smile" }),
        Animations = Window:AddTab({ Title = L("animations"),  Icon = "play" }),
        Visual     = Window:AddTab({ Title = L("visual"),      Icon = "sparkles" }),
        Server     = Window:AddTab({ Title = L("server"),      Icon = "globe" }),
        Misc       = Window:AddTab({ Title = L("misc"),        Icon = "wrench" }),
        Config     = Window:AddTab({ Title = L("config"),      Icon = "sliders-horizontal" }),
    }

    -- ── HOME ──────────────────────────────────────
    Tabs.Home:AddSection("👑 Bo.Sqr | " .. (Lang=="AR" and "عالم المملكة ULTIMATE" or "Kingdom World ULTIMATE"))
    Tabs.Home:AddParagraph({
        Title = "👑 " .. L("dev"),
        Content = "💬 " .. L("dev_content")
    })
    Tabs.Home:AddParagraph({
        Title = "👤 " .. L("profile"),
        Content = "Name: @"..Player.Name.."\nID: "..tostring(Player.UserId).."\nExecutor: "..((_identifyexecutor()) or "Unknown")
    })
    Tabs.Home:AddButton({
        Title = "💬 " .. L("copy_discord"),
        Description = "discord.gg/Riveteam",
        Callback = function() setclipboard("discord.gg/Riveteam") Notify("✅",L("copy_done")) end
    })

    -- ── PLAYER ────────────────────────────────────
    Tabs.Player:AddSection("⚡ قوى خارقة")
    Tabs.Player:AddSlider("KW_WalkSpeed", { Title="🏃 سرعة المشي", Min=16, Max=1000, Default=16, Rounding=0,
        Callback=function(v) if Humanoid then Humanoid.WalkSpeed=v end end })
    Tabs.Player:AddSlider("KW_JumpPower", { Title="🦘 قوة القفز", Min=50, Max=1000, Default=50, Rounding=0,
        Callback=function(v) if Humanoid then Humanoid.JumpPower=v end end })
    local FlyToggleKW = Tabs.Player:AddToggle("KW_Fly", { Title="✈️ طيران", Default=false })
    FlyToggleKW:OnChanged(function()
        if Options.KW_Fly.Value then if not FlyActive then ToggleFly() end
        else if FlyActive then ToggleFly() end end
    end)
    Tabs.Player:AddSlider("KW_FlySpeed", { Title="✈️ سرعة الطيران", Min=50, Max=500, Default=100, Rounding=0,
        Callback=function(v) _G.FlySpeed=v end })
    local NoclipToggleKW = Tabs.Player:AddToggle("KW_Noclip", { Title="👻 Noclip", Default=false })
    NoclipToggleKW:OnChanged(function()
        if Options.KW_Noclip.Value then if not NoclipActive then ToggleNoclip() end
        else if NoclipActive then ToggleNoclip() end end
    end)
    local InfJumpToggleKW = Tabs.Player:AddToggle("KW_InfJump", { Title="🦘 Infinite Jump", Default=false })
    InfJumpToggleKW:OnChanged(function() InfJumpActive=Options.KW_InfJump.Value if InfJumpActive then Notify("🦘","اضغط Space باستمرار!") end end)
    game:GetService("UserInputService").JumpRequest:Connect(function() if InfJumpActive and Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
    local GodModeToggleKW = Tabs.Player:AddToggle("KW_GodMode", { Title="🛡️ God Mode", Default=false })
    GodModeToggleKW:OnChanged(function()
        if Options.KW_GodMode.Value then if not GodModeActive then ToggleGodMode() end
        else if GodModeActive then ToggleGodMode() end end
    end)
    local AutoHealToggleKW = Tabs.Player:AddToggle("KW_AutoHeal", { Title="💚 Auto Heal", Default=false })
    AutoHealToggleKW:OnChanged(function()
        AutoHealActive=Options.KW_AutoHeal.Value
        if AutoHealActive then
            spawn(function() while AutoHealActive do task.wait(0.5) if Humanoid and Humanoid.Health<Humanoid.MaxHealth then Humanoid.Health=Humanoid.Health+5 end end end)
            Notify("💚 Auto Heal","الشفاء التلقائي نشط!")
        end
    end)
    Tabs.Player:AddButton({ Title="🔄 إعادة تعيين الحالة", Callback=function()
        if Humanoid then Humanoid.WalkSpeed=16 Humanoid.JumpPower=50 Humanoid.MaxHealth=100 Humanoid.Health=100 end
        Notify("🔄 تم","تم إعادة تعيين جميع الإعدادات")
    end})

    -- ── CARS ──────────────────────────────────────
    Tabs.Cars:AddSection("⚙️ التحكم بالسيارة")
    Tabs.Cars:AddSlider("KW_CarSpeed", { Title="⚡ سرعة السيارة", Min=50, Max=1000, Default=100, Rounding=0,
        Callback=function(v) KW_CarSpeedVal=v end })
    local CarSpeedToggle = Tabs.Cars:AddToggle("KW_CarSpeedToggle", { Title="🚗 تفعيل سرعة السيارة", Default=false })
    CarSpeedToggle:OnChanged(function()
        _G.KW_CarSpeedActive=Options.KW_CarSpeedToggle.Value
        if _G.KW_CarSpeedActive then
            Notify("🚗 تم","سرعة السيارة مفعلة!")
            spawn(function()
                while _G.KW_CarSpeedActive do task.wait(0.1) pcall(function() local seat=GetSeat() if seat then seat.MaxSpeed=KW_CarSpeedVal end end) end
                pcall(function() local s=GetSeat() if s then s.MaxSpeed=50 end end)
            end)
        else Notify("🛑","تم إيقاف السرعة") end
    end)
    Tabs.Cars:AddSection("🚀 تسريع فوري")
    Tabs.Cars:AddButton({ Title="⚡ سرعة 300 كم/س",  Callback=function() BoostCarSpeed(300)  end })
    Tabs.Cars:AddButton({ Title="🚀 سرعة 500 كم/س",  Callback=function() BoostCarSpeed(500)  end })
    Tabs.Cars:AddButton({ Title="🔥 سرعة 1000 كم/س", Callback=function() BoostCarSpeed(1000) end })
    Tabs.Cars:AddButton({ Title="🛑 إيقاف التسريع",   Callback=function() ResetCarSpeed()    end })
    Tabs.Cars:AddSection("🔥 دريفت (فحط)")
    local DriftToggle = Tabs.Cars:AddToggle("KW_Drift", { Title="🔥 فحط تلقائي", Default=false })
    DriftToggle:OnChanged(function()
        DriftFarmActive=Options.KW_Drift.Value
        if DriftFarmActive then local ok=StartDriftFarm() if not ok then DriftFarmActive=false end
        else Notify("⛔","تم إيقاف الفحط") local s=GetSeat() if s and s:IsA("VehicleSeat") then s.Steer=0 s.Throttle=0 s.AssemblyAngularVelocity=Vector3.new(0,0,0) end end
    end)
    Tabs.Cars:AddSlider("KW_DriftPower", { Title="⚡ قوة الدوران", Min=19, Max=100, Default=50, Rounding=0,
        Callback=function(v) _G.DriftPower=v end })
    Tabs.Cars:AddSection("⬆️ الترفيع (Wheelie)")
    local KW_LiftPower = 0.5
    Tabs.Cars:AddSlider("KW_LiftPower", { Title="💪 قوة الترفيع", Min=1, Max=10, Default=5, Rounding=0,
        Callback=function(v) KW_LiftPower=v/10 end })
    local LeftLiftToggle = Tabs.Cars:AddToggle("KW_LeftLift", { Title="⬅️ ترفيع كفرين يسار", Default=false })
    LeftLiftToggle:OnChanged(function()
        _G.KW_LeftLift=Options.KW_LeftLift.Value
        if _G.KW_LeftLift then Notify("⬅️ تم","ترفيع كفرين يسار مفعل!",2)
            spawn(function()
                while _G.KW_LeftLift do task.wait(0.05) pcall(function()
                    local car=GetCarModel() if car and car.PrimaryPart then
                        local gyro=car.PrimaryPart:FindFirstChild("KW_LeftLiftGyro") or Instance.new("BodyGyro")
                        gyro.Name="KW_LeftLiftGyro" gyro.MaxTorque=Vector3.new(0,0,500000) gyro.P=10000 gyro.D=500
                        gyro.CFrame=car.PrimaryPart.CFrame*CFrame.Angles(0,0,math.rad(KW_LiftPower*45)) gyro.Parent=car.PrimaryPart
                        car.PrimaryPart.CustomPhysicalProperties=PhysicalProperties.new(0.3-(KW_LiftPower*0.2),0.1,0.1,1,1) end end) end
                pcall(function() local car=GetCarModel() if car and car.PrimaryPart then
                    if car.PrimaryPart:FindFirstChild("KW_LeftLiftGyro") then car.PrimaryPart.KW_LeftLiftGyro:Destroy() end
                    car.PrimaryPart.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.3,0.5,1,1) end end)
            end)
        end
    end)
    local RightLiftToggle = Tabs.Cars:AddToggle("KW_RightLift", { Title="➡️ ترفيع كفرين يمين", Default=false })
    RightLiftToggle:OnChanged(function()
        _G.KW_RightLift=Options.KW_RightLift.Value
        if _G.KW_RightLift then Notify("➡️ تم","ترفيع كفرين يمين مفعل!",2)
            spawn(function()
                while _G.KW_RightLift do task.wait(0.05) pcall(function()
                    local car=GetCarModel() if car and car.PrimaryPart then
                        local gyro=car.PrimaryPart:FindFirstChild("KW_RightLiftGyro") or Instance.new("BodyGyro")
                        gyro.Name="KW_RightLiftGyro" gyro.MaxTorque=Vector3.new(0,0,500000) gyro.P=10000 gyro.D=500
                        gyro.CFrame=car.PrimaryPart.CFrame*CFrame.Angles(0,0,math.rad(-KW_LiftPower*45)) gyro.Parent=car.PrimaryPart
                        car.PrimaryPart.CustomPhysicalProperties=PhysicalProperties.new(0.3-(KW_LiftPower*0.2),0.1,0.1,1,1) end end) end
                pcall(function() local car=GetCarModel() if car and car.PrimaryPart then
                    if car.PrimaryPart:FindFirstChild("KW_RightLiftGyro") then car.PrimaryPart.KW_RightLiftGyro:Destroy() end
                    car.PrimaryPart.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.3,0.5,1,1) end end)
            end)
        end
    end)
    local WheelieToggle = Tabs.Cars:AddToggle("KW_Wheelie", { Title="🏎️ رفع نص كلاسيكي", Default=false })
    WheelieToggle:OnChanged(function()
        _G.KW_WheelieActive=Options.KW_Wheelie.Value
        if _G.KW_WheelieActive then Notify("🏎️","رفع نص مفعل!",2)
            spawn(function()
                while _G.KW_WheelieActive do task.wait(0.05) pcall(function()
                    local car=GetCarModel() local seat=GetSeat()
                    if car and car.PrimaryPart and seat then
                        car.PrimaryPart.CustomPhysicalProperties=PhysicalProperties.new(0.01,0.01,0.01,0.01,0.01)
                        local gyro=car.PrimaryPart:FindFirstChild("KW_WheelieGyro") or Instance.new("BodyGyro")
                        gyro.Name="KW_WheelieGyro" gyro.MaxTorque=Vector3.new(50000,0,0) gyro.P=10000 gyro.D=500
                        gyro.CFrame=car.PrimaryPart.CFrame*CFrame.Angles(math.rad(-45),0,0) gyro.Parent=car.PrimaryPart
                        seat.MaxSpeed=80 seat.Throttle=1
                        local vel=car.PrimaryPart:FindFirstChild("KW_WheelieVel") or Instance.new("BodyVelocity")
                        vel.Name="KW_WheelieVel" vel.MaxForce=Vector3.new(0,0,500000) vel.Velocity=car.PrimaryPart.CFrame.LookVector*50 vel.Parent=car.PrimaryPart
                    end end) end
                pcall(function() local car=GetCarModel() if car and car.PrimaryPart then
                    if car.PrimaryPart:FindFirstChild("KW_WheelieGyro") then car.PrimaryPart.KW_WheelieGyro:Destroy() end
                    if car.PrimaryPart:FindFirstChild("KW_WheelieVel")  then car.PrimaryPart.KW_WheelieVel:Destroy()  end
                    car.PrimaryPart.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.3,0.5,1,1) end end)
            end)
        end
    end)
    Tabs.Cars:AddButton({ Title="⚖️ تسوية — إعادة الوضع الطبيعي", Callback=function()
        _G.KW_LeftLift=false _G.KW_RightLift=false _G.KW_WheelieActive=false
        pcall(function() local car=GetCarModel() if car and car.PrimaryPart then
            for _,n in pairs({"KW_LeftLiftGyro","KW_RightLiftGyro","KW_WheelieGyro","KW_WheelieVel"}) do
                if car.PrimaryPart:FindFirstChild(n) then car.PrimaryPart[n]:Destroy() end end
            car.PrimaryPart.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.3,0.5,1,1)
            car.PrimaryPart.AssemblyAngularVelocity=Vector3.new(0,0,0) end end)
        Notify("⚖️ تم","تم إعادة الوضع الطبيعي للسيارة")
    end})

    -- ── FARM ──────────────────────────────────────
    Tabs.Farm:AddSection("💰 تجميع الفلوس")
    local SmartFarmToggle = Tabs.Farm:AddToggle("KW_SmartFarm", { Title="🤖 Smart Farm", Default=false })
    SmartFarmToggle:OnChanged(function()
        if Options.KW_SmartFarm.Value then StartSmartFarm()
        else SmartFarmActive=false Notify("⛔","تم إيقاف Smart Farm") end
    end)
    local AutoCollectToggle = Tabs.Farm:AddToggle("KW_AutoCollect", { Title="🎯 جمع تلقائي سريع (20م)", Default=false })
    AutoCollectToggle:OnChanged(function()
        _G.AutoCollect=Options.KW_AutoCollect.Value
        if _G.AutoCollect then
            spawn(function()
                while _G.AutoCollect do task.wait(0.1) if not HRP then continue end
                    for _,obj in pairs(workspace:GetDescendants()) do if not _G.AutoCollect then break end
                        if obj:IsA("BasePart") then local d=(HRP.Position-obj.Position).Magnitude if d<=20 then
                            local mn={"Money","Cash","Coin","Gold","Riyal","فلوس","مال","نقود","ريال","CashPart","Reward"}
                            for _,n in pairs(mn) do if obj.Name:lower():find(n:lower()) then
                                obj.CFrame=HRP.CFrame firetouchinterest(HRP,obj,0) firetouchinterest(HRP,obj,1) break end end end end end
                end
            end)
        end
    end)
    Tabs.Farm:AddButton({ Title="💰 تجميع فوري (30م)", Callback=function()
        if not HRP then return end local c=0
        for _,obj in pairs(workspace:GetDescendants()) do if obj:IsA("BasePart") then
            local d=(HRP.Position-obj.Position).Magnitude if d<=30 then
                local mn={"Money","Cash","Coin","Gold","Riyal","فلوس","مال","نقود","ريال","CashPart","Reward"}
                for _,n in pairs(mn) do if obj.Name:lower():find(n:lower()) then
                    firetouchinterest(HRP,obj,0) task.wait(0.05) firetouchinterest(HRP,obj,1) c=c+1 break end end end end end
        Notify("💰 تم","تم جمع "..c.." عنصر!")
    end})
    Tabs.Farm:AddSection("🚗 تجميع تلقائي بالسيارة")
    Tabs.Farm:AddParagraph({ Title="ملاحظة", Content="اركب أي سيارة وشغل التجميع التلقائي!" })
    local AutoFarm120 = Tabs.Farm:AddToggle("KW_AutoFarm120", { Title="🚗 سرعة 120", Default=false })
    AutoFarm120:OnChanged(function() if Options.KW_AutoFarm120.Value then StartAutoFarmDrive(120) else StopAutoFarmDrive() end end)
    local AutoFarm140 = Tabs.Farm:AddToggle("KW_AutoFarm140", { Title="🚗 سرعة 140", Default=false })
    AutoFarm140:OnChanged(function() if Options.KW_AutoFarm140.Value then StartAutoFarmDrive(140) else StopAutoFarmDrive() end end)
    local AutoFarm160 = Tabs.Farm:AddToggle("KW_AutoFarm160", { Title="🚗 سرعة 160", Default=false })
    AutoFarm160:OnChanged(function() if Options.KW_AutoFarm160.Value then StartAutoFarmDrive(160) else StopAutoFarmDrive() end end)
    local AutoFarm180 = Tabs.Farm:AddToggle("KW_AutoFarm180", { Title="🚗 سرعة 180", Default=false })
    AutoFarm180:OnChanged(function() if Options.KW_AutoFarm180.Value then StartAutoFarmDrive(180) else StopAutoFarmDrive() end end)

    -- ── COMBAT ────────────────────────────────────
    Tabs.Combat:AddSection("⚔️ أنظمة القتال")
    local AimbotToggleKW = Tabs.Combat:AddToggle("KW_Aimbot", { Title="🎯 Aimbot", Default=false })
    AimbotToggleKW:OnChanged(function()
        if Options.KW_Aimbot.Value then if not AimbotActive then ToggleAimbot() end
        else if AimbotActive then ToggleAimbot() end end
    end)
    local SilentAimToggle = Tabs.Combat:AddToggle("KW_SilentAim", { Title="🔫 Silent Aim", Default=false })
    SilentAimToggle:OnChanged(function()
        if Options.KW_SilentAim.Value then if not SilentAimActive then ToggleSilentAim() end
        else if SilentAimActive then ToggleSilentAim() end end
    end)
    Tabs.Combat:AddSection("⚙️ إعدادات Aimbot")
    Tabs.Combat:AddSlider("KW_AimbotSmooth", { Title="🎯 نعومة التصويب", Min=0.1, Max=1, Default=0.5, Rounding=1,
        Callback=function(v) AimbotSmoothness=v end })
    Tabs.Combat:AddSlider("KW_AimbotFOV", { Title="📐 مجال الرؤية FOV", Min=50, Max=500, Default=200, Rounding=0,
        Callback=function(v) AimbotFOV=v end })
    Tabs.Combat:AddDropdown("KW_AimbotPart", { Title="🎯 جزء الهدف", Values={"Head","Torso","HumanoidRootPart"}, Multi=false, Default="Head" })
    local KW_AimbotPartDrop = Options.KW_AimbotPart
    if KW_AimbotPartDrop then KW_AimbotPartDrop:OnChanged(function(v) AimbotPart=v end) end

    -- ── TELEPORT ──────────────────────────────────
    Tabs.Teleport:AddSection("📍 نظام النقل الفوري")
    Tabs.Teleport:AddButton({ Title="📍 حفظ الموقع الحالي", Callback=function()
        if not HRP then return end table.insert(SavedLocations,HRP.CFrame)
        Notify("📍 تم الحفظ","الموقع #"..#SavedLocations.." محفوظ!")
    end})
    Tabs.Teleport:AddButton({ Title="🏠 الانتقال للموقع الأخير", Callback=function()
        if #SavedLocations>0 then if HRP then HRP.CFrame=SavedLocations[#SavedLocations] Notify("🏠 تم","تم الانتقال للموقع المحفوظ!") end
        else Notify("⚠️","لا يوجد مواقع محفوظة!") end
    end})
    Tabs.Teleport:AddButton({ Title="🔄 مسح المواقع المحفوظة", Callback=function() SavedLocations={} Notify("🔄","تم مسح جميع المواقع") end})
    Tabs.Teleport:AddButton({ Title="🌍 الانتقال للسباون", Callback=function() if HRP then HRP.CFrame=CFrame.new(0,10,0) Notify("🌍 تم","تم الانتقال للسباون!") end end})
    Tabs.Teleport:AddInput("KW_TpPlayerInput", { Title="🏃 انتقال للاعب (اسم)", Placeholder="اكتب اسم اللاعب...", Callback=function(txt)
        local t=game.Players:FindFirstChild(txt) if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
            if HRP then HRP.CFrame=t.Character.HumanoidRootPart.CFrame+Vector3.new(0,3,0) Notify("🏃 تم","تم الانتقال إلى "..t.Name) end
        else Notify("⚠️","اللاعب غير موجود!") end
    end})

    -- ── TROLLING ──────────────────────────────────
    Tabs.Trolling:AddSection("😈 نظام المقالب")
    Tabs.Trolling:AddInput("KW_TrollTarget", { Title="😈 اسم اللاعب المستهدف", Placeholder="اكتب اسم اللاعب...", Callback=function(v) _G.TrollTargetName=v end })
    Tabs.Trolling:AddButton({ Title="🌪️ رمي اللاعب (Fling)",   Callback=function() if _G.TrollTargetName then FlingPlayer(_G.TrollTargetName) else Notify("⚠️","اكتب اسم اللاعب أولاً!") end end })
    Tabs.Trolling:AddButton({ Title="📍 جلب اللاعب (Bring)",    Callback=function() if _G.TrollTargetName then BringPlayer(_G.TrollTargetName) else Notify("⚠️","اكتب اسم اللاعب أولاً!") end end })
    Tabs.Trolling:AddButton({ Title="🧊 تجميد اللاعب (Freeze)", Callback=function() if _G.TrollTargetName then FreezePlayer(_G.TrollTargetName) else Notify("⚠️","اكتب اسم اللاعب أولاً!") end end })
    Tabs.Trolling:AddButton({ Title="🔓 إلغاء التجميد",          Callback=function() if _G.TrollTargetName then UnfreezePlayer(_G.TrollTargetName) else Notify("⚠️","اكتب اسم اللاعب أولاً!") end end })
    Tabs.Trolling:AddButton({ Title="🌪️ رمي جميع اللاعبين", Callback=function()
        for _,p in pairs(game.Players:GetPlayers()) do if p~=Player then FlingPlayer(p.Name) task.wait(0.2) end end Notify("🌪️","تم رمي جميع اللاعبين!")
    end})
    Tabs.Trolling:AddButton({ Title="🧊 تجميد جميع اللاعبين", Callback=function()
        for _,p in pairs(game.Players:GetPlayers()) do if p~=Player then FreezePlayer(p.Name) task.wait(0.1) end end Notify("🧊","تم تجميد جميع اللاعبين!")
    end})

    -- ── ANIMATIONS ────────────────────────────────
    Tabs.Animations:AddSection("🎭 حركات جاهزة")
    Tabs.Animations:AddButton({ Title="💃 رقص (Dance)",    Callback=function() PlayAnimation("507771019") end })
    Tabs.Animations:AddButton({ Title="😂 ضحك (Laugh)",    Callback=function() PlayAnimation("507770818") end })
    Tabs.Animations:AddButton({ Title="👋 موجة (Wave)",     Callback=function() PlayAnimation("507770239") end })
    Tabs.Animations:AddButton({ Title="👉 إشارة (Point)",   Callback=function() PlayAnimation("507770453") end })
    Tabs.Animations:AddButton({ Title="🎉 تشجيع (Cheer)",   Callback=function() PlayAnimation("507770677") end })
    Tabs.Animations:AddButton({ Title="🧟 زومبي (Zombie)",  Callback=function() PlayAnimation("507776043") end })
    Tabs.Animations:AddButton({ Title="🥷 نينجا (Ninja)",   Callback=function() PlayAnimation("507776268") end })
    Tabs.Animations:AddButton({ Title="🛑 إيقاف الحركة",    Callback=function() if CurrentAnimation then CurrentAnimation:Stop() CurrentAnimation=nil Notify("🛑","تم إيقاف الحركة") end end })
    Tabs.Animations:AddSection("🎭 Animation ID مخصص")
    Tabs.Animations:AddInput("KW_CustomAnim", { Title="🎬 Animation ID", Placeholder="اكتب رقم Animation...", Callback=function(t)
        local id=tonumber(t) if id then PlayAnimation(id) else Notify("⚠️","رقم Animation غير صحيح!") end
    end})

    -- ── VISUAL ────────────────────────────────────
    Tabs.Visual:AddSection("👁️ البصريات")
    local ESPKW = Tabs.Visual:AddToggle("KW_ESP", { Title="👁️ ESP V2 (كشف مع معلومات)", Default=false })
    ESPKW:OnChanged(function()
        if Options.KW_ESP.Value then if not ESPActive then ToggleESP() end
        else if ESPActive then ToggleESP() end end
    end)
    Tabs.Visual:AddButton({ Title="☀️ Full Bright", Callback=function() FullBright() end })
    Tabs.Visual:AddButton({ Title="🌫️ إزالة الضباب", Callback=function() game:GetService("Lighting").FogEnd=100000 Notify("🌫️ تم","تم إزالة الضباب!") end })
    Tabs.Visual:AddSlider("KW_Brightness", { Title="🔆 سطوع العالم", Min=0, Max=20, Default=10, Rounding=1,
        Callback=function(v) game:GetService("Lighting").Brightness=v end })
    local NightModeToggle = Tabs.Visual:AddToggle("KW_NightMode", { Title="🌙 وضع الليل الدائم", Default=false })
    NightModeToggle:OnChanged(function()
        if Options.KW_NightMode.Value then game:GetService("Lighting").ClockTime=0 Notify("🌙","وضع الليل الدائم نشط")
        else game:GetService("Lighting").ClockTime=14 Notify("☀️","وضع النهار") end
    end)
    local RainbowToggle = Tabs.Visual:AddToggle("KW_Rainbow", { Title="🌈 Rainbow World", Default=false })
    RainbowToggle:OnChanged(function()
        _G.RainbowWorld=Options.KW_Rainbow.Value
        if _G.RainbowWorld then
            spawn(function() while _G.RainbowWorld do task.wait(0.1) local h=tick()%5/5
                game:GetService("Lighting").Ambient=Color3.fromHSV(h,1,1)
                game:GetService("Lighting").OutdoorAmbient=Color3.fromHSV(h,1,1) end end)
            Notify("🌈","Rainbow World نشط!")
        else game:GetService("Lighting").Ambient=Color3.fromRGB(128,128,128) game:GetService("Lighting").OutdoorAmbient=Color3.fromRGB(128,128,128) end
    end)

    -- ── SERVER ────────────────────────────────────
    Tabs.Server:AddSection("🌐 إدارة السيرفر")
    Tabs.Server:AddButton({ Title="🌐 الانتقال لسيرفر عشوائي", Description="Server Hop", Callback=function() ServerHop() end })
    Tabs.Server:AddButton({ Title="🔄 إعادة الاتصال", Callback=function()
        Notify("🔄","جاري إعادة الاتصال...")
        game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
    end})
    Tabs.Server:AddButton({ Title="📋 نسخ معرف السيرفر", Callback=function()
        setclipboard(game.JobId) Notify("📋","تم نسخ معرف السيرفر!")
    end})
    Tabs.Server:AddButton({ Title="📊 معلومات السيرفر", Callback=function()
        local pl=#game.Players:GetPlayers() local mx=game.Players.MaxPlayers
        Notify("🌐 معلومات","اللاعبين: "..pl.."/"..mx.."\nServer ID: "..game.JobId:sub(1,10).."...",5)
    end})
    Tabs.Server:AddSection("👥 قائمة اللاعبين")
    Tabs.Server:AddButton({ Title="📋 عرض قائمة اللاعبين", Callback=function()
        local list="" for _,p in pairs(game.Players:GetPlayers()) do list=list.."• "..p.Name.."\n" end
        Notify("👥 اللاعبين ("..#game.Players:GetPlayers()..")",list,8)
    end})

    -- ── MISC ──────────────────────────────────────
    Tabs.Misc:AddSection("⚙️ أدوات متقدمة")
    Tabs.Misc:AddButton({ Title="🛡️ Anti Ban", Description="حماية من الطرد", Callback=function()
        if not _getrawmetatable then
            Notify("⚠️","هذا executor لا يدعم Anti Ban") return
        end
        local mt = _getrawmetatable(game)
        pcall(_setreadonly, mt, false)
        local old = mt.__namecall
        mt.__namecall = _newcclosure(function(self,...)
            local m = getnamecallmethod()
            if m == "Kick" then Notify("🛡️ Anti Ban","تم منع محاولة طرد!",5) return nil end
            return old(self,...)
        end)
        Notify("🛡️ Anti Ban","حماية النظام نشطة!")
    end})
    Tabs.Misc:AddButton({ Title="🎲 تكبير اللاعب", Callback=function()
        if not Character then return end
        for _,p in pairs(Character:GetDescendants()) do if p:IsA("BasePart") then p.Size=p.Size*1.5 end end
        Notify("🎲 تم","تم تكبير اللاعب!")
    end})
    Tabs.Misc:AddButton({ Title="🔍 تصغير اللاعب", Callback=function()
        if not Character then return end
        for _,p in pairs(Character:GetDescendants()) do if p:IsA("BasePart") then p.Size=p.Size*0.5 end end
        Notify("🔍 تم","تم تصغير اللاعب!")
    end})
    local SpeedHackToggle = Tabs.Misc:AddToggle("KW_SpeedHack", { Title="⚡ Speed Hack (Shift للسرعة)", Default=false })
    SpeedHackToggle:OnChanged(function()
        SpeedHackActive=Options.KW_SpeedHack.Value
        if SpeedHackActive then
            Notify("⚡ Speed Hack","مفعل! اضغط Shift للسرعة الفائقة")
            SpeedHackConn=RunService.Heartbeat:Connect(function()
                if not SpeedHackActive then return end if not HRP then return end
                local uis=UserInputService
                if uis:IsKeyDown(Enum.KeyCode.LeftShift) then
                    local mv=Vector3.new(0,0,0) local cam=workspace.CurrentCamera
                    if uis:IsKeyDown(Enum.KeyCode.W) then mv=mv+cam.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.S) then mv=mv-cam.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.A) then mv=mv-cam.CFrame.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.D) then mv=mv+cam.CFrame.RightVector end
                    if mv.Magnitude>0 then HRP.Velocity=Vector3.new(mv.Unit.X*200,HRP.Velocity.Y,mv.Unit.Z*200) end
                end
            end)
        else if SpeedHackConn then SpeedHackConn:Disconnect() end Notify("⚡","Speed Hack معطل") end
    end)
    local AntiFlingToggle = Tabs.Misc:AddToggle("KW_AntiFling", { Title="🛡️ Anti Fling", Default=false })
    AntiFlingToggle:OnChanged(function()
        AntiFlingActive=Options.KW_AntiFling.Value
        if AntiFlingActive then
            Notify("🛡️ Anti Fling","محمي من الرمي!")
            AntiFlingConn=RunService.Heartbeat:Connect(function()
                if not AntiFlingActive then return end if not HRP then return end
                if HRP.Velocity.Magnitude>500 then HRP.Velocity=Vector3.new(0,0,0) HRP.RotVelocity=Vector3.new(0,0,0) end
            end)
        else if AntiFlingConn then AntiFlingConn:Disconnect() end Notify("🛡️","Anti Fling معطل") end
    end)
    local InfStaminaToggle = Tabs.Misc:AddToggle("KW_InfStamina", { Title="⚡ Infinite Stamina", Default=false })
    InfStaminaToggle:OnChanged(function()
        InfStaminaActive=Options.KW_InfStamina.Value
        if InfStaminaActive then
            Notify("⚡ Infinite Stamina","لا تتعب أبداً!")
            spawn(function() while InfStaminaActive do task.wait(0.1) if Humanoid then
                pcall(function() if Humanoid:FindFirstChild("Stamina") then Humanoid.Stamina.Value=100 end end) end end end)
        else Notify("⚡","Infinite Stamina معطل") end
    end)
    local ChatSpyToggle = Tabs.Misc:AddToggle("KW_ChatSpy", { Title="👁️ Chat Spy", Default=false })
    ChatSpyToggle:OnChanged(function()
        ChatSpyActive=Options.KW_ChatSpy.Value
        if ChatSpyActive then
            Notify("👁️ Chat Spy","تراقب كل الرسائل!")
            for _,p in pairs(game.Players:GetPlayers()) do
                p.Chatted:Connect(function(msg) if ChatSpyActive and p~=Player then Notify("💬 "..p.Name,msg,3) end end)
            end
            game.Players.PlayerAdded:Connect(function(p)
                p.Chatted:Connect(function(msg) if ChatSpyActive and p~=Player then Notify("💬 "..p.Name,msg,3) end end)
            end)
        else Notify("👁️","Chat Spy معطل") end
    end)
    Tabs.Misc:AddButton({ Title="📊 إحصائيات اللاعب", Callback=function()
        local s="السرعة: "..(Humanoid and Humanoid.WalkSpeed or "N/A")..
                "\nالصحة: "..(Humanoid and math.floor(Humanoid.Health) or "N/A")..
                "\nالموقع: "..(HRP and tostring(math.floor(HRP.Position.X))..", "..tostring(math.floor(HRP.Position.Z)) or "N/A")
        Notify("📊 إحصائيات",s,5)
    end})
    Tabs.Misc:AddSection("📋 سكربتات خارجية")
    Tabs.Misc:AddButton({ Title="♾️ Load Infinite-Yield", Callback=function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end})
    Tabs.Misc:AddButton({ Title="🔍 Load RemoteSpy", Callback=function()
        loadstring(game:HttpGetAsync("https://github.com/richie0866/remote-spy/releases/latest/download/RemoteSpy.lua"))()
    end})
    Tabs.Misc:AddSection("⚙️ تنظيف")
    Tabs.Misc:AddButton({ Title="🧹 تنظيف جميع الأنظمة", Callback=function()
        FlyActive=false NoclipActive=false DriftFarmActive=false SmartFarmActive=false
        GodModeActive=false AutoHealActive=false AutoFarmDriveActive=false
        AimbotActive=false SilentAimActive=false SpeedHackActive=false
        AntiFlingActive=false InfStaminaActive=false ChatSpyActive=false
        _G.AutoCollect=false _G.Turbo=false _G.AutoSteer=false _G.RainbowWorld=false
        if FlyConn then FlyConn:Disconnect() end
        if NoclipConn then NoclipConn:Disconnect() end
        if AutoFarmConn then AutoFarmConn:Disconnect() end
        if AimbotConn then AimbotConn:Disconnect() end
        if SpeedHackConn then SpeedHackConn:Disconnect() end
        if AntiFlingConn then AntiFlingConn:Disconnect() end
        Notify("🧹 تم","تم تنظيف جميع الأنظمة")
    end})
    Tabs.Misc:AddButton({ Title="❌ إغلاق السكربت", Callback=function()
        FlyActive=false NoclipActive=false DriftFarmActive=false SmartFarmActive=false
        GodModeActive=false AutoHealActive=false AutoFarmDriveActive=false
        AimbotActive=false SilentAimActive=false SpeedHackActive=false
        AntiFlingActive=false InfStaminaActive=false ChatSpyActive=false
        _G.AutoCollect=false _G.Turbo=false _G.AutoSteer=false _G.RainbowWorld=false
        if FlyConn then FlyConn:Disconnect() end
        if NoclipConn then NoclipConn:Disconnect() end
        if AutoFarmConn then AutoFarmConn:Disconnect() end
        if AimbotConn then AimbotConn:Disconnect() end
        if SpeedHackConn then SpeedHackConn:Disconnect() end
        if AntiFlingConn then AntiFlingConn:Disconnect() end
        _getgenv().bosqr_loaded = nil
        pcall(function() Window:Destroy() end)
    end})

    -- Welcome
    -- ── CONFIG ────────────────────────────────────
    Tabs.Config:AddSection("🎨 " .. L("config_theme"))
    local _themeMapKW = {
        Rose={Accent=Color3.fromRGB(255,80,160),Dark=Color3.fromRGB(20,10,18)},
        Amethyst={Accent=Color3.fromRGB(170,80,255),Dark=Color3.fromRGB(18,10,30)},
        Aqua={Accent=Color3.fromRGB(0,200,220),Dark=Color3.fromRGB(10,20,25)},
        Green={Accent=Color3.fromRGB(0,200,80),Dark=Color3.fromRGB(10,20,12)},
        Orange={Accent=Color3.fromRGB(255,140,0),Dark=Color3.fromRGB(22,14,8)},
        Red={Accent=Color3.fromRGB(255,50,50),Dark=Color3.fromRGB(22,8,8)},
        Blue={Accent=Color3.fromRGB(50,130,255),Dark=Color3.fromRGB(8,12,24)},
        Dark={Accent=Color3.fromRGB(120,120,140),Dark=Color3.fromRGB(15,15,20)},
        Darker={Accent=Color3.fromRGB(80,80,100),Dark=Color3.fromRGB(10,10,14)},
    }
    local function applyThemeKW(v)
        local t = _themeMapKW[v]
        if not t then return end
        _G.BoSqr_Theme = v
        task.spawn(function()
            pcall(function()
                local function recolorKW(obj)
                    if obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("CanvasGroup") then
                        local c=obj.BackgroundColor3
                        local r,g,b=c.R*255,c.G*255,c.B*255
                        if r<55 and g<55 and b<65 and obj.BackgroundTransparency<0.9 then
                            obj.BackgroundColor3=t.Dark
                        end
                        if r>100 and b>100 and g<100 then
                            obj.BackgroundColor3=t.Accent
                        end
                    end
                    if obj:IsA("TextButton") and obj.BackgroundTransparency<0.9 then
                        local c=obj.BackgroundColor3
                        local r,g,b=c.R*255,c.G*255,c.B*255
                        if r<55 and g<55 and b<65 then obj.BackgroundColor3=t.Dark end
                    end
                    if obj:IsA("UIStroke") then obj.Color=t.Accent end
                    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                        local c=obj.ImageColor3
                        local r,g,b=c.R*255,c.G*255,c.B*255
                        if not(r>250 and g>250 and b>250) then obj.ImageColor3=t.Accent end
                    end
                    for _,ch in pairs(obj:GetChildren()) do recolorKW(ch) end
                end
                local cg=game:GetService("CoreGui")
                for _,ch in pairs(cg:GetChildren()) do pcall(recolorKW,ch) end
                local pg=Player:FindFirstChild("PlayerGui")
                if pg then for _,ch in pairs(pg:GetChildren()) do pcall(recolorKW,ch) end end
            end)
            Notify("🎨",v.." ✅")
        end)
    end
    if _G.BoSqr_Theme then
        task.delay(1, function()
            pcall(function() applyThemeKW(_G.BoSqr_Theme) end)
        end)
    end
    local KW_ThemeDrop = Tabs.Config:AddDropdown("KW_ThemeDrop", {
        Title = L("config_theme"),
        Values = {"Rose","Amethyst","Aqua","Green","Orange","Red","Blue","Dark","Darker"},
        Multi = false, Default = _G.BoSqr_Theme or "Rose"
    })
    KW_ThemeDrop:OnChanged(function(v) applyThemeKW(v) end)
    -- Setup SaveManager for KW
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        SaveManager:IgnoreFields({"KW_ThemeDrop"})
        SaveManager:SetFolder("BoSqr_KW")
        InterfaceManager:SetLibrary(Fluent)
        InterfaceManager:SetFolder("BoSqr_KW")
    end)

    Tabs.Config:AddButton({
        Title = "💾 " .. L("config_save"),
        Callback = function()
            pcall(function() SaveManager:Save() end)
            Notify("💾", L("save_done"))
        end
    })
    Tabs.Config:AddButton({
        Title = "📂 " .. L("config_load"),
        Callback = function()
            pcall(function() SaveManager:Load() end)
            Notify("📂", L("load_done"))
        end
    })
    Tabs.Config:AddButton({
        Title = "🔄 " .. L("config_reset"),
        Description = Lang=="AR" and "حذف الإعدادات المحفوظة" or "Delete saved config",
        Callback = function()
            pcall(function()
                local path = "BoSqr_KW/config.json"
                if _isfolder("BoSqr_KW") then
                    if _isfile(path) then _delfile(path) end
                end
            end)
            Notify("🔄", L("reset_done"))
        end
    })
    Tabs.Config:AddSection("⚙️")
    Tabs.Config:AddButton({
        Title = "❌ " .. L("close_script"),
        Callback = function()
            FlyActive=false NoclipActive=false DriftFarmActive=false SmartFarmActive=false
            GodModeActive=false AutoHealActive=false AutoFarmDriveActive=false
            AimbotActive=false SilentAimActive=false SpeedHackActive=false
            AntiFlingActive=false InfStaminaActive=false ChatSpyActive=false
            _G.AutoCollect=false _G.Turbo=false _G.AutoSteer=false _G.RainbowWorld=false
            if FlyConn then FlyConn:Disconnect() end
            if NoclipConn then NoclipConn:Disconnect() end
            if AutoFarmConn then AutoFarmConn:Disconnect() end
            if AimbotConn then AimbotConn:Disconnect() end
            if SpeedHackConn then SpeedHackConn:Disconnect() end
            if AntiFlingConn then AntiFlingConn:Disconnect() end
            -- Allow re-execution
            _getgenv().bosqr_loaded = nil
            pcall(function() Window:Destroy() end)
        end
    })

    task.wait(1)
    Notify("🎉 Bo.Sqr | " .. (Lang=="AR" and "عالم المملكة" or "Kingdom World"), L("welcome_kw"), 10)
    print("✅ Bo.Sqr | Kingdom World ULTIMATE - تم التحميل | Discord: Riveteam")

else
    -- ماب غير معروف
    warn("⚠️ Bo.Sqr | هذا السكربت مخصص لـ MM2 أو عالم المملكة فقط!")
    warn("PlaceId الحالي: " .. tostring(currentMapID))
end

-- ══════════════════════════════════════════════
-- Select First Tab
-- ══════════════════════════════════════════════
Window:SelectTab(1)
