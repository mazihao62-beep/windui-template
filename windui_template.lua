--[[
    WindUI 通用脚本模板 v6.0
    纯UI模板 — 不含任何具体功能，只提供UI框架
    作者: b站英吉利超入_
    功能: 6Tab标准UI + 粒子背景(Scale坐标) + 主题切换 + 配置保存 + OpenButton
    使用: 见尾部「模板使用指南」
    清理: _G.CleanupTpl()
]]

-- ========== 基础服务 ==========
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local WS = game:GetService("Workspace")
local CG = game:GetService("CoreGui")
local IM = UIS.TouchEnabled and not UIS.KeyboardEnabled
if not IM then pcall(function() IM = UIS.TouchEnabled and not UIS.MouseEnabled end) end

local TAG = "TplESP_"

-- ========== 清理系统(启动时自动清除上次残留) ==========
local function clean()
    local c = 0
    pcall(function()
        -- 清除带TAG标记的旧实例
        for _, v in ipairs(CG:GetDescendants()) do
            local ok, a = pcall(function() return v:GetAttribute(TAG) end)
            if ok and a then pcall(function() v:Destroy() end); c = c + 1 end
        end
        -- 清除多余的WindUI实例
        local wc = 0
        for _, g in ipairs(CG:GetChildren()) do
            if g:IsA("ScreenGui") then
                local n = g.Name
                if n:find("WindUI") then
                    wc = wc + 1
                    if wc > 1 then pcall(function() g:Destroy() end); c = c + 1 end
                elseif n:find("Tpl") or n:find("ESP_Particles") then
                    pcall(function() g:Destroy() end); c = c + 1
                end
            end
        end
    end)
    if c > 0 then print("[清理] " .. c .. " 个残留实例") end
end
clean()
_G.CleanupTpl = function() clean() end

-- ========== 辅助函数(给实例打标记,方便清理) ==========
local function tg(v)
    if v then pcall(function() v:SetAttribute(TAG, true) end) end
    return v
end

-- ========== 设置表 ==========
local S = {
    Particles = true,
    CurrentTheme = "Dark",
    ParticleColor = Color3.fromRGB(80, 170, 255),
}
-- 【添加你的设置项】: 例如: Enabled = false, MaxRange = 500

-- ========== 主题色映射 ==========
local TC = {
    dark = Color3.fromRGB(80, 170, 255), light = Color3.fromRGB(60, 130, 210),
    rose = Color3.fromRGB(255, 130, 170), plant = Color3.fromRGB(70, 210, 130),
    ocean = Color3.fromRGB(60, 190, 240), sunset = Color3.fromRGB(255, 160, 70),
    midnight = Color3.fromRGB(130, 100, 240), forest = Color3.fromRGB(60, 180, 90),
    lavender = Color3.fromRGB(190, 140, 255), coral = Color3.fromRGB(255, 140, 90),
    mint = Color3.fromRGB(80, 230, 190), peanut = Color3.fromRGB(210, 180, 90),
    sky = Color3.fromRGB(100, 190, 255), blood = Color3.fromRGB(230, 90, 80),
    lemon = Color3.fromRGB(230, 210, 70), cyber = Color3.fromRGB(0, 235, 210),
}

-- 获取主题主色(供粒子使用)
local function gtc(n)
    if not n then return Color3.fromRGB(80, 170, 255) end
    local l = n:lower()
    local t = nil; pcall(function() t = WindUI:GetThemes() end)
    if t and t[n] then
        local d = t[n]; local c = nil
        pcall(function() if type(d) == "table" then c = d.Primary or d.Accent or d.Color or d.Main end end)
        if c then return c end
    end
    local m = TC[l]; if m then return m end
    if l:find("dark") or l:find("night") then return Color3.fromRGB(80, 170, 255) end
    if l:find("light") then return Color3.fromRGB(60, 130, 210) end
    if l:find("rose") or l:find("pink") then return Color3.fromRGB(255, 130, 170) end
    if l:find("plant") or l:find("green") or l:find("forest") or l:find("mint") then return Color3.fromRGB(70, 210, 130) end
    if l:find("ocean") or l:find("blue") or l:find("sky") then return Color3.fromRGB(60, 190, 240) end
    if l:find("sunset") or l:find("orange") or l:find("coral") then return Color3.fromRGB(255, 160, 70) end
    if l:find("midnight") or l:find("purple") or l:find("lavender") then return Color3.fromRGB(130, 100, 240) end
    if l:find("blood") or l:find("red") then return Color3.fromRGB(230, 90, 80) end
    if l:find("lemon") or l:find("yellow") then return Color3.fromRGB(230, 210, 70) end
    return Color3.fromRGB(80, 170, 255)
