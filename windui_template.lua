--[[
    WindUI 通用脚本模板 v3.3（开箱即用版）
    
    v3.3 三大究极Bug修复（同步主线v12.3）:
    B1: 部分主题颜色不合适 → 重新设计ThemeColors配色方案（更柔和/适配）
    B2: 粒子穿透UI → 动态追踪窗口Frame位置，粒子容器ClipsDescendants=true
    B3: 关闭脚本后残留 → 启动时立即清理 + _G.强制清理函数
    
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
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if not IsMobile then pcall(function() IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled end) end

-- ============================================================
--  第2部分：B3 启动时立即清理所有残留 + 外部清理函数
-- ============================================================
local TAG_NAME = "TemplateESP"

local function immediateCleanup()
    local count = 0
    pcall(function()
        for _, inst in ipairs(CoreGui:GetDescendants()) do
            local s, attr = pcall(function() return inst:GetAttribute(TAG_NAME) end)
            if s and attr then pcall(function() inst:Destroy() end); count = count + 1 end
        end
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local n = gui.Name
                if n:find("Template") or n:find("Particle") or n:find("WindUI") then
                    pcall(function() gui:Destroy() end); count = count + 1
                end
            end
        end
    end)
    if count > 0 then print("[清理] 启动时已清除 " .. count .. " 个残留实例") end
end
immediateCleanup()

_G.CleanupTemplate = function()
    immediateCleanup()
    print("[清理] 手动清理完成")
end

local function tagTrack(inst)
    if not inst then return nil end; pcall(function() inst:SetAttribute(TAG_NAME, true) end); return inst
end

-- ============================================================
--  第3部分：设置项
-- ============================================================
local Settings = {
    Particles = true, CurrentTheme = "Dark", ParticleColor = Color3.fromRGB(80, 170, 255),
    ESP_Enabled = false, ESP_BadOnly = false, ESP_ShowDistance = true, ESP_ShowHealth = true, ESP_MaxRange = 500,
}

-- ============================================================
--  第4部分：B1 主题色配色方案（手动精选，柔和适配）
-- ============================================================
local ThemeColors = {
    dark = Color3.fromRGB(80,170,255), light = Color3.fromRGB(60,130,210),
    rose = Color3.fromRGB(255,130,170), plant = Color3.fromRGB(70,210,130),
    ocean = Color3.fromRGB(60,190,240), sunset = Color3.fromRGB(255,160,70),
    midnight = Color3.fromRGB(130,100,240), forest = Color3.fromRGB(60,180,90),
    lavender = Color3.fromRGB(190,140,255), coral = Color3.fromRGB(255,140,90),
    mint = Color3.fromRGB(80,230,190), peanut = Color3.fromRGB(210,180,90),
    sky = Color3.fromRGB(100,190,255), blood = Color3.fromRGB(230,90,80),
    lemon = Color3.fromRGB(230,210,70), cyber = Color3.fromRGB(0,235,210),
}

local function nameToColor(n) local h=0;for i=1,#n do h=h+string.byte(n,i)end;local s=math.sin(h*137.5)*0.5+0.5;local s2=math.sin(h*73.1+50)*0.5+0.5;return Color3.fromRGB(math.floor(80+s*175),math.floor(100+s2*155),math.floor(130+math.sin(h*41.7)*0.5*125)) end

local function getThemePrimaryColor(name)
    if not name then return Color3.fromRGB(80,170,255) end;local l=name:lower()
    local themes=nil;pcall(function()themes=WindUI:GetThemes()end)
    if themes and themes[name] then local d=themes[name];local c=nil;pcall(function()if type(d)=="table" then c=d.Primary or d.Accent or d.Color or d.Main end end);if c then return c end end
    local m=ThemeColors[l];if m then return m end
    if l:find("dark")or l:find("night")then return Color3.fromRGB(80,170,255)end;if l:find("light")then return Color3.fromRGB(60,130,210)end;if l:find("rose")or l:find("pink")then return Color3.fromRGB(255,130,170)end;if l:find("plant")or l:find("green")or l:find("forest")or l:find("mint")then return Color3.fromRGB(70,210,130)end;if l:find("ocean")or l:find("blue")or l:find("sky")then return Color3.fromRGB(60,190,240)end;if l:find("sunset")or l:find("orange")or l:find("coral")then return Color3.fromRGB(255,160,70)end;if l:find("midnight")or l:find("purple")or l:find("lavender")then return Color3.fromRGB(130,100,240)end;if l:find("blood")or l:find("red")then return Color3.fromRGB(230,90,80)end;if l:find("lemon")or l:find("yellow")then return Color3.fromRGB(230,210,70)end
    return nameToColor(name)
end

-- ============================================================
--  第5部分：内部变量
-- ============================================================
local WindowRef=nil;local FloatingButtonGui=nil;local ParticleContainer=nil;local ParticleRunning=false;local Particles={};local WindowMainFrame=nil;local ParticleHeartbeat=nil;local PopupConfirmed=false
local Controls={};local Keybinds={};local TabElements={};local ConfigName="default"
local ESP_Objects={};local ESP_Scanning=false;local ESP_Stats={Good=0,Bad=0,Total=0};local PlayerChar=nil

local function mobileToggleWindow() if not WindowRef then return end; pcall(function()VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.RightShift,false,game);task.wait(0.05);VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.RightShift,false,game)end) end

