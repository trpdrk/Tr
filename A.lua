-- ==============================================================================
-- DELTA HUB - MM2 | Aimbot Sheriff ล็อกฆาตกรอัตโนมัติ 120ม. | มือถือ
-- ==============================================================================

pcall(function()
    for _,v in pairs(getconnections(game.RunService.Heartbeat)) do v:Disable() end
    for _,v in pairs(getconnections(game.RunService.RenderStepped)) do v:Disable() end
end)

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

for _, name in ipairs({"MM2Hub_New", "MM2_FloatingIcon"}) do
    local old = CoreGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local Running = true
local MenuVisible = true
local Connections = {}
local Settings = {
    Noclip = false,
    AutoCoin = false,
    WalkSpeed = false,
    AuraKnife = false,
    Aimbot = false,
    FlingMurderer = false,
    SpeedValue = 27,
    CoinSpeed = 20,
    FlingSpeed = 28,
    AuraRange = 200,
    AuraDelay = 0.3,
    AimbotRange = 120 -- ✅ ระยะล็อกเป้า 120 เมตร
}

local RoleCache = {}
local ESP_Draws = {}
local IsFlying = false
local MurdererFound = false
local LastMurderer = nil
local LastAuraTime = 0
local FlingStarted = false

-- =======================================
-- 🟢 ไอคอนลอย
-- =======================================
local IconGui = Instance.new("ScreenGui")
IconGui.Name = "MM2_FloatingIcon"
IconGui.Parent = CoreGui
IconGui.ResetOnSpawn = false

local FloatingIcon = Instance.new("TextButton")
FloatingIcon.Size = UDim2.new(0, 55, 0, 55)
FloatingIcon.Position = UDim2.new(0.01, 0, 0.5, -27)
FloatingIcon.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
FloatingIcon.Text = "🔪"
FloatingIcon.TextSize = 26
FloatingIcon.Active = true
FloatingIcon.Draggable = true
FloatingIcon.Parent = IconGui
Instance.new("UICorner", FloatingIcon).CornerRadius = UDim.new(1, 0)

-- ======================================
-- 🟢 เมนูหลัก
-- ======================================
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "MM2Hub_New"
MainGui.Parent = CoreGui
MainGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 520)
MainFrame.Position = UDim2.new(0.05, 0, 0.03, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = MainGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🔪 MM2 HUB"
TitleText.TextColor3 = Color3.fromRGB(255, 85, 85)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 40, 0, 40)
HideButton.Position = UDim2.new(1, -85, 0, 5)
HideButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
HideButton.Text = "−"
HideButton.TextColor3 = Color3.new(1,1,1)
HideButton.TextSize = 24
HideButton.Font = Enum.Font.GothamBold
HideButton.Parent = TitleBar
Instance.new("UICorner", HideButton).CornerRadius = UDim.new(0, 8)

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -45, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseButton.Text = "✕"
CloseButton.Rotation = 45
CloseButton.TextColor3 = Color3.new(1,1,1)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TitleBar
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 8)

local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -24, 0, 32)
StatusBox.Position = UDim2.new(0, 12, 0, 60)
StatusBox.BackgroundColor3 = Color3.fromRGB(38, 38, 58)
StatusBox.Parent = MainFrame
Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 8)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 1, 0)
StatusText.Position = UDim2.new(0, 5, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "✅ พร้อมใช้งาน"
StatusText.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 12
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusBox

local function MakeToggle(name, y)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -24, 0, 48)
    Btn.Position = UDim2.new(0, 12, 0, y)
    Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    Btn.Text = name .. " | ปิด"
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 14
    Btn.AutoButtonColor = false
    Btn.Parent = MainFrame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    Btn.MouseButton1Click:Connect(function()
        Settings[name] = not Settings[name]
        if Settings[name] then
            Btn.Text = name .. " | ✅ เปิด"
            Btn.BackgroundColor3 = Color3.fromRGB(30, 85, 55)
        else
            Btn.Text = name .. " | ปิด"
            Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        end
    end)
    return Btn
