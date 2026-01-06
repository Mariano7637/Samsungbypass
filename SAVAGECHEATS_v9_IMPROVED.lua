--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║           SAVAGECHEATS_ AIMBOT UNIVERSAL v9.0 IMPROVED        ║
    ║                  BYPASS AVANÇADO + WALLBANG                   ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║  • BYPASS ANTI-KICK FORTE (NoClip/Fly/Speed)                  ║
    ║  • WALLBANG - Atirar através de paredes                       ║
    ║  • RAPID FIRE EXTREMO (0.001 - 0.5)                           ║
    ║  • MUNIÇÃO INFINITA CORRIGIDA                                 ║
    ║  • FLY HACK com bypass                                        ║
    ║  • Compatível com Mobile                                      ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════
--                          SERVIÇOS
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")

-- ═══════════════════════════════════════════════════════════════
--                      VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════════════════════

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Detectar jogo
local GameId = game.PlaceId
local IsPrisonLife = GameId == 155615604 or GameId == 419601093
local GameName = IsPrisonLife and "Prison Life" or "Universal"

-- Limpar instância anterior
if _G.SAVAGE_V9 then
    pcall(function() _G.SAVAGE_V9_CLEANUP() end)
    task.wait(0.3)
end

-- ═══════════════════════════════════════════════════════════════
--                       CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Aimbot
    AimbotEnabled = false,
    SilentAim = false,
    IgnoreWalls = false,
    SkipDowned = true,
    AimPart = "Head",
    
    -- Team Filter
    TeamFilter = "Todos",
    
    -- FOV
    FOVRadius = 150,
    FOVVisible = true,
    
    -- Smoothing
    Smoothness = 0.3,
    
    -- ESP
    ESPEnabled = false,
    ESPBox = true,
    ESPName = true,
    ESPHealth = true,
    ESPDistance = true,
    
    -- NoClip com Bypass
    NoClipEnabled = false,
    NoClipBypassMode = "Advanced", -- "Basic", "Advanced", "Stealth"
    
    -- Fly com Bypass
    FlyEnabled = false,
    FlySpeed = 50,
    
    -- Hitbox
    HitboxEnabled = false,
    HitboxSize = 5,
    
    -- Speed com Bypass
    SpeedEnabled = false,
    SpeedMultiplier = 0.2,
    SpeedBypassMode = "CFrame", -- "CFrame", "Velocity", "Teleport"
    
    -- Rapid Fire EXTREMO
    RapidFireEnabled = false,
    RapidFireRate = 0.001, -- 0.001 a 0.5 (EXTREMO)
    
    -- Munição Infinita CORRIGIDA
    InfiniteAmmoEnabled = false,
    
    -- WALLBANG - Atirar através de paredes
    WallbangEnabled = false,
    
    -- Misc
    ShowLine = false,
    MaxDistance = 1000,
    
    -- Bypass Settings
    BypassAntiCheat = true,
    SpoofWalkSpeed = true,
    DisableGameGuard = true,
}

local State = {
    Target = nil,
    TargetPart = nil,
    Locked = false,
    Flying = false,
    OriginalWalkSpeed = 16,
    OriginalJumpPower = 50,
}

local Connections = {}
local ESPObjects = {}

-- ═══════════════════════════════════════════════════════════════
--                         CORES DO TEMA
-- ═══════════════════════════════════════════════════════════════

local Theme = {
    Primary = Color3.fromRGB(200, 30, 30),
    Secondary = Color3.fromRGB(25, 25, 25),
    Background = Color3.fromRGB(15, 15, 15),
    Surface = Color3.fromRGB(35, 35, 35),
    SurfaceLight = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(50, 200, 50),
    Warning = Color3.fromRGB(255, 180, 0),
    Border = Color3.fromRGB(60, 60, 60),
    Accent = Color3.fromRGB(255, 80, 80),
}

-- ═══════════════════════════════════════════════════════════════
--                    FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════

local function GetScreenCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen and screenPos.Z > 0
end

local function Distance2D(a, b)
    return (a - b).Magnitude
end

local function Distance3D(a, b)
    return (a - b).Magnitude
end

local function IsAlive(character)
    if not character then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    
    if Config.SkipDowned then
        if character:FindFirstChild("Knocked") or 
           character:FindFirstChild("Downed") or
           hum:GetState() == Enum.HumanoidStateType.Physics then
            return false
        end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════
--              BYPASS ANTI-CHEAT AVANÇADO (PRISON LIFE)
-- ═══════════════════════════════════════════════════════════════

local AntiCheatBypassed = false
local OriginalFunctions = {}
local HookedRemotes = {}

local function BypassGameGuard()
    if AntiCheatBypassed then return end
    
    pcall(function()
        -- Desabilitar GAMEGUARD
        local gameGuard = ReplicatedStorage:FindFirstChild("GAMEGUARD")
        if gameGuard then
            gameGuard:Destroy()
        end
        
        -- Desabilitar scripts de anti-cheat conhecidos
        local antiCheatNames = {
            "AntiCheat", "AntiExploit", "GameGuard", "AntiHack",
            "SecurityScript", "Anticheat", "AC", "AntiKill",
            "CharacterCollision", "CollisionCheck", "SpeedCheck",
            "VelocityCheck", "PositionCheck", "TeleportCheck"
        }
        
        for _, name in pairs(antiCheatNames) do
            pcall(function()
                local found = ReplicatedStorage:FindFirstChild(name, true)
                if found then found:Destroy() end
                
                found = Workspace:FindFirstChild(name, true)
                if found then found:Destroy() end
                
                if LocalPlayer.PlayerScripts then
                    found = LocalPlayer.PlayerScripts:FindFirstChild(name, true)
                    if found then found:Destroy() end
                end
            end)
        end
        
        -- Desabilitar scripts no ReplicatedStorage
        pcall(function()
            local scripts = ReplicatedStorage:FindFirstChild("Scripts")
            if scripts then
                local collision = scripts:FindFirstChild("CharacterCollision")
                if collision then collision:Destroy() end
            end
        end)
    end)
    
    AntiCheatBypassed = true
    print("[SAVAGE v9] GameGuard/AntiCheat Bypassed!")
end

