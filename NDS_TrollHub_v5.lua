--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     NDS TROLL HUB v5.0 - ULTIMATE                         ║
    ║                   Natural Disaster Survival                               ║
    ║                 Compatível com Executores Mobile                          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    
    CORREÇÕES v5.0:
    ═══════════════
    ✓ Fix loop ao morrer (desativa funções E para de seguir)
    ✓ Proteção contra objetos (não colidem com você)
    ✓ Lista de players GRANDE e funcional com scroll
    ✓ Range maior no orbit (configurável até 50)
    ✓ God Mode REAL funcional
    ✓ NOVA: Telecinese - controle objetos com touch!
    
    FUNÇÕES:
    ════════
    [TROLAGEM]
    • Ímã de Objetos, Orbit Attack, Blackhole
    • Part Rain, Cage Trap, Spin Attack
    • Hat Fling, Body Fling, Launch
    • Slow Player
    
    [TELECINESE]
    • Selecione objetos tocando neles
    • Controle com touch/mouse
    • Funciona com objetos ancorados!
    
    [UTILIDADES]
    • God Mode Real, Fly, Noclip
    • Speed, ESP, Teleport
--]]

-- ═══════════════════════════════════════════════════════════════════════════
-- SERVIÇOS
-- ═══════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIGURAÇÃO
-- ═══════════════════════════════════════════════════════════════════════════

local Config = {
    OrbitRadius = 25,        -- Raio do orbit (aumentado!)
    OrbitSpeed = 2,          -- Velocidade do orbit
    OrbitHeight = 5,         -- Altura do orbit
    MagnetForce = 300,       -- Força do ímã
    SpinRadius = 15,         -- Raio do spin
    SpinSpeed = 4,           -- Velocidade do spin
    FlySpeed = 60,           -- Velocidade do fly
    SpeedMultiplier = 3,     -- Multiplicador de velocidade
    ProtectSelf = true,      -- Proteção contra objetos
}

-- ═══════════════════════════════════════════════════════════════════════════
-- VARIÁVEIS DE ESTADO
-- ═══════════════════════════════════════════════════════════════════════════

local State = {
    SelectedPlayer = nil,
    Magnet = false,
    Orbit = false,
    Blackhole = false,
    PartRain = false,
    Cage = false,
    Spin = false,
    HatFling = false,
    BodyFling = false,
    Launch = false,
    SlowPlayer = false,
    GodMode = false,
    Fly = false,
    Noclip = false,
    Speed = false,
    ESP = false,
    Telekinesis = false,
}

local Connections = {}
local CreatedObjects = {}
local AnchorPart = nil
local MainAttachment = nil

-- Telecinese
local TelekinesisTarget = nil
local TelekinesisDistance = 15

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Notificação
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- Limpar conexões
local function ClearConnections(prefix)
    for name, conn in pairs(Connections) do
        if prefix then
            if string.find(name, prefix) then
                pcall(function() conn:Disconnect() end)
                Connections[name] = nil
            end
        else
            pcall(function() conn:Disconnect() end)
        end
    end
    if not prefix then Connections = {} end
end

-- Limpar objetos criados
local function ClearCreatedObjects()
    for _, obj in pairs(CreatedObjects) do
        pcall(function() obj:Destroy() end)
    end
    CreatedObjects = {}
end

