--not protected by @nlzz :)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")

local pickUpItemRemote = Remotes and Remotes:FindFirstChild("Interaction") and Remotes.Interaction:FindFirstChild("PickUpItem")
local placeStructureRemote = Remotes and Remotes:FindFirstChild("Building") and Remotes.Building:FindFirstChild("PlaceStructure")
local buyItemRemote = Remotes and Remotes:FindFirstChild("Merchant") and Remotes.Merchant:FindFirstChild("BuyItem")
local addSuppressorRemote = Remotes and Remotes:FindFirstChild("Tools") and Remotes.Tools:FindFirstChild("AddSuppressor")
local adjustBackpackRemote = Remotes and Remotes:FindFirstChild("Tools") and Remotes.Tools:FindFirstChild("AdjustBackpack")
local resetRemote = Remotes and Remotes:FindFirstChild("Misc") and Remotes.Misc:FindFirstChild("Reset")

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
Title = "SPYMM v8.2",
Footer = "Survive the Apocalypse",
NotifySide = "Right",
ShowCustomCursor = true,
})

local Tabs = {
Visuals = Window:AddTab("视觉", "eye"),
Player = Window:AddTab("玩家", "user"),
Combat = Window:AddTab("战斗", "swords"),
Exploits = Window:AddTab("漏洞利用", "zap"),
Misc = Window:AddTab("杂项", "settings"),
["UI Settings"] = Window:AddTab("界面设置", "sliders-horizontal"),
}

local connections = {}
local mobESPInstances = {}
local playerESPInstances = {}
local structureESPInstances = {}
local flyBV, flyBG = nil, nil
local flyActive = false
local antiAFKConn = nil
local autoSprintActive = false
local killAuraConn = nil
local aimbotConn = nil
local aimbotTarget = nil
local fovCircle = nil
local killAuraIndicatorLine = nil
local killAuraIndicatorCircle = nil
local repairAuraConn = nil

local originalValues = {
walkSpeed = nil,
}

local originalLighting = { stored = false }
local originalFog = { stored = false }

local mobOptions = { ESP = false, Chams = false, Name = false, Distance = false }
local playerESPVars = { ESP = false, Chams = false, Name = false, Distance = false, Health = false }
local structureESPVars = { ESP = false, Chams = false, Name = false, Distance = false }
local bhopActive = false
local bhopConn = nil
local remoteSpyEnabled = false
local remoteSpyLogs = {}

local mobNames = {"Runner", "Crawler", "Riot", "Zombie", "Brute", "Spitter", "Boss"}

local espConfig = {
textSize = 10,
fillTransparency = 0.4,
outlineTransparency = 0.0,
}