local function SpoofHumanoidProperties()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        -- Salvar valores originais
        if State.OriginalWalkSpeed == 16 then
            State.OriginalWalkSpeed = hum.WalkSpeed
            State.OriginalJumpPower = hum.JumpPower or hum.JumpHeight
        end
    end)
end

-- Hook para interceptar verificações de anti-cheat
local function HookAntiCheatRemotes()
    pcall(function()
        local mt = getrawmetatable(game)
        if not mt then return end
        
        local oldNamecall = mt.__namecall
        local oldIndex = mt.__index
        
        setreadonly(mt, false)
        
        -- Hook __namecall para interceptar FireServer
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            -- Bloquear kicks de anti-cheat
            if method == "Kick" then
                return nil
            end
            
            -- Interceptar FireServer para remotes de anti-cheat
            if method == "FireServer" then
                local remoteName = self.Name:lower()
                local blockList = {"anticheat", "kick", "ban", "detect", "exploit", "hack", "cheat", "gameguard"}
                
                for _, blocked in pairs(blockList) do
                    if remoteName:find(blocked) then
                        return nil
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end)
        
        -- Hook __index para spoofar WalkSpeed
        mt.__index = newcclosure(function(self, key)
            if Config.SpoofWalkSpeed then
                if typeof(self) == "Instance" and self:IsA("Humanoid") then
                    if key == "WalkSpeed" and Config.SpeedEnabled then
                        return 16 -- Retorna valor normal para checks
                    end
                end
            end
            return oldIndex(self, key)
        end)
        
        setreadonly(mt, true)
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    SISTEMA DE TIMES
-- ═══════════════════════════════════════════════════════════════

local function GetPlayerTeamName(player)
    if not player.Team then return "Sem Time" end
    local teamName = player.Team.Name:lower()
    
    if teamName:find("prisoner") or teamName:find("prisioneiro") then
        return "Prisioneiros"
    elseif teamName:find("guard") or teamName:find("guarda") or teamName:find("police") then
        return "Guardas"
    elseif teamName:find("criminal") or teamName:find("criminoso") then
        return "Criminosos"
    end
    
    return player.Team.Name
end

local function ShouldTarget(player)
    if player == LocalPlayer then return false end
    
    local filter = Config.TeamFilter
    
    if filter == "Todos" then
        return player ~= LocalPlayer
    elseif filter == "Inimigos" then
        if not LocalPlayer.Team or not player.Team then return true end
        return LocalPlayer.Team ~= player.Team
    else
        local playerTeam = GetPlayerTeamName(player)
        return playerTeam == filter
    end
end

local function HasLineOfSight(origin, target)
    if Config.IgnoreWalls or Config.WallbangEnabled then return true end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local result = Workspace:Raycast(origin, (target - origin), params)
    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        return model and model:FindFirstChildOfClass("Humanoid") ~= nil
    end
    return true
end

local function GetTargetPart(character)
    local part = character:FindFirstChild(Config.AimPart)
    if not part then
        part = character:FindFirstChild("Head") or 
               character:FindFirstChild("HumanoidRootPart")
    end
    return part
end

-- ═══════════════════════════════════════════════════════════════
--                    SISTEMA DE ALVO
-- ═══════════════════════════════════════════════════════════════

local function FindTarget()
    local bestTarget, bestPart = nil, nil
    local bestDist = Config.FOVRadius
    local center = GetScreenCenter()
    local camPos = Camera.CFrame.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if ShouldTarget(player) then
            local char = player.Character
            if char and IsAlive(char) then
                local part = GetTargetPart(char)
                if part then
                    local dist3D = Distance3D(camPos, part.Position)
                    if dist3D <= Config.MaxDistance then
                        local screenPos, visible = WorldToScreen(part.Position)
                        if visible then
                            local dist2D = Distance2D(center, screenPos)
                            if dist2D < bestDist then
                                if HasLineOfSight(camPos, part.Position) then
                                    bestDist = dist2D
                                    bestTarget = player
                                    bestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget, bestPart
end

-- ═══════════════════════════════════════════════════════════════
--                    SISTEMA DE MIRA
-- ═══════════════════════════════════════════════════════════════

local function AimAt(position)
    if not position then return end
    
    local camPos = Camera.CFrame.Position
    local targetCF = CFrame.lookAt(camPos, position)
    
    if Config.Smoothness > 0 then
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 - Config.Smoothness)
    else
        Camera.CFrame = targetCF
    end
end

-- ═══════════════════════════════════════════════════════════════
--                    SILENT AIM + WALLBANG
-- ═══════════════════════════════════════════════════════════════

local SilentAimHooked = false
local OldIndex = nil

local function EnableSilentAim()
    if SilentAimHooked then return end
    
    pcall(function()
        local mt = getrawmetatable(game)
        local oldReadonly = isreadonly(mt)
        setreadonly(mt, false)
        
        OldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if (Config.SilentAim or Config.WallbangEnabled) and Config.AimbotEnabled then
                if typeof(self) == "Instance" and self:IsA("Mouse") then
                    local target, part = FindTarget()
                    if target and part then
                        if key == "Hit" then
                            return part.CFrame
                        elseif key == "Target" then
                            return part
                        end
                    end
                end
            end
            return OldIndex(self, key)
        end)
        
        setreadonly(mt, oldReadonly)
        SilentAimHooked = true
    end)
end

local function DisableSilentAim()
    if not SilentAimHooked then return end
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        if OldIndex then mt.__index = OldIndex end
        setreadonly(mt, true)
        SilentAimHooked = false
    end)
end

-- ═══════════════════════════════════════════════════════════════
--              NOCLIP COM BYPASS AVANÇADO
-- ═══════════════════════════════════════════════════════════════

local NoClipConnection = nil
local NoClipBypassApplied = false
local OriginalCanCollide = {}

