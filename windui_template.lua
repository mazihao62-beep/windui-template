-- WindUI 模板 v6.7
-- 作者: b站英吉利超入_
-- 🔧 v6.7: 透明改用 WI.TransparencyValue (对齐官方文档)
-- 🔧 v6.6: 修复毛玻璃溢出(ClipsDescendants裁剪模糊层)
-- 6Tab: 主控面板/功能设置/UI设置/信息统计/配置管理/关于
-- 依赖: WindUI (Footagesus/WindUI)

local WI,rC,mR,LO=nil,0,6,false
while rC<mR do
local ok,r=pcall(function()
return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if ok and r then WI=r;LO=true;break end
rC=rC+1;if rC<mR then task.wait(1.5)end
end
if not LO then return end

local P,U,C=game:GetService("Players"),game:GetService("UserInputService"),game:GetService("CoreGui")
local IM=false
pcall(function()IM=U.TouchEnabled and not U.KeyboardEnabled end)

local function clean()
local c=0
for _,g in ipairs(C:GetChildren())do
if g:IsA("ScreenGui")then
local n=g.Name
if n:find("Tpl_")or n:find("WindUI")then
if n~="Tpl_MobileBtn"and g:GetChildren()and#g:GetChildren()>1 then pcall(function()g:Destroy()end);c=c+1 end
elseif n:find("Tpl")or n:find("ESP_Particles")then pcall(function()g:Destroy()end);c=c+1 end
end
end
end)
if c>0 then print("[清理] "..c.." 个残留实例")end
end
clean()
_G.CleanupTpl=function()clean()end

