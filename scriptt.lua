--[[ KAVO UI ]]
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"
))()

local Window = Library.CreateLib("cmajor7 hub", "DarkTheme")

--[[ SHARED STATE ]]
local State = {
    AutoCollect = false,
    AutoPotion  = false,
    AutoEgg     = false,
    LearnedIDs  = {},
    SelectedEggs = {},
    EggDelay = 1
}

--[[ SERVICES ]]
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local remoteEvent = RS:WaitForChild("Msg"):WaitForChild("RemoteEvent")
local remoteFunc  = RS:WaitForChild("Msg"):WaitForChild("RemoteFunction")
local magicShop   = player:WaitForChild("MagicShop") -- IMPORTANT

--[[ COMMANDS (PLAIN UTF-8) ]]
local CMD_COLLECT = "领取动物赚的钱"
local CMD_POTION = "购买魔法药水"
local CMD_EGG    = "购买蛋"

--[[ EGG CONFIG ]]
local OrderedEggNames = {
    "Plain Egg","Mud Egg","Speckled Egg","Hydro Egg",
    "Tentacle Egg","Frost Egg","Demon Egg","Horn Egg","Cacti Egg",
    "Volt Egg","Plume Egg","Tiger Egg"
}

local EggList = {
    ["Plain Egg"]="Egg_7000001",
    ["Mud Egg"]="Egg_7000002",
    ["Speckled Egg"]="Egg_7000003",
    ["Hydro Egg"]="Egg_7000004",
    ["Tentacle Egg"]="Egg_7000005",
    ["Frost Egg"]="Egg_7000006",
    ["Demon Egg"]="Egg_7000007",
    ["Horn Egg"]="Egg_7000008",
    ["Cacti Egg"]="Egg_7000009",
    ["Volt Egg"]="Egg_7000010",
    ["Plume Egg"]="Egg_7000011",
    ["Tiger Egg"]="Egg_7000012"
}

--[[ UI TABS ]]
local FarmTab = Window:NewTab("Farming")
local EggTab  = Window:NewTab("Eggs & Potions")

--[[ FARM SECTION ]]
local FarmSection = FarmTab:NewSection("Animal Collection")

FarmSection:NewToggle("Auto Collect Animals (Collect Manually Once)", "Collect once manually to teach IDs", function(v)
    State.AutoCollect = v
end)

FarmSection:NewButton("Clear Learned Animals", "Reset learned IDs", function()
    table.clear(State.LearnedIDs)
end)

--[[ POTION SECTION ]]
local PotionSection = FarmTab:NewSection("Auto Potions")

PotionSection:NewToggle("Auto Buy Potions", "Buys potions when restocked", function(v)
    State.AutoPotion = v
end)

--[[ EGG UI ]]
local EggSelect = EggTab:NewSection("Select Eggs")

for _, name in ipairs(OrderedEggNames) do
    local id = EggList[name]
    EggSelect:NewToggle(name, "Include this egg", function(v)
        if v then
            State.SelectedEggs[name] = id
        else
            State.SelectedEggs[name] = nil
        end
    end)
end

local EggControl = EggTab:NewSection("Egg Control")

EggControl:NewToggle("Auto Buy Eggs", "Enable egg buyer", function(v)
    State.AutoEgg = v
end)

EggControl:NewSlider("Egg Delay", "Seconds between purchases", 5, 1, function(v)
    State.EggDelay = v
end)

--[[ CORE LOGIC ]]

-- AUTO COLLECT LOOP
task.spawn(function()
    while true do
        if State.AutoCollect then
            for _, id in ipairs(State.LearnedIDs) do
                remoteEvent:FireServer(CMD_COLLECT, id)
            end
        end
        task.wait(0.5)
    end
end)

-- AUTO POTION LOOP
task.spawn(function()
    local stockIDs = {"15000001","15000002","15000003"}
    while true do
        if State.AutoPotion then
            for _, id in ipairs(stockIDs) do
                local item = magicShop:FindFirstChild(id)
                if item and item.Value > 0 then
                    remoteFunc:InvokeServer(CMD_POTION, {id})
                    task.wait(0.2)
                end
            end
        end
        task.wait(2)
    end
end)

-- EGG FINDER
local function getEggOnConveyor(id)
    local scene = workspace:FindFirstChild("战斗场景")
    if not scene then return end
    local belt = scene.aramsumsumguriguri:FindFirstChild("传送带上的蛋")
    return belt and belt:FindFirstChild(id)
end

-- AUTO EGG LOOP
task.spawn(function()
    while true do
        if State.AutoEgg then
            for _, eggID in pairs(State.SelectedEggs) do
                local egg = getEggOnConveyor(eggID)
                if egg then
                    remoteEvent:FireServer(CMD_EGG, egg)
                    task.wait(State.EggDelay)
                end
            end
        end
        task.wait(0.5)
    end
end)

--[[ SINGLE LEARNING HOOK ]]
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    if self == remoteEvent and method == "FireServer" and args[1] == CMD_COLLECT then
        local id = args[2]
        if typeof(id) == "number" then
            for _, v in ipairs(State.LearnedIDs) do
                if v == id then
                    return old(self, ...)
                end
            end
            table.insert(State.LearnedIDs, id)
            print("[Jao9z] Learned Animal ID:", id)
        end
    end

    return old(self, ...)
end)

--[[ ANTI AFK ]]
player.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)
