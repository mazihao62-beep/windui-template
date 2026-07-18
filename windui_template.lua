--[[
    WindUI 通用脚本模板 v3.4（开箱即用版）
    
    v3.4 同步修复8个UI Bug（与v12.4一致）:
    A: findWindowMainFrame() 双保险搜索窗口Frame
    B: win.OnClose/OnOpen 改用轮询检测窗口可见性
    C: 初始粒子颜色与Dark主题一致
    D: 透明度改用 WindUI.TransparencyValue
    E: PC端也创建半透明悬浮按钮（默认隐藏）
    F: 清理旧WindUI实例
    G: 移除无用变量
    I: ESP扫描循环可停止
    
    作者: b站英吉利超入_
    WindUI加载: https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua
]]

-- ========= 服务 ==========
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if not IsMobile then pcall(function() IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled end) end

-- ========= 启动清理 ==========
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
        -- Bug F: 清理旧WindUI实例（保留最新的）
        local winduiCount = 0
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:find("WindUI") then
                winduiCount = winduiCount + 1
                if winduiCount > 1 then
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
    if not inst then return nil end
    pcall(function() inst:SetAttribute(TAG_NAME, true) end)
    return inst
end

-- ========= 设置 ==========
local Settings = {
    Particles = true, CurrentTheme = "Dark", ParticleColor = Color3.fromRGB(80, 170, 255), -- Bug C
}

-- ========= 主题色 ==========
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

local function nameToColor(n)
    local h=0;for i=1,#n do h=h+string.byte(n,i)end
    return Color3.fromRGB(math.floor(80+math.sin(h*137.5)*0.5*175+0.5),math.floor(100+math.sin(h*73.1+50)*0.5*155+0.5),math.floor(130+math.sin(h*41.7)*0.5*125+0.5))
end

local function getThemePrimaryColor(name)
    if not name then return Color3.fromRGB(80,170,255) end;local l=name:lower()
    local themes=nil;pcall(function()themes=WindUI:GetThemes()end)
    if themes and themes[name] then local d=themes[name];local c=nil;pcall(function()if type(d)=="table" then c=d.Primary or d.Accent or d.Color or d.Main end end);if c then return c end end
    local m=ThemeColors[l];if m then return m end
    if l:find("dark")or l:find("night")then return Color3.fromRGB(80,170,255)end;if l:find("light")then return Color3.fromRGB(60,130,210)end;if l:find("rose")or l:find("pink")then return Color3.fromRGB(255,130,170)end;if l:find("plant")or l:find("green")or l:find("forest")or l:find("mint")then return Color3.fromRGB(70,210,130)end;if l:find("ocean")or l:find("blue")or l:find("sky")then return Color3.fromRGB(60,190,240)end;if l:find("sunset")or l:find("orange")or l:find("coral")then return Color3.fromRGB(255,160,70)end;if l:find("midnight")or l:find("purple")or l:find("lavender")then return Color3.fromRGB(130,100,240)end;if l:find("blood")or l:find("red")then return Color3.fromRGB(230,90,80)end;if l:find("lemon")or l:find("yellow")then return Color3.fromRGB(230,210,70)end
    return nameToColor(name)
end

-- ========= 内部变量 ==========
local WindowRef=nil;local FloatingButtonGui=nil;local ParticleContainer=nil
local ParticleRunning=false;local Particles={};local WindowMainFrame=nil;local ParticleHeartbeat=nil;local PopupConfirmed=false
local Controls={};local Keybinds={};local TabElements={};local ConfigName="default";local WindowVisiblePoll=false

local function mobileToggleWindow()
    if not WindowRef then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.RightShift,false,game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.RightShift,false,game)
    end)
end

