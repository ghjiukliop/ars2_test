local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local enemiesFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local remote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local teleportEnabled = false
local killedNPCs = {}
local dungeonkill = {}
local selectedMobName = ""
local movementMethod = "Tween" -- Phương thức di chuyển mặc định
local farmingStyle = "Default" -- Phong cách farm mặc định

-- Hệ thống lưu trữ mới
local ConfigSystem = {}
local HttpService = game:GetService("HttpService")
ConfigSystem.Folder = "HTHub"
ConfigSystem.SubFolder = "AriseCrossover"
ConfigSystem.FileName = player.Name .. "_Config.json"
ConfigSystem.FilePath = ConfigSystem.Folder .. "/" .. ConfigSystem.SubFolder .. "/" .. ConfigSystem.FileName
ConfigSystem.DefaultConfig = {
    SelectedMobName = "",
    FarmSelectedMob = false,
    AutoFarmNearestNPCs = false,
    MainAutoDestroy = false,
    MainAutoArise = false,
    FarmingMethod = "Tween",
    DamageMobs = false,
    SelectedShop = "",
    SelectedWeapon = "",
    AutoBuyEnabled = false,
    AutoScanEnabled = false,
    ScanDelay = 1,
    SelectedRanks = {},
    AutoSellEnabled = false
}
ConfigSystem.CurrentConfig = {}

-- Hàm tạo thư mục nếu không tồn tại
ConfigSystem.CreateFolders = function()
    -- Thử các phương thức khác nhau để tạo thư mục trên nhiều executor
    local success = pcall(function()
        if makefolder then
            if not isfolder(ConfigSystem.Folder) then
                makefolder(ConfigSystem.Folder)
            end
            
            if not isfolder(ConfigSystem.Folder .. "/" .. ConfigSystem.SubFolder) then
                makefolder(ConfigSystem.Folder .. "/" .. ConfigSystem.SubFolder)
            end
        end
    end)
    
    return success
end

-- Hàm để lưu cấu hình (thử nhiều phương thức)
ConfigSystem.SaveConfig = function()
    -- Đảm bảo thư mục tồn tại
    ConfigSystem.CreateFolders()
    
    -- Mã hóa cấu hình thành chuỗi JSON
    local jsonData = HttpService:JSONEncode(ConfigSystem.CurrentConfig)
    
    -- Thử các phương thức lưu khác nhau
    local success, err = pcall(function()
        -- Phương thức 1: writefile trực tiếp (Synapse X, KRNL, Script-Ware)
        if writefile then
            writefile(ConfigSystem.FilePath, jsonData)
            return true
        end
        
        -- Phương thức 2: Sử dụng SaveInstance (một số executor khác)
        if saveinstance then
            saveinstance(ConfigSystem.FilePath, jsonData)
            return true
        end
        
        -- Phương thức 3: Fluxus và một số executor khác
        if fluxus and fluxus.save_file then
            fluxus.save_file(ConfigSystem.FilePath, jsonData)
            return true
        end
        
        -- Phương thức 4: Delta và một số executor khác
        if delta_config and delta_config.save then
            delta_config.save(ConfigSystem.FilePath, jsonData)
            return true
        end
        
        -- Phương thức 5: Codex
        if writefile and getrenv().writefile then
            getrenv().writefile(ConfigSystem.FilePath, jsonData)
            return true
        end
        
        return false
    end)
    
    if success then
        print("Đã lưu cấu hình thành công vào: " .. ConfigSystem.FilePath)
        return true
    else
        warn("Lưu cấu hình thất bại:", err)
        return false
    end
end

-- Hàm để tải cấu hình (thử nhiều phương thức)
ConfigSystem.LoadConfig = function()
    -- Thử các phương thức đọc khác nhau
    local success, content = pcall(function()
        -- Phương thức 1: readfile chuẩn (Synapse X, KRNL, Script-Ware)
        if readfile and isfile and isfile(ConfigSystem.FilePath) then
            return readfile(ConfigSystem.FilePath)
        end
        
        -- Phương thức 2: Fluxus
        if fluxus and fluxus.read_file and fluxus.file_exists and fluxus.file_exists(ConfigSystem.FilePath) then
            return fluxus.read_file(ConfigSystem.FilePath)
        end
        
        -- Phương thức 3: Delta
        if delta_config and delta_config.load and delta_config.exists and delta_config.exists(ConfigSystem.FilePath) then
            return delta_config.load(ConfigSystem.FilePath)
        end
        
        -- Phương thức 4: Codex
        if readfile and getrenv().readfile and isfile and getrenv().isfile and getrenv().isfile(ConfigSystem.FilePath) then
            return getrenv().readfile(ConfigSystem.FilePath)
        end
        
        return nil
    end)
    
    if success and content then
        local data
        success, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        
        if success and data then
        ConfigSystem.CurrentConfig = data
            print("Đã tải cấu hình từ: " .. ConfigSystem.FilePath)
        return true
    else
            warn("Lỗi khi phân tích cấu hình, tạo mới.")
        end
    end
    
    -- Nếu không đọc được hoặc có lỗi, tạo cấu hình mặc định
        ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
        ConfigSystem.SaveConfig()
    print("Khởi tạo cấu hình mới")
        return false
    end

-- Tạo một hệ thống auto save riêng
local function setupAutoSave()
    spawn(function()
        while wait(5) do -- Lưu mỗi 5 giây
            pcall(function()
                ConfigSystem.SaveConfig()
            end)
        end
    end)
end

-- Tải cấu hình khi khởi động
ConfigSystem.LoadConfig()
setupAutoSave() -- Bắt đầu auto save

-- Cập nhật hàm để lưu ngay khi thay đổi giá trị
local function setupSaveEvents()
    for _, tab in pairs(Tabs) do
        if tab and tab._components then
            for _, element in pairs(tab._components) do
                if element and element.OnChanged then
                    element.OnChanged:Connect(function()
                        pcall(function()
                            ConfigSystem.SaveConfig()
                        end)
                    end)
                end
            end
        end
    end
end

-- Thiết lập SaveManager của Fluent để tương thích
local playerName = game:GetService("Players").LocalPlayer.Name
if InterfaceManager then
    InterfaceManager:SetFolder("HTHub")
end
if SaveManager then
    SaveManager:SetFolder("HTHub/AriseCrossover/" .. playerName)
end

-- Tự động phát hiện HumanoidRootPart mới khi người chơi hồi sinh
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    hrp = newCharacter:WaitForChild("HumanoidRootPart")
end)

local function anticheat()
    local player = game.Players.LocalPlayer
    if player and player.Character then
        local characterScripts = player.Character:FindFirstChild("CharacterScripts")
        
        if characterScripts then
            local flyingFixer = characterScripts:FindFirstChild("FlyingFixer")
            if flyingFixer then
                flyingFixer:Destroy()
            end

            local characterUpdater = characterScripts:FindFirstChild("CharacterUpdater")
            if characterUpdater then
                characterUpdater:Destroy()
            end
        end
    end
end

local function isEnemyDead(enemy)
    local healthBar = enemy:FindFirstChild("HealthBar")
    if healthBar and healthBar:FindFirstChild("Main") and healthBar.Main:FindFirstChild("Bar") then
        local amount = healthBar.Main.Bar:FindFirstChild("Amount")
        if amount and amount:IsA("TextLabel") and amount.ContentText == "0 HP" then
            return true
        end
    end
    return false
end

local function getNearestSelectedEnemy()
    -- Nếu không tìm thấy quái vật nào trong 5 giây, làm mới danh sách
    if not selectedEnemyFoundTime or os.time() - selectedEnemyFoundTime > 5 then
        killedNPCs = {} -- Đặt lại danh sách quái vật đã tiêu diệt
    end

    local nearestEnemy = nil
    local shortestDistance = math.huge
    local playerPosition = hrp.Position

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
            local healthBar = enemy:FindFirstChild("HealthBar")
            if healthBar and healthBar:FindFirstChild("Main") and healthBar.Main:FindFirstChild("Title") then
                local title = healthBar.Main.Title
                if title and title:IsA("TextLabel") and title.ContentText == selectedMobName and not killedNPCs[enemy.Name] then
                    local enemyPosition = enemy.HumanoidRootPart.Position
                    local distance = (playerPosition - enemyPosition).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestEnemy = enemy
                    end
                end
            end
        end
    end

    if nearestEnemy then
        selectedEnemyFoundTime = os.time() -- Cập nhật thời gian tìm thấy quái vật
    end
    
    return nearestEnemy
end

local function getAnyEnemy()
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and not dungeonkill[enemy.Name] then
            return enemy
        end
    end
    return nil
end

local function fireShowPetsRemote()
    local args = {
        [1] = {
            [1] = {
                ["Event"] = "ShowPets"
            },
            [2] = "\t"
        }
    }
    remote:FireServer(unpack(args))
end

local function getNearestEnemy()
    local nearestEnemy, shortestDistance = nil, math.huge
    local playerPosition = hrp.Position

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and not killedNPCs[enemy.Name] then
            local distance = (playerPosition - enemy:GetPivot().Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestEnemy = enemy
            end
        end
    end
    return nearestEnemy
end

local function moveToTarget(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") then return end
    local enemyHrp = target.HumanoidRootPart

    if movementMethod == "Teleport" then
        hrp.CFrame = enemyHrp.CFrame * CFrame.new(0, 0, 6)
    elseif movementMethod == "Tween" then
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = enemyHrp.CFrame * CFrame.new(0, 0, 6)})
        tween:Play()
    elseif movementMethod == "Walk" then
        hrp.Parent:MoveTo(enemyHrp.Position)
    end
