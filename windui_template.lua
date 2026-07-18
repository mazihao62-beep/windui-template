--[[
    WindUI 通用脚本模板 v2.0（开箱即用版）
    
    ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    ★                                          ★
    ★  WindUI 通用脚本模板                     ★
    ★  内置: NPC透视/高亮/标签 完整工作示例      ★
    ★  开箱即用 + 配置保存 + 粒子背景 + 毛玻璃   ★
    ★                                          ★
    ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    
    作者: b站英吉利超入_
    WindUI加载: https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua
    官方文档:  footagesus-windui.mintlify.app
    
    =============== 快速开始 ===============
    1. 复制此文件到你的项目
    2. 修改下面的 Window Title / Author / Folder
    3. 搜索 "【你的功能】" 替换为实际功能
    4. 脚本提供的NPC透视示例可直接使用
    5. 在 主控面板/功能设置 添加你的额外控件
    6. 去掉不需要的Tab
    
    无需任何外部依赖，复制即用。
    =========================================
]]

-- ============================================================
--  第1部分：服务获取 + 平台检测
--  这些是标准的 Roblox 服务引用，别删，后面到处都要用
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- 自动检测手机平台（触屏无键盘=手机，触屏有键盘=触屏笔记本）
local IsMobile = false
pcall(function()
    IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

-- ============================================================
--  第2部分：设置项
--  所有功能开关、参数默认值都写在这里
--  【重要】添加新功能时记得在这里加默认值
-- ============================================================
local Settings = {
    -- ======== 内置设置（不要删） ========
    Particles = true,
    CurrentTheme = "Dark",
    
    -- ======== NPC透视示例功能 ========
    ESP_Enabled = false,       -- 透视总开关
    ESP_BadOnly = false,       -- 仅显示坏人
    ESP_ShowDistance = true,   -- 头顶显示距离
    ESP_ShowHealth = true,     -- 头顶显示血量
    ESP_MaxRange = 500,        -- 最大探测距离
    
    -- 【你的功能】在此添加你的功能默认值
    -- Example2: AutoAim = false,
    -- Example3: AimKey = "",
}

-- ============================================================
--  第3部分：内部变量
--  不要手动修改这些，由代码自动管理
-- ============================================================
local WindowRef = nil
local FloatingButtonGui = nil
local ParticleGui = nil
local ParticleRunning = false
local PopupConfirmed = false
local Controls = {}
local Keybinds = {}
local TabElements = {}
local ConfigName = "default"

-- NPC透视专用变量
local ESP_Objects = {}          -- ESP对象列表 {Highlight, Billboard}
local ESP_Scanning = false      -- 是否正在扫描
local ESP_Stats = {Good=0, Bad=0, Total=0}
local PlayerChar = nil         -- 本地玩家角色

-- ============================================================
--  第4部分：粒子背景系统
--  25个浮动粒子，范围约束在0.06~0.94（不会飘出UI外）
--  速度极慢，碰到边缘平滑反弹（不瞬移）
--  颜色随16主题自动适配
-- ============================================================

-- 主题色映射表（与WindUI内置16主题对应）
local ThemeColors = {
    Dark = Color3.fromRGB(100, 180, 255),
    Light = Color3.fromRGB(80, 140, 200),
    Rose = Color3.fromRGB(255, 120, 160),
    Plant = Color3.fromRGB(100, 200, 120),
    Ocean = Color3.fromRGB(80, 180, 230),
    Sunset = Color3.fromRGB(255, 150, 80),
    Midnight = Color3.fromRGB(120, 100, 220),
    Forest = Color3.fromRGB(80, 170, 80),
    Lavender = Color3.fromRGB(180, 130, 255),
    Coral = Color3.fromRGB(255, 130, 100),
    Mint = Color3.fromRGB(100, 220, 180),
    Peanut = Color3.fromRGB(200, 170, 100),
    Sky = Color3.fromRGB(130, 180, 255),
    Blood = Color3.fromRGB(220, 80, 80),
    Lemon = Color3.fromRGB(220, 200, 80),
    Cyber = Color3.fromRGB(0, 220, 200),
}

local function getParticleColor()
    local themeName = Settings.CurrentTheme or "Dark"
    if ThemeColors[themeName] then
        return ThemeColors[themeName]
    end
    local primary = nil
    pcall(function()
        if WindUI and WindUI.Theme and WindUI.Theme.Primary then
            primary = WindUI.Theme.Primary
        end
    end)
    if primary then return primary end
    return Color3.fromRGB(100, 180, 255)
end

local function createParticles()
    if ParticleGui then
        pcall(function() ParticleGui:Destroy() end)
        ParticleGui = nil
    end
    if not Settings.Particles then return end

    pcall(function()
        ParticleGui = Instance.new("ScreenGui")
        ParticleGui.Name = "Template_Particles"
        ParticleGui.ResetOnSpawn = false
        ParticleGui.DisplayOrder = -999
        ParticleGui.IgnoreGuiInset = true
        ParticleGui.Parent = CoreGui

        local numParticles = 25
        local particles = {}
        local particleColor = getParticleColor()

        for i = 1, numParticles do
            local dot = Instance.new("Frame")
            local size = math.random(2, 4)
            dot.Size = UDim2.new(0, size, 0, size)
            dot.Position = UDim2.new(
                0.08 + math.random() * 0.84, 0,
                0.08 + math.random() * 0.84, 0
            )
            dot.BackgroundColor3 = particleColor
            dot.BackgroundTransparency = 0.4 + math.random() * 0.4
            dot.BorderSizePixel = 0
            dot.Parent = ParticleGui

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 10)
            c.Parent = dot

            local angle = math.random() * 6.28
            local speed = 0.0005 + math.random() * 0.0015
            table.insert(particles, {
                Frame = dot,
                Vx = math.cos(angle) * speed,
                Vy = math.sin(angle) * speed,
                Phase = math.random() * 6.28,
                SizeBase = size,
                MinBound = 0.06,
                MaxBound = 0.94,
            })
        end

        ParticleRunning = true
        task.spawn(function()
            local time = 0
            while ParticleRunning and ParticleGui and ParticleGui.Parent do
                time = time + 0.03
                pcall(function()
                    for _, p in ipairs(particles) do
                        if not p.Frame or not p.Frame.Parent then continue end

                        local x = p.Frame.Position.X.Scale + p.Vx
                        local y = p.Frame.Position.Y.Scale + p.Vy

                        -- 边界平滑反弹
                        if x > p.MaxBound then x = p.MaxBound; p.Vx = -p.Vx + (math.random()-0.5)*0.0002
                        elseif x < p.MinBound then x = p.MinBound; p.Vx = -p.Vx + (math.random()-0.5)*0.0002 end
                        if y > p.MaxBound then y = p.MaxBound; p.Vy = -p.Vy + (math.random()-0.5)*0.0002
                        elseif y < p.MinBound then y = p.MinBound; p.Vy = -p.Vy + (math.random()-0.5)*0.0002 end

                        p.Frame.Position = UDim2.new(x, 0, y, 0)

                        local breathe = 0.4 + math.sin(time * 0.8 + p.Phase) * 0.25
                        p.Frame.BackgroundTransparency = breathe

                        local sizeDelta = math.sin(time + p.Phase) * 0.8
                        local s = math.max(1, p.SizeBase + sizeDelta)
                        p.Frame.Size = UDim2.new(0, s, 0, s)
                    end
                end)
                task.wait(0.03)
            end
        end)
    end)
