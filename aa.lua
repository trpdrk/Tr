-- ==============================================================================
-- MM2 ULTIMATE HUB + FlingMurderer (เวอร์ชันสุดท้าย ใช้งานได้จริง)
-- ==============================================================================

if not Drawing or not getgenv then
    print("❌ Executor ไม่รองรับ")
    return
end

-- เคลียร์ของเก่า
if getgenv().MM2_LoadedUI then pcall(function() getgenv().MM2_LoadedUI:Destroy() end) end
if getgenv().MM2_Connection then getgenv().MM2_Connection:Disconnect() end
if getgenv().MM2_NoclipConnection then getgenv().MM2_NoclipConnection:Disconnect() end
if getgenv().MM2_CoinConnection then getgenv().MM2_CoinConnection:Disconnect() end
if getgenv().MM2_SpeedConnection then getgenv().MM2_SpeedConnection:Disconnect() end
if getgenv().MM2_AuraConnection then getgenv().MM2_AuraConnection:Disconnect() end
if getgenv().MM2_FlingConnection then getgenv().MM2_FlingConnection:Disconnect() end
if getgenv().MM2_PlayerRemoving then getgenv().MM2_PlayerRemoving:Disconnect() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    Noclip = false, AutoCoin = false, WalkSpeed = false,
    AuraKill = false, FlingMurderer = false,
    SpeedValue = 27, CoinSpeed = 20, FlingSpeed = 20, AuraRange = 200
}

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_ESP_Gui"
ScreenGui.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent = CoreGui
elseif gethui then ScreenGui.Parent = gethui()
else ScreenGui.Parent = CoreGui end
getgenv().MM2_LoadedUI = ScreenGui

local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Size = UDim2.new(0, 52, 0, 52)
FloatingBtn.Position = UDim2.new(0, 20, 0.4, 0)
FloatingBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
FloatingBtn.Text = "🔪"
FloatingBtn.TextColor3 = Color3.fromRGB(231, 76, 60)
FloatingBtn.TextSize = 24
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.Active = true
FloatingBtn.Draggable = true
FloatingBtn.Parent = ScreenGui
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local st = Instance.new("UIStroke", FloatingBtn)
st.Color = Color3.fromRGB(231, 76, 60); st.Thickness = 2.5

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 420)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "MM2 ULTIMATE HUB"
Title.TextColor3 = Color3.fromRGB(231, 76, 60)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 35)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
StatusLabel.Text = "บทบาท: กำลังตรวจสอบ..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Parent = MainFrame
Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 8)

local function MakeBtn(name, y, key)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 38)
    Btn.Position = UDim2.new(0, 10, 0, y)
    Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    Btn.Text = name .. ": ปิด ❌"
    Btn.TextColor3 = Color3.fromRGB(231, 76, 60)
    Btn.TextSize = 13
    Btn.Font = Enum.Font.GothamBold
    Btn.Parent = MainFrame
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    Btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        if Settings[key] then
            Btn.Text = name .. ": เปิด ✅"
            Btn.TextColor3 = Color3.fromRGB(46, 204, 113)
        else
            Btn.Text = name .. ": ปิด ❌"
            Btn.TextColor3 = Color3.fromRGB(231, 76, 60)
        end
    end)
    return Btn
end

MakeBtn("Noclip", 85, "Noclip")
MakeBtn("WalkSpeed (27)", 130, "WalkSpeed")
MakeBtn("Auto Coin", 175, "AutoCoin")
MakeBtn("Aura Kill (200m)", 220, "AuraKill")
MakeBtn("บินชนฆาตกร", 265, "FlingMurderer")

local uiVisible = true
FloatingBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    MainFrame.Visible = uiVisible
end)

-- ตัวแปรระบบ
local RoleCache = {}
local ESPCache = {}
local GunCache = {}
local MurdererFound = false
local LastMurderer = nil
local FlingActive = false
local LastGameState = ""
local RoundStartTime = 0
local FastScanEnd = 0