end

local function teleportAndTrackDeath()
    while teleportEnabled do
        local target = getNearestEnemy()
        if target and target.Parent then
            anticheat()
            moveToTarget(target)
            task.wait(0.5)
            fireShowPetsRemote()
            remote:FireServer({
                {
                    ["PetPos"] = {},
                    ["AttackType"] = "All",
                    ["Event"] = "Attack",
                    ["Enemy"] = target.Name
                },
                "\7"
            })

            while teleportEnabled and target.Parent and not isEnemyDead(target) do
                task.wait(0.1)
            end

            killedNPCs[target.Name] = true
        end
        task.wait(0.2)
    end
end

local function teleportDungeon()
    while teleportEnabled do
        local function getDistance(pos1, pos2)
            return (pos1 - pos2).Magnitude
        end

        local function getClosestEnemy()
            local closestEnemy = nil
            local closestDistance = math.huge
            local playerPosition = hrp.Position
            for _, enemy in pairs(enemiesFolder:GetChildren()) do
                local hp = enemy:GetAttribute("HP")
                if hp and hp > 0 and enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
                    local distance = getDistance(playerPosition, enemy.HumanoidRootPart.Position)
                    if distance < closestDistance then
                        closestDistance = distance
                        closestEnemy = enemy
                    end
                end
            end
            return closestEnemy
        end

        local function moveToEnemy(enemy)
            if enemy and enemy:FindFirstChild("HumanoidRootPart") then
                local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(hrp, tweenInfo, {
                    CFrame = enemy.HumanoidRootPart.CFrame * CFrame.new(0, 0, 6)
                })
                tween:Play()
                tween.Completed:Wait()
            end
        end

        local enemy = getClosestEnemy()
        if enemy then
            moveToEnemy(enemy)
            while teleportEnabled and enemy:GetAttribute("HP") and enemy:GetAttribute("HP") > 0 do
                task.wait(0.3)
            end
        else
            task.wait(1)
        end
    end
end

local function teleportToSelectedEnemy()
    local lastResetTime = os.time()
    
    while teleportEnabled do
        local target = getNearestSelectedEnemy()
        
        -- Nếu không tìm thấy mục tiêu trong 3 giây, làm mới danh sách
        if not target and os.time() - lastResetTime > 3 then
            killedNPCs = {}
            lastResetTime = os.time()
            print("Đã làm mới danh sách quái vật đã tiêu diệt")
        end
        
        if target and target.Parent then
            anticheat()
            moveToTarget(target)
            task.wait(0.5)
            fireShowPetsRemote()

            remote:FireServer({
                {
                    ["PetPos"] = {},
                    ["AttackType"] = "All",
                    ["Event"] = "Attack",
                    ["Enemy"] = target.Name
                },
                "\7"
            })

            while teleportEnabled and target.Parent and not isEnemyDead(target) do
                task.wait(0.1)
            end

            killedNPCs[target.Name] = true
        end
        task.wait(0.20)
    end
end

-- Farm Method Selection Dropdown
local Fluent
local SaveManager
local InterfaceManager

local success, err = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Lỗi khi tải thư viện Fluent: " .. tostring(err))
    -- Thử tải từ URL dự phòng
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua"))()
        SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
        InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
end

if not Fluent then
    error("Không thể tải thư viện Fluent. Vui lòng kiểm tra kết nối internet hoặc executor.")
    return
end

