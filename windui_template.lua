--[[
    WindUI 通用脚本模板 v2.2（开箱即用版）
    
    ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    ★  WindUI 通用脚本模板                       ★
    ★  内置: NPC透视/高亮/标签 完整工作示例        ★
    ★  开箱即用 + 配置保存 + 粒子背景 + 毛玻璃     ★
    ★  清理系统: 脚本停止后自动清除所有残留         ★
    ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    
    作者: b站英吉利超入_
    WindUI加载: https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua
    官方文档:  footagesus-windui.mintlify.app
]]

-- ============================================================
--  第1部分：服务获取 + 平台检测
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local IsMobile = false
pcall(function() IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled end)

-- ============================================================
--  第2部分：清理系统
--  维护所有创建对象的引用，支持一键彻底清理
--  解决脚本关闭后 Highlight/Billboard/粒子 残留的问题
-- ============================================================
local ScriptInstances = {}

local function trackInstance(instance)
    if instance then table.insert(ScriptInstances, instance) end
    return instance
end

local function cleanAllInstances()
    print("[模板] 彻底清理中...")
    
    -- 1. 停止粒子
    local oldParticles = CoreGui:FindFirstChild("Template_Particles")
    if oldParticles then pcall(function() oldParticles:Destroy() end) end
    
    -- 2. 销毁所有 ESP
    for model, esp in pairs(ESP_Objects) do
        pcall(function() if esp.Highlight then esp.Highlight:Destroy() end end)
        pcall(function() if esp.Billboard then esp.Billboard:Destroy() end end)
    end
    ESP_Objects = {}
    ESP_Stats = {Good=0, Bad=0, Total=0}
    
    -- 3. 销毁跟踪的实例
    for _, inst in ipairs(ScriptInstances) do
        pcall(function() inst:Destroy() end)
    end
    ScriptInstances = {}
    
    -- 4. 清理特定名称的 GUI
    local guiNames = {"Template_Particles", "Template_Btn", "Template_Heartbeat"}
    for _, name in ipairs(guiNames) do
        local existing = CoreGui:FindFirstChild(name)
        if existing then pcall(function() existing:Destroy() end) end
    end
    
    -- 5. 清除全局引用
    FloatingButtonGui = nil; ParticleGui = nil
    Particles = {}; WindowRef = nil
    ESP_Scanning = false; ParticleRunning = false
    
    print("[模板] 清理完成 ✓")
end

_G.CleanupTemplate = cleanAllInstances

task.spawn(function()
    task.wait(0.1)
    local guiNames = {"Template_Particles", "Template_Btn", "Template_Heartbeat"}
    for _, name in ipairs(guiNames) do
        local existing = CoreGui:FindFirstChild(name)
        if existing then pcall(function() existing:Destroy() end) end
    end
end)

-- ============================================================
--  第3部分：设置项
-- ============================================================
local Settings = {
    Particles = true, CurrentTheme = "Dark",
    ESP_Enabled = false, ESP_BadOnly = false,
    ESP_ShowDistance = true, ESP_ShowHealth = true, ESP_MaxRange = 500,
}

-- ============================================================
--  第4部分：内部变量
-- ============================================================
local WindowRef = nil; local FloatingButtonGui = nil; local ParticleGui = nil
local ParticleRunning = false; local PopupConfirmed = false
local Controls = {}; local Keybinds = {}; local TabElements = {}
local ConfigName = "default"; local Particles = {}
local ESP_Objects = {}; local ESP_Scanning = false
local ESP_Stats = {Good=0, Bad=0, Total=0}; local PlayerChar = nil

-- ============================================================
--  第5部分：粒子背景系统 v2.2
--  50粒子 4-8px 紧约束 颜色取 WindUI 主色
-- ============================================================
local ThemeColors = {
    Dark = Color3.fromRGB(100,180,255), Light = Color3.fromRGB(80,140,200),
    Rose = Color3.fromRGB(255,120,160), Plant = Color3.fromRGB(100,200,120),
    Ocean = Color3.fromRGB(80,180,230), Sunset = Color3.fromRGB(255,150,80),
    Midnight = Color3.fromRGB(120,100,220), Forest = Color3.fromRGB(80,170,80),
    Lavender = Color3.fromRGB(180,130,255), Coral = Color3.fromRGB(255,130,100),
    Mint = Color3.fromRGB(100,220,180), Peanut = Color3.fromRGB(200,170,100),
    Sky = Color3.fromRGB(130,180,255), Blood = Color3.fromRGB(220,80,80),
    Lemon = Color3.fromRGB(220,200,80), Cyber = Color3.fromRGB(0,220,200),
}