local function RemoveESP(p)
    if ESPCache[p] then
        if ESPCache[p].Box then ESPCache[p].Box:Remove() end
        if ESPCache[p].NameText then ESPCache[p].NameText:Remove() end
        ESPCache[p] = nil
    end
    RoleCache[p] = nil
end

local function RemoveGunESP(g)
    if GunCache[g] then
        if GunCache[g].Box then GunCache[g].Box:Remove() end
        if GunCache[g].Text then GunCache[g].Text:Remove() end
        GunCache[g] = nil
    end
end

local function GetRole(p)
    local char = p.Character
    if not char then return "Innocent" end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return "Innocent" end
    local rv = char:FindFirstChild("Role")
    if rv and rv:IsA("StringValue") then return rv.Value end
    local function chk(c)
        if not c then return nil end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = string.lower(t.Name)
                if n:find("knife") or n:find("blade") then return "Murderer" end
                if n:find("gun") or n:find("revolver") then return "Sheriff" end
            end
        end
        return nil
    end
    local r = chk(char)
    if r then return r end
    r = chk(p:FindFirstChild("Backpack"))
    if r then return r end
    return "Innocent"
end

local function Setup(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.3)
        RoleCache[p] = GetRole(p)
    end)
    if p.Character then RoleCache[p] = GetRole(p) end
end
for _, p in ipairs(Players:GetPlayers()) do Setup(p) end
Players.PlayerAdded:Connect(Setup)
getgenv().MM2_PlayerRemoving = Players.PlayerRemoving:Connect(RemoveESP)

-- Noclip
local OrigCC = {}
getgenv().MM2_NoclipConnection = RunService.Stepped:Connect(function()
    local c = LocalPlayer.Character
    if not c then return end
    if Settings.Noclip or Settings.AutoCoin or Settings.FlingMurderer then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                if OrigCC[p] == nil then OrigCC[p] = p.CanCollide end
                p.CanCollide = false
            end
        end
    else
        for p, v in pairs(OrigCC) do
            if p and p:IsDescendantOf(Workspace) then p.CanCollide = v end
        end
        table.clear(OrigCC)
    end
end)

-- WalkSpeed
getgenv().MM2_SpeedConnection = RunService.Heartbeat:Connect(function()
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChild("Humanoid")
    if h and h.Health > 0 and Settings.WalkSpeed then h.WalkSpeed = Settings.SpeedValue end
end)

-- Aura Kill
local LastAura = 0
getgenv().MM2_AuraConnection = RunService.Heartbeat:Connect(function()
    if not Settings.AuraKill then return end
    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChild("Humanoid")
    if not hrp or not h or h.Health <= 0 then return end
    if os.clock() - LastAura < 0.25 then return end
    
    for _, p in ipairs(Players:GetPlayers()) do RoleCache[p] = GetRole(p) end
    local myRole = RoleCache[LocalPlayer] or GetRole(LocalPlayer)
    local tool = c:FindFirstChildWhichIsA("Tool")
    local tn = tool and string.lower(tool.Name) or ""
    local isK = myRole == "Murderer" or tn:find("knife") or tn:find("blade")
    local isG = myRole == "Sheriff" or tn:find("gun") or tn:find("revolver")
    
    if isK then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local pc = p.Character
                local phrp = pc and pc:FindFirstChild("HumanoidRootPart")
                local ph = pc and pc:FindFirstChild("Humanoid")
                if phrp and ph and ph.Health > 0 then
                    if (hrp.Position - phrp.Position).Magnitude <= Settings.AuraRange then
                        pcall(function()
                            local hd = tool:FindFirstChild("Handle")
                            if hd then
                                firetouchinterest(hd, phrp, 0)
                                task.wait()
                                firetouchinterest(hd, phrp, 1)
                                LastAura = os.clock()
                            end
                        end)
                        break
                    end
                end
            end
        end
    elseif isG then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and RoleCache[p] == "Murderer" then
                local pc = p.Character
                local phrp = pc and pc:FindFirstChild("HumanoidRootPart")
                local ph = pc and pc:FindFirstChild("Humanoid")
                if phrp and ph and ph.Health > 0 then
                    if (hrp.Position - phrp.Position).Magnitude <= Settings.AuraRange then
                        pcall(function()
                            local function fire(r)
                                if r and r:IsA("RemoteEvent") then
                                    r:FireServer(phrp.Position, p)
                                    LastAura = os.clock()
                                    return true
                                end
                                return false
                            end
                            if not fire(tool:FindFirstChild("Shoot")) then
                                if not fire(tool:FindFirstChild("Remote")) then
                                    for _, d in ipairs(tool:GetDescendants()) do
                                        if fire(d) then break end
                                    end
                                end
                            end
                        end)
                        break
                    end
                end
            end
        end
    end
end)