local Window = Fluent:CreateWindow({
    Title = "HT HUB | Arise Crossover",
    SubTitle = "",
    TabWidth = 140,
    Size = UDim2.fromOffset(450, 350),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Discord = Window:AddTab({ Title = "INFO", Icon = ""}),
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    tp = Window:AddTab({ Title = "Teleports", Icon = "" }),
    mount = Window:AddTab({ Title = "Mount Location/farm", Icon = "" }),
    dungeon = Window:AddTab({ Title = "Dungeon ", Icon = "" }),
    shop = Window:AddTab({ Title = "Shop", Icon = "" }),
    Player = Window:AddTab({ Title = "Player", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Tạo mapping giữa các map và danh sách mob tương ứng
local mobsByWorld = {
    ["SoloWorld"] = {"Soondoo", "Gonshee", "Daek", "Longin", "Anders", "Largalgan"},
    ["NarutoWorld"] = {"Snake Man", "Blossom", "Black Crow"},
    ["OPWorld"] = {"Shark Man", "Eminel", "Light Admiral"},
    ["BleachWorld"] = {"Luryu", "Fyakuya", "Genji"},
    ["BCWorld"] = {"Sortudo", "Michille", "Wind"},
    ["ChainsawWorld"] = {"Heaven", "Zere", "Ika"},
    ["JojoWorld"] = {"Diablo", "Gosuke", "Golyne"},
    ["DBWorld"] = {"Turtle", "Green", "Sky"},
    ["OPMWorld"] = {"Rider", "Cryborg", "Hurricane"}
}

local selectedWorld = "SoloWorld" -- Default world

-- Dropdown để chọn World/Map
Tabs.Main:AddDropdown("WorldDropdown", {
    Title = "Select World",
    Values = {"SoloWorld", "NarutoWorld", "OPWorld", "BleachWorld", "BCWorld", "ChainsawWorld", "JojoWorld", "DBWorld", "OPMWorld"},
    Multi = false,
    Default = selectedWorld,
    Callback = function(world)
        selectedWorld = world
        ConfigSystem.CurrentConfig.SelectedWorld = world
        
        -- Cập nhật danh sách mob dựa trên world được chọn
        local mobDropdown = Fluent.Options.WorldMobDropdown
        if mobDropdown then
            mobDropdown:SetValues(mobsByWorld[world] or {})
            -- Đặt giá trị mặc định nếu có mob
            if #mobsByWorld[world] > 0 then
                selectedMobName = mobsByWorld[world][1]
                mobDropdown:SetValue(selectedMobName)
                ConfigSystem.CurrentConfig.SelectedMobName = selectedMobName
            else
                selectedMobName = ""
            end
        end
        
        ConfigSystem.SaveConfig()
        killedNPCs = {} -- Đặt lại danh sách NPC đã tiêu diệt khi thay đổi world
    end
})

-- Dropdown để chọn Mob trong world đã chọn
Tabs.Main:AddDropdown("WorldMobDropdown", {
    Title = "Select Enemy",
    Values = mobsByWorld[selectedWorld] or {},
    Multi = false,
    Default = mobsByWorld[selectedWorld] and mobsByWorld[selectedWorld][1] or "",
    Callback = function(mob)
        selectedMobName = mob
        ConfigSystem.CurrentConfig.SelectedMobName = mob
        ConfigSystem.SaveConfig()
        killedNPCs = {} -- Đặt lại danh sách NPC đã tiêu diệt khi thay đổi mob
        print("Selected Mob:", selectedMobName) -- Gỡ lỗi
    end
})

Tabs.Main:AddToggle("FarmSelectedMob", {
    Title = "Farm Selected Mob",
    Default = ConfigSystem.CurrentConfig.FarmSelectedMob or false,
    Callback = function(state)
        teleportEnabled = state
        damageEnabled = state -- Đảm bảo tính năng tấn công mobs được kích hoạt
        ConfigSystem.CurrentConfig.FarmSelectedMob = state
        ConfigSystem.SaveConfig()
        killedNPCs = {} -- Đặt lại danh sách NPC đã tiêu diệt khi bắt đầu farm
        if state then
            task.spawn(teleportToSelectedEnemy)
        end
    end
})

Tabs.Main:AddToggle("TeleportMobs", {
    Title = "Auto farm (nearest NPCs)",
    Default = ConfigSystem.CurrentConfig.AutoFarmNearestNPCs or false,
    Callback = function(state)
        teleportEnabled = state
        ConfigSystem.CurrentConfig.AutoFarmNearestNPCs = state
        ConfigSystem.SaveConfig()
        if state then
            task.spawn(teleportAndTrackDeath)
        end
    end
})

local Dropdown = Tabs.Main:AddDropdown("MovementMethod", {
    Title = "Farming Method",
    Values = {"Tween", "Teleport"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.FarmingMethod == "Teleport" and 2 or 1,
    Callback = function(option)
        movementMethod = option
        ConfigSystem.CurrentConfig.FarmingMethod = option
        ConfigSystem.SaveConfig()
    end 
})

Tabs.Main:AddToggle("GamepassShadowFarm", {
    Title = "Shadow farm",
    Default = false,
    Callback = function(state)
        local attackatri = game:GetService("Players").LocalPlayer.Settings
        local atri = attackatri:GetAttribute("AutoAttack")
        
        if state then
            -- Bật tính năng
            if atri == false then
                attackatri:SetAttribute("AutoAttack", true)
            end
            print("Shadow farm đã bật")
        else
            -- Tắt tính năng
            attackatri:SetAttribute("AutoAttack", false)
            print("Shadow farm đã tắt")
        end
    end
})

-- Thêm Auto Attack toggle
local autoAttackEnabled = false
local attackCooldown = 0.5

Tabs.Main:AddToggle("AutoAttackToggle", {
    Title = "Auto Attack Mobs",
    Default = false,
    Callback = function(state)
        autoAttackEnabled = state
        
        if state then
            Fluent:Notify({
                Title = "Auto Attack",
                Content = "Đã bật tự động tấn công mobs",
                Duration = 3
            })
            
            -- Bắt đầu vòng lặp auto attack
            task.spawn(function()
                while autoAttackEnabled do
                    local targetEnemy
                    
                    -- Kiểm tra xem Farm Selected Mob có đang bật không
                    if ConfigSystem.CurrentConfig.FarmSelectedMob and selectedMobName ~= "" then
                        -- Nếu đang farm mob đã chọn, tìm mob đó
                        targetEnemy = getNearestSelectedEnemy()
                    else
                        -- Nếu không, tìm bất kỳ mob nào gần nhất
                        targetEnemy = getNearestEnemy()
                    end
                    
                    if targetEnemy then
                        local args = {
                            [1] = {
                                [1] = {
                                    ["Event"] = "PunchAttack",
                                    ["Enemy"] = targetEnemy.Name
                                },
                                [2] = "\4"
                            }
                        }
                        remote:FireServer(unpack(args))
                    end
                    task.wait(attackCooldown) -- Chờ giữa các lần tấn công
                end
            end)
        else
            Fluent:Notify({
                Title = "Auto Attack",
                Content = "Đã tắt tự động tấn công mobs",
                Duration = 3
            })
        end
    end
})

local function SetSpawnAndReset(spawnName)
    local args = {
        [1] = {
            [1] = {
                ["Event"] = "ChangeSpawn",
                ["Spawn"] = spawnName
            },
            [2] = "\n"
        }
    }

    local remote = game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")
    remote:FireServer(unpack(args))

    -- Đợi một chút trước khi hồi sinh (tùy chọn, để đảm bảo điểm hồi sinh được thiết lập)
    task.wait(0.5)

    -- Hồi sinh nhân vật
    local player = game.Players.LocalPlayer
if player.Character and player.Character.Parent then
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = 0 -- Tạo ra cái chết tự nhiên mà không xóa nhân vật đột ngột
    end
end

end

Tabs.tp:AddButton({
    Title = "Leveling City",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("SoloWorld")
    end
})

Tabs.tp:AddButton({
    Title = "Grass Village",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("NarutoWorld")
    end
})

Tabs.tp:AddButton({
    Title = "Brum Island",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("OPWorld") -- Thay đổi thành tên điểm hồi sinh đúng
    end
})

Tabs.tp:AddButton({
    Title = "Faceheal Town",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("BleachWorld")
    end
})

Tabs.tp:AddButton({
    Title = "Lucky Kingdom",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("BCWorld")
    end
})

Tabs.tp:AddButton({
    Title = "Nipon City",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("ChainsawWorld")
    end
})

Tabs.tp:AddButton({
    Title = "Mori Town",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("JojoWorld")
    end
})

Tabs.tp:AddButton({
    Title = "Dragon City",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("DBWorld")
    end
})

Tabs.tp:AddButton({
    Title = "XZ City",
    Description = "Set spawn & reset",
    Callback = function()
        SetSpawnAndReset("OPMWorld")
    end
})

local TweenService = game:GetService("TweenService")

-- Lấy Player và HumanoidRootPart
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Cập nhật HRP khi nhân vật hồi sinh
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    hrp = character:WaitForChild("HumanoidRootPart") -- Lấy HRP mới sau khi hồi sinh
end)

-- Hàm di chuyển (Luôn sử dụng HRP mới nhất)
local function teleportWithTween(targetCFrame)
    if hrp then
        local tweenInfo = TweenInfo.new(
            2, -- Thời gian (giây)
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out,
            0, -- Không lặp lại
            false, -- Không đảo ngược
            0 -- Không độ trễ
        )

        local tweenGoal = {CFrame = targetCFrame}
        local tween = TweenService:Create(hrp, tweenInfo, tweenGoal)
        tween:Play()
    end
end


-- Locations List
local locations = {
    {Name = "Location 1", CFrame = CFrame.new(-6161.25781, 140.639832, 5512.9668, -0.41691944, -8.07482721e-08, 0.908943415, -2.94452178e-07, 1, -4.62235228e-08, -0.908943415, -2.86911842e-07, -0.41691944)},
    {Name = "Location 2", CFrame = CFrame.new(-5868.44141, 132.70488, 362.519379, 0.836233854, -7.47273816e-08, -0.548372984, 2.59595481e-07, 1, 2.59595481e-07, 0.548372984, -3.59437678e-07, 0.836233854)},
    {Name = "Location 3", CFrame = CFrame.new(-5430.81006, 107.441559, -5502.25244, 0.8239398, -3.60997859e-07, -0.566677332, 2.59595453e-07, 1, -2.59595396e-07, 0.566677332, 6.67841249e-08, 0.8239398)},
    {Name = "Location 4", CFrame = CFrame.new(-702.243225, 133.344467, -3538.11646, 0.978662074, 0.000114096198, -0.205476329, -0.000112703143, 1, 1.84834444e-05, 0.205476329, 5.06878177e-06, 0.978662074)},
    {Name = "Location 5", CFrame = CFrame.new(450.001709, 117.564827, 3435.4292, -0.999887109, -1.20863996e-12, 0.0150266131, -1.12492459e-12, 1, 5.57959278e-12, -0.0150266131, 5.56205906e-12, -0.999887109)},
    {Name = "Location 6", CFrame = CFrame.new(3230.96826, 135.41008, 36.1600113, -0.534268856, -4.75206689e-05, 0.845314622, -7.48304665e-05, 1, 8.92103617e-06, -0.845314622, -5.84890549e-05, -0.534268856)},
    {Name = "Location 7", CFrame = CFrame.new(4325.36523, 118.995422, -4819.78857, -0.257801384, 3.98855832e-07, -0.966197908, -5.63039578e-07, 1, 5.63040146e-07, 0.966197908, 6.89160231e-07, -0.257801384)}
    
    
}

-- Add buttons for each location
for _, loc in ipairs(locations) do
    Tabs.mount:AddButton({
        Title = loc.Name,
        Callback = function()
            teleportWithTween(loc.CFrame)
        end
    })
end


local autoDestroy = false
local autoArise = false

-- Function to Fire DestroyPrompt


local enemiesFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")


local function fireDestroy()
    while autoDestroy do
        task.wait(0.3)  -- Delay to prevent overloading

        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if enemy:IsA("Model") then
                local rootPart = enemy:FindFirstChild("HumanoidRootPart")
                local DestroyPrompt = rootPart and rootPart:FindFirstChild("DestroyPrompt")

                if DestroyPrompt then
                    DestroyPrompt:SetAttribute("MaxActivationDistance", 100000)
                    fireproximityprompt(DestroyPrompt)
                end
            end
        end
    end
end



-- Function to Fire ArisePrompt

local enemiesFolder = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")


local function fireArise()
    while autoArise do
        task.wait(0.3)  -- Delay to prevent overloading

        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if enemy:IsA("Model") then
                local rootPart = enemy:FindFirstChild("HumanoidRootPart")
                local arisePrompt = rootPart and rootPart:FindFirstChild("ArisePrompt")

                if arisePrompt then
                    arisePrompt:SetAttribute("MaxActivationDistance", 100000)
                    fireproximityprompt(arisePrompt)
                end
            end
        end
    end
end


-- Auto Destroy Toggle
Tabs.Main:AddToggle("AutoDestroy", {
    Title = "Auto Destroy",
    Default = ConfigSystem.CurrentConfig.MainAutoDestroy or false,
    Callback = function(state)
        autoDestroy = state
        ConfigSystem.CurrentConfig.MainAutoDestroy = state
        ConfigSystem.SaveConfig()
        if state then
            task.spawn(fireDestroy)
        end
    end
})

-- Auto Arise Toggle
Tabs.Main:AddToggle("AutoArise", {
    Title = "Auto Arise",
    Default = ConfigSystem.CurrentConfig.MainAutoArise or false,
    Callback = function(state)
        autoArise = state
        ConfigSystem.CurrentConfig.MainAutoArise = state
        ConfigSystem.SaveConfig()
        if state then
            task.spawn(fireArise)
        end
    end
})

Tabs.dungeon:AddToggle("AutoDestroy", {
    Title = "Auto Destroy",
    Default = false,
    Flag = "DungeonAutoDestroy", -- Thêm Flag để lưu cấu hình
    Callback = function(state)
        autoDestroy = state
        if state then
            task.spawn(fireDestroy)
        end
    end
})

-- Auto Arise Toggle
Tabs.dungeon:AddToggle("AutoArise", {
    Title = "Auto Arise",
    Default = false,
    Flag = "DungeonAutoArise", -- Thêm Flag để lưu cấu hình
    Callback = function(state)
        autoArise = state
        if state then
            task.spawn(fireArise)
        end
    end
})


local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local dungeonFolder = workspace:WaitForChild("__Main"):WaitForChild("__Dungeon")

-- Variable to control teleporting
local teleportingEnabled = false

-- Function to create a dungeon
local function createDungeon()
    print("[DEBUG] Đang cố gắng tạo dungeon...")
    local args = {
        [1] = {
            [1] = {
                ["Event"] = "DungeonAction",
                ["Action"] = "Create"
            },
            [2] = "\n" 
        }
    }
    ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
    print("[DEBUG] Đã kích hoạt sự kiện tạo Dungeon!")
end

-- Function to start the dungeon
local function startDungeon()
    local dungeonInstance = dungeonFolder:FindFirstChild("Dungeon")
    if dungeonInstance then
        local dungeonID = dungeonInstance:GetAttribute("ID")
        if dungeonID then
            print("[DEBUG] Bắt đầu dungeon với ID:", dungeonID)
            local args = {
                [1] = {
                    [1] = {
                        ["Dungeon"] = dungeonID,
                        ["Event"] = "DungeonAction",
                        ["Action"] = "Start"
                    },
                    [2] = "\n"
                }
            }
            ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
            print("[DEBUG] Đã kích hoạt sự kiện bắt đầu Dungeon!")
        else
            print("[LỖI] Không tìm thấy ID của Dungeon!")
        end
    else
        print("[LỖI] Không tìm thấy instance của Dungeon!")
    end
end

-- Function to teleport directly to an object and bypass anti-cheat
local function teleportToObject(object)
    if object and object:IsA("Part") then
        print("[DEBUG] Đang dịch chuyển đến:", object.Name)

        -- Vượt qua anti-cheat
        local f = player.Character and player.Character:FindFirstChild("CharacterScripts") and player.Character.CharacterScripts:FindFirstChild("FlyingFixer")
        if f then f:Destroy() else print("blablabla bleble") end

        local cha = player.Character and player.Character:FindFirstChild("CharacterScripts") and player.Character.CharacterScripts:FindFirstChild("CharacterUpdater")
        if cha then cha:Destroy() print("discord") else print("Cid") end

        -- Dịch chuyển trực tiếp
        hrp.CFrame = object.CFrame
        print("[DEBUG] Đã hoàn thành dịch chuyển đến:", object.Name)

        task.wait(2) -- Độ trễ nhỏ sau khi dịch chuyển
        createDungeon() -- Kích hoạt remote tạo dungeon

        task.wait(1) -- Độ trễ ngắn trước khi bắt đầu dungeon
        startDungeon() -- Kích hoạt remote bắt đầu dungeon
    else
        print("[LỖI] Mục tiêu dịch chuyển không hợp lệ!")
    end
end

-- Function to continuously teleport to objects when enabled
local function teleportLoop()
    while teleportingEnabled do
        print("[DEBUG] Đang tìm kiếm các đối tượng dungeon...")
        local foundObject = false
        for _, object in ipairs(dungeonFolder:GetChildren()) do
            if object:IsA("Part") then
                foundObject = true
                teleportToObject(object)
                task.wait(1) -- Ngăn thực thi quá mức
            end
        end
        if not foundObject then
            print("[CẢNH BÁO] Không tìm thấy đối tượng dungeon hợp lệ!")
        end
        task.wait(0.5) -- Độ trễ trước khi kiểm tra lại
    end
end



-- Add the toggle button to start/stop teleporting
Tabs.dungeon:AddToggle("TeleportToDungeon", {
    Title = "Teleport to Dungeon",
    Default = false,
    Callback = function(state)
        teleportingEnabled = state
        print("[DEBUG] Đã bật/tắt dịch chuyển:", state)
        if state then
            task.spawn(teleportLoop) -- Bắt đầu vòng lặp dịch chuyển khi bật
        end
    end
})


local AutoDetectToggle = Tabs.dungeon:AddToggle("AutoDetectDungeon", {Title = "Auto Detect Dungeon", Default = true})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local villageSpawns = {
    ["Grass Village"] = "NarutoWorld",
    ["BRUM ISLAND"] = "OPWorld",
    ["Leveling City"] = "SoloWorld",
    ["FACEHEAL TOWN"] = "BleachWorld",
    ["Lucky"] = "BCWorld",
    ["Nipon City"] = "ChainsawWorld",
    ["Mori Town"] = "JojoWorld",
    ["Dragon City"] = "DBWorld",
    ["XZ City"] = "OPMWorld",
}

local function SetSpawnAndReset(spawnName)
    local args = {
        [1] = {
            [1] = {
                ["Event"] = "ChangeSpawn",
                ["Spawn"] = spawnName
            },
            [2] = "\n"
        }
    }

    local remote = ReplicatedStorage:WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")
    remote:FireServer(unpack(args))

    -- Đợi một chút trước khi hồi sinh (tùy chọn, để đảm bảo điểm hồi sinh được thiết lập)
    task.wait(0.5)

    -- Hồi sinh nhân vật
    if player.Character then
        player.Character:BreakJoints() -- Buộc nhân vật phải hồi sinh
    end
end

local function detectDungeon()
    player.PlayerGui.Warn.ChildAdded:Connect(function(dungeon)
        if dungeon:IsA("Frame") and AutoDetectToggle.Value then
            print("Đã phát hiện Dungeon!")
            for _, child in ipairs(dungeon:GetChildren()) do
                if child:IsA("TextLabel") then
                    for village, spawnName in pairs(villageSpawns) do
                        if string.find(string.lower(child.Text), string.lower(village)) then
                            teleportEnabled = false
                            print("Đã phát hiện làng:", village)
                            SetSpawnAndReset(spawnName)
                            return
                        end
                    end
                end
            end
        end
    end)
end

-- Đảm bảo hàm hoạt động
AutoDetectToggle:OnChanged(function(value)
    if value then
        detectDungeon()
    end
end)

detectDungeon()

local function resetAutoFarm()
    -- Đặt lại tất cả trạng thái và hàm
    killedNPCs = {} -- Đặt lại số lượng NPC đã tiêu diệt

    print("AutoFarm đã được đặt lại!") -- In thông báo xác nhận

    -- Khởi động lại tất cả các hàm nếu cần
end

task.spawn(function()
    while true do
        task.wait(120) -- Đợi 120 giây
        resetAutoFarm() -- Gọi hàm đặt lại
    end
end)

local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = game:GetService("Players").LocalPlayer

local antiAfkConnection

local AntiAfkToggle = Tabs.Player:AddToggle("AntiAfk", {
    Title = "Anti AFK",
    Default = false,
    Callback = function(enabled)
        if enabled then
            print("Đã bật Anti AFK")
            -- Đảm bảo không tạo nhiều kết nối
            if not antiAfkConnection then
                antiAfkConnection = LocalPlayer.Idled:Connect(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1) -- Thời gian chờ có thể điều chỉnh
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end
        else
            print("Đã tắt Anti AFK")
            -- Ngắt kết nối sự kiện khi tắt
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil -- Đặt lại biến kết nối
            end
        end
    end
})

Tabs.Player:AddButton({
    Title = "Boost FPS",
    Description = "Lowers graphics",
    Callback = function()
        local Optimizer = {Enabled = false}

        local function DisableEffects()
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = not Optimizer.Enabled
                end
                if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then
                    v.Enabled = not Optimizer.Enabled
                end
            end
        end

        local function MaximizePerformance()
            local lighting = game:GetService("Lighting")
            if Optimizer.Enabled then
                lighting.GlobalShadows = false
                lighting.FogEnd = 9e9
                lighting.Brightness = 2
                settings().Rendering.QualityLevel = 1
                settings().Physics.PhysicsEnvironmentalThrottle = 1
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
                settings().Physics.AllowSleep = true
                settings().Physics.ForceCSGv2 = false
                settings().Physics.DisableCSGv2 = true
                settings().Rendering.EagerBulkExecution = true

                game:GetService("StarterGui"):SetCore("TopbarEnabled", false)

                settings().Network.IncomingReplicationLag = 0
                settings().Rendering.MaxPartCount = 100000
            else
                lighting.GlobalShadows = true
                lighting.FogEnd = 100000
                lighting.Brightness = 3
                settings().Rendering.QualityLevel = 7
                settings().Physics.PhysicsEnvironmentalThrottle = 0
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
                settings().Physics.AllowSleep = false
                settings().Physics.ForceCSGv2 = true
                settings().Physics.DisableCSGv2 = false
                settings().Rendering.EagerBulkExecution = false

                game:GetService("StarterGui"):SetCore("TopbarEnabled", true)

                settings().Network.IncomingReplicationLag = 1
                settings().Rendering.MaxPartCount = 500000
            end
        end

        local function OptimizeInstances()
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CastShadow = not Optimizer.Enabled
                    v.Reflectance = Optimizer.Enabled and 0 or v.Reflectance
                    v.Material = Optimizer.Enabled and Enum.Material.SmoothPlastic or v.Material
                end
                if v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = Optimizer.Enabled and 1 or 0
                end
                if v:IsA("MeshPart") then
                    v.RenderFidelity = Optimizer.Enabled and Enum.RenderFidelity.Performance or Enum.RenderFidelity.Precise
                end
            end

            game:GetService("Debris"):SetAutoCleanupEnabled(true)
        end

        local function CleanMemory()
            if Optimizer.Enabled then
                game:GetService("Debris"):AddItem(Instance.new("Model"), 0)
                settings().Physics.ThrottleAdjustTime = 2
                game:GetService("RunService"):Set3dRenderingEnabled(false)
            else
                game:GetService("RunService"):Set3dRenderingEnabled(true)
            end
        end

        local function ToggleOptimizer()
            Optimizer.Enabled = not Optimizer.Enabled
            DisableEffects()
            MaximizePerformance()
            OptimizeInstances()
            CleanMemory()
            print("FPS Booster: " .. (Optimizer.Enabled and "ON" or "OFF"))
        end

        game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.RightControl then
                ToggleOptimizer()
            end
        end)

        ToggleOptimizer()

        game:GetService("RunService").Heartbeat:Connect(function()
            if Optimizer.Enabled then
                CleanMemory()
            end
        end)
    end
})



local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local targetCFrame = CFrame.new(
    3648.76318, 223.552261, 2637.36719, 
    0.846323907, 7.72367986e-18, -0.532668591, 
    -1.10462046e-17, 1, -3.05065368e-18, 
    0.532668591, 8.46580728e-18, 0.846323907
)

local function tweenToPivot()
    hrp.CFrame = targetCFrame
end


local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local speedValue = 16 -- Tốc độ di chuyển mặc định
local jumpValue = 50  -- Lực nhảy mặc định
local speedEnabled = false
local jumpEnabled = false

local function updateCharacter()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        humanoid.WalkSpeed = speedEnabled and speedValue or 16
        humanoid.JumpPower = jumpEnabled and jumpValue or 50
    end
end

-- Nhập tốc độ
local SpeedInput = Tabs.Player:AddInput("SpeedInput", {
    Title = "Speed",
    Default = tostring(speedValue),
    Placeholder = "Enter speed",
    Numeric = true,
    Finished = true, 
    Callback = function(Value)
        speedValue = tonumber(Value) or 16
        updateCharacter() -- Cập nhật nhân vật ngay lập tức khi tốc độ thay đổi
    end
})

-- Nhập lực nhảy
local JumpInput = Tabs.Player:AddInput("JumpInput", {
    Title = "Jump Power",
    Default = tostring(jumpValue),
    Placeholder = "Enter jump power",
    Numeric = true,
    Finished = true, 
    Callback = function(Value)
        jumpValue = tonumber(Value) or 50
        updateCharacter() -- Cập nhật nhân vật ngay lập tức khi lực nhảy thay đổi
    end
})

-- Bật/tắt tốc độ
local SpeedToggle = Tabs.Player:AddToggle("SpeedToggle", {
    Title = "Enable Speed",
    Default = false
})

SpeedToggle:OnChanged(function(Value)
    speedEnabled = Value
    updateCharacter() -- Cập nhật nhân vật ngay lập tức khi toggle thay đổi
end)

-- Bật/tắt lực nhảy
local JumpToggle = Tabs.Player:AddToggle("JumpToggle", {
    Title = "Enable Jump Power",
    Default = false
})

JumpToggle:OnChanged(function(Value)
    jumpEnabled = Value
    updateCharacter() -- Cập nhật nhân vật ngay lập tức khi toggle thay đổi
end)

-- Cập nhật nhân vật khi hồi sinh
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- Đợi nhân vật tải xong
    updateCharacter()
end)

-- Cập nhật ban đầu
updateCharacter()

local player = game.Players.LocalPlayer

local function tweenCharacter(targetCFrame)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = tweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
    end
end

-- Thêm nút
Tabs.tp:AddButton({
    Title = "Tween to Dedu island",
    Description = "Smoothly moves your character",
    Callback = function()
        tweenCharacter(CFrame.new(3859.06299, 60.1228409, 3081.9458, -0.987112403, 6.46206388e-07, -0.160028473, 5.63319077e-07, 1, 5.63319418e-07, 0.160028473, 4.65912507e-07, -0.987112403)) -- Thay đổi vị trí theo nhu cầu
    end
})



local NoClipToggle = Tabs.Player:AddToggle("NoClipToggle", {
    Title = "Enable NoClip",
    Default = false
})

-- Hàm NoClip
local noclipEnabled = false
NoClipToggle:OnChanged(function(Value)
    noclipEnabled = Value
    if noclipEnabled then
        task.spawn(function()
            while noclipEnabled do
                for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                task.wait()
            end
        end)
    else
        for _, part in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end)



Tabs.Player:AddButton({
    Title = "Server Hop",
    Description = "Switches to a different server",
    Callback = function()
        local PlaceID = game.PlaceId
        local AllIDs = {}
        local foundAnything = ""
        local actualHour = os.date("!*t").hour
        local File = pcall(function()
            AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
        end)
        if not File then
            table.insert(AllIDs, actualHour)
            writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
        end
        local function TPReturner()
            local Site
            if foundAnything == "" then
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            for _, v in pairs(Site.data) do
                if tonumber(v.maxPlayers) > tonumber(v.playing) then
                    local ID = tostring(v.id)
                    local isNewServer = true
                    for _, existing in pairs(AllIDs) do
                        if ID == tostring(existing) then
                            isNewServer = false
                            break
                        end
                    end
                    if isNewServer then
                        table.insert(AllIDs, ID)
                        writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                        game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
                        return
                    end
                end
            end
        end
        TPReturner()
    end
})



    

        
Tabs.dungeon:AddToggle("AutoBuyDungeonTicket", {
    Title = "Auto Buy Dungeon Ticket",
    Default = false,
    Callback = function(state)
        buyTicketEnabled = state
        print("[DEBUG] Auto Buy Dungeon Ticket toggled:", state)
        
        if state then
            task.spawn(function()
                while buyTicketEnabled do
                    local args = {
                        [1] = {
                            [1] = {
                                ["Type"] = "Gems",
                                ["Event"] = "DungeonAction",
                                ["Action"] = "BuyTicket"
                            },
                            [2] = "\n"
                        }
                    }

                    game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
                    task.wait(5) -- Đợi 5 giây trước khi gửi lại
                end
            end)
        end
    end
})



    local localPlayer = game:GetService("Players").LocalPlayer
local playerCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local playerHRP = playerCharacter:WaitForChild("HumanoidRootPart")
local enemyContainer = workspace:WaitForChild("__Main"):WaitForChild("__Enemies"):WaitForChild("Client")
local networkEvent = game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")

local autoFarmActive = false
local defeatedEnemies = {}

local function isTargetDefeated(target)
    local healthUI = target:FindFirstChild("HealthBar")
    if healthUI and healthUI:FindFirstChild("Main") and healthUI.Main:FindFirstChild("Bar") then
        local healthText = healthUI.Main.Bar:FindFirstChild("Amount")
        if healthText and healthText:IsA("TextLabel") and healthText.ContentText == "0 HP" then
            return true
        end
    end
    return false
end

local function findClosestTarget()
    local closestJJ2, closestJJ3, closestJJ4 = nil, nil, nil
    local distJJ2, distJJ3, distJJ4 = math.huge, math.huge, math.huge
    local playerPos = localPlayer.Character and localPlayer.Character:GetPivot().Position

    if not playerPos then return nil end

    for _, enemy in ipairs(enemyContainer:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
            local enemyType = enemy:GetAttribute("ID")
            
            -- Đảm bảo script bỏ qua các kẻ địch đã chết
            if not defeatedEnemies[enemy.Name] then
                local distance = (playerPos - enemy:GetPivot().Position).Magnitude
                
                if enemyType == "JJ2" and distance < distJJ2 then
                    distJJ2 = distance
                    closestJJ2 = enemy
                elseif enemyType == "JJ3" and distance < distJJ3 then
                    distJJ3 = distance
                    closestJJ3 = enemy
                elseif enemyType == "JJ4" and distance < distJJ4 then
                    distJJ4 = distance
                    closestJJ4 = enemy
                end
            end
        end
    end

    -- Ưu tiên: JJ2 > JJ3 > JJ4
    return closestJJ2 or closestJJ3 or closestJJ4
end

local function triggerPetVisibility()
    local arguments = {
        [1] = {
            [1] = {
                ["Event"] = "ShowPets"
            },
            [2] = "\t"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(arguments))
end

local function startAutoFarm()
    while autoFarmActive do
        local targetEnemy = findClosestTarget()
        
        while autoFarmActive and targetEnemy do
            if not targetEnemy.Parent then break end

            local targetHRP = targetEnemy:FindFirstChild("HumanoidRootPart")
            local playerHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

            if targetHRP and playerHRP then
                -- Move to target enemy
                playerHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 6)

                task.wait(0.5)
                triggerPetVisibility()

                networkEvent:FireServer({
                    {
                        ["PetPos"] = {},
                        ["AttackType"] = "All",
                        ["Event"] = "Attack",
                        ["Enemy"] = targetEnemy.Name
                    },
                    "\7"
                })

                -- Wait until enemy is defeated or a higher-priority one appears
                while autoFarmActive and targetEnemy.Parent do
                    if isTargetDefeated(targetEnemy) then
                        defeatedEnemies[targetEnemy.Name] = true -- Mark it as dead immediately
                        break
                    end
                    
                    task.wait(0.1)
                    
                    -- Switch if a higher-priority target appears
                    local newTarget = findClosestTarget()
                    if newTarget and newTarget:GetAttribute("ID") == "JJ2" and newTarget ~= targetEnemy then
                        break
                    elseif newTarget and newTarget:GetAttribute("ID") == "JJ3" and targetEnemy:GetAttribute("ID") == "JJ4" then
                        break
                    end
                end
            end

            targetEnemy = findClosestTarget() -- Move to next enemy
        end

        task.wait(0.20)
    end
end

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "auto Jeju farm",
    Default = false,
    Callback = function(state)
        autoFarmActive = state
        if state then
            task.spawn(startAutoFarm)
        end
    end
})


local AutoEnterDungeon = Tabs.dungeon:AddToggle("AutoEnterDungeon", { Title = "Auto Enter Guild Dungeon", Default = false })

local function EnterDungeon()
    while AutoEnterDungeon.Value do
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "DungeonAction",
                    ["Action"] = "TestEnter"
                },
                [2] = "\n"
            }
        }

        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
        task.wait(0.5) -- Điều chỉnh độ trễ nếu cần
    end
