--[[
    WindUI 通用脚本模板 v6.1
    纯UI框架 — 不含任何具体功能，只提供完整的UI骨架
    作者: b站英吉利超入_
    
    💡 一句话说明:
    这个模板提供了完整的 Roblox WindUI 界面系统，包括:
      6个Tab页面 · 粒子背景 · 16种主题 · 配置保存 · 手机/PC自适应
    你只需要添加你的游戏功能代码，就可以直接使用。
    
    🔗 加载方式:
      loadstring(game:HttpGet("https://raw.githubusercontent.com/mazihao62-beep/windui-template/main/windui_template.lua"))()
    
    🧹 清理残留:
      _G.CleanupTpl()
    
    ⚠️ 所有你需要修改的地方都用 【】 标注了，搜索【就能找到
]]

-- ============================================================================
--  第一部分: 初始化 (不需要修改)
-- ============================================================================
--  作用: 获取Roblox服务、检测平台(手机/PC)、清理上次脚本残留
--  注意: 不要删这里的任何代码

local Players = game:GetService("Players")        -- 玩家服务
local UIS = game:GetService("UserInputService")    -- 输入服务(键盘/触控)
local WS = game:GetService("Workspace")            -- 工作区
local CG = game:GetService("CoreGui")              -- 核心Gui(存放UI的地方)

-- 检测是否为手机端 (手机显示悬浮按钮, PC不显示)
local IM = UIS.TouchEnabled and not UIS.KeyboardEnabled
if not IM then pcall(function() IM = UIS.TouchEnabled and not UIS.MouseEnabled end) end

local TAG = "TplESP_" -- 用于标记脚本创建的实例，方便清理

