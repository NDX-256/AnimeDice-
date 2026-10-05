--//==================================================
--// FrioZvanHub v1.9
--// Dice Shop + Buy Once + Equip Once
--// Tower Panel + Auto Tower
--// Trait Panel + Auto Trait Target
--// Auto Sell LOCKED
--//==================================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- FLUENT LOADER
--==================================================


local function LoadURL(URL)
local Success, Result = pcall(function()
return loadstring(game:HttpGet(URL))
end)

if not Success or type(Result) ~= "function" then  
    return nil  
end  

local OK, Module = pcall(Result)  

if not OK then  
    return nil  
end  

return Module

end

local Fluent = LoadURL(
"https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
)

if not Fluent then
warn("[FrioZvanHub] Fluent gagal dimuat.")
return
end

local SaveManager = LoadURL(
"https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
)

local InterfaceManager = LoadURL(
"https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
)

--==================================================
-- NETWORK
--==================================================

local Network = ReplicatedStorage:WaitForChild("Network", 10)

if not Network then
Fluent:Notify({
Title = "FrioZvanHub",
Content = "Network tidak ditemukan.",
Duration = 3
})
return
end

local PlotService = Network:WaitForChild("PlotService", 10)
local RollService = Network:WaitForChild("RollService", 10)
local SellService = Network:WaitForChild("SellService", 10)
local DiceShopService = Network:WaitForChild("DiceShopService", 10)
local TowersService = Network:WaitForChild("Towers", 10)

local TowerRE
local TowerRF

if TowersService then
TowerRE = TowersService:WaitForChild("RE", 10)
TowerRF = TowersService:WaitForChild("RF", 10)
end

if not PlotService
or not RollService
or not SellService
or not DiceShopService then

Fluent:Notify({  
    Title = "FrioZvanHub",  
    Content = "Service game tidak ditemukan.",  
    Duration = 3  
})  

return

end

local PlotRE = PlotService:WaitForChild("RE", 10)
local RollRE = RollService:WaitForChild("RE", 10)
local SellRF = SellService:WaitForChild("RF", 10)
local DiceShopRE = DiceShopService:WaitForChild("RE", 10)

local CollectBalance = PlotRE:WaitForChild("CollectBalance", 10)
local EquipBest = PlotRE:WaitForChild("EquipBest", 10)

local SetAutoRoll = RollRE:WaitForChild("SetAutoRoll", 10)

local SellInventory = SellRF:WaitForChild("SellInventory", 10)

local BuyDice = DiceShopRE:WaitForChild("BuyDice", 10)
local EquipDice = DiceShopRE:WaitForChild("EquipDice", 10)

--==================================================
-- TOWER REMOTES
--==================================================

local EquipBestTowerTeam
local SetAutoTower

local CancelTower
local PlayTower
local CompleteTowerFloor

if TowerRE then

EquipBestTowerTeam =  
    TowerRE:WaitForChild(  
        "EquipBestTowerTeam",  
        10  
    )  

SetAutoTower =  
    TowerRE:WaitForChild(  
        "SetAutoTower",  
        10  
    )

end

if TowerRF then

CancelTower =  
    TowerRF:WaitForChild(  
        "CancelTower",  
        10  
    )  

PlayTower =  
    TowerRF:WaitForChild(  
        "PlayTower",  
        10  
    )  

CompleteTowerFloor =  
    TowerRF:WaitForChild(  
        "CompleteTowerFloor",  
        10  
    )

end

--==================================================
-- DICE DATA
--==================================================

local DiceModule

pcall(function()

DiceModule =  
    require(  
        ReplicatedStorage  
            .Framework  
            .Features  
            .Rolling  
            .Dice  
    )

end)

local DiceData = {}

if DiceModule
and type(DiceModule.GetAll) == "function" then

local Success, Data =  
    pcall(function()  
        return DiceModule.GetAll()  
    end)  

if Success and type(Data) == "table" then  
    DiceData = Data  
end

end

local DiceNames = {}

for DiceName, Data in pairs(DiceData) do

if type(DiceName) == "string"  
    and type(Data) == "table" then  

    table.insert(  
        DiceNames,  
        DiceName  
    )  

end

end

table.sort(
DiceNames,
function(A, B)

local APrice =  
        tonumber(DiceData[A].price) or 0  

    local BPrice =  
        tonumber(DiceData[B].price) or 0  

    return APrice < BPrice  

end

)

local SelectedDice = DiceNames[1]

--==================================================
-- TOWER DATA
--==================================================

local TowerModule

pcall(function()

TowerModule =  
    require(  
        ReplicatedStorage  
            .Framework  
            .Features  
            .Towers  
            .Towers  
    )

end)

local TowerData = {}

if TowerModule
and type(TowerModule.GetAll) == "function" then

local Success, Data =  
    pcall(function()  
        return TowerModule.GetAll()  
    end)  

if Success and type(Data) == "table" then  
    TowerData = Data  
end

end

local TowerNames = {}

for TowerName, Data in pairs(TowerData) do

if type(TowerName) == "string"  
    and type(Data) == "table" then  

    table.insert(  
        TowerNames,  
        TowerName  
    )  

end

end

table.sort(
TowerNames,
function(A, B)

local AOrder =  
        tonumber(TowerData[A].order) or 999  

    local BOrder =  
        tonumber(TowerData[B].order) or 999  

    return AOrder < BOrder  

end

)

local SelectedTower = TowerNames[1]

--==================================================
-- STATES
--==================================================

local AutoRoll = false
local AutoEquipBest = false
local AutoCollectMoney = false
local AutoSell = false
local AutoTower = false

--==================================================
-- INSTANT ROLL
--==================================================

local HiddenRollButton

pcall(function()

local UIReferences =  
    require(  
        ReplicatedStorage  
            .Framework  
            .Features  
            .UI  
            .UIReferences  
    )  

local Root = UIReferences.Root  

if not Root then  
    return  
end  

local Rolling = Root.Rolling  

if not Rolling then  
    return  
end  

local Options = Rolling.Options  

if not Options then  
    return  
end  

HiddenRollButton =  
    Options:FindFirstChild("HiddenRoll")

end)

--==================================================
-- CUTSCENE SKIP
--==================================================

pcall(function()

local RollController =  
    require(  
        ReplicatedStorage  
            .Framework  
            .Features  
            .Rolling  
            .RollController  
    )  

if type(RollController) ~= "table" then  
    return  
end  

local PlayCutscene =  
    RollController.PlayCutscene  

if type(PlayCutscene) ~= "function" then  
    return  
end  

if debug  
    and debug.getupvalue  
    and debug.setupvalue then  

    for Index = 1, 100 do  

        local Name, Value =  
            debug.getupvalue(  
                PlayCutscene,  
                Index  
            )  

        if not Name then  
            break  
        end  

        if Name == "rollCutscene"  
            and type(Value) == "function" then  

            debug.setupvalue(  
                PlayCutscene,  
                Index,  
                function(_, _, Model)  

                    if Model then  
                        pcall(function()  
                            Model:Destroy()  
                        end)  
                    end  

                end  
            )  

            break  
        end  

    end  

end

end)

--==================================================
-- INVENTORY UUID SCANNER
-- AUTO SELL - JANGAN DIUBAH
--==================================================

local function GetInventoryUUIDList()

local UUIDList = {}  
local Found = {}  