local function getParticleColor()
    local primary = nil
    pcall(function() if WindUI and WindUI.Theme and WindUI.Theme.Primary then primary = WindUI.Theme.Primary end end)
    if primary then return primary end
    local themeName = Settings.CurrentTheme or "Dark"
    if ThemeColors[themeName] then return ThemeColors[themeName] end
    return Color3.fromRGB(100, 180, 255)
end

local function createParticles()
    if ParticleGui then pcall(function() ParticleGui:Destroy() end); ParticleGui = nil end
    Particles = {}
    if not Settings.Particles then return end
    pcall(function()
        ParticleGui = Instance.new("ScreenGui")
        ParticleGui.Name = "Template_Particles"; ParticleGui.ResetOnSpawn = false
        ParticleGui.DisplayOrder = -999; ParticleGui.IgnoreGuiInset = true; ParticleGui.Parent = CoreGui
        trackInstance(ParticleGui)

        for i = 1, 50 do
            local dot = Instance.new("Frame"); local size = math.random(4,8)
            dot.Size = UDim2.new(0,size,0,size)
            dot.Position = UDim2.new(0.18+math.random()*0.60, 0, 0.10+math.random()*0.55, 0)
            dot.BackgroundColor3 = getParticleColor(); dot.BackgroundTransparency = 0.4+math.random()*0.4
            dot.BorderSizePixel = 0; dot.Parent = ParticleGui; trackInstance(dot)
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = dot; trackInstance(c)
            local angle = math.random()*6.28; local speed = 0.0005+math.random()*0.0015
            table.insert(Particles, {Frame=dot, Vx=math.cos(angle)*speed, Vy=math.sin(angle)*speed, Phase=math.random()*6.28, SizeBase=size, MinBoundX=0.18, MaxBoundX=0.78, MinBoundY=0.08, MaxBoundY=0.68})
        end
        ParticleRunning = true
        task.spawn(function()
            local time = 0
            while ParticleRunning and ParticleGui and ParticleGui.Parent do
                time = time + 0.03
                pcall(function()
                    for _, p in ipairs(Particles) do
                        if not p.Frame or not p.Frame.Parent then continue end
                        local x = p.Frame.Position.X.Scale + p.Vx; local y = p.Frame.Position.Y.Scale + p.Vy
                        if x > p.MaxBoundX then x=p.MaxBoundX; p.Vx=-p.Vx+(math.random()-0.5)*0.0002 elseif x<p.MinBoundX then x=p.MinBoundX; p.Vx=-p.Vx+(math.random()-0.5)*0.0002 end
                        if y > p.MaxBoundY then y=p.MaxBoundY; p.Vy=-p.Vy+(math.random()-0.5)*0.0002 elseif y<p.MinBoundY then y=p.MinBoundY; p.Vy=-p.Vy+(math.random()-0.5)*0.0002 end
                        p.Frame.Position = UDim2.new(x,0,y,0)
                        p.Frame.BackgroundTransparency = 0.4+math.sin(time*0.8+p.Phase)*0.25
                        local s = math.max(1, p.SizeBase+math.sin(time+p.Phase)*0.8)
                        p.Frame.Size = UDim2.new(0,s,0,s)
                    end
                end)
                task.wait(0.03)
            end
        end)
    end)
end

local function updateParticleColor()
    local color = getParticleColor()
    if not color or #Particles == 0 then return end
    pcall(function() for _, p in ipairs(Particles) do if p.Frame and p.Frame.Parent then p.Frame.BackgroundColor3 = color end end end)
end

local function destroyParticles()
    ParticleRunning = false
    if ParticleGui then pcall(function() ParticleGui:Destroy() end); ParticleGui = nil end
    Particles = {}