-- 清理函数: 脚本启动时自动清除上一次留下的残留
-- 包括: 旧的粒子、旧的标签、多余的WindUI窗口
local function clean()
    local c = 0
    pcall(function()
        -- 1. 清除带标记的旧实例 (Highlight, BillboardGui等)
        for _, v in ipairs(CG:GetDescendants()) do
            local ok, a = pcall(function() return v:GetAttribute(TAG) end)
            if ok and a then pcall(function() v:Destroy() end); c = c + 1 end
        end
        -- 2. 清除多余的WindUI窗口 (多次执行脚本会积累多个)
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

-- 打标记函数: 给创建的实例打上TAG标记，方便清理系统找到它们
local function tg(v)
    if v then pcall(function() v:SetAttribute(TAG, true) end) end
    return v
end


-- ============================================================================
--  第二部分: 设置表 S (你需要在这里添加你的设置项)
-- ============================================================================
--  作用: 存储所有开关/数值的当前状态
--  说明: 
--    - 所有控件(Toggle/Slider等)的值都会保存在这里
--    - 配置保存系统会自动保存和恢复这些带 Flag 的控件的值
--    - Particles=粒子开关, CurrentTheme=当前主题, ParticleColor=粒子颜色

local S = {
    Particles = true,          -- 粒子背景开关 (UI设置里控制)
    CurrentTheme = "Dark",     -- 当前主题名
    ParticleColor = Color3.fromRGB(80, 170, 255), -- 粒子颜色(随主题变化)
}
--  ⬇️ 【在此添加你的设置项】 ⬇️  例如:
--    Enabled = false,        -- 功能开关 (默认关闭)
--    MaxRange = 500,         -- 最大距离
--    BadOnly = false,        -- 仅显示坏人
--    ShowDist = false,       -- 显示距离
--    ShowHP = false,         -- 显示血量


-- ============================================================================
--  第三部分: 内部变量 (不需要修改)
-- ============================================================================

local WN = nil  -- 窗口引用 (创建窗口后自动赋值)
local PC = nil  -- 粒子容器 (粒子的父级Frame)
local CT = {}   -- 控件引用表 (用来访问Toggle/Slider等控件, 例如 CT.ESP:Set(true))
local KB = {}   -- 快捷键表 (存储快捷键字符串, 例如 KB.ESP = "G")
local PP = false -- Popup是否已确认 (确认后才会创建窗口)
local TE = {}   -- 统计Tab的Paragraph引用 (用于更新统计数字)
local CF = "default" -- 当前配置名
local PR = false -- 粒子动画是否在运行
local PS = {}   -- 粒子表 (存储所有粒子的位置/速度等数据)


-- ============================================================================
--  第四部分: 主题色映射 (不需要修改)
-- ============================================================================
--  作用: 16种内置主题各自对应的粒子颜色

local TC = {
    dark = Color3.fromRGB(80, 170, 255),    light = Color3.fromRGB(60, 130, 210),
    rose = Color3.fromRGB(255, 130, 170),   plant = Color3.fromRGB(70, 210, 130),
    ocean = Color3.fromRGB(60, 190, 240),   sunset = Color3.fromRGB(255, 160, 70),
    midnight = Color3.fromRGB(130, 100, 240), forest = Color3.fromRGB(60, 180, 90),
    lavender = Color3.fromRGB(190, 140, 255), coral = Color3.fromRGB(255, 140, 90),
    mint = Color3.fromRGB(80, 230, 190),    peanut = Color3.fromRGB(210, 180, 90),
    sky = Color3.fromRGB(100, 190, 255),    blood = Color3.fromRGB(230, 90, 80),
    lemon = Color3.fromRGB(230, 210, 70),   cyber = Color3.fromRGB(0, 235, 210),
}

-- 根据主题名获取主色 (粒子颜色跟随主题)
local function gtc(n)
    if not n then return Color3.fromRGB(80, 170, 255) end
    local l = n:lower()
    -- 优先从WindUI主题定义中获取颜色
    local t = nil; pcall(function() t = WindUI:GetThemes() end)
    if t and t[n] then
        local d = t[n]; local c = nil
        pcall(function() if type(d) == "table" then c = d.Primary or d.Accent or d.Color or d.Main end end)
        if c then return c end
    end
    -- 备选: 从静态映射表中查找
    local m = TC[l]; if m then return m end
    -- 最终备选: 按关键词匹配
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


-- ============================================================================
--  第五部分: 用户功能函数 ⭐ (你需要在这里添加你的功能代码)
-- ============================================================================

--  ⬇️ 【在这里添加你的辅助函数, 例如:】 ⬇️
--  
--  -- 递归搜索嵌套属性 (用于扫描Configuration内部)
--  local function rFind(inst, name)
--      local f = inst:FindFirstChild(name)
--      if f then return f end
--      for _, c in ipairs(inst:GetChildren()) do
--          if c:IsA("Configuration") or c:IsA("Folder") then
--              local r = rFind(c, name)
--              if r then return r end
--          end
--      end
--      return nil
--  end
--
--  -- 分类函数 (判断NPC是好人还是坏人)
--  local function classify(char)
--      -- 检查 Humanoid 属性
--      local hum = char:FindFirstChildOfClass("Humanoid")
--      if hum then
--          -- 先查 NPCType 属性
--          local nt = nil; pcall(function() nt = hum:GetAttribute("NPCType") end)
--          if nt == "Agent" then return "Good" end
--          if nt == "Enemy" then return "Bad" end
--          -- 再查名字
--          local nm = char.Name:lower()
--          if nm:find("警察") or nm:find("police") then return "Good" end
--          if nm:find("恐怖") or nm:find("terrorist") then return "Bad" end
--      end
--      return "Good" -- 默认好人
--  end
--
--  -- 创建ESP (Highlight高亮 + BillboardGui头顶标签)
--  -- (参考 airport-security-esp 仓库的完整实现)


-- ⬇️ 【窗口关闭时禁用你的功能】 ⬇️
--  作用: 当用户关闭窗口时，同时关闭所有功能
local function disableFunc()
    -- 例: S.Enabled = false
    -- 例: for _, o in pairs(H) do if o.bb then o.bb.Enabled = false end end
    -- 例: for _, o in pairs(H) do if o.hl then o.hl.Enabled = false end end
    -- 提示: 记得同步Toggle控件的显示: CT.ESP:Set(false)
end

-- ⬇️ 【你的主循环/扫描函数】 ⬇️
--  作用: 遍历游戏世界，找到目标并创建ESP
--  例:
--  local function doScan()
--      for _, o in ipairs(WS:GetDescendants()) do
--          if o:IsA("Humanoid") then
--              local c = o.Parent
--              -- 跳过玩家自己
--              local isPl = false
--              for _, p in ipairs(Players:GetPlayers()) do
--                  if p.Character == c then isPl = true; break end
--              end
--              if not isPl and S.Enabled then
--                  makeESP(c, classify(c))
--              end
--          end
--      end
--  end


-- ============================================================================
--  第六部分: 粒子系统 (不需要修改)
-- ============================================================================
--  粒子使用 Scale 坐标 (0~1 百分比)，永远不会卡在屏幕边界
--  粒子颜色跟随当前主题自动变化

-- 更新粒子颜色 (主题切换时自动调用)
local function updateParticleColors()
    local col = S.ParticleColor
    for _, p in ipairs(PS) do
        if p.F and p.F.Parent then p.F.BackgroundColor3 = col end
    end
end

-- 创建粒子
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


-- ============================================================================
--  第七部分: 创建窗口 ⭐ (你需要在这里添加你的功能控件)
-- ============================================================================

local function cw()
    if WN then return end
    
    -- 创建WindUI窗口
    local ok2, w = pcall(function()
        return WI:CreateWindow({
            Title = "WindUI模板",         -- 窗口标题
            Author = "b站英吉利超入_",      -- 作者名
            Icon = "solar:code-bold",      -- 窗口图标
            Size = UDim2.fromOffset(750, 520), -- 窗口大小
            ToggleKey = Enum.KeyCode.RightShift, -- 默认开关快捷键 (RightShift)
            Folder = "windui-template",    -- 配置保存文件夹名
            Acrylic = true,                -- 毛玻璃效果
            Transparent = true,            -- 透明背景
            Resizable = false,             -- 不允许调整大小
            SideBarWidth = 180,            -- 侧边栏宽度
            ScrollBarEnabled = true,       -- 启用滚动条
            HideSearchBar = true,          -- 隐藏搜索框
            OpenButton = {                 -- 手机悬浮按钮
                Title = "打开菜单",
                Scale = 0.5,
                Enabled = true,
                OnlyMobile = IM,           -- 仅手机端显示
                Draggable = true,          -- 可拖拽
                Color = ColorSequence.new(Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 200, 255)),
                CornerRadius = UDim.new(1, 0),
                StrokeThickness = 3,
            },
            OnClose = function()           -- 窗口关闭时
                disableFunc()              --   → 禁用功能
                dp2()                       --   → 销毁粒子
            end,
            OnOpen = function()            -- 窗口打开时
                if S.Particles then
                    task.spawn(function() task.wait(0.5); cp() end)  -- → 重建粒子
                end
            end,
        })
    end)
    if not ok2 or not w then return end
    WN = w

    -- ================================================================
    --  Tab 1: 主控面板 ⭐ (在这里添加你的功能开关/滑块)
    -- ================================================================
    local mt = WN:Tab({ Title = "主控面板", Icon = "solar:slider-vertical-bold" })
    
    -- ⬇️ 【在此添加你的功能控件】 ⬇️
    --
    --  可用控件:
    --
    --  🔘 Toggle (开关)
    --    CT.MYTOG = mt:Toggle({
    --        Flag = "MyTog",     -- 配置保存用的名字 (自动保存)
    --        Title = "我的开关",  -- 显示文字
    --        Value = false,      -- 默认值
    --        Callback = function(v) S.MyToggle = v end  -- 切换时回调
    --    })
    --
    --  🎚 Slider (滑块)
    --    mt:Slider({
    --        Flag = "MySlider",
    --        Title = "我的滑块",
    --        Step = 10,          -- 步进值
    --        Value = {           -- 范围
    --            Min = 0,
    --            Max = 1000,
    --            Default = 500
    --        },
    --        Width = 200,        -- 宽度 (可选)
    --        IsTextbox = true,   -- 允许输入数字 (可选)
    --        Callback = function(v) S.MySlider = v end
    --    })
    --
    --  📝 Input (输入框)
    --    mt:Input({
    --        Flag = "MyInput",
    --        Title = "我的输入",
    --        Value = "默认文字",
    --        Placeholder = "输入...",  -- 占位文字 (可选)
    --        Callback = function(v) S.MyInput = v end
    --    })
    --
    --  📋 Dropdown (下拉选择)
    --    mt:Dropdown({
    --        Flag = "MyDropdown",
    --        Title = "选择模式",
    --        Values = {"模式A", "模式B", "模式C"},
    --        Value = "模式A",
    --        Callback = function(v) S.MyDropdown = v end
    --    })
    --
    --  📄 Paragraph (只读文字)
    --    mt:Paragraph({ Title = "说明文字" })
    --
    --  分隔线: mt:Divider()
    --  间距:   mt:Space()


    -- ================================================================
    --  Tab 2: 功能设置 ⭐ (在这里添加你的快捷键绑定)
    -- ================================================================
    local ft = WN:Tab({ Title = "功能设置", Icon = "solar:settings-bold" })
    
    -- ⬇️ 【在此添加快捷键绑定】 ⬇️
    --  例:
    --  CT.EK = ft:Keybind({
    --      Flag = "ESPK",       -- 配置保存名
    --      Title = "透视快捷键",  -- 显示文字
    --      Value = "",          -- 默认值 (空=无快捷键)
    --      Callback = function(k) KB.ESP = k end  -- 回调返回字符串如 "G"
    --  })
    --
    --  监听快捷键 (在窗口创建后添加):
    --  UIS.InputBegan:Connect(function(i, g)
    --      if g then return end  -- 忽略GUI操作
    --      if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    --      local k = i.KeyCode.Name
    --      if KB.ESP and KB.ESP ~= "" and k == KB.ESP then
    --          S.Enabled = not S.Enabled
    --          if CT.ESP then CT.ESP:Set(S.Enabled) end
    --      end
    --  end)


    -- ================================================================
    --  Tab 3: UI设置 (已经完整，一般不需要改)
    -- ================================================================
    local ut = WN:Tab({ Title = "UI设置", Icon = "solar:monitor-bold" })
    ut:Paragraph({ Title = "⚙️ 快捷键" })
    CT.WK = ut:Keybind({
        Flag = "WinKB", Title = "窗口开关", Value = "RightShift",
        Callback = function(k) KB.WK = k; if WN then pcall(function() WN:SetToggleKey(Enum.KeyCode[k]) end) end end
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


    -- ================================================================
    --  Tab 4: 信息统计 ⭐ (在这里添加你的统计显示项)
    -- ================================================================
    local st = WN:Tab({ Title = "信息统计", Icon = "solar:chart-bold" })
    
    -- ⬇️ 【在此添加统计显示项】 ⬇️
    TE.GP = st:Paragraph({ Title = "📊 统计项 1: 0" })
    TE.BP = st:Paragraph({ Title = "📊 统计项 2: 0" })
    TE.SP = st:Paragraph({ Title = "📊 统计项 3: 0" })
    --  说明: TE.GP / TE.BP / TE.SP 是 Paragraph 的引用
    --  更新显示: TE.GP:SetTitle("🟢 好人: " .. count)
    --  或者用 Input (带背景的输入框, Locked=true 为只读):
    --  st:Input({Title="状态", Value="等待中...", Locked=true})


    -- ================================================================
    --  Tab 5: 配置管理 (已经完整，一般不需要改)
    -- ================================================================
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
    
    -- 保存按钮
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
    
    -- 加载按钮
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
    
    -- 删除按钮
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


    -- ================================================================
    --  Tab 6: 关于 (可以修改作者信息)
    -- ================================================================
    local at = WN:Tab({ Title = "关于", Icon = "solar:info-square-bold" })
    at:Paragraph({ Title = "WindUI模板 v6.1", Desc = "纯UI框架" })
    at:Divider()
    at:Paragraph({ Title = "👤 作者", Desc = "b站英吉利超入_" })
    -- ⬆️ 【修改作者名】 ⬆️
    at:Divider()
    at:Paragraph({ Title = "💡 使用", Desc = IM and "手机: 点击悬浮按钮" or "PC: RightShift打开菜单" })
    at:Paragraph({ Title = "🧹 清理", Desc = "_G.CleanupTpl()" })

    print("[v6.1] WindUI模板已加载")
end


-- ============================================================================
--  第八部分: 加载WindUI并显示弹窗 (不需要修改)
-- ============================================================================

local WI = nil
local ok, rv = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if ok and rv then
    WI = rv
    pcall(function() WI:SetTheme("Dark") end)
    S.ParticleColor = gtc("Dark")
    
    -- 显示确认弹窗
    WI:Popup({
        Title = "WindUI模板 v6.1",
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
    
    -- 等待用户确认
    while not PP do task.wait(0.5) end
else
    print("[v6.1] WindUI加载失败")
    local msg = Instance.new("Message")
    msg.Text = "⚠️ WindUI加载失败"
    msg.Parent = WS
    task.delay(3, function() msg:Destroy() end)
end


-- ============================================================================
--  📖 模板使用教程
-- ============================================================================
--  
--  🎯 快速开始 (5分钟上手)
--  
--  1. 复制模板 → 重命名 → 搜索所有 【 标记
--  2. 在「设置表 S」添加你的设置项 (第5个【】)
--  3. 在「用户功能函数」添加你的功能代码 (第6~8个【】)
--  4. 在「主控面板 Tab」添加你的 Toggle/Slider (第11个【】)
--  5. 在「功能设置 Tab」添加快捷键 (第12个【】)
--  6. 在「信息统计 Tab」添加统计项 (第13个【】)
--  7. 修改「关于 Tab」的作者名 (第14个【】)
--  8. 完成 🎉
--  
--  🔍 搜索 【 就能找到所有需要修改的地方
--  
--  📦 控件参考
--  
--  Toggle(开关)       → mt:Toggle({Flag, Title, Value, Callback})
--  Slider(滑块)       → mt:Slider({Flag, Title, Step, Value={Min,Max,Default}})
--  Input(输入框)      → mt:Input({Flag, Title, Value, Callback})
--  Dropdown(下拉)     → mt:Dropdown({Flag, Title, Values, Value, Callback})
--  Keybind(快捷键)    → ft:Keybind({Flag, Title, Value, Callback})
--  Paragraph(文字)    → mt:Paragraph({Title, Desc?})
--  Button(按钮)       → mt:Button({Title, Icon?, Callback})
--  Divider(分隔线)   → mt:Divider()
--  
--  ⚠️ 易错点
--  
--  1. Keybind 回调返回的是字符串 "G" 不是 Enum.KeyCode.G
--  2. Toggle:Set(true) 传布尔值，不传表格
--  3. Input:Set("文字") 传字符串，不传表格
--  4. Slider 参数: {Step=1, Value={Min=0, Max=100, Default=50}}
--  5. Dropdown:Refresh({...}) 传入新数组更新选项
--  6. Paragraph:SetTitle("新文字") 更新文字
--  7. Window:Toggle() / :Open() / :Close() 控制窗口显隐
--  8. OpenButton.OnlyMobile=true 仅手机显示悬浮按钮
--  9. OnClose/OnOpen 在窗口关闭/打开时自动触发
--  10. 粒子用 Scale 坐标(0~1)，永不卡边界
--  11. 所有带 Flag 的控件都会自动接入配置保存
