-- SB HUB 脚本
-- 加载 Rayfield 库
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

-- 创建主窗口
local Window = Rayfield:CreateWindow({
    Name = "SB HUB",
    LoadingTitle = "作者老木正在升空中...",
    LoadingSubtitle = "by SB",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SB_HUB_Config",
        FileName = "Settings"
    }
})

-- ==================== 王朝崩溃 ====================
if game.GameId == 4165264097 then
    local HomeTab = Window:CreateTab("主页", "home")
    HomeTab:CreateLabel("作者：SB 没啥群（此脚本免费禁止倒卖）")

    local DynastyTab = Window:CreateTab("王朝崩溃", 4483362458)
    DynastyTab:CreateButton({
        Name = "ragebot作者eu。屁",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/chenhaofu888666-dotcom/-/refs/heads/main/Collapse%20of%20dynasty.lua"))()
        end
    })
end

-- ==================== 监狱泵 ====================
if game.GameId == 6601115643 then
    local HomeTab = Window:CreateTab("主页", "home")
    HomeTab:CreateLabel("作者：SB 没啥群（此脚本免费禁止倒卖）")

    local PrisonTab = Window:CreateTab("人物功能", "user")

    -- 无限体力按钮
    PrisonTab:CreateButton({
        Name = "无限体力",
        Callback = function()
            local WorkoutHandler = require(game.Workspace.Src.WorkoutHandler)
            hookfunction(WorkoutHandler.ReachedZeroStamina, function() end)
        end
    })
end