end

MakeToggle("Noclip", 102)
MakeToggle("WalkSpeed", 160)
MakeToggle("AutoCoin", 218)
MakeToggle("AuraKnife", 276)
MakeToggle("Aimbot", 334)
MakeToggle("FlingMurderer", 392)

-- ======================================
-- 🟢 ฟังก์ชันเปิด/ปิดเมนู
-- ======================================
local function ToggleMenu()
    MenuVisible = not MenuVisible
    MainFrame.Visible = MenuVisible
    FloatingIcon.Text = MenuVisible and "✕" or "🔪"
end

local function ShutdownAll()
    Running = false
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    for _, data in pairs(ESP_Draws) do pcall(function() data.Box:Remove() data.Text:Remove() end) end
    ESP_Draws = {}
    pcall(function() MainGui:Destroy() end)
    pcall(function() IconGui:Destroy() end)
    table.clear(Settings)
    table.clear(RoleCache)
    print("❌ ปิดระบบทั้งหมดเรียบร้อย")
end

FloatingIcon.MouseButton1Click:Connect(ToggleMenu)
HideButton.MouseButton1Click:Connect(ToggleMenu)
CloseButton.MouseButton1Click:Connect(ShutdownAll)

-- ======================================
-- 🟢 ฟังก์ชันช่วยเหลือ
-- ======================================
local function IsMurderer()
    local Char = LocalPlayer.Character
    if not Char then return false end
    local RoleObj = Char:FindFirstChild("Role")
    if RoleObj and RoleObj:IsA("StringValue") then
        return RoleObj.Value == "Murderer"
    end
    return false
end

local function IsSheriff()
    local Char = LocalPlayer.Character
    if not Char then return false end
    local RoleObj = Char:FindFirstChild("Role")
    if RoleObj and RoleObj:IsA("StringValue") then
        return RoleObj.Value == "Sheriff"
    end
    return false
end

local function GetKnife()
    local Char = LocalPlayer.Character
    if not Char then return nil end
    for _, tool in ipairs(Char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = string.lower(tool.Name)
            if string.find(name, "knife") or string.find(name, "blade") then
                return tool
            end
        end
    end
    return nil
end

local function SwingKnife()
    local knife = GetKnife()
    if knife then pcall(function() knife:Activate() end) end
end

-- ======================================
-- 🟢 อัปเดตบทบาท
-- ======================================
local function UpdateAllRoles()
    if not Running then return end
    MurdererFound = false
    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr ~= LocalPlayer and Plr.Character then
            local RoleObj = Plr.Character:FindFirstChild("Role")
            if RoleObj and RoleObj:IsA("StringValue") then
                RoleCache[Plr] = RoleObj.Value
                if RoleObj.Value == "Murderer" then
                    MurdererFound = true
                    LastMurderer = Plr
                end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(p)
    RoleCache[p] = nil
    if ESP_Draws[p] then
        pcall(function() ESP_Draws[p].Box:Remove() ESP_Draws[p].Text:Remove() end)
        ESP_Draws[p] = nil
    end
    if LastMurderer == p then LastMurderer = nil end
end)

