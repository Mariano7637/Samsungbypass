--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     NDS TROLL HUB v7.5 - SERVER MAGNET                         ║
    ║                   Natural Disaster Survival                               ║
    ║                 Compatível com Executores Mobile                          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
--]]

-- SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- CONFIGURAÇÃO
local Config = {
    OrbitRadius = 25,
    OrbitSpeed = 2,
    OrbitHeight = 5,
    MagnetForce = 500,
    SpinRadius = 15,
    SpinSpeed = 4,
    FlySpeed = 60,
    SpeedMultiplier = 3,
    
    -- OTIMIZAÇÕES DE PERFORMANCE (baseado em pesquisa)
    OrbitUpdateInterval = 0.05,  -- 20 FPS para orbit (era 60)
    BlackholeUpdateInterval = 0.05,  -- 20 FPS para blackhole
    SpinUpdateInterval = 0.05,  -- 20 FPS para spin
    
    -- COMPETIÇÃO (SÓ PARA ORBIT)
    OrbitRecaptureInterval = 0.3,  -- Re-captura rápida para Orbit competir
    OrbitResponsiveness = 400,  -- Responsiveness maior só para Orbit
    OrbitMaxVelocity = 800,  -- Velocidade maior só para Orbit
}

-- ESTADO
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
    View = false,
    Noclip = false,
    Speed = false,
    ESP = false,
    Telekinesis = false,
    SkyLift = false,
    ServerMagnet = false,
}

local Connections = {}
local CreatedObjects = {}
local AnchorPart = nil
local MainAttachment = nil
local TelekinesisTarget = nil
local TelekinesisDistance = 15

-- FUNÇÕES UTILITÁRIAS
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

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

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

local function ClearCreatedObjects()
    for _, obj in pairs(CreatedObjects) do
        pcall(function() obj:Destroy() end)
    end
    CreatedObjects = {}
end

local function DisableAllFunctions()
    for key, _ in pairs(State) do
        if key ~= "SelectedPlayer" then
            State[key] = false
        end
    end
    ClearConnections()
    ClearCreatedObjects()
    
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
    
    local hrp = GetHRP()
    if hrp then
        pcall(function()
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end)
    end
end

-- SISTEMA DE REDE
local function SetupNetworkControl()
    if AnchorPart then pcall(function() AnchorPart:Destroy() end) end
    
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
    
    -- OTIMIZAÇÃO: SimRadius em thread separada, não todo frame
    task.spawn(function()
        while true do
            pcall(function()
                if sethiddenproperty then
                    sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                end
                -- Tentar também o método alternativo
                if setsimulationradius then
                    setsimulationradius(math.huge, math.huge)
                end
            end)
            task.wait(0.5)  -- A cada 0.5s em vez de todo frame
        end
    end)
end

-- SISTEMA DE PARTES
local function GetUnanchoredParts()
    local parts = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
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

local function SetupPartControl(part, targetAttachment)
    if not part or not part:IsA("BasePart") then return end
    if part.Anchored then return end
    if part.Name:find("_NDS") then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and part:IsDescendantOf(player.Character) then
            if player == LocalPlayer then return end
        end
    end
    
    pcall(function()
        -- Remover nossos controles antigos
        local align = part:FindFirstChild("_NDSAlign")
        local attach = part:FindFirstChild("_NDSAttach")
        if align then align:Destroy() end
        if attach then attach:Destroy() end
        
        -- ANTI-COMPETICAO AGRESSIVA: Remover TODOS os controles de outros scripts
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("AlignPosition") or child:IsA("AlignOrientation") or
               child:IsA("BodyPosition") or child:IsA("BodyVelocity") or
               child:IsA("BodyForce") or child:IsA("BodyGyro") or
               child:IsA("VectorForce") or child:IsA("LineForce") or
               child:IsA("BodyAngularVelocity") or child:IsA("BodyThrust") or
               child:IsA("RocketPropulsion") or child:IsA("Torque") then
                child:Destroy()
            end
        end
        
        -- Remover Attachments genericos de outros scripts (nao os nossos)
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("Attachment") and not child.Name:find("_NDS") then
                child:Destroy()
            end
        end
    end)
    
    -- Configurar parte para controle total
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    
    -- Zerar propriedades fisicas para controle absoluto
    pcall(function()
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
    end)
    
    local attach = Instance.new("Attachment")
    attach.Name = "_NDSAttach"
    attach.Parent = part
    
    local align = Instance.new("AlignPosition")
    align.Name = "_NDSAlign"
    align.MaxForce = math.huge
    align.MaxVelocity = math.huge  -- VELOCIDADE INFINITA!
    align.Responsiveness = 300    -- Mais responsivo
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

-- FUNÇÕES DE TROLAGEM

local function ToggleMagnet()
    State.Magnet = not State.Magnet
    
    if State.Magnet then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Magnet = false
            return false, "Selecione um player!"
        end
        
        -- Lista de partes controladas (para evitar re-escanear todo workspace)
        local controlledParts = {}
        
        -- Captura inicial com otimizações
        for _, part in pairs(GetAvailableParts()) do
            -- Desligar propriedades que causam lag
            pcall(function()
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
            end)
            SetupPartControl(part, MainAttachment)
            controlledParts[part] = true
        end
        
        -- Captura instantanea de novas partes
        Connections.MagnetNew = Workspace.DescendantAdded:Connect(function(obj)
            if State.Magnet and obj:IsA("BasePart") then
                task.defer(function()
                    if not controlledParts[obj] then
                        pcall(function()
                            obj.CanCollide = false
                            obj.CanQuery = false
                            obj.CanTouch = false
                        end)
                        SetupPartControl(obj, MainAttachment)
                        controlledParts[obj] = true
                    end
                end)
            end
        end)
        
        -- Atualiza posicao do alvo (esse precisa ser todo frame para magnet funcionar bem)
        Connections.MagnetUpdate = RunService.Heartbeat:Connect(function()
            if State.Magnet and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and AnchorPart then
                    AnchorPart.CFrame = hrp.CFrame
                end
            end
        end)
        
        -- RE-CAPTURA OTIMIZADA: verifica apenas partes já controladas que perderam controle
        -- Intervalo maior (1s) e só verifica partes na lista, não todo workspace
        task.spawn(function()
            while State.Magnet do
                task.wait(1)  -- Aumentado de 0.5s para 1s
                if not State.Magnet then break end
                
                -- Verificar partes controladas que perderam o AlignPosition
                for part, _ in pairs(controlledParts) do
                    if part and part.Parent then
                        local align = part:FindFirstChild("_NDSAlign")
                        if not align then
                            SetupPartControl(part, MainAttachment)
                        end
                    else
                        -- Parte foi destruida, remover da lista
                        controlledParts[part] = nil
                    end
                end
            end
        end)
        
        return true, "Ima ativado!"
    else
        ClearConnections("Magnet")
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                CleanPartControl(part)
            end
        end
        return false, "Ima desativado"
    end
end