end

local function updateParticleColor()
    local color = getParticleColor()
    if not ParticleGui then return end
    pcall(function()
        for _, child in ipairs(ParticleGui:GetChildren()) do
            if child:IsA("Frame") then child.BackgroundColor3 = color end
        end
    end)
end

local function destroyParticles()
    ParticleRunning = false
    if ParticleGui then
        pcall(function() ParticleGui:Destroy() end)
        ParticleGui = nil
    end
end

-- ============================================================
--  第5部分：NPC透视系统（完整工作示例）
--  检测所有带 Humanoid + Head 的角色
--  用 Highlight 做穿墙高亮
--  用 BillboardGui 做头顶标签
-- ============================================================

-- 判断是好人还是坏人
-- 返回: "Good" / "Bad"
local function classifyNPC(humanoid, npcModel, npcName, fullPath)
    npcName = npcName or ""
    fullPath = fullPath or ""
    
    -- 第1层：Humanoid属性检测（最可靠）
    -- 游戏源码 NPCSetup.lua 设置了 NPCType = "Agent"(好人) / "Enemy"(坏人)
    local npcType = nil
    pcall(function() npcType = humanoid:GetAttribute("NPCType") end)
    if npcType then
        if npcType == "Agent" or npcType == "Good" or npcType == "Friendly" then
            return "Good"
        elseif npcType == "Enemy" or npcType == "Bad" or npcType == "Hostile" then
            return "Bad"
        end
    end
    
    -- 第2层：名字检测（中文优先）
    local nameLower = npcName:lower()
    
    -- 好人关键词
    local goodKeywords = {
        "警察", "保安", "警卫", "警", "守卫", "卫兵", "士兵", "军人",
        "polic", "secur", "guard", "agent", "officer", "soldier",
        "police", "sheriff", "swat", "fbi", "military","安保","安全",
    }
    for _, kw in ipairs(goodKeywords) do
        if nameLower:find(kw) then return "Good" end
    end
    
    -- 坏人关键词
    local badKeywords = {
        "恐怖", "匪", "坏人", "罪犯", "敌人", "坏蛋", "歹徒", "暴徒",
        "terror", "enemy", "hostile", "criminal", "threat", "suspect",
        "intruder", "invader", "rogue", "hijack","叛","贼","偷",
    }
    for _, kw in ipairs(badKeywords) do
        if nameLower:find(kw) then return "Bad" end
    end
    
    -- 第3层：路径检测
    if fullPath:find("AgentTemplate") then return "Good" end
    if fullPath:find("NPCTemplate") then return "Bad" end
    
    -- 第4层：TeamColor检测
    local tc = humanoid.TeamColor
    if tc then
        if tc == BrickColor.new("Bright blue") or tc == BrickColor.new("Bright green") then
            return "Good"
        end
        if tc == BrickColor.new("Bright red") or tc == BrickColor.new("Really black") then
            return "Bad"
        end
    end
    
    -- 第5层：身上工具检测
    if npcModel then
        pcall(function()
            for _, child in ipairs(npcModel:GetChildren()) do
                if child:IsA("Tool") then
                    local toolName = child.Name:lower()
                    if toolName:find("arrest") or toolName:find("taser") or toolName:find("handcuff") then
                        return "Good"
                    end
                    if toolName:find("knife") or toolName:find("gun") or toolName:find("weapon") then
                        return "Bad"
                    end
                end
            end
        end)
    end
    
    -- 无法判断→标记为坏人（宁错杀不放过）
    return "Bad"