local function ApplyAdvancedNoClipBypass()
    if NoClipBypassApplied then return end
    
    pcall(function()
        -- Método 1: Destruir scripts de colisão
        local scripts = ReplicatedStorage:FindFirstChild("Scripts")
        if scripts then
            for _, child in pairs(scripts:GetDescendants()) do
                if child.Name:lower():find("collision") or child.Name:lower():find("clip") then
                    child:Destroy()
                end
            end
        end
        
        -- Método 2: Desabilitar verificações de posição
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local name = remote.Name:lower()
                if name:find("position") or name:find("teleport") or name:find("check") then
                    pcall(function()
                        remote:Destroy()
                    end)
                end
            end
        end
        
        -- Método 3: Spoofar física do personagem
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Salvar estado original
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        OriginalCanCollide[part] = part.CanCollide
                    end
                end
            end
        end
        
        NoClipBypassApplied = true
    end)
end

local function EnableNoClip()
    if NoClipConnection then return end
    
    -- Aplicar bypass antes de ativar
    if Config.BypassAntiCheat then
        BypassGameGuard()
        ApplyAdvancedNoClipBypass()
    end
    
    NoClipConnection = RunService.Stepped:Connect(function()
        if not Config.NoClipEnabled then return end
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function DisableNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
    
    -- Restaurar colisão original
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            for part, canCollide in pairs(OriginalCanCollide) do
                if part and part.Parent then
                    part.CanCollide = canCollide
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    FLY HACK COM BYPASS
-- ═══════════════════════════════════════════════════════════════

local FlyConnection = nil
local BodyGyro = nil
local BodyVelocity = nil

local function EnableFly()
    if FlyConnection then return end
    
    -- Aplicar bypass
    if Config.BypassAntiCheat then
        BypassGameGuard()
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    -- Criar BodyGyro para estabilização
    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.P = 9e4
    BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BodyGyro.CFrame = hrp.CFrame
    BodyGyro.Parent = hrp
    
    -- Criar BodyVelocity para movimento
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BodyVelocity.Parent = hrp
    
    State.Flying = true
    
    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Config.FlyEnabled or not State.Flying then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        
        -- Atualizar BodyGyro
        if BodyGyro then
            BodyGyro.CFrame = Camera.CFrame
        end
        
        -- Calcular direção de movimento
        local moveDirection = Vector3.new(0, 0, 0)
        
        if hum.MoveDirection.Magnitude > 0 then
            moveDirection = Camera.CFrame.LookVector * hum.MoveDirection.Z + 
                           Camera.CFrame.RightVector * hum.MoveDirection.X
        end
        
        -- Movimento vertical
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or 
           UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection + Vector3.new(0, -1, 0)
        end
        
        -- Aplicar velocidade
        if BodyVelocity then
            BodyVelocity.Velocity = moveDirection.Unit * Config.FlySpeed
            if moveDirection.Magnitude == 0 then
                BodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end
        
        -- Bypass: Manter humanoid em estado válido
        hum:ChangeState(Enum.HumanoidStateType.Flying)
    end)
end