-- ======================================
-- ⚔️ AURA KILL 200m (Murderer)
-- ======================================
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not Running or not Settings.AuraKnife then return end
    if not IsMurderer() then return end
    local MyChar = LocalPlayer.Character
    if not MyChar then return end
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
    local MyHum = MyChar:FindFirstChild("Humanoid")
    if not MyRoot or not MyHum or MyHum.Health <= 0 then return end
    if not GetKnife() then return end
    
    local Now = os.clock()
    if Now - LastAuraTime < Settings.AuraDelay then return end
    
    local Targets = {}
    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr ~= LocalPlayer and Plr.Character then
            local Role = RoleCache[Plr] or "Innocent"
            if Role ~= "Murderer" then
                local TRoot = Plr.Character:FindFirstChild("HumanoidRootPart")
                local THum = Plr.Character:FindFirstChild("Humanoid")
                if TRoot and THum and THum.Health > 0 then
                    local Dist = (MyRoot.Position - TRoot.Position).Magnitude
                    if Dist <= Settings.AuraRange then
                        table.insert(Targets, {Player = Plr, Dist = Dist, Position = TRoot.Position})
                    end
                end
            end
        end
    end
    
    if #Targets > 0 then
        table.sort(Targets, function(a,b) return a.Dist < b.Dist end)
        local Target = Targets[1]
        local lookAt = Vector3.new(Target.Position.X, MyRoot.Position.Y, Target.Position.Z)
        MyRoot.CFrame = CFrame.new(MyRoot.Position, lookAt)
        SwingKnife()
        LastAuraTime = Now
        StatusText.Text = "⚔️ โจมตี: " .. Target.Player.Name .. " | " .. math.floor(Target.Dist) .. "ม"
    end
end))

-- ======================================
-- 🎯 AIMBOT SHERIFF - ล็อกฆาตกรอัตโนมัติ 120ม.
-- ✅ เปิดฟังก์ชันก็ล็อกทันที ไม่ต้องกดค้าง
-- ✅ ทำงานเฉพาะตอนเป็น Sheriff
-- ✅ ล็อกเป้าเฉพาะฆาตกร
-- ======================================
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not Running or not Settings.Aimbot then return end
    
    -- เช็คเงื่อนไข: ต้องเป็น Sheriff เท่านั้น
    if not IsSheriff() then
        StatusText.Text = "🎯 Aimbot: ต้องเป็น Sheriff เท่านั้น"
        return
    end
    
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return end
    
    -- หาฆาตกรในระยะ 120 เมตร
    local MurdererTarget = nil
    local MurdererDist = math.huge
    
    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr ~= LocalPlayer and RoleCache[Plr] == "Murderer" and Plr.Character then
            local TRoot = Plr.Character:FindFirstChild("HumanoidRootPart")
            local THead = Plr.Character:FindFirstChild("Head")
            local THum = Plr.Character:FindFirstChild("Humanoid")
            if TRoot and THead and THum and THum.Health > 0 then
                local Dist = (MyRoot.Position - TRoot.Position).Magnitude
                if Dist <= Settings.AimbotRange and Dist < MurdererDist then
                    MurdererDist = Dist
                    MurdererTarget = {Player = Plr, Head = THead, Root = TRoot}
                end
            end
        end
    end
    
    -- ถ้าเจอฆาตกร → ล็อกกล้องที่หัวทันที
    if MurdererTarget then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, MurdererTarget.Head.Position)
        StatusText.Text = "🎯 ล็อกฆาตกร: " .. MurdererTarget.Player.Name .. " | " .. math.floor(MurdererDist) .. "ม"
    else
        StatusText.Text = "🎯 ไม่มีฆาตกรในระยะ " .. Settings.AimbotRange .. "ม"
    end
end))