end

local WN = nil  -- 窗口引用
local PC = nil  -- 粒子容器
local CT = {}   -- 控件引用(TC.ESP, CT.BO...)
local KB = {}   -- 快捷键
local PP = false -- Popup已确认
local TE = {}   -- 统计Tab的Paragraph引用
local CF = "default" -- 配置名
local PR = false -- 粒子运行中
local PS = {}   -- 粒子表

-- ========== 用户功能函数(请在此添加你的代码) ==========

-- 【窗口关闭时禁用你的功能】
local function disableFunc()
    -- 例: S.Enabled = false; refreshAllESP()
end

-- 【你的功能: 扫描/更新逻辑】
-- 例: 遍历Workspace找NPC, makeESP(), classify() ...

-- ========== 粒子系统 ==========

-- 更新粒子颜色(主题切换时自动调用)
local function updateParticleColors()
    local col = S.ParticleColor
    for _, p in ipairs(PS) do
        if p.F and p.F.Parent then p.F.BackgroundColor3 = col end
    end
end

-- 创建粒子(Scale坐标 0~1, 永不卡边界)
local function cp()
    if PC then pcall(function() local p = PC.Parent; if p then p:Destroy() end end); PC = nil end
    PS = {}; PR = false
    if not S.Particles then return end
    task.wait(0.5)
    pcall(function()
        local sg = Instance.new("ScreenGui"); sg.Name = "Tpl_Particles"
        sg.ResetOnSpawn = false; sg.DisplayOrder = 999999
        sg.IgnoreGuiInset = true; sg.Parent = CG
        PC = Instance.new("Frame"); PC.Size = UDim2.new(1, 0, 1, 0)
        PC.BackgroundTransparency = 1; PC.BorderSizePixel = 0; PC.Active = false; PC.Parent = sg
        local col = S.ParticleColor
        for i = 1, 50 do
            local d = Instance.new("Frame"); local sz = math.random(5, 10)
            d.Size = UDim2.new(0, sz, 0, sz)
            local sx = 0.2 + math.random() * 0.6; local sy = 0.2 + math.random() * 0.6
            d.Position = UDim2.new(sx, 0, sy, 0)
            d.BackgroundColor3 = col; d.BackgroundTransparency = 0.3 + math.random() * 0.5
            d.BorderSizePixel = 0; d.Parent = PC
            Instance.new("UICorner", d).CornerRadius = UDim.new(0, 10)
            local a = math.random() * 6.28; local sp = 0.0008 + math.random() * 0.002
            table.insert(PS, {
                F = d, Sx = sx, Sy = sy, Vx = math.cos(a) * sp, Vy = math.sin(a) * sp,
                Ph = math.random() * 6.28, Sz = sz,
            })
        end
        PR = true
        task.spawn(function()
            local t = 0
            while PR and PC do
                t = t + 0.03
                pcall(function()
                    local curCol = S.ParticleColor
                    for _, p in ipairs(PS) do
                        if p.F and p.F.Parent then
                            local sx = math.max(0.05, math.min(0.95, p.Sx + p.Vx))
                            local sy = math.max(0.05, math.min(0.95, p.Sy + p.Vy))
                            if sx >= 0.95 or sx <= 0.05 then p.Vx = -p.Vx end
                            if sy >= 0.95 or sy <= 0.05 then p.Vy = -p.Vy end
                            p.Sx = sx; p.Sy = sy
                            p.F.Position = UDim2.new(sx, 0, sy, 0)
                            if curCol ~= p.F.BackgroundColor3 then p.F.BackgroundColor3 = curCol end
                            p.F.BackgroundTransparency = 0.3 + math.sin(t * 0.8 + p.Ph) * 0.4
                            local bs = math.max(2, p.Sz + math.sin(t + p.Ph) * 1.5)
                            p.F.Size = UDim2.new(0, bs, 0, bs)
                        end
                    end
                end)
                task.wait(0.03)
            end
        end)
    end)
end

-- 销毁粒子
local function dp2()
    PR = false
    if PC then pcall(function() local p = PC.Parent; if p then p:Destroy() end end); PC = nil end
    PS = {}
end