local function DisableFly()
    State.Flying = false
    
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    
    if BodyGyro then
        BodyGyro:Destroy()
        BodyGyro = nil
    end
    
    if BodyVelocity then
        BodyVelocity:Destroy()
        BodyVelocity = nil
    end
    
    -- Restaurar estado do humanoid
    pcall(function()
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    HITBOX
-- ═══════════════════════════════════════════════════════════════

local HitboxConnection = nil
local OriginalSizes = {}

local function UpdateHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if ShouldTarget(player) then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    if not OriginalSizes[player] then
                        OriginalSizes[player] = root.Size
                    end
                    
                    if Config.HitboxEnabled then
                        local size = Config.HitboxSize
                        root.Size = Vector3.new(size, size, size)
                        root.Transparency = 0.7
                        root.CanCollide = false
                        root.Material = Enum.Material.ForceField
                    else
                        root.Size = OriginalSizes[player] or Vector3.new(2, 2, 1)
                        root.Transparency = 1
                        root.Material = Enum.Material.SmoothPlastic
                    end
                end
            end
        end
    end
end

local function EnableHitbox()
    if HitboxConnection then return end
    HitboxConnection = RunService.Heartbeat:Connect(function()
        if Config.HitboxEnabled then UpdateHitboxes() end
    end)
end

local function DisableHitbox()
    if HitboxConnection then
        HitboxConnection:Disconnect()
        HitboxConnection = nil
    end
    Config.HitboxEnabled = false
    UpdateHitboxes()
    OriginalSizes = {}
end

-- ═══════════════════════════════════════════════════════════════
--              SPEED HACK COM BYPASS AVANÇADO
-- ═══════════════════════════════════════════════════════════════

local SpeedConnection = nil

local function EnableSpeed()
    if SpeedConnection then return end
    
    -- Aplicar bypass
    if Config.BypassAntiCheat then
        BypassGameGuard()
        SpoofHumanoidProperties()
    end
    
    SpeedConnection = RunService.Stepped:Connect(function()
        if not Config.SpeedEnabled then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum and hum.MoveDirection.Magnitude > 0 then
            if Config.SpeedBypassMode == "CFrame" then
                -- Método CFrame (mais seguro)
                hrp.CFrame = hrp.CFrame + hum.MoveDirection * Config.SpeedMultiplier
            elseif Config.SpeedBypassMode == "Velocity" then
                -- Método Velocity (mais rápido, menos seguro)
                hrp.Velocity = hum.MoveDirection * (16 + Config.SpeedMultiplier * 100)
            elseif Config.SpeedBypassMode == "Teleport" then
                -- Método Teleport (micro-teleportes)
                local newPos = hrp.Position + hum.MoveDirection * Config.SpeedMultiplier * 2
                hrp.CFrame = CFrame.new(newPos) * (hrp.CFrame - hrp.CFrame.Position)
            end
        end
    end)
end

local function DisableSpeed()
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--          RAPID FIRE EXTREMO + MUNIÇÃO INFINITA CORRIGIDA
-- ═══════════════════════════════════════════════════════════════

local ModifiedGuns = {}
local GunModConnection = nil
local AmmoLoopConnection = nil

local function ModifyGunExtreme(gun)
    if not gun then return false end
    if ModifiedGuns[gun] then return true end
    
    local success = pcall(function()
        -- Método 1: Modificar GunStates (Prison Life padrão)
        local gunStates = gun:FindFirstChild("GunStates")
        if gunStates then
            local sM = require(gunStates)
            
            -- Rapid Fire EXTREMO
            if Config.RapidFireEnabled then
                sM["FireRate"] = Config.RapidFireRate
                sM["AutoFire"] = true
                sM["speedrate"] = Config.RapidFireRate
                sM["Automatic"] = true
            end
            
            -- Munição Infinita
            if Config.InfiniteAmmoEnabled then
                sM["MaxAmmo"] = math.huge
                sM["StoredAmmo"] = math.huge
                sM["AmmoPerClip"] = math.huge
                sM["ClipSize"] = math.huge
                sM["Ammo"] = math.huge
                sM["Magazine"] = math.huge
                sM["Clips"] = math.huge
                sM["maxammos"] = math.huge
                sM["ReloadTime"] = 0
                sM["reloadtime"] = 0
            end
            
            -- Bônus de dano e alcance
            sM["Range"] = 99999
            sM["BaseDamage"] = sM["BaseDamage"] and sM["BaseDamage"] * 2 or 50
            
            ModifiedGuns[gun] = true
        end
        
        -- Método 2: Modificar Ammos diretamente
        local ammos = gun:FindFirstChild("Ammos")
        if ammos and Config.InfiniteAmmoEnabled then
            if ammos:IsA("NumberValue") or ammos:IsA("IntValue") then
                ammos.Value = 999999
            elseif ammos:IsA("ModuleScript") then
                local ammoData = require(ammos)
                if type(ammoData) == "table" then
                    for k, v in pairs(ammoData) do
                        if type(v) == "number" then
                            ammoData[k] = 999999
                        end
                    end
                end
            end
        end
        
        -- Método 3: Modificar valores diretamente na ferramenta
        for _, child in pairs(gun:GetDescendants()) do
            if Config.InfiniteAmmoEnabled then
                if child.Name:lower():find("ammo") or child.Name:lower():find("clip") or 
                   child.Name:lower():find("magazine") or child.Name:lower():find("bullet") then
                    if child:IsA("NumberValue") or child:IsA("IntValue") then
                        child.Value = 999999
                    end
                end
            end
            
            if Config.RapidFireEnabled then
                if child.Name:lower():find("fire") or child.Name:lower():find("rate") or
                   child.Name:lower():find("speed") or child.Name:lower():find("cooldown") then
                    if child:IsA("NumberValue") then
                        child.Value = Config.RapidFireRate
                    end
                end
            end
        end
    end)
    
    return success
end

local function ApplyGunMods()
    -- Modificar armas no Backpack
    for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            ModifyGunExtreme(item)
        end
    end
    
    -- Modificar arma equipada
    if LocalPlayer.Character then
        for _, item in pairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") then
                ModifyGunExtreme(item)
            end
        end
    end
end

-- Loop contínuo para manter munição infinita
local function StartAmmoLoop()
    if AmmoLoopConnection then return end
    
    AmmoLoopConnection = RunService.Heartbeat:Connect(function()
        if not Config.InfiniteAmmoEnabled then return end
        
        pcall(function()
            -- Atualizar munição constantemente
            local char = LocalPlayer.Character
            if char then
                for _, tool in pairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        -- Método direto: setar valores de munição
                        for _, child in pairs(tool:GetDescendants()) do
                            if child:IsA("NumberValue") or child:IsA("IntValue") then
                                local name = child.Name:lower()
                                if name:find("ammo") or name:find("clip") or 
                                   name:find("magazine") or name:find("bullet") or
                                   name:find("round") then
                                    if child.Value < 100 then
                                        child.Value = 999999
                                    end
                                end
                            end
                        end
                        
                        -- Modificar GunStates em tempo real
                        local gunStates = tool:FindFirstChild("GunStates")
                        if gunStates then
                            pcall(function()
                                local sM = require(gunStates)
                                sM["Ammo"] = 999999
                                sM["StoredAmmo"] = 999999
                                sM["Magazine"] = 999999
                                sM["ClipSize"] = 999999
                            end)
                        end
                    end
                end
            end
            
            -- Atualizar GUI de munição
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("TextLabel") then
                        local text = gui.Text:lower()
                        if text:find("reloading") then
                            gui.Text = "999999"
                        end
                    end
                end
            end
        end)
    end)
end

local function StopAmmoLoop()
    if AmmoLoopConnection then
        AmmoLoopConnection:Disconnect()
        AmmoLoopConnection = nil
    end
end

local function EnableRapidFire()
    ModifiedGuns = {}
    ApplyGunMods()
    
    if not Connections.GunBackpack then
        Connections.GunBackpack = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                ModifyGunExtreme(child)
            end
        end)
    end
end

local function EnableInfiniteAmmo()
    ModifiedGuns = {}
    ApplyGunMods()
    StartAmmoLoop()
    
    if not Connections.AmmoBackpack then
        Connections.AmmoBackpack = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                ModifyGunExtreme(child)
            end
        end)
    end
end

local function DisableGunMods()
    ModifiedGuns = {}
    StopAmmoLoop()
    
    if Connections.GunBackpack then
        Connections.GunBackpack:Disconnect()
        Connections.GunBackpack = nil
    end
    
    if Connections.AmmoBackpack then
        Connections.AmmoBackpack:Disconnect()
        Connections.AmmoBackpack = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--                    WALLBANG SYSTEM
-- ═══════════════════════════════════════════════════════════════

local WallbangConnection = nil
local OriginalRaycast = nil

local function EnableWallbang()
    if WallbangConnection then return end
    
    pcall(function()
        -- Hook raycast para ignorar paredes
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if Config.WallbangEnabled then
                -- Interceptar raycasts de armas
                if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                    -- Modificar para ignorar paredes
                    if args[2] then -- RaycastParams ou IgnoreList
                        if typeof(args[2]) == "RaycastParams" then
                            args[2].FilterType = Enum.RaycastFilterType.Blacklist
                            -- Adicionar todas as partes estáticas à lista de ignorados
                            local ignoreList = {LocalPlayer.Character, Camera}
                            for _, part in pairs(Workspace:GetDescendants()) do
                                if part:IsA("BasePart") and part.Anchored and not part:IsDescendantOf(Players) then
                                    table.insert(ignoreList, part)
                                end
                            end
                            args[2].FilterDescendantsInstances = ignoreList
                        end
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end)
        
        setreadonly(mt, true)
    end)
    
    -- Conexão adicional para modificar hits
    WallbangConnection = RunService.Heartbeat:Connect(function()
        if not Config.WallbangEnabled then return end
        
        -- Forçar hits através de paredes usando silent aim
        if Config.AimbotEnabled and State.Target and State.TargetPart then
            -- O silent aim já está configurado para ignorar paredes
        end
    end)
    
    print("[SAVAGE v9] Wallbang Enabled - Você pode atirar através de paredes!")