local espDefinitions = {
{
key = "Gun",
displayName = "枪械透视",
icon = "crosshair",
items = {
"AA-12", "AK-47", "Assault Rifle", "Desert Eagle", "Double Barrel",
"Flamethrower", "Grenade Launcher", "LMG", "MediGun", "Pistol",
"Ray Gun", "Revolver", "Rifle", "Shotgun", "Sniper", "SVD", "Uzi"
},
colors = { fill = Color3.fromRGB(255, 30, 30), outline = Color3.fromRGB(255, 255, 255), text = Color3.fromRGB(255, 120, 120) },
},
{
key = "Melee",
displayName = "近战武器透视",
icon = "swords",
items = {
"Bat", "Chainsaw", "Crowbar", "Fire Axe", "Hatchet", "Katana", "Knife",
"Riot Shield", "Scythe", "Sledgehammer", "Spear", "Spiked Bat"
},
colors = { fill = Color3.fromRGB(255, 140, 0), outline = Color3.fromRGB(255, 255, 255), text = Color3.fromRGB(255, 200, 100) },
},
{
key = "Medical",
displayName = "医疗物品透视",
icon = "heart-pulse",
items = {
"Bandage", "Compound H", "Compound I", "Compound R", "Compound S", "Medkit"
},
colors = { fill = Color3.fromRGB(0, 255, 80), outline = Color3.fromRGB(255, 255, 255), text = Color3.fromRGB(150, 255, 150) },
},
{
key = "Armor",
displayName = "护甲透视",
icon = "shield",
items = {
"Power Armor", "Light Armor", "Medium Armor", "Heavy Armor"
},
colors = { fill = Color3.fromRGB(0, 100, 255), outline = Color3.fromRGB(255, 255, 255), text = Color3.fromRGB(160, 200, 255) },
},
{
key = "Food",
displayName = "食物透视",
icon = "utensils",
items = {
"Chips", "Carrot", "Bloxiade", "Beans", "MRE", "Bloxy Cola"
},
colors = { fill = Color3.fromRGB(190, 255, 0), outline = Color3.fromRGB(255, 255, 255), text = Color3.fromRGB(210, 255, 150) },
},
{
key = "Resource",
displayName = "资源透视",
icon = "box",
items = {
"AC", "Battery", "Battery Pack", "Bucket", "Dumbell", "Exhaust Pipe",
"Reactor Component", "Refined Metal", "Satellite Dish", "Scrap",
"Screws", "Spatula", "Tray", "TV", "Watch", "Zombie Heart"
},
colors = { fill = Color3.fromRGB(0, 220, 255), outline = Color3.fromRGB(255, 255, 255), text = Color3.fromRGB(180, 240, 255) },
},
{
key = "Fuel",
displayName = "燃料透视",
icon = "zap",
items = { "Nuclear Fuel", "Refined Fuel", "Fuel" },
colors = { fill = Color3.fromRGB(255, 220, 0), outline = Color3.fromRGB(255, 255, 255), text = Color3.fromRGB(255, 240, 160) },
},
{
key = "Ability",
displayName = "技能透视",
icon = "zap-circle",
items = {
"Airstrike", "Attack Order", "Call of the Dead",
"Summon Brute", "Summon Zombies", "Taunt",
"The Future", "The Past", "The Present"
},
colors = { fill = Color3.fromRGB(180, 0, 255), outline = Color3.fromRGB(255, 255, 255), text = Color3.fromRGB(220, 150, 255) },
},
}

local espSystems = {}

for _, def in ipairs(espDefinitions) do
local sys = {
key = def.key,
displayName = def.displayName,
colors = def.colors,
items = def.items,
itemList = {},
vars = { ESP = false, Chams = false, Name = false, Distance = false },
instances = {},
listenersSetup = false,
}
for _, name in ipairs(def.items) do
sys.itemList[name] = true
end
espSystems[def.key] = sys
end

local itemNames = {}
local itemCategoryLookup = {}
for _, def in ipairs(espDefinitions) do
for _, itemName in ipairs(def.items) do
table.insert(itemNames, itemName)
itemCategoryLookup[itemName] = def.key
end
end

local extraItemCategories = {
Ammo = { "Ammo Box", "Long Ammo", "Medium Ammo", "Pistol Ammo", "Shells" },
Structures = {
"Ammo Crate", "Barbed Wire", "Bear Trap", "Boost Pad", "Electric Fence",
"Farm Plot", "Fence", "Floodlight", "Gate", "Landmine", "Map",
"Repair Drone", "Shelf", "Teleporter", "Time Machine", "Turret",
"Wall", "Watchtower"
},
Consumables = { "Grenade", "Molotov" },
Backpacks = { "Basic Backpack", "Good Backpack", "Great Backpack" },
MiscItems = {
"Emerald", "Gas Mask", "Power Armor Arm", "Power Armor Core",
"Radio Tower Part", "Blueprint", "Military Keycard", "Repair Hammer", "Suppressor"
},
}
for catName, catItems in pairs(extraItemCategories) do
for _, itemName in ipairs(catItems) do
table.insert(itemNames, itemName)
itemCategoryLookup[itemName] = catName
end
end
table.sort(itemNames)