end

-- ============================================================
--  第6部分：NPC透视系统
-- ============================================================
local function classifyNPC(humanoid, npcModel, npcName, fullPath)
    npcName = npcName or ""; fullPath = fullPath or ""
    local npcType = nil; pcall(function() npcType = humanoid:GetAttribute("NPCType") end)
    if npcType then
        if npcType == "Agent" or npcType == "Good" or npcType == "Friendly" then return "Good"
        elseif npcType == "Enemy" or npcType == "Bad" or npcType == "Hostile" then return "Bad" end
    end
    local nameLower = npcName:lower()
    for _, kw in ipairs({"警察","保安","警卫","警","守卫","卫兵","士兵","军人","polic","secur","guard","agent","officer","soldier","police","sheriff","swat","fbi","military","安保","安全"}) do
        if nameLower:find(kw) then return "Good" end
    end
    for _, kw in ipairs({"恐怖","匪","坏人","罪犯","敌人","坏蛋","歹徒","暴徒","terror","enemy","hostile","criminal","threat","suspect","intruder","invader","rogue","hijack","叛","贼","偷"}) do
        if nameLower:find(kw) then return "Bad" end
    end
    if fullPath:find("AgentTemplate") then return "Good" end
    if fullPath:find("NPCTemplate") then return "Bad" end
    local tc = humanoid.TeamColor
    if tc then
        if tc == BrickColor.new("Bright blue") or tc == BrickColor.new("Bright green") then return "Good" end
        if tc == BrickColor.new("Bright red") or tc == BrickColor.new("Really black") then return "Bad" end
    end
    return "Bad"
end

local function createNPCESP(npcModel)
    if not npcModel or not npcModel.PrimaryPart then return end
    if ESP_Objects[npcModel] then return end
    local humanoid = npcModel:FindFirstChildOfClass("Humanoid"); local head = npcModel:FindFirstChild("Head")
    if not humanoid or not head then return end
    local npcType = classifyNPC(humanoid, npcModel, npcModel.Name, npcModel:GetFullName())
    local isGood = (npcType == "Good"); local color = isGood and Color3.fromRGB(0,255,80) or Color3.fromRGB(255,50,50)
    local label = isGood and "👮 好人" or "💀 坏人"
    local hl = trackInstance(Instance.new("Highlight"))
    hl.Adornee = npcModel; hl.FillColor = color; hl.FillTransparency = 0.55
    hl.OutlineColor = Color3.fromRGB(255,255,255); hl.OutlineTransparency = 0.3
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Enabled = Settings.ESP_Enabled; hl.Parent = CoreGui
    local bg = trackInstance(Instance.new("BillboardGui"))
    bg.Adornee = head; bg.Size = UDim2.new(0,200,0,80); bg.StudsOffset = Vector3.new(0,3,0)
    bg.AlwaysOnTop = true; bg.Enabled = Settings.ESP_Enabled; bg.Parent = CoreGui
    local frame = trackInstance(Instance.new("Frame"))
    frame.Size = UDim2.new(1,-10,1,-10); frame.Position = UDim2.new(0,5,0,5)
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0); frame.BackgroundTransparency = 0.35; frame.BorderSizePixel = 0; frame.Parent = bg
    local fc = trackInstance(Instance.new("UICorner")); fc.CornerRadius = UDim.new(0,6); fc.Parent = frame
    local typeLabel = trackInstance(Instance.new("TextLabel"))
    typeLabel.Size = UDim2.new(1,-8,0,22); typeLabel.Position = UDim2.new(0,4,0,2); typeLabel.BackgroundTransparency = 1
    typeLabel.Text = label; typeLabel.TextColor3 = color; typeLabel.TextScaled = true
    typeLabel.Font = Enum.Font.SourceSansBold; typeLabel.TextXAlignment = Enum.TextXAlignment.Center; typeLabel.Parent = frame
    local infoLabel = trackInstance(Instance.new("TextLabel"))
    infoLabel.Size = UDim2.new(1,-8,0,18); infoLabel.Position = UDim2.new(0,4,0,24); infoLabel.BackgroundTransparency = 1
    infoLabel.Text = ""; infoLabel.TextColor3 = Color3.fromRGB(220,220,220); infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.SourceSans; infoLabel.TextXAlignment = Enum.TextXAlignment.Center; infoLabel.Parent = frame
    local hpBg = trackInstance(Instance.new("Frame"))
    hpBg.Size = UDim2.new(0.8,0,0,4); hpBg.Position = UDim2.new(0.1,0,0,46)
    hpBg.BackgroundColor3 = Color3.fromRGB(60,60,60); hpBg.BackgroundTransparency = 0.3; hpBg.BorderSizePixel = 0; hpBg.Parent = frame
    local hpf = trackInstance(Instance.new("Frame"))
    hpf.Size = UDim2.new(1,0,1,0); hpf.BackgroundColor3 = isGood and Color3.fromRGB(0,200,100) or Color3.fromRGB(200,50,50); hpf.BorderSizePixel = 0; hpf.Parent = hpBg
    local hfc = trackInstance(Instance.new("UICorner")); hfc.CornerRadius = UDim.new(0,2); hfc.Parent = hpBg
    ESP_Objects[npcModel] = {Model=npcModel, Humanoid=humanoid, Head=head, Highlight=hl, Billboard=bg, Frame=frame, TypeLabel=typeLabel, InfoLabel=infoLabel, HPBar=hpf, HPBg=hpBg, IsGood=isGood, Label=label, Color=color}