local function AddUUID(Value)  

    if type(Value) ~= "string" then  
        return  
    end  

    if #Value < 30 then  
        return  
    end  

    if not string.find(  
        Value,  
        "-",  
        1,  
        true  
    ) then  
        return  
    end  

    if Found[Value] then  
        return  
    end  

    Found[Value] = true  

    UUIDList[#UUIDList + 1] =  
        Value  

end  

local function ScanTable(  
    Data,  
    Depth  
)  

    if type(Data) ~= "table" then  
        return  
    end  

    if Depth > 5 then  
        return  
    end  

    for Key, Value in pairs(Data) do  

        AddUUID(Key)  
        AddUUID(Value)  

        if type(Value) == "table" then  

            AddUUID(Value.UUID)  
            AddUUID(Value.uuid)  
            AddUUID(Value.Id)  
            AddUUID(Value.id)  

            ScanTable(  
                Value,  
                Depth + 1  
            )  

        end  

    end  

end  

pcall(function()  

    local GetLoadedModules =  
        getloadedmodules  
        or get_loaded_modules  

    if not GetLoadedModules then  
        return  
    end  

    for _, Module in pairs(  
        GetLoadedModules()  
    ) do  

        if typeof(Module) == "Instance" then  

            local Valid = false  

            pcall(function()  

                Valid =  
                    Module:IsDescendantOf(  
                        ReplicatedStorage  
                    )  
                    or Module:IsDescendantOf(  
                        LocalPlayer  
                    )  

            end)  

            if Valid then  

                local Name =  
                    string.lower(  
                        Module.Name  
                    )  

                if string.find(Name, "data")  
                    or string.find(Name, "inventory")  
                    or string.find(Name, "replica")  
                    or string.find(Name, "item") then  

                    pcall(function()  

                        local Data =  
                            require(Module)  

                        if type(Data) == "table" then  

                            ScanTable(  
                                Data,  
                                1  
                            )  

                        end  

                    end)  

                end  

            end  

        end  

    end  

end)  

pcall(function()  

    local PlayerGui =  
        LocalPlayer:FindFirstChild(  
            "PlayerGui"  
        )  

    if not PlayerGui then  
        return  
    end  

    for _, Object in pairs(  
        PlayerGui:GetDescendants()  
    ) do  

        for _, Value in pairs(  
            Object:GetAttributes()  
        ) do  

            AddUUID(Value)  

        end  

        if Object:IsA("StringValue") then  
            AddUUID(Object.Value)  
        end  

    end  

end)  

pcall(function()  

    local Containers = {  

        LocalPlayer:FindFirstChild(  
            "Backpack"  
        ),  

        LocalPlayer.Character  

    }  

    for _, Container in pairs(Containers) do  

        if Container then  

            for _, Item in pairs(  
                Container:GetChildren()  
            ) do  

                AddUUID(Item.Name)  

                for _, Value in pairs(  
                    Item:GetAttributes()  
                ) do  

                    AddUUID(Value)  

                end  

            end  

        end  

    end  

end)  

return UUIDList

end

--==================================================
-- WINDOW
--==================================================

local Window =
Fluent:CreateWindow({

Title =  
        "FrioZvanHub v1.0",  

    SubTitle =  
        "Free Script",  

    TabWidth = 160,  

    Size =  
        UDim2.fromOffset(  
            580,  
            460  
        ),  

    Acrylic = false,  

    Theme = "Dark",  

    MinimizeKey =  
        Enum.KeyCode.RightControl  

})

--==================================================
-- TABS
--==================================================

local MainTab =
Window:AddTab({
Title = "Main",
Icon = "home"
})

local TowerTab =
Window:AddTab({
Title = "Tower",
Icon = "layers"
})

local TraitTab =
Window:AddTab({
Title = "Trait & Grade",
Icon = "badge-check"
})

local ShopTab =
Window:AddTab({
Title = "Shop",
Icon = "shopping-cart"
})

local FuseTab =
Window:AddTab({
Title = "Fuse",
Icon = "git-merge"
})

local TradeTab =
Window:AddTab({
Title = "Trade",
Icon = "repeat"
})

local SettingsTab =
Window:AddTab({
Title = "Settings",
Icon = "settings"
})

--==================================================
-- MAIN
--==================================================

MainTab:AddToggle(
"AutoRoll",
{
Title = "Auto Roll",
Default = false
}
):OnChanged(function(Value)

AutoRoll = Value  

pcall(function()  

    if SetAutoRoll then  
        SetAutoRoll:FireServer(Value)  
    end  

end)  

if Value  
    and HiddenRollButton then  

    task.defer(function()  

        pcall(function()  
            HiddenRollButton:Activate()  
        end)  

    end)  

end

end)

--==================================================
-- AUTO EQUIP BEST
--==================================================

MainTab:AddToggle(
"AutoEquipBest",
{
Title = "Auto Equip Best",
Default = false
}
):OnChanged(function(Value)

AutoEquipBest = Value  

if not Value then  
    return  
end  

task.spawn(function()  

    while AutoEquipBest do  

        pcall(function()  

            if EquipBest then  
                EquipBest:FireServer()  
            end  

        end)  

        task.wait(1)  

    end  

end)

end)

--==================================================
-- EQUIP BEST
--==================================================

MainTab:AddButton({

Title = "Equip Best",  

Callback = function()  

    pcall(function()  

        if EquipBest then  
            EquipBest:FireServer()  
        end  

    end)  

end

})

--==================================================
-- AUTO COLLECT
--==================================================

MainTab:AddToggle(
"AutoCollectMoney",
{
Title = "Auto Collect Money",
Default = false
}
):OnChanged(function(Value)

AutoCollectMoney = Value  

if not Value then  
    return  
end  

task.spawn(function()  

    while AutoCollectMoney do  

        for PlotID = 1, 20 do  

            if not AutoCollectMoney then  
                break  
            end  

            pcall(function()  

                if CollectBalance then  

                    CollectBalance:FireServer(  
                        PlotID  
                    )  

                end  

            end)  

            task.wait(0.05)  

        end  

        task.wait(0.5)  

    end  

end)

end)

--==================================================
-- COLLECT ALL
--==================================================

MainTab:AddButton({

Title = "Collect All",  

Callback = function()  

    task.spawn(function()  

        for PlotID = 1, 20 do  

            pcall(function()  

                if CollectBalance then  

                    CollectBalance:FireServer(  
                        PlotID  
                    )  

                end  

            end)  

            task.wait(0.05)  

        end  

    end)  

end

})

--==================================================
-- TOWER TAB
-- HANYA OPEN PANEL
--==================================================

TowerTab:AddParagraph({

Title = "Tower Panel",  

Content =  
    "Semua fitur Tower tersedia di panel khusus."

})

--==================================================
-- TOWER PANEL VARIABLES
--==================================================

local TowerPanelGui
local TowerPanel
local TowerPanelStroke

local TowerStatusLabel
local TowerNameLabel
local TowerDifficultyLabel
local TowerBattleLabel
local TowerFloorLabel
local TowerResultLabel

local TowerStartButton
local TowerStopButton
local TowerEquipButton
local TowerSelector
local TowerListFrame

local TowerPanelDragging = false
local TowerPanelDragStart
local TowerPanelStartPosition

local TowerRunning = false
local TowerBattleNumber = 0
local TowerCurrentFloor = "-"
local TowerLastResult = "Ready"

--==================================================
-- TOWER PANEL GUI
--==================================================

TowerPanelGui =
Instance.new("ScreenGui")

TowerPanelGui.Name =
"FrioZvanTowerPanel"

TowerPanelGui.ResetOnSpawn = false
TowerPanelGui.IgnoreGuiInset = true

local TowerParented = false

pcall(function()

TowerPanelGui.Parent = CoreGui  
TowerParented = true

end)

if not TowerParented then

pcall(function()  

    TowerPanelGui.Parent =  
        LocalPlayer:WaitForChild(  
            "PlayerGui"  
        )  

end)

end

--==================================================
-- TOWER PANEL
--==================================================

TowerPanel =
Instance.new("Frame")

TowerPanel.Name =
"TOWER PANEL"

TowerPanel.Size =
UDim2.fromOffset(
330,
330
)

TowerPanel.Position =
UDim2.new(
0.5,
-165,
0.5,
-165
)

TowerPanel.BackgroundColor3 =
Color3.fromRGB(
18,
18,
23
)

TowerPanel.BackgroundTransparency =
0.04

TowerPanel.BorderSizePixel = 0
TowerPanel.Active = true
TowerPanel.Visible = false
TowerPanel.Parent = TowerPanelGui

local TowerCorner =
Instance.new("UICorner")

TowerCorner.CornerRadius =
UDim.new(
0,
12
)

TowerCorner.Parent =
TowerPanel

TowerPanelStroke =
Instance.new("UIStroke")

TowerPanelStroke.Thickness = 1.4
TowerPanelStroke.Transparency = 0.3
TowerPanelStroke.Parent = TowerPanel

--==================================================
-- TOWER TITLE
--==================================================

local TowerTitle =
Instance.new("TextLabel")

TowerTitle.Size =
UDim2.new(
1,
-55,
0,
38
)

TowerTitle.Position =
UDim2.fromOffset(
14,
3
)

TowerTitle.BackgroundTransparency = 1
TowerTitle.Text = "TOWER PANEL"

TowerTitle.TextColor3 =
Color3.fromRGB(
225,
225,
230
)

TowerTitle.TextSize = 16
TowerTitle.Font = Enum.Font.GothamBold
TowerTitle.TextXAlignment =
Enum.TextXAlignment.Left

TowerTitle.Parent = TowerPanel

--==================================================
-- TOWER CLOSE
--==================================================

local TowerClose =
Instance.new("TextButton")

TowerClose.Size =
UDim2.fromOffset(
32,
32
)

TowerClose.Position =
UDim2.new(
1,
-38,
0,
6
)

TowerClose.BackgroundColor3 =
Color3.fromRGB(
30,
30,
36
)

TowerClose.BackgroundTransparency = 0.15
TowerClose.Text = "×"

TowerClose.TextColor3 =
Color3.fromRGB(
190,
190,
195
)

TowerClose.TextSize = 20
TowerClose.Font = Enum.Font.GothamBold
TowerClose.AutoButtonColor = false
TowerClose.Parent = TowerPanel

local CloseCorner =
Instance.new("UICorner")

CloseCorner.CornerRadius =
UDim.new(
0,
8
)

CloseCorner.Parent =
TowerClose

--==================================================
-- TOWER SELECTOR
--==================================================

TowerSelector =
Instance.new("TextButton")

TowerSelector.Size =
UDim2.new(
1,
-28,
0,
32
)

TowerSelector.Position =
UDim2.fromOffset(
14,
43
)

TowerSelector.BackgroundColor3 =
Color3.fromRGB(
27,
27,
34
)

TowerSelector.BackgroundTransparency = 0.1

TowerSelector.Text =
"Tower: "
.. tostring(
SelectedTower or "None"
)

TowerSelector.TextColor3 =
Color3.fromRGB(
205,
205,
210
)

TowerSelector.TextSize = 12
TowerSelector.Font = Enum.Font.GothamMedium
TowerSelector.AutoButtonColor = false
TowerSelector.Parent = TowerPanel

local SelectorCorner =
Instance.new("UICorner")

SelectorCorner.CornerRadius =
UDim.new(
0,
7
)

SelectorCorner.Parent =
TowerSelector

--==================================================
-- TOWER LIST
--==================================================

TowerListFrame =
Instance.new("ScrollingFrame")

TowerListFrame.Size =
UDim2.new(
1,
-28,
0,
0
)

TowerListFrame.Position =
UDim2.fromOffset(
14,
78
)

TowerListFrame.BackgroundColor3 =
Color3.fromRGB(
23,
23,
29
)

TowerListFrame.BorderSizePixel = 0
TowerListFrame.Visible = false
TowerListFrame.ZIndex = 20
TowerListFrame.ScrollBarThickness = 3

TowerListFrame.CanvasSize =
UDim2.new(
0,
0,
0,
#TowerNames * 29
)

TowerListFrame.Parent = TowerPanel

local TowerListCorner =
Instance.new("UICorner")

TowerListCorner.CornerRadius =
UDim.new(
0,
8
)

TowerListCorner.Parent =
TowerListFrame

local TowerListLayout =
Instance.new("UIListLayout")

TowerListLayout.Padding =
UDim.new(
0,
2
)

TowerListLayout.Parent =
TowerListFrame

--==================================================
-- TOWER LABEL
--==================================================

local function CreateTowerLabel(
Text,
Y
)

local Label =  
    Instance.new("TextLabel")  

Label.Size =  
    UDim2.new(  
        1,  
        -28,  
        0,  
        21  
    )  

Label.Position =  
    UDim2.fromOffset(  
        14,  
        Y  
    )  

Label.BackgroundTransparency = 1  
Label.Text = Text  

Label.TextColor3 =  
    Color3.fromRGB(  
        190,  
        190,  
        198  
    )  

Label.TextSize = 11  
Label.Font = Enum.Font.GothamMedium  
Label.TextXAlignment =  
    Enum.TextXAlignment.Left  

Label.Parent = TowerPanel  

return Label

end

TowerNameLabel =
CreateTowerLabel(
"Tower      : "
.. tostring(
SelectedTower or "None"
),
82
)

TowerDifficultyLabel =
CreateTowerLabel(
"Difficulty : -",
103
)

TowerStatusLabel =
CreateTowerLabel(
"Status     : IDLE",
124
)

TowerBattleLabel =
CreateTowerLabel(
"Battle     : 0",
145
)

TowerFloorLabel =
CreateTowerLabel(
"Floor      : -",
166
)

TowerResultLabel =
CreateTowerLabel(
"Result     : Ready",
187
)

--==================================================
-- TOWER DISPLAY
--==================================================

local function UpdateTowerDisplay()

TowerNameLabel.Text =  
    "Tower      : "  
    .. tostring(  
        SelectedTower or "None"  
    )  

TowerBattleLabel.Text =  
    "Battle     : "  
    .. tostring(  
        TowerBattleNumber  
    )  

TowerFloorLabel.Text =  
    "Floor      : "  
    .. tostring(  
        TowerCurrentFloor  
    )  

local Data =  
    TowerData[SelectedTower]  

if Data then  

    local Difficulty = "Unknown"  

    if type(Data.difficulty) == "table" then  

        Difficulty =  
            tostring(  
                Data.difficulty.name  
            )  

    else  

        Difficulty =  
            tostring(  
                Data.difficulty or "Unknown"  
            )  

    end  

    TowerDifficultyLabel.Text =  
        "Difficulty : "  
        .. Difficulty  

else  

    TowerDifficultyLabel.Text =  
        "Difficulty : -"  

end

end

local function SetTowerStatus(Status)

TowerStatusLabel.Text =  
    "Status     : "  
    .. tostring(  
        Status  
    )

end

local function SetTowerResult(Result)

TowerLastResult =  
    tostring(  
        Result  
    )  

TowerResultLabel.Text =  
    "Result     : "  
    .. TowerLastResult

end

--==================================================
-- SELECT TOWER
--==================================================

TowerSelector.Activated:Connect(
function()

TowerListFrame.Visible =  
        not TowerListFrame.Visible  

    if TowerListFrame.Visible then  

        local Height =  
            math.min(  
                #TowerNames * 29,  
                145  
            )  

        TowerListFrame.Size =  
            UDim2.new(  
                1,  
                -28,  
                0,  
                Height  
            )  

    else  

        TowerListFrame.Size =  
            UDim2.new(  
                1,  
                -28,  
                0,  
                0  
            )  

    end  

end

)

for _, TowerName in ipairs(
TowerNames
) do

local Button =  
    Instance.new("TextButton")  

Button.Size =  
    UDim2.new(  
        1,  
        -6,  
        0,  
        27  
    )  

Button.BackgroundColor3 =  
    Color3.fromRGB(  
        30,  
        30,  
        37  
    )  

Button.Text =  
    tostring(  
        TowerName  
    )  

Button.TextColor3 =  
    Color3.fromRGB(  
        205,  
        205,  
        210  
    )  

Button.TextSize = 11  
Button.Font = Enum.Font.GothamMedium  
Button.AutoButtonColor = false  
Button.ZIndex = 21  
Button.Parent = TowerListFrame  

local ButtonCorner =  
    Instance.new("UICorner")  

ButtonCorner.CornerRadius =  
    UDim.new(  
        0,  
        5  
    )  

ButtonCorner.Parent = Button  

Button.Activated:Connect(  
    function()  

        if TowerRunning then  

            Fluent:Notify({  

                Title = "Tower",  

                Content =  
                    "Stop Tower terlebih dahulu.",  

                Duration = 2  

            })  

            return  
        end  

        SelectedTower =  
            TowerName  

        TowerSelector.Text =  
            "Tower: "  
            .. tostring(  
                TowerName  
            )  

        TowerListFrame.Visible = false  

        TowerListFrame.Size =  
            UDim2.new(  
                1,  
                -28,  
                0,  
                0  
            )  

        TowerCurrentFloor = "-"  
        TowerBattleNumber = 0  

        SetTowerStatus("IDLE")  
        SetTowerResult("Tower selected")  

        UpdateTowerDisplay()  

    end  
)

end

--==================================================
-- TOWER EQUIP BEST
--==================================================

TowerEquipButton =
Instance.new("TextButton")

TowerEquipButton.Size =
UDim2.fromOffset(
142,
32
)

TowerEquipButton.Position =
UDim2.fromOffset(
14,
218
)

TowerEquipButton.BackgroundColor3 =
Color3.fromRGB(
30,
30,
37
)

TowerEquipButton.Text = "EQUIP BEST"

TowerEquipButton.TextColor3 =
Color3.fromRGB(
215,
215,
220
)

TowerEquipButton.TextSize = 11
TowerEquipButton.Font = Enum.Font.GothamBold
TowerEquipButton.AutoButtonColor = false
TowerEquipButton.Parent = TowerPanel

local EquipCorner =
Instance.new("UICorner")

EquipCorner.CornerRadius =
UDim.new(
0,
8
)

EquipCorner.Parent =
TowerEquipButton

TowerEquipButton.Activated:Connect(
function()

if TowerRunning then  

        Fluent:Notify({  

            Title = "Tower",  

            Content =  
                "Stop Tower terlebih dahulu.",  

            Duration = 2  

        })  

        return  
    end  

    if not EquipBestTowerTeam then  
        return  
    end  

    pcall(function()  

        EquipBestTowerTeam:FireServer()  

    end)  

    SetTowerResult(  
        "Best team equipped"  
    )  

end

)

--==================================================
-- TOWER START
--==================================================

TowerStartButton =
Instance.new("TextButton")

TowerStartButton.Size =
UDim2.fromOffset(
142,
32
)

TowerStartButton.Position =
UDim2.fromOffset(
174,
218
)

TowerStartButton.BackgroundColor3 =
Color3.fromRGB(
30,
30,
37
)

TowerStartButton.Text = "START"

TowerStartButton.TextColor3 =
Color3.fromRGB(
215,
215,
220
)

TowerStartButton.TextSize = 12
TowerStartButton.Font = Enum.Font.GothamBold
TowerStartButton.AutoButtonColor = false
TowerStartButton.Parent = TowerPanel

local StartCorner =
Instance.new("UICorner")

StartCorner.CornerRadius =
UDim.new(
0,
8
)

StartCorner.Parent =
TowerStartButton

--==================================================
-- TOWER STOP
--==================================================

TowerStopButton =
Instance.new("TextButton")

TowerStopButton.Size =
UDim2.fromOffset(
302,
32
)

TowerStopButton.Position =
UDim2.fromOffset(
14,
258
)

TowerStopButton.BackgroundColor3 =
Color3.fromRGB(
30,
30,
37
)

TowerStopButton.Text = "STOP"

TowerStopButton.TextColor3 =
Color3.fromRGB(
215,
215,
220
)

TowerStopButton.TextSize = 12
TowerStopButton.Font = Enum.Font.GothamBold
TowerStopButton.AutoButtonColor = false
TowerStopButton.Parent = TowerPanel

local StopCorner =
Instance.new("UICorner")

StopCorner.CornerRadius =
UDim.new(
0,
8
)

StopCorner.Parent =
TowerStopButton

--==================================================
-- TOWER RGB
--==================================================

task.spawn(function()

local Hue = 0  

while  
    TowerPanelGui  
    and TowerPanelGui.Parent  
do  

    Hue =  
        (Hue + 0.0022) % 1  

    pcall(function()  

        TowerPanelStroke.Color =  
            Color3.fromHSV(  
                Hue,  
                0.38,  
                0.55  
            )  

    end)  

    task.wait(0.04)  

end

end)

--==================================================
-- TOWER DRAG PANEL
--==================================================

TowerTitle.InputBegan:Connect(
function(Input)

if Input.UserInputType ~=  
            Enum.UserInputType.MouseButton1  
        and Input.UserInputType ~=  
            Enum.UserInputType.Touch then  

        return  
    end  

    TowerPanelDragging = true  

    TowerPanelDragStart =  
        Input.Position  

    TowerPanelStartPosition =  
        TowerPanel.Position  

    Input.Changed:Connect(  
        function()  

            if Input.UserInputState ==  
                Enum.UserInputState.End then  

                TowerPanelDragging = false  

            end  

        end  
    )  

end

)

UserInputService.InputChanged:Connect(
function(Input)

if not TowerPanelDragging then  
        return  
    end  

    if Input.UserInputType ~=  
            Enum.UserInputType.MouseMovement  
        and Input.UserInputType ~=  
            Enum.UserInputType.Touch then  

        return  
    end  

    local Delta =  
        Input.Position -  
        TowerPanelDragStart  

    TowerPanel.Position =  
        UDim2.new(  

            TowerPanelStartPosition.X.Scale,  

            TowerPanelStartPosition.X.Offset  
                + Delta.X,  

            TowerPanelStartPosition.Y.Scale,  

            TowerPanelStartPosition.Y.Offset  
                + Delta.Y  
        )  

end

)

--==================================================
-- TOWER CLOSE
--==================================================

TowerClose.Activated:Connect(
function()

TowerPanel.Visible = false  

end

)

--==================================================
-- START TOWER
--==================================================

local function StartTower()

if TowerRunning then  
    return  
end  

local TowerName =  
    SelectedTower  

if not TowerName then  

    SetTowerStatus("NO TOWER")  
    SetTowerResult("Select tower first")  

    return  
end  

if not EquipBestTowerTeam  
    or not PlayTower  
    or not CompleteTowerFloor then  

    SetTowerStatus("ERROR")  
    SetTowerResult("Tower remote incomplete")  

    return  
end  

TowerRunning = true  
AutoTower = true  

TowerBattleNumber = 0  
TowerCurrentFloor = "-"  

SetTowerStatus("STARTING")  
SetTowerResult("Preparing...")  

UpdateTowerDisplay()  

task.spawn(function()  

    if not TowerRunning then  
        return  
    end  

    pcall(function()  
        EquipBestTowerTeam:FireServer()  
    end)  

    task.wait(0.3)  

    if not TowerRunning then  
        return  
    end  

    if SetAutoTower then  

        pcall(function()  

            SetAutoTower:FireServer(  
                TowerName  
            )  

        end)  

        task.wait(0.2)  

    end  

    while TowerRunning do  

        TowerBattleNumber += 1  
        TowerCurrentFloor = "-"  

        UpdateTowerDisplay()  

        SetTowerStatus(  
            "STARTING BATTLE"  
        )  

        SetTowerResult(  
            "Battle #"  
            .. tostring(  
                TowerBattleNumber  
            )  
        )  

        local PlayOK  
        local PlayResult  

        PlayOK, PlayResult =  
            pcall(function()  

                return PlayTower:InvokeServer(  
                    TowerName  
                )  

            end)  

        print(  
            "[FZH Tower] Play:",  
            PlayOK,  
            PlayResult  
        )  

        if not PlayOK  
            or PlayResult ~= true then  

            SetTowerStatus("RETRYING")  
            SetTowerResult("Play failed")  

            task.wait(3.2)  

            continue  

        end  

        SetTowerStatus("RUNNING")  
        SetTowerResult("Battle started")  

        local BattleEnded = false  

        while TowerRunning  
            and not BattleEnded do  

            local CompleteOK  
            local Result  

            CompleteOK, Result =  
                pcall(function()  

                    return CompleteTowerFloor:InvokeServer()  

                end)  

            if CompleteOK  
                and typeof(Result) == "table" then  

                for _, ActionData in ipairs(  
                    Result  
                ) do  

                    local Action =  
                        ActionData.action  

                    local Floor =  
                        ActionData.floor  

                    print(  
                        "[FZH Tower]",  
                        Action,  
                        "Floor:",  
                        Floor or "-"  
                    )  

                    if Floor then  

                        TowerCurrentFloor =  
                            Floor  

                        UpdateTowerDisplay()  

                    end  

                    if Action ==  
                        "floorStarted" then  

                        SetTowerStatus(  
                            "FLOOR "  
                            .. tostring(  
                                Floor or "?"  
                            )  
                        )  

                        SetTowerResult(  
                            "Floor started"  
                        )  

                    elseif Action ==  
                        "damageEnemy" then  

                        SetTowerStatus(  
                            "FIGHTING"  
                        )  

                        SetTowerResult(  
                            "Enemy hit"  
                        )  

                    elseif Action ==  
                        "floorCompleted" then  

                        SetTowerStatus(  
                            "FLOOR CLEAR"  
                        )  

                        SetTowerResult(  
                            "Floor "  
                            .. tostring(  
                                Floor or "?"  
                            )  
                            .. " completed"  
                        )  

                    elseif Action ==  
                        "memberDefeated" then  

                        SetTowerStatus(  
                            "MEMBER DEFEATED"  
                        )  

                        SetTowerResult(  
                            "Team member defeated"  
                        )  

                    elseif Action ==  
                        "damagePlayer" then  

                        SetTowerStatus(  
                            "DAMAGE"  
                        )  

                    elseif Action ==  
                        "ended" then  

                        BattleEnded = true  

                        SetTowerStatus(  
                            "ENDED"  
                        )  

                        SetTowerResult(  
                            "Battle #"  
                            .. tostring(  
                                TowerBattleNumber  
                            )  
                            .. " finished"  
                        )  

                        break  

                    end  

                end  

            end  

            task.wait(0.2)  

        end  

        if not TowerRunning then  
            break  
        end  

        if BattleEnded then  

            SetTowerStatus(  
                "NEXT BATTLE"  
            )  

            SetTowerResult(  
                "Waiting server..."  
            )  

            task.wait(3.2)  

        end  

    end  

    SetTowerStatus("STOPPED")  
    SetTowerResult("Tower stopped")  

end)

end

--==================================================
-- STOP TOWER
--==================================================

local function StopTower()

if not TowerRunning then  

    SetTowerStatus("IDLE")  
    SetTowerResult("Nothing running")  

    return  
end  

TowerRunning = false  
AutoTower = false  

SetTowerStatus("STOPPING")  
SetTowerResult("Cancelling...")  

pcall(function()  

    if SetAutoTower then  
        SetAutoTower:FireServer(false)  
    end  

end)  

pcall(function()  

    if CancelTower then  
        CancelTower:InvokeServer()  
    end  

end)  

task.spawn(function()  

    task.wait(0.15)  

    pcall(function()  

        if CompleteTowerFloor then  
            CompleteTowerFloor:InvokeServer()  
        end  

    end)  

    SetTowerStatus("STOPPED")  
    SetTowerResult("Tower stopped")  

end)

end

--==================================================
-- TOWER START / STOP
--==================================================

TowerStartButton.Activated:Connect(
function()
StartTower()
end
)

TowerStopButton.Activated:Connect(
function()
StopTower()
end
)

--==================================================
-- OPEN TOWER PANEL
--==================================================

TowerTab:AddButton({

Title =  
    "Open Tower Panel",  

Callback = function()  

    TowerPanel.Visible = true  

    UpdateTowerDisplay()  

end

})

--==================================================
-- TRAIT TAB
--==================================================

TraitTab:AddParagraph({

Title = "Trait Panel",  

Content =  
    "Roll Trait dan cari trait target di panel khusus."

})

--==================================================
-- TRAIT MODULES
--==================================================

local DataController
local EntryRegistry
local TraitsModule
local TraitClient
local RollTraitSignal

pcall(function()

DataController =  
    require(  
        ReplicatedStorage  
            .Framework  
            .Features  
            .Data  
            .DataController  
    )

end)

pcall(function()

EntryRegistry =  
    require(  
        ReplicatedStorage  
            .Framework  
            .Features  
            .Inventory  
            .EntryRegistry  
    )

end)

pcall(function()

TraitsModule =  
    require(  
        ReplicatedStorage  
            .Framework  
            .Features  
            .Traits  
            .Traits  
    )

end)

pcall(function()

local ClientComm =  
    require(  
        ReplicatedStorage.Packages.Network  
    ).ClientComm  

TraitClient =  
    ClientComm.new(  
        Network,  
        false,  
        "TraitService"  
    )  

RollTraitSignal =  
    TraitClient:GetSignal(  
        "Roll"  
    )

end)

--==================================================
-- TRAIT DATA
--==================================================

local TraitNames = {}

if type(TraitsModule) == "table" then

for TraitName, Data in pairs(TraitsModule) do  

    if type(TraitName) == "string"  
        and type(Data) == "table" then  

        table.insert(  
            TraitNames,  
            TraitName  
        )  

    end  

end

end

table.sort(
TraitNames,
function(A, B)

local AOrder =  
        tonumber(  
            TraitsModule[A].order  
        ) or 999  

    local BOrder =  
        tonumber(  
            TraitsModule[B].order  
        ) or 999  

    return AOrder < BOrder  

end

)

local SelectedTraitTarget =
TraitNames[1]

--==================================================
-- TRAIT PANEL VARIABLES
--==================================================

local TraitPanelGui
local TraitPanel
local TraitPanelStroke

local TraitTitle
local TraitClose

local TraitUnitSelector
local TraitUnitList

local TraitTargetSelector
local TraitTargetList

local TraitCurrentLabel
local TraitTargetLabel
local TraitStoneLabel
local TraitStatusLabel

local TraitRollButton
local TraitAutoButton
local TraitStopButton
local TraitRefreshButton

local TraitPanelDragging = false
local TraitPanelDragStart
local TraitPanelStartPosition

local TraitUnits = {}
local SelectedTraitUnit = nil

local TraitAutoRunning = false

--==================================================
-- TRAIT UNIT SCANNER
--==================================================

local function GetTraitUnits()

local Units = {}  

if not DataController then  
    return Units  
end  

local Inventory  

local Success =  
    pcall(function()  

        Inventory =  
            DataController.Inventory()  

    end)  

if not Success  
    or type(Inventory) ~= "table" then  

    return Units  
end  

for Key, Entry in pairs(Inventory) do  

    if type(Entry) == "table"  
        and EntryRegistry then  

        local IsUnit = false  

        pcall(function()  

            local Config =  
                EntryRegistry.getEntryConfig(  
                    Entry.name  
                )  

            if Config  
                and Config.kind == "Unit" then  

                IsUnit = true  

            end  

        end)  

        if IsUnit then  

            table.insert(  
                Units,  
                {  
                    Key = Key,  
                    Name = tostring(  
                        Entry.name  
                        or Key  
                    )  
                }  
            )  

        end  

    end  

end  

table.sort(  
    Units,  
    function(A, B)  

        return A.Name < B.Name  

    end  
)  

return Units

end

--==================================================
-- CURRENT TRAIT
--==================================================

local function GetCurrentTrait()

if not SelectedTraitUnit then  
    return nil  
end  

if not DataController then  
    return nil  
end  

local Entry  

local Success =  
    pcall(function()  

        Entry =  
            DataController.Inventory[  
                SelectedTraitUnit.Key  
            ]  

    end)  

if not Success  
    or not Entry then  

    return nil  
end  

local Trait  

local TraitSuccess =  
    pcall(function()  

        if Entry.attributes  
            and type(  
                Entry.attributes.trait  
            ) == "function" then  

            Trait =  
                Entry.attributes.trait()  

        end  

    end)  

if not TraitSuccess then  
    return nil  
end  

return Trait

end

--==================================================
-- TRAIT REROLL COUNT
--==================================================

local function GetTraitRerollAmount()

if not DataController then  
    return 0  
end  

local Inventory  

local Success =  
    pcall(function()  

        Inventory =  
            DataController.Inventory()  

    end)  

if not Success  
    or type(Inventory) ~= "table" then  

    return 0  
end  

for _, Entry in pairs(Inventory) do  

    if type(Entry) == "table"  
        and tostring(  
            Entry.name  
        ) == "Trait Reroll" then  

        local Amount  

        pcall(function()  

            if type(Entry.amount) == "function" then  
                Amount = Entry.amount()  
            else  
                Amount =  
                    Entry.amount  
                    or Entry.quantity  
                    or Entry.count  
            end  

        end)  

        return tonumber(Amount) or 0  

    end  

end  

return 0

end

--==================================================
-- TRAIT PANEL GUI
--==================================================

TraitPanelGui =
Instance.new("ScreenGui")

TraitPanelGui.Name =
"FrioZvanTraitPanel"

TraitPanelGui.ResetOnSpawn = false
TraitPanelGui.IgnoreGuiInset = true

local TraitParented = false

pcall(function()

TraitPanelGui.Parent = CoreGui  
TraitParented = true

end)

if not TraitParented then

pcall(function()  

    TraitPanelGui.Parent =  
        LocalPlayer:WaitForChild(  
            "PlayerGui"  
        )  

end)

end

--==================================================
-- TRAIT PANEL
--==================================================

TraitPanel =
Instance.new("Frame")

TraitPanel.Name =
"TRAIT PANEL"

TraitPanel.Size =
UDim2.fromOffset(
330,
365
)

TraitPanel.Position =
UDim2.new(
0.5,
-165,
0.5,
-182
)

TraitPanel.BackgroundColor3 =
Color3.fromRGB(
18,
18,
23
)

TraitPanel.BackgroundTransparency =
0.04

TraitPanel.BorderSizePixel = 0
TraitPanel.Active = true
TraitPanel.Visible = false
TraitPanel.Parent = TraitPanelGui

local TraitCorner =
Instance.new("UICorner")

TraitCorner.CornerRadius =
UDim.new(
0,
12
)

TraitCorner.Parent =
TraitPanel

TraitPanelStroke =
Instance.new("UIStroke")

TraitPanelStroke.Thickness = 1.4
TraitPanelStroke.Transparency = 0.3
TraitPanelStroke.Parent = TraitPanel

--==================================================
-- TRAIT TITLE
--==================================================

TraitTitle =
Instance.new("TextLabel")

TraitTitle.Size =
UDim2.new(
1,
-55,
0,
38
)

TraitTitle.Position =
UDim2.fromOffset(
14,
3
)

TraitTitle.BackgroundTransparency = 1
TraitTitle.Text = "TRAIT PANEL"

TraitTitle.TextColor3 =
Color3.fromRGB(
225,
225,
230
)

TraitTitle.TextSize = 16
TraitTitle.Font = Enum.Font.GothamBold
TraitTitle.TextXAlignment =
Enum.TextXAlignment.Left

TraitTitle.Parent = TraitPanel

--==================================================
-- TRAIT CLOSE
--==================================================

TraitClose =
Instance.new("TextButton")

TraitClose.Size =
UDim2.fromOffset(
32,
32
)

TraitClose.Position =
UDim2.new(
1,
-38,
0,
6
)

TraitClose.BackgroundColor3 =
Color3.fromRGB(
30,
30,
36
)

TraitClose.BackgroundTransparency = 0.15
TraitClose.Text = "×"

TraitClose.TextColor3 =
Color3.fromRGB(
190,
190,
195
)

TraitClose.TextSize = 20
TraitClose.Font = Enum.Font.GothamBold
TraitClose.AutoButtonColor = false
TraitClose.Parent = TraitPanel

local TraitCloseCorner =
Instance.new("UICorner")

TraitCloseCorner.CornerRadius =
UDim.new(
0,
8
)

TraitCloseCorner.Parent =
TraitClose

--==================================================
-- TRAIT UNIT SELECTOR
--==================================================

TraitUnitSelector =
Instance.new("TextButton")

TraitUnitSelector.Size =
UDim2.new(
1,
-28,
0,
32
)

TraitUnitSelector.Position =
UDim2.fromOffset(
14,
43
)

TraitUnitSelector.BackgroundColor3 =
Color3.fromRGB(
27,
27,
34
)

TraitUnitSelector.BackgroundTransparency = 0.1

TraitUnitSelector.Text =
"Unit: Loading..."

TraitUnitSelector.TextColor3 =
Color3.fromRGB(
205,
205,
210
)

TraitUnitSelector.TextSize = 11
TraitUnitSelector.Font = Enum.Font.GothamMedium
TraitUnitSelector.AutoButtonColor = false
TraitUnitSelector.TextXAlignment =
Enum.TextXAlignment.Left

TraitUnitSelector.Parent = TraitPanel

local TraitUnitSelectorPadding =
Instance.new("UIPadding")

TraitUnitSelectorPadding.PaddingLeft =
UDim.new(
0,
9
)

TraitUnitSelectorPadding.Parent =
TraitUnitSelector

local TraitUnitSelectorCorner =
Instance.new("UICorner")

TraitUnitSelectorCorner.CornerRadius =
UDim.new(
0,
7
)

TraitUnitSelectorCorner.Parent =
TraitUnitSelector

--==================================================
-- TRAIT UNIT LIST
--==================================================

TraitUnitList =
Instance.new("ScrollingFrame")

TraitUnitList.Size =
UDim2.new(
1,
-28,
0,
0
)

TraitUnitList.Position =
UDim2.fromOffset(
14,
78
)

TraitUnitList.BackgroundColor3 =
Color3.fromRGB(
23,
23,
29
)

TraitUnitList.BorderSizePixel = 0
TraitUnitList.Visible = false
TraitUnitList.ZIndex = 30
TraitUnitList.ScrollBarThickness = 3

TraitUnitList.CanvasSize =
UDim2.new(
0,
0,
0,
0
)

TraitUnitList.Parent = TraitPanel

local TraitUnitListCorner =
Instance.new("UICorner")

TraitUnitListCorner.CornerRadius =
UDim.new(
0,
8
)

TraitUnitListCorner.Parent =
TraitUnitList

local TraitUnitLayout =
Instance.new("UIListLayout")

TraitUnitLayout.Padding =
UDim.new(
0,
2
)

TraitUnitLayout.Parent =
TraitUnitList

--==================================================
-- TRAIT TARGET SELECTOR
--==================================================

TraitTargetSelector =
Instance.new("TextButton")

TraitTargetSelector.Size =
UDim2.new(
1,
-28,
0,
32
)

TraitTargetSelector.Position =
UDim2.fromOffset(
14,
81
)

TraitTargetSelector.BackgroundColor3 =
Color3.fromRGB(
27,
27,
34
)

TraitTargetSelector.BackgroundTransparency = 0.1

TraitTargetSelector.Text =
"Target: "
.. tostring(
SelectedTraitTarget or "None"
)

TraitTargetSelector.TextColor3 =
Color3.fromRGB(
205,
205,
210
)

TraitTargetSelector.TextSize = 11
TraitTargetSelector.Font = Enum.Font.GothamMedium
TraitTargetSelector.AutoButtonColor = false
TraitTargetSelector.TextXAlignment =
Enum.TextXAlignment.Left

TraitTargetSelector.Parent = TraitPanel

local TraitTargetSelectorPadding =
Instance.new("UIPadding")

TraitTargetSelectorPadding.PaddingLeft =
UDim.new(
0,
9
)

TraitTargetSelectorPadding.Parent =
TraitTargetSelector

local TraitTargetSelectorCorner =
Instance.new("UICorner")

TraitTargetSelectorCorner.CornerRadius =
UDim.new(
0,
7
)

TraitTargetSelectorCorner.Parent =
TraitTargetSelector

--==================================================
-- TRAIT TARGET LIST
--==================================================

TraitTargetList =
Instance.new("ScrollingFrame")

TraitTargetList.Size =
UDim2.new(
1,
-28,
0,
0
)

TraitTargetList.Position =
UDim2.fromOffset(
14,
116
)

TraitTargetList.BackgroundColor3 =
Color3.fromRGB(
23,
23,
29
)

TraitTargetList.BorderSizePixel = 0
TraitTargetList.Visible = false
TraitTargetList.ZIndex = 30
TraitTargetList.ScrollBarThickness = 3

TraitTargetList.CanvasSize =
UDim2.new(
0,
0,
0,
#TraitNames * 28
)

TraitTargetList.Parent = TraitPanel

local TraitTargetListCorner =
Instance.new("UICorner")

TraitTargetListCorner.CornerRadius =
UDim.new(
0,
8
)

TraitTargetListCorner.Parent =
TraitTargetList

local TraitTargetLayout =
Instance.new("UIListLayout")

TraitTargetLayout.Padding =
UDim.new(
0,
2
)

TraitTargetLayout.Parent =
TraitTargetList

--==================================================
-- TRAIT LABELS
--==================================================

local function CreateTraitLabel(
Text,
Y
)

local Label =  
    Instance.new("TextLabel")  

Label.Size =  
    UDim2.new(  
        1,  
        -28,  
        0,  
        21  
    )  

Label.Position =  
    UDim2.fromOffset(  
        14,  
        Y  
    )  

Label.BackgroundTransparency = 1  
Label.Text = Text  

Label.TextColor3 =  
    Color3.fromRGB(  
        190,  
        190,  
        198  
    )  

Label.TextSize = 11  
Label.Font = Enum.Font.GothamMedium  
Label.TextXAlignment =  
    Enum.TextXAlignment.Left  

Label.Parent = TraitPanel  

return Label

end

TraitCurrentLabel =
CreateTraitLabel(
"Current : -",
119
)

TraitTargetLabel =
CreateTraitLabel(
"Target  : "
.. tostring(
SelectedTraitTarget or "-"
),
140
)

TraitStoneLabel =
CreateTraitLabel(
"Reroll  : 0",
161
)

TraitStatusLabel =
CreateTraitLabel(
"Status  : READY",
182
)

--==================================================
-- TRAIT BUTTON HELPER
--==================================================

local function CreateTraitButton(
Text,
X,
Y,
Width
)

local Button =  
    Instance.new("TextButton")  

Button.Size =  
    UDim2.fromOffset(  
        Width,  
        32  
    )  

Button.Position =  
    UDim2.fromOffset(  
        X,  
        Y  
    )  

Button.BackgroundColor3 =  
    Color3.fromRGB(  
        30,  
        30,  
        37  
    )  

Button.Text = Text  

Button.TextColor3 =  
    Color3.fromRGB(  
        215,  
        215,  
        220  
    )  

Button.TextSize = 11  
Button.Font = Enum.Font.GothamBold  
Button.AutoButtonColor = false  
Button.Parent = TraitPanel  

local Corner =  
    Instance.new("UICorner")  

Corner.CornerRadius =  
    UDim.new(  
        0,  
        8  
    )  

Corner.Parent = Button  

return Button

end

TraitRollButton =
CreateTraitButton(
"ROLL ONCE",
14,
211,
96
)

TraitAutoButton =
CreateTraitButton(
"AUTO ROLL",
117,
211,
96
)

TraitStopButton =
CreateTraitButton(
"STOP",
220,
211,
96
)

TraitRefreshButton =
CreateTraitButton(
"REFRESH",
14,
251,
302
)

--==================================================
-- TRAIT UPDATE INFO
--==================================================

local function UpdateTraitPanel()

TraitUnits =  
    GetTraitUnits()  

local OldKey =  
    SelectedTraitUnit  
    and SelectedTraitUnit.Key  

SelectedTraitUnit = nil  

if OldKey then  

    for _, Unit in ipairs(  
        TraitUnits  
    ) do  

        if Unit.Key == OldKey then  

            SelectedTraitUnit = Unit  
            break  

        end  

    end  

end  

if not SelectedTraitUnit then  
    SelectedTraitUnit = TraitUnits[1]  
end  

if SelectedTraitUnit then  

    TraitUnitSelector.Text =  
        "Unit: "  
        .. tostring(  
            SelectedTraitUnit.Name  
        )  

else  

    TraitUnitSelector.Text =  
        "Unit: No Unit Found"  

end  

local CurrentTrait =  
    GetCurrentTrait()  

TraitCurrentLabel.Text =  
    "Current : "  
    .. tostring(  
        CurrentTrait or "-"  
    )  

TraitTargetLabel.Text =  
    "Target  : "  
    .. tostring(  
        SelectedTraitTarget or "-"  
    )  

TraitStoneLabel.Text =  
    "Reroll  : "  
    .. tostring(  
        GetTraitRerollAmount()  
    )

end

--==================================================
-- REBUILD UNIT LIST
--==================================================

local function RebuildTraitUnitList()

for _, Child in ipairs(  
    TraitUnitList:GetChildren()  
) do  

    if Child:IsA("TextButton") then  
        Child:Destroy()  
    end  

end  

TraitUnits =  
    GetTraitUnits()  

local OldKey =  
    SelectedTraitUnit  
    and SelectedTraitUnit.Key  

SelectedTraitUnit = nil  

if OldKey then  

    for _, Unit in ipairs(  
        TraitUnits  
    ) do  

        if Unit.Key == OldKey then  

            SelectedTraitUnit = Unit  
            break  

        end  

    end  

end  

if not SelectedTraitUnit then  
    SelectedTraitUnit = TraitUnits[1]  
end  

for _, Unit in ipairs(  
    TraitUnits  
) do  

    local Button =  
        Instance.new("TextButton")  

    Button.Size =  
        UDim2.new(  
            1,  
            -6,  
            0,  
            27  
        )  

    Button.BackgroundColor3 =  
        Color3.fromRGB(  
            30,  
            30,  
            37  
        )  

    Button.Text =  
        tostring(  
            Unit.Name  
        )  

    Button.TextColor3 =  
        Color3.fromRGB(  
            205,  
            205,  
            210  
        )  

    Button.TextSize = 11  
    Button.Font = Enum.Font.GothamMedium  
    Button.AutoButtonColor = false  
    Button.ZIndex = 31  
    Button.Parent = TraitUnitList  

    local Corner =  
        Instance.new("UICorner")  

    Corner.CornerRadius =  
        UDim.new(  
            0,  
            5  
        )  

    Corner.Parent = Button  

    Button.Activated:Connect(  
        function()  

            if TraitAutoRunning then  
                return  
            end  

            SelectedTraitUnit = Unit  

            TraitUnitSelector.Text =  
                "Unit: "  
                .. tostring(  
                    Unit.Name  
                )  

            TraitUnitList.Visible = false  

            TraitUnitList.Size =  
                UDim2.new(  
                    1,  
                    -28,  
                    0,  
                    0  
                )  

            UpdateTraitPanel()  

        end  
    )  

end  

TraitUnitList.CanvasSize =  
    UDim2.new(  
        0,  
        0,  
        0,  
        #TraitUnits * 29  
    )  

if SelectedTraitUnit then  

    TraitUnitSelector.Text =  
        "Unit: "  
        .. tostring(  
            SelectedTraitUnit.Name  
        )  

else  

    TraitUnitSelector.Text =  
        "Unit: No Unit Found"  

end

end

--==================================================
-- REBUILD TARGET LIST
--==================================================

local function RebuildTraitTargetList()

for _, Child in ipairs(  
    TraitTargetList:GetChildren()  
) do  

    if Child:IsA("TextButton") then  
        Child:Destroy()  
    end  

end  

for _, TraitName in ipairs(  
    TraitNames  
) do  

    local Button =  
        Instance.new("TextButton")  

    Button.Size =  
        UDim2.new(  
            1,  
            -6,  
            0,  
            26  
        )  

    Button.BackgroundColor3 =  
        Color3.fromRGB(  
            30,  
            30,  
            37  
        )  

    Button.Text =  
        tostring(  
            TraitName  
        )  

    Button.TextColor3 =  
        Color3.fromRGB(  
            205,  
            205,  
            210  
        )  

    Button.TextSize = 11  
    Button.Font = Enum.Font.GothamMedium  
    Button.AutoButtonColor = false  
    Button.ZIndex = 31  
    Button.Parent = TraitTargetList  

    local Corner =  
        Instance.new("UICorner")  

    Corner.CornerRadius =  
        UDim.new(  
            0,  
            5  
        )  

    Corner.Parent = Button  

    Button.Activated:Connect(  
        function()  

            if TraitAutoRunning then  
                return  
            end  

            SelectedTraitTarget =  
                TraitName  

            TraitTargetSelector.Text =  
                "Target: "  
                .. tostring(  
                    TraitName  
                )  

            TraitTargetList.Visible = false  

            TraitTargetList.Size =  
                UDim2.new(  
                    1,  
                    -28,  
                    0,  
                    0  
                )  

            UpdateTraitPanel()  

        end  
    )  

end

end

--==================================================
-- UNIT DROPDOWN
--==================================================

TraitUnitSelector.Activated:Connect(
function()

if TraitAutoRunning then  
        return  
    end  

    TraitTargetList.Visible = false  

    TraitTargetList.Size =  
        UDim2.new(  
            1,  
            -28,  
            0,  
            0  
        )  

    TraitUnitList.Visible =  
        not TraitUnitList.Visible  

    if TraitUnitList.Visible then  

        local Height =  
            math.min(  
                #TraitUnits * 29,  
                130  
            )  

        TraitUnitList.Size =  
            UDim2.new(  
                1,  
                -28,  
                0,  
                Height  
            )  

    else  

        TraitUnitList.Size =  
            UDim2.new(  
                1,  
                -28,  
                0,  
                0  
            )  

    end  

end

)

--==================================================
-- TARGET DROPDOWN
--==================================================

TraitTargetSelector.Activated:Connect(
function()

if TraitAutoRunning then  
        return  
    end  

    TraitUnitList.Visible = false  

    TraitUnitList.Size =  
        UDim2.new(  
            1,  
            -28,  
            0,  
            0  
        )  

    TraitTargetList.Visible =  
        not TraitTargetList.Visible  

    if TraitTargetList.Visible then  

        local Height =  
            math.min(  
                #TraitNames * 28,  
                130  
            )  

        TraitTargetList.Size =  
            UDim2.new(  
                1,  
                -28,  
                0,  
                Height  
            )  

    else  

        TraitTargetList.Size =  
            UDim2.new(  
                1,  
                -28,  
                0,  
                0  
            )  

    end  

end

)

--==================================================
-- TRAIT ROLL ONCE
--==================================================

TraitRollButton.Activated:Connect(
function()

if TraitAutoRunning then  
        return  
    end  

    if not SelectedTraitUnit then  

        TraitStatusLabel.Text =  
            "Status  : NO UNIT"  

        return  
    end  

    if not RollTraitSignal then  

        TraitStatusLabel.Text =  
            "Status  : SIGNAL ERROR"  

        return  
    end  

    local Stones =  
        GetTraitRerollAmount()  

    if Stones <= 0 then  

        TraitStatusLabel.Text =  
            "Status  : NO REROLL"  

        return  
    end  

    local Current =  
        GetCurrentTrait()  

    if Current  
        and Current ==  
            SelectedTraitTarget then  

        TraitStatusLabel.Text =  
            "Status  : TARGET FOUND"  

        return  
    end  

    local Success =  
        pcall(function()  

            RollTraitSignal:Fire(  
                SelectedTraitUnit.Key  
            )  

        end)  

    if Success then  

        TraitStatusLabel.Text =  
            "Status  : ROLLING"  

    else  

        TraitStatusLabel.Text =  
            "Status  : ROLL FAILED"  

    end  

    task.delay(  
        0.35,  
        function()  

            if not TraitPanelGui  
                or not TraitPanelGui.Parent then  
                return  
            end  

            UpdateTraitPanel()  

        end  
    )  

end

)

--==================================================
-- TRAIT AUTO ROLL
--==================================================

local function StopTraitAuto(
Message
)

TraitAutoRunning = false  

TraitStatusLabel.Text =  
    "Status  : "  
    .. tostring(  
        Message or "STOPPED"  
    )

end

local function StartTraitAuto()

if TraitAutoRunning then  
    return  
end  

if not SelectedTraitUnit then  

    TraitStatusLabel.Text =  
        "Status  : NO UNIT"  

    return  
end  

if not SelectedTraitTarget then  

    TraitStatusLabel.Text =  
        "Status  : NO TARGET"  

    return  
end  

if not RollTraitSignal then  

    TraitStatusLabel.Text =  
        "Status  : SIGNAL ERROR"  

    return  
end  

TraitAutoRunning = true  

TraitStatusLabel.Text =  
    "Status  : AUTO ROLL"  

task.spawn(function()  

    while TraitAutoRunning do  

        if not SelectedTraitUnit then  

            StopTraitAuto(  
                "NO UNIT"  
            )  

            break  
        end  

        local Current =  
            GetCurrentTrait()  

        if Current  
            and Current ==  
                SelectedTraitTarget then  

            StopTraitAuto(  
                "TARGET FOUND"  
            )  

            break  
        end  

        local Stones =  
            GetTraitRerollAmount()  

        TraitStoneLabel.Text =  
            "Reroll  : "  
            .. tostring(  
                Stones  
            )  

        if Stones <= 0 then  

            StopTraitAuto(  
                "NO REROLL"  
            )  

            break  
        end  

        TraitStatusLabel.Text =  
            "Status  : ROLLING"  

        local Success =  
            pcall(function()  

                RollTraitSignal:Fire(  
                    SelectedTraitUnit.Key  
                )  

            end)  

        if not Success then  

            StopTraitAuto(  
                "ROLL FAILED"  
            )  

            break  
        end  

        task.wait(0.35)  

        if not TraitAutoRunning then  
            break  
        end  

        local NewTrait =  
            GetCurrentTrait()  

        TraitCurrentLabel.Text =  
            "Current : "  
            .. tostring(  
                NewTrait or "-"  
            )  

        TraitTargetLabel.Text =  
            "Target  : "  
            .. tostring(  
                SelectedTraitTarget  
            )  

        TraitStoneLabel.Text =  
            "Reroll  : "  
            .. tostring(  
                GetTraitRerollAmount()  
            )  

        if NewTrait  
            and NewTrait ==  
                SelectedTraitTarget then  

            StopTraitAuto(  
                "TARGET FOUND"  
            )  

            break  
        end  

        task.wait(0.05)  

    end  

end)

end

--==================================================
-- AUTO BUTTON
--==================================================

TraitAutoButton.Activated:Connect(
function()

if TraitAutoRunning then  
        return  
    end  

    StartTraitAuto()  

end

)

--==================================================
-- STOP BUTTON
--==================================================

TraitStopButton.Activated:Connect(
function()

if TraitAutoRunning then  

        StopTraitAuto(  
            "STOPPED"  
        )  

    else  

        TraitStatusLabel.Text =  
            "Status  : READY"  

    end  

end

)

--==================================================
-- REFRESH BUTTON
--==================================================

TraitRefreshButton.Activated:Connect(
function()

if TraitAutoRunning then  
        return  
    end  

    RebuildTraitUnitList()  
    RebuildTraitTargetList()  
    UpdateTraitPanel()  

    TraitStatusLabel.Text =  
        "Status  : REFRESHED"  

end

)

--==================================================
-- TRAIT CLOSE
--==================================================

TraitClose.Activated:Connect(
function()

TraitAutoRunning = false  
    TraitPanel.Visible = false  

end

)

--==================================================
-- TRAIT RGB
--==================================================

task.spawn(function()

local Hue = 0  

while  
    TraitPanelGui  
    and TraitPanelGui.Parent  
do  

    Hue =  
        (Hue + 0.0022) % 1  

    pcall(function()  

        TraitPanelStroke.Color =  
            Color3.fromHSV(  
                Hue,  
                0.38,  
                0.55  
            )  

    end)  

    task.wait(0.04)  

end

end)

--==================================================
-- TRAIT DRAG
--==================================================

TraitTitle.InputBegan:Connect(
function(Input)

if Input.UserInputType ~=  
            Enum.UserInputType.MouseButton1  
        and Input.UserInputType ~=  
            Enum.UserInputType.Touch then  

        return  
    end  

    TraitPanelDragging = true  

    TraitPanelDragStart =  
        Input.Position  

    TraitPanelStartPosition =  
        TraitPanel.Position  

    Input.Changed:Connect(  
        function()  

            if Input.UserInputState ==  
                Enum.UserInputState.End then  

                TraitPanelDragging = false  

            end  

        end  
    )  

end

)

UserInputService.InputChanged:Connect(
function(Input)

if not TraitPanelDragging then  
        return  
    end  

    if Input.UserInputType ~=  
            Enum.UserInputType.MouseMovement  
        and Input.UserInputType ~=  
            Enum.UserInputType.Touch then  

        return  
    end  

    local Delta =  
        Input.Position -  
        TraitPanelDragStart  

    TraitPanel.Position =  
        UDim2.new(  

            TraitPanelStartPosition.X.Scale,  

            TraitPanelStartPosition.X.Offset  
                + Delta.X,  

            TraitPanelStartPosition.Y.Scale,  

            TraitPanelStartPosition.Y.Offset  
                + Delta.Y  
        )  

end

)

--==================================================
-- OPEN TRAIT PANEL
--==================================================

TraitTab:AddButton({

Title =  
    "Open Trait Panel",  

Callback = function()  

    RebuildTraitUnitList()  
    RebuildTraitTargetList()  
    UpdateTraitPanel()  

    TraitPanel.Visible = true  

end

})

--==================================================
-- TRAIT INFO REFRESH
--==================================================

task.spawn(function()

while  
    TraitPanelGui  
    and TraitPanelGui.Parent  
do  

    if TraitPanel.Visible then  

        pcall(function()  

            local Current =  
                GetCurrentTrait()  

            TraitCurrentLabel.Text =  
                "Current : "  
                .. tostring(  
                    Current or "-"  
                )  

            TraitTargetLabel.Text =  
                "Target  : "  
                .. tostring(  
                    SelectedTraitTarget or "-"  
                )  

            TraitStoneLabel.Text =  
                "Reroll  : "  
                .. tostring(  
                    GetTraitRerollAmount()  
                )  

        end)  

    end  

    task.wait(0.5)  

end

end)


--==================================================
-- GRADE / FUSE / TRADE INTEGRATION
--==================================================

local FZHExtras = {
    Grade = {},
    Fuse = {},
    Trade = {}
}

--==================================================
-- GRADE DATA
--==================================================

pcall(function()
    FZHExtras.Grade.Module = require(
        ReplicatedStorage.Framework.Features.Grades.Grades
    )
    FZHExtras.Grade.ClientComm = require(
        ReplicatedStorage.Packages.Network
    ).ClientComm
    FZHExtras.Grade.Signal = FZHExtras.Grade.ClientComm.new(
        ReplicatedStorage.Network,
        false,
        "GradeService"
    ):GetSignal("Roll")
end)

FZHExtras.Grade.Names = {}

if type(FZHExtras.Grade.Module) == "table" then
    for Name, Data in pairs(FZHExtras.Grade.Module) do
        if type(Name) == "string" and type(Data) == "table" then
            table.insert(FZHExtras.Grade.Names, Name)
        end
    end
end

table.sort(FZHExtras.Grade.Names, function(A, B)
    return (tonumber(FZHExtras.Grade.Module[A].order) or 999)
        < (tonumber(FZHExtras.Grade.Module[B].order) or 999)
end)

FZHExtras.Grade.SelectedTarget = FZHExtras.Grade.Names[1]

local function FZHGetGradeUnits()
    local Out = {}
    local Inv
    pcall(function()
        Inv = DataController.Inventory()
    end)
    if type(Inv) ~= "table" then
        return Out
    end

    for Key, Entry in pairs(Inv) do
        if type(Entry) == "table" and EntryRegistry then
            local IsUnit = false
            pcall(function()
                local Config = EntryRegistry.getEntryConfig(Entry.name)
                IsUnit = Config and Config.kind == "Unit"
            end)
            if IsUnit then
                table.insert(Out, {
                    Key = Key,
                    Name = tostring(Entry.name or Key)
                })
            end
        end
    end

    table.sort(Out, function(A, B)
        return A.Name < B.Name
    end)
    return Out
end

local function FZHGetGradeCurrent()
    local S = FZHExtras.Grade.SelectedUnit
    if not S then return "-" end
    local Entry
    local OK = pcall(function()
        Entry = DataController.Inventory[S.Key]()
    end)
    if not OK or type(Entry) ~= "table" then return "-" end
    local Value = "-"
    pcall(function()
        if Entry.attributes and type(Entry.attributes.grade) == "function" then
            Value = Entry.attributes.grade()
        elseif Entry.attributes then
            Value = Entry.attributes.grade or "-"
        end
    end)
    return tostring(Value or "-")
end

local function FZHGetGems()
    local Inv
    pcall(function() Inv = DataController.Inventory() end)
    if type(Inv) ~= "table" then return 0 end
    for _, Entry in pairs(Inv) do
        if type(Entry) == "table" and tostring(Entry.name) == "Gems" then
            local N
            pcall(function()
                if type(Entry.amount) == "function" then
                    N = Entry.amount()
                else
                    N = Entry.amount or Entry.quantity or Entry.count or Entry.Amount
                end
            end)
            return tonumber(N) or 0
        end
    end
    return 0
end

local function FZHCreateNativePanel(Name, Title, Width, Height)
    local G = Instance.new("ScreenGui")
    G.Name = Name
    G.ResetOnSpawn = false
    G.IgnoreGuiInset = true
    pcall(function() G.Parent = CoreGui end)
    if not G.Parent then
        pcall(function() G.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
    end

    local P = Instance.new("Frame")
    P.Size = UDim2.fromOffset(Width, Height)
    P.Position = UDim2.new(0.5, -Width/2, 0.5, -Height/2)
    P.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
    P.BorderSizePixel = 0
    P.Active = true
    P.Visible = false
    P.Parent = G

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 12)
    C.Parent = P

    local S = Instance.new("UIStroke")
    S.Thickness = 1.4
    S.Transparency = 0.28
    S.Parent = P

    local T = Instance.new("TextLabel")
    T.Size = UDim2.new(1, -55, 0, 38)
    T.Position = UDim2.fromOffset(14, 3)
    T.BackgroundTransparency = 1
    T.Text = Title
    T.TextColor3 = Color3.fromRGB(235, 235, 240)
    T.TextSize = 16
    T.Font = Enum.Font.GothamBold
    T.TextXAlignment = Enum.TextXAlignment.Left
    T.Parent = P

    local X = Instance.new("TextButton")
    X.Size = UDim2.fromOffset(32, 32)
    X.Position = UDim2.new(1, -38, 0, 6)
    X.BackgroundTransparency = 1
    X.Text = "×"
    X.TextColor3 = Color3.fromRGB(190, 190, 200)
    X.TextSize = 22
    X.Font = Enum.Font.GothamBold
    X.Parent = P
    X.Activated:Connect(function() P.Visible = false end)

    local Dragging, DragStart, StartPos = false, nil, nil
    T.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1
            or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            StartPos = P.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(Input)
        if not Dragging then return end
        if Input.UserInputType ~= Enum.UserInputType.MouseMovement
            and Input.UserInputType ~= Enum.UserInputType.Touch then return end
        local D = Input.Position - DragStart
        P.Position = UDim2.new(
            StartPos.X.Scale, StartPos.X.Offset + D.X,
            StartPos.Y.Scale, StartPos.Y.Offset + D.Y
        )
    end)

    task.spawn(function()
        local H = 0
        while G.Parent do
            H = (H + 0.0022) % 1
            S.Color = Color3.fromHSV(H, 0.38, 0.55)
            task.wait(0.04)
        end
    end)

    return G, P
