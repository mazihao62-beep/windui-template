--[[
    WindUI 通用脚本模板 v3.0（开箱即用版）
    
    v3.0 三大Bug修复（质量第一）:
    1. 粒子颜色适配主题 - 切换主题时直接存储Color3，绕过不稳定API
    2. 紧约束X:0.28~0.58 Y:0.18~0.50 - 粒子在窗口区域内飘浮，速度减半
    3. 脚本Tag清理 - 所有实例标记_ScriptTag="TemplateESP"，启动时全量扫描清除残留
    
    作者: b站英吉利超入_
    WindUI加载: https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua
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
--  第2部分：脚本Tag清理系统（v3.0核心改进）
--  每个创建的实例标记 _ScriptTag = "TemplateESP"
--  启动时扫描CoreGui所有带此Tag的实例→摧毁
--  即使脚本意外中断，重启也能清除所有残留
-- ============================================================
local TAG_NAME = "TemplateESP"

local function tagTrack(instance)
    if not instance then return nil end
    pcall(function() instance:SetAttribute(TAG_NAME, true) end)
    return instance
end

task.spawn(function()
    task.wait(0.1)
    local count = 0
    pcall(function()
        for _, inst in ipairs(CoreGui:GetDescendants()) do
            local s, attr = pcall(function() return inst:GetAttribute(TAG_NAME) end)
            if s and attr then pcall(function() inst:Destroy() end); count = count + 1 end
        end
    end)
    if count > 0 then print("[清理] 已清除 " .. count .. " 个旧实例") end
end)

-- ============================================================
--  第3部分：设置项
-- ============================================================
local Settings = {
    Particles = true, CurrentTheme = "Dark",
    ParticleColor = Color3.fromRGB(100, 180, 255), -- v3.0: 存实际Color3
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
--  第5部分：粒子背景系统 v3.0
--  改进:
--    1. 颜色: 切换主题时直接存Color3到Settings.ParticleColor
--            getParticleColor()只读Settings.ParticleColor
--    2. 紧约束: X:0.28~0.58 Y:0.18~0.50
--    3. 速度减半: 0.0002~0.0008
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
    return Settings.ParticleColor or Color3.fromRGB(100, 180, 255)
end

local function createParticles()
    if ParticleGui then pcall(function() ParticleGui:Destroy() end); ParticleGui = nil end
    Particles = {}; if not Settings.Particles then return end
    pcall(function()
        ParticleGui = tagTrack(Instance.new("ScreenGui"))
        ParticleGui.Name = "Template_Particles"; ParticleGui.ResetOnSpawn=false; ParticleGui.DisplayOrder=-999; ParticleGui.IgnoreGuiInset=true; ParticleGui.Parent=CoreGui
        for i=1,50 do
            local dot = tagTrack(Instance.new("Frame")); local size=math.random(4,8)
            dot.Size = UDim2.new(0,size,0,size)
            dot.Position = UDim2.new(0.28+math.random()*0.30, 0, 0.18+math.random()*0.32, 0)
            dot.BackgroundColor3 = getParticleColor(); dot.BackgroundTransparency=0.4+math.random()*0.4
            dot.BorderSizePixel=0; dot.Parent=ParticleGui
            local c = tagTrack(Instance.new("UICorner")); c.CornerRadius=UDim.new(0,10); c.Parent=dot
            local angle=math.random()*6.28; local speed=0.0002+math.random()*0.0006
            table.insert(Particles, {Frame=dot, Vx=math.cos(angle)*speed, Vy=math.sin(angle)*speed, Phase=math.random()*6.28, SizeBase=size, MinBoundX=0.28, MaxBoundX=0.58, MinBoundY=0.18, MaxBoundY=0.50})
        end
        ParticleRunning=true
        task.spawn(function()
            local time=0
            while ParticleRunning and ParticleGui and ParticleGui.Parent do
                time=time+0.03
                pcall(function()
                    for _,p in ipairs(Particles) do
                        if not p.Frame or not p.Frame.Parent then continue end
                        local x=p.Frame.Position.X.Scale+p.Vx; local y=p.Frame.Position.Y.Scale+p.Vy
                        if x>p.MaxBoundX then x=p.MaxBoundX; p.Vx=-p.Vx+(math.random()-0.5)*0.0001 elseif x<p.MinBoundX then x=p.MinBoundX; p.Vx=-p.Vx+(math.random()-0.5)*0.0001 end
                        if y>p.MaxBoundY then y=p.MaxBoundY; p.Vy=-p.Vy+(math.random()-0.5)*0.0001 elseif y<p.MinBoundY then y=p.MinBoundY; p.Vy=-p.Vy+(math.random()-0.5)*0.0001 end
                        p.Frame.Position=UDim2.new(x,0,y,0)
                        p.Frame.BackgroundTransparency=0.4+math.sin(time*0.8+p.Phase)*0.25
                        local s=math.max(1,p.SizeBase+math.sin(time+p.Phase)*0.8)
                        p.Frame.Size=UDim2.new(0,s,0,s)
                    end
                end)
                task.wait(0.03)
            end
        end)
    end)
end

local function updateParticleColor()
    local color=getParticleColor(); if not color or #Particles==0 then return end
    pcall(function() for _,p in ipairs(Particles) do if p.Frame and p.Frame.Parent then p.Frame.BackgroundColor3=color end end end)
end

local function destroyParticles()
    ParticleRunning=false; if ParticleGui then pcall(function() ParticleGui:Destroy() end); ParticleGui=nil end; Particles={}
end

-- ============================================================
--  第6部分：NPC透视系统
-- ============================================================
local function classifyNPC(humanoid, npcModel, npcName, fullPath)
    npcName=npcName or ""; fullPath=fullPath or ""
    local npcType=nil; pcall(function() npcType=humanoid:GetAttribute("NPCType") end)
    if npcType then if npcType=="Agent" or npcType=="Good" or npcType=="Friendly" then return "Good" elseif npcType=="Enemy" or npcType=="Bad" or npcType=="Hostile" then return "Bad" end end
    local nameLower=npcName:lower()
    for _,kw in ipairs({"警察","保安","警卫","警","守卫","卫兵","士兵","军人","polic","secur","guard","agent","officer","soldier","police","sheriff","swat","fbi","military","安保","安全"}) do if nameLower:find(kw) then return "Good" end end
    for _,kw in ipairs({"恐怖","匪","坏人","罪犯","敌人","坏蛋","歹徒","暴徒","terror","enemy","hostile","criminal","threat","suspect","intruder","invader","rogue","hijack","叛","贼","偷"}) do if nameLower:find(kw) then return "Bad" end end
    if fullPath:find("AgentTemplate") then return "Good" end; if fullPath:find("NPCTemplate") then return "Bad" end
    local tc=humanoid.TeamColor; if tc then if tc==BrickColor.new("Bright blue") or tc==BrickColor.new("Bright green") then return "Good" end; if tc==BrickColor.new("Bright red") or tc==BrickColor.new("Really black") then return "Bad" end end
    return "Bad"
end

local function createNPCESP(npcModel)
    if not npcModel or not npcModel.PrimaryPart then return end; if ESP_Objects[npcModel] then return end
    local humanoid=npcModel:FindFirstChildOfClass("Humanoid"); local head=npcModel:FindFirstChild("Head"); if not humanoid or not head then return end
    local npcType=classifyNPC(humanoid, npcModel, npcModel.Name, npcModel:GetFullName())
    local isGood=(npcType=="Good"); local color=isGood and Color3.fromRGB(0,255,80) or Color3.fromRGB(255,50,50)
    local label=isGood and "👮 好人" or "💀 坏人"
    local hl=tagTrack(Instance.new("Highlight")); hl.Adornee=npcModel; hl.FillColor=color; hl.FillTransparency=0.55; hl.OutlineColor=Color3.fromRGB(255,255,255); hl.OutlineTransparency=0.3; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Enabled=Settings.ESP_Enabled; hl.Parent=CoreGui
    local bg=tagTrack(Instance.new("BillboardGui")); bg.Adornee=head; bg.Size=UDim2.new(0,200,0,80); bg.StudsOffset=Vector3.new(0,3,0); bg.AlwaysOnTop=true; bg.Enabled=Settings.ESP_Enabled; bg.Parent=CoreGui
    local frame=tagTrack(Instance.new("Frame")); frame.Size=UDim2.new(1,-10,1,-10); frame.Position=UDim2.new(0,5,0,5); frame.BackgroundColor3=Color3.fromRGB(0,0,0); frame.BackgroundTransparency=0.35; frame.BorderSizePixel=0; frame.Parent=bg
    local fc=tagTrack(Instance.new("UICorner")); fc.CornerRadius=UDim.new(0,6); fc.Parent=frame
    local typeLabel=tagTrack(Instance.new("TextLabel")); typeLabel.Size=UDim2.new(1,-8,0,22); typeLabel.Position=UDim2.new(0,4,0,2); typeLabel.BackgroundTransparency=1; typeLabel.Text=label; typeLabel.TextColor3=color; typeLabel.TextScaled=true; typeLabel.Font=Enum.Font.SourceSansBold; typeLabel.TextXAlignment=Enum.TextXAlignment.Center; typeLabel.Parent=frame
    local infoLabel=tagTrack(Instance.new("TextLabel")); infoLabel.Size=UDim2.new(1,-8,0,18); infoLabel.Position=UDim2.new(0,4,0,24); infoLabel.BackgroundTransparency=1; infoLabel.Text=""; infoLabel.TextColor3=Color3.fromRGB(220,220,220); infoLabel.TextScaled=true; infoLabel.Font=Enum.Font.SourceSans; infoLabel.TextXAlignment=Enum.TextXAlignment.Center; infoLabel.Parent=frame
    local hpBg=tagTrack(Instance.new("Frame")); hpBg.Size=UDim2.new(0.8,0,0,4); hpBg.Position=UDim2.new(0.1,0,0,46); hpBg.BackgroundColor3=Color3.fromRGB(60,60,60); hpBg.BackgroundTransparency=0.3; hpBg.BorderSizePixel=0; hpBg.Parent=frame
    local hpf=tagTrack(Instance.new("Frame")); hpf.Size=UDim2.new(1,0,1,0); hpf.BackgroundColor3=isGood and Color3.fromRGB(0,200,100) or Color3.fromRGB(200,50,50); hpf.BorderSizePixel=0; hpf.Parent=hpBg
    local hfc=tagTrack(Instance.new("UICorner")); hfc.CornerRadius=UDim.new(0,2); hfc.Parent=hpBg
    ESP_Objects[npcModel]={Model=npcModel, Humanoid=humanoid, Head=head, Highlight=hl, Billboard=bg, Frame=frame, TypeLabel=typeLabel, InfoLabel=infoLabel, HPBar=hpf, HPBg=hpBg, IsGood=isGood, Label=label, Color=color}
end

local function updateAllESP()
    if not Settings.ESP_Enabled then return end
    local char=PlayerChar; if not char or not char.PrimaryPart then local plr=Players.LocalPlayer; if plr then pcall(function() char=plr.Character end); PlayerChar=char end end
    local myPos=char and char.PrimaryPart and char.PrimaryPart.Position
    for model,esp in pairs(ESP_Objects) do
        pcall(function()
            if not model or not model.Parent then if esp.Highlight then esp.Highlight:Destroy() end; if esp.Billboard then esp.Billboard:Destroy() end; ESP_Objects[model]=nil; return end
            if Settings.ESP_BadOnly and esp.IsGood then esp.Highlight.Enabled=false; esp.Billboard.Enabled=false; return end
            esp.Highlight.Enabled=true; esp.Billboard.Enabled=true
            local distText=""; if Settings.ESP_ShowDistance and myPos and esp.Head then local dist=(esp.Head.Position-myPos).Magnitude; if dist<=Settings.ESP_MaxRange then distText=string.format("%.0fm",dist) else esp.Highlight.Enabled=false; esp.Billboard.Enabled=false; return end end
            local hpText=""; local curHp=100; local maxHp=100
            if Settings.ESP_ShowHealth then pcall(function() curHp=esp.Humanoid.Health; maxHp=esp.Humanoid.MaxHealth end); hpText=string.format("HP: %.0f/%.0f",curHp,maxHp); esp.HPBar.Size=UDim2.new(math.max(0,curHp/maxHp),0,1,0) end
            local parts={}; if distText~="" then table.insert(parts,distText) end; if hpText~="" then table.insert(parts,hpText) end
            esp.InfoLabel.Text=table.concat(parts," | "); esp.HPBg.Visible=Settings.ESP_ShowHealth
        end)
    end
end

local function toggleESP(enabled)
    Settings.ESP_Enabled=enabled; for _,esp in pairs(ESP_Objects) do pcall(function() esp.Highlight.Enabled=enabled; esp.Billboard.Enabled=enabled end) end
end

local function startESPScanLoop()
    if ESP_Scanning then return end; ESP_Scanning=true
    task.spawn(function()
        while ESP_Scanning do
            pcall(function()
                local gc=0; local bc=0
                for _,obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("Head") then
                        local isP=false; pcall(function() local plr=Players:GetPlayerFromCharacter(obj); if plr then isP=true end end)
                        if isP then continue end; createNPCESP(obj)
                        if ESP_Objects[obj] then if ESP_Objects[obj].IsGood then gc=gc+1 else bc=bc+1 end end
                    end
                end
                ESP_Stats.Good=gc; ESP_Stats.Bad=bc; ESP_Stats.Total=gc+bc
                for model,_ in pairs(ESP_Objects) do if not model or not model.Parent then pcall(function() if ESP_Objects[model] then if ESP_Objects[model].Highlight then ESP_Objects[model].Highlight:Destroy() end; if ESP_Objects[model].Billboard then ESP_Objects[model].Billboard:Destroy() end end end); ESP_Objects[model]=nil end end
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
    pcall(function() for _,s in ipairs(CoreGui:GetDescendants()) do if s:IsA("ScrollingFrame") then s.ScrollBarThickness=14; s.ScrollBarImageColor3=Color3.fromRGB(220,220,220); s.ScrollBarImageTransparency=0.1 end end end)
end

-- ============================================================
--  第7部分：加载 WindUI
-- ============================================================
local WindUI = nil
local s,r = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))() end)

if s and r then
    WindUI=r; pcall(function() WindUI:SetTheme("Dark") end)
    WindUI:Popup({Title="WindUI 脚本模板 v3.0", Icon="solar:info-square-bold", Content=[[📋 NPC透视 - 高亮显示 + 头顶标签
💾 配置保存 - 自动保存/读取设置
🎨 主题系统 - 16种内置主题一键切换
✨ 粒子背景 - 紧约束窗口内飘浮 + 主题色适配
🌀 增强毛玻璃 - Acrylic + 透明叠加
🧹 脚本Tag清理 - 重启自动清除所有残留

⚠️ 加载后所有功能默认关闭，需手动开启]], Buttons={{Title="取消", Callback=function() end, Variant="Tertiary"},{Title="确认加载", Icon="solar:arrow-right-bold", Callback=function() PopupConfirmed=true; pcall(function() WindUI:Notify({Title="✅ 已加载", Content="⌨️ 按 RightShift 打开菜单", Duration=4, Icon="solar:bell-bold"}) end); task.spawn(function() createWindow() end) end, Variant="Primary"}}})
    task.spawn(function()
        while not PopupConfirmed do task.wait(0.5) end; task.wait(1.5); beautifyUI()
        local plr=Players.LocalPlayer; if plr then PlayerChar=plr.Character; plr.CharacterAdded:Connect(function(nc) PlayerChar=nc end) end
        startESPScanLoop()
        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end; if input.UserInputType~=Enum.UserInputType.Keyboard then return end
            local kn=input.KeyCode.Name
            if Keybinds.ESP and Keybinds.ESP~="" and kn==Keybinds.ESP then Settings.ESP_Enabled=not Settings.ESP_Enabled; pcall(function() if Controls.ESPToggle then Controls.ESPToggle:Set(Settings.ESP_Enabled) end end); toggleESP(Settings.ESP_Enabled) end
            if Keybinds.BadOnly and Keybinds.BadOnly~="" and kn==Keybinds.BadOnly then Settings.ESP_BadOnly=not Settings.ESP_BadOnly; pcall(function() if Controls.BadOnlyToggle then Controls.BadOnlyToggle:Set(Settings.ESP_BadOnly) end end) end
        end)
    end)

    function createWindow()
        if WindowRef then return end
        local ok,win = pcall(function() return WindUI:CreateWindow({Title="WindUI 脚本模板", Author="b站英吉利超入_", Icon="solar:shield-warning-bold", Size=UDim2.fromOffset(750,520), ToggleKey=Enum.KeyCode.RightShift, Folder="windui-template", Acrylic=true, Transparent=true, Resizable=false, SideBarWidth=180, ScrollBarEnabled=true, HideSearchBar=true}) end)
        if not ok or not win then print("[模板] 窗口创建失败:", ok); return end
        WindowRef=win; pcall(function() WindUI.TransparencyValue=0.22 end)

        local mt=win:Tab({Title="主控面板", Icon="solar:slider-vertical-bold"})
        mt:Paragraph({Title="👁 NPC透视控制"})
        Controls.ESPToggle=mt:Toggle({Flag="ESPToggle", Title="透视开关", Value=false, Desc="高亮显示+头顶标签", Callback=function(v) toggleESP(v) end})
        Controls.BadOnlyToggle=mt:Toggle({Flag="BadOnlyToggle", Title="仅显示坏人", Value=false, Desc="隐藏好人", Callback=function(v) Settings.ESP_BadOnly=v end})
        mt:Divider(); mt:Paragraph({Title="📏 标签显示设置"})
        Controls.DistanceToggle=mt:Toggle({Flag="DistanceToggle", Title="显示距离", Value=true, Callback=function(v) Settings.ESP_ShowDistance=v end})
        Controls.HealthToggle=mt:Toggle({Flag="HealthToggle", Title="显示血量", Value=true, Callback=function(v) Settings.ESP_ShowHealth=v end})
        mt:Divider()
        Controls.RangeSlider=mt:Slider({Flag="RangeSlider", Title="最大探测距离", Step=10, Value={Min=50,Max=1000,Default=500}, Width=200, IsTextbox=true, Callback=function(v) Settings.ESP_MaxRange=v end})

        local ft=win:Tab({Title="功能设置", Icon="solar:settings-bold"})
        ft:Paragraph({Title="🔑 快捷键设置"})
        Controls.ESPKeybind=ft:Keybind({Flag="ESPKeybind", Title="透视开关快捷键", Value="", Callback=function(k) Keybinds.ESP=k end})
        Controls.BadOnlyKeybind=ft:Keybind({Flag="BadOnlyKeybind", Title="仅显示坏人快捷键", Value="", Callback=function(k) Keybinds.BadOnly=k end})
        ft:Divider(); ft:Paragraph({Title="💡 提示", Desc="窗口快捷键在UI设置中绑定（默认 RightShift）"})

        local ut=win:Tab({Title="UI设置", Icon="solar:monitor-bold"})
        ut:Paragraph({Title="⚙️ 界面设置"})
        Controls.WindowKeybind=ut:Keybind({Flag="WindowKeybind", Title="窗口开关快捷键", Value="RightShift", Callback=function(k) Keybinds.Window=k; if WindowRef then pcall(function() WindowRef:SetToggleKey(Enum.KeyCode[k]) end) end end})
        Controls.FloatingBtnToggle=ut:Toggle({Flag="FloatingBtnToggle", Title="显示悬浮按钮", Value=IsMobile, Callback=function(v) if FloatingButtonGui then FloatingButtonGui.Enabled=v end end})
        ut:Divider(); ut:Paragraph({Title="🌀 背景效果"})
        Controls.ParticlesToggle=ut:Toggle({Flag="ParticlesToggle", Title="浮动粒子背景(50个)", Value=true, Callback=function(v) Settings.Particles=v; if v then createParticles() else destroyParticles() end end})
        ut:Divider(); ut:Paragraph({Title="✨ 窗口效果"})
        Controls.AcrylicToggle=ut:Toggle({Flag="AcrylicToggle", Title="毛玻璃效果", Value=true, Callback=function(v) pcall(function() WindUI:ToggleAcrylic(v) end) end})
        Controls.TransparencyToggle=ut:Toggle({Flag="TransparencyToggle", Title="透明背景增强毛玻璃", Value=true, Callback=function(v) if WindowRef then pcall(function() WindowRef:ToggleTransparency(v) end) end end})
        ut:Divider(); ut:Paragraph({Title="🎨 主题系统", Desc="切换主题时粒子颜色自动适配"})
        local allThemes={}; pcall(function() allThemes=WindUI:GetThemes() end)
        local tns={}; for n,_ in pairs(allThemes) do table.insert(tns,n) end; table.sort(tns)
        -- v3.0: 切换主题时直接存储Color3到Settings.ParticleColor
        Controls.ThemeDropdown=ut:Dropdown({Flag="ThemeDropdown", Title="选择主题", Values=tns, Value="Dark", Callback=function(sl) if sl then Settings.CurrentTheme=sl; pcall(function() WindUI:SetTheme(sl) end); local c=ThemeColors[sl]; if c then Settings.ParticleColor=c end; updateParticleColor() end end})

        local st=win:Tab({Title="信息统计", Icon="solar:chart-bold"})
        TabElements.StatGood=st:Paragraph({Title="🟢 好人: 0"}); TabElements.StatBad=st:Paragraph({Title="🔴 坏人: 0"}); TabElements.StatTotal=st:Paragraph({Title="📊 总计: 0"})
        st:Divider(); TabElements.StatusInput=st:Input({Flag="StatusInputCache", Title="扫描状态", Value="等待中...", Locked=true})

        local ct=win:Tab({Title="配置管理", Icon="solar:diskette-bold"})
        ct:Paragraph({Title="💾 配置管理", Desc="保存/加载你的所有设置"})
        local cni=ct:Input({Flag="ConfigNameInput", Title="配置名称", Value="default", Icon="solar:file-text-bold", Callback=function(v) ConfigName=v end})
        ct:Space(); local CM=WindowRef.ConfigManager; local AC={}; pcall(function() AC=CM:AllConfigs() end)
        local DV=nil; pcall(function() for _,v in ipairs(AC) do if v=="default" then DV="default"; break end end end)
        local ACD=ct:Dropdown({Title="已有配置", Desc="选择要加载的配置", Values=AC, Value=DV, Callback=function(v) if v then ConfigName=v; pcall(function() cni:Set(v) end) end end})
        ct:Space(); ct:Button({Title="💾 保存配置", Icon="solar:check-circle-bold", Justify="Center", Color=Color3.fromHex("#305dff"), Callback=function() if not CM then return end; pcall(function() local c=CM:Config(ConfigName); if c and c:Save() then WindUI:Notify({Title="✅ 配置已保存", Content="配置 '"..ConfigName.."' 已保存", Icon="solar:check-circle-bold", Duration=3}); ACD:Refresh(CM:AllConfigs()) end end) end})
        ct:Space(); ct:Button({Title="📂 加载配置", Icon="solar:refresh-circle-bold", Justify="Center", Color=Color3.fromHex("#10C550"), Callback=function() if not CM then return end; pcall(function() local c=CM:CreateConfig(ConfigName,false); if c and c:Load() then WindUI:Notify({Title="✅ 配置已加载", Content="配置 '"..ConfigName.."' 已加载", Icon="solar:refresh-circle-bold", Duration=3}) end end) end})
        ct:Space(); ct:Button({Title="🗑️ 删除配置", Icon="solar:trash-bin-trash-bold", Justify="Center", Color=Color3.fromHex("#ff3040"), Callback=function() if not CM then return end; pcall(function() local c=CM:Config(ConfigName); if c and c:Delete() then WindUI:Notify({Title="🗑️ 配置已删除", Content="配置 '"..ConfigName.."' 已删除", Icon="solar:trash-bin-trash-bold", Duration=3}); ACD:Refresh(CM:AllConfigs()) end end) end})
        ct:Divider(); ct:Paragraph({Title="💡 提示", Desc="所有带 Flag 的元素自动保存/恢复\n脚本Tag清理: 重启自动清除全部残留"})

        task.spawn(function() task.wait(1); pcall(function() if CM then local config=CM:CreateConfig("default",true) end end); createParticles() end)

        local at=win:Tab({Title="关于", Icon="solar:info-square-bold"})
        at:Paragraph({Title="WindUI 脚本模板 v3.0", Desc="三大Bug修复: 粒子颜色/紧约束/脚本Tag清理"})
        at:Divider(); at:Paragraph({Title="👤 作者", Desc="b站英吉利超入_"})
        at:Divider(); at:Paragraph({Title="💡 使用说明", Desc=IsMobile and "手机: 点击悬浮按钮" or "PC: 按 RightShift 打开菜单"})
        at:Paragraph({Title="⚠️ 提示", Desc="所有功能默认关闭，请在菜单中手动开启"})
        at:Paragraph({Title="🧹 清理", Desc="重启脚本自动清除所有残留 (脚本Tag系统)"})

        if IsMobile then
            task.spawn(function()
                task.wait(1)
                pcall(function()
                    FloatingButtonGui=tagTrack(Instance.new("ScreenGui")); FloatingButtonGui.Name="Template_Btn"; FloatingButtonGui.Enabled=true; FloatingButtonGui.ResetOnSpawn=false; FloatingButtonGui.Parent=CoreGui
                    local btn=tagTrack(Instance.new("ImageButton")); btn.Size=UDim2.new(0,50,0,50); btn.Position=UDim2.new(0.9,-25,0.8,-25); btn.BackgroundColor3=Color3.fromRGB(0,180,80); btn.BackgroundTransparency=0.2; btn.BorderSizePixel=0; btn.Parent=FloatingButtonGui
                    local c=tagTrack(Instance.new("UICorner")); c.CornerRadius=UDim.new(0,25); c.Parent=btn
                    local t=tagTrack(Instance.new("TextLabel")); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1; t.Text="👁"; t.TextScaled=true; t.Font=Enum.Font.SourceSansBold; t.TextColor3=Color3.fromRGB(255,255,255); t.Parent=btn
                    local d,ds,sp=false,nil,nil
                    btn.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then d=true; ds=inp.Position; sp=btn.Position end end)
                    btn.InputChanged:Connect(function(inp) if d and (inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMovement) then btn.Position=UDim2.new(sp.X.Scale,sp.X.Offset+inp.Position.X-ds.X,sp.Y.Scale,sp.Y.Offset+inp.Position.Y-ds.Y) end end)
                    btn.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)
                    btn.MouseButton1Click:Connect(function() if WindowRef then pcall(function() WindowRef:Toggle() end) end end)
                end)
            end)
        end
    end
    print("[模板] v3.0 已加载 | 作者: b站英吉利超入_")
else
    print("[模板] WindUI 加载失败"); local msg=Instance.new("Message"); msg.Text="⚠️ WindUI 加载失败，请重试"; msg.Parent=Workspace; task.delay(5,function() msg:Destroy() end)
end
print("[模板] 脚本加载完成")