end

AutoEnterDungeon:OnChanged(function(Value)
    if Value then
        task.spawn(EnterDungeon) -- Start loop when enabled
    end
end)

Tabs.Discord:AddParagraph({
    Title = "Thông tin",
    Content = "Script được tạo bởi HT HUB"
})

Tabs.Discord:AddButton({
    Title = "Copy Discord Link",
    Description = "Join my discord",
    Callback = function()
        setclipboard("https://discord.gg/v94FqK3zH5")
        Fluent:Notify({
            Title = "Đã sao chép!",
            Content = "Đường dẫn Discord đã được sao chép vào clipboard.",
            Duration = 3
        })
    end
})


SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Thay đổi cách lưu cấu hình để sử dụng tên người chơi
local playerName = game:GetService("Players").LocalPlayer.Name
InterfaceManager:SetFolder("HTHub")
SaveManager:SetFolder("HTHub/AriseCrossover/" .. playerName)

-- Xóa đoạn xây dựng phần cấu hình trong Settings tab
-- InterfaceManager:BuildInterfaceSection(Tabs.Settings)
-- SaveManager:BuildConfigSection(Tabs.Settings)

-- Thêm thông tin vào tab Settings
Tabs.Settings:AddParagraph({
    Title = "Cấu hình tự động",
    Content = "Cấu hình của bạn đang được tự động lưu theo tên nhân vật: " .. playerName
})