end

local function DisableWallbang()
    if WallbangConnection then
        WallbangConnection:Disconnect()
        WallbangConnection = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--                    FOV CIRCLE
-- ═══════════════════════════════════════════════════════════════

local FOVCircle = nil
local AimLine = nil

local function CreateDrawings()
    pcall(function()
        if FOVCircle then FOVCircle:Remove() end
        if AimLine then AimLine:Remove() end
        
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Thickness = 2
        FOVCircle.NumSides = 60
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Filled = false
        FOVCircle.Visible = false
        FOVCircle.ZIndex = 999
        FOVCircle.Color = Theme.Primary
        
        AimLine = Drawing.new("Line")
        AimLine.Thickness = 2
        AimLine.Color = Theme.Success
        AimLine.Visible = false
        AimLine.ZIndex = 998
    end)
end

local function UpdateDrawings()
    if FOVCircle then
        FOVCircle.Position = GetScreenCenter()
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Visible = Config.FOVVisible and Config.AimbotEnabled
        FOVCircle.Color = State.Locked and Theme.Success or Theme.Primary
    end
    
    if AimLine and Config.ShowLine and State.Locked and State.TargetPart then
        local targetPos, visible = WorldToScreen(State.TargetPart.Position)
        if visible then
            AimLine.From = GetScreenCenter()
            AimLine.To = targetPos
            AimLine.Visible = true
        else
            AimLine.Visible = false
        end
    elseif AimLine then
        AimLine.Visible = false
    end
end

local function DestroyDrawings()
    pcall(function()
        if FOVCircle then FOVCircle:Remove() FOVCircle = nil end
        if AimLine then AimLine:Remove() AimLine = nil end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    ESP
-- ═══════════════════════════════════════════════════════════════

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    pcall(function()
        ESPObjects[player] = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Health = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
        }
        
        local esp = ESPObjects[player]
        esp.Box.Thickness = 1
        esp.Box.Filled = false
        esp.Box.Visible = false
        
        for _, text in pairs({esp.Name, esp.Health, esp.Distance}) do
            text.Size = 13
            text.Center = true
            text.Outline = true
            text.Visible = false
        end
    end)
end

local function UpdateESP(player)
    local esp = ESPObjects[player]
    if not esp then return end
    
    local char = player.Character
    local show = Config.ESPEnabled and char and IsAlive(char)
    
    if not show then
        for _, obj in pairs(esp) do pcall(function() obj.Visible = false end) end
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if not root or not hum then
        for _, obj in pairs(esp) do pcall(function() obj.Visible = false end) end
        return
    end
    
    local rootPos, visible = WorldToScreen(root.Position)
    if not visible then
        for _, obj in pairs(esp) do pcall(function() obj.Visible = false end) end
        return
    end
    
    local headPos = WorldToScreen((head or root).Position + Vector3.new(0, 0.5, 0))
    local feetPos = WorldToScreen(root.Position - Vector3.new(0, 3, 0))
    
    local height = math.abs(headPos.Y - feetPos.Y)
    local width = height / 2
    
    local isTarget = ShouldTarget(player)
    local color = isTarget and Theme.Primary or Theme.Success
    
    if Config.ESPBox then
        esp.Box.Position = Vector2.new(rootPos.X - width/2, headPos.Y)
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Color = color
        esp.Box.Visible = true
    else
        esp.Box.Visible = false
    end
    
    if Config.ESPName then
        local teamName = GetPlayerTeamName(player)
        esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 16)
        esp.Name.Text = player.Name .. " [" .. teamName .. "]"
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end
    
    if Config.ESPHealth then
        local hp = math.floor(hum.Health)
        esp.Health.Position = Vector2.new(rootPos.X, feetPos.Y + 3)
        esp.Health.Text = hp .. " HP"
        esp.Health.Color = hp > 60 and Color3.new(0,1,0) or (hp > 30 and Color3.new(1,1,0) or Color3.new(1,0,0))
        esp.Health.Visible = true
    else
        esp.Health.Visible = false
    end
    
    if Config.ESPDistance then
        local dist = math.floor(Distance3D(Camera.CFrame.Position, root.Position))
        esp.Distance.Position = Vector2.new(rootPos.X, feetPos.Y + 16)
        esp.Distance.Text = dist .. "m"
        esp.Distance.Color = Color3.new(1, 1, 1)
        esp.Distance.Visible = true
    else
        esp.Distance.Visible = false
    end
end

local function RemoveESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[player] = nil
    end
end

local function InitESP()
    for _, player in pairs(Players:GetPlayers()) do CreateESP(player) end
    Connections.PlayerAdded = Players.PlayerAdded:Connect(CreateESP)
    Connections.PlayerRemoving = Players.PlayerRemoving:Connect(RemoveESP)
end

local function DestroyESP()
    for player, _ in pairs(ESPObjects) do RemoveESP(player) end
end

-- ═══════════════════════════════════════════════════════════════
--                    UI PRÓPRIA - REORGANIZADA
-- ═══════════════════════════════════════════════════════════════

local ScreenGui = nil
local MainFrame = nil
local FloatButton = nil
local CurrentTab = "AIM"
local UIVisible = false

local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function AddPadding(parent, padding)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, padding)
    pad.PaddingBottom = UDim.new(0, padding)
    pad.PaddingLeft = UDim.new(0, padding)
    pad.PaddingRight = UDim.new(0, padding)
    pad.Parent = parent
    return pad
end

-- ═══════════════════════════════════════════════════════════════
--                    COMPONENTES UI
-- ═══════════════════════════════════════════════════════════════

local function CreateSectionHeader(parent, title)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = Theme.Primary
    header.BorderSizePixel = 0
    header.Parent = parent
    AddCorner(header, 4)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "  " .. title
    label.TextColor3 = Theme.Text
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header
    
    return header