local pickupItemSet = {
["Ammo Box"]=true,["Long Ammo"]=true,["Medium Ammo"]=true,["Shells"]=true,["Pistol Ammo"]=true,
["Power Armor"]=true,["Light Armor"]=true,["Medium Armor"]=true,["Heavy Armor"]=true,
["Emerald"]=true,["Gas Mask"]=true,
["Ammo Crate"]=true,["Barbed Wire"]=true,["Bear Trap"]=true,["Boost Pad"]=true,
["Electric Fence"]=true,["Farm Plot"]=true,["Fence"]=true,["Floodlight"]=true,
["Gate"]=true,["Landmine"]=true,["Map"]=true,["Repair Drone"]=true,["Shelf"]=true,
["Teleporter"]=true,["Time Machine"]=true,["Turret"]=true,["Wall"]=true,["Watchtower"]=true,
["Basic Backpack"]=true,["Good Backpack"]=true,["Great Backpack"]=true,
["Grenade"]=true,["Molotov"]=true,
["AA-12"]=true,["AK-47"]=true,["Assault Rifle"]=true,["Desert Eagle"]=true,
["Double Barrel"]=true,["Flamethrower"]=true,["Grenade Launcher"]=true,["LMG"]=true,
["MediGun"]=true,["Pistol"]=true,["Ray Gun"]=true,["Revolver"]=true,["Rifle"]=true,
["Shotgun"]=true,["Sniper"]=true,["SVD"]=true,["Uzi"]=true,
["Bandage"]=true,["Compound H"]=true,["Compound I"]=true,["Compound R"]=true,
["Compound S"]=true,["Medkit"]=true,
["Bat"]=true,["Chainsaw"]=true,["Crowbar"]=true,["Fire Axe"]=true,["Hatchet"]=true,
["Katana"]=true,["Knife"]=true,["Riot Shield"]=true,["Scythe"]=true,
["Sledgehammer"]=true,["Spear"]=true,["Spiked Bat"]=true,
["Blueprint"]=true,["Military Keycard"]=true,["Repair Hammer"]=true,["Suppressor"]=true,
}
local pickupItemNames = {}
for k in pairs(pickupItemSet) do table.insert(pickupItemNames, k) end
table.sort(pickupItemNames)

local structureNames = {
"Ammo Crate", "Barbed Wire", "Bear Trap", "Boost Pad", "Electric Fence",
"Farm Plot", "Fence", "Floodlight", "Gate", "Landmine", "Map", "Repair Drone",
"Shelf", "Teleporter", "Time Machine", "Turret", "Wall", "Watchtower"
}

local charactersFolder = nil
local droppedItemsFolder = nil
local structuresFolder = nil
local mobListenersSetup = false
local structureListenersSetup = false

local function discoverFolders()
charactersFolder = Workspace:FindFirstChild("Characters")
droppedItemsFolder = Workspace:FindFirstChild("DroppedItems")
structuresFolder = Workspace:FindFirstChild("Structures")
or Workspace:FindFirstChild("PlayerStructures")
or Workspace:FindFirstChild("Buildings")
end
discoverFolders()

task.spawn(function()
while not Library.Unloaded do
task.wait(5)
local prevChars = charactersFolder
local prevItems = droppedItemsFolder
local prevStructs = structuresFolder
discoverFolders()
if charactersFolder ~= prevChars and charactersFolder then
refreshMobESP()
if not mobListenersSetup then setupMobListeners() end
end
if droppedItemsFolder ~= prevItems and droppedItemsFolder then
for _, sys in pairs(espSystems) do
sys.refresh()
end
for _, sys in pairs(espSystems) do
if not sys.listenersSetup then sys.setupListeners() end
end
end
if structuresFolder ~= prevStructs and structuresFolder then
refreshStructureESP()
if not structureListenersSetup then setupStructureListeners() end
end
end
end)

local function getItemMainPart(item)
if item.PrimaryPart then return item.PrimaryPart end
for _, child in ipairs(item:GetChildren()) do
if child:IsA("BasePart") then
return child
end
end
return nil
end

local function getDistanceColor(dist)
if dist > 250 then return Color3.fromRGB(255, 80, 80)
elseif dist > 150 then return Color3.fromRGB(255, 180, 80)
elseif dist > 100 then return Color3.fromRGB(255, 255, 80)
else return Color3.fromRGB(220, 220, 220) end
end