-- ============================================================
--  第6部分：B2 粒子系统重写（追踪窗口+Clips裁剪）
-- ============================================================
local function findWindowMainFrame()
    WindowMainFrame=nil;pcall(function()for _,gui in ipairs(CoreGui:GetChildren())do if gui:IsA("ScreenGui")then for _,f in ipairs(gui:GetChildren())do if f:IsA("Frame")and f:FindFirstChild("UICorner")then local uc=f:FindFirstChild("UICorner");if uc and uc.CornerRadius==UDim.new(0,8)and f.AbsoluteSize.X>700 then WindowMainFrame=f;return end end end end end end);return WindowMainFrame
end

local function getParticleColor() return Settings.ParticleColor or Color3.fromRGB(80,170,255) end

local function createParticles()
    if ParticleContainer then pcall(function()ParticleContainer:Destroy()end);ParticleContainer=nil end;Particles={};ParticleRunning=false
    if ParticleHeartbeat then pcall(function()ParticleHeartbeat:Disconnect()end);ParticleHeartbeat=nil end
    if not Settings.Particles then return end;findWindowMainFrame()
    if not WindowMainFrame then task.spawn(function()task.wait(1);findWindowMainFrame();if WindowMainFrame then createParticles()end end);return end
    pcall(function()
        local psg=Instance.new("ScreenGui");psg.Name="Template_ParticleContainer";psg.DisplayOrder=-9999;psg.ResetOnSpawn=false;psg.Parent=CoreGui;tagTrack(psg)
        ParticleContainer=Instance.new("Frame");ParticleContainer.BackgroundTransparency=1;ParticleContainer.BorderSizePixel=0;ParticleContainer.ClipsDescendants=true;ParticleContainer.Parent=psg;tagTrack(ParticleContainer)
        local pos=WindowMainFrame.AbsolutePosition;local size=WindowMainFrame.AbsoluteSize;ParticleContainer.Position=UDim2.fromOffset(pos.X,pos.Y);ParticleContainer.Size=UDim2.fromOffset(size.X,size.Y)
        ParticleHeartbeat=RunService.Heartbeat:Connect(function()if not ParticleContainer or not ParticleContainer.Parent then if ParticleHeartbeat then ParticleHeartbeat:Disconnect();ParticleHeartbeat=nil end;return end;if WindowMainFrame and WindowMainFrame.Parent then local ap=WindowMainFrame.AbsolutePosition;local as=WindowMainFrame.AbsoluteSize;ParticleContainer.Position=UDim2.fromOffset(ap.X,ap.Y);ParticleContainer.Size=UDim2.fromOffset(as.X,as.Y);ParticleContainer.Visible=WindowMainFrame.Visible else ParticleContainer.Visible=false;findWindowMainFrame()end end)
        local c=getParticleColor();local w=size.X;local h=size.Y
        for i=1,50 do local dot=Instance.new("Frame");local sz=math.random(4,8);dot.Size=UDim2.new(0,sz,0,sz);dot.Position=UDim2.fromOffset(math.random(10,math.max(20,w-10)),math.random(10,math.max(20,h-10)));dot.BackgroundColor3=c;dot.BackgroundTransparency=0.4+math.random()*0.4;dot.BorderSizePixel=0;dot.ZIndex=0;dot.Parent=ParticleContainer;tagTrack(dot);local cn=Instance.new("UICorner");cn.CornerRadius=UDim.new(0,10);cn.Parent=dot;local a=math.random()*6.28;local sp=0.1+math.random()*0.3;table.insert(Particles,{Frame=dot,Vx=math.cos(a)*sp,Vy=math.sin(a)*sp,Phase=math.random()*6.28,SizeBase=sz})end
        ParticleRunning=true
        task.spawn(function()local t=0;while ParticleRunning and ParticleContainer and ParticleContainer.Parent do t=t+0.03;pcall(function()local cw=ParticleContainer.AbsoluteSize.X;local ch=ParticleContainer.AbsoluteSize.Y;if cw<=0 or ch<=0 then task.wait(0.03);return end;for _,p in ipairs(Particles)do if not p.Frame or not p.Frame.Parent then continue end;local px=p.Frame.Position;local x=px.X.Offset+p.Vx;local y=px.Y.Offset+p.Vy;local sz=p.Frame.AbsoluteSize.X;if x+sz>=cw then x=cw-sz;p.Vx=-p.Vx*0.95 elseif x<0 then x=0;p.Vx=-p.Vx*0.95 end;if y+sz>=ch then y=ch-sz;p.Vy=-p.Vy*0.95 elseif y<0 then y=0;p.Vy=-p.Vy*0.95 end;p.Frame.Position=UDim2.fromOffset(x,y);p.Frame.BackgroundTransparency=0.4+math.sin(t*0.8+p.Phase)*0.25;local bs=math.max(1,p.SizeBase+math.sin(t+p.Phase)*0.8);p.Frame.Size=UDim2.new(0,bs,0,bs)end end);task.wait(0.03)end end)
    end)