end

-- 为单个NPC创建/更新ESP
local function createNPCESP(npcModel)
    if not npcModel or not npcModel.PrimaryPart then return end
    if ESP_Objects[npcModel] then return end  -- 已存在跳过
    
    local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
    local head = npcModel:FindFirstChild("Head")
    if not humanoid or not head then return end
    
    local npcType = classifyNPC(humanoid, npcModel, npcModel.Name, npcModel:GetFullName())
    local isGood = (npcType == "Good")
    local color = isGood and Color3.fromRGB(0, 255, 80) or Color3.fromRGB(255, 50, 50)
    local label = isGood and "👮 好人" or "💀 坏人"
    
    -- Highlight（穿墙高亮）
    local hl = Instance.new("Highlight")
    hl.Adornee = npcModel
    hl.FillColor = color
    hl.FillTransparency = 0.55
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0.3
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = Settings.ESP_Enabled
    hl.Parent = CoreGui
    
    -- BillboardGui（头顶标签）
    local bg = Instance.new("BillboardGui")
    bg.Adornee = head
    bg.Size = UDim2.new(0, 200, 0, 80)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true
    bg.Enabled = Settings.ESP_Enabled
    bg.Parent = CoreGui
    
    -- 标签背景
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 1, -10)
    frame.Position = UDim2.new(0, 5, 0, 5)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = bg
    
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 6)
    fc.Parent = frame
    
    -- 类型标签
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(1, -8, 0, 22)
    typeLabel.Position = UDim2.new(0, 4, 0, 2)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = label
    typeLabel.TextColor3 = color
    typeLabel.TextScaled = true
    typeLabel.Font = Enum.Font.SourceSansBold
    typeLabel.TextXAlignment = Enum.TextXAlignment.Center
    typeLabel.Parent = frame
    
    -- 距离+血量标签
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -8, 0, 18)
    infoLabel.Position = UDim2.new(0, 4, 0, 24)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = ""
    infoLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = frame
    
    -- 血量条背景
    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(0.8, 0, 0, 4)
    hpBg.Position = UDim2.new(0.1, 0, 0, 46)
    hpBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    hpBg.BackgroundTransparency = 0.3
    hpBg.BorderSizePixel = 0
    hpBg.Parent = frame
    
    local hpf = Instance.new("Frame")
    hpf.Size = UDim2.new(1, 0, 1, 0)
    hpf.BackgroundColor3 = isGood and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
    hpf.BorderSizePixel = 0
    hpf.Parent = hpBg
    
    local hfc = Instance.new("UICorner")
    hfc.CornerRadius = UDim.new(0, 2)
    hfc.Parent = hpBg
    
    ESP_Objects[npcModel] = {
        Model = npcModel,
        Humanoid = humanoid,
        Head = head,
        Highlight = hl,
        Billboard = bg,
        Frame = frame,
        TypeLabel = typeLabel,
        InfoLabel = infoLabel,
        HPBar = hpf,
        HPBg = hpBg,
        IsGood = isGood,
        Label = label,
        Color = color,
    }
end

-- 更新已有ESP的位置和数值
local function updateAllESP()
    if not Settings.ESP_Enabled then return end
    
    local char = PlayerChar
    if not char or not char.PrimaryPart then
        -- 尝试重新获取玩家角色
        local plr = Players.LocalPlayer
        if plr then
            pcall(function() char = plr.Character end)
            PlayerChar = char
        end
    end
    
    local myPos = char and char.PrimaryPart and char.PrimaryPart.Position
    
    for model, esp in pairs(ESP_Objects) do
        pcall(function()
            if not model or not model.Parent then
                -- NPC已被删除，清理ESP
                if esp.Highlight then esp.Highlight:Destroy() end
                if esp.Billboard then esp.Billboard:Destroy() end
                ESP_Objects[model] = nil
                return
            end
            
            -- 仅显示坏人模式
            if Settings.ESP_BadOnly and esp.IsGood then
                esp.Highlight.Enabled = false
                esp.Billboard.Enabled = false
                return
            end
            
            -- 正常显示
            esp.Highlight.Enabled = true
            esp.Billboard.Enabled = true
            
            -- 计算距离
            local distText = ""
            if Settings.ESP_ShowDistance and myPos then
                local head = esp.Head
                if head then
                    local dist = (head.Position - myPos).Magnitude
                    if dist <= Settings.ESP_MaxRange then
                        distText = string.format("%.0fm", dist)
                    else
                        -- 超出范围隐藏
                        esp.Highlight.Enabled = false
                        esp.Billboard.Enabled = false
                        return
                    end
                end
            end
            
            -- 血量
            local hpText = ""
            local maxHp = 100
            local curHp = 100
            if Settings.ESP_ShowHealth then
                pcall(function()
                    curHp = esp.Humanoid.Health
                    maxHp = esp.Humanoid.MaxHealth
                end)
                hpText = string.format("HP: %.0f/%.0f", curHp, maxHp)
                
                -- 血量条
                local ratio = math.max(0, curHp / maxHp)
                esp.HPBar.Size = UDim2.new(ratio, 0, 1, 0)
            end
            
            -- 组装文字
            local infoParts = {}
            if distText ~= "" then table.insert(infoParts, distText) end
            if hpText ~= "" then table.insert(infoParts, hpText) end
            esp.InfoLabel.Text = table.concat(infoParts, " | ")
            
            -- 血量条显隐
            esp.HPBg.Visible = Settings.ESP_ShowHealth
        end)
    end