-- FUNÇÃO ESPECIAL PARA ORBIT (com valores mais fortes para competir)
local function SetupOrbitPartControl(part, targetAttachment)
    if not part or not part:IsA("BasePart") then return end
    if part.Anchored then return end
    if part.Name:find("_NDS") then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and part:IsDescendantOf(player.Character) then
            if player == LocalPlayer then return end
        end
    end
    
    pcall(function()
        -- Remover nossos controles antigos
        local align = part:FindFirstChild("_NDSAlign")
        local attach = part:FindFirstChild("_NDSAttach")
        if align then align:Destroy() end
        if attach then attach:Destroy() end
        
        -- ANTI-COMPETICAO AGRESSIVA: Remover TODOS os controles de outros scripts
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("AlignPosition") or child:IsA("AlignOrientation") or
               child:IsA("BodyPosition") or child:IsA("BodyVelocity") or
               child:IsA("BodyForce") or child:IsA("BodyGyro") or
               child:IsA("VectorForce") or child:IsA("LineForce") or
               child:IsA("BodyAngularVelocity") or child:IsA("BodyThrust") or
               child:IsA("RocketPropulsion") or child:IsA("Torque") then
                child:Destroy()
            end
        end
        
        -- Remover Attachments genericos de outros scripts
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("Attachment") and not child.Name:find("_NDS") then
                child:Destroy()
            end
        end
    end)
    
    -- Configurar parte para controle total
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    
    -- Zerar propriedades fisicas para controle absoluto
    pcall(function()
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
    end)
    
    local attach = Instance.new("Attachment")
    attach.Name = "_NDSAttach"
    attach.Parent = part
    
    local align = Instance.new("AlignPosition")
    align.Name = "_NDSAlign"
    align.MaxForce = math.huge
    align.MaxVelocity = math.huge  -- VELOCIDADE INFINITA!
    align.Responsiveness = 400    -- Mais responsivo para Orbit
    align.Attachment0 = attach
    align.Attachment1 = targetAttachment or MainAttachment
    align.Parent = part
    
    return attach, align