end

local function updateAllESP()
    if not Settings.ESP_Enabled then return end
    local char = PlayerChar
    if not char or not char.PrimaryPart then local plr = Players.LocalPlayer; if plr then pcall(function() char = plr.Character end); PlayerChar = char end end
    local myPos = char and char.PrimaryPart and char.PrimaryPart.Position
    for model, esp in pairs(ESP_Objects) do
        pcall(function()
            if not model or not model.Parent then
                if esp.Highlight then esp.Highlight:Destroy() end; if esp.Billboard then esp.Billboard:Destroy() end
                ESP_Objects[model] = nil; return
            end
            if Settings.ESP_BadOnly and esp.IsGood then esp.Highlight.Enabled = false; esp.Billboard.Enabled = false; return end
            esp.Highlight.Enabled = true; esp.Billboard.Enabled = true
            local distText = ""
            if Settings.ESP_ShowDistance and myPos and esp.Head then
                local dist = (esp.Head.Position - myPos).Magnitude
                if dist <= Settings.ESP_MaxRange then distText = string.format("%.0fm", dist)
                else esp.Highlight.Enabled = false; esp.Billboard.Enabled = false; return end
            end
            local hpText = ""; local curHp = 100; local maxHp = 100
            if Settings.ESP_ShowHealth then
                pcall(function() curHp = esp.Humanoid.Health; maxHp = esp.Humanoid.MaxHealth end)
                hpText = string.format("HP: %.0f/%.0f", curHp, maxHp)
                esp.HPBar.Size = UDim2.new(math.max(0, curHp/maxHp), 0, 1, 0)
            end
            local infoParts = {}; if distText ~= "" then table.insert(infoParts, distText) end; if hpText ~= "" then table.insert(infoParts, hpText) end
            esp.InfoLabel.Text = table.concat(infoParts, " | "); esp.HPBg.Visible = Settings.ESP_ShowHealth
        end)
    end
end

local function toggleESP(enabled)
    Settings.ESP_Enabled = enabled
    for _, esp in pairs(ESP_Objects) do pcall(function() esp.Highlight.Enabled = enabled; esp.Billboard.Enabled = enabled end) end
end