end

-- 清理所有ESP
local function clearAllESP()
    for _, esp in pairs(ESP_Objects) do
        pcall(function()
            if esp.Highlight then esp.Highlight:Destroy() end
            if esp.Billboard then esp.Billboard:Destroy() end
        end)
    end
    ESP_Objects = {}
end

-- 切换ESP开关（更新所有已有ESP的Enabled + 隐藏/显示）
local function toggleESP(enabled)
    Settings.ESP_Enabled = enabled
    for _, esp in pairs(ESP_Objects) do
        pcall(function()
            esp.Highlight.Enabled = enabled
            esp.Billboard.Enabled = enabled
        end)
    end
end

-- 主扫描循环
local function startESPScanLoop()
    if ESP_Scanning then return end
    ESP_Scanning = true
    
    task.spawn(function()
        while ESP_Scanning do
            pcall(function()
                -- 扫描Workspace找所有带Humanoid的角色
                local goodCount = 0
                local badCount = 0
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("Head") then
                        -- 跳过真实玩家
                        local isPlayer = false
                        pcall(function()
                            local plr = Players:GetPlayerFromCharacter(obj)
                            if plr then isPlayer = true end
                        end)
                        if isPlayer then continue end
                        
                        -- 创建ESP
                        createNPCESP(obj)
                        
                        -- 统计
                        if ESP_Objects[obj] then
                            if ESP_Objects[obj].IsGood then
                                goodCount = goodCount + 1
                            else
                                badCount = badCount + 1
                            end
                        end
                    end
                end
                
                ESP_Stats.Good = goodCount
                ESP_Stats.Bad = badCount
                ESP_Stats.Total = goodCount + badCount
                
                -- 清理已经不存在的NPC
                for model, _ in pairs(ESP_Objects) do
                    if not model or not model.Parent then
                        pcall(function()
                            if ESP_Objects[model] then
                                if ESP_Objects[model].Highlight then ESP_Objects[model].Highlight:Destroy() end
                                if ESP_Objects[model].Billboard then ESP_Objects[model].Billboard:Destroy() end
                            end
                        end)
                        ESP_Objects[model] = nil
                    end
                end
                
                -- 更新信息统计
                if TabElements.StatGood then
                    TabElements.StatGood:SetTitle("🟢 好人: " .. ESP_Stats.Good)
                end
                if TabElements.StatBad then
                    TabElements.StatBad:SetTitle("🔴 坏人: " .. ESP_Stats.Bad)
                end
                if TabElements.StatTotal then
                    TabElements.StatTotal:SetTitle("📊 总计: " .. ESP_Stats.Total)
                end
                if TabElements.StatusInput then
                    local statusText = "扫描中 | 好人:" .. ESP_Stats.Good .. " 坏人:" .. ESP_Stats.Bad .. " 总计:" .. ESP_Stats.Total
                    TabElements.StatusInput:Set(statusText)
                end
            end)
            
            -- 更新ESP显示
            updateAllESP()
            
            task.wait(1)
        end
    end)
end

-- ============================================================
--  第6部分：美化UI（滚动条等）
-- ============================================================
local function beautifyUI()
    pcall(function()
        for _, s in ipairs(CoreGui:GetDescendants()) do
            if s:IsA("ScrollingFrame") then
                s.ScrollBarThickness = 14
                s.ScrollBarImageColor3 = Color3.fromRGB(220, 220, 220)
                s.ScrollBarImageTransparency = 0.1
            end
        end
    end)
end