Tabs.Settings:AddParagraph({
    Title = "Phím tắt",
    Content = "Nhấn LeftControl để ẩn/hiện giao diện"
})

-- Thêm nút xóa cấu hình hiện tại
Tabs.Settings:AddButton({
    Title = "Xóa cấu hình hiện tại",
    Description = "Đặt lại tất cả cài đặt về mặc định",
    Callback = function()
        SaveManager:Delete("AutoSave_" .. playerName)
        Fluent:Notify({
            Title = "Đã xóa cấu hình",
            Content = "Tất cả cài đặt đã được đặt lại về mặc định",
            Duration = 3
        })
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "HT HUB",
    Content = "Script đã tải xong! Cấu hình tự động lưu theo tên người chơi: " .. playerName,
    Duration = 3
})

-- Thay đổi cách tải cấu hình
local function AutoSaveConfig()
    local configName = "AutoSave_" .. playerName
    
    -- Tự động lưu cấu hình hiện tại
    task.spawn(function()
        while task.wait(5) do -- Lưu mỗi 5 giây
            pcall(function()
                SaveManager:Save(configName)
            end)
        end
    end)
    
    -- Tải cấu hình đã lưu nếu có
    pcall(function()
        SaveManager:Load(configName)
    end)
end

-- Thực thi tự động lưu/tải cấu hình
AutoSaveConfig()