local function getHealthColor(pct)
if pct > 0.6 then return Color3.fromRGB(80, 255, 80)
elseif pct > 0.3 then return Color3.fromRGB(255, 230, 50)
else return Color3.fromRGB(255, 60, 60) end
end

local function createHealthBar(parent, height, width, position)
local bg = Instance.new("Frame")
bg.Name = "HealthBarBG"
bg.Size = UDim2.new(width, 0, height, 0)
bg.Position = position
bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
bg.BackgroundTransparency = 0.2
bg.BorderSizePixel = 0
bg.Parent = parent

end

local function updateHealthBar(fill, pct, color)
fill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
fill.BackgroundColor3 = color
end

local function createTextBG(parent, size, position)
local bg = Instance.new("Frame")
bg.Name = "TextBG"
bg.Size = size
bg.Position = position
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.5
bg.BorderSizePixel = 0
bg.ZIndex = -1
bg.Parent = parent
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = bg
return bg
end

local MOB_RED = { fill = Color3.fromRGB(255, 30, 30), outline = Color3.fromRGB(255, 120, 120) }
local mobTypeColors = {
Zombie = MOB_RED, Runner = MOB_RED, Crawler = MOB_RED,
Brute = MOB_RED, Spitter = MOB_RED, Riot = MOB_RED, Boss = MOB_RED,
}

local function createCategoryESP(sys, item)
if not item:IsA("Model") then return end
if sys.instances[item] then return end

end

local function removeCategoryESP(sys, item)
local esp = sys.instances[item]
if esp then
if esp.Highlight then esp.Highlight:Destroy() end
if esp.Billboard then esp.Billboard:Destroy() end
if esp.DistanceConnection then esp.DistanceConnection:Disconnect() end
sys.instances[item] = nil
end
end

local function refreshCategoryESP(sys)
for item, _ in pairs(sys.instances) do
removeCategoryESP(sys, item)
end
if not sys.vars.ESP then return end
if not droppedItemsFolder then return end
for _, child in ipairs(droppedItemsFolder:GetChildren()) do
if sys.itemList[child.Name] then
createCategoryESP(sys, child)
end
end
end

local function setupCategoryListeners(sys)
if not droppedItemsFolder or sys.listenersSetup then return end
sys.listenersSetup = true
local addedConn = droppedItemsFolder.ChildAdded:Connect(function(child)
if sys.vars.ESP and sys.itemList[child.Name] then
task.wait(0.2)
createCategoryESP(sys, child)
end
end)
table.insert(connections, addedConn)
local removedConn = droppedItemsFolder.ChildRemoved:Connect(function(child)
removeCategoryESP(sys, child)
end)
table.insert(connections, removedConn)
end

for _, sys in pairs(espSystems) do
sys.create = function(item) createCategoryESP(sys, item) end
sys.remove = function(item) removeCategoryESP(sys, item) end
sys.refresh = function() refreshCategoryESP(sys) end
sys.setupListeners = function() setupCategoryListeners(sys) end
end

for _, sys in pairs(espSystems) do
setupCategoryListeners(sys)
end

local function removeMobESP(char)
local esp = mobESPInstances[char]
if esp then
if esp.Highlight then esp.Highlight:Destroy() end
if esp.Billboard then esp.Billboard:Destroy() end
if esp.DistanceConnection then esp.DistanceConnection:Disconnect() end
mobESPInstances[char] = nil
end
end

local function createMobESP(char)
if not char:IsA("Model") then return end
if mobESPInstances[char] then return end

end

local function refreshMobESP()
for char, _ in pairs(mobESPInstances) do
removeMobESP(char)
end
if not mobOptions.ESP then return end
if not charactersFolder then
Library:Notify({ Title = "怪物透视", Description = "未找到角色文件夹（正在重试...）", Time = 3 })
return
end
local playerCharSet = {}
for _, p in ipairs(Players:GetPlayers()) do
if p.Character then playerCharSet[p.Character] = true end
end
for _, child in ipairs(charactersFolder:GetChildren()) do
if child:IsA("Model") and not playerCharSet[child] then
createMobESP(child)
end
end
end

