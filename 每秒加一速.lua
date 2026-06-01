-- SB HUB - 自动走瓷砖专用版
-- 语言选择功能

local SupportedLanguages = {
    Chinese = "中文",
    English = "English"
}

local CurrentLanguage = SupportedLanguages.Chinese

local Lang = {
    [SupportedLanguages.Chinese] = {
        LoadingTitle = "SB HUB超高速跑者",
        LoadingSubtitle = "作者老木正在升空中...",
        AuthorLabel = "作者：SB （此脚本免费禁止倒卖）",
        AutoStepBtn = "自动刷速度",
        CopyQQBtn = "复制🐧群",
        CopyDCBtn = "复制dc",
        HomeTab = "主页",
        StepTab = "功能",
    },
    [SupportedLanguages.English] = {
        LoadingTitle = "SB HUB Hypervelocity runner",
        LoadingSubtitle = "Script is loading...",
        AuthorLabel = "Author: SB (Free script, no reselling)",
        AutoStepBtn = "Auto run",
        CopyDCBtn = "Copy Discord",
        HomeTab = "Home",
        StepTab = "Function",
    }
}

local function ShowLanguageSelector(callback)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game.CoreGui
    ScreenGui.Name = "LanguageSelectorGUI"

    local Frame = Instance.new("Frame")
    Frame.Parent = ScreenGui
    Frame.Size = UDim2.new(0, 300, 0, 150)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 0

    local Title = Instance.new("TextLabel")
    Title.Parent = Frame
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Title.Text = "选择语言 / Select Language"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18

    local MsgLabel = Instance.new("TextLabel")
    MsgLabel.Parent = Frame
    MsgLabel.Size = UDim2.new(1, 0, 0, 40)
    MsgLabel.Position = UDim2.new(0, 0, 0, 40)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.Text = "请选择你要使用的语言："
    MsgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    MsgLabel.Font = Enum.Font.Gotham
    MsgLabel.TextSize = 14

    local ChineseBtn = Instance.new("TextButton")
    ChineseBtn.Parent = Frame
    ChineseBtn.Size = UDim2.new(0.4, -10, 0, 40)
    ChineseBtn.Position = UDim2.new(0.05, 0, 0, 85)
    ChineseBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    ChineseBtn.Text = "中文"
    ChineseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ChineseBtn.Font = Enum.Font.GothamBold
    ChineseBtn.TextSize = 16
    ChineseBtn.BorderSizePixel = 0

    local EnglishBtn = Instance.new("TextButton")
    EnglishBtn.Parent = Frame
    EnglishBtn.Size = UDim2.new(0.4, -10, 0, 40)
    EnglishBtn.Position = UDim2.new(0.55, 0, 0, 85)
    EnglishBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    EnglishBtn.Text = "English"
    EnglishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    EnglishBtn.Font = Enum.Font.GothamBold
    EnglishBtn.TextSize = 16
    EnglishBtn.BorderSizePixel = 0

    ChineseBtn.MouseButton1Click:Connect(function()
        CurrentLanguage = SupportedLanguages.Chinese
        ScreenGui:Destroy()
        callback(CurrentLanguage)
    end)

    EnglishBtn.MouseButton1Click:Connect(function()
        CurrentLanguage = SupportedLanguages.English
        ScreenGui:Destroy()
        callback(CurrentLanguage)
    end)
end

local function LoadMainScript(lang)
    local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
    local texts = Lang[lang]

    local Window = Rayfield:CreateWindow({
        Name = texts.LoadingTitle,
        LoadingTitle = texts.LoadingSubtitle,
        LoadingSubtitle = "by SB",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "SB_HUB_Config_Step",
            FileName = "Settings"
        }
    })

    local HomeTab = Window:CreateTab(texts.HomeTab, "home")
    HomeTab:CreateLabel(texts.AuthorLabel)

    if lang == SupportedLanguages.Chinese then
        HomeTab:CreateButton({
            Name = texts.CopyQQBtn,
            Callback = function()
                setclipboard("1092163863")
                Rayfield:Notify({
                    Title = texts.LoadingTitle,
                    Content = "已复制🐧群号到剪贴板",
                    Duration = 3
                })
            end
        })
    end

    HomeTab:CreateButton({
        Name = texts.CopyDCBtn,
        Callback = function()
            setclipboard("https://discord.gg/x8rX7aYq3")
            Rayfield:Notify({
                Title = texts.LoadingTitle,
                Content = lang == SupportedLanguages.Chinese and "已复制dc链接到剪贴板" or "Discord link copied to clipboard",
                Duration = 3
            })
        end
    })

    local StepTab = Window:CreateTab(texts.StepTab, "game")
    
    local isRunning = false
    
    StepTab:CreateToggle({
        Name = texts.AutoStepBtn,
        CurrentValue = false,
        Callback = function(Value)
            if Value then
                isRunning = true
                task.spawn(function()
                    local replicatedStorage = game:GetService("ReplicatedStorage")
                    local remotes = replicatedStorage:WaitForChild("Remotes")
                    local stepTaken = remotes:WaitForChild("StepTaken")
                    local args = {4, true, "Road4"}
                    
                    while isRunning do
                        pcall(function()
                            stepTaken:FireServer(unpack(args))
                        end)
                        task.wait()
                    end
                end)
            else
                isRunning = false
            end
        end
    })
end

ShowLanguageSelector(function(selectedLang)
    LoadMainScript(selectedLang)
end)