end

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
        local lastUpdate = 0  -- OTIMIZAÇÃO: Throttle
        
        -- Desligar propriedades que causam lag
        for i, part in pairs(parts) do
            pcall(function()
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
            end)
            
            local att = Instance.new("Attachment")
            att.Name = "_NDSOrbitAtt" .. i
            att.Parent = AnchorPart
            table.insert(CreatedObjects, att)
            
            SetupOrbitPartControl(part, att)  -- Usa função especial do Orbit
            partData[i] = {part = part, attachment = att, baseAngle = (i / #parts) * math.pi * 2}
        end
        
        -- OTIMIZAÇÃO: Usar throttling - atualiza apenas 20x por segundo em vez de 60
        Connections.OrbitUpdate = RunService.Heartbeat:Connect(function(dt)
            local now = tick()
            
            -- Sempre atualiza o ângulo para movimento suave
            angle = angle + dt * Config.OrbitSpeed
            
            -- Mas só atualiza posições a cada intervalo
            if now - lastUpdate < Config.OrbitUpdateInterval then return end
            lastUpdate = now
            
            if State.Orbit and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local hrpPos = hrp.Position  -- Cache da posição
                    for i, data in pairs(partData) do
                        if data.part and data.part.Parent and data.attachment then
                            local currentAngle = data.baseAngle + angle
                            local offset = Vector3.new(
                                math.cos(currentAngle) * Config.OrbitRadius,
                                Config.OrbitHeight + math.sin(currentAngle * 2) * 2,
                                math.sin(currentAngle) * Config.OrbitRadius
                            )
                            data.attachment.WorldPosition = hrpPos + offset
                        end
                    end
                end
            end
        end)
        
        -- SISTEMA DE RE-CAPTURA COMPETITIVA (SÓ PARA ORBIT)
        task.spawn(function()
            while State.Orbit do
                task.wait(Config.OrbitRecaptureInterval)
                if not State.Orbit then break end
                
                for i, data in pairs(partData) do
                    if data.part and data.part.Parent then
                        local align = data.part:FindFirstChild("_NDSAlign")
                        if not align then
                            -- Parte perdeu controle, re-capturar com função especial
                            SetupOrbitPartControl(data.part, data.attachment)
                        end
                    end
                end
            end
        end)
        
        return true, "Orbit ativado!"
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

-- FUNÇÃO SKY LIFT - DOMINANTE (levanta todas as partes para o céu)
local function ToggleSkyLift()
    State.SkyLift = not State.SkyLift
    
    if State.SkyLift then
        local parts = GetAvailableParts()
        local skyParts = {}
        local skyHeight = 3000  -- Altura alvo no céu
        
        -- Função para remover TODOS os controles de outros scripts
        local function RemoveAllControls(part)
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("AlignPosition") or child:IsA("AlignOrientation") or
                   child:IsA("BodyPosition") or child:IsA("BodyVelocity") or
                   child:IsA("BodyForce") or child:IsA("BodyGyro") or
                   child:IsA("VectorForce") or child:IsA("LineForce") or
                   child:IsA("BodyAngularVelocity") or child:IsA("BodyThrust") or
                   child:IsA("RocketPropulsion") or child:IsA("Torque") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
        
        -- Configurar cada parte
        for _, part in pairs(parts) do
            pcall(function()
                -- Remover controles de outros scripts
                RemoveAllControls(part)
                
                -- Zerar propriedades físicas para controle absoluto
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
                part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
                
                -- Criar BodyForce para cima (força constante baseada na massa)
                local bf = Instance.new("BodyForce")
                bf.Name = "_NDSSkyForce"
                bf.Force = Vector3.new(0, part:GetMass() * 5000, 0)  -- Força MUITO alta para cima
                bf.Parent = part
                table.insert(CreatedObjects, bf)
                
                -- Aplicar velocidade inicial para cima
                part.AssemblyLinearVelocity = Vector3.new(0, 500, 0)
                
                table.insert(skyParts, part)
            end)
        end
        
        -- Loop de proteção AGRESSIVO (a cada 0.1s)
        task.spawn(function()
            while State.SkyLift do
                task.wait(0.1)
                if not State.SkyLift then break end
                
                for _, part in pairs(skyParts) do
                    if part and part.Parent then
                        pcall(function()
                            -- Verificar se ainda tem nosso controle
                            local skyForce = part:FindFirstChild("_NDSSkyForce")
                            if not skyForce then
                                -- Remover controles de outros e reaplicar
                                RemoveAllControls(part)
                                
                                local bf = Instance.new("BodyForce")
                                bf.Name = "_NDSSkyForce"
                                bf.Force = Vector3.new(0, part:GetMass() * 5000, 0)
                                bf.Parent = part
                                table.insert(CreatedObjects, bf)
                            end
                            
                            -- Manter velocidade alta para cima
                            if part.Position.Y < skyHeight then
                                part.AssemblyLinearVelocity = Vector3.new(0, 500, 0)
                            end
                        end)
                    end
                end
            end
        end)
        
        Notify("Sky Lift", "Partes sendo levantadas para o céu!", 3)
        return true, "Sky Lift ativado!"
    else
        -- Desativar
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                local skyForce = part:FindFirstChild("_NDSSkyForce")
                if skyForce then
                    pcall(function() skyForce:Destroy() end)
                end
            end
        end
        return false, "Sky Lift desativado"
    end
end

-- FUNÇÃO SERVER MAGNET - Distribui partes entre TODOS os players simultaneamente
local function ToggleServerMagnet()
    State.ServerMagnet = not State.ServerMagnet
    
    if State.ServerMagnet then
        -- Pegar todos os players exceto o local
        local function GetTargetPlayers()
            local targets = {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        table.insert(targets, player)
                    end
                end
            end
            return targets
        end
        
        -- Estrutura para controlar partes por player
        local playerAttachments = {}  -- {player = attachment}
        local partAssignments = {}    -- {part = player}
        local controlledParts = {}    -- Lista de partes controladas
        
        -- Criar attachment para cada player
        local function SetupPlayerAttachments()
            -- Limpar attachments antigos
            for player, att in pairs(playerAttachments) do
                if att and att.Parent then
                    pcall(function() att:Destroy() end)
                end
            end
            playerAttachments = {}
            
            local targets = GetTargetPlayers()
            for i, player in pairs(targets) do
                local att = Instance.new("Attachment")
                att.Name = "_NDSServerMagnetAtt" .. i
                att.Parent = AnchorPart
                table.insert(CreatedObjects, att)
                playerAttachments[player] = att
            end
            
            return targets
        end
        
        -- Função para configurar controle de parte com anti-competição
        local function SetupServerMagnetPart(part, targetAttachment)
            if not part or not part:IsA("BasePart") then return end
            if part.Anchored then return end
            if part.Name:find("_NDS") then return end
            
            -- Ignorar partes de jogadores
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and part:IsDescendantOf(player.Character) then
                    return
                end
            end
            
            pcall(function()
                -- ANTI-COMPETIÇÃO: Remover TODOS os controles de outros scripts
                for _, child in pairs(part:GetChildren()) do
                    if child:IsA("AlignPosition") or child:IsA("AlignOrientation") or
                       child:IsA("BodyPosition") or child:IsA("BodyVelocity") or
                       child:IsA("BodyForce") or child:IsA("BodyGyro") or
                       child:IsA("VectorForce") or child:IsA("LineForce") or
                       child:IsA("BodyAngularVelocity") or child:IsA("BodyThrust") or
                       child:IsA("RocketPropulsion") or child:IsA("Torque") then
                        child:Destroy()
                    end
                end
                
                -- Remover Attachments de outros scripts
                for _, child in pairs(part:GetChildren()) do
                    if child:IsA("Attachment") and not child.Name:find("_NDS") then
                        child:Destroy()
                    end
                end
                
                -- Remover nossos controles antigos
                local oldAlign = part:FindFirstChild("_NDSServerAlign")
                local oldAttach = part:FindFirstChild("_NDSServerAttach")
                if oldAlign then oldAlign:Destroy() end
                if oldAttach then oldAttach:Destroy() end
            end)
            
            -- Configurar parte para controle total
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            
            -- Zerar propriedades físicas
            pcall(function()
                part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end)
            
            local attach = Instance.new("Attachment")
            attach.Name = "_NDSServerAttach"
            attach.Parent = part
            
            local align = Instance.new("AlignPosition")
            align.Name = "_NDSServerAlign"
            align.MaxForce = math.huge
            align.MaxVelocity = math.huge
            align.Responsiveness = 300
            align.Attachment0 = attach
            align.Attachment1 = targetAttachment
            align.Parent = part
            
            return attach, align
        end
        
        -- Distribuir partes entre players de forma inteligente
        local function DistributeParts()
            local targets = GetTargetPlayers()
            if #targets == 0 then return end
            
            -- Atualizar attachments se players mudaram
            SetupPlayerAttachments()
            
            local parts = GetAvailableParts()
            local playerIndex = 1
            
            -- Distribuir cada parte para um player diferente (rotação)
            for _, part in pairs(parts) do
                if not controlledParts[part] then
                    local targetPlayer = targets[playerIndex]
                    local targetAtt = playerAttachments[targetPlayer]
                    
                    if targetAtt then
                        SetupServerMagnetPart(part, targetAtt)
                        partAssignments[part] = targetPlayer
                        controlledParts[part] = true
                    end
                    
                    -- Próximo player (rotação circular)
                    playerIndex = playerIndex + 1
                    if playerIndex > #targets then
                        playerIndex = 1
                    end
                end
            end
        end
        
        -- Captura inicial
        DistributeParts()
        
        -- Captura de novas partes
        Connections.ServerMagnetNew = Workspace.DescendantAdded:Connect(function(obj)
            if State.ServerMagnet and obj:IsA("BasePart") then
                task.defer(function()
                    if not controlledParts[obj] then
                        local targets = GetTargetPlayers()
                        if #targets > 0 then
                            -- Escolher player com menos partes
                            local partCounts = {}
                            for _, player in pairs(targets) do
                                partCounts[player] = 0
                            end
                            for part, player in pairs(partAssignments) do
                                if part and part.Parent and partCounts[player] then
                                    partCounts[player] = partCounts[player] + 1
                                end
                            end
                            
                            -- Encontrar player com menos partes
                            local minPlayer = targets[1]
                            local minCount = math.huge
                            for player, count in pairs(partCounts) do
                                if count < minCount then
                                    minCount = count
                                    minPlayer = player
                                end
                            end
                            
                            local targetAtt = playerAttachments[minPlayer]
                            if targetAtt then
                                SetupServerMagnetPart(obj, targetAtt)
                                partAssignments[obj] = minPlayer
                                controlledParts[obj] = true
                            end
                        end
                    end
                end)
            end
        end)
        
        -- Atualiza posição dos attachments para seguir os players
        Connections.ServerMagnetUpdate = RunService.Heartbeat:Connect(function()
            if State.ServerMagnet then
                for player, att in pairs(playerAttachments) do
                    if player and player.Character and att and att.Parent then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            att.WorldPosition = hrp.Position
                        end
                    end
                end
            end
        end)
        
        -- Re-captura e redistribuição periódica
        task.spawn(function()
            while State.ServerMagnet do
                task.wait(1)
                if not State.ServerMagnet then break end
                
                -- Verificar se players mudaram
                local currentTargets = GetTargetPlayers()
                local needsRedistribute = false
                
                -- Verificar se algum player saiu ou entrou
                for player, _ in pairs(playerAttachments) do
                    if not player or not player.Parent or not player.Character then
                        needsRedistribute = true
                        break
                    end
                end
                
                for _, player in pairs(currentTargets) do
                    if not playerAttachments[player] then
                        needsRedistribute = true
                        break
                    end
                end
                
                if needsRedistribute then
                    -- Limpar e redistribuir
                    partAssignments = {}
                    controlledParts = {}
                    DistributeParts()
                else
                    -- Apenas re-capturar partes que perderam controle
                    for part, player in pairs(partAssignments) do
                        if part and part.Parent then
                            local align = part:FindFirstChild("_NDSServerAlign")
                            if not align then
                                local targetAtt = playerAttachments[player]
                                if targetAtt then
                                    SetupServerMagnetPart(part, targetAtt)
                                end
                            end
                        else
                            -- Parte foi destruída
                            partAssignments[part] = nil
                            controlledParts[part] = nil
                        end
                    end
                end
            end
        end)
        
        local targetCount = #GetTargetPlayers()
        Notify("Server Magnet", "Atacando " .. targetCount .. " players!", 3)
        return true, "Server Magnet ativado! (" .. targetCount .. " alvos)"
    else
        ClearConnections("ServerMagnet")
        
        -- Limpar controles
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    local align = part:FindFirstChild("_NDSServerAlign")
                    local attach = part:FindFirstChild("_NDSServerAttach")
                    if align then align:Destroy() end
                    if attach then attach:Destroy() end
                    part.CanCollide = true
                end)
            end
        end
        
        return false, "Server Magnet desativado"
    end
end

local function ToggleBlackhole()
    State.Blackhole = not State.Blackhole
    
    if State.Blackhole then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Blackhole = false
            return false, "Selecione um player!"
        end
        
        local angle = 0
        local lastUpdate = 0  -- OTIMIZAÇÃO: Throttle
        
        for _, part in pairs(GetAvailableParts()) do
            -- Desligar propriedades que causam lag
            pcall(function()
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
            end)
            
            SetupPartControl(part, MainAttachment)
            local torque = Instance.new("Torque")
            torque.Name = "_NDSTorque"
            torque.Torque = Vector3.new(50000, 50000, 50000)
            local att = part:FindFirstChild("_NDSAttach")
            if att then torque.Attachment0 = att end
            torque.Parent = part
        end
        
        -- OTIMIZAÇÃO: Usar throttling
        Connections.BlackholeUpdate = RunService.Heartbeat:Connect(function(dt)
            local now = tick()
            
            -- Sempre atualiza o ângulo
            angle = angle + dt * 5
            
            -- Mas só atualiza posição a cada intervalo
            if now - lastUpdate < Config.BlackholeUpdateInterval then return end
            lastUpdate = now
            
            if State.Blackhole and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and AnchorPart then
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

local function TogglePartRain()
    State.PartRain = not State.PartRain
    
    if State.PartRain then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.PartRain = false
            return false, "Selecione um player!"
        end
        
        for _, part in pairs(GetAvailableParts()) do
            SetupPartControl(part, MainAttachment)
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
        local lastUpdate = 0  -- OTIMIZAÇÃO: Throttle
        
        for i, part in pairs(parts) do
            -- Desligar propriedades que causam lag
            pcall(function()
                part.CanCollide = false
                part.CanQuery = false
                part.CanTouch = false
            end)
            
            local att = Instance.new("Attachment")
            att.Name = "_NDSSpinAtt" .. i
            att.Parent = AnchorPart
            table.insert(CreatedObjects, att)
            
            SetupPartControl(part, att)
            partData[i] = {part = part, attachment = att, baseAngle = (i / #parts) * math.pi * 2}
        end
        
        -- OTIMIZAÇÃO: Usar throttling
        Connections.SpinUpdate = RunService.Heartbeat:Connect(function(dt)
            local now = tick()
            
            -- Sempre atualiza o ângulo
            angle = angle + dt * Config.SpinSpeed
            
            -- Mas só atualiza posições a cada intervalo
            if now - lastUpdate < Config.SpinUpdateInterval then return end
            lastUpdate = now
            
            if State.Spin and State.SelectedPlayer and State.SelectedPlayer.Character then
                local hrp = State.SelectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local hrpPos = hrp.Position  -- Cache da posição
                    for i, data in pairs(partData) do
                        if data.part and data.part.Parent and data.attachment then
                            local currentAngle = data.baseAngle + angle
                            local offset = Vector3.new(
                                math.cos(currentAngle) * Config.SpinRadius,
                                1,
                                math.sin(currentAngle) * Config.SpinRadius
                            )
                            data.attachment.WorldPosition = hrpPos + offset
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
            
            SetupPartControl(part, att)
            
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

local function ToggleHatFling()
    State.HatFling = not State.HatFling
    
    if State.HatFling then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.HatFling = false
            return false, "Selecione um player!"
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

local function ToggleLaunch()
    State.Launch = not State.Launch
    
    if State.Launch then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.Launch = false
            return false, "Selecione um player!"
        end
        
        for _, part in pairs(GetAvailableParts()) do
            SetupPartControl(part, MainAttachment)
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

local function ToggleSlowPlayer()
    State.SlowPlayer = not State.SlowPlayer
    
    if State.SlowPlayer then
        if not State.SelectedPlayer or not State.SelectedPlayer.Character then
            State.SlowPlayer = false
            return false, "Selecione um player!"
        end
        
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

-- UTILIDADES

local function ToggleGodMode()
    State.GodMode = not State.GodMode
    
    if State.GodMode then
        local char = GetCharacter()
        local humanoid = GetHumanoid()
        
        if not char or not humanoid then
            State.GodMode = false
            return false, "Erro!"
        end
        
        local ff = Instance.new("ForceField")
        ff.Name = "_NDSForceField"
        ff.Visible = false
        ff.Parent = char
        table.insert(CreatedObjects, ff)
        
        Connections.GodModeHealth = humanoid.HealthChanged:Connect(function()
            if State.GodMode then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
        
        Connections.GodModeHeartbeat = RunService.Heartbeat:Connect(function()
            if State.GodMode then
                local hum = GetHumanoid()
                if hum then
                    hum.Health = hum.MaxHealth
                end
                local c = GetCharacter()
                if c and not c:FindFirstChild("_NDSForceField") then
                    local newFF = Instance.new("ForceField")
                    newFF.Name = "_NDSForceField"
                    newFF.Visible = false
                    newFF.Parent = c
                end
            end
        end)
        
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end)
        
        return true, "God Mode ativado!"
    else
        ClearConnections("GodMode")
        local char = GetCharacter()
        if char then
            local ff = char:FindFirstChild("_NDSForceField")
            if ff then ff:Destroy() end
        end
        local humanoid = GetHumanoid()
        if humanoid then
            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            end)
        end
        return false, "God Mode desativado"
    end
end

-- FLY GUI V3 - Sistema completo
local FlyV3 = {
    GUI = nil,
    Loaded = false,
    Flying = false,
    Speed = 1,
    TpWalking = false,
    Ctrl = {f = 0, b = 0, l = 0, r = 0}
}

local function CreateFlyGuiV3()
    if FlyV3.GUI then FlyV3.GUI:Destroy() end
    FlyV3.Loaded = true
    
    local main = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local up = Instance.new("TextButton")
    local down = Instance.new("TextButton")
    local onof = Instance.new("TextButton")
    local TextLabel = Instance.new("TextLabel")
    local plus = Instance.new("TextButton")
    local speedLabel = Instance.new("TextLabel")
    local mine = Instance.new("TextButton")
    local closebutton = Instance.new("TextButton")
    local mini = Instance.new("TextButton")
    local mini2 = Instance.new("TextButton")
    
    main.Name = "NDSFlyGuiV3"
    main.Parent = LocalPlayer:WaitForChild("PlayerGui")
    main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    main.ResetOnSpawn = false
    FlyV3.GUI = main
    
    Frame.Parent = main
    Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
    Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
    Frame.Position = UDim2.new(0.1, 0, 0.38, 0)
    Frame.Size = UDim2.new(0, 190, 0, 57)
    Frame.Active = true
    Frame.Draggable = true
    
    up.Name = "up"
    up.Parent = Frame
    up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
    up.Size = UDim2.new(0, 44, 0, 28)
    up.Font = Enum.Font.SourceSans
    up.Text = "UP"
    up.TextColor3 = Color3.fromRGB(0, 0, 0)
    up.TextSize = 14
    
    down.Name = "down"
    down.Parent = Frame
    down.BackgroundColor3 = Color3.fromRGB(215, 255, 121)
    down.Position = UDim2.new(0, 0, 0.491, 0)
    down.Size = UDim2.new(0, 44, 0, 28)
    down.Font = Enum.Font.SourceSans
    down.Text = "DOWN"
    down.TextColor3 = Color3.fromRGB(0, 0, 0)
    down.TextSize = 14
    
    onof.Name = "onof"
    onof.Parent = Frame
    onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
    onof.Position = UDim2.new(0.703, 0, 0.491, 0)
    onof.Size = UDim2.new(0, 56, 0, 28)
    onof.Font = Enum.Font.SourceSans
    onof.Text = "fly"
    onof.TextColor3 = Color3.fromRGB(0, 0, 0)
    onof.TextSize = 14
    
    TextLabel.Parent = Frame
    TextLabel.BackgroundColor3 = Color3.fromRGB(242, 60, 255)
    TextLabel.Position = UDim2.new(0.469, 0, 0, 0)
    TextLabel.Size = UDim2.new(0, 100, 0, 28)
    TextLabel.Font = Enum.Font.SourceSans
    TextLabel.Text = "FLY GUI V3"
    TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextScaled = true
    
    plus.Name = "plus"
    plus.Parent = Frame
    plus.BackgroundColor3 = Color3.fromRGB(133, 145, 255)
    plus.Position = UDim2.new(0.232, 0, 0, 0)
    plus.Size = UDim2.new(0, 45, 0, 28)
    plus.Font = Enum.Font.SourceSans
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(0, 0, 0)
    plus.TextScaled = true
    
    speedLabel.Name = "speed"
    speedLabel.Parent = Frame
    speedLabel.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
    speedLabel.Position = UDim2.new(0.468, 0, 0.491, 0)
    speedLabel.Size = UDim2.new(0, 44, 0, 28)
    speedLabel.Font = Enum.Font.SourceSans
    speedLabel.Text = "1"
    speedLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    speedLabel.TextScaled = true
    
    mine.Name = "mine"
    mine.Parent = Frame
    mine.BackgroundColor3 = Color3.fromRGB(123, 255, 247)
    mine.Position = UDim2.new(0.232, 0, 0.491, 0)
    mine.Size = UDim2.new(0, 45, 0, 29)
    mine.Font = Enum.Font.SourceSans
    mine.Text = "-"
    mine.TextColor3 = Color3.fromRGB(0, 0, 0)
    mine.TextScaled = true
    
    closebutton.Name = "Close"
    closebutton.Parent = Frame
    closebutton.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
    closebutton.Font = Enum.Font.SourceSans
    closebutton.Size = UDim2.new(0, 45, 0, 28)
    closebutton.Text = "X"
    closebutton.TextSize = 30
    closebutton.Position = UDim2.new(0, 0, -1, 27)
    closebutton.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    mini.Name = "minimize"
    mini.Parent = Frame
    mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
    mini.Font = Enum.Font.SourceSans
    mini.Size = UDim2.new(0, 45, 0, 28)
    mini.Text = "-"
    mini.TextSize = 40
    mini.Position = UDim2.new(0, 44, -1, 27)
    mini.TextColor3 = Color3.fromRGB(0, 0, 0)
    
    mini2.Name = "minimize2"
    mini2.Parent = Frame
    mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
    mini2.Font = Enum.Font.SourceSans
    mini2.Size = UDim2.new(0, 45, 0, 28)
    mini2.Text = "+"
    mini2.TextSize = 40
    mini2.Position = UDim2.new(0, 44, -1, 57)
    mini2.Visible = false
    mini2.TextColor3 = Color3.fromRGB(0, 0, 0)
    
    -- Variáveis locais
    local speeds = 1
    local nowe = false
    local tpwalking = false
    local ctrl = {f = 0, b = 0, l = 0, r = 0}
    local lastctrl = {f = 0, b = 0, l = 0, r = 0}
    local bg, bv
    
    -- Função para iniciar TP Walking
    local function startTpWalking()
        for i = 1, speeds do
            task.spawn(function()
                local hb = RunService.Heartbeat
                tpwalking = true
                local chr = GetCharacter()
                local hum = GetHumanoid()
                while tpwalking and chr and hum and hum.Parent do
                    hb:Wait()
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
    end
    
    -- Função para habilitar/desabilitar estados do Humanoid
    local function setHumanoidStates(enabled)
        local hum = GetHumanoid()
        if not hum then return end
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Flying, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, enabled)
        if enabled then
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        else
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
        end
    end
    
    -- Botão Fly ON/OFF
    onof.MouseButton1Down:Connect(function()
        local char = GetCharacter()
        local hum = GetHumanoid()
        if not char or not hum then return end
        
        if nowe == true then
            -- Desligar fly
            nowe = false
            FlyV3.Flying = false
            State.Fly = false
            setHumanoidStates(true)
            tpwalking = false
            ctrl = {f = 0, b = 0, l = 0, r = 0}
            lastctrl = {f = 0, b = 0, l = 0, r = 0}
            if bg then bg:Destroy() bg = nil end
            if bv then bv:Destroy() bv = nil end
            hum.PlatformStand = false
            local animate = char:FindFirstChild("Animate")
            if animate then animate.Disabled = false end
            ClearConnections("FlyV3")
            return
        else
            -- Ligar fly
            nowe = true
            FlyV3.Flying = true
            State.Fly = true
            startTpWalking()
            local animate = char:FindFirstChild("Animate")
            if animate then animate.Disabled = true end
            
            -- Parar animações
            for _, v in pairs(hum:GetPlayingAnimationTracks()) do
                v:AdjustSpeed(0)
            end
            setHumanoidStates(false)
        end
        
        -- Detectar tipo de rig (R6 ou R15)
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not torso then return end
        
        local maxspeed = 50
        local speed = 0
        
        bg = Instance.new("BodyGyro", torso)
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = torso.CFrame
        
        bv = Instance.new("BodyVelocity", torso)
        bv.Velocity = Vector3.new(0, 0.1, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        hum.PlatformStand = true
        
        -- Keybinds
        Connections.FlyV3KeyDown = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.W then ctrl.f = 1 end
            if input.KeyCode == Enum.KeyCode.S then ctrl.b = -1 end
            if input.KeyCode == Enum.KeyCode.A then ctrl.l = -1 end
            if input.KeyCode == Enum.KeyCode.D then ctrl.r = 1 end
        end)
        
        Connections.FlyV3KeyUp = UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.W then ctrl.f = 0 end
            if input.KeyCode == Enum.KeyCode.S then ctrl.b = 0 end
            if input.KeyCode == Enum.KeyCode.A then ctrl.l = 0 end
            if input.KeyCode == Enum.KeyCode.D then ctrl.r = 0 end
        end)
        
        -- Loop de voo
        Connections.FlyV3Loop = RunService.RenderStepped:Connect(function()
            if not nowe or not bv or not bg or hum.Health == 0 then return end
            
            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed + 0.5 + (speed / maxspeed)
                if speed > maxspeed then speed = maxspeed end
            elseif speed ~= 0 then
                speed = speed - 1
                if speed < 0 then speed = 0 end
            end
            
            local cam = workspace.CurrentCamera
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.Velocity = ((cam.CFrame.LookVector * (ctrl.f + ctrl.b)) + ((cam.CFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).Position) - cam.CFrame.Position)) * speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                bv.Velocity = ((cam.CFrame.LookVector * (lastctrl.f + lastctrl.b)) + ((cam.CFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).Position) - cam.CFrame.Position)) * speed
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end
            
            bg.CFrame = cam.CFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
        end)
    end)
    
    -- Botões UP/DOWN
    local upConnection, downConnection
    
    up.MouseButton1Down:Connect(function()
        upConnection = up.MouseEnter:Connect(function()
            while upConnection do
                task.wait()
                local hrp = GetHRP()
                if hrp then
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, 1, 0)
                end
            end
        end)
    end)
    
    up.MouseLeave:Connect(function()
        if upConnection then
            upConnection:Disconnect()
            upConnection = nil
        end
    end)
    
    down.MouseButton1Down:Connect(function()
        downConnection = down.MouseEnter:Connect(function()
            while downConnection do
                task.wait()
                local hrp = GetHRP()
                if hrp then
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, -1, 0)
                end
            end
        end)
    end)
    
    down.MouseLeave:Connect(function()
        if downConnection then
            downConnection:Disconnect()
            downConnection = nil
        end
    end)
    
    -- Botões de velocidade
    plus.MouseButton1Down:Connect(function()
        speeds = speeds + 1
        speedLabel.Text = tostring(speeds)
        if nowe then
            tpwalking = false
            task.wait(0.1)
            startTpWalking()
        end
    end)
    
    mine.MouseButton1Down:Connect(function()
        if speeds == 1 then
            speedLabel.Text = "min!"
            task.wait(1)
            speedLabel.Text = tostring(speeds)
        else
            speeds = speeds - 1
            speedLabel.Text = tostring(speeds)
            if nowe then
                tpwalking = false
                task.wait(0.1)
                startTpWalking()
            end
        end
    end)
    
    -- Botão fechar
    closebutton.MouseButton1Click:Connect(function()
        if nowe then
            nowe = false
            FlyV3.Flying = false
            State.Fly = false
            tpwalking = false
            local hum = GetHumanoid()
            local char = GetCharacter()
            if hum then
                hum.PlatformStand = false
                setHumanoidStates(true)
            end
            if char then
                local animate = char:FindFirstChild("Animate")
                if animate then animate.Disabled = false end
            end
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
            ClearConnections("FlyV3")
        end
        FlyV3.Loaded = false
        FlyV3.GUI = nil
        main:Destroy()
    end)
    
    -- Botões minimizar
    mini.MouseButton1Click:Connect(function()
        up.Visible = false
        down.Visible = false
        onof.Visible = false
        plus.Visible = false
        speedLabel.Visible = false
        mine.Visible = false
        mini.Visible = false
        mini2.Visible = true
        Frame.BackgroundTransparency = 1
        closebutton.Position = UDim2.new(0, 0, -1, 57)
    end)
    
    mini2.MouseButton1Click:Connect(function()
        up.Visible = true
        down.Visible = true
        onof.Visible = true
        plus.Visible = true
        speedLabel.Visible = true
        mine.Visible = true
        mini.Visible = true
        mini2.Visible = false
        Frame.BackgroundTransparency = 0
        closebutton.Position = UDim2.new(0, 0, -1, 27)
    end)
    
    -- Handler de respawn
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.7)
        local hum = newChar:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        local animate = newChar:FindFirstChild("Animate")
        if animate then animate.Disabled = false end
        nowe = false
        FlyV3.Flying = false
        State.Fly = false
        tpwalking = false
    end)
    
    return main