-- Thêm hỗ trợ Mobile UI
repeat task.wait(0.25) until game:IsLoaded()
getgenv().Image = "rbxassetid://13099788281" -- ID tài nguyên hình ảnh đã sửa
getgenv().ToggleUI = "LeftControl" -- Phím để bật/tắt giao diện

-- Tạo giao diện mobile cho người dùng điện thoại
task.spawn(function()
    local success, errorMsg = pcall(function()
        if not getgenv().LoadedMobileUI == true then 
            getgenv().LoadedMobileUI = true
            local OpenUI = Instance.new("ScreenGui")
            local ImageButton = Instance.new("ImageButton")
            local UICorner = Instance.new("UICorner")
            
            -- Kiểm tra thiết bị
            if syn and syn.protect_gui then
                syn.protect_gui(OpenUI)
                OpenUI.Parent = game:GetService("CoreGui")
            elseif gethui then
                OpenUI.Parent = gethui()
            else
                OpenUI.Parent = game:GetService("CoreGui")
            end
            
            OpenUI.Name = "OpenUI"
            OpenUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            
            ImageButton.Parent = OpenUI
            ImageButton.BackgroundColor3 = Color3.fromRGB(105,105,105)
            ImageButton.BackgroundTransparency = 0.8
            ImageButton.Position = UDim2.new(0.9,0,0.1,0)
            ImageButton.Size = UDim2.new(0,50,0,50)
            ImageButton.Image = getgenv().Image
            ImageButton.Draggable = true
            ImageButton.Transparency = 0.2
            
            UICorner.CornerRadius = UDim.new(0,200)
            UICorner.Parent = ImageButton
            
            ImageButton.MouseButton1Click:Connect(function()
                game:GetService("VirtualInputManager"):SendKeyEvent(true,getgenv().ToggleUI,false,game)
            end)
        end
    end)
    
    if not success then
        warn("Lỗi khi tạo nút Mobile UI: " .. tostring(errorMsg))
    end
end)

-- Kiểm tra script đã tải thành công
local scriptSuccess, scriptError = pcall(function()
    Fluent:Notify({
        Title = "Script đã khởi động thành công",
        Content = "HT Hub | Arise Crossover đang hoạt động",
        Duration = 5
    })
end)

if not scriptSuccess then
    warn("Lỗi khi khởi động script: " .. tostring(scriptError))
    -- Thử cách khác để thông báo người dùng
    if game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(0.3, 0, 0.1, 0)
        textLabel.Position = UDim2.new(0.35, 0, 0.45, 0)
        textLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.Text = "HT Hub đã khởi động nhưng gặp lỗi. Hãy thử lại."
        textLabel.Parent = screenGui
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = textLabel
        
        game:GetService("Debris"):AddItem(screenGui, 5)
    end
end

-- Thêm event listener để lưu ngay khi thay đổi giá trị
local function setupSaveEvents()
    for _, tab in pairs(Tabs) do
        if tab and tab._components then -- Kiểm tra tab và tab._components có tồn tại không
        for _, element in pairs(tab._components) do
                if element and element.OnChanged then -- Kiểm tra element và element.OnChanged có tồn tại không
                element.OnChanged:Connect(function()
                    pcall(function()
                        SaveManager:Save("AutoSave_" .. playerName)
                    end)
                end)
                end
            end
        end
    end
end

-- Thực thi tự động lưu/tải cấu hình
AutoSaveConfig()
setupSaveEvents() -- Thêm dòng này

local BuyWeaponSection = Tabs.shop:AddSection("Buy Weapon")
-- Mapping giữa shops và weapons
local weaponsByShop = {
    ["WeaponShop1"] = {"SpikeMace", "GemStaff", "DualKando", "CrystalScepter", "DualBoneMace", "DualSteelNaginata"},
    ["WeaponShop2"] = {"MonsterSlayer", "DualBasicStaffs", "PirateSaber", "BronzeGreatAxe", "MixedBattleAxe", "DualAncientMace"},
    ["WeaponShop3"] = {"DualPirateSaber", "DualSteelSabers", "DualSteelButterfly", "SteelSaber", "SteelButterfly", "SteelKando"},
    ["WeaponShop4"] = {"SteelNaginata", "GreatKopesh", "BoneMace", "CrimsonStaff", "AncientMace", "GreatSaber"},
    ["WeaponShop5"] = {"DualGreatSaber", "BasicStaff", "StellKopesh", "GreatTrident", "DualCrystalScepter", "DualTrident"},
    ["WeaponShop6"] = {"OzSword2", "CrystalSword2", "ObsidianDualAxe2", "SilverSpear2", "DragonAxe2", "DualDivineAxe2"},
    ["WeaponShop7"] = {"BloodStaff2", "DualCrimsonStaff2", "DualGemStaffs2", "GreatScythe2", "TwinObsidianDualStaff2", "SlayerScythe2"},
    ["WeaponShop8"] = {"BeholderStaff2", "TwinMixedAxe2", "TwinTrollSlayer2", "RuneAxe2", "DualSilverSpear2", "DualDragonAxe2"},
    ["WeaponShop9"] = {"SteelSword2", "SteelSpear2", "StarSpear2", "BoneStaff2", "SunGreatAxe2", "EnergyGreatSword2"},
}

local selectedShop = "WeaponShop1" -- Shop mặc định
local selectedWeapon = "" -- Weapon mặc định
local autoBuyEnabled = false -- Trạng thái Auto Buy

-- Cập nhật ConfigSystem để lưu các biến mới
ConfigSystem.DefaultConfig.SelectedShop = selectedShop
ConfigSystem.DefaultConfig.SelectedWeapon = selectedWeapon
ConfigSystem.DefaultConfig.AutoBuyEnabled = autoBuyEnabled

-- Dropdown để chọn Shop
Tabs.shop:AddDropdown("ShopDropdown", {
    Title = "Select Shop",
    Values = {"WeaponShop1", "WeaponShop2", "WeaponShop3", "WeaponShop4", "WeaponShop5", "WeaponShop6", "WeaponShop7", "WeaponShop8", "WeaponShop9"},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.SelectedShop or selectedShop,
    Callback = function(shop)
        selectedShop = shop
        ConfigSystem.CurrentConfig.SelectedShop = shop
        
        -- Cập nhật danh sách weapon dựa trên shop được chọn
        local weaponDropdown = Fluent.Options.WeaponDropdown
        if weaponDropdown then
            weaponDropdown:SetValues(weaponsByShop[shop] or {})
            -- Đặt giá trị mặc định nếu có weapon
            if #weaponsByShop[shop] > 0 then
                selectedWeapon = weaponsByShop[shop][1]
                weaponDropdown:SetValue(selectedWeapon)
                ConfigSystem.CurrentConfig.SelectedWeapon = selectedWeapon
            else
                selectedWeapon = ""
            end
        end
        
        ConfigSystem.SaveConfig()
    end
})