-- ======================================
-- 🚀 FLING MURDERER
-- ======================================
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not Running then return end
    UpdateAllRoles()

    local Values = Workspace:FindFirstChild("Values")
    local GameState = Values and Values:FindFirstChild("GameState")
    local State = GameState and GameState.Value or ""

    if State ~= "Preparing" then
        FlingStarted = false
    end

    if State == "Intermission" then
        StatusText.Text = "⏳ รอเริ่มรอบ"
    elseif State == "Preparing" then
        if MurdererFound then
            StatusText.Text = Settings.FlingMurderer and "🚀 วิ่งไปหาฆาตกร..." or "✅ เจอฆาตกร! (เปิด FlingMurderer)"
        else
            StatusText.Text = "⏳ กำลังสุ่มบทบาท..."
        end
    elseif State == "Playing" then
        if not Settings.AuraKnife or not IsMurderer() then
            StatusText.Text = "🎮 เกมเริ่มแล้ว"
        end
    end

    if Settings.FlingMurderer and MurdererFound and State == "Preparing" and LastMurderer and LastMurderer.Character then
        local MyChar = LocalPlayer.Character
        if not MyChar then return end
        local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
        local MyHum = MyChar:FindFirstChild("Humanoid")
        if not MyRoot or not MyHum or MyHum.Health <= 0 then return end
        
        local TargetRoot = LastMurderer.Character:FindFirstChild("HumanoidRootPart")
        if not TargetRoot then return end
        
        local Direction = (TargetRoot.Position - MyRoot.Position)
        local Distance = Direction.Magnitude
        local UnitDir = Direction.Unit
        
        if Distance > 3 then
            if not FlingStarted then FlingStarted = true end
            local lookAt = Vector3.new(TargetRoot.Position.X, MyRoot.Position.Y, TargetRoot.Position.Z)
            MyRoot.CFrame = CFrame.new(MyRoot.Position, lookAt)
            MyRoot.Velocity = UnitDir * Settings.FlingSpeed + Vector3.new(0, 3, 0)
            for _, Part in ipairs(MyChar:GetDescendants()) do
                if Part:IsA("BasePart") then Part.CanCollide = false end
            end
            StatusText.Text = "🚀 ไปหาฆาตกร: " .. math.floor(Distance) .. "ม"
        else
            MyRoot.Velocity = Vector3.new(0, 12, 0)
            FlingStarted = false
            StatusText.Text = "✅ ถึงฆาตกรแล้ว!"
        end
    end
end))

-- ======================================
-- 🟢 Noclip + เดินเร็ว
-- ======================================
table.insert(Connections, RunService.Stepped:Connect(function()
    if not Running then return end
    local Char = LocalPlayer.Character
    if not Char then return end
    local Hum = Char:FindFirstChild("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Hum or not Root or Hum.Health <= 0 then return end

    if Settings.Noclip then
        for _, Part in ipairs(Char:GetDescendants()) do
            if Part:IsA("BasePart") then Part.CanCollide = false end
        end
    end
    if Settings.WalkSpeed then
        Hum.WalkSpeed = Settings.SpeedValue
    end
end))

-- ======================================
-- 🟢 เก็บเหรียญ
-- ======================================
local CoinsSeen = {}
LocalPlayer.CharacterAdded:Connect(function() CoinsSeen = {} end)

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not Running or not Settings.AutoCoin or IsFlying then return end
    local Char = LocalPlayer.Character
    if not Char then return end
    local Root = Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char:FindFirstChild("Humanoid")
    if not Root or not Hum or Hum.Health <= 0 then return end

    local Nearest, MinDist = nil, 1/0
    for _, Obj in ipairs(Workspace:GetDescendants()) do
        if Obj.Name == "Coin" and Obj:IsA("BasePart") and not CoinsSeen[Obj] then
            local d = (Root.Position - Obj.Position).Magnitude
            if d < MinDist then MinDist = d; Nearest = Obj end
        end
    end
    if not Nearest then return end
    IsFlying = true

    local Updater
    Updater = RunService.RenderStepped:Connect(function()
        if not Running or not Settings.AutoCoin or not Nearest or not Nearest.Parent then
            Updater:Disconnect(); IsFlying = false; return
        end
        local Dir = (Nearest.Position - Root.Position)
        if Dir.Magnitude < 2.5 then
            CoinsSeen[Nearest] = true
            Updater:Disconnect(); IsFlying = false
        else
            Root.Velocity = Dir.Unit * Settings.CoinSpeed
        end
    end)
end))