end

local function ToggleFly()
    if not FlyV3.Loaded then
        CreateFlyGuiV3()
        return true, "Fly GUI V3 aberto!"
    else
        if FlyV3.GUI then
            FlyV3.GUI:Destroy()
        end
        FlyV3.Loaded = false
        FlyV3.GUI = nil
        State.Fly = false
        return false, "Fly GUI V3 fechado"
    end
end

-- FUNÇÃO VIEW: Ver player selecionado (atualiza quando morre/respawna)
local function ToggleView()
    State.View = not State.View
    
    if State.View then
        if not State.SelectedPlayer then
            State.View = false
            return false, "Selecione um player!"
        end
        
        local targetPlayer = State.SelectedPlayer
        local originalCameraSubject = Camera.CameraSubject
        
        -- Função para atualizar a câmera para o personagem atual do player
        local function UpdateCameraTarget()
            if not State.View then return end
            if not targetPlayer or not targetPlayer.Parent then
                -- Player saiu do jogo
                State.View = false
                Camera.CameraSubject = GetHumanoid()
                ClearConnections("View")
                Notify("View", "Player saiu do jogo", 2)
                return
            end
            
            local targetChar = targetPlayer.Character
            if targetChar then
                local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
                if targetHumanoid then
                    Camera.CameraSubject = targetHumanoid
                end
            end
        end
        
        -- Atualizar câmera inicial
        UpdateCameraTarget()
        
        -- Monitorar quando o player respawna (CharacterAdded)
        Connections.ViewCharacterAdded = targetPlayer.CharacterAdded:Connect(function(newChar)
            task.wait(0.1)  -- Pequeno delay para o Humanoid carregar
            UpdateCameraTarget()
        end)
        
        -- Monitorar se o player sai do jogo
        Connections.ViewPlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            if player == targetPlayer then
                State.View = false
                Camera.CameraSubject = GetHumanoid()
                ClearConnections("View")
                Notify("View", "Player saiu do jogo", 2)
            end
        end)
        
        -- Loop de segurança para garantir que a câmera está sempre no alvo
        task.spawn(function()
            while State.View do
                task.wait(0.5)
                if State.View and targetPlayer and targetPlayer.Parent then
                    UpdateCameraTarget()
                end
            end
        end)
        
        return true, "View ativado em " .. targetPlayer.Name
    else
        ClearConnections("View")
        -- Voltar câmera para o próprio player
        local myHumanoid = GetHumanoid()
        if myHumanoid then
            Camera.CameraSubject = myHumanoid
        end
        return false, "View desativado"
    end
