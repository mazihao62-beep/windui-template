--[[
    WindUI 通用脚本模板 v5.0
    作者: b站英吉利超入_
    功能: 6Tab标准UI + 粒子背景 + 主题切换 + 配置保存 + OpenButton悬浮按钮
    修复: 用WindUI内置OpenButton替换手工按钮 + OnClose/OnOpen回调
    使用: 搜索"【你的功能】"替换; _G.CleanupTpl()
    注意: 修改disableFunc()以在窗口关闭时禁用你的功能
    
    ===== WindUI 文档链接 =====
    Window: footagesus-windui.mintlify.app/components/window
    Tab: footagesus-windui.mintlify.app/components/tab
    Toggle: footagesus-windui.mintlify.app/components/toggle
    Slider: footagesus-windui.mintlify.app/components/slider
    Input: footagesus-windui.mintlify.app/components/input
    Dropdown: footagesus-windui.mintlify.app/components/dropdown
    Colorpicker: footagesus-windui.mintlify.app/components/colorpicker
    Keybind: footagesus-windui.mintlify.app/components/keybind
    Notification: footagesus-windui.mintlify.app/components/notification
    Dialog: footagesus-windui.mintlify.app/components/dialog
    Popup: footagesus-windui.mintlify.app/components/popup
    Tooltip: footagesus-windui.mintlify.app/components/tooltip
    Config Saving: footagesus-windui.mintlify.app/guides/config-saving
    Icons: footagesus-windui.mintlify.app/guides/icons
    Acrylic: footagesus-windui.mintlify.app/guides/acrylic
    Localization: footagesus-windui.mintlify.app/guides/localization
    
    ===== 易错点速查 =====
    1. Keybind回调返回字符串(如"G")，不是Enum.KeyCode
    2. Toggle:Set(bool)直接传布尔值，不传表格
    3. Input:Set(string)直接传字符串
    4. Slider参数: {Step=1, Value={Min=0, Max=100, Default=50}}
    5. Dropdown:Refresh(新值数组)更新选项
    6. Paragraph:SetTitle("新标题")更新文字
    7. Window:Toggle() / Window:Open() / Window:Close() 控制窗口显隐
    8. OpenButton.OnlyMobile=true 仅手机显示悬浮按钮
    9. OnClose/OnOpen回调在窗口关闭/打开时触发
    10. ToggleKey=Enum.KeyCode.RightShift 默认窗口开关快捷键
]]
local Players=game:GetService("Players");local UIS=game:GetService("UserInputService");local WS=game:GetService("Workspace");local CG=game:GetService("CoreGui")
local IM=UIS.TouchEnabled and not UIS.KeyboardEnabled;if not IM then pcall(function()IM=UIS.TouchEnabled and not UIS.MouseEnabled end)end
local TAG="TplESP_"

local function clean()
    local c=0;pcall(function()
        for _,v in ipairs(CG:GetDescendants())do local ok,a=pcall(function()return v:GetAttribute(TAG)end);if ok and a then pcall(function()v:Destroy()end);c=c+1 end end
        local wc=0;for _,g in ipairs(CG:GetChildren())do if g:IsA("ScreenGui")then local n=g.Name;if n:find("WindUI")then wc=wc+1;if wc>1 then pcall(function()g:Destroy()end);c=c+1 end elseif n:find("Tpl")then pcall(function()g:Destroy()end);c=c+1 end end end
    end);if c>0 then print("[清理]"..c.."个")end
end
clean()
_G.CleanupTpl=function()clean()end

local function tg(v)if v then pcall(function()v:SetAttribute(TAG,true)end)end;return v end
local S={Particles=true,CurrentTheme="Dark",ParticleColor=Color3.fromRGB(80,170,255)}
local TC={dark=Color3.fromRGB(80,170,255),light=Color3.fromRGB(60,130,210),rose=Color3.fromRGB(255,130,170),plant=Color3.fromRGB(70,210,130),ocean=Color3.fromRGB(60,190,240),sunset=Color3.fromRGB(255,160,70),midnight=Color3.fromRGB(130,100,240),forest=Color3.fromRGB(60,180,90),lavender=Color3.fromRGB(190,140,255),coral=Color3.fromRGB(255,140,90),mint=Color3.fromRGB(80,230,190),peanut=Color3.fromRGB(210,180,90),sky=Color3.fromRGB(100,190,255),blood=Color3.fromRGB(230,90,80),lemon=Color3.fromRGB(230,210,70),cyber=Color3.fromRGB(0,235,210)}