-- ========== 创建窗口 ==========
local function cw()
    if WN then return end
    local ok2, w = pcall(function()
        return WI:CreateWindow({
            Title = "WindUI模板",
            Author = "b站英吉利超入_",
            Icon = "solar:code-bold",
            Size = UDim2.fromOffset(750, 520),
            ToggleKey = Enum.KeyCode.RightShift,
            Folder = "windui-template",
            Acrylic = true,
            Transparent = true,
            Resizable = false,
            SideBarWidth = 180,
            ScrollBarEnabled = true,
            HideSearchBar = true,
            OpenButton = {
                Title = "打开菜单",
                Scale = 0.5,
                Enabled = true,
                OnlyMobile = IM,
                Draggable = true,
                Color = ColorSequence.new(Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 200, 255)),
                CornerRadius = UDim.new(1, 0),
                StrokeThickness = 3,
            },
            OnClose = function()
                disableFunc()
                dp2()
            end,
            OnOpen = function()
                if S.Particles then
                    task.spawn(function() task.wait(0.5); cp() end)
                end
            end,
        })
    end)
    if not ok2 or not w then return end
    WN = w

    -- ===== Tab 1: 主控面板 =====
    local mt = WN:Tab({ Title = "主控面板", Icon = "solar:slider-vertical-bold" })
    -- 【在此添加你的功能控件】
    -- 例: CT.ESP = mt:Toggle({Flag="ESP", Title="透视开关", Value=false, Callback=function(v) S.Enabled=v end})

    -- ===== Tab 2: 功能设置 =====
    local ft = WN:Tab({ Title = "功能设置", Icon = "solar:settings-bold" })
    -- 【在此添加快捷键绑定】
    -- 例: CT.EK = ft:Keybind({Flag="ESPK", Title="透视快捷键", Value="", Callback=function(k) KB.ESP=k end})

    -- ===== Tab 3: UI设置 =====
    local ut = WN:Tab({ Title = "UI设置", Icon = "solar:monitor-bold" })
    ut:Paragraph({ Title = "⚙️ 快捷键" })
    CT.WK = ut:Keybind({
        Flag = "WinKB", Title = "窗口开关", Value = "RightShift",
        Callback = function(k)
            KB.WK = k
            if WN then pcall(function() WN:SetToggleKey(Enum.KeyCode[k]) end) end
        end
    })
    ut:Divider()
    ut:Paragraph({ Title = "🌀 粒子背景" })
    CT.PT = ut:Toggle({
        Flag = "PT", Title = "粒子背景", Value = true,
        Callback = function(v) S.Particles = v; if v then task.spawn(cp) else dp2() end end
    })
    ut:Divider()
    ut:Paragraph({ Title = "✨ 窗口效果" })
    CT.AT = ut:Toggle({
        Flag = "AT", Title = "毛玻璃(Acrylic)", Value = true,
        Callback = function(v) pcall(function() WI:ToggleAcrylic(v) end) end
    })
    CT.TT = ut:Toggle({
        Flag = "TT", Title = "透明背景", Value = true,
        Callback = function(v) pcall(function() if WN then pcall(function() WN:ToggleTransparency(v) end) end end) end
    })
    ut:Divider()
    ut:Paragraph({ Title = "🎨 主题" })
    local allT = {}; pcall(function() allT = WI:GetThemes() end)
    local tn = {}; for n, _ in pairs(allT) do table.insert(tn, n) end; table.sort(tn)
    CT.TD = ut:Dropdown({
        Flag = "TD", Title = "选择主题", Values = tn, Value = "Dark",
        Callback = function(sl)
            if sl and type(sl) == "string" then
                S.CurrentTheme = sl; pcall(function() WI:SetTheme(sl) end)
                S.ParticleColor = gtc(sl); updateParticleColors()
            end
        end
    })

    -- ===== Tab 4: 信息统计 =====
    local st = WN:Tab({ Title = "信息统计", Icon = "solar:chart-bold" })
    -- 【在此添加统计显示项】
    TE.GP = st:Paragraph({ Title = "📊 统计项 1: 0" })
    TE.BP = st:Paragraph({ Title = "📊 统计项 2: 0" })
    TE.SP = st:Paragraph({ Title = "📊 统计项 3: 0" })
    st:Divider()
    -- 可添加Locked Input用于显示状态: st:Input({Title="状态", Value="等待中...", Locked=true})

    -- ===== Tab 5: 配置管理 =====
    local ct = WN:Tab({ Title = "配置管理", Icon = "solar:diskette-bold" })
    local cni = ct:Input({
        Flag = "CN", Title = "配置名称", Value = "default",
        Icon = "solar:file-text-bold", Callback = function(v) CF = v end
    }); ct:Space()
    local CM = WN.ConfigManager
    local AC = {}; pcall(function() AC = CM:AllConfigs() end)
    local DV = nil
    pcall(function() for _, v in ipairs(AC) do if v == "default" then DV = "default"; break end end end)
    local ACD = ct:Dropdown({
        Title = "已有配置", Values = AC, Value = DV,
        Callback = function(v) if v then CF = v; pcall(function() cni:Set(v) end) end end
    }); ct:Space()
    ct:Button({
        Title = "💾 保存", Icon = "solar:check-circle-bold", Justify = "Center",
        Color = Color3.fromHex("#305dff"),
        Callback = function()
            if not CM then return end
            pcall(function()
                local c = CM:Config(CF)
                if c and c:Save() then
                    WI:Notify({ Title = "✅ 已保存", Content = "配置 '" .. CF .. "'", Duration = 3, Icon = "solar:check-circle-bold" })
                    ACD:Refresh(CM:AllConfigs())
                end
            end)
        end
    }); ct:Space()
    ct:Button({
        Title = "📂 加载", Icon = "solar:refresh-circle-bold", Justify = "Center",
        Color = Color3.fromHex("#10C550"),
        Callback = function()
            if not CM then return end
            pcall(function()
                local c = CM:CreateConfig(CF, false)
                if c and c:Load() then
                    WI:Notify({ Title = "✅ 已加载", Content = "配置 '" .. CF .. "'", Duration = 3, Icon = "solar:refresh-circle-bold" })
                end
            end)
        end
    }); ct:Space()
    ct:Button({
        Title = "🗑️ 删除", Icon = "solar:trash-bin-trash-bold", Justify = "Center",
        Color = Color3.fromHex("#ff3040"),
        Callback = function()
            if not CM then return end
            pcall(function()
                local c = CM:Config(CF)
                if c and c:Delete() then
                    WI:Notify({ Title = "🗑️ 已删除", Content = "配置 '" .. CF .. "'", Duration = 3, Icon = "solar:trash-bin-trash-bold" })
                    ACD:Refresh(CM:AllConfigs())
                end
            end)
        end
    })
    -- 自动加载默认配置 + 启动粒子
    task.spawn(function()
        task.wait(1)
        pcall(function() if CM then CM:CreateConfig("default", true) end end)
        task.spawn(cp)
    end)

    -- ===== Tab 6: 关于 =====
    local at = WN:Tab({ Title = "关于", Icon = "solar:info-square-bold" })
    at:Paragraph({ Title = "WindUI模板 v6.0", Desc = "纯UI框架" })
    at:Divider()
    at:Paragraph({ Title = "👤 作者", Desc = "b站英吉利超入_" })
    at:Divider()
    at:Paragraph({ Title = "💡 使用", Desc = IM and "手机: 点击悬浮按钮" or "PC: RightShift打开菜单" })
    at:Paragraph({ Title = "🧹 清理", Desc = "_G.CleanupTpl()" })

    print("[v6.0] WindUI模板已加载")