end

--==================================================
-- GRADE PANEL
--==================================================

do
    local E = FZHExtras.Grade
    E.Gui, E.Panel = FZHCreateNativePanel(
        "FrioZvanGradePanel",
        "GRADE PANEL",
        340,
        365
    )

    local function Label(Y, TextValue)
        local L = Instance.new("TextLabel")
        L.Size = UDim2.new(1, -28, 0, 25)
        L.Position = UDim2.fromOffset(14, Y)
        L.BackgroundTransparency = 1
        L.Text = TextValue
        L.TextColor3 = Color3.fromRGB(205, 205, 215)
        L.TextSize = 13
        L.Font = Enum.Font.Gotham
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.Parent = E.Panel
        return L
    end

    E.UnitLabel = Label(48, "Unit      : -")
    E.TargetLabel = Label(74, "Target    : -")
    E.GemLabel = Label(100, "Gems      : 0")
    E.StatusLabel = Label(126, "Status    : READY")

    local function Button(Y, X, W, TextValue)
        local B = Instance.new("TextButton")
        B.Size = UDim2.fromOffset(W, 34)
        B.Position = UDim2.fromOffset(X, Y)
        B.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        B.Text = TextValue
        B.TextColor3 = Color3.fromRGB(230, 230, 235)
        B.TextSize = 12
        B.Font = Enum.Font.GothamMedium
        B.AutoButtonColor = true
        B.Parent = E.Panel
        local C = Instance.new("UICorner")
        C.CornerRadius = UDim.new(0, 7)
        C.Parent = B
        return B
    end

    E.UnitButton = Button(160, 14, 312, "SELECT UNIT")
    E.TargetButton = Button(202, 14, 312, "SELECT TARGET")
    E.Roll = Button(246, 14, 100, "ROLL ONCE")
    E.Auto = Button(246, 120, 100, "AUTO ROLL")
    E.Stop = Button(246, 226, 100, "STOP")
    E.Refresh = Button(288, 14, 312, "REFRESH")

    E.UnitDrop = Instance.new("Frame")
    E.UnitDrop.Size = UDim2.fromOffset(312, 150)
    E.UnitDrop.Position = UDim2.fromOffset(14, 198)
    E.UnitDrop.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    E.UnitDrop.Visible = false
    E.UnitDrop.ZIndex = 20
    E.UnitDrop.Parent = E.Panel

    E.TargetDrop = E.UnitDrop:Clone()
    E.TargetDrop.Position = UDim2.fromOffset(14, 198)
    E.TargetDrop.Parent = E.Panel
    E.TargetDrop.Visible = false

    local function ClearDrop(D)
        for _, C in ipairs(D:GetChildren()) do
            C:Destroy()
        end
    end

    local function AddDropButton(D, Y, TextValue, Callback)
        local B = Instance.new("TextButton")
        B.Size = UDim2.new(1, -6, 0, 28)
        B.Position = UDim2.fromOffset(3, Y)
        B.BackgroundTransparency = 1
        B.Text = TextValue
        B.TextColor3 = Color3.fromRGB(220, 220, 225)
        B.TextSize = 12
        B.Font = Enum.Font.Gotham
        B.TextXAlignment = Enum.TextXAlignment.Left
        B.Parent = D
        B.Activated:Connect(Callback)
    end

    local function UpdateGrade()
        E.UnitLabel.Text = "Unit      : " .. (E.SelectedUnit and E.SelectedUnit.Name or "-")
        E.TargetLabel.Text = "Target    : " .. tostring(E.SelectedTarget or "-")
        E.GemLabel.Text = "Gems      : " .. tostring(FZHGetGems())
        E.UnitButton.Text = E.SelectedUnit and E.SelectedUnit.Name or "SELECT UNIT"
        E.TargetButton.Text = E.SelectedTarget or "SELECT TARGET"
        E.StatusLabel.Text = "Status    : " .. tostring(E.Status or "READY")
    end

    local function RefreshGrade()
        E.Units = FZHGetGradeUnits()
        if not E.SelectedUnit or not table.find(E.Units, E.SelectedUnit) then
            E.SelectedUnit = E.Units[1]
        end
        if not E.SelectedTarget then E.SelectedTarget = E.Names[1] end
        UpdateGrade()
    end

    local function ShowUnits()
        E.TargetDrop.Visible = false
        ClearDrop(E.UnitDrop)
        local Y = 3
        for _, U in ipairs(E.Units or {}) do
            if Y > 145 then break end
            AddDropButton(E.UnitDrop, Y, U.Name, function()
                E.SelectedUnit = U
                E.UnitDrop.Visible = false
                UpdateGrade()
            end)
            Y = Y + 28
        end
        E.UnitDrop.Visible = not E.UnitDrop.Visible
    end

    local function ShowTargets()
        E.UnitDrop.Visible = false
        ClearDrop(E.TargetDrop)
        local Y = 3
        for _, N in ipairs(E.Names) do
            if Y > 145 then break end
            AddDropButton(E.TargetDrop, Y, N, function()
                E.SelectedTarget = N
                E.TargetDrop.Visible = false
                UpdateGrade()
            end)
            Y = Y + 28
        end
        E.TargetDrop.Visible = not E.TargetDrop.Visible
    end

    local function RollGrade()
        if not E.SelectedUnit or not E.Signal then
            E.Status = "SIGNAL ERROR"
            UpdateGrade()
            return
        end
        if FZHGetGems() <= 0 then
            E.Status = "NO GEMS"
            UpdateGrade()
            return
        end
        pcall(function() E.Signal:Fire(E.SelectedUnit.Key) end)
        E.Status = "ROLLING"
        UpdateGrade()
        task.wait(0.35)
        UpdateGrade()
    end

    E.AutoRunning = false
    local function StopGrade(Msg)
        E.AutoRunning = false
        E.Status = Msg or "STOPPED"
        UpdateGrade()
    end

    local function StartGrade()
        if E.AutoRunning then return end
        if not E.SelectedUnit or not E.SelectedTarget then
            E.Status = "NO SELECTION"
            UpdateGrade()
            return
        end
        E.AutoRunning = true
        task.spawn(function()
            while E.AutoRunning do
                if FZHGetGradeCurrent() == tostring(E.SelectedTarget) then
                    StopGrade("TARGET FOUND")
                    break
                end
                if FZHGetGems() <= 0 then
                    StopGrade("NO GEMS")
                    break
                end
                RollGrade()
                if not E.AutoRunning then break end
                if FZHGetGradeCurrent() == tostring(E.SelectedTarget) then
                    StopGrade("TARGET FOUND")
                    break
                end
                task.wait(0.05)
            end
        end)
    end

    E.UnitButton.Activated:Connect(ShowUnits)
    E.TargetButton.Activated:Connect(ShowTargets)
    E.Roll.Activated:Connect(RollGrade)
    E.Auto.Activated:Connect(StartGrade)
    E.Stop.Activated:Connect(function() StopGrade("STOPPED") end)
    E.Refresh.Activated:Connect(function()
        if not E.AutoRunning then
            RefreshGrade()
            E.Status = "REFRESHED"
            UpdateGrade()
        end
    end)

    RefreshGrade()