-- ============================================================
--  第7部分：加载 WindUI + 弹出确认弹窗
--  如果加载失败，自动降级为原生 Message 提示
-- ============================================================
local WindUI = nil
local s, r = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if s and r then
    WindUI = r
    pcall(function() WindUI:SetTheme("Dark") end)

    -- ===================== Popup 确认弹窗 =====================
    WindUI:Popup({
        Title = "WindUI 脚本模板 v2.0",
        Icon = "solar:info-square-bold",
        Content = [[
📋 NPC透视 - 高亮显示 + 头顶标签
💾 配置保存 - 自动保存/读取设置
🎨 主题系统 - 16种内置主题一键切换
✨ 粒子背景 - 动态浮动粒子（主题色自适应）
🌀 增强毛玻璃 - Acrylic + 透明叠加
🔧 自定义快捷键 - 自由绑定

⚠️ 加载后所有功能默认关闭，需手动开启
        ]],
        Buttons = {
            { Title = "取消", Callback = function() end, Variant = "Tertiary" },
            { Title = "确认加载", Icon = "solar:arrow-right-bold", Callback = function()
                PopupConfirmed = true
                pcall(function()
                    WindUI:Notify({
                        Title = "✅ 已加载",
                        Content = "⌨️ 按 RightShift 打开菜单\n所有功能默认关闭",
                        Duration = 4, Icon = "solar:bell-bold",
                    })
                end)
                task.spawn(function()
                    createWindow()
                end)
            end, Variant = "Primary" }
        }
    })

    -- ===================== 用户确认后的初始化 =====================
    task.spawn(function()
        while not PopupConfirmed do task.wait(0.5) end
        task.wait(1.5)
        beautifyUI()
        
        -- 获取玩家角色
        pcall(function()
            local plr = Players.LocalPlayer
            if plr then
                PlayerChar = plr.Character
                plr.CharacterAdded:Connect(function(newChar)
                    PlayerChar = newChar
                end)
            end
        end)
        
        -- 启动NPC扫描循环
        startESPScanLoop()
        
        -- 快捷键监听
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local keyName = input.KeyCode.Name
            
            -- ESP开关快捷键
            if Keybinds.ESP and Keybinds.ESP ~= "" and keyName == Keybinds.ESP then
                Settings.ESP_Enabled = not Settings.ESP_Enabled
                pcall(function()
                    if Controls.ESPToggle then Controls.ESPToggle:Set(Settings.ESP_Enabled) end
                end)
                toggleESP(Settings.ESP_Enabled)
            end
            
            -- 仅显示坏人快捷键
            if Keybinds.BadOnly and Keybinds.BadOnly ~= "" and keyName == Keybinds.BadOnly then
                Settings.ESP_BadOnly = not Settings.ESP_BadOnly
                pcall(function()
                    if Controls.BadOnlyToggle then Controls.BadOnlyToggle:Set(Settings.ESP_BadOnly) end
                end)
            end
            
            -- 【你的功能】快捷键
            -- if Keybinds.XXX and Keybinds.XXX ~= "" and keyName == Keybinds.XXX then
            --     Settings.XXX = not Settings.XXX
            --     pcall(function()
            --         if Controls.XXX then Controls.XXX:Set(Settings.XXX) end
            --     end)
            --     -- 执行操作
            -- end
        end)
    end)

    -- ===================== 创建窗口 =====================
    function createWindow()
        if WindowRef then return end

        local ok, win = pcall(function()
            return WindUI:CreateWindow({
                Title = "WindUI 脚本模板",
                Author = "b站英吉利超入_",
                Icon = "solar:shield-warning-bold",
                Size = UDim2.fromOffset(750, 520),
                ToggleKey = Enum.KeyCode.RightShift,
                Folder = "windui-template",  -- 配置保存文件夹名
                Acrylic = true,
                Transparent = true,
                Resizable = false,
                SideBarWidth = 180,
                ScrollBarEnabled = true,
                HideSearchBar = true,
            })
        end)
        if not ok or not win then
            print("[模板] 窗口创建失败:", ok)
            return
        end
        WindowRef = win
        pcall(function() WindUI.TransparencyValue = 0.22 end)

        -- ===================== Tab 1: 主控面板 =====================
        local mainTab = win:Tab({Title="主控面板", Icon="solar:slider-vertical-bold"})

        mainTab:Paragraph({Title="👁 NPC透视控制"})
        
        Controls.ESPToggle = mainTab:Toggle({
            Flag = "ESPToggle", Title = "透视开关", Value = false,
            Desc = "高亮显示 + 头顶标签",
            Callback = function(v) toggleESP(v) end
        })
        
        Controls.BadOnlyToggle = mainTab:Toggle({
            Flag = "BadOnlyToggle", Title = "仅显示坏人", Value = false,
            Desc = "隐藏好人，只显示威胁目标",
            Callback = function(v) Settings.ESP_BadOnly = v end
        })
        
        mainTab:Divider()
        mainTab:Paragraph({Title="📏 标签显示设置"})
        
        Controls.DistanceToggle = mainTab:Toggle({
            Flag = "DistanceToggle", Title = "显示距离", Value = true,
            Callback = function(v) Settings.ESP_ShowDistance = v end
        })
        Controls.HealthToggle = mainTab:Toggle({
            Flag = "HealthToggle", Title = "显示血量", Value = true,
            Callback = function(v) Settings.ESP_ShowHealth = v end
        })
        
        mainTab:Divider()
        mainTab:Paragraph({Title="🎯 扫描参数"})
        
        Controls.RangeSlider = mainTab:Slider({
            Flag = "RangeSlider", Title = "最大探测距离", Step = 10,
            Value = { Min = 50, Max = 1000, Default = 500 },
            Width = 200, IsTextbox = true,
            Callback = function(v) Settings.ESP_MaxRange = v end
        })
        
        -- 【你的功能】在此添加你的 Toggle / Slider / Dropdown
        -- Controls.YourToggle = mainTab:Toggle({
        --     Flag = "YourToggle", Title = "功能开关", Value = false,
        --     Callback = function(v) Settings.YourSetting = v end
        -- })
        -- Controls.YourSlider = mainTab:Slider({
        --     Flag = "YourSlider", Title = "参数名", Step = 1,
        --     Value = { Min = 0, Max = 100, Default = 50 },
        --     Width = 200, IsTextbox = true,
        --     Callback = function(v) Settings.YourParam = v end
        -- })
        -- Controls.YourDropdown = mainTab:Dropdown({
        --     Flag = "YourDropdown", Title = "选项名",
        --     Values = {"A", "B", "C"}, Value = "A",
        --     Callback = function(v) Settings.YourOption = v end
        -- })
        -- Controls.YourInput = mainTab:Input({
        --     Flag = "YourInput", Title = "输入框名", Value = "默认值",
        --     Callback = function(v) Settings.YourText = v end
        -- })

        -- ===================== Tab 2: 功能设置 =====================
        local funcTab = win:Tab({Title="功能设置", Icon="solar:settings-bold"})
        funcTab:Paragraph({Title="🔑 快捷键设置（点击后按键盘绑定）"})
        
        Controls.ESPKeybind = funcTab:Keybind({
            Flag = "ESPKeybind", Title = "透视开关快捷键", Value = "",
            Callback = function(key) Keybinds.ESP = key end
        })
        Controls.BadOnlyKeybind = funcTab:Keybind({
            Flag = "BadOnlyKeybind", Title = "仅显示坏人快捷键", Value = "",
            Callback = function(key) Keybinds.BadOnly = key end
        })
        
        funcTab:Divider()
        
        -- 【你的功能】快捷键
        -- Controls.YourKeybind = funcTab:Keybind({
        --     Flag = "YourKeybind", Title = "功能快捷键", Value = "",
        --     Callback = function(key) Keybinds.YourFunc = key end
        -- })
        
        funcTab:Divider()
        funcTab:Paragraph({Title="💡 提示", Desc="窗口快捷键在UI设置中绑定（默认 RightShift）\n快捷键默认全部为空，需自行绑定"})

        -- ===================== Tab 3: UI 设置 =====================
        local uiTab = win:Tab({Title="UI设置", Icon="solar:monitor-bold"})

        uiTab:Paragraph({Title="⚙️ 界面设置"})
        Controls.WindowKeybind = uiTab:Keybind({
            Flag = "WindowKeybind", Title = "窗口开关快捷键", Value = "RightShift",
            Callback = function(key)
                Keybinds.Window = key
                if WindowRef then pcall(function() WindowRef:SetToggleKey(Enum.KeyCode[key]) end) end
            end
        })
        Controls.FloatingBtnToggle = uiTab:Toggle({
            Flag = "FloatingBtnToggle", Title = "显示悬浮按钮", Value = IsMobile,
            Callback = function(v) if FloatingButtonGui then FloatingButtonGui.Enabled = v end end
        })
        uiTab:Divider()

        uiTab:Paragraph({Title="🌀 背景效果"})
        Controls.ParticlesToggle = uiTab:Toggle({
            Flag = "ParticlesToggle", Title = "浮动粒子背景", Value = true,
            Callback = function(v)
                Settings.Particles = v
                if v then createParticles() else destroyParticles() end
            end
        })
        uiTab:Divider()

        uiTab:Paragraph({Title="✨ 窗口效果"})
        Controls.AcrylicToggle = uiTab:Toggle({
            Flag = "AcrylicToggle", Title = "毛玻璃效果", Value = true,
            Callback = function(v) pcall(function() WindUI:ToggleAcrylic(v) end) end
        })
        Controls.TransparencyToggle = uiTab:Toggle({
            Flag = "TransparencyToggle", Title = "透明背景增强毛玻璃", Value = true,
            Callback = function(v) if WindowRef then pcall(function() WindowRef:ToggleTransparency(v) end) end end
        })
        uiTab:Divider()

        uiTab:Paragraph({Title="🎨 主题系统", Desc="16种内置主题，切换时粒子颜色自动适配"})
        local allThemes = {}
        pcall(function() allThemes = WindUI:GetThemes() end)
        local themeNames = {}
        for name, _ in pairs(allThemes) do table.insert(themeNames, name) end
        table.sort(themeNames)

        Controls.ThemeDropdown = uiTab:Dropdown({
            Flag = "ThemeDropdown", Title = "选择主题", Values = themeNames, Value = "Dark",
            Callback = function(selected)
                if selected then
                    Settings.CurrentTheme = selected
                    pcall(function() WindUI:SetTheme(selected) end)
                    updateParticleColor()
                end
            end
        })
        uiTab:Divider()
        uiTab:Paragraph({Title="💡 提示", Desc="粒子背景 + 毛玻璃 + 透明背景叠加效果最佳"})

        -- ===================== Tab 4: 信息统计 =====================
        local statsTab = win:Tab({Title="信息统计", Icon="solar:chart-bold"})
        
        TabElements.StatGood = statsTab:Paragraph({Title="🟢 好人: 0"})
        TabElements.StatBad = statsTab:Paragraph({Title="🔴 坏人: 0"})
        TabElements.StatTotal = statsTab:Paragraph({Title="📊 总计: 0"})
        statsTab:Divider()
        TabElements.StatusInput = statsTab:Input({
            Flag = "StatusInputCache", Title = "扫描状态", Value = "等待中...", Locked = true
        })

        -- ===================== Tab 5: 配置管理 =====================
        local configTab = win:Tab({Title="配置管理", Icon="solar:diskette-bold"})
        configTab:Paragraph({Title="💾 配置管理", Desc="保存/加载你的所有设置"})

        local ConfigNameInput = configTab:Input({
            Flag = "ConfigNameInput", Title = "配置名称", Value = "default",
            Icon = "solar:file-text-bold",
            Callback = function(value) ConfigName = value end
        })
        configTab:Space()

        local ConfigManager = WindowRef.ConfigManager
        local AllConfigs = {}
        pcall(function() AllConfigs = ConfigManager:AllConfigs() end)
        local DefaultValue = nil
        pcall(function()
            for _, v in ipairs(AllConfigs) do if v == "default" then DefaultValue = "default"; break end end
        end)

        local AllConfigsDropdown = configTab:Dropdown({
            Title = "已有配置", Desc = "选择要加载的配置",
            Values = AllConfigs, Value = DefaultValue,
            Callback = function(value)
                if value then ConfigName = value; pcall(function() ConfigNameInput:Set(value) end) end
            end
        })
        configTab:Space()

        configTab:Button({
            Title = "💾 保存配置", Icon = "solar:check-circle-bold", Justify = "Center",
            Color = Color3.fromHex("#305dff"),
            Callback = function()
                if not ConfigManager then
                    pcall(function() WindUI:Notify({Title="错误", Content="配置系统不可用", Duration=3}) end)
                    return
                end
                pcall(function()
                    local config = ConfigManager:Config(ConfigName)
                    if config and config:Save() then
                        WindUI:Notify({Title="✅ 配置已保存", Content="配置 '" .. ConfigName .. "' 已保存", Icon="solar:check-circle-bold", Duration=3})
                        AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
                    end
                end)
            end
        })
        configTab:Space()

        configTab:Button({
            Title = "📂 加载配置", Icon = "solar:refresh-circle-bold", Justify = "Center",
            Color = Color3.fromHex("#10C550"),
            Callback = function()
                if not ConfigManager then
                    pcall(function() WindUI:Notify({Title="错误", Content="配置系统不可用", Duration=3}) end)
                    return
                end
                pcall(function()
                    local config = ConfigManager:CreateConfig(ConfigName, false)
                    if config and config:Load() then
                        WindUI:Notify({Title="✅ 配置已加载", Content="配置 '" .. ConfigName .. "' 已加载", Icon="solar:refresh-circle-bold", Duration=3})
                    end
                end)
            end
        })
        configTab:Space()

        configTab:Button({
            Title = "🗑️ 删除配置", Icon = "solar:trash-bin-trash-bold", Justify = "Center",
            Color = Color3.fromHex("#ff3040"),
            Callback = function()
                if not ConfigManager then return end
                pcall(function()
                    local config = ConfigManager:Config(ConfigName)
                    if config and config:Delete() then
                        WindUI:Notify({Title="🗑️ 配置已删除", Content="配置 '" .. ConfigName .. "' 已删除", Icon="solar:trash-bin-trash-bold", Duration=3})
                        AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
                    end
                end)
            end
        })
        configTab:Divider()
        configTab:Paragraph({Title="💡 提示", Desc="所有带 Flag 的元素会自动保存/恢复\n包括：Toggle、快捷键、滑块、Dropdown、Input 等"})

        -- 自动加载配置 + 启动粒子
        task.spawn(function()
            task.wait(1)
            pcall(function()
                if ConfigManager then
                    local config = ConfigManager:CreateConfig("default", true)
                end
            end)
            createParticles()
        end)

        -- ===================== Tab 6: 关于 =====================
        local aboutTab = win:Tab({Title="关于", Icon="solar:info-square-bold"})
        aboutTab:Paragraph({Title="WindUI 脚本模板 v2.0", Desc="开箱即用的 WindUI 完整示例"})
        aboutTab:Divider()
        aboutTab:Paragraph({Title="👤 作者", Desc="b站英吉利超入_"})
        aboutTab:Divider()
        local usage = IsMobile and "手机: 点击悬浮按钮" or "PC: 按 RightShift 打开菜单"
        aboutTab:Paragraph({Title="💡 使用说明", Desc=usage})
        aboutTab:Paragraph({Title="⚠️ 提示", Desc="所有功能默认关闭，请在菜单中手动开启\n	extit{注：在编辑器中运行前请先修改 Settings 表}"})

        -- ===================== 手机悬浮按钮 =====================
        if IsMobile then
            task.spawn(function()
                task.wait(1)
                pcall(function()
                    FloatingButtonGui = Instance.new("ScreenGui")
                    FloatingButtonGui.Name = "Template_Btn"
                    FloatingButtonGui.Enabled = true
                    FloatingButtonGui.ResetOnSpawn = false
                    FloatingButtonGui.Parent = CoreGui

                    local btn = Instance.new("ImageButton")
                    btn.Size = UDim2.new(0,50,0,50)
                    btn.Position = UDim2.new(0.9,-25,0.8,-25)
                    btn.BackgroundColor3 = Color3.fromRGB(0,180,80)
                    btn.BackgroundTransparency = 0.2
                    btn.BorderSizePixel = 0
                    btn.Parent = FloatingButtonGui

                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0,25)
                    c.Parent = btn

                    local t = Instance.new("TextLabel")
                    t.Size = UDim2.new(1,0,1,0)
                    t.BackgroundTransparency = 1
                    t.Text = "👁"
                    t.TextScaled = true
                    t.Font = Enum.Font.SourceSansBold
                    t.TextColor3 = Color3.fromRGB(255,255,255)
                    t.Parent = btn

                    local dragging, dragStart, startPos = false, nil, nil
                    btn.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            dragStart = input.Position
                            startPos = btn.Position
                        end
                    end)
                    btn.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                            btn.Position = UDim2.new(
                                startPos.X.Scale, startPos.X.Offset + input.Position.X - dragStart.X,
                                startPos.Y.Scale, startPos.Y.Offset + input.Position.Y - dragStart.Y
                            )
                        end
                    end)
                    btn.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)

                    btn.MouseButton1Click:Connect(function()
                        if WindowRef then pcall(function() WindowRef:Toggle() end) end
                    end)
                end)
            end)
        end
    end

    print("[模板] v2.0 已加载 | 作者: b站英吉利超入_")