local S={
Particles=true,
CurrentTheme="Dark",
ParticleColor=Color3.fromRGB(80,170,255)
}
local WN,PC,PP,PR,CF=nil,nil,false,false,"default"
local CT,KB,TE,PS={},{WK="RightShift"},{},{}
local TC={
dark=Color3.fromRGB(80,170,255),light=Color3.fromRGB(60,130,210),
rose=Color3.fromRGB(255,130,170),plant=Color3.fromRGB(70,210,130),
ocean=Color3.fromRGB(60,190,240),sunset=Color3.fromRGB(255,160,70),
midnight=Color3.fromRGB(130,100,240),forest=Color3.fromRGB(60,180,90),
lavender=Color3.fromRGB(190,140,255),coral=Color3.fromRGB(255,140,90),
mint=Color3.fromRGB(80,230,190),sky=Color3.fromRGB(100,190,255),
blood=Color3.fromRGB(230,90,80),lemon=Color3.fromRGB(230,210,70),
cyber=Color3.fromRGB(0,235,210)
}
local function gtc(n)
if not n then return Color3.fromRGB(80,170,255)end
local l=n:lower()
local m=TC[l];if m then return m end
if l:find("dark")then return Color3.fromRGB(80,170,255)end
if l:find("rose")or l:find("pink")then return Color3.fromRGB(255,130,170)end
if l:find("plant")or l:find("green")then return Color3.fromRGB(70,210,130)end
if l:find("ocean")or l:find("blue")then return Color3.fromRGB(60,190,240)end
if l:find("sunset")or l:find("orange")then return Color3.fromRGB(255,160,70)end
if l:find("midnight")or l:find("purple")then return Color3.fromRGB(130,100,240)end
if l:find("blood")or l:find("red")then return Color3.fromRGB(230,90,80)end
if l:find("lemon")or l:find("yellow")then return Color3.fromRGB(230,210,70)end
return Color3.fromRGB(80,170,255)
end
local function disableFunc()end
local function uPC()
local col=S.ParticleColor
for _,p in ipairs(PS)do if p.F and p.F.Parent then p.F.BackgroundColor3=col end end
end
local function cp()
if PC then pcall(function()local p=PC.Parent;if p then p:Destroy()end end);PC=nil end
PS={};PR=false
if not S.Particles then return end
task.wait(0.5)
pcall(function()
local sg=Instance.new("ScreenGui")
sg.Name="Tpl_Particles";sg.ResetOnSpawn=false;sg.DisplayOrder=999999;sg.IgnoreGuiInset=true;sg.Parent=C
PC=Instance.new("Frame")
PC.Size=UDim2.new(1,0,1,0);PC.BackgroundTransparency=1;PC.BorderSizePixel=0;PC.Active=false;PC.Parent=sg
local col=S.ParticleColor
for i=1,50 do
local d=Instance.new("Frame")
local sz=math.random(5,10)
d.Size=UDim2.new(0,sz,0,sz)
local sx=0.2+math.random()*0.6
local sy=0.2+math.random()*0.6
d.Position=UDim2.new(sx,0,sy,0)
d.BackgroundColor3=col;d.BackgroundTransparency=0.3+math.random()*0.5;d.BorderSizePixel=0;d.Parent=PC
Instance.new("UICorner",d).CornerRadius=UDim.new(0,10)
local a=math.random()*6.28
local sp=0.0008+math.random()*0.002
table.insert(PS,{F=d,Sx=sx,Sy=sy,Vx=math.cos(a)*sp,Vy=math.sin(a)*sp,Ph=math.random()*6.28,Sz=sz})
end
PR=true
task.spawn(function()
local t=0
while PR and PC do
t=t+0.03
pcall(function()
local curCol=S.ParticleColor
for _,p in ipairs(PS)do
if p.F and p.F.Parent then
local sx=math.max(0.05,math.min(0.95,p.Sx+p.Vx))
local sy=math.max(0.05,math.min(0.95,p.Sy+p.Vy))
if sx>=0.95 or sx<=0.05 then p.Vx=-p.Vx end
if sy>=0.95 or sy<=0.05 then p.Vy=-p.Vy end
p.Sx=sx;p.Sy=sy
p.F.Position=UDim2.new(sx,0,sy,0)
if curCol~=p.F.BackgroundColor3 then p.F.BackgroundColor3=curCol end
p.F.BackgroundTransparency=0.3+math.sin(t*0.8+p.Ph)*0.4
local bs=math.max(2,p.Sz+math.sin(t+p.Ph)*1.5)
p.F.Size=UDim2.new(0,bs,0,bs)
end
end
end)
task.wait(0.03)
end
end)
end)
end
local function dp2()
PR=false
if PC then pcall(function()local p=PC.Parent;if p then p:Destroy()end end);PC=nil end
PS={}
end
local function makeMobileBtn()
if not IM then return end
task.spawn(function()
while not WN do task.wait(0.1)end
local sg=Instance.new("ScreenGui")
sg.Name="Tpl_MobileBtn";sg.ResetOnSpawn=false;sg.Parent=C
local btn=Instance.new("ImageButton")
btn.Size=UDim2.new(0,50,0,50);btn.Position=UDim2.new(0.85,0,0.6,0);btn.BackgroundColor3=Color3.fromRGB(0,255,100)
btn.BackgroundTransparency=0.2;btn.BorderSizePixel=0;btn.Parent=sg
Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
local lbl=Instance.new("TextLabel")
lbl.Text="?";lbl.TextScaled=true;lbl.Size=UDim2.new(1,0,1,0);lbl.BackgroundTransparency=1;lbl.TextColor3=Color3.new(1,1,1)
lbl.Font=Enum.Font.SourceSansBold;lbl.Parent=btn
local dragging=false;local startPos=nil;local startOffset=nil
btn.InputBegan:Connect(function(input)
if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
local pos=U:GetMouseLocation()
dragging=true;startPos=Vector2.new(pos.X,pos.Y);startOffset=btn.Position
end
end)
btn.InputEnded:Connect(function(input)
if not dragging then
pcall(function()
if WN then WN:Toggle()end
end)
end
dragging=false
end)
U.InputChanged:Connect(function(input)
if dragging and input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement then
local pos=U:GetMouseLocation()
local dx=pos.X-startPos.X;local dy=pos.Y-startPos.Y
local vp=workspace.CurrentCamera.ViewportSize
local sx=math.max(0.02,math.min(0.95,(startOffset.X.Scale+dx/vp.X)))
local sy=math.max(0.02,math.min(0.95,(startOffset.Y.Scale+dy/vp.Y)))
btn.Position=UDim2.new(sx,0,sy,0)
end
end)
print("[模板] 手机悬浮按钮已创建")
end)
end
local function cw()
if WN then return end
local ok2,w=pcall(function()
return WI:CreateWindow({
Title="WindUI模板",
Author="b站英吉利超入_",
Icon="solar:code-bold",
Size=UDim2.fromOffset(750,520),
ToggleKey=Enum.KeyCode.RightShift,
Folder="windui-template",
Acrylic=true,
Transparent=true,
Resizable=false,
SideBarWidth=180,
ScrollBarEnabled=true,
HideSearchBar=true,
OnClose=function()disableFunc();dp2()end,
OnOpen=function()if S.Particles then task.spawn(function()task.wait(0.5);cp()end)end end
})
end)
if not ok2 or not w then return end
WN=w
task.spawn(function()task.wait(0.8);pcall(function()if WN and WN.Parent then WN.Parent.ClipsDescendants=true;print("[v6.7] ✅ ClipsDescendants已应用(毛玻璃裁剪)")end end)end)
task.spawn(function()
task.wait(0.5)
pcall(function()WN:SetToggleKey(Enum.KeyCode.RightShift)end)
end)
makeMobileBtn()
-- 手动快捷键监听（兜底，WindUI内部ToggleKey可能失效）
task.spawn(function()
task.wait(1.5)
U.InputBegan:Connect(function(input,gpe)
if gpe then return end
if input.UserInputType~=Enum.UserInputType.Keyboard then return end
local kn=input.KeyCode and input.KeyCode.Name or ""
if kn==KB.WK and WN then
pcall(function()WN:Toggle()end)
end
end)
end)
local mt=WN:Tab({Title="主控面板",Icon="solar:slider-vertical-bold"})
local ft=WN:Tab({Title="功能设置",Icon="solar:settings-bold"})
local ut=WN:Tab({Title="UI设置",Icon="solar:monitor-bold"})
ut:Paragraph({Title="⚙️ 快捷键"})
CT.WK=ut:Keybind({
Flag="WinKB",
Title="窗口开关",
Value="RightShift",
Callback=function(k)
KB.WK=k
if WN then
pcall(function()
local kc=Enum.KeyCode[k]
if not kc then kc=Enum.KeyCode.RightShift end
WN:SetToggleKey(kc)
end)
end
end
})
ut:Divider()
ut:Paragraph({Title="🌀 粒子背景"})
CT.PT=ut:Toggle({
Flag="PT",
Title="粒子背景",
Value=true,
Callback=function(v)S.Particles=v;if v then task.spawn(cp)else dp2()end end
})
ut:Divider()
ut:Paragraph({Title="✨ 窗口效果"})
CT.AT=ut:Toggle({
Flag="AT",
Title="毛玻璃",
Value=true,
Callback=function(v)pcall(function()WI:ToggleAcrylic(v)end)end
})
CT.TT=ut:Toggle({
Flag="TT",
Title="透明背景",
Value=true,
Callback=function(v)WI.TransparencyValue=v and 0.15 or 0 end
})
ut:Divider()
ut:Paragraph({Title="🎨 主题"})
local allT={}
pcall(function()allT=WI:GetThemes()end)
local tn={}
for n,_ in pairs(allT)do table.insert(tn,n)end
table.sort(tn)
CT.TD=ut:Dropdown({
Flag="TD",
Title="选择主题",
Values=tn,
Value="Dark",
Callback=function(sl)
if sl and type(sl)=="string"then
S.CurrentTheme=sl
WI:SetTheme(sl)
S.ParticleColor=gtc(sl)
uPC()
end
end
})
local st=WN:Tab({Title="信息统计",Icon="solar:chart-bold"})
TE.Item1=st:Paragraph({Title="📊 统计项 1: 0"})
TE.Item2=st:Paragraph({Title="📊 统计项 2: 0"})
TE.Item3=st:Paragraph({Title="📊 统计项 3: 0"})
local ct=WN:Tab({Title="配置管理",Icon="solar:diskette-bold"})
local cni=ct:Input({Flag="CN",Title="配置名称",Value="default",Icon="solar:file-text-bold",Callback=function(v)CF=v end})
ct:Space()
local CM=WN.ConfigManager
local AC={}
pcall(function()AC=CM:AllConfigs()end)
local DV=nil
pcall(function()for _,v in ipairs(AC)do if v=="default"then DV="default";break end end end)
local ACD=ct:Dropdown({Title="已有配置",Values=AC,Value=DV,Callback=function(v)if v then CF=v;cni:Set(v)end end})
ct:Space()
ct:Button({Title="💾 保存",Icon="solar:check-circle-bold",Justify="Center",Color=Color3.fromHex("#305dff"),
Callback=function()if not CM then return end;local c=CM:Config(CF)
if c and c:Save()then WI:Notify({Title="✅ 已保存",Content="配置 '"..CF.."'",Duration=3,Icon="solar:check-circle-bold"});ACD:Refresh(CM:AllConfigs())end end})
ct:Space()
ct:Button({Title="📂 加载",Icon="solar:refresh-circle-bold",Justify="Center",Color=Color3.fromHex("#10C550"),
Callback=function()if not CM then return end;local c=CM:CreateConfig(CF,false)
if c and c:Load()then WI:Notify({Title="✅ 已加载",Content="配置 '"..CF.."'",Duration=3,Icon="solar:refresh-circle-bold"})end end})
ct:Space()
ct:Button({Title="🗑️ 删除",Icon="solar:trash-bin-trash-bold",Justify="Center",Color=Color3.fromHex("#ff3040"),
Callback=function()if not CM then return end;local c=CM:Config(CF)
if c and c:Delete()then WI:Notify({Title="🗑️ 已删除",Content="配置 '"..CF.."'",Duration=3,Icon="solar:trash-bin-trash-bold"});ACD:Refresh(CM:AllConfigs())end end})
task.spawn(function()task.wait(1);pcall(function()CM:CreateConfig("default",true)end);task.spawn(cp)end)
local at=WN:Tab({Title="关于",Icon="solar:info-square-bold"})
at:Paragraph({Title="WindUI模板 v6.7",Desc="毛玻璃裁剪 + 透明改用TransparencyValue"})
at:Divider()
at:Paragraph({Title="👤 作者",Desc="b站英吉利超入_"})
at:Divider()
at:Paragraph({Title="💡 使用",Desc=IM and"手机:点击悬浮按钮"or"PC:RightShift打开菜单"})
at:Paragraph({Title="🧹 清理",Desc="_G.CleanupTpl()"})
print("[v6.7] WindUI模板已加载")
end
pcall(function()WI:SetTheme("Dark")end)
S.ParticleColor=gtc("Dark")
WI:Popup({
Title="WindUI模板 v6.7",
Icon="solar:info-square-bold",
Content="✨ 6Tab标准UI框架\n🌀 粒子背景\n🎨 16种主题\n💾 配置保存\n✂️ 毛玻璃裁剪\n🔧 透明修复(v6.7)",
Buttons={
{Title="取消",Callback=function()end,Variant="Tertiary"},
{Title="确认加载",Icon="solar:arrow-right-bold",Callback=function()
PP=true
WI:Notify({Title="✅ 已加载",Content="按RightShift打开菜单",Duration=4,Icon="solar:bell-bold"})
task.spawn(cw)
end,Variant="Primary"}
}
})
while not PP do task.wait(0.5)end