end

--==================================================
-- FUSE PANEL
--==================================================

do
    local E = FZHExtras.Fuse
    pcall(function()
        E.FusingUtil = require(
            ReplicatedStorage.Framework.Features.Fusing.FusingUtil
        )
        E.Inventory = DataController.Inventory
        E.Remote = ReplicatedStorage.Network.FusingService.RE.Fuse
    end)

    E.Pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

    -- Universal large-number formatter for Anime/Fuse values.
    -- Uses 3-digit groups and supports values far beyond T.
    local LARGE_SUFFIXES = {
        "", "K", "M", "B", "T",
        "qd", "qn", "sx", "sp", "oc", "no", "dc",
        "ud", "dd", "td", "qad", "qid", "sxd", "spd",
        "ocd", "nod", "vg", "uvg", "dvg", "tvg", "qavg",
        "qivg", "sxvg", "spvg", "ocvg", "novg", "tr",
        "utr", "dtr", "ttr", "qatr", "qitr", "sxtr", "sptr",
        "octr", "notr", "qr", "uqr", "dqr", "tqr", "qaqr",
        "qiqr", "sxqr", "spqr", "ocqr", "noqr"
    }

    local function FormatLargeNumber(Value)
        if type(Value) == "string" then
            return Value
        end

        local N = tonumber(Value)
        if not N then return "?" end
        if N == 0 then return "0" end

        local Abs = math.abs(N)
        local Sign = N < 0 and "-" or ""
        local Group = math.floor(math.log10(Abs) / 3)

        if Group <= 0 then
            return tostring(N)
        end

        local Scaled = Abs / (10 ^ (Group * 3))
        local Suffix = LARGE_SUFFIXES[Group + 1]

        if not Suffix then
            -- Keep the value readable even if the game adds a suffix
            -- beyond the known table.
            return string.format("%.3e", N)
        end

        local Text
        if Scaled >= 100 then
            Text = string.format("%.0f", Scaled)
        elseif Scaled >= 10 then
            Text = string.format("%.1f", Scaled)
        else
            Text = string.format("%.2f", Scaled)
        end

        Text = Text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
        return Sign .. Text .. Suffix
    end

    local function Short(N)
        local Text = FormatLargeNumber(N)
        if Text == "?" then return Text end
        return "1/" .. Text
    end

    local function RefreshFuse()
        E.Units = {}
        local Inv
        pcall(function() Inv = E.Inventory() end)
        if type(Inv) ~= "table" then return end
        for UUID, Entry in pairs(Inv) do
            if type(UUID) == "string" and string.match(UUID, E.Pattern) then
                local OK, Chance = pcall(function()
                    return E.FusingUtil.GetChance(E.Inventory[UUID]())
                end)
                if OK and Chance ~= nil then
                    table.insert(E.Units, {
                        UUID = UUID,
                        Name = tostring(Entry.name or "Unknown"),
                        Chance = Chance
                    })
                end
            end
        end
        table.sort(E.Units, function(A, B) return A.Name < B.Name end)
    end

    E.Gui, E.Panel = FZHCreateNativePanel(
        "FrioZvanFusePanel",
        "FUSE PANEL",
        300,
        285
    )

    local function FButton(Y, TextValue)
        local B = Instance.new("TextButton")
        B.Size = UDim2.fromOffset(272, 34)
        B.Position = UDim2.fromOffset(14, Y)
        B.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        B.Text = TextValue
        B.TextColor3 = Color3.fromRGB(230, 230, 235)
        B.TextSize = 12
        B.Font = Enum.Font.GothamMedium
        B.Parent = E.Panel
        local C = Instance.new("UICorner")
        C.CornerRadius = UDim.new(0, 7)
        C.Parent = B
        return B
    end

    E.Slots = {}
    E.Selected = {}
    for I = 1, 3 do
        local B = FButton(48 + (I - 1) * 42, "SELECT UNIT " .. I)
        E.Slots[I] = B
    end
    E.FuseButton = FButton(174, "FUSE")
    E.RefreshButton = FButton(216, "REFRESH")

    E.Drop = Instance.new("Frame")
    E.Drop.Size = UDim2.fromOffset(272, 145)
    E.Drop.Position = UDim2.fromOffset(14, 84)
    E.Drop.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    E.Drop.Visible = false
    E.Drop.ZIndex = 30
    E.Drop.Parent = E.Panel

    local function RebuildDrop(Slot)
        for _, C in ipairs(E.Drop:GetChildren()) do C:Destroy() end
        local Y = 3
        for _, U in ipairs(E.Units or {}) do
            if Y > 140 then break end
            local Used = false
            for I = 1, 3 do
                if I ~= Slot and E.Selected[I] and E.Selected[I].UUID == U.UUID then
                    Used = true
                end
            end
            if not Used then
                local B = Instance.new("TextButton")
                B.Size = UDim2.new(1, -6, 0, 28)
                B.Position = UDim2.fromOffset(3, Y)
                B.BackgroundTransparency = 1
                B.Text = U.Name .. "  [" .. Short(U.Chance) .. "]"
                B.TextColor3 = Color3.fromRGB(220, 220, 225)
                B.TextSize = 11
                B.Font = Enum.Font.Gotham
                B.TextXAlignment = Enum.TextXAlignment.Left
                B.ZIndex = 31
                B.Parent = E.Drop
                B.Activated:Connect(function()
                    E.Selected[Slot] = U
                    E.Drop.Visible = false
                    E.Slots[Slot].Text = U.Name .. "  [" .. Short(U.Chance) .. "]"
                end)
                Y = Y + 28
            end
        end
        E.Drop.Visible = not E.Drop.Visible
    end

    for I = 1, 3 do
        E.Slots[I].Activated:Connect(function()
            RebuildDrop(I)
        end)
    end

    E.FuseButton.Activated:Connect(function()
        if not E.Remote then return end
        if not E.Selected[1] or not E.Selected[2] or not E.Selected[3] then return end
        if E.Selected[1].UUID == E.Selected[2].UUID
            or E.Selected[1].UUID == E.Selected[3].UUID
            or E.Selected[2].UUID == E.Selected[3].UUID then return end
        pcall(function()
            E.Remote:FireServer(
                E.Selected[1].UUID,
                E.Selected[2].UUID,
                E.Selected[3].UUID
            )
        end)
        task.wait(0.2)
        RefreshFuse()
    end)

    E.RefreshButton.Activated:Connect(function()
        RefreshFuse()
        E.Selected = {}
        for I = 1, 3 do
            E.Slots[I].Text = "SELECT UNIT " .. I
        end
    end)

    RefreshFuse()
