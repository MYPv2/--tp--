-- ============================================
-- Ctrl + TP v3.0 PREMIUM | Toggle T | Anti-Rollback
-- Detección Server Authority | Cooldown randomizado | Indicador
-- ============================================
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local CONFIG = {
    keybindToggle = Enum.KeyCode.T,
    offsetY = 3,
    cooldownMin = 0.10,       -- cooldown mínimo
    cooldownMax = 0.25,       -- cooldown máximo (randomizado)
    onlyIfTarget = false,
    detectRollback = true,    -- 🔥 detectar si el servidor te devuelve
    rollbackThreshold = 10,   -- studs de diferencia para considerar rollback
    showIndicator = true,
}

local activo = true
local cooldownActivo = false
local indicatorLabel = nil

-- ============================================
-- INDICADOR
-- ============================================
local function crearIndicador()
    if not CONFIG.showIndicator then return end
    if indicatorLabel and indicatorLabel.Parent then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CtrlTPIndicator"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true

    local ok = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 0, 28)
    label.Position = UDim2.new(0, 10, 0, 90)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.TextColor3 = Color3.fromRGB(0, 255, 150)
    label.Text = "CTRL+TP: ON"
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.Parent = gui

    indicatorLabel = label
end

local function actualizarIndicador()
    if not indicatorLabel then return end
    if activo then
        indicatorLabel.Text = "CTRL+TP: ON"
        indicatorLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    else
        indicatorLabel.Text = "CTRL+TP: OFF"
        indicatorLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- ============================================
-- FUNCIONES
-- ============================================
local function GetCharacter()
    return LocalPlayer.Character
end

local function Teleport(pos)
    local Char = GetCharacter()
    if not Char then return nil end

    local HRP = Char:FindFirstChild("HumanoidRootPart")
    local posFinal = pos + Vector3.new(0, CONFIG.offsetY, 0)

    if HRP then
        HRP.CFrame = CFrame.new(posFinal)
    else
        Char:MoveTo(pos)
    end
    return posFinal
end

-- 🔥 Detectar si el servidor revirtió el teleporte
local function detectarRollback(posNueva)
    if not CONFIG.detectRollback then return false end

    task.wait(0.25)

    local Char = GetCharacter()
    if not Char or not Char.PrimaryPart then return false end

    local posActual = Char.PrimaryPart.Position
    local distancia = (posActual - posNueva).Magnitude

    if distancia > CONFIG.rollbackThreshold then
        print("[Ctrl+TP] ⚠️ Server Authority detectado. Teleporte revertido.")
        if indicatorLabel then
            indicatorLabel.Text = "CTRL+TP: BLOCKED"
            indicatorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.wait(2)
            actualizarIndicador()
        end
        return true
    end
    return false
end

-- ============================================
-- CTRL + CLICK
-- ============================================
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not activo then return end
    if cooldownActivo then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1
    and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then

        if CONFIG.onlyIfTarget and not Mouse.Target then return end

        local pos = Mouse.Hit and Mouse.Hit.p
        if pos then
            cooldownActivo = true

            local posNueva
            pcall(function()
                posNueva = Teleport(pos)
            end)

            if posNueva then
                task.spawn(function()
                    detectarRollback(posNueva)
                end)
            end

            -- 🔥 Cooldown randomizado
            local cooldownRandom = CONFIG.cooldownMin + math.random() * (CONFIG.cooldownMax - CONFIG.cooldownMin)
            task.wait(cooldownRandom)
            cooldownActivo = false
        end
    end
end)

-- ============================================
-- TOGGLE CON TECLA T
-- ============================================
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == CONFIG.keybindToggle then
        activo = not activo
        actualizarIndicador()
        print("[Ctrl+TP] " .. (activo and "✅ ACTIVADO" or "❌ DESACTIVADO"))
    end
end)

-- ============================================
-- RESET AL RESPAWNEAR
-- ============================================
LocalPlayer.CharacterAdded:Connect(function()
    cooldownActivo = false
    actualizarIndicador()
end)

-- ============================================
-- INIT
-- ============================================
crearIndicador()
actualizarIndicador()

print("[Ctrl+TP v3.0 PREMIUM] Cargado ✅ | Ctrl + Click | T toggle")
print("  Cooldown: " .. CONFIG.cooldownMin .. "s - " .. CONFIG.cooldownMax .. "s (randomizado)")
print("  Detección de rollback: " .. tostring(CONFIG.detectRollback))