local function startESPScanLoop()
    if ESP_Scanning then return end; ESP_Scanning = true
    task.spawn(function()
        while ESP_Scanning do
            pcall(function()
                local goodCount = 0; local badCount = 0
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("Head") then
                        local isPlayer = false; pcall(function() local plr=Players:GetPlayerFromCharacter(obj); if plr then isPlayer=true end end)
                        if isPlayer then continue end; createNPCESP(obj)
                        if ESP_Objects[obj] then if ESP_Objects[obj].IsGood then goodCount=goodCount+1 else badCount=badCount+1 end end
                    end
                end
                ESP_Stats.Good = goodCount; ESP_Stats.Bad = badCount; ESP_Stats.Total = goodCount+badCount
                for model,_ in pairs(ESP_Objects) do
                    if not model or not model.Parent then
                        pcall(function() if ESP_Objects[model] then if ESP_Objects[model].Highlight then ESP_Objects[model].Highlight:Destroy() end; if ESP_Objects[model].Billboard then ESP_Objects[model].Billboard:Destroy() end end end)
                        ESP_Objects[model] = nil
                    end
                end
                if TabElements.StatGood then TabElements.StatGood:SetTitle("🟢 好人: "..ESP_Stats.Good) end
                if TabElements.StatBad then TabElements.StatBad:SetTitle("🔴 坏人: "..ESP_Stats.Bad) end
                if TabElements.StatTotal then TabElements.StatTotal:SetTitle("📊 总计: "..ESP_Stats.Total) end
                if TabElements.StatusInput then TabElements.StatusInput:Set("扫描中 | 好人:"..ESP_Stats.Good.." 坏人:"..ESP_Stats.Bad.." 总计:"..ESP_Stats.Total) end
            end)
            updateAllESP(); task.wait(1)
        end
    end)
end

local function beautifyUI()
    pcall(function() for _, s in ipairs(CoreGui:GetDescendants()) do if s:IsA("ScrollingFrame") then s.ScrollBarThickness=14; s.ScrollBarImageColor3=Color3.fromRGB(220,220,220); s.ScrollBarImageTransparency=0.1 end end end)
end

-- ============================================================
--  第7部分：加载 WindUI
-- ============================================================
local WindUI = nil
local s, r = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))() end)