end

--==================================================
-- TRADE SYSTEM
--==================================================

do
    local E = FZHExtras.Trade
    pcall(function()
        E.ClientComm = require(ReplicatedStorage.Packages.Network).ClientComm
        E.Client = E.ClientComm.new(
            ReplicatedStorage.Network,
            false,
            "TradeService"
        )
        E.Request = E.Client:GetSignal("RequestTrade")
        E.TradeEvent = E.Client:GetSignal("TradeEvent")
        E.Advance = E.Client:GetSignal("AdvanceTrade")
        E.ChangeOffer = E.Client:GetSignal("ChangeOffer")
    end)

    E.PlayerName = nil
    E.GemsAmount = 0
    E.TraitAmount = 0
    E.AnimeItem = nil
    E.AnimeItems = {}
    E.AnimeMap = {}
    E.Target = nil
    E.Active = false
    E.Offered = false

    local function PlayersList()
        local Out = {}
        for _, Plr in ipairs(Players:GetPlayers()) do
            if Plr ~= LocalPlayer then
                table.insert(Out, Plr.Name)
            end
        end
        table.sort(Out)
        return Out
    end

    E.PlayerNames = PlayersList()

    E.PlayerDrop = TradeTab:AddDropdown("TradePlayer", {
        Title = "Select Player",
        Values = E.PlayerNames,
        Multi = false,
        Default = E.PlayerNames[1]
    })

    TradeTab:AddInput("TradeGemsAmount", {
        Title = "Gems Amount",
        Default = "0",
        Placeholder = "Amount",
        Numeric = true,
        Finished = false
    }):OnChanged(function(V)
        E.GemsAmount = math.max(0, math.floor(tonumber(V) or 0))
    end)

    TradeTab:AddInput("TradeTraitAmount", {
        Title = "Trait Reroll Amount",
        Default = "0",
        Placeholder = "Amount",
        Numeric = true,
        Finished = false
    }):OnChanged(function(V)
        E.TraitAmount = math.max(0, math.floor(tonumber(V) or 0))
    end)

    local AnimeDrop

    local function ShortTradeValue(Number)
        local Text = FormatLargeNumber(Number)
        if Text == "?" then return Text end
        return "1/" .. Text
    end

    local function RefreshAnimeItems()
        E.AnimeItems = {}
        E.AnimeMap = {}

        pcall(function()
            local DataController = require(ReplicatedStorage.Framework.Features.Data.DataController)
            local EntryRegistry = require(ReplicatedStorage.Framework.Features.Inventory.EntryRegistry)
            local FusingUtil = require(ReplicatedStorage.Framework.Features.Fusing.FusingUtil)
            local Inventory = DataController.Inventory
            local Data = Inventory()

            if type(Data) ~= "table" then return end

            for UUID, Entry in pairs(Data) do
                if type(UUID) == "string" and type(Entry) == "table" then
                    local Config = nil
                    pcall(function()
                        Config = EntryRegistry.getEntryConfig(Entry.name)
                    end)

                    if Config and Config.kind == "Unit" then
                        local Chance = nil
                        pcall(function()
                            Chance = FusingUtil.GetChance(Inventory[UUID]())
                        end)

                        local Name = tostring(Entry.name or "Unknown")
                        local Display = Name .. "  [" .. ShortTradeValue(Chance) .. "]"
                        local BaseDisplay = Display
                        local Suffix = 2
                        while E.AnimeMap[Display] do
                            Display = BaseDisplay .. " (" .. tostring(Suffix) .. ")"
                            Suffix = Suffix + 1
                        end

                        table.insert(E.AnimeItems, Display)
                        E.AnimeMap[Display] = {
                            UUID = UUID,
                            Name = Name,
                            Chance = Chance
                        }
                    end
                end
            end
        end)

        table.sort(E.AnimeItems)

        if AnimeDrop then
            pcall(function() AnimeDrop:SetValues(E.AnimeItems) end)
            if E.AnimeItem and E.AnimeMap[E.AnimeItem] then
                pcall(function() AnimeDrop:SetValue(E.AnimeItem) end)
            else
                E.AnimeItem = E.AnimeItems[1]
                pcall(function() AnimeDrop:SetValue(E.AnimeItem or "") end)
            end
        end
    end

    AnimeDrop = TradeTab:AddDropdown("TradeAnimeItem", {
        Title = "Anime Item",
        Values = {},
        Multi = false
    })

    AnimeDrop:OnChanged(function(V)
        E.AnimeItem = V
    end)

    TradeTab:AddButton({
        Title = "Refresh Anime Items",
        Callback = RefreshAnimeItems
    })

    local function RefreshTradePlayers()
        E.PlayerNames = PlayersList()
        pcall(function() E.PlayerDrop:SetValues(E.PlayerNames) end)
        if not E.PlayerName or not table.find(E.PlayerNames, E.PlayerName) then
            E.PlayerName = E.PlayerNames[1]
        end
        pcall(function() E.PlayerDrop:SetValue(E.PlayerName or "") end)
    end

    E.PlayerDrop:OnChanged(function(V)
        E.PlayerName = V
    end)

    TradeTab:AddButton({
        Title = "Refresh Players",
        Callback = RefreshTradePlayers
    })

    TradeTab:AddButton({
        Title = "Send Trade",
        Callback = function()
            if not E.Request or not E.PlayerName then return end
            local Target = Players:FindFirstChild(E.PlayerName)
            if not Target or Target == LocalPlayer then return end
            E.Target = Target
            E.Active = true
            E.Offered = false
            pcall(function() E.Request:Fire(Target) end)
        end
    })

    TradeTab:AddParagraph({
        Title = "Trade Status",
        Content = "Select a player, set Gems / Trait Reroll, choose an Anime Item, then send trade."
    })

    local function OfferSelected()
        if not E.ChangeOffer or E.Offered then return end
        E.Offered = true
        if E.GemsAmount > 0 then
            pcall(function() E.ChangeOffer:Fire("Gems", E.GemsAmount) end)
        end
        if E.TraitAmount > 0 then
            pcall(function() E.ChangeOffer:Fire("Trait Reroll", E.TraitAmount) end)
        end
        if E.AnimeItem and E.AnimeMap[E.AnimeItem] then
            local Item = E.AnimeMap[E.AnimeItem]
            pcall(function() E.ChangeOffer:Fire(Item.UUID, 1) end)
        end
    end

    if E.TradeEvent then
        E.TradeEvent:Connect(function(A, Status, Data)
            if not E.Active then return end
            if Status == "Started" then
                OfferSelected()
                return
            end

            if Status == "Updated" and type(Data) == "table" then
                if Data.phase == "Offer"
                    and Data.otherReady == true
                    and Data.ownReady ~= true then
                    task.wait(0.05)
                    pcall(function() E.Advance:Fire() end)
                    return
                end

                if Data.phase == "Confirm"
                    and Data.otherAccepted == true
                    and Data.ownAccepted ~= true then
                    task.wait(0.05)
                    pcall(function() E.Advance:Fire() end)
                    return
                end
            end

            if Status == "Ended"
                or Status == "RequestClosed"
                or Status == "RequestExpired" then
                E.Active = false
                E.Offered = false
            end
        end)
    end

    Players.PlayerAdded:Connect(RefreshTradePlayers)
    Players.PlayerRemoving:Connect(RefreshTradePlayers)

    RefreshAnimeItems()