local function setupMobListeners()
if not charactersFolder or mobListenersSetup then return end
mobListenersSetup = true
local addedConn = charactersFolder.ChildAdded:Connect(function(child)
if mobOptions.ESP and child:IsA("Model") then
task.wait(0.3)
createMobESP(child)
end
end)
table.insert(connections, addedConn)
local removedConn = charactersFolder.ChildRemoved:Connect(function(child)
removeMobESP(child)
end)
table.insert(connections, removedConn)
end

local function removeStructureESP(structure)
local esp = structureESPInstances[structure]
if esp then
if esp.Highlight then esp.Highlight:Destroy() end
if esp.Billboard then esp.Billboard:Destroy() end
if esp.DistanceConnection then esp.DistanceConnection:Disconnect() end
structureESPInstances[structure] = nil
end
end

local function createStructureESP(structure)
if not structure:IsA("Model") then return end
if structureESPInstances[structure] then return end

end

local function refreshStructureESP()
for structure, _ in pairs(structureESPInstances) do
removeStructureESP(structure)
end
if not structureESPVars.ESP then return end
if not structuresFolder then
Library:Notify({ Title = "建筑透视", Description = "未找到建筑文件夹（正在重试...）", Time = 3 })
return
end
for _, child in ipairs(structuresFolder:GetChildren()) do
if child:IsA("Model") then
createStructureESP(child)
end
end
end

local function setupStructureListeners()
if not structuresFolder or structureListenersSetup then return end
structureListenersSetup = true
local addedConn = structuresFolder.ChildAdded:Connect(function(child)
if structureESPVars.ESP and child:IsA("Model") then
task.wait(0.3)
createStructureESP(child)
end
end)
table.insert(connections, addedConn)
local removedConn = structuresFolder.ChildRemoved:Connect(function(child)
removeStructureESP(child)
end)
table.insert(connections, removedConn)
end

local function removePlayerESP(player)
local esp = playerESPInstances[player]
if esp then
if esp.ESP then esp.ESP:Destroy() end
if esp.Highlight then esp.Highlight:Destroy() end
if esp.Billboard then esp.Billboard:Destroy() end
if esp.DistanceConnection then esp.DistanceConnection:Disconnect() end
playerESPInstances[player] = nil
end
end

local function createPlayerESP(player)
local char = player.Character
if not char then return end
if playerESPInstances[player] then return end

end

local function refreshPlayerESP()
for player, _ in pairs(playerESPInstances) do
removePlayerESP(player)
end
if not playerESPVars.ESP then return end
for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer and player.Character then
createPlayerESP(player)
end
end
end

local function setupPlayerListeners()
local playerAddedConn = Players.PlayerAdded:Connect(function(player)
player.CharacterAdded:Connect(function(char)
if playerESPVars.ESP then
task.wait(1)
if player ~= LocalPlayer then
createPlayerESP(player)
end
end
end)
end)
table.insert(connections, playerAddedConn)

end

local function setupAntiAFK()
local player = LocalPlayer
if antiAFKConn then antiAFKConn:Disconnect() end
antiAFKConn = player.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end

local function disableAntiAFK()
if antiAFKConn then
antiAFKConn:Disconnect()
antiAFKConn = nil
end
end

local function setupBunnyHop()
if bhopConn then bhopConn:Disconnect() end
if not bhopActive then return end
bhopConn = RunService.Stepped:Connect(function(_, dt)
local char = LocalPlayer.Character
local humanoid = char and char:FindFirstChildOfClass("Humanoid")
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not humanoid or not hrp or humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
if humanoid.FloorMaterial ~= Enum.Material.Air then
humanoid.Jump = true
end
end
end)
end

local function startFly()
local char = LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not hrp then return end
if flyActive then return end
flyActive = true
flyBV = Instance.new("BodyVelocity")
flyBV.Name = "FlyBodyVelocity"
flyBV.Velocity = Vector3.new(0, 0, 0)
flyBV.MaxForce = Vector3.new(1, 1, 1) * 40000
flyBV.P = 30000
flyBV.Parent = hrp

end

local function stopFly()
flyActive = false
if flyBV then flyBV:Destroy(); flyBV = nil end
if flyBG then flyBG:Destroy(); flyBG = nil end
end