end

local function updateParticleColor()local c=getParticleColor();if not c or #Particles==0 then return end;pcall(function()for _,p in ipairs(Particles)do if p.Frame and p.Frame.Parent then p.Frame.BackgroundColor3=c end end end)end
local function destroyParticles()ParticleRunning=false;if ParticleHeartbeat then pcall(function()ParticleHeartbeat:Disconnect()end);ParticleHeartbeat=nil end;if ParticleContainer then pcall(function()local pa=ParticleContainer.Parent;if pa then pcall(function()pa:Destroy()end)end end);ParticleContainer=nil end;Particles={}end

-- ============================================================
--  第7部分：NPC透视系统
-- ============================================================
local function classifyNPC(humanoid,nm,name,fp)
    name=name or"";fp=fp or"";local nt=nil;pcall(function()nt=humanoid:GetAttribute("NPCType")end)
    if nt then if nt=="Agent"or nt=="Good"or nt=="Friendly"then return"Good"elseif nt=="Enemy"or nt=="Bad"or nt=="Hostile"then return"Bad"end end;local nl=name:lower()
    for _,kw in ipairs({"警察","保安","警卫","警","守卫","卫兵","士兵","军人","polic","secur","guard","agent","officer","soldier","police","sheriff","swat","fbi","military","安保","安全"})do if nl:find(kw)then return"Good"end end
    for _,kw in ipairs({"恐怖","匪","坏人","罪犯","敌人","坏蛋","歹徒","暴徒","terror","enemy","hostile","criminal","threat","suspect","intruder","invader","rogue","hijack","叛","贼","偷"})do if nl:find(kw)then return"Bad"end end
    if fp:find("AgentTemplate")then return"Good"end;if fp:find("NPCTemplate")then return"Bad"end;local tc=humanoid.TeamColor;if tc then if tc==BrickColor.new("Bright blue")or tc==BrickColor.new("Bright green")then return"Good"end;if tc==BrickColor.new("Bright red")or tc==BrickColor.new("Really black")then return"Bad"end end;return"Bad"
end