-- Desativar TODAS as funções (chamado ao morrer)
local function DisableAllFunctions()
    for key, _ in pairs(State) do
        if key ~= "SelectedPlayer" then
            State[key] = false
        end
    end
    ClearConnections()
    ClearCreatedObjects()
    
    -- Limpar controles de partes
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            pcall(function()
                local align = obj:FindFirstChild("_NDSAlign")
                local attach = obj:FindFirstChild("_NDSAttach")
                local torque = obj:FindFirstChild("_NDSTorque")
                if align then align:Destroy() end
                if attach then attach:Destroy() end
                if torque then torque:Destroy() end
            end)
        end
    end
    
    -- Resetar velocidade do HRP se existir
    local hrp = GetHRP()
    if hrp then
        pcall(function()
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SISTEMA DE CONTROLE DE REDE
-- ═══════════════════════════════════════════════════════════════════════════

local function SetupNetworkControl()
    -- Remover âncora anterior
    if AnchorPart then pcall(function() AnchorPart:Destroy() end) end
    
    -- Criar parte âncora invisível
    AnchorPart = Instance.new("Part")
    AnchorPart.Name = "_NDSAnchor"
    AnchorPart.Size = Vector3.new(1, 1, 1)
    AnchorPart.Transparency = 1
    AnchorPart.CanCollide = false
    AnchorPart.Anchored = true
    AnchorPart.CFrame = CFrame.new(0, 10000, 0)
    AnchorPart.Parent = Workspace
    table.insert(CreatedObjects, AnchorPart)
    
    MainAttachment = Instance.new("Attachment")
    MainAttachment.Name = "MainAttach"
    MainAttachment.Parent = AnchorPart
    
    -- SimulationRadius
    Connections.SimRadius = RunService.Heartbeat:Connect(function()
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SISTEMA DE PARTES
-- ═══════════════════════════════════════════════════════════════════════════

local function GetUnanchoredParts()
    local parts = {}
    local myChar = GetCharacter()
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            -- Filtrar partes de personagens e sistema
            local isValid = true
            
            if obj.Name:find("_NDS") then isValid = false end
            if obj.Name == "Terrain" then isValid = false end
            
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and obj:IsDescendantOf(player.Character) then
                    isValid = false
                    break
                end
            end
            
            if isValid then
                table.insert(parts, obj)
            end
        end
    end
    
    return parts
end

local function GetMyAccessories()
    local handles = {}
    local char = GetCharacter()
    if char then
        for _, acc in pairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    table.insert(handles, handle)
                end
            end
        end
    end
    return handles
end

local function GetAvailableParts()
    local parts = GetUnanchoredParts()
    if #parts < 5 then
        local handles = GetMyAccessories()
        for _, h in pairs(handles) do
            table.insert(parts, h)
        end
    end
    return parts
end

-- Configurar parte para controle (COM PROTEÇÃO)
local function SetupPartControl(part, targetAttachment, noCollideWithMe)
    if not part or not part:IsA("BasePart") then return end
    if part.Anchored then return end
    if part.Name:find("_NDS") then return end
    
    -- Verificar se é parte de personagem
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and part:IsDescendantOf(player.Character) then
            if player == LocalPlayer then return end -- Não controlar minhas partes
        end
    end
    
    -- Limpar controles existentes
    pcall(function()
        local align = part:FindFirstChild("_NDSAlign")
        local attach = part:FindFirstChild("_NDSAttach")
        local torque = part:FindFirstChild("_NDSTorque")
        if align then align:Destroy() end
        if attach then attach:Destroy() end
        if torque then torque:Destroy() end
    end)
    
    -- PROTEÇÃO: Desabilitar colisão com o próprio player
    if Config.ProtectSelf or noCollideWithMe then
        part.CanCollide = false
    end
    
    -- Criar attachment
    local attach = Instance.new("Attachment")
    attach.Name = "_NDSAttach"
    attach.Parent = part
    
    -- Criar AlignPosition
    local align = Instance.new("AlignPosition")
    align.Name = "_NDSAlign"
    align.MaxForce = math.huge
    align.MaxVelocity = Config.MagnetForce
    align.Responsiveness = 200
    align.Attachment0 = attach
    align.Attachment1 = targetAttachment or MainAttachment
    align.Parent = part
    
    return attach, align
end

local function CleanPartControl(part)
    if not part then return end
    pcall(function()
        local align = part:FindFirstChild("_NDSAlign")
        local attach = part:FindFirstChild("_NDSAttach")
        local torque = part:FindFirstChild("_NDSTorque")
        if align then align:Destroy() end
        if attach then attach:Destroy() end
        if torque then torque:Destroy() end
        part.CanCollide = true
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: ÍMÃ DE OBJETOS
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleMagnet()
    State.Magnet = not State.Magnet
    
    if State.Magnet then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Magnet = false
            return false, "Selecione um player!"
        end
        
        -- Configurar partes
        for _, part in pairs(GetAvailableParts()) do
            SetupPartControl(part, MainAttachment, true)
        end
        
        -- Novas partes
        Connections.MagnetNew = Workspace.DescendantAdded:Connect(function(obj)
            if State.Magnet and obj:IsA("BasePart") then
                task.wait(0.1)
                SetupPartControl(obj, MainAttachment, true)
            end
        end)
        
        -- Atualizar posição
        Connections.MagnetUpdate = RunService.Heartbeat:Connect(function()
            if State.Magnet and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and AnchorPart then
                    AnchorPart.CFrame = hrp.CFrame
                end
            end
        end)
        
        return true, "Ímã ativado!"
    else
        ClearConnections("Magnet")
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                CleanPartControl(part)
            end
        end
        return false, "Ímã desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: ORBIT ATTACK (Range grande e círculo perfeito)
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleOrbit()
    State.Orbit = not State.Orbit
    
    if State.Orbit then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Orbit = false
            return false, "Selecione um player!"
        end
        
        local angle = 0
        local parts = GetAvailableParts()
        local partData = {}
        
        -- Criar attachment individual para cada parte
        for i, part in pairs(parts) do
            local att = Instance.new("Attachment")
            att.Name = "_NDSOrbitAtt" .. i
            att.Parent = AnchorPart
            table.insert(CreatedObjects, att)
            
            SetupPartControl(part, att, true)
            partData[i] = {part = part, attachment = att, baseAngle = (i / #parts) * math.pi * 2}
        end
        
        -- Atualizar órbita
        Connections.OrbitUpdate = RunService.Heartbeat:Connect(function(dt)
            if State.Orbit and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    angle = angle + dt * Config.OrbitSpeed
                    
                    for i, data in pairs(partData) do
                        if data.part and data.part.Parent and data.attachment then
                            local currentAngle = data.baseAngle + angle
                            local offset = Vector3.new(
                                math.cos(currentAngle) * Config.OrbitRadius,
                                Config.OrbitHeight + math.sin(currentAngle * 2) * 2,
                                math.sin(currentAngle) * Config.OrbitRadius
                            )
                            data.attachment.WorldPosition = hrp.Position + offset
                        end
                    end
                end
            end
        end)
        
        return true, "Orbit ativado! (Raio: " .. Config.OrbitRadius .. ")"
    else
        ClearConnections("Orbit")
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                CleanPartControl(part)
            end
        end
        return false, "Orbit desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: BLACKHOLE
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleBlackhole()
    State.Blackhole = not State.Blackhole
    
    if State.Blackhole then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Blackhole = false
            return false, "Selecione um player!"
        end
        
        local angle = 0
        
        for _, part in pairs(GetAvailableParts()) do
            SetupPartControl(part, MainAttachment, true)
            
            -- Torque para rotação
            local torque = Instance.new("Torque")
            torque.Name = "_NDSTorque"
            torque.Torque = Vector3.new(50000, 50000, 50000)
            local att = part:FindFirstChild("_NDSAttach")
            if att then torque.Attachment0 = att end
            torque.Parent = part
        end
        
        Connections.BlackholeNew = Workspace.DescendantAdded:Connect(function(obj)
            if State.Blackhole and obj:IsA("BasePart") then
                task.wait(0.1)
                SetupPartControl(obj, MainAttachment, true)
            end
        end)
        
        Connections.BlackholeUpdate = RunService.Heartbeat:Connect(function(dt)
            if State.Blackhole and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and AnchorPart then
                    angle = angle + dt * 5
                    local spiral = Vector3.new(math.cos(angle) * 2, math.sin(angle * 2), math.sin(angle) * 2)
                    AnchorPart.CFrame = CFrame.new(hrp.Position + spiral)
                end
            end
        end)
        
        return true, "Blackhole ativado!"
    else
        ClearConnections("Blackhole")
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                CleanPartControl(part)
                local torque = part:FindFirstChild("_NDSTorque")
                if torque then torque:Destroy() end
            end
        end
        return false, "Blackhole desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: PART RAIN
-- ═══════════════════════════════════════════════════════════════════════════

local function TogglePartRain()
    State.PartRain = not State.PartRain
    
    if State.PartRain then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.PartRain = false
            return false, "Selecione um player!"
        end
        
        for _, part in pairs(GetAvailableParts()) do
            SetupPartControl(part, MainAttachment, true)
        end
        
        Connections.PartRainUpdate = RunService.Heartbeat:Connect(function()
            if State.PartRain and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and AnchorPart then
                    local offset = Vector3.new(math.random(-15, 15), 50, math.random(-15, 15))
                    AnchorPart.CFrame = CFrame.new(hrp.Position + offset)
                end
            end
        end)
        
        return true, "Part Rain ativado!"
    else
        ClearConnections("PartRain")
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                CleanPartControl(part)
            end
        end
        return false, "Part Rain desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: SPIN ATTACK
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleSpin()
    State.Spin = not State.Spin
    
    if State.Spin then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Spin = false
            return false, "Selecione um player!"
        end
        
        local angle = 0
        local parts = GetAvailableParts()
        local partData = {}
        
        for i, part in pairs(parts) do
            local att = Instance.new("Attachment")
            att.Name = "_NDSSpinAtt" .. i
            att.Parent = AnchorPart
            table.insert(CreatedObjects, att)
            
            SetupPartControl(part, att, true)
            partData[i] = {part = part, attachment = att, baseAngle = (i / #parts) * math.pi * 2}
        end
        
        Connections.SpinUpdate = RunService.Heartbeat:Connect(function(dt)
            if State.Spin and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    angle = angle + dt * Config.SpinSpeed
                    
                    for i, data in pairs(partData) do
                        if data.part and data.part.Parent and data.attachment then
                            local currentAngle = data.baseAngle + angle
                            local offset = Vector3.new(
                                math.cos(currentAngle) * Config.SpinRadius,
                                1,
                                math.sin(currentAngle) * Config.SpinRadius
                            )
                            data.attachment.WorldPosition = hrp.Position + offset
                        end
                    end
                end
            end
        end)
        
        return true, "Spin ativado!"
    else
        ClearConnections("Spin")
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                CleanPartControl(part)
            end
        end
        return false, "Spin desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: CAGE TRAP
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleCage()
    State.Cage = not State.Cage
    
    if State.Cage then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Cage = false
            return false, "Selecione um player!"
        end
        
        local parts = GetAvailableParts()
        local partData = {}
        local cageRadius = 4
        
        for i, part in pairs(parts) do
            if i > 24 then break end
            
            local att = Instance.new("Attachment")
            att.Name = "_NDSCageAtt" .. i
            att.Parent = AnchorPart
            table.insert(CreatedObjects, att)
            
            SetupPartControl(part, att, true)
            
            -- Posição na gaiola
            local layer = math.floor((i - 1) / 8)
            local indexInLayer = (i - 1) % 8
            local angle = (indexInLayer / 8) * math.pi * 2
            
            partData[i] = {
                part = part,
                attachment = att,
                angle = angle,
                height = (layer - 1) * 3
            }
        end
        
        Connections.CageUpdate = RunService.Heartbeat:Connect(function()
            if State.Cage and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for i, data in pairs(partData) do
                        if data.attachment then
                            local offset = Vector3.new(
                                math.cos(data.angle) * cageRadius,
                                data.height,
                                math.sin(data.angle) * cageRadius
                            )
                            data.attachment.WorldPosition = hrp.Position + offset
                        end
                    end
                end
            end
        end)
        
        return true, "Cage ativado!"
    else
        ClearConnections("Cage")
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                CleanPartControl(part)
            end
        end
        return false, "Cage desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: HAT FLING
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleHatFling()
    State.HatFling = not State.HatFling
    
    if State.HatFling then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.HatFling = false
            return false, "Selecione um player!"
        end
        
        local hrp = GetHRP()
        local targetHRP = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if not hrp or not targetHRP then
            State.HatFling = false
            return false, "Erro!"
        end
        
        local angle = 0
        
        Connections.HatFlingUpdate = RunService.Heartbeat:Connect(function(dt)
            if State.HatFling and State.SelectedPlayer and State.SelectedPlayer.Character then
                local tHRP = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = GetHRP()
                if tHRP and myHRP then
                    angle = angle + dt * 30
                    local offset = Vector3.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
                    myHRP.CFrame = CFrame.new(tHRP.Position + offset)
                    myHRP.Velocity = Vector3.new(9e5, 9e5, 9e5)
                    myHRP.RotVelocity = Vector3.new(9e5, 9e5, 9e5)
                end
            end
        end)
        
        return true, "Hat Fling ativado!"
    else
        ClearConnections("HatFling")
        local hrp = GetHRP()
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
        return false, "Hat Fling desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: BODY FLING
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleBodyFling()
    State.BodyFling = not State.BodyFling
    
    if State.BodyFling then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.BodyFling = false
            return false, "Selecione um player!"
        end
        
        Connections.BodyFlingUpdate = RunService.Heartbeat:Connect(function()
            if State.BodyFling and State.SelectedPlayer and State.SelectedPlayer.Character then
                local tHRP = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = GetHRP()
                if tHRP and myHRP then
                    myHRP.CFrame = tHRP.CFrame
                    myHRP.Velocity = Vector3.new(9e7, 9e7, 9e7)
                end
            end
        end)
        
        return true, "Body Fling ativado!"
    else
        ClearConnections("BodyFling")
        local hrp = GetHRP()
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
        return false, "Body Fling desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: LAUNCH
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleLaunch()
    State.Launch = not State.Launch
    
    if State.Launch then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Launch = false
            return false, "Selecione um player!"
        end
        
        -- Configurar partes para ir para cima do player
        for _, part in pairs(GetAvailableParts()) do
            SetupPartControl(part, MainAttachment, true)
        end
        
        Connections.LaunchUpdate = RunService.Heartbeat:Connect(function()
            if State.Launch and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and AnchorPart then
                    AnchorPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, -3, 0))
                end
            end
        end)
        
        return true, "Launch ativado!"
    else
        ClearConnections("Launch")
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                CleanPartControl(part)
            end
        end
        return false, "Launch desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: SLOW PLAYER
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleSlowPlayer()
    State.SlowPlayer = not State.SlowPlayer
    
    if State.SlowPlayer then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.SlowPlayer = false
            return false, "Selecione um player!"
        end
        
        -- Criar partes pesadas
        local slowParts = {}
        for i = 1, 6 do
            local part = Instance.new("Part")
            part.Name = "_NDSSlowPart"
            part.Size = Vector3.new(3, 3, 3)
            part.Transparency = 0.9
            part.CanCollide = true
            part.Anchored = false
            part.Massless = false
            part.CustomPhysicalProperties = PhysicalProperties.new(100, 1, 0, 1, 1)
            part.Parent = Workspace
            table.insert(slowParts, part)
            table.insert(CreatedObjects, part)
        end
        
        Connections.SlowUpdate = RunService.Heartbeat:Connect(function()
            if State.SlowPlayer and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for i, part in pairs(slowParts) do
                        if part and part.Parent then
                            local angle = (i / #slowParts) * math.pi * 2
                            local offset = Vector3.new(math.cos(angle) * 2, 0, math.sin(angle) * 2)
                            part.CFrame = CFrame.new(hrp.Position + offset)
                        end
                    end
                end
            end
        end)
        
        return true, "Slow ativado!"
    else
        ClearConnections("Slow")
        for _, obj in pairs(CreatedObjects) do
            if obj and obj.Name == "_NDSSlowPart" then
                pcall(function() obj:Destroy() end)
            end
        end
        return false, "Slow desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: GOD MODE REAL
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleGodMode()
    State.GodMode = not State.GodMode
    
    if State.GodMode then
        local char = GetCharacter()
        local humanoid = GetHumanoid()
        
        if not char or not humanoid then
            State.GodMode = false
            return false, "Erro!"
        end
        
        -- MÉTODO 1: ForceField invisível
        local ff = Instance.new("ForceField")
        ff.Name = "_NDSForceField"
        ff.Visible = false
        ff.Parent = char
        table.insert(CreatedObjects, ff)
        
        -- MÉTODO 2: Health infinita
        Connections.GodModeHealth = humanoid.HealthChanged:Connect(function()
            if State.GodMode then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
        
        -- MÉTODO 3: Heartbeat backup
        Connections.GodModeHeartbeat = RunService.Heartbeat:Connect(function()
            if State.GodMode then
                local hum = GetHumanoid()
                if hum then
                    hum.Health = hum.MaxHealth
                end
                
                -- Recriar ForceField se removido
                local c = GetCharacter()
                if c and not c:FindFirstChild("_NDSForceField") then
                    local newFF = Instance.new("ForceField")
                    newFF.Name = "_NDSForceField"
                    newFF.Visible = false
                    newFF.Parent = c
                end
            end
        end)
        
        -- MÉTODO 4: Prevenir dano de queda
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        
        return true, "God Mode REAL ativado!"
    else
        ClearConnections("GodMode")
        
        local char = GetCharacter()
        if char then
            local ff = char:FindFirstChild("_NDSForceField")
            if ff then ff:Destroy() end
        end
        
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        end
        
        return false, "God Mode desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: FLY
-- ═══════════════════════════════════════════════════════════════════════════

local flyKeys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false}

local function ToggleFly()
    State.Fly = not State.Fly
    
    if State.Fly then
        local hrp = GetHRP()
        if not hrp then
            State.Fly = false
            return false, "Erro!"
        end
        
        local bv = Instance.new("BodyVelocity")
        bv.Name = "_NDSFlyBV"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp
        table.insert(CreatedObjects, bv)
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "_NDSFlyBG"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 9e4
        bg.Parent = hrp
        table.insert(CreatedObjects, bg)
        
        Connections.FlyInputBegan = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode.Name
                if flyKeys[key] ~= nil then flyKeys[key] = true end
            end
        end)
        
        Connections.FlyInputEnded = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode.Name
                if flyKeys[key] ~= nil then flyKeys[key] = false end
            end
        end)
        
        Connections.FlyUpdate = RunService.Heartbeat:Connect(function()
            if State.Fly then
                local h = GetHumanoid()
                local r = GetHRP()
                if not h or not r then return end
                
                local bvel = r:FindFirstChild("_NDSFlyBV")
                local bgyro = r:FindFirstChild("_NDSFlyBG")
                if not bvel or not bgyro then return end
                
                local direction = Vector3.new(0, 0, 0)
                local camCF = Camera.CFrame
                
                if flyKeys.W then direction = direction + camCF.LookVector end
                if flyKeys.S then direction = direction - camCF.LookVector end
                if flyKeys.A then direction = direction - camCF.RightVector end
                if flyKeys.D then direction = direction + camCF.RightVector end
                if flyKeys.Space then direction = direction + Vector3.new(0, 1, 0) end
                if flyKeys.LeftShift then direction = direction - Vector3.new(0, 1, 0) end
                
                -- Mobile support
                if h.MoveDirection.Magnitude > 0 then
                    direction = direction + (camCF.LookVector * h.MoveDirection.Z + camCF.RightVector * h.MoveDirection.X)
                end
                
                if direction.Magnitude > 0 then
                    bvel.Velocity = direction.Unit * Config.FlySpeed
                else
                    bvel.Velocity = Vector3.new(0, 0, 0)
                end
                
                bgyro.CFrame = camCF
            end
        end)
        
        return true, "Fly ativado! (WASD + Space/Shift)"
    else
        ClearConnections("Fly")
        
        local hrp = GetHRP()
        if hrp then
            local bv = hrp:FindFirstChild("_NDSFlyBV")
            local bg = hrp:FindFirstChild("_NDSFlyBG")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        
        for k, _ in pairs(flyKeys) do flyKeys[k] = false end
        
        return false, "Fly desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: NOCLIP
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleNoclip()
    State.Noclip = not State.Noclip
    
    if State.Noclip then
        Connections.NoclipUpdate = RunService.Stepped:Connect(function()
            if State.Noclip then
                local char = GetCharacter()
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
        
        return true, "Noclip ativado!"
    else
        ClearConnections("Noclip")
        return false, "Noclip desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: SPEED
-- ═══════════════════════════════════════════════════════════════════════════

local originalSpeed = 16

local function ToggleSpeed()
    State.Speed = not State.Speed
    
    if State.Speed then
        local humanoid = GetHumanoid()
        if humanoid then
            originalSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = originalSpeed * Config.SpeedMultiplier
        end
        
        Connections.SpeedUpdate = RunService.Heartbeat:Connect(function()
            if State.Speed then
                local h = GetHumanoid()
                if h and h.WalkSpeed < originalSpeed * Config.SpeedMultiplier then
                    h.WalkSpeed = originalSpeed * Config.SpeedMultiplier
                end
            end
        end)
        
        return true, "Speed ativado! (3x)"
    else
        ClearConnections("Speed")
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = originalSpeed
        end
        return false, "Speed desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: ESP
-- ═══════════════════════════════════════════════════════════════════════════

local espObjects = {}

local function ToggleESP()
    State.ESP = not State.ESP
    
    if State.ESP then
        local function createESP(player)
            if player == LocalPlayer then return end
            if not player.Character then return end
            
            local highlight = Instance.new("Highlight")
            highlight.Name = "_NDSESP"
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = player.Character
            highlight.Parent = player.Character
            
            espObjects[player] = highlight
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then createESP(player) end
            
            Connections["ESPChar_" .. player.Name] = player.CharacterAdded:Connect(function()
                if State.ESP then
                    task.wait(0.5)
                    createESP(player)
                end
            end)
        end
        
        Connections.ESPPlayerAdded = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                if State.ESP then
                    task.wait(0.5)
                    createESP(player)
                end
            end)
        end)
        
        return true, "ESP ativado!"
    else
        for _, highlight in pairs(espObjects) do
            pcall(function() highlight:Destroy() end)
        end
        espObjects = {}
        
        ClearConnections("ESP")
        
        return false, "ESP desativado"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: TELEPORT
-- ═══════════════════════════════════════════════════════════════════════════

local function TeleportToPlayer()
    if not State.SelectedPlayer or not State.SelectedPlayer.Character then
        return false, "Selecione um player!"
    end
    
    local hrp = GetHRP()
    local targetHRP = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if hrp and targetHRP then
        hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
        return true, "Teleportado!"
    end
    
    return false, "Erro!"
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNÇÃO: TELECINESE (NOVA!)
-- ═══════════════════════════════════════════════════════════════════════════

local function ToggleTelekinesis()
    State.Telekinesis = not State.Telekinesis
    
    if State.Telekinesis then
        -- Criar indicador visual
        local indicator = Instance.new("Part")
        indicator.Name = "_NDSTelekIndicator"
        indicator.Size = Vector3.new(0.5, 0.5, 0.5)
        indicator.Shape = Enum.PartType.Ball
        indicator.Material = Enum.Material.Neon
        indicator.Color = Color3.fromRGB(138, 43, 226)
        indicator.Transparency = 0.3
        indicator.CanCollide = false
        indicator.Anchored = true
        indicator.Parent = Workspace
        table.insert(CreatedObjects, indicator)
        
        -- Selecionar objeto com click/touch
        Connections.TelekSelect = UserInputService.InputBegan:Connect(function(input)
            if not State.Telekinesis then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local ray = Camera:ScreenPointToRay(input.Position.X, input.Position.Y)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {GetCharacter()}
                
                local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)
                if result and result.Instance then
                    local part = result.Instance
                    if part:IsA("BasePart") then
                        TelekinesisTarget = part
                        TelekinesisDistance = (part.Position - Camera.CFrame.Position).Magnitude
                        
                        -- Desancorar se necessário
                        if part.Anchored then
                            -- Tentar desancorar (pode não funcionar em FE)
                            pcall(function() part.Anchored = false end)
                        end
                        
                        -- Configurar controle
                        SetupPartControl(part, MainAttachment, true)
                        
                        Notify("Telecinese", "Objeto selecionado: " .. part.Name, 2)
                    end
                end
            end
        end)
        
        -- Mover objeto com mouse/touch
        Connections.TelekMove = RunService.RenderStepped:Connect(function()
            if State.Telekinesis and TelekinesisTarget and TelekinesisTarget.Parent then
                local mousePos = UserInputService:GetMouseLocation()
                local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
                local targetPos = ray.Origin + ray.Direction * TelekinesisDistance
                
                if AnchorPart then
                    AnchorPart.CFrame = CFrame.new(targetPos)
                end
                
                -- Atualizar indicador
                if indicator and indicator.Parent then
                    indicator.CFrame = CFrame.new(targetPos)
                end
            end
        end)
        
        -- Scroll para ajustar distância
        Connections.TelekScroll = UserInputService.InputChanged:Connect(function(input)
            if State.Telekinesis and input.UserInputType == Enum.UserInputType.MouseWheel then
                TelekinesisDistance = math.clamp(TelekinesisDistance + input.Position.Z * 5, 5, 100)
            end
        end)
        
        -- Soltar objeto com click direito
        Connections.TelekRelease = UserInputService.InputBegan:Connect(function(input)
            if State.Telekinesis and input.UserInputType == Enum.UserInputType.MouseButton2 then
                if TelekinesisTarget then
                    CleanPartControl(TelekinesisTarget)
                    TelekinesisTarget = nil
                    Notify("Telecinese", "Objeto solto!", 1)
                end
            end
        end)
        
        return true, "Telecinese ativada! Click para selecionar, Right-click para soltar"
    else
        ClearConnections("Telek")
        
        if TelekinesisTarget then
            CleanPartControl(TelekinesisTarget)
            TelekinesisTarget = nil
        end
        
        return false, "Telecinese desativada"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RECONEXÃO AO RESPAWNAR
-- ═══════════════════════════════════════════════════════════════════════════

LocalPlayer.CharacterAdded:Connect(function(char)
    -- DESATIVAR TUDO ao morrer
    DisableAllFunctions()
    
    task.wait(1)
    
    -- Reconfigurar rede
    SetupNetworkControl()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- INTERFACE DO USUÁRIO
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateUI()
    -- Remover UI existente
    pcall(function()
        game:GetService("CoreGui"):FindFirstChild("NDSTrollHub"):Destroy()
    end)
    pcall(function()
        LocalPlayer.PlayerGui:FindFirstChild("NDSTrollHub"):Destroy()
    end)
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NDSTrollHub"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Cores
    local Colors = {
        Bg = Color3.fromRGB(18, 18, 22),
        Secondary = Color3.fromRGB(28, 28, 35),
        Accent = Color3.fromRGB(138, 43, 226),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(140, 140, 140),
        Success = Color3.fromRGB(50, 205, 50),
        Error = Color3.fromRGB(255, 70, 70),
    }
    
    -- Frame Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 340, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -170, 0.5, -250)
    MainFrame.BackgroundColor3 = Colors.Bg
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Colors.Accent
    MainStroke.Thickness = 2
    MainStroke.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 45)
    Header.BackgroundColor3 = Colors.Secondary
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 12)
    HeaderFix.Position = UDim2.new(0, 0, 1, -12)
    HeaderFix.BackgroundColor3 = Colors.Secondary
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🎭 NDS Troll Hub v5.0"
    Title.TextColor3 = Colors.Text
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -40, 0.5, -15)
    MinBtn.BackgroundColor3 = Colors.Accent
    MinBtn.Text = "−"
    MinBtn.TextColor3 = Colors.Text
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 20
    MinBtn.Parent = Header
    
    local MinBtnCorner = Instance.new("UICorner")
    MinBtnCorner.CornerRadius = UDim.new(0, 8)
    MinBtnCorner.Parent = MinBtn
    
    -- Seção de Seleção de Player (LISTA GRANDE)
    local PlayerSection = Instance.new("Frame")
    PlayerSection.Size = UDim2.new(1, -20, 0, 140)
    PlayerSection.Position = UDim2.new(0, 10, 0, 50)
    PlayerSection.BackgroundColor3 = Colors.Secondary
    PlayerSection.BorderSizePixel = 0
    PlayerSection.Parent = MainFrame
    
    local PlayerSectionCorner = Instance.new("UICorner")
    PlayerSectionCorner.CornerRadius = UDim.new(0, 8)
    PlayerSectionCorner.Parent = PlayerSection
    
    local PlayerLabel = Instance.new("TextLabel")
    PlayerLabel.Size = UDim2.new(1, -10, 0, 20)
    PlayerLabel.Position = UDim2.new(0, 10, 0, 5)
    PlayerLabel.BackgroundTransparency = 1
    PlayerLabel.Text = "🎯 Selecionar Player:"
    PlayerLabel.TextColor3 = Colors.TextDim
    PlayerLabel.Font = Enum.Font.Gotham
    PlayerLabel.TextSize = 12
    PlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
    PlayerLabel.Parent = PlayerSection
    
    -- Lista de Players (ScrollingFrame GRANDE)
    local PlayerListFrame = Instance.new("ScrollingFrame")
    PlayerListFrame.Size = UDim2.new(1, -20, 0, 90)
    PlayerListFrame.Position = UDim2.new(0, 10, 0, 28)
    PlayerListFrame.BackgroundColor3 = Colors.Bg
    PlayerListFrame.BorderSizePixel = 0
    PlayerListFrame.ScrollBarThickness = 6
    PlayerListFrame.ScrollBarImageColor3 = Colors.Accent
    PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlayerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PlayerListFrame.Parent = PlayerSection
    
    local PlayerListCorner = Instance.new("UICorner")
    PlayerListCorner.CornerRadius = UDim.new(0, 6)
    PlayerListCorner.Parent = PlayerListFrame
    
    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.SortOrder = Enum.SortOrder.Name
    PlayerListLayout.Padding = UDim.new(0, 4)
    PlayerListLayout.Parent = PlayerListFrame
    
    local PlayerListPadding = Instance.new("UIPadding")
    PlayerListPadding.PaddingAll = UDim.new(0, 5)
    PlayerListPadding.Parent = PlayerListFrame
    
    -- Status do player selecionado
    local SelectedLabel = Instance.new("TextLabel")
    SelectedLabel.Size = UDim2.new(1, -20, 0, 18)
    SelectedLabel.Position = UDim2.new(0, 10, 1, -22)
    SelectedLabel.BackgroundTransparency = 1
    SelectedLabel.Text = "Nenhum player selecionado"
    SelectedLabel.TextColor3 = Colors.TextDim
    SelectedLabel.Font = Enum.Font.Gotham
    SelectedLabel.TextSize = 11
    SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SelectedLabel.Parent = PlayerSection
    
    -- Função para atualizar lista de players
    local function UpdatePlayerList()
        -- Limpar lista
        for _, child in pairs(PlayerListFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Adicionar players
        for _, player in pairs(Players:GetPlayers()) do
            local btn = Instance.new("TextButton")
            btn.Name = player.Name
            btn.Size = UDim2.new(1, -10, 0, 32)
            btn.BackgroundColor3 = Colors.Secondary
            btn.Text = ""
            btn.Parent = PlayerListFrame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -50, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            nameLabel.TextColor3 = player == LocalPlayer and Colors.Accent or Colors.Text
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 11
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = btn
            
            -- Indicador de seleção
            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, 10, 0, 10)
            indicator.Position = UDim2.new(1, -25, 0.5, -5)
            indicator.BackgroundColor3 = State.SelectedPlayer == player and Colors.Success or Colors.TextDim
            indicator.Parent = btn
            
            local indicatorCorner = Instance.new("UICorner")
            indicatorCorner.CornerRadius = UDim.new(1, 0)
            indicatorCorner.Parent = indicator
            
            btn.MouseButton1Click:Connect(function()
                State.SelectedPlayer = player
                SelectedLabel.Text = "✓ Selecionado: " .. player.DisplayName
                SelectedLabel.TextColor3 = Colors.Success
                
                -- Atualizar indicadores
                for _, child in pairs(PlayerListFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        local ind = child:FindFirstChild("Frame")
                        if ind then
                            ind.BackgroundColor3 = child.Name == player.Name and Colors.Success or Colors.TextDim
                        end
                    end
                end
                
                Notify("Player Selecionado", player.DisplayName, 2)
            end)
        end
    end
    
    -- Atualizar lista inicial
    UpdatePlayerList()
    
    -- Atualizar quando players entram/saem
    Players.PlayerAdded:Connect(UpdatePlayerList)
    Players.PlayerRemoving:Connect(UpdatePlayerList)
    
    -- ScrollFrame para botões
    local ButtonsScroll = Instance.new("ScrollingFrame")
    ButtonsScroll.Size = UDim2.new(1, -20, 1, -205)
    ButtonsScroll.Position = UDim2.new(0, 10, 0, 195)
    ButtonsScroll.BackgroundTransparency = 1
    ButtonsScroll.BorderSizePixel = 0
    ButtonsScroll.ScrollBarThickness = 4
    ButtonsScroll.ScrollBarImageColor3 = Colors.Accent
    ButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ButtonsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ButtonsScroll.Parent = MainFrame
    
    local ButtonsLayout = Instance.new("UIListLayout")
    ButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ButtonsLayout.Padding = UDim.new(0, 6)
    ButtonsLayout.Parent = ButtonsScroll
    
    -- Função para criar categoria
    local function CreateCategory(name, order)
        local cat = Instance.new("Frame")
        cat.Size = UDim2.new(1, 0, 0, 22)
        cat.BackgroundTransparency = 1
        cat.LayoutOrder = order
        cat.Parent = ButtonsScroll
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "━━ " .. name .. " ━━"
        label.TextColor3 = Colors.Accent
        label.Font = Enum.Font.GothamBold
        label.TextSize = 11
        label.Parent = cat
    end
    
    -- Função para criar botão toggle
    local function CreateToggleButton(name, icon, callback, order, stateKey)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = Colors.Secondary
        btn.Text = ""
        btn.LayoutOrder = order
        btn.Parent = ButtonsScroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = icon .. " " .. name
        label.TextColor3 = Colors.Text
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn
        
        local status = Instance.new("Frame")
        status.Size = UDim2.new(0, 12, 0, 12)
        status.Position = UDim2.new(1, -28, 0.5, -6)
        status.BackgroundColor3 = Colors.TextDim
        status.Parent = btn
        
        local statusCorner = Instance.new("UICorner")
        statusCorner.CornerRadius = UDim.new(1, 0)
        statusCorner.Parent = status
        
        btn.MouseButton1Click:Connect(function()
            local success, msg = callback()
            status.BackgroundColor3 = success and Colors.Success or Colors.TextDim
            if msg then Notify(name, msg, 2) end
        end)
        
        return btn, status
    end
    
    -- Função para criar botão simples
    local function CreateButton(name, icon, callback, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = Colors.Secondary
        btn.Text = ""
        btn.LayoutOrder = order
        btn.Parent = ButtonsScroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = icon .. " " .. name
        label.TextColor3 = Colors.Text
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            local success, msg = callback()
            if msg then Notify(name, msg, 2) end
        end)
        
        return btn
    end
    
    -- Criar categorias e botões
    CreateCategory("TROLAGEM - PLAYER", 1)
    CreateToggleButton("Ímã de Objetos", "🧲", ToggleMagnet, 2, "Magnet")
    CreateToggleButton("Orbit Attack", "🌀", ToggleOrbit, 3, "Orbit")
    CreateToggleButton("Blackhole", "🕳️", ToggleBlackhole, 4, "Blackhole")
    CreateToggleButton("Part Rain", "🌧️", TogglePartRain, 5, "PartRain")
    CreateToggleButton("Spin Attack", "🔄", ToggleSpin, 6, "Spin")
    CreateToggleButton("Cage Trap", "🔒", ToggleCage, 7, "Cage")
    CreateToggleButton("Hat Fling", "🎩", ToggleHatFling, 8, "HatFling")
    CreateToggleButton("Body Fling", "💨", ToggleBodyFling, 9, "BodyFling")
    CreateToggleButton("Launch", "🚀", ToggleLaunch, 10, "Launch")
    CreateToggleButton("Slow Player", "🐢", ToggleSlowPlayer, 11, "SlowPlayer")
    
    CreateCategory("TELECINESE", 20)
    CreateToggleButton("Telecinese", "🖐️", ToggleTelekinesis, 21, "Telekinesis")
    
    CreateCategory("UTILIDADES", 30)
    CreateToggleButton("God Mode Real", "💖", ToggleGodMode, 31, "GodMode")
    CreateToggleButton("Fly", "🦅", ToggleFly, 32, "Fly")
    CreateToggleButton("Noclip", "👻", ToggleNoclip, 33, "Noclip")
    CreateToggleButton("Speed (3x)", "⚡", ToggleSpeed, 34, "Speed")
    CreateToggleButton("ESP", "👁️", ToggleESP, 35, "ESP")
    CreateButton("Teleport", "📍", TeleportToPlayer, 36)
    
    CreateCategory("CONFIGURAÇÕES", 40)
    
    -- Slider de Raio do Orbit
    local orbitSlider = Instance.new("Frame")
    orbitSlider.Size = UDim2.new(1, 0, 0, 50)
    orbitSlider.BackgroundColor3 = Colors.Secondary
    orbitSlider.LayoutOrder = 41
    orbitSlider.Parent = ButtonsScroll
    
    local orbitSliderCorner = Instance.new("UICorner")
    orbitSliderCorner.CornerRadius = UDim.new(0, 8)
    orbitSliderCorner.Parent = orbitSlider
    
    local orbitLabel = Instance.new("TextLabel")
    orbitLabel.Size = UDim2.new(1, -20, 0, 20)
    orbitLabel.Position = UDim2.new(0, 10, 0, 5)
    orbitLabel.BackgroundTransparency = 1
    orbitLabel.Text = "🌀 Raio do Orbit: " .. Config.OrbitRadius
    orbitLabel.TextColor3 = Colors.Text
    orbitLabel.Font = Enum.Font.Gotham
    orbitLabel.TextSize = 11
    orbitLabel.TextXAlignment = Enum.TextXAlignment.Left
    orbitLabel.Parent = orbitSlider
    
    local orbitSliderBg = Instance.new("Frame")
    orbitSliderBg.Size = UDim2.new(1, -20, 0, 10)
    orbitSliderBg.Position = UDim2.new(0, 10, 0, 30)
    orbitSliderBg.BackgroundColor3 = Colors.Bg
    orbitSliderBg.Parent = orbitSlider
    
    local orbitSliderBgCorner = Instance.new("UICorner")
    orbitSliderBgCorner.CornerRadius = UDim.new(1, 0)
    orbitSliderBgCorner.Parent = orbitSliderBg
    
    local orbitSliderFill = Instance.new("Frame")
    orbitSliderFill.Size = UDim2.new(Config.OrbitRadius / 50, 0, 1, 0)
    orbitSliderFill.BackgroundColor3 = Colors.Accent
    orbitSliderFill.Parent = orbitSliderBg
    
    local orbitSliderFillCorner = Instance.new("UICorner")
    orbitSliderFillCorner.CornerRadius = UDim.new(1, 0)
    orbitSliderFillCorner.Parent = orbitSliderFill
    
    local orbitSliderBtn = Instance.new("TextButton")
    orbitSliderBtn.Size = UDim2.new(1, 0, 1, 0)
    orbitSliderBtn.BackgroundTransparency = 1
    orbitSliderBtn.Text = ""
    orbitSliderBtn.Parent = orbitSliderBg
    
    local draggingOrbit = false
    
    orbitSliderBtn.MouseButton1Down:Connect(function() draggingOrbit = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingOrbit = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if draggingOrbit then
            local mouse = UserInputService:GetMouseLocation()
            local relX = math.clamp((mouse.X - orbitSliderBg.AbsolutePosition.X) / orbitSliderBg.AbsoluteSize.X, 0, 1)
            Config.OrbitRadius = math.floor(relX * 45) + 5
            orbitSliderFill.Size = UDim2.new(relX, 0, 1, 0)
            orbitLabel.Text = "🌀 Raio do Orbit: " .. Config.OrbitRadius
        end
    end)
    
    -- Minimizar
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 340, 0, 45)}):Play()
            MinBtn.Text = "+"
            PlayerSection.Visible = false
            ButtonsScroll.Visible = false
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 340, 0, 500)}):Play()
            MinBtn.Text = "−"
            task.wait(0.3)
            PlayerSection.Visible = true
            ButtonsScroll.Visible = true
        end
    end)
    
    -- Arrastar
    local dragging = false
    local dragStart, startPos
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    return ScreenGui
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════════════════

SetupNetworkControl()
local UI = CreateUI()

-- Notificação
task.spawn(function()
    task.wait(1)
    Notify("NDS Troll Hub v5.0", "Carregado com sucesso!", 3)
end)

print("═══════════════════════════════════════")
print("   🎭 NDS Troll Hub v5.0 - ULTIMATE")
print("   Carregado com sucesso!")
print("═══════════════════════════════════════")
