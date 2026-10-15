-- ==============================================================================
-- DELTA HUB - MM2 | ลบ ESP ปืนออกแล้ว + เมนูลากได้
-- ==============================================================================

if not Drawing or not getgenv then
    print("❌ Executor ไม่รองรับ")
    return
end

if getgenv().MM2_Loaded then
    for _, v in pairs(getconnections(game:GetService("RunService").Heartbeat)) do v:Disable() end
    for _, v in pairs(getconnections(game:GetService("RunService").RenderStepped)) do v:Disable()
end
getgenv().MM2_Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    Noclip = false, AutoCoin = false, WalkSpeed = false,
    AuraKnife = false, Aimbot = false, FlingMurderer = false,
    SpeedValue = 27, CoinSpeed = 20, FlingSpeed = 20,
    AuraRange = 200, AimbotRange = 120, AimbotSmooth = 0.35
}

local RoleCache = {}
local ESPCache = {}
local IsFlying = false
local RoleAssigned = false
local GameStarted = false

-- สร้าง UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2Hub"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 380)
MainFrame.Position = UDim2.new(0.02, 0, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
Title.Text = "  🔪 DELTA HUB - MM2"
Title.TextColor3 = Color3.fromRGB(255, 90, 90)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 24)
StatusLabel.Position = UDim2.new(0, 10, 0, 48)
StatusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
StatusLabel.Text = "สถานะ: รอสุ่มบทบาท..."
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.Parent = MainFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 6)

local function CreateButton(name, posY, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 42)
    Btn.Position = UDim2.new(0, 10, 0, posY)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    Btn.Text = name .. ": ปิด ❌"
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 13
    Btn.AutoButtonColor = false
    Btn.Parent = MainFrame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    Btn.MouseButton1Click:Connect(function()
        local newState = not Settings[name]
        Settings[name] = newState
        Btn.Text = name .. ": " .. (newState and "เปิด ✅" or "ปิด ❌")
        Btn.BackgroundColor3 = newState and Color3.fromRGB(30, 90, 60) or Color3.fromRGB(40, 40, 60)
        callback(newState)
    end)
    return Btn
end

-- ปุ่มต่างๆ
CreateButton("Noclip", 80, function(s) Settings.Noclip = s end)
CreateButton("WalkSpeed", 132, function(s) Settings.WalkSpeed = s end)
CreateButton("AutoCoin", 184, function(s) Settings.AutoCoin = s end)
CreateButton("AuraKnife", 236, function(s) Settings.AuraKnife = s end)
CreateButton("Aimbot", 288, function(s) Settings.Aimbot = s end)
CreateButton("FlingMurderer", 340, function(s) Settings.FlingMurderer = s end)

-- ตรวจสอบบทบาท
local function RefreshRoles()
    RoleAssigned = false
    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr ~= LocalPlayer and Plr.Character then
            local RoleVal = Plr.Character:FindFirstChild("Role")
            if RoleVal and RoleVal:IsA("StringValue") then
                if not RoleCache[Plr] or RoleCache[Plr] == "" then
                    RoleAssigned = true
                end
                RoleCache[Plr] = RoleVal.Value
            end
        end
    end
end

local function RemoveESP(player)
    if ESPCache[player] then
        if ESPCache[player].Box then ESPCache[player].Box:Remove() end
        if ESPCache[player].NameText then ESPCache[player].NameText:Remove() end
        ESPCache[player] = nil
    end
    RoleCache[player] = nil
end

Players.PlayerRemoving:Connect(RemoveESP)