end

local function CreateToggle(parent, name, default, callback)
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.Parent = parent
    AddCorner(container, 4)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 20)
    toggleBg.Position = UDim2.new(1, -48, 0.5, -10)
    toggleBg.BackgroundColor3 = default and Theme.Primary or Theme.Border
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = container
    AddCorner(toggleBg, 10)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    toggleCircle.BackgroundColor3 = Theme.Text
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleBg
    AddCorner(toggleCircle, 8)
    
    local enabled = default
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container
    
    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        local targetPos = enabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local targetColor = enabled and Theme.Primary or Theme.Border
        
        TweenService:Create(toggleCircle, TweenInfo.new(0.15), {Position = targetPos}):Play()
        TweenService:Create(toggleBg, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
        
        if callback then callback(enabled) end
    end)
    
    return container
end

local function CreateSlider(parent, name, min, max, default, decimals, callback)
    decimals = decimals or 0
    
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.Parent = parent
    AddCorner(container, 4)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -55, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = decimals > 0 and string.format("%." .. decimals .. "f", default) or tostring(default)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0, 32)
    sliderBg.BackgroundColor3 = Theme.Border
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    AddCorner(sliderBg, 3)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Theme.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    AddCorner(sliderFill, 3)
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Size = UDim2.new(0, 14, 0, 14)
    sliderKnob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    sliderKnob.BackgroundColor3 = Theme.Text
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Parent = sliderBg
    sliderKnob.ZIndex = 2
    AddCorner(sliderKnob, 7)
    
    local dragging = false
    
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * pos
        
        if decimals > 0 then
            value = math.floor(value * (10 ^ decimals) + 0.5) / (10 ^ decimals)
        else
            value = math.floor(value + 0.5)
        end
        
        sliderFill.Size = UDim2.new(pos, 0, 1, 0)
        sliderKnob.Position = UDim2.new(pos, -7, 0.5, -7)
        valueLabel.Text = decimals > 0 and string.format("%." .. decimals .. "f", value) or tostring(value)
        
        if callback then callback(value) end
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return container
end

local function CreateDropdown(parent, name, options, default, callback)
    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = Theme.Surface
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = parent
    AddCorner(container, 4)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, -5, 0, 32)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local selected = Instance.new("TextButton")
    selected.Size = UDim2.new(0.5, -15, 0, 24)
    selected.Position = UDim2.new(0.5, 5, 0, 4)
    selected.BackgroundColor3 = Theme.SurfaceLight
    selected.Text = default
    selected.TextColor3 = Theme.Accent
    selected.TextSize = 11
    selected.Font = Enum.Font.GothamBold
    selected.BorderSizePixel = 0
    selected.Parent = container
    AddCorner(selected, 4)
    
    local expanded = false
    local optionFrames = {}
    
    for i, option in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(0.5, -15, 0, 24)
        optBtn.Position = UDim2.new(0.5, 5, 0, 4 + i * 26)
        optBtn.BackgroundColor3 = Theme.Border
        optBtn.Text = option
        optBtn.TextColor3 = Theme.Text
        optBtn.TextSize = 10
        optBtn.Font = Enum.Font.Gotham
        optBtn.BorderSizePixel = 0
        optBtn.Visible = false
        optBtn.Parent = container
        AddCorner(optBtn, 4)
        
        optBtn.MouseButton1Click:Connect(function()
            selected.Text = option
            expanded = false
            container.Size = UDim2.new(1, 0, 0, 32)
            for _, f in pairs(optionFrames) do f.Visible = false end
            if callback then callback(option) end
        end)
        
        table.insert(optionFrames, optBtn)
    end
    
    selected.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            container.Size = UDim2.new(1, 0, 0, 32 + #options * 26)
            for _, f in pairs(optionFrames) do f.Visible = true end
        else
            container.Size = UDim2.new(1, 0, 0, 32)
            for _, f in pairs(optionFrames) do f.Visible = false end
        end
    end)
    
    return container
end

local function CreateSpacer(parent, height)
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, height)
    spacer.BackgroundTransparency = 1
    spacer.Parent = parent
    return spacer
end