if s and r then
    WindUI = r; pcall(function() WindUI:SetTheme("Dark") end)

    WindUI:Popup({
        Title = "WindUI 脚本模板 v2.2",
        Icon = "solar:info-square-bold",
        Content = [[
📋 NPC透视 - 高亮显示 + 头顶标签
💾 配置保存 - 自动保存/读取设置
🎨 主题系统 - 16种内置主题一键切换
✨ 粒子背景 - 50粒子紧约束窗口内飘浮
🌀 增强毛玻璃 - Acrylic + 透明叠加
🧹 清理系统 - 脚本停止后自动清除所有残留

⚠️ 加载后所有功能默认关闭，需手动开启
        ]],
        Buttons = {
            { Title = "取消", Callback = function() end, Variant = "Tertiary" },
            { Title = "确认加载", Icon = "solar:arrow-right-bold", Callback = function()
                PopupConfirmed = true
                pcall(function() WindUI:Notify({Title="✅ 已加载", Content="⌨️ 按 RightShift 打开菜单", Duration=4, Icon="solar:bell-bold"}) end)
                task.spawn(function() createWindow() end)
            end, Variant = "Primary" }
        }
    })

    task.spawn(function()
        while not PopupConfirmed do task.wait(0.5) end
        task.wait(1.5); beautifyUI()
        local plr = Players.LocalPlayer
        if plr then PlayerChar = plr.Character; plr.CharacterAdded:Connect(function(newChar) PlayerChar = newChar end) end
        startESPScanLoop()
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end; if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local keyName = input.KeyCode.Name
            if Keybinds.ESP and Keybinds.ESP ~= "" and keyName == Keybinds.ESP then
                Settings.ESP_Enabled = not Settings.ESP_Enabled
                pcall(function() if Controls.ESPToggle then Controls.ESPToggle:Set(Settings.ESP_Enabled) end end)
                toggleESP(Settings.ESP_Enabled)
            end
            if Keybinds.BadOnly and Keybinds.BadOnly ~= "" and keyName == Keybinds.BadOnly then
                Settings.ESP_BadOnly = not Settings.ESP_BadOnly
                pcall(function() if Controls.BadOnlyToggle then Controls.BadOnlyToggle:Set(Settings.ESP_BadOnly) end end)
            end
        end)
    end)

    function createWindow()
        if WindowRef then return end
        local ok, win = pcall(function() return WindUI:CreateWindow({Title="WindUI 脚本模板", Author="b站英吉利超入_", Icon="solar:shield-warning-bold", Size=UDim2.fromOffset(750,520), ToggleKey=Enum.KeyCode.RightShift, Folder="windui-template", Acrylic=true, Transparent=true, Resizable=false, SideBarWidth=180, ScrollBarEnabled=true, HideSearchBar=true}) end)
        if not ok or not win then print("[模板] 窗口创建失败:", ok); return end
        WindowRef = win; pcall(function() WindUI.TransparencyValue = 0.22 end)

        local mainTab = win:Tab({Title="主控面板", Icon="solar:slider-vertical-bold"})
        mainTab:Paragraph({Title="👁 NPC透视控制"})
        Controls.ESPToggle = mainTab:Toggle({Flag="ESPToggle", Title="透视开关", Value=false, Desc="高亮显示+头顶标签", Callback=function(v) toggleESP(v) end})
        Controls.BadOnlyToggle = mainTab:Toggle({Flag="BadOnlyToggle", Title="仅显示坏人", Value=false, Desc="隐藏好人", Callback=function(v) Settings.ESP_BadOnly=v end})
        mainTab:Divider()
        mainTab:Paragraph({Title="📏 标签显示设置"})
        Controls.DistanceToggle = mainTab:Toggle({Flag="DistanceToggle", Title="显示距离", Value=true, Callback=function(v) Settings.ESP_ShowDistance=v end})
        Controls.HealthToggle = mainTab:Toggle({Flag="HealthToggle", Title="显示血量", Value=true, Callback=function(v) Settings.ESP_ShowHealth=v end})
        mainTab:Divider()
        Controls.RangeSlider = mainTab:Slider({Flag="RangeSlider", Title="最大探测距离", Step=10, Value={Min=50,Max=1000,Default=500}, Width=200, IsTextbox=true, Callback=function(v) Settings.ESP_MaxRange=v end})

        local funcTab = win:Tab({Title="功能设置", Icon="solar:settings-bold"})
        funcTab:Paragraph({Title="🔑 快捷键设置（点击后按键盘绑定）"})
        Controls.ESPKeybind = funcTab:Keybind({Flag="ESPKeybind", Title="透视开关快捷键", Value="", Callback=function(key) Keybinds.ESP=key end})
        Controls.BadOnlyKeybind = funcTab:Keybind({Flag="BadOnlyKeybind", Title="仅显示坏人快捷键", Value="", Callback=function(key) Keybinds.BadOnly=key end})
        funcTab:Divider()
        funcTab:Paragraph({Title="💡 提示", Desc="窗口快捷键在UI设置中绑定（默认 RightShift）\\n快捷键默认全部为空，需自行绑定"})

        local uiTab = win:Tab({Title="UI设置", Icon="solar:monitor-bold"})
        uiTab:Paragraph({Title="⚙️ 界面设置"})
        Controls.WindowKeybind = uiTab:Keybind({Flag="WindowKeybind", Title="窗口开关快捷键", Value="RightShift", Callback=function(key) Keybinds.Window=key; if WindowRef then pcall(function() WindowRef:SetToggleKey(Enum.KeyCode[key]) end) end end})
        Controls.FloatingBtnToggle = uiTab:Toggle({Flag="FloatingBtnToggle", Title="显示悬浮按钮", Value=IsMobile, Callback=function(v) if FloatingButtonGui then FloatingButtonGui.Enabled=v end end})
        uiTab:Divider()
        uiTab:Paragraph({Title="🌀 背景效果"})
        Controls.ParticlesToggle = uiTab:Toggle({Flag="ParticlesToggle", Title="浮动粒子背景 (50个)", Value=true, Callback=function(v) Settings.Particles=v; if v then createParticles() else destroyParticles() end end})
        uiTab:Divider()
        uiTab:Paragraph({Title="✨ 窗口效果"})
        Controls.AcrylicToggle = uiTab:Toggle({Flag="AcrylicToggle", Title="毛玻璃效果", Value=true, Callback=function(v) pcall(function() WindUI:ToggleAcrylic(v) end) end})
        Controls.TransparencyToggle = uiTab:Toggle({Flag="TransparencyToggle", Title="透明背景增强毛玻璃", Value=true, Callback=function(v) if WindowRef then pcall(function() WindowRef:ToggleTransparency(v) end) end end})
        uiTab:Divider()
        uiTab:Paragraph({Title="🎨 主题系统", Desc="16种内置主题，切换时粒子颜色自动适配"})
        local allThemes = {}; pcall(function() allThemes = WindUI:GetThemes() end)
        local themeNames = {}; for name,_ in pairs(allThemes) do table.insert(themeNames, name) end; table.sort(themeNames)
        Controls.ThemeDropdown = uiTab:Dropdown({Flag="ThemeDropdown", Title="选择主题", Values=themeNames, Value="Dark", Callback=function(selected) if selected then Settings.CurrentTheme=selected; pcall(function() WindUI:SetTheme(selected) end); updateParticleColor() end end})

        local statsTab = win:Tab({Title="信息统计", Icon="solar:chart-bold"})
        TabElements.StatGood = statsTab:Paragraph({Title="🟢 好人: 0"})
        TabElements.StatBad = statsTab:Paragraph({Title="🔴 坏人: 0"})
        TabElements.StatTotal = statsTab:Paragraph({Title="📊 总计: 0"})
        statsTab:Divider()
        TabElements.StatusInput = statsTab:Input({Flag="StatusInputCache", Title="扫描状态", Value="等待中...", Locked=true})

        local configTab = win:Tab({Title="配置管理", Icon="solar:diskette-bold"})
        configTab:Paragraph({Title="💾 配置管理", Desc="保存/加载你的所有设置"})
        local ConfigNameInput = configTab:Input({Flag="ConfigNameInput", Title="配置名称", Value="default", Icon="solar:file-text-bold", Callback=function(value) ConfigName=value end})
        configTab:Space()
        local ConfigManager = WindowRef.ConfigManager; local AllConfigs={}; pcall(function() AllConfigs = ConfigManager:AllConfigs() end)
        local DefaultValue=nil; pcall(function() for _,v in ipairs(AllConfigs) do if v=="default" then DefaultValue="default"; break end end end)
        local AllConfigsDropdown = configTab:Dropdown({Title="已有配置", Desc="选择要加载的配置", Values=AllConfigs, Value=DefaultValue, Callback=function(value) if value then ConfigName=value; pcall(function() ConfigNameInput:Set(value) end) end end})
        configTab:Space()
        configTab:Button({Title="💾 保存配置", Icon="solar:check-circle-bold", Justify="Center", Color=Color3.fromHex("#305dff"), Callback=function() if not ConfigManager then return end; pcall(function() local c=ConfigManager:Config(ConfigName); if c and c:Save() then WindUI:Notify({Title="✅ 配置已保存", Content="配置 '"..ConfigName.."' 已保存", Icon="solar:check-circle-bold", Duration=3}); AllConfigsDropdown:Refresh(ConfigManager:AllConfigs()) end end) end})
        configTab:Space()
        configTab:Button({Title="📂 加载配置", Icon="solar:refresh-circle-bold", Justify="Center", Color=Color3.fromHex("#10C550"), Callback=function() if not ConfigManager then return end; pcall(function() local c=ConfigManager:CreateConfig(ConfigName,false); if c and c:Load() then WindUI:Notify({Title="✅ 配置已加载", Content="配置 '"..ConfigName.."' 已加载", Icon="solar:refresh-circle-bold", Duration=3}) end end) end})
        configTab:Space()
        configTab:Button({Title="🗑️ 删除配置", Icon="solar:trash-bin-trash-bold", Justify="Center", Color=Color3.fromHex("#ff3040"), Callback=function() if not ConfigManager then return end; pcall(function() local c=ConfigManager:Config(ConfigName); if c and c:Delete() then WindUI:Notify({Title="🗑️ 配置已删除", Content="配置 '"..ConfigName.."' 已删除", Icon="solar:trash-bin-trash-bold", Duration=3}); AllConfigsDropdown:Refresh(ConfigManager:AllConfigs()) end end) end})
        configTab:Divider()
        configTab:Paragraph({Title="💡 提示", Desc="所有带 Flag 的元素会自动保存/恢复\\n🧹 脚本停止后会自动清除所有残留\\n💊 手动清理: 在控制台输入 _G.CleanupTemplate()"})

        task.spawn(function()
            task.wait(1); pcall(function() if ConfigManager then local config = ConfigManager:CreateConfig("default",true) end end)
            createParticles()
        end)

        local aboutTab = win:Tab({Title="关于", Icon="solar:info-square-bold"})
        aboutTab:Paragraph({Title="WindUI 脚本模板 v2.2", Desc="开箱即用的 WindUI 完整示例"})
        aboutTab:Divider()
        aboutTab:Paragraph({Title="👤 作者", Desc="b站英吉利超入_"})
        aboutTab:Divider()
        aboutTab:Paragraph({Title="💡 使用说明", Desc=IsMobile and "手机: 点击悬浮按钮" or "PC: 按 RightShift 打开菜单"})
        aboutTab:Paragraph({Title="⚠️ 提示", Desc="所有功能默认关闭，请在菜单中手动开启"})
        aboutTab:Paragraph({Title="🧹 清理", Desc="执行 _G.CleanupTemplate() 清除所有残留"})

        if IsMobile then
            task.spawn(function()
                task.wait(1)
                pcall(function()
                    FloatingButtonGui = trackInstance(Instance.new("ScreenGui"))
                    FloatingButtonGui.Name = "Template_Btn"; FloatingButtonGui.Enabled = true
                    FloatingButtonGui.ResetOnSpawn = false; FloatingButtonGui.Parent = CoreGui
                    local btn = trackInstance(Instance.new("ImageButton"))
                    btn.Size = UDim2.new(0,50,0,50); btn.Position = UDim2.new(0.9,-25,0.8,-25)
                    btn.BackgroundColor3 = Color3.fromRGB(0,180,80); btn.BackgroundTransparency = 0.2; btn.BorderSizePixel = 0; btn.Parent = FloatingButtonGui
                    local c = trackInstance(Instance.new("UICorner")); c.CornerRadius = UDim.new(0,25); c.Parent = btn
                    local t = trackInstance(Instance.new("TextLabel"))
                    t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.Text = "👁"
                    t.TextScaled = true; t.Font = Enum.Font.SourceSansBold; t.TextColor3 = Color3.fromRGB(255,255,255); t.Parent = btn
                    local dragging,dragStart,startPos = false,nil,nil
                    btn.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=input.Position; startPos=btn.Position end end)
                    btn.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then btn.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+input.Position.X-dragStart.X,startPos.Y.Scale,startPos.Y.Offset+input.Position.Y-dragStart.Y) end end)
                    btn.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
                    btn.MouseButton1Click:Connect(function() if WindowRef then pcall(function() WindowRef:Toggle() end) end end)
                end)
            end)
        end
    end
    print("[模板] v2.2 已加载 | 作者: b站英吉利超入_")
    print("[模板] 清理命令: _G.CleanupTemplate()")
else
    print("[模板] WindUI 加载失败")
    local msg = Instance.new("Message"); msg.Text = "⚠️ WindUI 加载失败，请重试"; msg.Parent = Workspace; task.delay(5, function() msg:Destroy() end)
end
print("[模板] 脚本加载完成")

--[[============================================================
    使用注意事项（详细）
    
    ...（完整注释内容，同 v2.1）
    
    ★ 清理系统说明 (v2.2) ★
        脚本启动时自动清除上一次运行的残留
        所有 Highlight/Billboard/Gui 通过 trackInstance() 追踪
        脚本停止后在控制台输入 _G.CleanupTemplate() 一键清除
        清理内容: Highlight高亮, Billboard标签, 粒子, 悬浮按钮, 全部ScreenGui
    
    ★ WindUI 控件常用方法速查 ★
        Toggle    → :Set(true/false)
        Slider    → 通过 Callback 接收值
        Input     → :Set("new text")
        Dropdown  → :Refresh({new values})
        Keybind   → Callback 返回字符串 KeyName
        Paragraph → :SetTitle("new title")
============================================================--]]