else
    -- WindUI 加载失败
    print("[模板] WindUI 加载失败")
    local msg = Instance.new("Message")
    msg.Text = "⚠️ WindUI 加载失败，请重试"
    msg.Parent = Workspace
    task.delay(5, function() msg:Destroy() end)
end

print("[模板] 脚本加载完成")


--[[============================================================

    ============================================================
    使用注意事项（详细）
    ============================================================

    ★ 首次使用流程 ★
        1. 执行脚本 → 弹出 Popup 确认弹窗
        2. 点击「确认加载」→ 加载完成
        3. 按 RightShift 打开菜单
        4. 去「主控面板」开启「透视开关」
        5. NPC 自动高亮 + 头顶标签
        6. 去「功能设置」绑定快捷键
        7. 去「UI设置」自由设置主题/粒子/毛玻璃
        8. 所有设置会自动保存

    ★ 如何自定义脚本 ★
        1. 修改 Window 标题: 在 CreateWindow 的 Title 参数
        2. 修改作者: Author 参数
        3. 修改配置文件夹名: Folder 参数
        4. 添加新功能: 在「主控面板」加 Toggle/Slider/Dropdown
        5. 添加快捷键: 在「功能设置」加 Keybind
        6. 添加统计: 在「信息统计」加 Paragraph
        7. 去掉不需要的 Tab: 直接删掉对应 Tab 代码块

    ★ WindUI 控件常用方法速查 ★
        Toggle    → :Set(true/false)
        Slider    → 通过 Callback 接收值
        Input     → :Set("new text")
        Dropdown  → :Refresh({new values})
        Keybind   → Callback 返回字符串 KeyName
        Paragraph → :SetTitle("new title")
        Button    → Callback 在点击时触发
        Divider   → 创建即生效
        Space     → 创建即生效
        
    ★ 配置保存系统说明 ★
        所有带 Flag 的控件自动接入配置保存系统
        配置保存路径: WindUI/{Folder}/{ConfigName}.json
        默认自动加载 "default" 配置
        配置保存内容: 所有 Flag 控件的当前值
        
    ★ NPC 分类器说明 ★
        NPC 分类逻辑（优先级从高到低）:
        1. Humanoid 的 NPCType 属性 (Agent=好人, Enemy=坏人)
        2. NPC 名字 (中文优先: 警察/保安/恐怖/匪)
        3. 路径检测 (AgentTemplate/NPCTemplate)
        4. TeamColor 检测
        5. 随身工具检测
        6. 以上均无匹配 → 默认坏人
        
        如果你要改分类逻辑:
        在 classifyNPC 函数中添加/删除关键词即可

    ★ 手机适配说明 ★
        PC端: 悬浮按钮默认隐藏，用 RightShift 开菜单
        手机端: 悬浮按钮默认显示，点击按钮开菜单
        可在 UI设置 → 显示悬浮按钮 手动开关
        
    ★ 常见问题 FAQ ★
        Q: 为什么加载后看不到 NPC？
        A: 所有功能默认关闭，去「主控面板」开启「透视开关」
        
        Q: 为什么快捷键按了没反应？
        A: 快捷键默认全部为空，需去「功能设置」手动绑定
        
        Q: 为什么下拉主题没有16个？
        A: WindUI 版本差异，部分主题可能被过滤（但仍可正常用）
        
        Q: 为什么窗口没显示？
        A: 按 RightShift 打开（手机点悬浮按钮）
        
        Q: 怎么保存我的设置？
        A: 去「配置管理」输入名称点保存，下次自动加载
        
        Q: 所有NPC显示为坏人/无法区分？
        A: 修改 classifyNPC 函数中的关键词，适配具体游戏
        
        Q: 脚本报 nil 错误？
        A: WindUI 可能加载失败，检查网络或换源
        
    ★ 开发提醒 ★
        1. 所有 pcall 包裹的代码出错不会中断脚本运行
        2. Settings 表存放所有功能状态，可在外部访问
        3. Controls 表存放所有 UI 控件引用
        4. TabElements 表存放统计/状态元素引用
        5. 添加新功能时记得同时加: 默认值 + 控件 + 快捷键
        6. 不要在脚本运行中动态修改 Tab 结构
        7. 配置系统只保存带 Flag 的控件值

    ★ 官方文档链接 ★
        Window:      footagesus-windui.mintlify.app/components/window
        Tab:         footagesus-windui.mintlify.app/components/tab
        Toggle:      footagesus-windui.mintlify.app/components/toggle
        Slider:      footagesus-windui.mintlify.app/components/slider
        Input:       footagesus-windui.mintlify.app/components/input
        Dropdown:    footagesus-windui.mintlify.app/components/dropdown
        Keybind:     footagesus-windui.mintlify.app/components/keybind
        Button:      footagesus-windui.mintlify.app/components/button
        Paragraph:   footagesus-windui.mintlify.app/components/paragraph
        Popup:       footagesus-windui.mintlify.app/components/popup
        Notification: footagesus-windui.mintlify.app/components/notification
        Config Saving: footagesus-windui.mintlify.app/guides/config-saving
        Themes:      footagesus-windui.mintlify.app/configuration/themes
        Acrylic:     footagesus-windui.mintlify.app/guides/acrylic
        Icons:       footagesus-windui.mintlify.app/guides/icons
        
        WindUI 加载: https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua

============================================================--]]