end

-- ========== 加载WindUI ==========
local WI = nil
local ok, rv = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if ok and rv then
    WI = rv
    pcall(function() WI:SetTheme("Dark") end)
    S.ParticleColor = gtc("Dark")
    WI:Popup({
        Title = "WindUI模板 v6.0",
        Icon = "solar:info-square-bold",
        Content = "✨ 6Tab标准UI框架\n🔘 WindUI内置OpenButton\n🌀 粒子背景(Scale坐标)\n🎨 16种主题\n💾 配置保存系统",
        Buttons = {
            { Title = "取消", Callback = function() end, Variant = "Tertiary" },
            {
                Title = "确认加载", Icon = "solar:arrow-right-bold",
                Callback = function()
                    PP = true
                    pcall(function()
                        WI:Notify({ Title = "✅ 已加载", Content = "按RightShift打开菜单", Duration = 4, Icon = "solar:bell-bold" })
                    end)
                    task.spawn(cw)
                end,
                Variant = "Primary"
            },
        }
    })
    while not PP do task.wait(0.5) end
else
    print("[v6.0] WindUI加载失败")
    local msg = Instance.new("Message")
    msg.Text = "⚠️ WindUI加载失败"
    msg.Parent = WS
    task.delay(3, function() msg:Destroy() end)
end