-- Dropdown để chọn Weapon trong shop đã chọn
Tabs.shop:AddDropdown("WeaponDropdown", {
    Title = "Select Weapon",
    Values = weaponsByShop[selectedShop] or {},
    Multi = false,
    Default = ConfigSystem.CurrentConfig.SelectedWeapon or (weaponsByShop[selectedShop] and weaponsByShop[selectedShop][1] or ""),
    Callback = function(weapon)
        selectedWeapon = weapon
        ConfigSystem.CurrentConfig.SelectedWeapon = weapon
        ConfigSystem.SaveConfig()
        print("Selected Weapon:", selectedWeapon) -- Gỡ lỗi
    end
})
-- ⏳ Đồng bộ lại danh sách vũ khí sau khi GUI đã khởi tạo
task.defer(function()
    local currentShop = ConfigSystem.CurrentConfig.SelectedShop
    local currentWeapon = ConfigSystem.CurrentConfig.SelectedWeapon
    local weaponDropdown = Fluent.Options.WeaponDropdown

    if currentShop and weaponsByShop[currentShop] and weaponDropdown then
        weaponDropdown:SetValues(weaponsByShop[currentShop])
        if table.find(weaponsByShop[currentShop], currentWeapon) then
            weaponDropdown:SetValue(currentWeapon)
        else
            local defaultWeapon = weaponsByShop[currentShop][1]
            selectedWeapon = defaultWeapon
            weaponDropdown:SetValue(defaultWeapon)
            ConfigSystem.CurrentConfig.SelectedWeapon = defaultWeapon
            ConfigSystem.SaveConfig()
        end
    end
end)


-- Hàm để mua weapon
local function buyWeapon()
    if selectedShop and selectedWeapon and selectedWeapon ~= "" then
        local args = {
            [1] = {
                [1] = {
                    ["Action"] = "Buy",
                    ["Shop"] = selectedShop,
                    ["Item"] = selectedWeapon,
                    ["Event"] = "ItemShopAction"
                },
                [2] = "\n"
            }
        }
        
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
        print("Đã mua:", selectedWeapon, "từ cửa hàng:", selectedShop)
    else
        print("Vui lòng chọn shop và weapon!")
    end
end

-- Toggle để bật/tắt Auto Buy
Tabs.shop:AddToggle("AutoBuyToggle", {
    Title = "Auto Buy Weapon",
    Default = ConfigSystem.CurrentConfig.AutoBuyEnabled or false,
    Callback = function(state)
        autoBuyEnabled = state
        ConfigSystem.CurrentConfig.AutoBuyEnabled = state
        ConfigSystem.SaveConfig()
        
        if state then
            task.spawn(function()
                while autoBuyEnabled do
                    buyWeapon()
                    task.wait(1) -- Chờ 1 giây giữa mỗi lần mua
                end
            end)
        end
    end
})
local UpdateWeaponSection = Tabs.shop:AddSection("Update Weapon")
-- Thêm code cho tab Update sau phần mã của tab Buy
-- Hàm để lấy danh sách tên vũ khí duy nhất từ inventory
local function getUniqueWeaponNames()
    local weapons = {}
    local seenNames = {} -- Để theo dõi tên duy nhất

    local playerWeapons = game:GetService("Players").LocalPlayer.leaderstats.Inventory.Weapons:GetChildren()
    print("Đang lấy danh sách vũ khí...") -- GỠ LỖI

    for _, weapon in ipairs(playerWeapons) do
        local weaponName = weapon:GetAttribute("Name") -- Lấy thuộc tính "Name"
        if weaponName then
            print("Đã tìm thấy vũ khí:", weaponName) -- GỠ LỖI
            if not seenNames[weaponName] then
                table.insert(weapons, weaponName)
                seenNames[weaponName] = true -- Đánh dấu tên đã thấy
            end
        end
    end
    return weapons
end

-- Hàm để lấy danh sách ID của tất cả vũ khí cùng loại
local function getWeaponIDs(weaponType)
    local weaponIDs = {}
    
    local playerWeapons = game:GetService("Players").LocalPlayer.leaderstats.Inventory.Weapons:GetChildren()
    for _, weapon in ipairs(playerWeapons) do
        local weaponName = weapon:GetAttribute("Name")
        -- Kiểm tra xem vũ khí có phải là loại đang tìm kiếm không
        if weaponName == weaponType then
            table.insert(weaponIDs, weapon.Name) -- Thêm ID của vũ khí vào danh sách
            print("Đã tìm thấy ID vũ khí:", weapon.Name) -- GỠ LỖI
        end
    end
    
    return weaponIDs
end

-- Lấy danh sách tên vũ khí ban đầu
local weaponTypes = getUniqueWeaponNames()
local selectedWeaponType = weaponTypes[1] or "" -- Loại vũ khí mặc định
local autoUpdateEnabled = false -- Trạng thái Auto Update
local autoSelectedEnabled = false -- Trạng thái Auto Update cho vũ khí đã chọn

-- Cập nhật ConfigSystem
ConfigSystem.DefaultConfig.SelectedWeaponType = selectedWeaponType
ConfigSystem.DefaultConfig.AutoUpdateEnabled = autoUpdateEnabled
ConfigSystem.DefaultConfig.AutoSelectedEnabled = autoSelectedEnabled

-- Dropdown để chọn loại vũ khí muốn nâng cấp
Tabs.shop:AddDropdown("WeaponTypeDropdown", {
    Title = "Select Weapon",
    Values = weaponTypes,
    Multi = false,
    Default = ConfigSystem.CurrentConfig.SelectedWeaponType or selectedWeaponType,
    Callback = function(weaponType)
        selectedWeaponType = weaponType
        ConfigSystem.CurrentConfig.SelectedWeaponType = weaponType
        ConfigSystem.SaveConfig()
        print("Selected Weapon Type:", selectedWeaponType) -- GỠ LỖI
    end
})

-- Hàm để lấy tất cả vũ khí theo level
local function getWeaponsByLevel(weaponType)
    local weaponsByLevel = {}
    
    -- Khởi tạo mảng để lưu trữ vũ khí theo level
    for i = 1, 7 do
        weaponsByLevel[i] = {}
    end
    
    local playerWeapons = game:GetService("Players").LocalPlayer.leaderstats.Inventory.Weapons:GetChildren()
    for _, weapon in ipairs(playerWeapons) do
        local weaponName = weapon:GetAttribute("Name")
        local weaponLevel = weapon:GetAttribute("Level") or 1
        
        -- Nếu không chọn loại vũ khí cụ thể hoặc vũ khí thuộc loại đã chọn
        if (not weaponType or weaponType == "" or weaponName == weaponType) and weaponLevel >= 1 and weaponLevel <= 7 then
            table.insert(weaponsByLevel[weaponLevel], weapon.Name)
            print("Đã tìm thấy vũ khí:", weaponName, "Level:", weaponLevel, "ID:", weapon.Name)
        end
    end
    
    return weaponsByLevel
end