local function createNPCESP(nm)if not nm or not nm.PrimaryPart then return end;if ESP_Objects[nm]then return end;local h=nm:FindFirstChildOfClass("Humanoid");local hd=nm:FindFirstChild("Head");if not h or not hd then return end;local nt=classifyNPC(h,nm,nm.Name,nm:GetFullName());local ig=(nt=="Good");local c=ig and Color3.fromRGB(0,255,80)or Color3.fromRGB(255,50,50);local lb=ig and"👮 好人"or"💀 坏人"
local hl=tagTrack(Instance.new("Highlight"));hl.Adornee=nm;hl.FillColor=c;hl.FillTransparency=0.55;hl.OutlineColor=Color3.fromRGB(255,255,255);hl.OutlineTransparency=0.3;hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.Enabled=Settings.ESP_Enabled;hl.Parent=CoreGui
local bg=tagTrack(Instance.new("BillboardGui"));bg.Adornee=hd;bg.Size=UDim2.new(0,200,0,80);bg.StudsOffset=Vector3.new(0,3,0);bg.AlwaysOnTop=true;bg.Enabled=Settings.ESP_Enabled;bg.Parent=CoreGui
local fr=tagTrack(Instance.new("Frame"));fr.Size=UDim2.new(1,-10,1,-10);fr.Position=UDim2.new(0,5,0,5);fr.BackgroundColor3=Color3.fromRGB(0,0,0);fr.BackgroundTransparency=0.35;fr.BorderSizePixel=0;fr.Parent=bg;tagTrack(Instance.new("UICorner"));fr.UICorner.CornerRadius=UDim.new(0,6)
local tl=tagTrack(Instance.new("TextLabel"));tl.Size=UDim2.new(1,-8,0,22);tl.Position=UDim2.new(0,4,0,2);tl.BackgroundTransparency=1;tl.Text=lb;tl.TextColor3=c;tl.TextScaled=true;tl.Font=Enum.Font.SourceSansBold;tl.TextXAlignment=Enum.TextXAlignment.Center;tl.Parent=fr
local il=tagTrack(Instance.new("TextLabel"));il.Size=UDim2.new(1,-8,0,18);il.Position=UDim2.new(0,4,0,24);il.BackgroundTransparency=1;il.Text="";il.TextColor3=Color3.fromRGB(220,220,220);il.TextScaled=true;il.Font=Enum.Font.SourceSans;il.TextXAlignment=Enum.TextXAlignment.Center;il.Parent=fr
local hb=tagTrack(Instance.new("Frame"));hb.Size=UDim2.new(0.8,0,0,4);hb.Position=UDim2.new(0.1,0,0,46);hb.BackgroundColor3=Color3.fromRGB(60,60,60);hb.BackgroundTransparency=0.3;hb.BorderSizePixel=0;hb.Parent=fr;local hf=tagTrack(Instance.new("Frame"));hf.Size=UDim2.new(1,0,1,0);hf.BackgroundColor3=ig and Color3.fromRGB(0,200,100)or Color3.fromRGB(200,50,50);hf.BorderSizePixel=0;hf.Parent=hb;tagTrack(Instance.new("UICorner"));hb.UICorner.CornerRadius=UDim.new(0,2)
ESP_Objects[nm]={Model=nm,Humanoid=h,Head=hd,Highlight=hl,Billboard=bg,Frame=fr,TypeLabel=tl,InfoLabel=il,HPBar=hf,HPBg=hb,IsGood=ig,Label=lb,Color=c}end