-- Auto Coin
local ProcCoins = {}
local IsFlying = false
LocalPlayer.CharacterAdded:Connect(function()
    table.clear(ProcCoins); IsFlying = false
    MurdererFound = false; LastMurderer = nil; FlingActive = false
    RoundStartTime = os.clock(); FastScanEnd = RoundStartTime + 5
    print("🔄 รอบใหม่! สแกนเร็ว 5 วินาทีแรก")
end)

getgenv().MM2_CoinConnection = RunService.Heartbeat:Connect(function()
    if not Settings.AutoCoin or IsFlying then return end
    local c = LocalPlayer.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    local h = c and c:FindFirstChild("Humanoid")
    if not hrp or not h or h.Health <= 0 then return end
    
    local near, min = nil, math.huge
    for _, o in ipairs(Workspace:GetDescendants()) do
        if not ProcCoins[o] and (o.Name == "Coin" or o:FindFirstChild("CoinVisual")) then
            local part = o:IsA("BasePart") and o or o:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (hrp.Position - part.Position).Magnitude
                if d < min then min = d; near = part end
            end
        end
    end
    if not near then return end
    ProcCoins[near] = true
    IsFlying = true
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not Settings.AutoCoin or not near.Parent or not hrp or h.Health <= 0 then
            conn:Disconnect(); IsFlying = false; return
        end
        local dir = (near.Position - hrp.Position)
        if dir.Magnitude < 2 then
            conn:Disconnect(); IsFlying = false
        else
            hrp.Velocity = dir.Unit * Settings.CoinSpeed
        end
    end)
end)

