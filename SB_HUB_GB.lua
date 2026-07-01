-- SB HUB - 打僵尸游戏专用版 (GameId: 4342047058)
-- 使用 Obsidian UI 库

-- ==================== 加载 Obsidian UI 库 ====================
local LibUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local UILibrary = loadstring(game:HttpGet(LibUrl .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(LibUrl .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(LibUrl .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- ==================== 创建主窗口 ====================
local MainWindow = UILibrary.CreateWindow({
    Title = "SB HUB",
    Footer = "打僵尸专用版 | GameId: 4342047058",
    Icon = 1234567890123,
    NotifingSide = "Right"
})

-- ==================== 创建标签页 ====================
local CombatTab = MainWindow:AddTab("战斗")
local CharacterTab = MainWindow:AddTab("人物")
local SettingsTab = MainWindow:AddTab("设置")

-- ==================== 功能变量 ====================
local headshotEnabled = false
local isFlying = false
local flySpeed = 35
local bv = nil
local flyAnim = nil
local flyConnection = nil
local flyTurner = nil
local noSlowActive = false
local walkSpeedConnection = nil
local noSlowCharacterConnection = nil
local isAxeStunActive = false
local axeStunConnection = nil
local axeStunDistance = 15
local axeStunMaxTargets = 5
local axeStunCharacterConnection = nil

-- 杀戮光环 - 固定参数
local KILL_AURA_RANGE = 5
local KILL_AURA_MAX_TARGETS = 2
local KILL_AURA_INTERVAL = 0.6

local isKillAuraActive = false
local attackDraculaEnabled = false
local killAuraConnection = nil
local killAuraCharacterConnection = nil
local killAuraCooldown = 0

-- ==================== 强制头部命中模块 ====================
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Weapons = Modules:WaitForChild("Weapons")

local originalBayonetHitCheck = nil
local originalMeleeHitCheck = nil
local bayonetHooked = false
local meleeHooked = false

local function customBayonetHitCheck(self, origin, direction, raycastParams, hitEntities)
    local rayResult = workspace:Raycast(origin, direction, raycastParams)
    if rayResult then
        local hitPart = rayResult.Instance
        local zombieModel = hitPart and hitPart.Parent
        if zombieModel and zombieModel.Name == "m_Zombie" then
            local orig = zombieModel:FindFirstChild("Orig")
            if orig then
                local head = nil
                for _, part in ipairs(zombieModel:GetChildren()) do
                    if part.Name == "Head" and (part:IsA("Part") or part:IsA("MeshPart")) then
                        head = part
                        break
                    end
                end
                if head then
                    local zombieRef = orig.Value
                    local headPos = head.CFrame.Position
                    self.remoteEvent:FireServer("Bayonet_HitZombie", zombieRef, headPos, true, "Head")
                    zombieRef:SetAttribute("WepHitID", tick())
                    zombieRef:SetAttribute("WepHitDirection", direction * 10)
                    zombieRef:SetAttribute("WepHitPos", rayResult.Position)
                    task.delay(0.2, function()
                        if zombieRef:GetAttribute("WepHitID") == tick() then
                            zombieRef:SetAttribute("WepHitDirection", nil)
                            zombieRef:SetAttribute("WepHitPos", nil)
                            zombieRef:SetAttribute("WepHitID", nil)
                        end
                    end)
                    return 1
                end
            end
        end
        if originalBayonetHitCheck then
            return originalBayonetHitCheck(self, origin, direction, raycastParams, hitEntities)
        end
    end
    return 0
end

local function customMeleeHitCheck(self, origin, direction, raycastParams, hitEntities, isCharge)
    local rayResult = workspace:Raycast(origin, direction, raycastParams)
    if rayResult then
        local hitPart = rayResult.Instance
        local zombieModel = hitPart and hitPart.Parent
        if zombieModel and zombieModel.Name == "m_Zombie" then
            local orig = zombieModel:FindFirstChild("Orig")
            if orig then
                local head = nil
                for _, part in ipairs(zombieModel:GetChildren()) do
                    if part.Name == "Head" and (part:IsA("Part") or part:IsA("MeshPart")) then
                        head = part
                        break
                    end
                end
                if head then
                    local zombieRef = orig.Value
                    local headPos = head.CFrame.Position
                    if isCharge then
                        self.remoteEvent:FireServer("ThrustCharge", zombieRef, headPos, rayResult.Normal)
                    else
                        local hitDirection = (headPos - origin).Unit * 25
                        self.remoteEvent:FireServer("HitZombieM", zombieRef, headPos, true, hitDirection, "Head", rayResult.Normal)
                        if not zombieRef:GetAttribute("WepHitDirection") then
                            local uid = tick()
                            zombieRef:SetAttribute("WepHitID", uid)
                            zombieRef:SetAttribute("WepHitDirection", hitDirection)
                            zombieRef:SetAttribute("WepHitPos", rayResult.Position)
                            task.delay(0.2, function()
                                if zombieRef:GetAttribute("WepHitID") == uid then
                                    zombieRef:SetAttribute("WepHitDirection", nil)
                                    zombieRef:SetAttribute("WepHitPos", nil)
                                    zombieRef:SetAttribute("WepHitID", nil)
                                end
                            end)
                        end
                    end
                    return 1
                end
            end
        end
        if originalMeleeHitCheck then
            return originalMeleeHitCheck(self, origin, direction, raycastParams, hitEntities, isCharge)
        end
    end
    return 0
end

local function enableHeadshot()
    if headshotEnabled then return end
    local flintlockSuccess, FlintLock = pcall(require, Weapons:FindFirstChild("Flintlock"))
    if flintlockSuccess and FlintLock and not bayonetHooked then
        originalBayonetHitCheck = FlintLock.BayonetHitCheck
        FlintLock.BayonetHitCheck = customBayonetHitCheck
        bayonetHooked = true
    end
    local meleeSuccess, MeleeBase = pcall(require, Weapons:FindFirstChild("MeleeBase"))
    if meleeSuccess and MeleeBase and not meleeHooked then
        originalMeleeHitCheck = MeleeBase.MeleeHitCheck
        MeleeBase.MeleeHitCheck = customMeleeHitCheck
        meleeHooked = true
    end
    headshotEnabled = true
end

local function disableHeadshot()
    if not headshotEnabled then return end
    if bayonetHooked then
        local flintlockSuccess, FlintLock = pcall(require, Weapons:FindFirstChild("Flintlock"))
        if flintlockSuccess and FlintLock and originalBayonetHitCheck then
            FlintLock.BayonetHitCheck = originalBayonetHitCheck
        end
        bayonetHooked = false
    end
    if meleeHooked then
        local meleeSuccess, MeleeBase = pcall(require, Weapons:FindFirstChild("MeleeBase"))
        if meleeSuccess and MeleeBase and originalMeleeHitCheck then
            MeleeBase.MeleeHitCheck = originalMeleeHitCheck
        end
        meleeHooked = false
    end
    headshotEnabled = false
    originalBayonetHitCheck = nil
    originalMeleeHitCheck = nil
end

local function onHeadshotCharacterAdded()
    if headshotEnabled then
        task.wait(1)
        disableHeadshot()
        task.wait(0.1)
        enableHeadshot()
    end
end

-- ==================== 飞行模块 ====================
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    if getnamecallmethod() == "FireServer" and tostring(self) == "ForceSelfDamage" then return nil end
    return old(self, ...)
end)

local ctrl = require(lp.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local SmoothTurner = {}
SmoothTurner.__index = SmoothTurner

function SmoothTurner.new(rootPart, camera)
    local self = setmetatable({}, SmoothTurner)
    self.RootPart = rootPart
    self.Camera = camera or workspace.CurrentCamera
    self.Enabled = false
    self.BodyGyro = nil
    self.HeartbeatConn = nil
    return self
end

function SmoothTurner:Start()
    if self.Enabled then return end
    if not self.RootPart or not self.RootPart.Parent then return end
    local gyro = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    gyro.P = 50000
    gyro.D = 500
    gyro.CFrame = self.RootPart.CFrame
    gyro.Parent = self.RootPart
    self.BodyGyro = gyro
    self.Enabled = true
    self:_startHeartbeat()
end

function SmoothTurner:Stop()
    if self.BodyGyro then
        self.BodyGyro:Destroy()
        self.BodyGyro = nil
    end
    self.Enabled = false
    if self.HeartbeatConn then
        self.HeartbeatConn:Disconnect()
        self.HeartbeatConn = nil
    end
end

function SmoothTurner:SetDirection(direction)
    if not self.Enabled or not self.BodyGyro or not self.RootPart then return end
    local newCFrame = CFrame.lookAt(self.RootPart.Position, self.RootPart.Position + direction.Unit)
    self.BodyGyro.CFrame = newCFrame
end

function SmoothTurner:_startHeartbeat()
    if self.HeartbeatConn then self.HeartbeatConn:Disconnect() end
    self.HeartbeatConn = Run.RenderStepped:Connect(function()
        if not self.Enabled or not self.BodyGyro or not self.RootPart or not self.Camera then return end
        local look = self.Camera.CFrame.LookVector
        self:SetDirection(look)
    end)
end

function SmoothTurner:Destroy()
    self:Stop()
    self.RootPart = nil
    self.Camera = nil
end

local function clearFlyRes()
    if flyAnim and lp.Character then flyAnim.Parent = lp.Character end
    if bv then bv:Destroy() end
    bv = nil
    if flyTurner then flyTurner:Destroy(); flyTurner = nil end
    local char = lp.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum and hum.Parent then 
        hum:ChangeState(Enum.HumanoidStateType.Running) 
    end
end

local function ensurePhysics(hrp)
    if hrp:FindFirstChild("SB_BV") then hrp.SB_BV:Destroy() end
    bv = Instance.new("BodyVelocity", hrp)
    bv.Name = "SB_BV"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    if flyTurner then flyTurner:Destroy() end
    flyTurner = SmoothTurner.new(hrp, workspace.CurrentCamera)
    flyTurner:Start()
end

local function setFlyEnabled(enabled)
    if enabled == isFlying then return end
    isFlying = enabled
    if enabled then
        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local hum = char:WaitForChild("Humanoid")
        hum.AutoRotate = false
        flyAnim = char:FindFirstChild("Animate")
        if flyAnim then flyAnim.Parent = nil end
        ensurePhysics(hrp)
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = Run.RenderStepped:Connect(function()
            if not isFlying or not char.Parent or not bv or not hum or not hrp.Parent then return end
            local mv = ctrl:GetMoveVector()
            local camCF = cam.CFrame
            local moveDir = Vector3.zero
            if mv.Magnitude > 0 then
                moveDir = (camCF.LookVector * -mv.Z) + (camCF.RightVector * mv.X)
            end
            local upDown = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                upDown = flySpeed
            elseif UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                upDown = -flySpeed
            end
            if moveDir.Magnitude > 0 then
                bv.Velocity = (moveDir.Unit * flySpeed) + Vector3.new(0, upDown, 0)
            else
                bv.Velocity = Vector3.new(0, upDown, 0)
            end
            if hum:GetState() ~= Enum.HumanoidStateType.Climbing then
                hum:ChangeState(Enum.HumanoidStateType.Climbing)
            end
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        clearFlyRes()
        local char = lp.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.AutoRotate = true end
        end
    end
end

lp.CharacterAdded:Connect(function(char)
    if isFlying then
        local wasFlying = isFlying
        clearFlyRes()
        isFlying = false
        task.wait(0.5)
        if wasFlying then
            setFlyEnabled(true)
        end
    end
    task.wait(0.1)
    if not isFlying then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end
    end
end)

-- ==================== 无减速功能 ====================
local function setupNoSlow()
    local char = lp.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if walkSpeedConnection then
        walkSpeedConnection:Disconnect()
        walkSpeedConnection = nil
    end
    walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if noSlowActive and humanoid.WalkSpeed < 16 then
            humanoid.WalkSpeed = 16
        end
    end)
    if noSlowActive and humanoid.WalkSpeed < 16 then
        humanoid.WalkSpeed = 16
    end
end

local function setNoSlowEnabled(enabled)
    noSlowActive = enabled
    if enabled then
        setupNoSlow()
        if noSlowCharacterConnection then
            noSlowCharacterConnection:Disconnect()
        end
        noSlowCharacterConnection = lp.CharacterAdded:Connect(function()
            task.wait(1)
            if noSlowActive then
                setupNoSlow()
            end
        end)
    else
        if walkSpeedConnection then
            walkSpeedConnection:Disconnect()
            walkSpeedConnection = nil
        end
        if noSlowCharacterConnection then
            noSlowCharacterConnection:Disconnect()
            noSlowCharacterConnection = nil
        end
    end
end

-- ==================== 肘击模块 ====================
local function getMeleeWeapon()
    local char = lp.Character
    if not char then return nil end
    for _, item in pairs(char:GetChildren()) do
        if item:GetAttribute("Melee") then
            return item
        end
    end
    for _, item in pairs(lp.Backpack:GetChildren()) do
        if item:GetAttribute("Melee") then
            return item
        end
    end
    return nil
end

local function executeStun(zombie)
    local weapon = getMeleeWeapon()
    if not weapon or weapon.Name ~= "Axe" then return end
    local zombieState = zombie:FindFirstChild("State")
    if zombieState and zombieState.Value == "Stunned" then return end
    local hrp = zombie:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        weapon.RemoteEvent:FireServer("BraceBlock")
        weapon.RemoteEvent:FireServer("StopBraceBlock")
        local Feed = {"FeedbackStun", zombie, hrp.CFrame.Position}
        weapon.RemoteEvent:FireServer(unpack(Feed))
    end)
end

local function startAxeStun()
    if axeStunConnection then
        axeStunConnection:Disconnect()
        axeStunConnection = nil
    end
    axeStunConnection = Run.Heartbeat:Connect(function()
        if not isAxeStunActive then return end
        local char = lp.Character
        if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local zombies = workspace:FindFirstChild("Zombies")
        if not zombies then return end
        local zombiesInRange = {}
        for _, zombie in pairs(zombies:GetChildren()) do
            if zombie:IsA("Model") then
                local zombieHrp = zombie:FindFirstChild("HumanoidRootPart")
                if zombieHrp then
                    local distance = (zombieHrp.Position - hrp.Position).Magnitude
                    if distance <= axeStunDistance then
                        table.insert(zombiesInRange, zombie)
                    end
                end
            end
        end
        table.sort(zombiesInRange, function(a, b)
            local aHrp = a:FindFirstChild("HumanoidRootPart")
            local bHrp = b:FindFirstChild("HumanoidRootPart")
            if not aHrp or not bHrp then return false end
            return (aHrp.Position - hrp.Position).Magnitude < (bHrp.Position - hrp.Position).Magnitude
        end)
        local targetsToStun = {}
        for i = 1, math.min(axeStunMaxTargets, #zombiesInRange) do
            table.insert(targetsToStun, zombiesInRange[i])
        end
        for _, zombie in pairs(targetsToStun) do
            task.spawn(function()
                executeStun(zombie)
            end)
        end
    end)
end

local function stopAxeStun()
    if axeStunConnection then
        axeStunConnection:Disconnect()
        axeStunConnection = nil
    end
end

local function setAxeStunEnabled(enabled)
    isAxeStunActive = enabled
    if enabled then
        startAxeStun()
        if axeStunCharacterConnection then
            axeStunCharacterConnection:Disconnect()
        end
        axeStunCharacterConnection = lp.CharacterAdded:Connect(function()
            stopAxeStun()
            task.wait(1)
            if isAxeStunActive then
                startAxeStun()
            end
        end)
    else
        stopAxeStun()
        if axeStunCharacterConnection then
            axeStunCharacterConnection:Disconnect()
            axeStunCharacterConnection = nil
        end
    end
end

-- ==================== 杀戮光环模块 ====================
local function getMeleeForAura()
    local char = lp.Character
    if not char then return nil end
    for _, item in pairs(char:GetChildren()) do
        if item:GetAttribute("Melee") then
            return item
        end
    end
    for _, item in pairs(lp.Backpack:GetChildren()) do
        if item:GetAttribute("Melee") then
            return item
        end
    end
    return nil
end

local function getAuraDistance(target)
    local char = lp.Character
    if not char or not target or not target:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    return (target.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
end

local function attackZombie(zombie)
    local weapon = getMeleeForAura()
    if not weapon then return end
    
    local range = KILL_AURA_RANGE
    if weapon.Name == "Pike" then
        range = KILL_AURA_RANGE + 1
    elseif weapon.Name == "Axe" then
        range = KILL_AURA_RANGE - 1
    end
    
    local char = lp.Character
    if weapon.Parent ~= char then
        weapon.Parent = char
        task.wait(0.1)
    end
    
    if getAuraDistance(zombie) <= range then
        weapon.RemoteEvent:FireServer("Swing", "Side")
        local head = zombie:FindFirstChild("Head") or zombie:FindFirstChild("HumanoidRootPart")
        if head then
            weapon.RemoteEvent:FireServer("HitZombieM", zombie, head.Position, true)
        end
    end
end

local function attackDracula()
    local weapon = getMeleeForAura()
    if not weapon then return end
    
    local dracula = workspace:FindFirstChild("Transylvania") and 
                   workspace.Transylvania:FindFirstChild("Modes") and
                   workspace.Transylvania.Modes:FindFirstChild("Boss") and
                   workspace.Transylvania.Modes.Boss:FindFirstChild("Dracula")
    if not dracula or not dracula:FindFirstChild("HumanoidRootPart") then return end
    
    local range = KILL_AURA_RANGE
    if weapon.Name == "Pike" then
        range = KILL_AURA_RANGE + 1
    elseif weapon.Name == "Axe" then
        range = KILL_AURA_RANGE - 1
    end
    
    local char = lp.Character
    if weapon.Parent ~= char then
        weapon.Parent = char
        task.wait(0.1)
    end
    
    if getAuraDistance(dracula) <= range then
        weapon.RemoteEvent:FireServer("Swing", "Side")
        local head = dracula:FindFirstChild("Head") or dracula:FindFirstChild("HumanoidRootPart")
        if head then
            weapon.RemoteEvent:FireServer("HitZombieM", dracula, head.Position, true, "Head")
        end
    end
end

local function startKillAura()
    if killAuraConnection then
        killAuraConnection:Disconnect()
        killAuraConnection = nil
    end
    
    killAuraConnection = Run.Heartbeat:Connect(function()
        if not isKillAuraActive then return end
        
        local now = tick()
        if now - killAuraCooldown < KILL_AURA_INTERVAL then return end
        
        local char = lp.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        local zombies = workspace:FindFirstChild("Zombies")
        if not zombies then return end
        
        local zombiesInRange = {}
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        for _, zombie in pairs(zombies:GetChildren()) do
            if zombie:IsA("Model") and zombie:FindFirstChild("HumanoidRootPart") then
                local zombieType = zombie:GetAttribute("Type")
                if zombieType == "Barrel" then
                    -- 不攻击炸药桶
                else
                    local zombieState = zombie:FindFirstChild("State")
                    if zombieState and zombieState.Value ~= "Spawn" then
                        local dist = (zombie.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if dist <= KILL_AURA_RANGE + 2 then
                            table.insert(zombiesInRange, zombie)
                        end
                    end
                end
            end
        end
        
        table.sort(zombiesInRange, function(a, b)
            local aHrp = a:FindFirstChild("HumanoidRootPart")
            local bHrp = b:FindFirstChild("HumanoidRootPart")
            if not aHrp or not bHrp then return false end
            return (aHrp.Position - hrp.Position).Magnitude < (bHrp.Position - hrp.Position).Magnitude
        end)
        
        local targets = {}
        for i = 1, math.min(KILL_AURA_MAX_TARGETS, #zombiesInRange) do
            table.insert(targets, zombiesInRange[i])
        end
        
        for _, zombie in pairs(targets) do
            task.spawn(function()
                attackZombie(zombie)
            end)
        end
        
        if attackDraculaEnabled then
            local dracula = workspace:FindFirstChild("Transylvania") and 
                           workspace.Transylvania:FindFirstChild("Modes") and
                           workspace.Transylvania.Modes:FindFirstChild("Boss") and
                           workspace.Transylvania.Modes.Boss:FindFirstChild("Dracula")
            if dracula and dracula:FindFirstChild("HumanoidRootPart") then
                local dist = (dracula.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist <= KILL_AURA_RANGE + 2 then
                    task.spawn(function()
                        attackDracula()
                    end)
                end
            end
        end
        
        killAuraCooldown = now
    end)
end

local function stopKillAura()
    if killAuraConnection then
        killAuraConnection:Disconnect()
        killAuraConnection = nil
    end
end

local function setKillAuraEnabled(enabled)
    isKillAuraActive = enabled
    if enabled then
        killAuraCooldown = 0
        startKillAura()
        if killAuraCharacterConnection then
            killAuraCharacterConnection:Disconnect()
        end
        killAuraCharacterConnection = lp.CharacterAdded:Connect(function()
            stopKillAura()
            task.wait(1)
            if isKillAuraActive then
                killAuraCooldown = 0
                startKillAura()
            end
        end)
    else
        stopKillAura()
        if killAuraCharacterConnection then
            killAuraCharacterConnection:Disconnect()
            killAuraCharacterConnection = nil
        end
    end
end

-- ==================== UI 构建 ====================

-- 战斗标签页
local CombatGroup1 = CombatTab:AddLeftGroupbox("战斗增强")
CombatGroup1:AddToggle("强制爆头", {
    Default = false,
    Callback = function(value)
        if value then
            enableHeadshot()
            lp.CharacterAdded:Connect(onHeadshotCharacterAdded)
        else
            disableHeadshot()
        end
    end
})

local CombatGroup2 = CombatTab:AddLeftGroupbox("肘击设置")

CombatGroup2:AddSlider("肘击距离", {
    Default = 15,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Callback = function(value)
        axeStunDistance = value
    end
})

local desc1 = Instance.new("TextLabel")
desc1.Parent = CombatGroup2.Container
desc1.Size = UDim2.new(1, -10, 0, 14)
desc1.Position = UDim2.new(0, 5, 0, 30)
desc1.Text = "设置肘击触发距离"
desc1.TextColor3 = Color3.fromRGB(150, 150, 155)
desc1.TextSize = 11
desc1.TextXAlignment = Enum.TextXAlignment.Left
desc1.BackgroundTransparency = 1
desc1.Font = Enum.Font.Gotham

local spacer1 = Instance.new("Frame")
spacer1.Parent = CombatGroup2.Container
spacer1.Size = UDim2.new(1, 0, 0, 10)
spacer1.Position = UDim2.new(0, 0, 0, 44)
spacer1.BackgroundTransparency = 1

CombatGroup2:AddSlider("同时肘击数量", {
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(value)
        axeStunMaxTargets = math.floor(value)
    end
})

local desc2 = Instance.new("TextLabel")
desc2.Parent = CombatGroup2.Container
desc2.Size = UDim2.new(1, -10, 0, 14)
desc2.Position = UDim2.new(0, 5, 0, 30)
desc2.Text = "一次肘击最多攻击僵尸数"
desc2.TextColor3 = Color3.fromRGB(150, 150, 155)
desc2.TextSize = 11
desc2.TextXAlignment = Enum.TextXAlignment.Left
desc2.BackgroundTransparency = 1
desc2.Font = Enum.Font.Gotham

local spacer2 = Instance.new("Frame")
spacer2.Parent = CombatGroup2.Container
spacer2.Size = UDim2.new(1, 0, 0, 10)
spacer2.Position = UDim2.new(0, 0, 0, 44)
spacer2.BackgroundTransparency = 1

CombatGroup2:AddToggle("肘击光环", {
    Default = false,
    Callback = function(value)
        setAxeStunEnabled(value)
    end
})

-- 杀戮光环
local CombatGroup3 = CombatTab:AddLeftGroupbox("杀戮光环")
CombatGroup3:AddToggle("开启杀戮光环", {
    Default = false,
    Callback = function(value)
        setKillAuraEnabled(value)
    end
})

local killDesc = Instance.new("TextLabel")
killDesc.Parent = CombatGroup3.Container
killDesc.Size = UDim2.new(1, -10, 0, 14)
killDesc.Position = UDim2.new(0, 5, 0, 25)
killDesc.Text = "距离5 | 同时攻击2个 | 间隔0.6秒 | 不攻击炸药桶"
killDesc.TextColor3 = Color3.fromRGB(150, 150, 155)
killDesc.TextSize = 11
killDesc.TextXAlignment = Enum.TextXAlignment.Left
killDesc.BackgroundTransparency = 1
killDesc.Font = Enum.Font.Gotham

-- 人物标签页
local CharGroup1 = CharacterTab:AddLeftGroupbox("飞行设置")
CharGroup1:AddSlider("飞行速度", {
    Default = 35,
    Min = 20,
    Max = 200,
    Rounding = 1,
    Callback = function(value)
        flySpeed = value
    end
})

local flyDesc = Instance.new("TextLabel")
flyDesc.Parent = CharGroup1.Container
flyDesc.Size = UDim2.new(1, -10, 0, 14)
flyDesc.Position = UDim2.new(0, 5, 0, 30)
flyDesc.Text = "调整飞行移动速度"
flyDesc.TextColor3 = Color3.fromRGB(150, 150, 155)
flyDesc.TextSize = 11
flyDesc.TextXAlignment = Enum.TextXAlignment.Left
flyDesc.BackgroundTransparency = 1
flyDesc.Font = Enum.Font.Gotham

local spacer3 = Instance.new("Frame")
spacer3.Parent = CharGroup1.Container
spacer3.Size = UDim2.new(1, 0, 0, 10)
spacer3.Position = UDim2.new(0, 0, 0, 44)
spacer3.BackgroundTransparency = 1

CharGroup1:AddToggle("飞行", {
    Default = false,
    Callback = function(value)
        setFlyEnabled(value)
    end
})

local CharGroup2 = CharacterTab:AddLeftGroupbox("移动")
CharGroup2:AddToggle("无减速", {
    Default = false,
    Callback = function(value)
        setNoSlowEnabled(value)
    end
})

-- 设置标签页
local SettingsGroup = SettingsTab:AddLeftGroupbox("界面设置")
SettingsGroup:AddButton("卸载脚本", function()
    if killAuraConnection then killAuraConnection:Disconnect() end
    if axeStunConnection then axeStunConnection:Disconnect() end
    if flyConnection then flyConnection:Disconnect() end
    if walkSpeedConnection then walkSpeedConnection:Disconnect() end
    if killAuraCharacterConnection then killAuraCharacterConnection:Disconnect() end
    if axeStunCharacterConnection then axeStunCharacterConnection:Disconnect() end
    if noSlowCharacterConnection then noSlowCharacterConnection:Disconnect() end
    clearFlyRes()
    disableHeadshot()
    UILibrary:Unload()
end)

-- ==================== 主题和保存 ====================
ThemeManager:SetLibrary(UILibrary)
SaveManager:SetLibrary(UILibrary)
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

-- ==================== 通知 ====================
UILibrary:Notify({
    Title = "SB HUB",
    Text = "已加载 | 按 RightShift 开关菜单",
    Duration = 4
})

-- ==================== 快捷键开关 ====================
local toggleKey = Enum.KeyCode.RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == toggleKey then
        MainWindow:Toggle()
    end
end)

print("✅ SB HUB 已加载 | 使用 Obsidian UI 库")