local function updateAllESP()if not Settings.ESP_Enabled then return end;local ch=PlayerChar;if not ch or not ch.PrimaryPart then local p=Players.LocalPlayer;if p then pcall(function()ch=p.Character end);PlayerChar=ch end end;local mp=ch and ch.PrimaryPart and ch.PrimaryPart.Position;for md,esp in pairs(ESP_Objects)do pcall(function()if not md or not md.Parent then if esp.Highlight then esp.Highlight:Destroy()end;if esp.Billboard then esp.Billboard:Destroy()end;ESP_Objects[md]=nil;return end;if Settings.ESP_BadOnly and esp.IsGood then esp.Highlight.Enabled=false;esp.Billboard.Enabled=false;return end;esp.Highlight.Enabled=true;esp.Billboard.Enabled=true;local dt="";if Settings.ESP_ShowDistance and mp and esp.Head then local d=(esp.Head.Position-mp).Magnitude;if d<=Settings.ESP_MaxRange then dt=string.format("%.0fm",d)else esp.Highlight.Enabled=false;esp.Billboard.Enabled=false;return end end;local ht="";local ch=100;local mh=100;if Settings.ESP_ShowHealth then pcall(function()ch=esp.Humanoid.Health;mh=esp.Humanoid.MaxHealth end);ht=string.format("HP: %.0f/%.0f",ch,mh);esp.HPBar.Size=UDim2.new(math.max(0,ch/mh),0,1,0)end;local ps={};if dt~=""then table.insert(ps,dt)end;if ht~=""then table.insert(ps,ht)end;esp.InfoLabel.Text=table.concat(ps," | ");esp.HPBg.Visible=Settings.ESP_ShowHealth end)end end

local function toggleESP(en)Settings.ESP_Enabled=en;for _,esp in pairs(ESP_Objects)do pcall(function()esp.Highlight.Enabled=en;esp.Billboard.Enabled=en end)end end

local function startESPScanLoop()if ESP_Scanning then return end;ESP_Scanning=true;task.spawn(function()while ESP_Scanning do pcall(function()local gc=0;local bc=0;for _,o in ipairs(Workspace:GetDescendants())do if o:IsA("Model")and o:FindFirstChildOfClass("Humanoid")and o:FindFirstChild("Head")then local isP=false;pcall(function()local p=Players:GetPlayerFromCharacter(o);if p then isP=true end end);if isP then continue end;createNPCESP(o);if ESP_Objects[o]then if ESP_Objects[o].IsGood then gc=gc+1 else bc=bc+1 end end end end;ESP_Stats.Good=gc;ESP_Stats.Bad=bc;ESP_Stats.Total=gc+bc;for md,_ in pairs(ESP_Objects)do if not md or not md.Parent then pcall(function()if ESP_Objects[md]then if ESP_Objects[md].Highlight then ESP_Objects[md].Highlight:Destroy()end;if ESP_Objects[md].Billboard then ESP_Objects[md].Billboard:Destroy()end end end);ESP_Objects[md]=nil end end;if TabElements.StatGood then TabElements.StatGood:SetTitle("🟢 好人: "..ESP_Stats.Good)end;if TabElements.StatBad then TabElements.StatBad:SetTitle("🔴 坏人: "..ESP_Stats.Bad)end;if TabElements.StatTotal then TabElements.StatTotal:SetTitle("📊 总计: "..ESP_Stats.Total)end;if TabElements.StatusInput then TabElements.StatusInput:Set("扫描中 | 好人:"..ESP_Stats.Good.." 坏人:"..ESP_Stats.Bad.." 总计:"..ESP_Stats.Total)end end);updateAllESP();task.wait(1)end end)end

local function beautifyUI()pcall(function()for _,s in ipairs(CoreGui:GetDescendants())do if s:IsA("ScrollingFrame")then s.ScrollBarThickness=14;s.ScrollBarImageColor3=Color3.fromRGB(220,220,220);s.ScrollBarImageTransparency=0.1 end end end)end
task.spawn(function()while true do task.wait(3);beautifyUI()end end)

-- ============================================================
--  第8部分：加载 WindUI
-- ============================================================
local WindUI=nil;local s,r=pcall(function()return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()end)