-- Hàm để nâng cấp vũ khí theo level
local function upgradeWeaponsByLevel(weaponType)
    local weaponsByLevel = getWeaponsByLevel(weaponType)
    local anyUpgraded = false
    
    -- Duyệt qua từng level, bắt đầu từ level thấp nhất
    for level = 1, 6 do
        local weapons = weaponsByLevel[level]
        
        -- Nếu có ít nhất 3 vũ khí cùng level, thực hiện nâng cấp
        while #weapons >= 3 do
            -- Lấy 3 vũ khí đầu tiên để nâng cấp
            local upgradeWeapons = {
                weapons[1],
                weapons[2],
                weapons[3]
            }
            
            -- Xóa 3 vũ khí này khỏi danh sách
            table.remove(weapons, 1)
            table.remove(weapons, 1)
            table.remove(weapons, 1)
            
            -- Thực hiện nâng cấp
            local weaponName = game:GetService("Players").LocalPlayer.leaderstats.Inventory.Weapons:FindFirstChild(upgradeWeapons[1]):GetAttribute("Name")
            
            local args = {
                [1] = {
                    [1] = {
                        ["Type"] = weaponName,
                        ["BuyType"] = "Gems",
                        ["Weapons"] = upgradeWeapons,
                        ["Event"] = "UpgradeWeapon",
                        ["Level"] = level + 1
                    },
                    [2] = "\n"
                }
            }
            
            game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
            print("Đang nâng cấp", #upgradeWeapons, "vũ khí", weaponName, "từ level", level, "lên level", level + 1)
            
            Fluent:Notify({
                Title = "Đang nâng cấp",
                Content = "Đang nâng cấp " .. weaponName .. " từ level " .. level .. " lên level " .. (level + 1),
                Duration = 3
            })
            
            anyUpgraded = true
            task.wait(1) -- Đợi 1 giây để tránh spam server
        end
    end
    
    if not anyUpgraded then
        Fluent:Notify({
            Title = "Thông báo",
            Content = "Không có vũ khí nào đủ số lượng để nâng cấp",
            Duration = 3
        })
    end
    
    return anyUpgraded
end

-- Nút để làm mới danh sách vũ khí
Tabs.shop:AddButton({
    Title = "Refresh Weapon List",
    Description = "Refresh the list of available weapons",
    Callback = function()
        weaponTypes = getUniqueWeaponNames()
        local weaponTypeDropdown = Fluent.Options.WeaponTypeDropdown
        if weaponTypeDropdown then
            weaponTypeDropdown:SetValues(weaponTypes)
            if #weaponTypes > 0 and not table.find(weaponTypes, selectedWeaponType) then
                selectedWeaponType = weaponTypes[1]
                weaponTypeDropdown:SetValue(selectedWeaponType)
                ConfigSystem.CurrentConfig.SelectedWeaponType = selectedWeaponType
                ConfigSystem.SaveConfig()
            end
        end
        
        Fluent:Notify({
            Title = "Danh sách đã làm mới",
            Content = "Đã cập nhật danh sách vũ khí có sẵn",
            Duration = 3
        })
    end
})

-- Toggle để bật/tắt nâng cấp vũ khí đã chọn
Tabs.shop:AddToggle("AutoSelectToggle", {
    Title = "Upgrade Selected Weapon",
    Default = ConfigSystem.CurrentConfig.AutoSelectedEnabled or false,
    Callback = function(state)
        autoSelectedEnabled = state
        ConfigSystem.CurrentConfig.AutoSelectedEnabled = state
        ConfigSystem.SaveConfig()
        
        if state then
            if not selectedWeaponType or selectedWeaponType == "" then
                Fluent:Notify({
                    Title = "Lỗi",
                    Content = "Vui lòng chọn loại vũ khí trước khi nâng cấp",
                    Duration = 3
                })
                return
            end
            
            task.spawn(function()
                while autoSelectedEnabled do
                    local upgraded = upgradeWeaponsByLevel(selectedWeaponType)
                    if not upgraded then
                        task.wait(5) -- Đợi lâu hơn nếu không có vũ khí nào được nâng cấp
                    else
                        task.wait(1) -- Đợi ngắn hơn nếu có vũ khí được nâng cấp
                    end
                end
            end)
        end
    end
})

-- Thêm section sell pet vào tab shop
local SellPetSection = Tabs.shop:AddSection("Sell Pet")
-- Ánh xạ các rank số sang chữ cái
local rankMapping = {
    [1] = "E",
    [2] = "D",
    [3] = "C",
    [4] = "B",
    [5] = "A",
    [6] = "S",
    [7] = "SS",
    [8] = "G",
    [9] = "N"
}

-- Tạo mảng giá trị để hiển thị trong dropdown
local rankValues = {}
for i = 1, 9 do
    table.insert(rankValues, rankMapping[i] .. " (Rank " .. i .. ")")
end

-- Biến để lưu trạng thái
local selectedRanks = {}
local autoSellEnabled = false

-- Cập nhật ConfigSystem để lưu các biến mới
ConfigSystem.DefaultConfig.SelectedRanks = {}
ConfigSystem.DefaultConfig.AutoSellEnabled = false

-- Dropdown để chọn Rank
Tabs.shop:AddDropdown("RankDropdown", {
    Title = "Choose Ranks",
    Values = rankValues,
    Multi = true,
    Default = ConfigSystem.CurrentConfig.SelectedRanks or {},
    Callback = function(selections)
        selectedRanks = {}
        -- Kiểm tra xem selections có phải là table hay không
        if type(selections) == "table" then
            for selection, isSelected in pairs(selections) do
                -- Chỉ xử lý các mục đã chọn (boolean = true)
                if isSelected == true then
                    -- Trích xuất số rank từ chuỗi (vd: từ "E (Rank 1)" lấy ra 1)
                    local rankStr = selection:match("Rank (%d+)")
                    if rankStr then
                        local rank = tonumber(rankStr)
                        if rank then
                            table.insert(selectedRanks, rank)
                        end
                    end
                end
            end
        end
        ConfigSystem.CurrentConfig.SelectedRanks = selections
        ConfigSystem.SaveConfig()
        print("Selected Ranks:", table.concat(selectedRanks, ", "))
    end
})

-- Hàm để bán pet theo rank
local function sellPetsByRank()
    local petFolder = player.leaderstats.Inventory:WaitForChild("Pets")
    local petsToSell = {}
    
    for _, pet in ipairs(petFolder:GetChildren()) do
        local rankVal = pet:GetAttribute("Rank")
        if typeof(rankVal) == "number" and table.find(selectedRanks, rankVal) then
            table.insert(petsToSell, pet.Name)
            
            -- Nếu đạt đủ 20 pet hoặc đây là pet cuối cùng, tiến hành bán
            if #petsToSell >= 20 then
                local args = {
                    [1] = {
                        [1] = {
                            ["Event"] = "SellPet",
                            ["Pets"] = petsToSell
                        },
                        [2] = "\t"
                    }
                }
                remote:FireServer(unpack(args))
                print("Đã bán", #petsToSell, "pet với rank đã chọn")
                
                -- Đợi một khoảng thời gian ngắn để tránh spam
                task.wait(0.3)
                
                -- Đặt lại danh sách
                petsToSell = {}
            end
        end
    end
    
    -- Bán nốt những pet còn lại (nếu có)
    if #petsToSell > 0 then
        local args = {
            [1] = {
                [1] = {
                    ["Event"] = "SellPet",
                    ["Pets"] = petsToSell
                },
                [2] = "\t"
            }
        }
        remote:FireServer(unpack(args))
        print("Đã bán", #petsToSell, "pet còn lại với rank đã chọn")
    end
end

-- Nút để bán ngay
Tabs.shop:AddButton({
    Title = "Sell Now",
    Description = "Sell all pets with selected ranks immediately",
    Callback = function()
        if #selectedRanks > 0 then
            sellPetsByRank()
        else
            Fluent:Notify({
                Title = "Chưa chọn rank",
                Content = "Vui lòng chọn ít nhất một rank để bán pet",
                Duration = 3
            })
        end
    end
})

-- Toggle để bật/tắt Auto Sell
Tabs.shop:AddToggle("AutoSellToggle", {
    Title = "Auto Sell Pets",
    Default = ConfigSystem.CurrentConfig.AutoSellEnabled or false,
    Callback = function(state)
        autoSellEnabled = state
        ConfigSystem.CurrentConfig.AutoSellEnabled = state
        ConfigSystem.SaveConfig()
        
        if state then
            if #selectedRanks > 0 then
                Fluent:Notify({
                    Title = "Auto Sell đã bật",
                    Content = "Sẽ tự động bán pet với các rank: " .. table.concat(selectedRanks, ", "),
                    Duration = 3
                })
                
                task.spawn(function()
                    while autoSellEnabled do
                        sellPetsByRank()
                        task.wait(5) -- Đợi 5 giây giữa mỗi lần kiểm tra và bán
                    end
                end)
            else
                Fluent:Notify({
                    Title = "Chưa chọn rank",
                    Content = "Vui lòng chọn ít nhất một rank để bán pet",
                    Duration = 3
                })
            end
        end
    end
})

-- Khôi phục lại tab Auto farm Dungeon
Tabs.dungeon:AddToggle("TeleportMobs", {
    Title = "Auto farm Dungeon",
    Default = false,
    Flag = "AutoFarmDungeon",
    Callback = function(state)
        teleportEnabled = state
        if state then
            task.spawn(function()
                local tweenService = game:GetService("TweenService")
                local player = game.Players.LocalPlayer
                local enemiesFolder = workspace.__Main.__Enemies.Server
                local isTweenActive = true

                local function getDistance(pos1, pos2)
                    return (pos1 - pos2).Magnitude
                end

                local function getClosestEnemy()
                    local closestEnemy = nil
                    local closestDistance = math.huge
                    local playerCharacter = player.Character

                    if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then return nil end
                    local playerPosition = playerCharacter.HumanoidRootPart.Position

                    for _, enemy in pairs(enemiesFolder:GetChildren()) do
                        local hp = enemy:GetAttribute("HP")
                        if hp and hp > 0 then
                            local enemyPosition = enemy.Position
                            if enemyPosition then
                                local distance = getDistance(playerPosition, enemyPosition)
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestEnemy = enemy
                                end
                            end
                        end
                    end

                    return closestEnemy
                end

                local function moveToEnemy(enemy)
                    local playerCharacter = player.Character
                    if playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart") and enemy.Position then
                        playerCharacter.PrimaryPart = playerCharacter.HumanoidRootPart
                        playerCharacter.HumanoidRootPart.Anchored = false

                        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear)
                        local tween = tweenService:Create(playerCharacter.PrimaryPart, tweenInfo, {CFrame = enemy.CFrame})
                        tween:Play()
                        tween.Completed:Wait()
                    end
                end

                local function monitorEnemies()
                    while teleportEnabled do
                        local closestEnemy = getClosestEnemy()
                        if closestEnemy then
                            moveToEnemy(closestEnemy)
                            while closestEnemy:GetAttribute("HP") and closestEnemy:GetAttribute("HP") > 0 do
                                task.wait(0.5)
                            end
                        else
                            break
                        end
                        task.wait(0.1)
                    end
                end

                monitorEnemies()
            end)
        end
    end
})