-- ระบบทะลุ
RunService.Stepped:Connect(function()
    local Char = LocalPlayer.Character
    if not Char then return end
    local Hum = Char:FindFirstChild("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Hum or Hum.Health <= 0 or not Root then return end

    if Settings.Noclip then
        for _, Part in ipairs(Char:GetDescendants()) do
            if Part:IsA("BasePart") then Part.CanCollide = false end
        end
    end
    if Settings.WalkSpeed then Hum.WalkSpeed = Settings.SpeedValue end
end)

-- ระบบเก็บเหรียญ
local ProcessedCoins = {}
LocalPlayer.CharacterAdded:Connect(function() 
    ProcessedCoins = {} 
    RoleAssigned = false
    GameStarted = false
end)

RunService.Heartbeat:Connect(function()
    if not Settings.AutoCoin or IsFlying then return end
    local Char = LocalPlayer.Character
    if not Char then return end
    local Hum = Char:FindFirstChild("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Hum or Hum.Health <= 0 or not Root then return end

    local NearestCoin, Dist = nil, math.huge
    for _, Desc in ipairs(Workspace:GetDescendants()) do
        if Desc.Name == "Coin" and Desc:IsA("BasePart") and not ProcessedCoins[Desc] then
            local CDist = (Root.Position - Desc.Position).Magnitude
            if CDist < Dist then Dist = CDist; NearestCoin = Desc end
        end
    end
    if not NearestCoin then return end
    IsFlying = true
    
    local Conn = RunService.RenderStepped:Connect(function()
        if not Settings.AutoCoin or not NearestCoin or not NearestCoin.Parent then
            Conn:Disconnect(); IsFlying = false; Root.Velocity = Vector3.new(0, 0, 0); return
        end
        local Dir = (NearestCoin.Position - Root.Position)
        if Dir.Magnitude < 2.5 then
            ProcessedCoins[NearestCoin] = true
            Conn:Disconnect(); IsFlying = false; Root.Velocity = Vector3.new(0, 0, 0)
        else
            Root.Velocity = Dir.Unit * Settings.CoinSpeed
        end
    end)
end)

-- 🚀 บินชนฆาตกร
local FlingActive = false

LocalPlayer.CharacterAdded:Connect(function()
    RoleAssigned = false; GameStarted = false; FlingActive = false
end)

RunService.RenderStepped:Connect(function()
    if not Settings.FlingMurderer then FlingActive = false; return end
    local Char = LocalPlayer.Character
    if not Char then return end
    local Hum = Char:FindFirstChild("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")
    if not Hum or not Root or Hum.Health <= 0 then return end
    
    local Values = Workspace:FindFirstChild("Values")
    local GameState = Values and Values:FindFirstChild("GameState")
    local State = GameState and GameState.Value or ""
    
    RefreshRoles()
    
    -- สถานะ
    if State == "Intermission" then StatusLabel.Text = "⏳ รอสุ่มบทบาท..."
    elseif State == "Preparing" then
        if not RoleAssigned then StatusLabel.Text = "⏳ กำลังสุ่มบทบาท..."
        else StatusLabel.Text = "✅ บทบาทเสร็จ! บินไป!" end
    elseif State == "Playing" then
        StatusLabel.Text = "🎮 เกมเริ่มแล้ว"
        GameStarted = true; FlingActive = false; return
    end
    
    -- บินตอนนับถอยหลัง
    if RoleAssigned and State == "Preparing" and not GameStarted then
        local MurdererPart = nil
        for _, Plr in ipairs(Players:GetPlayers()) do
            if Plr ~= LocalPlayer and RoleCache[Plr] == "Murderer" and Plr.Character then
                MurdererPart = Plr.Character:FindFirstChild("HumanoidRootPart")
                if MurdererPart then break end
            end
        end
        if not MurdererPart then return end
        
        if not FlingActive then
            FlingActive = true
            StatusLabel.Text = "🚀 กำลังบินไปหาฆาตกร!"
        end
        
        local Dir = (MurdererPart.Position - Root.Position)
        local Dist = Dir.Magnitude
        Dir = Dir.Unit
        
        if Dist > 3.5 then
            Root.Velocity = Dir * Settings.FlingSpeed
            Hum:MoveTo(MurdererPart.Position)
            for _, Part in ipairs(Char:GetDescendants()) do
                if Part:IsA("BasePart") then Part.CanCollide = false end
            end
        else
            Root.Velocity = Dir * 35 + Vector3.new(0, 8, 0)
            task.delay(0.5, function() if Root then Root.Velocity = Vector3.new(0, 0, 0) end end)
        end
    elseif State == "Playing" then
        FlingActive = false
    end
end)

-- ESP ผู้เล่น
RunService.RenderStepped:Connect(function()
    local MyChar = LocalPlayer.Character
    local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
    
    -- แสดงระยะฆาตกร
    local MurdererDist = ""
    for Plr, Role in pairs(RoleCache) do
        if Role == "Murderer" and Plr.Character and MyRoot then
            local PRoot = Plr.Character:FindFirstChild("HumanoidRootPart")
            if PRoot then MurdererDist = " | ฆาตกร [" .. math.floor((MyRoot.Position - PRoot.Position).Magnitude) .. "ม]" end
        end
    end
    if MurdererDist ~= "" then StatusLabel.Text = StatusLabel.Text .. MurdererDist end

    -- ESP ผู้เล่น
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            if pChar and pChar:FindFirstChild("HumanoidRootPart") then
                local pHum = pChar:FindFirstChild("Humanoid")
                if pHum and pHum.Health > 0 then
                    local targetRole = RoleCache[player] or "Innocent"
                    local ShowBox = false
                    local BoxColor = Color3.fromRGB(231, 76, 60)
                    if targetRole == "Murderer" then ShowBox = true; BoxColor = Color3.fromRGB(231, 76, 60)
                    elseif targetRole == "Sheriff" then ShowBox = true; BoxColor = Color3.fromRGB(52, 152, 219) end
                    
                    if ShowBox then
                        local pHrp = pChar.HumanoidRootPart
                        local pHead = pChar:FindFirstChild("Head")
                        if pHead then
                            local Pos, OnScr = Camera:WorldToViewportPoint(pHead.Position)
                            if OnScr then
                                if not ESPCache[player] then
                                    ESPCache[player] = {
                                        Box = Drawing.new("Square"),
                                        NameText = Drawing.new("Text")
                                    }
                                    ESPCache[player].Box.Thickness = 2
                                    ESPCache[player].Box.Filled = false
                                    ESPCache[player].NameText.Size = 12
                                    ESPCache[player].NameText.Center = true
                                end
                                local Box = ESPCache[player].Box
                                local NameText = ESPCache[player].NameText
                                local HPos, HOn = Camera:WorldToViewportPoint(pHead.Position)
                                local FPos, FOn = Camera:WorldToViewportPoint(pHrp.Position - Vector3.new(0, 1, 0))
                                if HOn and FOn then
                                    local H = math.abs(HPos.Y - FPos.Y) * 1.8
                                    local W = H * 0.6
                                    Box.Color = BoxColor
                                    Box.Position = Vector2.new(HPos.X - W/2, HPos.Y - H/2)
                                    Box.Size = Vector2.new(W, H)
                                    Box.Visible = true
                                    local DistStr = MyRoot and (" [" .. math.floor((MyRoot.Position - pHrp.Position).Magnitude) .. "ม]") or ""
                                    NameText.Text = targetRole .. DistStr
                                    NameText.Color = BoxColor
                                    NameText.Position = Vector2.new(HPos.X, HPos.Y - H - 16)
                                    NameText.Visible = true
                                end
                            elseif ESPCache[player] then
                                ESPCache[player].Box.Visible = false
                                ESPCache[player].NameText.Visible = false
                            end
                        end
                    elseif ESPCache[player] then
                        ESPCache[player].Box.Visible = false
                        ESPCache[player].NameText.Visible = false
                    end
                else RemoveESP(player) end
            else RemoveESP(player) end
        end
    end
end)

print("✅ โหลดสำเร็จ! ลบ ESP ปืนออกเรียบร้อยแล้ว")
  