end

--==================================================
-- OPEN BUTTONS
--==================================================

TraitTab:AddButton({
    Title = "Open Grade Panel",
    Callback = function()
        FZHExtras.Grade.Panel.Visible = true
        pcall(function()
            FZHExtras.Grade.Units = FZHGetGradeUnits()
            FZHExtras.Grade.SelectedUnit = FZHExtras.Grade.Units[1] or FZHExtras.Grade.SelectedUnit
        end)
    end
})

FuseTab:AddButton({
    Title = "Open Fuse Panel",
    Callback = function()
        FZHExtras.Fuse.Panel.Visible = true
        pcall(function()
            FZHExtras.Fuse.Units = {}
            local Inv = FZHExtras.Fuse.Inventory()
            for UUID, Entry in pairs(Inv) do
                if type(UUID) == "string" and string.match(UUID, FZHExtras.Fuse.Pattern) then
                    local OK, Chance = pcall(function()
                        return FZHExtras.Fuse.FusingUtil.GetChance(
                            FZHExtras.Fuse.Inventory[UUID]()
                        )
                    end)
                    if OK and Chance ~= nil then
                        table.insert(FZHExtras.Fuse.Units, {
                            UUID = UUID,
                            Name = tostring(Entry.name or "Unknown"),
                            Chance = Chance
                        })
                    end
                end
            end
        end)
    end
})