-- ========= 粒子系统 ==========
-- Bug A: 双保险搜索窗口
local function findWindowMainFrame()
    WindowMainFrame=nil
    pcall(function()
        for _,gui in ipairs(CoreGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _,f in ipairs(gui:GetChildren()) do
                    if f:IsA("Frame") and f:FindFirstChild("UICorner") then
                        local uc=f:FindFirstChild("UICorner")
                        if uc and uc.CornerRadius==UDim.new(0,8) and f.AbsoluteSize.X>700 then
                            WindowMainFrame=f;return
                        end
                    end
                end
            end
        end
    end)
    if not WindowMainFrame then
        pcall(function()
            for _,gui in ipairs(CoreGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name:find("WindUI") then
                    local bs=0;local bf=nil
                    for _,f in ipairs(gui:GetChildren()) do
                        if f:IsA("Frame") and f.AbsoluteSize.X>bs then
                            bs=f.AbsoluteSize.X;bf=f
                        end
                    end
                    if bf then WindowMainFrame=bf;return end
                end
            end
        end)
    end
    return WindowMainFrame
end

local function getParticleColor() return Settings.ParticleColor or Color3.fromRGB(80,170,255) end

local function createParticles()
    if ParticleContainer then pcall(function()ParticleContainer:Destroy()end);ParticleContainer=nil end
    Particles={};ParticleRunning=false
    if ParticleHeartbeat then pcall(function()ParticleHeartbeat:Disconnect()end);ParticleHeartbeat=nil end
    if not Settings.Particles then return end
    findWindowMainFrame()
    if not WindowMainFrame then
        task.spawn(function()task.wait(1);findWindowMainFrame();if WindowMainFrame then createParticles()end end)
        return
    end
    pcall(function()
        local psg=Instance.new("ScreenGui");psg.Name="Template_ParticleContainer";psg.DisplayOrder=-9999;psg.ResetOnSpawn=false;psg.Parent=CoreGui;tagTrack(psg)
        ParticleContainer=Instance.new("Frame");ParticleContainer.BackgroundTransparency=1;ParticleContainer.BorderSizePixel=0;ParticleContainer.ClipsDescendants=true;ParticleContainer.Parent=psg;tagTrack(ParticleContainer)
        local pos=WindowMainFrame.AbsolutePosition;local size=WindowMainFrame.AbsoluteSize
        ParticleContainer.Position=UDim2.fromOffset(pos.X,pos.Y);ParticleContainer.Size=UDim2.fromOffset(size.X,size.Y)
        ParticleHeartbeat=RunService.Heartbeat:Connect(function()
            if not ParticleContainer or not ParticleContainer.Parent then
                if ParticleHeartbeat then ParticleHeartbeat:Disconnect();ParticleHeartbeat=nil end;return
            end
            if WindowMainFrame and WindowMainFrame.Parent then
                local ap=WindowMainFrame.AbsolutePosition;local as=WindowMainFrame.AbsoluteSize
                ParticleContainer.Position=UDim2.fromOffset(ap.X,ap.Y);ParticleContainer.Size=UDim2.fromOffset(as.X,as.Y)
                ParticleContainer.Visible=WindowMainFrame.Visible
            else
                ParticleContainer.Visible=false;findWindowMainFrame()
            end
        end)
        local c=getParticleColor();local w=size.X;local h=size.Y
        for i=1,50 do
            local dot=Instance.new("Frame");local sz=math.random(4,8)
            dot.Size=UDim2.new(0,sz,0,sz);dot.Position=UDim2.fromOffset(math.random(10,math.max(20,w-10)),math.random(10,math.max(20,h-10)))
            dot.BackgroundColor3=c;dot.BackgroundTransparency=0.4+math.random()*0.4;dot.BorderSizePixel=0;dot.ZIndex=0;dot.Parent=ParticleContainer;tagTrack(dot)
            local cn=Instance.new("UICorner");cn.CornerRadius=UDim.new(0,10);cn.Parent=dot
            local a=math.random()*6.28;local sp=0.1+math.random()*0.3
            table.insert(Particles,{Frame=dot,Vx=math.cos(a)*sp,Vy=math.sin(a)*sp,Phase=math.random()*6.28,SizeBase=sz})
        end
        ParticleRunning=true
        task.spawn(function()
            local t=0
            while ParticleRunning and ParticleContainer and ParticleContainer.Parent do
                t=t+0.03
                pcall(function()
                    local cw=ParticleContainer.AbsoluteSize.X;local ch=ParticleContainer.AbsoluteSize.Y
                    if cw<=0 or ch<=0 then task.wait(0.03);return end
                    for _,p in ipairs(Particles) do
                        if not p.Frame or not p.Frame.Parent then continue end
                        local px=p.Frame.Position;local x=px.X.Offset+p.Vx;local y=px.Y.Offset+p.Vy
                        local sz=p.Frame.AbsoluteSize.X
                        if x+sz>=cw then x=cw-sz;p.Vx=-p.Vx*0.95
                        elseif x<0 then x=0;p.Vx=-p.Vx*0.95 end
                        if y+sz>=ch then y=ch-sz;p.Vy=-p.Vy*0.95
                        elseif y<0 then y=0;p.Vy=-p.Vy*0.95 end
                        p.Frame.Position=UDim2.fromOffset(x,y)
                        p.Frame.BackgroundTransparency=0.4+math.sin(t*0.8+p.Phase)*0.25
                        local bs=math.max(1,p.SizeBase+math.sin(t+p.Phase)*0.8)
                        p.Frame.Size=UDim2.new(0,bs,0,bs)
                    end
                end)
                task.wait(0.03)
            end
        end)
    end)
end

local function updateParticleColor()
    local c=getParticleColor();if not c or #Particles==0 then return end
    pcall(function() for _,p in ipairs(Particles) do if p.Frame and p.Frame.Parent then p.Frame.BackgroundColor3=c end end end)
end

local function destroyParticles()
    ParticleRunning=false
    if ParticleHeartbeat then pcall(function()ParticleHeartbeat:Disconnect()end);ParticleHeartbeat=nil end
    if ParticleContainer then
        pcall(function()local pa=ParticleContainer.Parent;if pa then pcall(function()pa:Destroy()end)end end)
        ParticleContainer=nil
    end
    Particles={}
end

-- Bug B: 窗口可见性轮询
local function startWindowVisibilityPoll()
    WindowVisiblePoll=true
    task.spawn(function()
        local wv=nil
        while WindowVisiblePoll do
            task.wait(0.5)
            pcall(function()
                if not WindowRef then WindowVisiblePoll=false;return end
                local iv=false;local ok1,v1=pcall(function()return WindowRef.Visible end)
                if ok1 then iv=v1 end
                if wv==nil then wv=iv end
                if wv~=iv then
                    if iv then if Settings.Particles then createParticles()end
                    else destroyParticles()end
                    wv=iv
                end
            end)
        end
    end)
end

-- ========= 美化UI ==========
local function beautifyUI()
    pcall(function()
        for _,s in ipairs(CoreGui:GetDescendants()) do
            if s:IsA("ScrollingFrame") then
                s.ScrollBarThickness=14
                s.ScrollBarImageColor3=Color3.fromRGB(220,220,220)
                s.ScrollBarImageTransparency=0.1
            end
        end
    end)
end

task.spawn(function() while true do task.wait(3);beautifyUI() end end)

-- ========= 加载WindUI ==========
local WindUI=nil;local s,r=pcall(function()return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()end)

if s and r then
    WindUI=r;pcall(function()WindUI:SetTheme("Dark")end)
    Settings.ParticleColor = getThemePrimaryColor("Dark") -- Bug C: 初始即匹配Dark

    WindUI:Popup({
        Title="WindUI 脚本模板 v3.4",
        Icon="solar:info-square-bold",
        Content="📋 NPC透视 - 高亮显示 + 头顶标签\n💾 配置保存 - 自动保存/读取设置\n🎨 主题系统 - 16种内置主题一键切换\n✨ 粒子背景 - 窗口内Clips裁剪+追踪窗口位置\n🌀 增强毛玻璃 - Acrylic + 透明叠加\n🧹 即时清理 - 启动时自动清除所有残留\n\n⚠️ 加载后所有功能默认关闭，需手动开启",
        Buttons={
            {Title="取消",Callback=function()end,Variant="Tertiary"},
            {Title="确认加载",Icon="solar:arrow-right-bold",
                Callback=function()
                    PopupConfirmed=true
                    pcall(function() WindUI:Notify({Title="✅ 已加载",Content="⌨️ 按 RightShift 打开菜单",Duration=4,Icon="solar:bell-bold"}) end)
                    task.spawn(function() createWindow() end)
                end,
                Variant="Primary"
            }
        }
    })

    task.spawn(function()
        while not PopupConfirmed do task.wait(0.5) end
        task.wait(0.5)
        beautifyUI()
        task.spawn(function() while true do pcall(function() if TabElements.GoodP and TabElements.BadP and TabElements.TotalP then end end) task.wait(1) end end)
    end)

    function createWindow()
        if WindowRef then return end
        local ok,win=pcall(function()
            return WindUI:CreateWindow({
                Title="WindUI 脚本模板",Author="b站英吉利超入_",Icon="solar:shield-warning-bold",
                Size=UDim2.fromOffset(750,520),ToggleKey=Enum.KeyCode.RightShift,
                Folder="windui-template",Acrylic=true,Transparent=true,
                Resizable=false,SideBarWidth=180,ScrollBarEnabled=true,HideSearchBar=true
            })
        end)
        if not ok or not win then print("[模板] 窗口创建失败:",ok);return end
        WindowRef=win
        pcall(function() WindUI.TransparencyValue = 0.22 end) -- Bug D
        startWindowVisibilityPoll() -- Bug B

        local mt=win:Tab({Title="主控面板",Icon="solar:slider-vertical-bold"})
        mt:Paragraph({Title="👁 【你的功能】控制",Desc="在此添加你的Toggle/Slider等控件"})
        -- 【你的功能】示例:
        -- Controls.YourToggle = mt:Toggle({Flag="YourFlag",Title="功能开关",Value=false,Callback=function(v) end})
        -- mt:Slider({Flag="YourSlider",Title="参数",Step=10,Value={Min=0,Max=100,Default=50},Width=200,IsTextbox=true,Callback=function(v) end})
        mt:Divider()
        mt:Paragraph({Title="💡 提示",Desc="所有带 Flag 的元素自动接入配置保存系统"})

        local ft=win:Tab({Title="功能设置",Icon="solar:settings-bold"})
        ft:Paragraph({Title="🔑 快捷键设置",Desc="在此添加你的快捷键绑定"})
        -- Controls.YourKeybind = ft:Keybind({Flag="YourKeybind",Title="快捷键",Value="",Callback=function(k) Keybinds.YourKey=k end})
        ft:Divider()
        ft:Paragraph({Title="💡 提示",Desc="窗口快捷键在UI设置中绑定（默认 RightShift）"})

        local ut=win:Tab({Title="UI设置",Icon="solar:monitor-bold"})
        ut:Paragraph({Title="⚙️ 界面设置"})
        Controls.WindowKeybind=ut:Keybind({Flag="WindowKeybind",Title="窗口开关快捷键",Value="RightShift",
            Callback=function(k)Keybinds.Window=k;if WindowRef then pcall(function()WindowRef:SetToggleKey(Enum.KeyCode[k])end)end end})
        Controls.FloatingBtnToggle=ut:Toggle({Flag="FloatingBtnToggle",Title="显示悬浮按钮",Value=IsMobile,
            Callback=function(v)if FloatingButtonGui then FloatingButtonGui.Enabled=v end end})
        ut:Divider()
        ut:Paragraph({Title="🌀 背景效果"})
        Controls.ParticlesToggle=ut:Toggle({Flag="ParticlesToggle",Title="浮动粒子背景(50个)",Value=true,
            Callback=function(v)Settings.Particles=v;if v then createParticles()else destroyParticles()end end})
        ut:Divider()
        ut:Paragraph({Title="✨ 窗口效果"})
        Controls.AcrylicToggle=ut:Toggle({Flag="AcrylicToggle",Title="毛玻璃效果",Value=true,
            Callback=function(v)pcall(function()WindUI:ToggleAcrylic(v)end)end})
        Controls.TransparencyToggle=ut:Toggle({Flag="TransparencyToggle",Title="透明背景",Value=true,
            Callback=function(v)if v then pcall(function()WindUI.TransparencyValue=0.22 end)else pcall(function()WindUI.TransparencyValue=0 end)end end})
        ut:Divider()
        ut:Paragraph({Title="🎨 主题系统",Desc="切换主题时粒子颜色自动适配"})
        local allThemes={};pcall(function()allThemes=WindUI:GetThemes()end)
        local themeNames={};for n,_ in pairs(allThemes)do table.insert(themeNames,n)end;table.sort(themeNames)
        Controls.ThemeDropdown=ut:Dropdown({Flag="ThemeDropdown",Title="选择主题",Values=themeNames,Value="Dark",
            Callback=function(selected)
                if selected then Settings.CurrentTheme=selected
                    pcall(function()WindUI:SetTheme(selected)end)
                    Settings.ParticleColor=getThemePrimaryColor(selected)
                    updateParticleColor()
                end
            end})

        local st=win:Tab({Title="信息统计",Icon="solar:chart-bold"})
        -- 【你的功能】统计显示:
        TabElements.GoodP=st:Paragraph({Title="🟢 统计项 1: 0"})
        TabElements.BadP=st:Paragraph({Title="🔴 统计项 2: 0"})
        TabElements.TotalP=st:Paragraph({Title="📊 统计项 3: 0"})
        st:Divider()
        TabElements.StatusInput=st:Input({Title="状态信息",Value="等待中...",Locked=true})

        local ct=win:Tab({Title="配置管理",Icon="solar:diskette-bold"})
        ct:Paragraph({Title="💾 配置管理",Desc="保存/加载你的所有设置"})
        local cni=ct:Input({Flag="ConfigNameInput",Title="配置名称",Value="default",Icon="solar:file-text-bold",
            Callback=function(v)ConfigName=v end})
        ct:Space()
        local CM=WindowRef.ConfigManager
        local AC={};pcall(function()AC=CM:AllConfigs()end)
        local DV=nil;pcall(function()for _,v in ipairs(AC)do if v=="default"then DV="default";break end end end)
        local ACD=ct:Dropdown({Title="已有配置",Desc="选择要加载的配置",Values=AC,Value=DV,
            Callback=function(v)if v then ConfigName=v;pcall(function()cni:Set(v)end)end end})
        ct:Space()
        ct:Button({Title="💾 保存配置",Icon="solar:check-circle-bold",Justify="Center",Color=Color3.fromHex("#305dff"),
            Callback=function()if not CM then return end
                pcall(function()local c=CM:Config(ConfigName);if c and c:Save()then
                    WindUI:Notify({Title="✅ 配置已保存",Content="配置 '"..ConfigName.."' 已保存",Icon="solar:check-circle-bold",Duration=3})
                    ACD:Refresh(CM:AllConfigs())end end)end})
        ct:Space()
        ct:Button({Title="📂 加载配置",Icon="solar:refresh-circle-bold",Justify="Center",Color=Color3.fromHex("#10C550"),
            Callback=function()if not CM then return end
                pcall(function()local c=CM:CreateConfig(ConfigName,false);if c and c:Load()then
                    WindUI:Notify({Title="✅ 配置已加载",Content="配置 '"..ConfigName.."' 已加载",Icon="solar:refresh-circle-bold",Duration=3})end end)end})
        ct:Space()
        ct:Button({Title="🗑️ 删除配置",Icon="solar:trash-bin-trash-bold",Justify="Center",Color=Color3.fromHex("#ff3040"),
            Callback=function()if not CM then return end
                pcall(function()local c=CM:Config(ConfigName);if c and c:Delete()then
                    WindUI:Notify({Title="🗑️ 配置已删除",Content="配置 '"..ConfigName.."' 已删除",Icon="solar:trash-bin-trash-bold",Duration=3})
                    ACD:Refresh(CM:AllConfigs())end end)end})
        ct:Divider()
        ct:Paragraph({Title="💡 提示",Desc="所有带 Flag 的元素自动保存/恢复\n手动清理: 执行 _G.CleanupTemplate()"})

        task.spawn(function()
            task.wait(1)
            pcall(function()if CM then local c=CM:CreateConfig("default",true)end end)
            createParticles()
        end)

        local at=win:Tab({Title="关于",Icon="solar:info-square-bold"})
        at:Paragraph({Title="WindUI 脚本模板 v3.4",Desc="同步修复8个UI Bug"})
        at:Divider()
        at:Paragraph({Title="👤 作者",Desc="b站英吉利超入_"})
        at:Divider()
        at:Paragraph({Title="💡 使用说明",Desc=IsMobile and "手机: 点击悬浮按钮" or "PC: 按 RightShift 打开菜单"})
        at:Paragraph({Title="⚠️ 提示",Desc="所有功能默认关闭，请在菜单中手动开启"})
        at:Paragraph({Title="🧹 清理",Desc="脚本启动时自动清理上次残留\n执行: _G.CleanupTemplate()"})

        -- Bug E: PC也创建悬浮按钮
        task.spawn(function()
            task.wait(1)
            pcall(function()
                FloatingButtonGui=tagTrack(Instance.new("ScreenGui"))
                FloatingButtonGui.Name="Template_Btn"
                FloatingButtonGui.Enabled=IsMobile
                FloatingButtonGui.ResetOnSpawn=false
                FloatingButtonGui.Parent=CoreGui
                local btn=tagTrack(Instance.new("ImageButton"))
                btn.Size=UDim2.new(0,50,0,50);btn.Position=UDim2.new(0.9,-25,0.8,-25)
                btn.BackgroundColor3=Color3.fromRGB(0,180,80);btn.BackgroundTransparency=0.2;btn.BorderSizePixel=0
                btn.Parent=FloatingButtonGui
                tagTrack(Instance.new("UICorner"));btn.UICorner.CornerRadius=UDim.new(0,25)
                local t=tagTrack(Instance.new("TextLabel"))
                t.Size=UDim2.new(1,0,1,0);t.BackgroundTransparency=1;t.Text="👁";t.TextScaled=true
                t.Font=Enum.Font.SourceSansBold;t.TextColor3=Color3.fromRGB(255,255,255);t.Parent=btn
                local d,ds,sp=false,nil,nil
                btn.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then
                        d=true;ds=inp.Position;sp=btn.Position end end)
                btn.InputChanged:Connect(function(inp)
                    if d and(inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseMovement)then
                        local nx=sp.X.Scale+(inp.Position.X-ds.X)/800
                        local ny=sp.Y.Scale+(inp.Position.Y-ds.Y)/600
                        nx=math.max(0.02,math.min(0.95,nx));ny=math.max(0.02,math.min(0.95,ny))
                        btn.Position=UDim2.new(nx,0,ny,0)end end)
                btn.InputEnded:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end)
                btn.MouseButton1Click:Connect(mobileToggleWindow)
            end)
        end)
    end
    print("[模板] v3.4 已加载 | 作者: b站英吉利超入_")
else
    print("[模板] WindUI 加载失败")
    local msg=Instance.new("Message")
    msg.Text="⚠️ WindUI 加载失败，请重试"
    msg.Parent=Workspace
    task.delay(5,function()msg:Destroy()end)
end
print("[模板] 脚本加载完成")