-- ======================================
-- 🟢 ESP ผู้เล่น
-- ======================================
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not Running then return end
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")

    if LastMurderer and LastMurderer.Character and MyRoot then
        local MR = LastMurderer.Character:FindFirstChild("HumanoidRootPart")
        if MR then
            local Dist = math.floor((MyRoot.Position - MR.Position).Magnitude + 0.5)
            local cur = StatusText.Text
            if not string.find(cur, "ฆาตกร") and not string.find(cur, "โจมตี") 
               and not string.find(cur, "ล็อก") and not string.find(cur, "ไปหา")
               and not string.find(cur, "เป้าหมาย") and not string.find(cur, "ถึง")
               and not string.find(cur, "Sheriff") and not string.find(cur, "ไม่มี") then
                StatusText.Text = cur .. " | ฆาตกร " .. Dist .. "ม"
            end
        end
    end

    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr == LocalPlayer then continue end
        local Char = Plr.Character
        if not Char then
            if ESP_Draws[Plr] then ESP_Draws[Plr].Box.Visible = false; ESP_Draws[Plr].Text.Visible = false end
            continue
        end
        local Root = Char:FindFirstChild("HumanoidRootPart")
        local Head = Char:FindFirstChild("Head")
        local Hum = Char:FindFirstChild("Humanoid")
        if not Root or not Head or not Hum or Hum.Health <= 0 then
            if ESP_Draws[Plr] then ESP_Draws[Plr].Box.Visible = false; ESP_Draws[Plr].Text.Visible = false end
            continue
        end

        local Role = RoleCache[Plr] or "Innocent"
        local ShowESP = false
        local Color = Color3.fromRGB(90, 160, 90)
        if Role == "Murderer" then ShowESP = true; Color = Color3.fromRGB(255, 70, 70)
        elseif Role == "Sheriff" then ShowESP = true; Color = Color3.fromRGB(70, 140, 255) end

        if ShowESP then
            local HPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
            local FPos = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 1, 0))
            if OnScreen then
                if not ESP_Draws[Plr] then
                    ESP_Draws[Plr] = {Box = Drawing.new("Square"), Text = Drawing.new("Text")}
                    ESP_Draws[Plr].Box.Thickness = 2
                    ESP_Draws[Plr].Box.Filled = false
                    ESP_Draws[Plr].Text.Size = 13
                    ESP_Draws[Plr].Text.Center = true
                end
                local Box = ESP_Draws[Plr].Box
                local Text = ESP_Draws[Plr].Text
                local H = math.abs(HPos.Y - FPos.Y) * 1.8
                local W = H * 0.55
                Box.Color = Color
                                Box.Position = Vector2.new(HPos.X - W/2, HPos.Y - H/2)
                Box.Size = Vector2.new(W, H)
                Box.Visible = true
                local DistText = MyRoot and (" [" .. math.floor((MyRoot.Position - Root.Position).Magnitude + 0.5) .. "ม]") or ""
                Text.Text = Plr.Name .. " - " .. Role .. DistText
                Text.Color = Color
                Text.Position = Vector2.new(HPos.X, HPos.Y - H - 18)
                Text.Visible = true
            elseif ESP_Draws[Plr] then
                ESP_Draws[Plr].Box.Visible = false
                ESP_Draws[Plr].Text.Visible = false
            end
        elseif ESP_Draws[Plr] then
            ESP_Draws[Plr].Box.Visible = false
            ESP_Draws[Plr].Text.Visible = false
        end
    end
end))

print("✅ โหลดสำเร็จ! สำหรับมือถือแอนดรอยด์")
print("   🎯 Aimbot Sheriff: เปิดแล้วล็อกฆาตกรอัตโนมัติ 120ม. ไม่ต้องกดค้าง")
print("   ⚔️ Aura Kill: 200 ม. (เฉพาะฆาตกร)")
print("   🚀 FlingMurderer: วิ่งหาฆาตกรช่วงนับถอยหลัง")