-- ==============================================================================
-- 🚀 FLING MURDERER — เวอร์ชันสุดท้าย (สแกนเร็ว + ไม่ต้องรู้ชื่อ GameState)
-- ==============================================================================
getgenv().MM2_FlingConnection = RunService.RenderStepped:Connect(function()
    if not Settings.FlingMurderer then FlingActive = false; return end
    
    local MyChar = LocalPlayer.Character
    if not MyChar then return end
    local MyHum = MyChar:FindFirstChild("Humanoid")
    local MyRoot = MyChar:FindFirstChild("HumanoidRootPart")
    if not MyHum or not MyRoot or MyHum.Health <= 0 then return end
    
    -- อ่าน GameState และพิมพ์ออกมา (ครั้งแรกที่เปลี่ยน)
    local Vals = Workspace:FindFirstChild("Values")
    local GS = Vals and Vals:FindFirstChild("GameState")
    local State = GS and GS.Value or "NOT_FOUND"
    if State ~= LastGameState then
        LastGameState = State
        print("📢 GameState = '" .. State .. "'")
    end
    
    -- สแกนบทบาท — 5 วินาทีแรกสแกนทุกเฟรม, หลังจากนั้นทุก 0.3 วิ
    local Now = os.clock()
    if Now < FastScanEnd then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                RoleCache[p] = GetRole(p)
                if RoleCache[p] == "Murderer" and not MurdererFound then
                    MurdererFound = true
                    LastMurderer = p
                    print("✅ เจอฆาตกร: " .. p.Name .. " (" .. math.floor((Now-RoundStartTime)*100)/100 .. "วิ)")
                end
            end
        end
    elseif Now % 0.3 < 0.05 then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                RoleCache[p] = GetRole(p)
                if RoleCache[p] == "Murderer" then MurdererFound = true; LastMurderer = p end
            end
        end
    end
    
    -- เช็คว่ายังถืออาวุธหรือยัง (ถ้ายังไม่ถือ = ยังไม่เริ่มเกมจริง)
    local hasWeapon = false
    for _, t in ipairs(MyChar:GetChildren()) do
        if t:IsA("Tool") then
            local n = string.lower(t.Name)
            if n:find("knife") or n:find("blade") or n:find("gun") or n:find("revolver") then
                hasWeapon = true; break
            end
        end
    end
    
    -- ตรวจสอบหลายชื่อ GameState ที่เป็นไปได้
    local sLow = string.lower(State)
    local isPrep = sLow:find("prepar") or sLow:find("start") or sLow:find("begin") 
                   or sLow:find("count") or sLow:find("round") or sLow:find("wait")
                   or State == "" or State == "NOT_FOUND"
    
    -- เงื่อนไขบิน: เจอฆาตกร + (ยังไม่ถืออาวุธ หรือ อยู่ในช่วงเตรียมตัว) + ภายใน 15 วินาทีแรก
    local CanFling = MurdererFound and LastMurderer and LastMurderer.Character
                     and (not hasWeapon or isPrep)
                     and (Now - RoundStartTime < 15)
    
    if not CanFling then
        if FlingActive then FlingActive = false; MyRoot.Velocity = Vector3.new(0,0,0) end
        return
    end
    
    local TargetRoot = LastMurderer.Character:FindFirstChild("HumanoidRootPart")
    if not TargetRoot then return end
    
    local Dir = (TargetRoot.Position - MyRoot.Position)
    local Dist = Dir.Magnitude
    local UDir = Dir.Unit
    
    if not FlingActive then
        FlingActive = true
        print("🚀 บินไปหาฆาตกร! ระยะ " .. math.floor(Dist) .. "ม.")
    end
    
    if Dist > 3.5 then
        MyRoot.CFrame = CFrame.new(MyRoot.Position, Vector3.new(TargetRoot.Position.X, MyRoot.Position.Y, TargetRoot.Position.Z))
        MyRoot.Velocity = UDir * Settings.FlingSpeed + Vector3.new(0, 2, 0)
        for _, p in ipairs(MyChar:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    else
        MyRoot.Velocity = UDir * 35 + Vector3.new(0, 8, 0)
        task.delay(0.5, function() if MyRoot then MyRoot.Velocity = Vector3.new(0,0,0) end end)
        FlingActive = false
        print("💥 ถึงแล้ว! พุ่งชน!")
    end
end)

-- ==============================================================================
-- ESP หลัก
-- ==============================================================================
local LastUpd = 0
getgenv().MM2_Connection = RunService.RenderStepped:Connect(function()
    if tick() - LastUpd >= 0.2 then
        LastUpd = tick()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then RoleCache[p] = GetRole(p) end
        end
    end
    
    local myRole = RoleCache[LocalPlayer] or GetRole(LocalPlayer)
    StatusLabel.Text = "บทบาท: " .. myRole
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    -- ESP ผู้เล่น
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local pc = p.Character
        local phrp = pc and pc:FindFirstChild("HumanoidRootPart")
        local ph = pc and pc:FindFirstChild("Humanoid")
        local phead = pc and pc:FindFirstChild("Head")
        if phrp and ph and ph.Health > 0 and phead then
            local tr = RoleCache[p] or "Innocent"
            local show = false
            local col = Color3.fromRGB(255,255,255)
            if myRole == "Innocent" then
                if tr == "Murderer" then show = true; col = Color3.fromRGB(231,76,60) end
                if tr == "Sheriff" then show = true; col = Color3.fromRGB(52,152,219) end
            elseif myRole == "Murderer" then
                if tr ~= "Murderer" then show = true; col = Color3.fromRGB(255,255,255) end
            elseif myRole == "Sheriff" then
                if tr == "Murderer" then show = true; col = Color3.fromRGB(231,76,60) end
            end
            
            if show and not ESPCache[p] then
                local b = Drawing.new("Square")
                b.Thickness = 1.5; b.Filled = false
                local t = Drawing.new("Text")
                t.Size = 12; t.Center = true; t.Outline = true
                ESPCache[p] = {Box = b, NameText = t}
            end
            
            local c = ESPCache[p]
            if show and c then
                local hp, on = Camera:WorldToViewportPoint(phead.Position + Vector3.new(0,0.3,0))
                local fp = Camera:WorldToViewportPoint(phrp.Position - Vector3.new(0,1,0))
                if on then
                    local h = math.abs(hp.Y - fp.Y)
                    local w = h / 2
                    c.Box.Color = col
                    c.Box.Size = Vector2.new(w, h)
                    c.Box.Position = Vector2.new(hp.X - w/2, hp.Y)
                    c.Box.Visible = true
                    local d = myHrp and math.floor((myHrp.Position - phrp.Position).Magnitude + 0.5) or 0
                    c.NameText.Text = p.Name .. " [" .. tr .. "] " .. d .. "m"
                    c.NameText.Color = col
                    c.NameText.Position = Vector2.new(hp.X, hp.Y - 18)
                    c.NameText.Visible = true
                else
                    c.Box.Visible = false; c.NameText.Visible = false
                end
            elseif c then
                c.Box.Visible = false; c.NameText.Visible = false
            end
        else
            RemoveESP(p)
        end
    end
    
        -- ESP ปืน
    local AG = {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Tool") then
            local n = string.lower(o.Name)
            if n:find("gun") or n:find("revolver") then
                local eq = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character and (o:IsDescendantOf(p.Character) or o:IsDescendantOf(p:FindFirstChild("Backpack"))) then
                        eq = true; break
                    end
                end
                if not eq then
                    AG[o] = true
                    local hd = o:FindFirstChild("Handle") or o:FindFirstChildWhichIsA("BasePart")
                    if hd then
                        if not GunCache[o] then
                            local b = Drawing.new("Square")
                            b.Thickness = 1.5; b.Filled = false
                            local t = Drawing.new("Text")
                            t.Size = 12; t.Center = true; t.Outline = true
                            GunCache[o] = {Box = b, Text = t}
                        end
                        local gp, on = Camera:WorldToViewportPoint(hd.Position)
                        local gc = GunCache[o]
                        if on then
                            gc.Box.Color = Color3.fromRGB(255,105,180)
                            gc.Box.Size = Vector2.new(24,24)
                            gc.Box.Position = Vector2.new(gp.X-12, gp.Y-12)
                            gc.Box.Visible = true
                            local d = myHrp and math.floor((myHrp.Position - hd.Position).Magnitude+0.5) or 0
                            gc.Text.Text = "[ปืน] " .. d .. "m"
                            gc.Text.Color = Color3.fromRGB(255,105,180)
                            gc.Text.Position = Vector2.new(gp.X, gp.Y-28)
                            gc.Text.Visible = true
                        else
                            gc.Box.Visible = false; gc.Text.Visible = false
                        end
                    end
                end
            end
        end
    end
    for g, _ in pairs(GunCache) do
        if not AG[g] then RemoveGunESP(g) end
    end
end)

print("✅ โหลดสำเร็จ! MM2 ULTIMATE HUB")
print("   🚀 บินชนฆาตกร: เปิดปุ่ม → ดูคอนโซลจะเห็น GameState จริงๆ")
print("   ⚔️ Aura Kill 200ม. | 🪙 Auto Coin | 👻 Noclip | 🏃 WalkSpeed")