if s and r then
    WindUI=r;pcall(function()WindUI:SetTheme("Dark")end)
    WindUI:Popup({Title="WindUI 脚本模板 v3.3",Icon="solar:info-square-bold",Content="📋 NPC透视 - 高亮显示 + 头顶标签\n💾 配置保存 - 自动保存/读取设置\n🎨 主题系统 - 16种内置主题一键切换\n✨ 粒子背景 - 窗口内Clips裁剪+追踪窗口位置\n🌀 增强毛玻璃 - Acrylic + 透明叠加\n🧹 即时清理 - 启动时自动清除所有残留\n\n⚠️ 加载后所有功能默认关闭，需手动开启",Buttons={{Title="取消",Callback=function()end,Variant="Tertiary"},{Title="确认加载",Icon="solar:arrow-right-bold",Callback=function()PopupConfirmed=true;pcall(function()WindUI:Notify({Title="✅ 已加载",Content="⌨️ 按 RightShift 打开菜单",Duration=4,Icon="solar:bell-bold"})end);task.spawn(function()createWindow()end)end,Variant="Primary"}}})
    task.spawn(function()
        while not PopupConfirmed do task.wait(0.5)end;task.wait(0.5);beautifyUI()
        local plr=Players.LocalPlayer;if plr then PlayerChar=plr.Character;plr.CharacterAdded:Connect(function(nc)PlayerChar=nc end)end;startESPScanLoop()
        UserInputService.InputBegan:Connect(function(input,gp)if gp then return end;if input.UserInputType~=Enum.UserInputType.Keyboard then return end;local kn=input.KeyCode.Name;if Keybinds.ESP and Keybinds.ESP~=""and kn==Keybinds.ESP then Settings.ESP_Enabled=not Settings.ESP_Enabled;pcall(function()if Controls.ESPToggle then Controls.ESPToggle:Set(Settings.ESP_Enabled)end end);toggleESP(Settings.ESP_Enabled)end;if Keybinds.BadOnly and Keybinds.BadOnly~=""and kn==Keybinds.BadOnly then Settings.ESP_BadOnly=not Settings.ESP_BadOnly;pcall(function()if Controls.BadOnlyToggle then Controls.BadOnlyToggle:Set(Settings.ESP_BadOnly)end end)end end)
    end)

    function createWindow()
        if WindowRef then return end;local ok,win=pcall(function()return WindUI:CreateWindow({Title="WindUI 脚本模板",Author="b站英吉利超入_",Icon="solar:shield-warning-bold",Size=UDim2.fromOffset(750,520),ToggleKey=Enum.KeyCode.RightShift,Folder="windui-template",Acrylic=true,Transparent=true,Resizable=false,SideBarWidth=180,ScrollBarEnabled=true,HideSearchBar=true})end)
        if not ok or not win then print("[模板] 窗口创建失败:",ok);return end;WindowRef=win;pcall(function()WindUI.TransparencyValue=0.22 end)
        pcall(function()win.OnClose=function()destroyParticles()end;win.OnOpen=function()if Settings.Particles then createParticles()end end end)

        local mt=win:Tab({Title="主控面板",Icon="solar:slider-vertical-bold"});mt:Paragraph({Title="👁 NPC透视控制"});Controls.ESPToggle=mt:Toggle({Flag="ESPToggle",Title="透视开关",Value=false,Desc="高亮显示+头顶标签",Callback=function(v)toggleESP(v)end});Controls.BadOnlyToggle=mt:Toggle({Flag="BadOnlyToggle",Title="仅显示坏人",Value=false,Desc="隐藏好人",Callback=function(v)Settings.ESP_BadOnly=v end});mt:Divider();mt:Paragraph({Title="📏 标签显示设置"});Controls.DistanceToggle=mt:Toggle({Flag="DistanceToggle",Title="显示距离",Value=true,Callback=function(v)Settings.ESP_ShowDistance=v end});Controls.HealthToggle=mt:Toggle({Flag="HealthToggle",Title="显示血量",Value=true,Callback=function(v)Settings.ESP_ShowHealth=v end});mt:Divider();Controls.RangeSlider=mt:Slider({Flag="RangeSlider",Title="最大探测距离",Step=10,Value={Min=50,Max=1000,Default=500},Width=200,IsTextbox=true,Callback=function(v)Settings.ESP_MaxRange=v end})

        local ft=win:Tab({Title="功能设置",Icon="solar:settings-bold"});ft:Paragraph({Title="🔑 快捷键设置"});Controls.ESPKeybind=ft:Keybind({Flag="ESPKeybind",Title="透视开关快捷键",Value="",Callback=function(k)Keybinds.ESP=k end});Controls.BadOnlyKeybind=ft:Keybind({Flag="BadOnlyKeybind",Title="仅显示坏人快捷键",Value="",Callback=function(k)Keybinds.BadOnly=k end});ft:Divider();ft:Paragraph({Title="💡 提示",Desc="窗口快捷键在UI设置中绑定（默认 RightShift）"})

        local ut=win:Tab({Title="UI设置",Icon="solar:monitor-bold"});ut:Paragraph({Title="⚙️ 界面设置"});Controls.WindowKeybind=ut:Keybind({Flag="WindowKeybind",Title="窗口开关快捷键",Value="RightShift",Callback=function(k)Keybinds.Window=k;if WindowRef then pcall(function()WindowRef:SetToggleKey(Enum.KeyCode[k])end)end end});Controls.FloatingBtnToggle=ut:Toggle({Flag="FloatingBtnToggle",Title="显示悬浮按钮",Value=IsMobile,Callback=function(v)if FloatingButtonGui then FloatingButtonGui.Enabled=v end end})
        ut:Divider();ut:Paragraph({Title="🌀 背景效果"});Controls.ParticlesToggle=ut:Toggle({Flag="ParticlesToggle",Title="浮动粒子背景(50个)",Value=true,Callback=function(v)Settings.Particles=v;if v then createParticles()else destroyParticles()end end})
        ut:Divider();ut:Paragraph({Title="✨ 窗口效果"});Controls.AcrylicToggle=ut:Toggle({Flag="AcrylicToggle",Title="毛玻璃效果",Value=true,Callback=function(v)pcall(function()WindUI:ToggleAcrylic(v)end)end});Controls.TransparencyToggle=ut:Toggle({Flag="TransparencyToggle",Title="透明背景增强毛玻璃",Value=true,Callback=function(v)if WindowRef then pcall(function()WindowRef:ToggleTransparency(v)end)end end})
        ut:Divider();ut:Paragraph({Title="🎨 主题系统",Desc="切换主题时粒子颜色自动适配（手动精选配色）"});local allThemes={};pcall(function()allThemes=WindUI:GetThemes()end);local tns={};for n,_ in pairs(allThemes)do table.insert(tns,n)end;table.sort(tns)
        Controls.ThemeDropdown=ut:Dropdown({Flag="ThemeDropdown",Title="选择主题",Values=tns,Value="Dark",Callback=function(sl)if sl then Settings.CurrentTheme=sl;pcall(function()WindUI:SetTheme(sl)end);Settings.ParticleColor=getThemePrimaryColor(sl);updateParticleColor()end end})

        local st=win:Tab({Title="信息统计",Icon="solar:chart-bold"});TabElements.StatGood=st:Paragraph({Title="🟢 好人: 0"});TabElements.StatBad=st:Paragraph({Title="🔴 坏人: 0"});TabElements.StatTotal=st:Paragraph({Title="📊 总计: 0"});st:Divider();TabElements.StatusInput=st:Input({Flag="StatusInputCache",Title="扫描状态",Value="等待中...",Locked=true})

        local ct=win:Tab({Title="配置管理",Icon="solar:diskette-bold"});ct:Paragraph({Title="💾 配置管理",Desc="保存/加载你的所有设置"});local cni=ct:Input({Flag="ConfigNameInput",Title="配置名称",Value="default",Icon="solar:file-text-bold",Callback=function(v)ConfigName=v end});ct:Space();local CM=WindowRef.ConfigManager;local AC={};pcall(function()AC=CM:AllConfigs()end);local DV=nil;pcall(function()for _,v in ipairs(AC)do if v=="default"then DV="default";break end end end);local ACD=ct:Dropdown({Title="已有配置",Desc="选择要加载的配置",Values=AC,Value=DV,Callback=function(v)if v then ConfigName=v;pcall(function()cni:Set(v)end)end end});ct:Space();ct:Button({Title="💾 保存配置",Icon="solar:check-circle-bold",Justify="Center",Color=Color3.fromHex("#305dff"),Callback=function()if not CM then return end;pcall(function()local c=CM:Config(ConfigName);if c and c:Save()then WindUI:Notify({Title="✅ 配置已保存",Content="配置 '"..ConfigName.."' 已保存",Icon="solar:check-circle-bold",Duration=3});ACD:Refresh(CM:AllConfigs())end end)end});ct:Space();ct:Button({Title="📂 加载配置",Icon="solar:refresh-circle-bold",Justify="Center",Color=Color3.fromHex("#10C550"),Callback=function()if not CM then return end;pcall(function()local c=CM:CreateConfig(ConfigName,false);if c and c:Load()then WindUI:Notify({Title="✅ 配置已加载",Content="配置 '"..ConfigName.."' 已加载",Icon="solar:refresh-circle-bold",Duration=3})end end)end});ct:Space();ct:Button({Title="🗑️ 删除配置",Icon="solar:trash-bin-trash-bold",Justify="Center",Color=Color3.fromHex("#ff3040"),Callback=function()if not CM then return end;pcall(function()local c=CM:Config(ConfigName);if c and c:Delete()then WindUI:Notify({Title="🗑️ 配置已删除",Content="配置 '"..ConfigName.."' 已删除",Icon="solar:trash-bin-trash-bold",Duration=3});ACD:Refresh(CM:AllConfigs())end end)end});ct:Divider();ct:Paragraph({Title="💡 提示",Desc="所有带 Flag 的元素自动保存/恢复\n手动清理: 执行 _G.CleanupTemplate()"})

        task.spawn(function()task.wait(1);pcall(function()if CM then local c=CM:CreateConfig("default",true)end end);createParticles()end)

        local at=win:Tab({Title="关于",Icon="solar:info-square-bold"});at:Paragraph({Title="WindUI 脚本模板 v3.3",Desc="三大究极Bug修复: 颜色/穿透/残留"});at:Divider();at:Paragraph({Title="👤 作者",Desc="b站英吉利超入_"});at:Divider();at:Paragraph({Title="💡 使用说明",Desc=IsMobile and"手机: 点击悬浮按钮"or"PC: 按 RightShift 打开菜单"});at:Paragraph({Title="⚠️ 提示",Desc="所有功能默认关闭，请在菜单中手动开启"});at:Paragraph({Title="🧹 清理",Desc="脚本启动时自动清理上次残留\n执行: _G.CleanupTemplate()"})

        if IsMobile then
            task.spawn(function()task.wait(1);pcall(function()FloatingButtonGui=tagTrack(Instance.new("ScreenGui"));FloatingButtonGui.Name="Template_Btn";FloatingButtonGui.Enabled=true;FloatingButtonGui.ResetOnSpawn=false;FloatingButtonGui.Parent=CoreGui;local btn=tagTrack(Instance.new("ImageButton"));btn.Size=UDim2.new(0,50,0,50);btn.Position=UDim2.new(0.9,-25,0.8,-25);btn.BackgroundColor3=Color3.fromRGB(0,180,80);btn.BackgroundTransparency=0.2;btn.BorderSizePixel=0;btn.Parent=FloatingButtonGui;tagTrack(Instance.new("UICorner"));btn.UICorner.CornerRadius=UDim.new(0,25);local t=tagTrack(Instance.new("TextLabel"));t.Size=UDim2.new(1,0,1,0);t.BackgroundTransparency=1;t.Text="👁";t.TextScaled=true;t.Font=Enum.Font.SourceSansBold;t.TextColor3=Color3.fromRGB(255,255,255);t.Parent=btn;local d,ds,sp=false,nil,nil;btn.InputBegan:Connect(function(inp)if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then d=true;ds=inp.Position;sp=btn.Position end end);btn.InputChanged:Connect(function(inp)if d and(inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMovement)then local nx=sp.X.Scale+(inp.Position.X-ds.X)/800;local ny=sp.Y.Scale+(inp.Position.Y-ds.Y)/600;nx=math.max(0.02,math.min(0.95,nx));ny=math.max(0.02,math.min(0.95,ny));btn.Position=UDim2.new(nx,0,ny,0)end end);btn.InputEnded:Connect(function(inp)if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end);btn.MouseButton1Click:Connect(mobileToggleWindow)end)end)
        end
    end
    print("[模板] v3.3 已加载 | 作者: b站英吉利超入_")
else
    print("[模板] WindUI 加载失败");local msg=Instance.new("Message");msg.Text="⚠️ WindUI 加载失败，请重试";msg.Parent=Workspace;task.delay(5,function()msg:Destroy()end)
end
print("[模板] 脚本加载完成")
