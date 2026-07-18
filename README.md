# WindUI 通用脚本模板 🧩

**作者: b站英吉利超入_**

基于 WindUI 的 Roblox 脚本通用模板，开箱即用。

---

## 🚀 使用方式

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/mazihao62-beep/windui-template/main/windui_template.lua"))()
```

---

## 📋 模板结构（6个标准Tab）

```
┌─ 主控面板 ─┬─ 功能设置 ─┬─ UI设置 ────────┬─ 信息统计 ─┬─ 配置管理 ─┬─ 关于 ─┐
│ 🎯功能控制   │ 🔑功能快捷键  │ ⚙️界面设置      │ 📊统计信息   │ 💾保存配置   │ 版本   │
│ ⚙️参数设置   │ 💡提示       │ 🌀粒子背景开关   │ 📡状态显示   │ 📂加载配置   │ 作者   │
│ Toggle/Slider│             │ ✨毛玻璃开关     │             │ 🗑️删除配置   │ 说明   │
│ Dropdown/Input│            │ 🔄透明背景开关   │             │ 下拉选择     │       │
│              │             │ 🎨主题下拉选择    │             │            │       │
└──────────────┴────────────┴──────────────────┴────────────┴────────────┴───────┘
```

---

## 🎁 内置功能

| 功能 | 说明 |
|------|------|
| ✅ **Popup 确认弹窗** | 加载前弹出功能说明，确认后才启动 |
| ✅ **粒子背景 v1.1** | 🆕 范围约束（不飘出UI）+ 缓慢反弹（不瞬移）+ 主题色自动适配 |
| ✅ **增强毛玻璃** | Acrylic + Transparent = 0.22 叠加 |
| ✅ **16主题** | 下拉一键切换 Dark/Light/Rose/Plant... 粒子颜色同步变 |
| ✅ **配置保存** | 所有 Flag 控件自动接入，自动加载 default |
| ✅ **手机适配** | 悬浮按钮 + 拖拽 |
| ✅ **快捷键监听** | 窗口/功能快捷键分离 |

---

## 📝 使用方法

1. 复制 `windui_template.lua` 到你的项目
2. 搜索 `【你的功能】` 替换为实际功能
3. 修改 Window 标题/作者/Size
4. 在 主控面板/功能设置/信息统计 添加你的控件
5. 去掉你不需要的 Tab

### 搜索替换清单

| 搜索 | 替换为 |
|------|--------|
| `【你的脚本名】` | 你的脚本名称 |
| `【你的项目名-folder】` | 你的项目文件夹名（配置保存用） |
| `【你的功能】` | 具体功能注释 |
| `YourToggle` | 你的 Toggle 变量名 |
| `YourSlider` | 你的 Slider 变量名 |
| `YourKeybind` | 你的快捷键变量名 |

---

## 🔗 参考链接

| # | 页面 | 链接 |
|---|------|------|
| 1️⃣ | Window | `footagesus-windui.mintlify.app/components/window` |
| 2️⃣ | Tab | `footagesus-windui.mintlify.app/components/tab` |
| 3️⃣ | Toggle | `footagesus-windui.mintlify.app/components/toggle` |
| 4️⃣ | Slider | `footagesus-windui.mintlify.app/components/slider` |
| 5️⃣ | Input | `footagesus-windui.mintlify.app/components/input` |
| 6️⃣ | Dropdown | `footagesus-windui.mintlify.app/components/dropdown` |
| 7️⃣ | Keybind | `footagesus-windui.mintlify.app/components/keybind` |
| 8️⃣ | Button | `footagesus-windui.mintlify.app/components/button` |
| 9️⃣ | Paragraph | `footagesus-windui.mintlify.app/components/paragraph` |
| 🔟 | Popup | `footagesus-windui.mintlify.app/components/popup` |
| 1️⃣1️⃣ | Notification | `footagesus-windui.mintlify.app/components/notification` |
| 1️⃣2️⃣ | Config Saving | `footagesus-windui.mintlify.app/guides/config-saving` |
| 1️⃣3️⃣ | Themes | `footagesus-windui.mintlify.app/configuration/themes` |
| 1️⃣4️⃣ | Acrylic | `footagesus-windui.mintlify.app/guides/acrylic` |
| 1️⃣5️⃣ | Icons | `footagesus-windui.mintlify.app/guides/icons` |

**加载链接:** `https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua`

---

## 📜 版本历史

| 版本 | 内容 |
|------|------|
| v1.1 | 🆕 粒子修复：范围约束+缓慢反弹+主题色自动适配 |
| v1.0 | ✅ 初始发布 - 6个标准Tab + 粒子背景 + 毛玻璃 + 16主题 + 配置保存 |