local function gtc(n)
    if not n then return Color3.fromRGB(80,170,255)end;local l=n:lower()
    local t=nil;pcall(function()t=WindUI:GetThemes()end)
    if t and t[n]then local d=t[n];local c=nil;pcall(function()if type(d)=="table"then c=d.Primary or d.Accent or d.Color or d.Main end end);if c then return c end end
    local m=TC[l];if m then return m end
    if l:find("dark")or l:find("night")then return Color3.fromRGB(80,170,255)end;if l:find("light")then return Color3.fromRGB(60,130,210)end
    if l:find("rose")or l:find("pink")then return Color3.fromRGB(255,130,170)end
    if l:find("plant")or l:find("green")or l:find("forest")or l:find("mint")then return Color3.fromRGB(70,210,130)end
    if l:find("ocean")or l:find("blue")or l:find("sky")then return Color3.fromRGB(60,190,240)end
    if l:find("sunset")or l:find("orange")or l:find("coral")then return Color3.fromRGB(255,160,70)end
    if l:find("midnight")or l:find("purple")or l:find("lavender")then return Color3.fromRGB(130,100,240)end
    if l:find("blood")or l:find("red")then return Color3.fromRGB(230,90,80)end
    if l:find("lemon")or l:find("yellow")then return Color3.fromRGB(230,210,70)end
    return Color3.fromRGB(80,170,255)
end

local WN=nil;local PC=nil;local CT={};local KB={};local PP=false;local TE={};local CF="default";local PR=false;local PS={};local WF=nil;local PH=nil

-- 【重要】修改此函数以在窗口关闭时禁用你的功能
local function disableFunc()
    -- 示例: 
    -- Settings.Enabled=false
    -- if CT.MyToggle then CT.MyToggle:Set(false) end
    -- for _,o in pairs(ESPObjects) do if o.Highlight then o.Highlight.Enabled=false end end
end

local function fw2()
    WF=nil
    pcall(function()
        for _,g in ipairs(CG:GetChildren())do
            if g:IsA("ScreenGui")and g.Name:find("WindUI")then
                local bs=0;local b=nil
                for _,f in ipairs(g:GetChildren())do if f:IsA("Frame")and f.AbsoluteSize.X>bs then bs=f.AbsoluteSize.X;b=f end end
                if b then WF=b end;return
            end
        end
    end)
    return WF
end

local function cp()
    if PC then pcall(function()PC:Destroy()end);PC=nil end;PS={};PR=false
    if PH then pcall(function()PH:Disconnect()end);PH=nil end
    if not S.Particles then return end
    task.wait(0.5);fw2()
    if not WF then task.spawn(function()task.wait(1);fw2();if WF then cp()end end);return end
    pcall(function()
        PC=Instance.new("Frame");PC.Size=UDim2.new(1,0,1,0);PC.Position=UDim2.new(0,0,0,0);PC.BackgroundTransparency=1;PC.BorderSizePixel=0;PC.ClipsDescendants=true;PC.ZIndex=5;PC.Parent=WF;tg(PC)
        local col=gtc(S.CurrentTheme);local w=WF.AbsoluteSize.X;local h=WF.AbsoluteSize.Y
        for i=1,50 do
            local d=Instance.new("Frame");local sz=math.random(4,8);d.Size=UDim2.new(0,sz,0,sz);d.Position=UDim2.fromOffset(math.random(10,math.max(20,w-10)),math.random(10,math.max(20,h-10)))
            d.BackgroundColor3=col;d.BackgroundTransparency=0.4+math.random()*0.4;d.BorderSizePixel=0;d.ZIndex=5;d.Parent=PC;tg(d)
            Instance.new("UICorner",d).CornerRadius=UDim.new(0,10)
            local a=math.random()*6.28;local sp=0.08+math.random()*0.2
            table.insert(PS,{F=d,Vx=math.cos(a)*sp,Vy=math.sin(a)*sp,Ph=math.random()*6.28,Sz=sz})
        end
        PR=true
        task.spawn(function()
            local t=0
            while PR and PC and PC.Parent do
                t=t+0.03
                pcall(function()
                    local cw=PC.AbsoluteSize.X;local ch=PC.AbsoluteSize.Y
                    if cw<=0 or ch<=0 then return end
                    for _,p in ipairs(PS)do
                        if p.F and p.F.Parent then
                            local x=p.F.Position.X.Offset+p.Vx;local y=p.F.Position.Y.Offset+p.Vy;local sz=p.F.AbsoluteSize.X
                            if x+sz>=cw then x=cw-sz;p.Vx=-p.Vx*0.95 elseif x<0 then x=0;p.Vx=-p.Vx*0.95 end
                            if y+sz>=ch then y=ch-sz;p.Vy=-p.Vy*0.95 elseif y<0 then y=0;p.Vy=-p.Vy*0.95 end
                            p.F.Position=UDim2.fromOffset(x,y);p.F.BackgroundTransparency=0.4+math.sin(t*0.8+p.Ph)*0.25
                            local bs=math.max(1,p.Sz+math.sin(t+p.Ph)*0.8);p.F.Size=UDim2.new(0,bs,0,bs)
                        end
                    end
                end)
                task.wait(0.03)
            end
        end)
    end)