end

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
        
        return true, "Speed ativado!"
    else
        ClearConnections("Speed")
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = originalSpeed
        end
        return false, "Speed desativado"
    end
end

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

local function ToggleTelekinesis()
    State.Telekinesis = not State.Telekinesis
    
    if State.Telekinesis then
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
                        pcall(function() part.Anchored = false end)
                        SetupPartControl(part, MainAttachment)
                        Notify("Telecinese", "Objeto: " .. part.Name, 2)
                    end
                end
            end
        end)
        
        Connections.TelekMove = RunService.RenderStepped:Connect(function()
            if State.Telekinesis and TelekinesisTarget and TelekinesisTarget.Parent then
                local mousePos = UserInputService:GetMouseLocation()
                local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
                local targetPos = ray.Origin + ray.Direction * TelekinesisDistance
                if AnchorPart then
                    AnchorPart.CFrame = CFrame.new(targetPos)
                end
                if indicator and indicator.Parent then
                    indicator.CFrame = CFrame.new(targetPos)
                end
            end
        end)
        
        Connections.TelekScroll = UserInputService.InputChanged:Connect(function(input)
            if State.Telekinesis and input.UserInputType == Enum.UserInputType.MouseWheel then
                TelekinesisDistance = math.clamp(TelekinesisDistance + input.Position.Z * 5, 5, 100)
            end
        end)
        
        Connections.TelekRelease = UserInputService.InputBegan:Connect(function(input)
            if State.Telekinesis and input.UserInputType == Enum.UserInputType.MouseButton2 then
                if TelekinesisTarget then
                    CleanPartControl(TelekinesisTarget)
                    TelekinesisTarget = nil
                    Notify("Telecinese", "Solto!", 1)
                end
            end
        end)
        
        return true, "Telecinese ativada!"
    else
        ClearConnections("Telek")
        if TelekinesisTarget then
            CleanPartControl(TelekinesisTarget)
            TelekinesisTarget = nil
        end
        return false, "Telecinese desativada"
    end