--==================================================
-- SHOP HEADER
--==================================================

ShopTab:AddParagraph({

Title = "Dice Shop",  

Content =  
    "Select a Dice to buy and equip."

})

--==================================================
-- DICE SELECTOR
--==================================================

local DiceDropdown

if #DiceNames > 0 then

DiceDropdown =  
    ShopTab:AddDropdown(  
        "SelectedDice",  
        {  
            Title = "Select Dice",  
            Values = DiceNames,  
            Multi = false,  
            Default = SelectedDice  
        }  
    )  

DiceDropdown:OnChanged(  
    function(Value)  

        SelectedDice = Value  

        local Data =  
            DiceData[Value]  

        if Data then  

            Fluent:Notify({  

                Title =  
                    "Dice Selected",  

                Content =  
                    tostring(Value)  
                    .. " | "  
                    .. tostring(Data.rarity)  
                    .. " | Luck "  
                    .. tostring(Data.luck)  
                    .. " | $"  
                    .. tostring(  
                        Data.price or 0  
                    ),  

                Duration = 2  

            })  

        end  

    end  
)

else

ShopTab:AddParagraph({  

    Title = "Dice",  

    Content =  
        "Dice data tidak ditemukan."  

})

end

--==================================================
-- DICE INFO
--==================================================