end

local function upc()
    local c=gtc(S.CurrentTheme);if not c or #PS==0 then return end
    pcall(function()for _,p in ipairs(PS)do if p.F and p.F.Parent then p.F.BackgroundColor3=c end end end)
end

local function dp2()
    PR=false;if PH then pcall(function()PH:Disconnect()end);PH=nil end
    if PC then pcall(function()PC:Destroy()end);PC=nil end;PS={}
end

local function bu()
    pcall(function()for _,s in ipairs(CG:GetDescendants())do if s:IsA("ScrollingFrame")then s.ScrollBarThickness=0 end end end)
end
task.spawn(function()while true do task.wait(3);bu()end end)

local WI=nil;local ok,rv=pcall(function()return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()end)
if ok and rv then
    WI=rv;pcall(function()WI:SetTheme("Dark")end);S.ParticleColor=gtc("Dark")
    WI:Popup({Title="WindUI模板 v5.0",Icon="solar:info-square-bold",
        Content="✨ 6Tab标准UI+粒子+主题+配置保存\n🔘 WindUI内置OpenButton悬浮按钮\n修改disableFunc()以在窗口关闭时禁用功能",
        Buttons={{Title="取消",Callback=function()end,Variant="Tertiary"},
            {Title="确认加载",Icon="solar:arrow-right-bold",Callback=function()
                PP=true
                pcall(function()WI:Notify({Title="✅ 已加载",Content="按RightShift打开菜单",Duration=4,Icon="solar:bell-bold"})end)
                task.spawn(function()cw()end)
            end,Variant="Primary"}}})
    
    while not PP do task.wait(0.5)end
    
    function cw()
        if WN then return end
        local ok2,w=pcall(function()return WI:CreateWindow({
            Title="WindUI模板",Author="b站英吉利超入_",Icon="solar:code-bold",
            Size=UDim2.fromOffset(750,520),ToggleKey=Enum.KeyCode.RightShift,
            Folder="windui-template",Acrylic=true,Transparent=true,Resizable=false,
            SideBarWidth=180,ScrollBarEnabled=true,HideSearchBar=true,
            OpenButton={Title="打开菜单",Scale=0.5,Enabled=true,OnlyMobile=true,Draggable=true,
                Color=ColorSequence.new(Color3.fromRGB(0,255,100),Color3.fromRGB(0,200,255)),
                CornerRadius=UDim.new(1,0),StrokeThickness=3},
            OnClose=function()disableFunc();dp2()end,
            OnOpen=function()if S.Particles then task.spawn(function()task.wait(0.8);cp()end)end end
        })end)
        if not ok2 or not w then return end
        WN=w
        
        -- 主控面板
        local mt=WN:Tab({Title="主控面板",Icon="solar:slider-vertical-bold"})
        mt:Paragraph({Title="👁 【你的功能】"})
        mt:Paragraph({Title="💡 Toggle/Slider/Input/Dropdown 都支持Flag自动保存"})
        
        -- 功能设置
        local ft=WN:Tab({Title="功能设置",Icon="solar:settings-bold"})
        ft:Paragraph({Title="🔑 快捷键 (无默认值,需自行绑定)"})
        
        -- UI设置
        local ut=WN:Tab({Title="UI设置",Icon="solar:monitor-bold"})
        ut:Paragraph({Title="⚙️ 界面"})
        CT.WK=ut:Keybind({Flag="WinKB",Title="窗口开关",Value="RightShift",Callback=function(k)KB.WK=k;if WN then pcall(function()WN:SetToggleKey(Enum.KeyCode[k])end)end end})
        ut:Divider()
        ut:Paragraph({Title="🌀 粒子背景"})
        CT.PT=ut:Toggle({Flag="PT",Title="粒子背景",Value=true,Callback=function(v)S.Particles=v;if v then task.spawn(cp)else dp2()end end})
        ut:Divider()
        ut:Paragraph({Title="✨ 窗口效果"})
        CT.AT=ut:Toggle({Flag="AT",Title="毛玻璃",Value=true,Callback=function(v)pcall(function()WI:ToggleAcrylic(v)end)end})
        CT.TT=ut:Toggle({Flag="TT",Title="透明背景",Value=true,Callback=function(v)pcall(function()WI:ToggleAcrylic(v)end)end})
        ut:Divider()
        ut:Paragraph({Title="🎨 主题 (16种内置)"})
        local allT={};pcall(function()allT=WI:GetThemes()end);local tn={};for n,_ in pairs(allT)do table.insert(tn,n)end;table.sort(tn)
        CT.TD=ut:Dropdown({Flag="TD",Title="选择主题",Values=tn,Value="Dark",Callback=function(sl)if sl then S.CurrentTheme=sl;pcall(function()WI:SetTheme(sl)end);S.ParticleColor=gtc(sl);upc()end end})
        
        -- 信息统计
        local st=WN:Tab({Title="信息统计",Icon="solar:chart-bold"})
        TE.GP=st:Paragraph({Title="📊 统计项 1: 0"})
        TE.BP=st:Paragraph({Title="📊 统计项 2: 0"})
        TE.SP=st:Paragraph({Title="📊 统计项 3: 0"})
        st:Divider()
        TE.SI=st:Input({Title="状态",Value="等待中...",Locked=true})
        
        -- 配置管理
        local ct=WN:Tab({Title="配置管理",Icon="solar:diskette-bold"})
        ct:Paragraph({Title="💾 配置 (保存/加载/删除)"})
        local cni=ct:Input({Flag="CN",Title="配置名称",Value="default",Icon="solar:file-text-bold",Callback=function(v)CF=v end});ct:Space()
        local CM=WN.ConfigManager;local AC={};pcall(function()AC=CM:AllConfigs()end)
        local DV=nil;pcall(function()for _,v in ipairs(AC)do if v=="default"then DV="default";break end end end)
        local ACD=ct:Dropdown({Title="已有配置",Values=AC,Value=DV,Callback=function(v)if v then CF=v;pcall(function()cni:Set(v)end)end end});ct:Space()
        ct:Button({Title="💾 保存",Icon="solar:check-circle-bold",Justify="Center",Color=Color3.fromHex("#305dff"),Callback=function()if not CM then return end;pcall(function()local c=CM:Config(CF);if c and c:Save()then WI:Notify({Title="✅ 已保存",Content="配置 '"..CF.."'",Duration=3,Icon="solar:check-circle-bold"});ACD:Refresh(CM:AllConfigs())end end)end});ct:Space()
        ct:Button({Title="📂 加载",Icon="solar:refresh-circle-bold",Justify="Center",Color=Color3.fromHex("#10C550"),Callback=function()if not CM then return end;pcall(function()local c=CM:CreateConfig(CF,false);if c and c:Load()then WI:Notify({Title="✅ 已加载",Content="配置 '"..CF.."'",Duration=3,Icon="solar:refresh-circle-bold"})end end)end});ct:Space()
        ct:Button({Title="🗑️ 删除",Icon="solar:trash-bin-trash-bold",Justify="Center",Color=Color3.fromHex("#ff3040"),Callback=function()if not CM then return end;pcall(function()local c=CM:Config(CF);if c and c:Delete()then WI:Notify({Title="🗑️ 已删除",Content="配置 '"..CF.."'",Duration=3,Icon="solar:trash-bin-trash-bold"});ACD:Refresh(CM:AllConfigs())end end)end})
        task.spawn(function()task.wait(1);pcall(function()if CM then CM:CreateConfig("default",true)end end);task.spawn(cp)end)
        
        -- 关于
        local at=WN:Tab({Title="关于",Icon="solar:info-square-bold"})
        at:Paragraph({Title="WindUI模板 v5.0",Desc="OpenButton+OnClose/OnOpen+WindUI官方API"})
        at:Divider();at:Paragraph({Title="👤 作者",Desc="b站英吉利超入_"})
        at:Divider();at:Paragraph({Title="💡 使用",Desc=IM and"手机: 点击悬浮按钮"or"PC: RightShift打开菜单"})
        at:Paragraph({Title="🧹 清理",Desc="_G.CleanupTpl()"})
        
        print("[v5.0] 已加载")
    end
else
    print("[v5.0] WindUI加载失败")
    local msg=Instance.new("Message");msg.Text="⚠️ WindUI加载失败";msg.Parent=WS;task.delay(3,function()msg:Destroy()end)
end