-- ═══════════════════════════════════════════════════════════════
--                    CRIAR UI PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local function CreateUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SAVAGE_V9_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        if syn then
            syn.protect_gui(ScreenGui)
        end
    end)
    
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Botão flutuante
    FloatButton = Instance.new("TextButton")
    FloatButton.Size = UDim2.new(0, 40, 0, 40)
    FloatButton.Position = UDim2.new(0, 10, 0.5, -20)
    FloatButton.BackgroundColor3 = Theme.Primary
    FloatButton.Text = "S"
    FloatButton.TextColor3 = Theme.Text
    FloatButton.TextSize = 20
    FloatButton.Font = Enum.Font.GothamBold
    FloatButton.BorderSizePixel = 0
    FloatButton.Parent = ScreenGui
    AddCorner(FloatButton, 20)
    
    -- Frame principal
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    AddCorner(MainFrame, 8)
    AddStroke(MainFrame, Theme.Primary, 2)
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Theme.Primary
    header.BorderSizePixel = 0
    header.Parent = MainFrame
    AddCorner(header, 8)
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 10)
    headerFix.Position = UDim2.new(0, 0, 1, -10)
    headerFix.BackgroundColor3 = Theme.Primary
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SAVAGECHEATS v9.0 IMPROVED"
    title.TextColor3 = Theme.Text
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Theme.Secondary
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    AddCorner(closeBtn, 4)
    
    closeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        UIVisible = false
    end)
    
    -- Tabs
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -16, 0, 30)
    tabFrame.Position = UDim2.new(0, 8, 0, 48)
    tabFrame.BackgroundColor3 = Theme.Secondary
    tabFrame.BorderSizePixel = 0
    tabFrame.Parent = MainFrame
    AddCorner(tabFrame, 4)
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabFrame
    
    local tabs = {"AIM", "ESP", "ARMAS", "MISC", "BYPASS"}
    local tabButtons = {}
    local tabContents = {}
    
    for _, tabName in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1/#tabs, -2, 1, 0)
        tabBtn.BackgroundColor3 = tabName == CurrentTab and Theme.Primary or Theme.Surface
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Theme.Text
        tabBtn.TextSize = 10
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabFrame
        AddCorner(tabBtn, 4)
        
        tabButtons[tabName] = tabBtn
        
        -- Content frame
        local content = Instance.new("ScrollingFrame")
        content.Size = UDim2.new(1, -16, 1, -90)
        content.Position = UDim2.new(0, 8, 0, 86)
        content.BackgroundTransparency = 1
        content.ScrollBarThickness = 4
        content.ScrollBarImageColor3 = Theme.Primary
        content.Visible = tabName == CurrentTab
        content.Parent = MainFrame
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 4)
        contentLayout.Parent = content
        
        tabContents[tabName] = content
        
        tabBtn.MouseButton1Click:Connect(function()
            CurrentTab = tabName
            for name, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = name == tabName and Theme.Primary or Theme.Surface
            end
            for name, cont in pairs(tabContents) do
                cont.Visible = name == tabName
            end
        end)
    end
    
    -- Toggle UI
    FloatButton.MouseButton1Click:Connect(function()
        UIVisible = not UIVisible
        MainFrame.Visible = UIVisible
    end)
    
    -- Drag
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA AIM
    -- ═══════════════════════════════════════════════════════════════
    
    local aimContent = tabContents["AIM"]
    
    CreateSectionHeader(aimContent, "Aimbot")
    
    CreateToggle(aimContent, "Aimbot", false, function(v)
        Config.AimbotEnabled = v
    end)
    
    CreateToggle(aimContent, "Silent Aim", false, function(v)
        Config.SilentAim = v
        if v then EnableSilentAim() else DisableSilentAim() end
    end)
    
    CreateToggle(aimContent, "Ignorar Paredes", false, function(v)
        Config.IgnoreWalls = v
    end)
    
    CreateSpacer(aimContent, 4)
    CreateSectionHeader(aimContent, "Configurações")
    
    CreateDropdown(aimContent, "Parte Alvo", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(v)
        Config.AimPart = v
    end)
    
    CreateDropdown(aimContent, "Focar Time", {"Todos", "Inimigos", "Prisioneiros", "Guardas", "Criminosos"}, "Todos", function(v)
        Config.TeamFilter = v
    end)
    
    CreateSlider(aimContent, "FOV Radius", 50, 500, 150, 0, function(v)
        Config.FOVRadius = v
    end)
    
    CreateSlider(aimContent, "Smoothness", 0, 1, 0.3, 2, function(v)
        Config.Smoothness = v
    end)
    
    CreateToggle(aimContent, "Mostrar FOV", true, function(v)
        Config.FOVVisible = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA ESP
    -- ═══════════════════════════════════════════════════════════════
    
    local espContent = tabContents["ESP"]
    
    CreateSectionHeader(espContent, "ESP")
    
    CreateToggle(espContent, "ESP Ativado", false, function(v)
        Config.ESPEnabled = v
    end)
    
    CreateToggle(espContent, "Caixas", true, function(v)
        Config.ESPBox = v
    end)
    
    CreateToggle(espContent, "Nomes", true, function(v)
        Config.ESPName = v
    end)
    
    CreateToggle(espContent, "Vida", true, function(v)
        Config.ESPHealth = v
    end)
    
    CreateToggle(espContent, "Distância", true, function(v)
        Config.ESPDistance = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA ARMAS (MELHORADA)
    -- ═══════════════════════════════════════════════════════════════
    
    local armasContent = tabContents["ARMAS"]
    
    CreateSectionHeader(armasContent, "Modificações de Armas")
    
    CreateToggle(armasContent, "Rapid Fire EXTREMO", false, function(v)
        Config.RapidFireEnabled = v
        if v then EnableRapidFire() else DisableGunMods() end
    end)
    
    CreateSlider(armasContent, "Fire Rate (menor=mais rápido)", 0.001, 0.5, 0.001, 3, function(v)
        Config.RapidFireRate = v
        if Config.RapidFireEnabled then
            ModifiedGuns = {}
            ApplyGunMods()
        end
    end)
    
    CreateToggle(armasContent, "Munição Infinita", false, function(v)
        Config.InfiniteAmmoEnabled = v
        if v then EnableInfiniteAmmo() else DisableGunMods() end
    end)
    
    CreateSpacer(armasContent, 4)
    CreateSectionHeader(armasContent, "Wallbang")
    
    CreateToggle(armasContent, "Atirar Através de Paredes", false, function(v)
        Config.WallbangEnabled = v
        if v then EnableWallbang() else DisableWallbang() end
    end)
    
    CreateSpacer(armasContent, 4)
    CreateSectionHeader(armasContent, "Hitbox")
    
    CreateToggle(armasContent, "Hitbox Expander", false, function(v)
        Config.HitboxEnabled = v
        if v then EnableHitbox() else DisableHitbox() end
    end)
    
    CreateSlider(armasContent, "Tamanho", 3, 25, 5, 0, function(v)
        Config.HitboxSize = v
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA MISC
    -- ═══════════════════════════════════════════════════════════════
    
    local miscContent = tabContents["MISC"]
    
    CreateSectionHeader(miscContent, "Movimento")
    
    CreateToggle(miscContent, "Speed Hack", false, function(v)
        Config.SpeedEnabled = v
        if v then EnableSpeed() else DisableSpeed() end
    end)
    
    CreateSlider(miscContent, "Velocidade (÷10)", 1, 50, 2, 0, function(v)
        Config.SpeedMultiplier = v / 10
    end)
    
    CreateDropdown(miscContent, "Modo Speed", {"CFrame", "Velocity", "Teleport"}, "CFrame", function(v)
        Config.SpeedBypassMode = v
    end)
    
    CreateToggle(miscContent, "NoClip", false, function(v)
        Config.NoClipEnabled = v
        if v then EnableNoClip() else DisableNoClip() end
    end)
    
    CreateSpacer(miscContent, 4)
    CreateSectionHeader(miscContent, "Fly")
    
    CreateToggle(miscContent, "Fly Hack", false, function(v)
        Config.FlyEnabled = v
        if v then EnableFly() else DisableFly() end
    end)
    
    CreateSlider(miscContent, "Fly Speed", 10, 200, 50, 0, function(v)
        Config.FlySpeed = v
    end)
    
    CreateSpacer(miscContent, 4)
    CreateSectionHeader(miscContent, "Informações")
    
    local infoBox = Instance.new("TextLabel")
    infoBox.Size = UDim2.new(1, 0, 0, 100)
    infoBox.BackgroundColor3 = Theme.Surface
    infoBox.Text = [[Jogo: ]] .. GameName .. [[

Dicas v9.0:
• Speed CFrame é mais seguro
• Rapid Fire 0.001 = EXTREMO
• Wallbang + Silent Aim = combo
• Bypass ativo automaticamente]]
    infoBox.TextColor3 = Theme.TextDim
    infoBox.TextSize = 10
    infoBox.Font = Enum.Font.Gotham
    infoBox.TextWrapped = true
    infoBox.TextYAlignment = Enum.TextYAlignment.Top
    infoBox.BorderSizePixel = 0
    infoBox.Parent = miscContent
    AddCorner(infoBox, 4)
    AddPadding(infoBox, 8)
    
    -- ═══════════════════════════════════════════════════════════════
    --                    ABA BYPASS (NOVA)
    -- ═══════════════════════════════════════════════════════════════
    
    local bypassContent = tabContents["BYPASS"]
    
    CreateSectionHeader(bypassContent, "Anti-Cheat Bypass")
    
    CreateToggle(bypassContent, "Bypass Anti-Cheat", true, function(v)
        Config.BypassAntiCheat = v
        if v then 
            BypassGameGuard()
            HookAntiCheatRemotes()
        end
    end)
    
    CreateToggle(bypassContent, "Spoofar WalkSpeed", true, function(v)
        Config.SpoofWalkSpeed = v
    end)
    
    CreateToggle(bypassContent, "Desabilitar GameGuard", true, function(v)
        Config.DisableGameGuard = v
        if v then BypassGameGuard() end
    end)
    
    CreateSpacer(bypassContent, 4)
    CreateSectionHeader(bypassContent, "Status")
    
    local statusBox = Instance.new("TextLabel")
    statusBox.Size = UDim2.new(1, 0, 0, 120)
    statusBox.BackgroundColor3 = Theme.Surface
    statusBox.Text = [[Status do Bypass:

• GameGuard: ]] .. (AntiCheatBypassed and "DESATIVADO ✓" or "ATIVO") .. [[

• Hook Remotes: ATIVO ✓
• Spoof WalkSpeed: ATIVO ✓
• NoClip Bypass: PRONTO ✓
• Fly Bypass: PRONTO ✓

Jogo detectado: ]] .. GameName
    statusBox.TextColor3 = Theme.Success
    statusBox.TextSize = 10
    statusBox.Font = Enum.Font.Gotham
    statusBox.TextWrapped = true
    statusBox.TextYAlignment = Enum.TextYAlignment.Top
    statusBox.BorderSizePixel = 0
    statusBox.Parent = bypassContent
    AddCorner(statusBox, 4)
    AddPadding(statusBox, 8)
end

-- ═══════════════════════════════════════════════════════════════
--                    LOOP PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local MainConnection = nil

local function MainLoop()
    MainConnection = RunService.RenderStepped:Connect(function()
        if Config.AimbotEnabled then
            local target, part = FindTarget()
            
            if target and part then
                State.Target = target
                State.TargetPart = part
                State.Locked = true
                
                if not Config.SilentAim then
                    AimAt(part.Position)
                end
            else
                State.Target = nil
                State.TargetPart = nil
                State.Locked = false
            end
        else
            State.Target = nil
            State.TargetPart = nil
            State.Locked = false
        end
        
        UpdateDrawings()
        
        for player, _ in pairs(ESPObjects) do
            UpdateESP(player)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    CLEANUP
-- ═══════════════════════════════════════════════════════════════

local function DestroyAll()
    if MainConnection then MainConnection:Disconnect() end
    
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    DisableSilentAim()
    DisableNoClip()
    DisableFly()
    DisableHitbox()
    DisableSpeed()
    DisableGunMods()
    DisableWallbang()
    DestroyDrawings()
    DestroyESP()
    
    if ScreenGui then ScreenGui:Destroy() end
    
    _G.SAVAGE_V9 = nil
end

_G.SAVAGE_V9 = true
_G.SAVAGE_V9_CLEANUP = DestroyAll

-- ═══════════════════════════════════════════════════════════════
--                    INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("═══════════════════════════════════════════════════")
    print("      SAVAGECHEATS_ AIMBOT UNIVERSAL v9.0 IMPROVED")
    print("═══════════════════════════════════════════════════")
    print("Jogo: " .. GameName)
    print("")
    print("NOVAS FUNÇÕES:")
    print("• Bypass Anti-Kick Avançado")
    print("• Wallbang (Atirar através de paredes)")
    print("• Rapid Fire EXTREMO (0.001)")
    print("• Munição Infinita CORRIGIDA")
    print("• Fly Hack com Bypass")
    print("")
    
    -- Aplicar bypass inicial
    if Config.BypassAntiCheat then
        BypassGameGuard()
        HookAntiCheatRemotes()
    end
    
    CreateUI()
    CreateDrawings()
    InitESP()
    MainLoop()
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        
        -- Reaplicar bypass
        if Config.BypassAntiCheat then
            AntiCheatBypassed = false
            NoClipBypassApplied = false
            BypassGameGuard()
        end
        
        if Config.NoClipEnabled then EnableNoClip() end
        if Config.SpeedEnabled then EnableSpeed() end
        if Config.FlyEnabled then EnableFly() end
        if Config.RapidFireEnabled or Config.InfiniteAmmoEnabled then
            ModifiedGuns = {}
            ApplyGunMods()
        end
        
        -- Reconectar eventos de armas
        if char then
            char.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    task.wait(0.1)
                    ModifyGunExtreme(child)
                end
            end)
        end
    end)
    
    print("═══════════════════════════════════════════════════")
    print("✓ Carregado! Clique no botão 'S' vermelho")
    print("═══════════════════════════════════════════════════")
end

Initialize()