ShopTab:AddButton({

Title = "Show Dice Info",  

Callback = function()  

    local Data =  
        DiceData[SelectedDice]  

    if not Data then  
        return  
    end  

    Fluent:Notify({  

        Title =  
            tostring(  
                SelectedDice  
            ),  

        Content =  
            "Rarity: "  
            .. tostring(Data.rarity)  
            .. "\nLuck: "  
            .. tostring(Data.luck)  
            .. "\nPrice: "  
            .. tostring(  
                Data.price or 0  
            ),  

        Duration = 4  

    })  

end

})

--==================================================
-- BUY + EQUIP ONCE
--==================================================

local BuyEquipOnce = false
local BuyEquipToggle

BuyEquipToggle =
ShopTab:AddToggle(
"BuyEquipOnce",
{
Title =
"Buy + Equip Selected",

Default = false  
    }  
)

BuyEquipToggle:OnChanged(
function(Value)

BuyEquipOnce = Value  

    if not Value then  
        return  
    end  

    local DiceName =  
        SelectedDice  

    if not DiceName then  

        Fluent:Notify({  

            Title =  
                "Dice Shop",  

            Content =  
                "Pilih Dice terlebih dahulu.",  

            Duration = 2  

        })  

        BuyEquipToggle:SetValue(false)  

        return  
    end  

    task.spawn(function()  

        local BuySuccess =  
            pcall(function()  

                BuyDice:FireServer(  
                    DiceName  
                )  

            end)  

        if not BuySuccess then  

            Fluent:Notify({  

                Title =  
                    "Dice Shop",  

                Content =  
                    "Buy Dice gagal.",  

                Duration = 2  

            })  

            BuyEquipOnce = false  
            BuyEquipToggle:SetValue(false)  

            return  
        end  

        task.wait(0.15)  

        local EquipSuccess =  
            pcall(function()  

                EquipDice:FireServer(  
                    DiceName  
                )  

            end)  

        if EquipSuccess then  

            Fluent:Notify({  

                Title =  
                    "Dice Shop",  

                Content =  
                    "Bought + Equipped: "  
                    .. DiceName,  

                Duration = 2  

            })  

        else  

            Fluent:Notify({  

                Title =  
                    "Dice Shop",  

                Content =  
                    "Buy berhasil, Equip gagal.",  

                Duration = 2  

            })  

        end  

        BuyEquipOnce = false  

        BuyEquipToggle:SetValue(false)  

    end)  

end

)

--==================================================
-- AUTO SELL
-- JANGAN DIUBAH
--==================================================

ShopTab:AddToggle(
"AutoSell",
{
Title =
"Auto Sell Inventory",

Default = false  
}

):OnChanged(function(Value)

AutoSell =  
    Value  

if not Value then  
    return  
end  

task.spawn(function()  

    while AutoSell do  

        local Success, UUIDs =  
            pcall(  
                GetInventoryUUIDList  
            )  

        if Success  
            and type(UUIDs) == "table"  
            and #UUIDs > 0 then  

            pcall(function()  

                SellInventory:InvokeServer(  
                    UUIDs  
                )  

            end)  

        end  

        task.wait(1)  

    end  

end)

end)

--==================================================
-- MANUAL SELL
--==================================================

ShopTab:AddButton({

Title =  
    "Sell Inventory",  

Callback = function()  

    task.spawn(function()  

        local Success, UUIDs =  
            pcall(  
                GetInventoryUUIDList  
            )  

        if not Success  
            or type(UUIDs) ~= "table"  
            or #UUIDs == 0 then  

            Fluent:Notify({  

                Title =  
                    "Shop",  

                Content =  
                    "No inventory detected.",  

                Duration = 2  

            })  

            return  
        end  

        local Result =  
            pcall(function()  

                SellInventory:InvokeServer(  
                    UUIDs  
                )  

            end)  

        Fluent:Notify({  

            Title =  
                "Shop",  

            Content =  
                Result  
                and "Inventory sold."  
                or "Sell request failed.",  

            Duration = 2  

        })  

    end)  

end

})

--==================================================
-- MOBILE FZH BUTTON
--==================================================

local ScreenGui =
Instance.new("ScreenGui")

ScreenGui.Name =
"FrioZvanHubMobile"

ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local GuiParented = false

pcall(function()

ScreenGui.Parent = CoreGui  
GuiParented = true

end)

if not GuiParented then

pcall(function()  

    ScreenGui.Parent =  
        LocalPlayer:WaitForChild(  
            "PlayerGui"  
        )  

end)

end

pcall(function()

local Old =  
    ScreenGui:FindFirstChild(  
        "FZH"  
    )  

if Old then  
    Old:Destroy()  
end

end)

local FloatingButton =
Instance.new("TextButton")

FloatingButton.Name = "FZH"

FloatingButton.Size =
UDim2.fromOffset(
54,
54
)

FloatingButton.Position =
UDim2.new(
0,
20,
0.5,
-27
)

FloatingButton.BackgroundColor3 =
Color3.fromRGB(
25,
25,
30
)

FloatingButton.BackgroundTransparency = 0.1
FloatingButton.Text = "FZH"

FloatingButton.TextColor3 =
Color3.fromRGB(
205,
205,
210
)

FloatingButton.TextSize = 13
FloatingButton.Font = Enum.Font.GothamBold
FloatingButton.AutoButtonColor = false
FloatingButton.Active = true
FloatingButton.Parent = ScreenGui

local Corner =
Instance.new("UICorner")

Corner.CornerRadius =
UDim.new(
0,
10
)

Corner.Parent =
FloatingButton

local Stroke =
Instance.new("UIStroke")

Stroke.Thickness = 1.5
Stroke.Transparency = 0.35
Stroke.Parent = FloatingButton

--==================================================
-- SOFT RGB
--==================================================

task.spawn(function()

local Hue = 0  

while  
    FloatingButton  
    and FloatingButton.Parent  
do  

    Hue =  
        (Hue + 0.0025) % 1  

    pcall(function()  

        Stroke.Color =  
            Color3.fromHSV(  
                Hue,  
                0.45,  
                0.60  
            )  

    end)  

    task.wait(0.04)  

end

end)

--==================================================
-- DRAG FZH
--==================================================

local Dragging = false
local DragStart
local StartPosition
local Moved = false

FloatingButton.InputBegan:Connect(
function(Input)

if Input.UserInputType ~=  
            Enum.UserInputType.Touch  
        and Input.UserInputType ~=  
            Enum.UserInputType.MouseButton1 then  

        return  
    end  

    Dragging = true  
    Moved = false  
    DragStart = Input.Position  
    StartPosition = FloatingButton.Position  

    Input.Changed:Connect(  
        function()  

            if Input.UserInputState ==  
                Enum.UserInputState.End then  

                Dragging = false  

            end  

        end  
    )  

end

)

UserInputService.InputChanged:Connect(
function(Input)

if not Dragging then  
        return  
    end  

    if Input.UserInputType ~=  
            Enum.UserInputType.Touch  
        and Input.UserInputType ~=  
            Enum.UserInputType.MouseMovement then  

        return  
    end  

    local Delta =  
        Input.Position -  
        DragStart  

    if math.abs(Delta.X) > 5  
        or math.abs(Delta.Y) > 5 then  

        Moved = true  

    end  

    FloatingButton.Position =  
        UDim2.new(  

            StartPosition.X.Scale,  

            StartPosition.X.Offset  
                + Delta.X,  

            StartPosition.Y.Scale,  

            StartPosition.Y.Offset  
                + Delta.Y  
        )  

end

)

--==================================================
-- OPEN FZH
--==================================================

FloatingButton.Activated:Connect(
function()

if Moved then  
        return  
    end  

    pcall(function()  

        Window:Minimize()  

    end)  

end

)

--==================================================
-- SETTINGS
--==================================================

pcall(function()

if SaveManager then  

    SaveManager:SetLibrary(  
        Fluent  
    )  

    SaveManager:IgnoreThemeSettings()  

    SaveManager:SetIgnoreIndexes({})  

    SaveManager:SetFolder(  
        "FrioZvanHub"  
    )  

end

end)

pcall(function()

if InterfaceManager then  

    InterfaceManager:SetLibrary(  
        Fluent  
    )  

    InterfaceManager:SetFolder(  
        "FrioZvanHub"  
    )  

    InterfaceManager:BuildInterfaceSection(  
        SettingsTab  
    )  

end

end)

pcall(function()

if SaveManager then  

    SaveManager:BuildConfigSection(  
        SettingsTab  
    )  

end

end)

--==================================================
-- LOADED
--==================================================

Fluent:Notify({

Title =  
    "FrioZvanHub",  

Content =  
    "v1.9 Loaded",  

Duration = 3

})