end

-- RECONEXÃO AO RESPAWNAR
LocalPlayer.CharacterAdded:Connect(function()
    DisableAllFunctions()
    task.wait(1)
    SetupNetworkControl()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- INTERFACE DO USUÁRIO (REESCRITA COMPLETAMENTE)
-- ═══════════════════════════════════════════════════════════════════════════

local function CreateUI()
    -- Remover UI existente
    pcall(function() game:GetService("CoreGui"):FindFirstChild("NDSTrollHub"):Destroy() end)
    pcall(function() LocalPlayer.PlayerGui:FindFirstChild("NDSTrollHub"):Destroy() end)
    
    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NDSTrollHub"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Cores
    local BgColor = Color3.fromRGB(20, 20, 25)
    local SecondaryColor = Color3.fromRGB(30, 30, 38)
    local AccentColor = Color3.fromRGB(138, 43, 226)
    local TextColor = Color3.fromRGB(255, 255, 255)
    local DimColor = Color3.fromRGB(120, 120, 120)
    local SuccessColor = Color3.fromRGB(50, 205, 50)
    
    -- Frame Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 320, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
    MainFrame.BackgroundColor3 = BgColor
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = AccentColor
    MainStroke.Thickness = 2
    MainStroke.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = SecondaryColor
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 10)
    HeaderCorner.Parent = Header
    
    -- Fix para cantos do header
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 10)
    HeaderFix.Position = UDim2.new(0, 0, 1, -10)
    HeaderFix.BackgroundColor3 = SecondaryColor
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "NDS Troll Hub v7.5 SERVER MAGNET"
    Title.TextColor3 = TextColor
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Botão Minimizar
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
    MinimizeBtn.BackgroundColor3 = AccentColor
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = TextColor
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 18
    MinimizeBtn.Parent = Header
    
    local MinBtnCorner = Instance.new("UICorner")
    MinBtnCorner.CornerRadius = UDim.new(0, 6)
    MinBtnCorner.Parent = MinimizeBtn
    
    -- Botão Fechar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = TextColor
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = Header
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 6)
    CloseBtnCorner.Parent = CloseBtn
    
    -- Container de Conteúdo
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -20, 1, -50)
    ContentFrame.Position = UDim2.new(0, 10, 0, 45)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Seção de Seleção de Player
    local PlayerSection = Instance.new("Frame")
    PlayerSection.Name = "PlayerSection"
    PlayerSection.Size = UDim2.new(1, 0, 0, 100)
    PlayerSection.BackgroundColor3 = SecondaryColor
    PlayerSection.BorderSizePixel = 0
    PlayerSection.Parent = ContentFrame
    
    local PlayerSectionCorner = Instance.new("UICorner")
    PlayerSectionCorner.CornerRadius = UDim.new(0, 8)
    PlayerSectionCorner.Parent = PlayerSection
    
    local PlayerLabel = Instance.new("TextLabel")
    PlayerLabel.Size = UDim2.new(1, -10, 0, 20)
    PlayerLabel.Position = UDim2.new(0, 5, 0, 5)
    PlayerLabel.BackgroundTransparency = 1
    PlayerLabel.Text = "Selecionar Player:"
    PlayerLabel.TextColor3 = DimColor
    PlayerLabel.Font = Enum.Font.Gotham
    PlayerLabel.TextSize = 11
    PlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
    PlayerLabel.Parent = PlayerSection
    
    -- ScrollingFrame para lista de players
    local PlayerList = Instance.new("ScrollingFrame")
    PlayerList.Name = "PlayerList"
    PlayerList.Size = UDim2.new(1, -10, 0, 50)
    PlayerList.Position = UDim2.new(0, 5, 0, 25)
    PlayerList.BackgroundColor3 = BgColor
    PlayerList.BorderSizePixel = 0
    PlayerList.ScrollBarThickness = 4
    PlayerList.ScrollBarImageColor3 = AccentColor
    PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    PlayerList.Parent = PlayerSection
    
    local PlayerListCorner = Instance.new("UICorner")
    PlayerListCorner.CornerRadius = UDim.new(0, 6)
    PlayerListCorner.Parent = PlayerList
    
    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.SortOrder = Enum.SortOrder.Name
    PlayerListLayout.Padding = UDim.new(0, 3)
    PlayerListLayout.Parent = PlayerList
    
    local PlayerListPadding = Instance.new("UIPadding")
    PlayerListPadding.PaddingTop = UDim.new(0, 3)
    PlayerListPadding.PaddingBottom = UDim.new(0, 3)
    PlayerListPadding.PaddingLeft = UDim.new(0, 3)
    PlayerListPadding.PaddingRight = UDim.new(0, 3)
    PlayerListPadding.Parent = PlayerList
    
    -- Status do player selecionado
    local SelectedStatus = Instance.new("TextLabel")
    SelectedStatus.Name = "SelectedStatus"
    SelectedStatus.Size = UDim2.new(1, -10, 0, 18)
    SelectedStatus.Position = UDim2.new(0, 5, 1, -22)
    SelectedStatus.BackgroundTransparency = 1
    SelectedStatus.Text = "Nenhum selecionado"
    SelectedStatus.TextColor3 = DimColor
    SelectedStatus.Font = Enum.Font.Gotham
    SelectedStatus.TextSize = 10
    SelectedStatus.TextXAlignment = Enum.TextXAlignment.Left
    SelectedStatus.Parent = PlayerSection
    
    -- Função para atualizar lista de players
    local function UpdatePlayerList()
        for _, child in pairs(PlayerList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            local btn = Instance.new("TextButton")
            btn.Name = player.Name
            btn.Size = UDim2.new(1, -6, 0, 22)
            btn.BackgroundColor3 = State.SelectedPlayer == player and AccentColor or SecondaryColor
            btn.Text = player.DisplayName
            btn.TextColor3 = TextColor
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 10
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            btn.Parent = PlayerList
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                State.SelectedPlayer = player
                SelectedStatus.Text = "Selecionado: " .. player.DisplayName
                SelectedStatus.TextColor3 = SuccessColor
                UpdatePlayerList()
                Notify("Player", player.DisplayName, 1)
            end)
        end
    end
    
    UpdatePlayerList()
    Players.PlayerAdded:Connect(UpdatePlayerList)
    Players.PlayerRemoving:Connect(UpdatePlayerList)
    
    -- ScrollFrame para botões
    local ButtonsScroll = Instance.new("ScrollingFrame")
    ButtonsScroll.Name = "ButtonsScroll"
    ButtonsScroll.Size = UDim2.new(1, 0, 1, -110)
    ButtonsScroll.Position = UDim2.new(0, 0, 0, 105)
    ButtonsScroll.BackgroundTransparency = 1
    ButtonsScroll.BorderSizePixel = 0
    ButtonsScroll.ScrollBarThickness = 4
    ButtonsScroll.ScrollBarImageColor3 = AccentColor
    ButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ButtonsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ButtonsScroll.Parent = ContentFrame
    
    local ButtonsLayout = Instance.new("UIListLayout")
    ButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ButtonsLayout.Padding = UDim.new(0, 5)
    ButtonsLayout.Parent = ButtonsScroll
    
    -- Tabela para armazenar indicadores de status
    local StatusIndicators = {}
    
    -- Função para criar categoria
    local function CreateCategory(name, order)
        local cat = Instance.new("Frame")
        cat.Size = UDim2.new(1, 0, 0, 18)
        cat.BackgroundTransparency = 1
        cat.LayoutOrder = order
        cat.Parent = ButtonsScroll
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "-- " .. name .. " --"
        label.TextColor3 = AccentColor
        label.Font = Enum.Font.GothamBold
        label.TextSize = 10
        label.Parent = cat
    end
    
    -- Função para criar botão toggle
    local function CreateToggle(name, callback, order, stateKey)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = SecondaryColor
        btn.Text = ""
        btn.LayoutOrder = order
        btn.Parent = ButtonsScroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = TextColor
        label.Font = Enum.Font.Gotham
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn
        
        local status = Instance.new("Frame")
        status.Size = UDim2.new(0, 10, 0, 10)
        status.Position = UDim2.new(1, -22, 0.5, -5)
        status.BackgroundColor3 = DimColor
        status.Parent = btn
        
        local statusCorner = Instance.new("UICorner")
        statusCorner.CornerRadius = UDim.new(1, 0)
        statusCorner.Parent = status
        
        if stateKey then
            StatusIndicators[stateKey] = status
        end
        
        btn.MouseButton1Click:Connect(function()
            local success, msg = callback()
            status.BackgroundColor3 = success and SuccessColor or DimColor
            if msg then Notify(name, msg, 2) end
        end)
        
        return btn
    end
    
    -- Função para criar botão simples
    local function CreateButton(name, callback, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = SecondaryColor
        btn.Text = name
        btn.TextColor3 = TextColor
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.LayoutOrder = order
        btn.Parent = ButtonsScroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            local success, msg = callback()
            if msg then Notify(name, msg, 2) end
        end)
        
        return btn
    end
    
    -- Criar botões - APENAS FUNÇÕES ESSENCIAIS
    CreateCategory("TROLAGEM", 1)
    CreateToggle("Ima de Objetos", ToggleMagnet, 2, "Magnet")
    CreateToggle("Orbit Attack", ToggleOrbit, 3, "Orbit")
    CreateToggle("Sky Lift", ToggleSkyLift, 4, "SkyLift")
    CreateToggle("Server Magnet", ToggleServerMagnet, 5, "ServerMagnet")
    
    CreateCategory("UTILIDADES", 10)
    CreateToggle("View Player", ToggleView, 11, "View")
    CreateToggle("Speed 3x", ToggleSpeed, 12, "Speed")
    CreateButton("Fly GUI", ToggleFly, 13)
    
    CreateCategory("CONFIG", 20)
    
    -- Slider de Raio
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 45)
    sliderFrame.BackgroundColor3 = SecondaryColor
    sliderFrame.LayoutOrder = 21
    sliderFrame.Parent = ButtonsScroll
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = sliderFrame
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, -10, 0, 18)
    sliderLabel.Position = UDim2.new(0, 5, 0, 3)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "Raio Orbit: " .. Config.OrbitRadius
    sliderLabel.TextColor3 = TextColor
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextSize = 10
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -10, 0, 8)
    sliderBg.Position = UDim2.new(0, 5, 0, 25)
    sliderBg.BackgroundColor3 = BgColor
    sliderBg.Parent = sliderFrame
    
    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(1, 0)
    sliderBgCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(Config.OrbitRadius / 50, 0, 1, 0)
    sliderFill.BackgroundColor3 = AccentColor
    sliderFill.Parent = sliderBg
    
    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(1, 0)
    sliderFillCorner.Parent = sliderFill
    
    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    sliderBtn.Parent = sliderBg
    
    local draggingSlider = false
    
    sliderBtn.MouseButton1Down:Connect(function()
        draggingSlider = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if draggingSlider then
            local mouse = UserInputService:GetMouseLocation()
            local relX = math.clamp((mouse.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            Config.OrbitRadius = math.floor(relX * 45) + 5
            sliderFill.Size = UDim2.new(relX, 0, 1, 0)
            sliderLabel.Text = "Raio Orbit: " .. Config.OrbitRadius
        end
    end)
    
    -- Botão flutuante para reabrir
    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Name = "FloatBtn"
    FloatBtn.Size = UDim2.new(0, 50, 0, 50)
    FloatBtn.Position = UDim2.new(0, 10, 0.5, -25)
    FloatBtn.BackgroundColor3 = AccentColor
    FloatBtn.Text = "NDS"
    FloatBtn.TextColor3 = TextColor
    FloatBtn.Font = Enum.Font.GothamBold
    FloatBtn.TextSize = 12
    FloatBtn.Visible = false
    FloatBtn.Parent = ScreenGui
    
    local FloatBtnCorner = Instance.new("UICorner")
    FloatBtnCorner.CornerRadius = UDim.new(1, 0)
    FloatBtnCorner.Parent = FloatBtn
    
    -- Minimizar
    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 320, 0, 40)}):Play()
            MinimizeBtn.Text = "+"
            ContentFrame.Visible = false
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 320, 0, 450)}):Play()
            MinimizeBtn.Text = "-"
            task.wait(0.2)
            ContentFrame.Visible = true
        end
    end)
    
    -- Fechar/Esconder
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        FloatBtn.Visible = true
    end)
    
    FloatBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        FloatBtn.Visible = false
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
    
    -- Arrastar botão flutuante
    local draggingFloat = false
    local floatDragStart, floatStartPos
    
    FloatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFloat = true
            floatDragStart = input.Position
            floatStartPos = FloatBtn.Position
        end
    end)
    
    FloatBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingFloat = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if draggingFloat and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - floatDragStart
            FloatBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
        end
    end)
    
    return ScreenGui
end

-- INICIALIZAÇÃO
SetupNetworkControl()
local UI = CreateUI()

task.spawn(function()
    task.wait(1)
    Notify("NDS Troll Hub v7.3 MAGNET OP", "Carregado!", 3)
end)

print("NDS Troll Hub v7.3 MAGNET OP - Carregado!")