local function setupKillAura(range, teamCheck, playerCheck)
if killAuraConn then killAuraConn:Disconnect() end

end

local function setupAimbot(aimbotKey, smoothness, fovRadius, teamCheck, playerCheck)
if aimbotConn then aimbotConn:Disconnect() end
local userInput = UserInputService
aimbotConn = RunService.RenderStepped:Connect(function()
local char = LocalPlayer.Character
if not char then return end
local humanoid = char:FindFirstChildOfClass("Humanoid")
if not humanoid or humanoid.Health <= 0 then return end

end

local function setupRepairAura(range, repairDroneCheck)
if repairAuraConn then repairAuraConn:Disconnect() end
local player = LocalPlayer
repairAuraConn = RunService.Heartbeat:Connect(function()
local char = player.Character
if not char then return end
local humanoid = char:FindFirstChildOfClass("Humanoid")
if not humanoid or humanoid.Health <= 0 then return end

end

local function setupAutoSprint()
if autoSprintActive then return end
autoSprintActive = true
local conn = RunService.Stepped:Connect(function(_, dt)
local char = LocalPlayer.Character
local humanoid = char and char:FindFirstChildOfClass("Humanoid")
if humanoid and humanoid.MoveDirection.Magnitude > 0 then
humanoid.WalkSpeed = 24
else
humanoid.WalkSpeed = originalValues.walkSpeed or 16
end
end)
table.insert(connections, conn)
end

local function disableAutoSprint()
autoSprintActive = false
if LocalPlayer.Character then
local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if humanoid then humanoid.WalkSpeed = originalValues.walkSpeed or 16 end
end
end

local function saveLighting()
if not originalLighting.stored then
originalLighting = {
stored = true,
Ambient = Lighting.Ambient,
Brightness = Lighting.Brightness,
ColorShift_Bottom = Lighting.ColorShift_Bottom,
ColorShift_Top = Lighting.ColorShift_Top,
ExposureCompensation = Lighting.ExposureCompensation,
FogColor = Lighting.FogColor,
FogEnd = Lighting.FogEnd,
FogStart = Lighting.FogStart,
OutdoorAmbient = Lighting.OutdoorAmbient,
ClockTime = Lighting.ClockTime,
GeographicLatitude = Lighting.GeographicLatitude,
}
originalFog = {
stored = true,
FogColor = Lighting.FogColor,
FogEnd = Lighting.FogEnd,
FogStart = Lighting.FogStart,
}
end
end

local function restoreLighting()
if originalLighting.stored then
Lighting.Ambient = originalLighting.Ambient
Lighting.Brightness = originalLighting.Brightness
Lighting.ColorShift_Bottom = originalLighting.ColorShift_Bottom
Lighting.ColorShift_Top = originalLighting.ColorShift_Top
Lighting.ExposureCompensation = originalLighting.ExposureCompensation
Lighting.FogColor = originalLighting.FogColor
Lighting.FogEnd = originalLighting.FogEnd
Lighting.FogStart = originalLighting.FogStart
Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
Lighting.ClockTime = originalLighting.ClockTime
Lighting.GeographicLatitude = originalLighting.GeographicLatitude
end
end

local function setupRemoteSpy()
if not remoteSpyEnabled then return end
remoteSpyLogs = {}
local remotesTable = {
PickUpItem = pickUpItemRemote,
PlaceStructure = placeStructureRemote,
BuyItem = buyItemRemote,
AddSuppressor = addSuppressorRemote,
AdjustBackpack = adjustBackpackRemote,
Reset = resetRemote,
}
for name, remote in pairs(remotesTable) do
if remote then
local conn = remote.OnClientEvent:Connect(function(...)
table.insert(remoteSpyLogs, {
Time = os.date("%H:%M:%S"),
Remote = name,
Arguments = {...},
})
end)
table.insert(connections, conn)
end
end
end

local function pickupItem(itemName)
if not pickUpItemRemote then
Library:Notify({ Title = "错误", Description = "未找到拾取物品的远程事件", Time = 3 })
return
end
if not droppedItemsFolder then
Library:Notify({ Title = "错误", Description = "未找到掉落物品文件夹", Time = 3 })
return
end
local item = droppedItemsFolder:FindFirstChild(itemName)
if not item then
Library:Notify({ Title = "错误", Description = "物品未找到: " .. itemName, Time = 3 })
return
end
pickUpItemRemote:FireServer(item)
Library:Notify({ Title = "拾取", Description = "已拾取 " .. itemName, Time = 2 })
end

local function autofarmItems(whitelist, range)
if not pickUpItemRemote then return end
local char = LocalPlayer.Character
if not char then return end
local root = char:FindFirstChild("HumanoidRootPart")
if not root then return end
if not droppedItemsFolder then return end
for _, item in ipairs(droppedItemsFolder:GetChildren()) do
if whitelist[item.Name] then
local mainPart = getItemMainPart(item)
if mainPart then
local dist = (root.Position - mainPart.Position).Magnitude
if dist <= range then
pickUpItemRemote:FireServer(item)
end
end
end
end
end

local function resetCharacter()
if resetRemote then
resetRemote:FireServer()
end
end

local function teleportToPlayer(targetPlayer)
local char = LocalPlayer.Character
if not char then return end
local targetChar = targetPlayer.Character
if not targetChar then return end
local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
if not targetRoot then return end
local root = char:FindFirstChild("HumanoidRootPart")
if root then
root.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
end
end

local function teleportToServer(replaceIndex, serverIndex)
local servers = {}
local HttpService = game:GetService("HttpService")
local success, result = pcall(function()
return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
end)
if not success or not result or not result.data then return end
for _, server in ipairs(result.data) do
if server.playing < server.maxPlayers then
table.insert(servers, server.id)
end
end
if #servers > 0 then
TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[serverIndex] or servers[1])
end
end

local function loadConfig(configName)
if SaveManager then
SaveManager.Load(configName)
end
end

local function saveConfig(configName)
if SaveManager then
SaveManager.Save(configName)
end
end

local function applyTheme(themeName)
if ThemeManager then
ThemeManager:SetTheme(themeName)
end
end

local function autoSellItems(itemNamesList)
local merchantRemote = buyItemRemote
if not merchantRemote then
Library:Notify({ Title = "错误", Description = "未找到商人远程事件", Time = 3 })
return
end
for _, itemName in ipairs(itemNamesList) do
merchantRemote:FireServer(itemName, "Sell")
end
end

local function autoBuyItem(itemName)
if not buyItemRemote then
Library:Notify({ Title = "错误", Description = "未找到购买物品的远程事件", Time = 3 })
return
end
buyItemRemote:FireServer(itemName, "Buy")
end

local function equipTool(toolName)
local char = LocalPlayer.Character
if not char then return end
local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
local tool = backpack and backpack:FindFirstChild(toolName)
if tool then
tool.Parent = char
end
end

local function unequipTools()
local char = LocalPlayer.Character
if not char then return end
for _, tool in ipairs(char:GetChildren()) do
if tool:IsA("Tool") then
tool.Parent = LocalPlayer:FindFirstChildOfClass("Backpack")
end
end
end

-- UI Setup
local VisualsGroup = Tabs.Visuals:AddSection("项目透视")
for _, def in ipairs(espDefinitions) do
local sys = espSystems[def.key]
local itemGroup = Tabs.Visuals:AddSection(def.displayName)
sys.vars.ESP = Toggles.ESP:AddToggle({
Name = def.displayName,
Default = false,
Callback = function(val)
sys.vars.ESP = val
if val then
sys.refresh()
if not sys.listenersSetup then sys.setupListeners() end
else
for item, _ in pairs(sys.instances) do
sys.remove(item)
end
end
end,
})
sys.vars.Chams = Toggles.ESP:AddToggle({
Name = def.displayName .. " 角色上色",
Default = false,
Callback = function(val)
sys.vars.Chams = val
sys.refresh()
end,
})
sys.vars.Name = Toggles.ESP:AddToggle({
Name = def.displayName .. " 名称",
Default = false,
Callback = function(val)
sys.vars.Name = val
sys.refresh()
end,
})
sys.vars.Distance = Toggles.ESP:AddToggle({
Name = def.displayName .. " 距离",
Default = false,
Callback = function(val)
sys.vars.Distance = val
sys.refresh()
end,
})
end

local MobGroup = Tabs.Visuals:AddSection("怪物透视")
mobOptions.ESP = Toggles.ESP:AddToggle({
Name = "怪物透视",
Default = false,
Callback = function(val)
mobOptions.ESP = val
refreshMobESP()
if not mobListenersSetup then setupMobListeners() end
end,
})
mobOptions.Chams = Toggles.ESP:AddToggle({
Name = "怪物角色上色",
Default = false,
Callback = function(val)
mobOptions.Chams = val
refreshMobESP()
end,
})
mobOptions.Name = Toggles.ESP:AddToggle({
Name = "怪物名称",
Default = false,
Callback = function(val)
mobOptions.Name = val
refreshMobESP()
end,
})
mobOptions.Distance = Toggles.ESP:AddToggle({
Name = "怪物距离",
Default = false,
Callback = function(val)
mobOptions.Distance = val
refreshMobESP()
end,
})

local PlayerGroup = Tabs.Visuals:AddSection("玩家透视")
playerESPVars.ESP = Toggles.ESP:AddToggle({
Name = "玩家透视",
Default = false,
Callback = function(val)
playerESPVars.ESP = val
refreshPlayerESP()
end,
})
playerESPVars.Name = Toggles.ESP:AddToggle({
Name = "玩家名称",
Default = false,
Callback = function(val)
playerESPVars.Name = val
refreshPlayerESP()
end,
})
playerESPVars.Distance = Toggles.ESP:AddToggle({
Name = "玩家距离",
Default = false,
Callback = function(val)
playerESPVars.Distance = val
refreshPlayerESP()
end,
})
playerESPVars.Health = Toggles.ESP:AddToggle({
Name = "玩家血量",
Default = false,
Callback = function(val)
playerESPVars.Health = val
refreshPlayerESP()
end,
})

local StructureGroup = Tabs.Visuals:AddSection("建筑透视")
structureESPVars.ESP = Toggles.ESP:AddToggle({
Name = "建筑透视",
Default = false,
Callback = function(val)
structureESPVars.ESP = val
refreshStructureESP()
if not structureListenersSetup then setupStructureListeners() end
end,
})
structureESPVars.Chams = Toggles.ESP:AddToggle({
Name = "建筑角色上色",
Default = false,
Callback = function(val)
structureESPVars.Chams = val
refreshStructureESP()
end,
})
structureESPVars.Name = Toggles.ESP:AddToggle({
Name = "建筑名称",
Default = false,
Callback = function(val)
structureESPVars.Name = val
refreshStructureESP()
end,
})
structureESPVars.Distance = Toggles.ESP:AddToggle({
Name = "建筑距离",
Default = false,
Callback = function(val)
structureESPVars.Distance = val
refreshStructureESP()
end,
})

Options.ESPMaxDistance = Tabs.Visuals:AddSlider("透视最大距离", {
Min = 50,
Max = 2000,
Default = 500,
Increment = 50,
Callback = function(val) end,
})

Tabs.Player:AddSection("玩家增强")
Toggles.Player:AddToggle({
Name = "飞行模式",
Default = false,
Callback = function(val)
if val then startFly() else stopFly() end
end,
})
Toggles.Player:AddToggle({
Name = "自动冲刺",
Default = false,
Callback = function(val)
if val then setupAutoSprint() else disableAutoSprint() end
end,
})
Toggles.Player:AddToggle({
Name = "兔子跳",
Default = false,
Callback = function(val)
bhopActive = val
if val then setupBunnyHop() else if bhopConn then bhopConn:Disconnect(); bhopConn = nil end end
end,
})
Toggles.Player:AddToggle({
Name = "防挂机",
Default = false,
Callback = function(val)
if val then setupAntiAFK() else disableAntiAFK() end
end,
})
Tabs.Player:AddButton("重置角色", resetCharacter)

local PlayerList = {}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then table.inser
