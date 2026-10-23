Aqui está um script único, pronto para copiar e colar no Roblox Studio. Ele inclui menu arrastável, minimizar, velocidade com botão Aplicar, Super Pulo ON/OFF, pontos de teleporte com salvar/renomear/excluir, configurações e encerramento com limpeza de conexões. O Auto Collect foi removido.

Cole como um `LocalScript` em `StarterPlayer > StarterPlayerScripts`.

lua
```

--[[
    WallBlackBR - Menu Universal
    Versão consolidada para Roblox Studio
    Recursos:
    - Menu arrastável e minimizável
    - Velocidade com botão Aplicar
    - Super Pulo ON/OFF
    - Salvar, selecionar, renomear e excluir TPs
    - Gerenciador de recursos e encerramento seguro
    - Sem Auto Collect
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CFG = {
    walkSpeed = 16,
    jumpPower = 100,
}

local State = {
    closed = false,
    minimized = false,
    superJump = false,
    character = nil,
    humanoid = nil,
    points = {},
    selectedPoint = nil,
    originalJumpPower = nil,
    originalJumpHeight = nil,
    originalUseJumpPower = nil,
}

local Connections = {}
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(Connections, c)
    return c
end

local function disconnectAll()
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Connections)
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local gui = make("ScreenGui", {
    Name = "WallBlackBR_Menu",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(300, 440),
    Position = UDim2.new(0, 24, 0, 60),
    BackgroundColor3 = Color3.fromRGB(12, 12, 17),
    BorderSizePixel = 0,
    Active = true,
}, gui)

make("UICorner", {CornerRadius = UDim.new(0, 12)}, main)
make("UIStroke", {
    Color = Color3.fromRGB(55, 55, 70),
    Thickness = 1,
}, main)

local title = make("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Color3.fromRGB(24, 24, 32),
    BorderSizePixel = 0,
}, main)

make("UICorner", {CornerRadius = UDim.new(0, 12)}, title)

make("TextLabel", {
    Size = UDim2.new(1, -90, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "WallBlackBR",
    TextColor3 = Color3.fromRGB(255, 55, 55),
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, title)

local minimize = make("TextButton", {
    Size = UDim2.fromOffset(28, 26),
    Position = UDim2.new(1, -70, 0, 8),
    Text = "-",
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.fromRGB(45, 45, 58),
    BorderSizePixel = 0,
}, title)

local close = make("TextButton", {
    Size = UDim2.fromOffset(28, 26),
    Position = UDim2.new(1, -36, 0, 8),
    Text = "X",
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.new(1, 1, 1),
    BackgroundColor3 = Color3.fromRGB(150, 35, 35),
    BorderSizePixel = 0,
}, title)

local content = make("ScrollingFrame", {
    Name = "Content",
    Position = UDim2.fromOffset(0, 46),
    Size = UDim2.new(1, 0, 1, -46),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)

make("UIPadding", {
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    PaddingBottom = UDim.new(0, 12),
}, content)

make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, content)

local function label(text, height)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, height or 25),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(220, 220, 230),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, content)
end

local function button(text, color)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = color or Color3.fromRGB(38, 38, 50),
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        AutoButtonColor = true,
    }, content)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    return b
end

local function textbox(placeholder, value)
    local t = make("TextBox", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Color3.fromRGB(28, 28, 38),
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Color3.fromRGB(130, 130, 145),
        PlaceholderText = placeholder,
        Text = value or "",
        ClearTextOnFocus = false,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
    }, content)
    make("UICorner", {CornerRadius = UDim.new(0, 7)}, t)
    return t
end

-- Arrastar o menu usando a barra de título
local dragging = false
local dragStart, startPosition

connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart
    main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Velocidade: digitar não aplica; somente o botão aplica
label("VELOCIDADE DE CAMINHADA")
local speedBox = textbox("Velocidade desejada", "16")
local applySpeed = button("Aplicar velocidade", Color3.fromRGB(35, 130, 75))
local speedStatus = label("Velocidade: aguardando aplicação", 22)

local function applyWalkSpeed()
    if State.closed or not State.humanoid then
        speedStatus.Text = "Personagem indisponível"
        return
    end

    local value = tonumber(speedBox.Text)
    if not value or value ~= value then
        speedStatus.Text = "Digite um número válido"
        return
    end

    value = math.clamp(value, 0, 500)
    CFG.walkSpeed = value
    speedBox.Text = tostring(value)

    local ok = pcall(function()
        State.humanoid.WalkSpeed = value
    end)

    speedStatus.Text = ok and ("Velocidade aplicada: " .. value)
        or "Não foi possível aplicar"
end

connect(applySpeed.MouseButton1Click, applyWalkSpeed)

-- Super Pulo
label("MOVIMENTO")
local jumpButton = button("Super Pulo: OFF")
local jumpBox = textbox("JumpPower (padrão: 100)", "100")

local function stopSuperJump()
    State.superJump = false
    local hum = State.humanoid

    if hum then
        pcall(function()
            if State.originalUseJumpPower ~= nil then
                hum.UseJumpPower = State.originalUseJumpPower
            end
            if State.originalJumpPower ~= nil then
                hum.JumpPower = State.originalJumpPower
            end
            if State.originalJumpHeight ~= nil then
                hum.JumpHeight = State.originalJumpHeight
            end
        end)
    end

    State.originalJumpPower = nil
    State.originalJumpHeight = nil
    State.originalUseJumpPower = nil
    jumpButton.Text = "Super Pulo: OFF"
end

local function startSuperJump()
    local hum = State.humanoid
    if not hum then return end

    local value = tonumber(jumpBox.Text)
    if not value or value ~= value then value = 100 end
    value = math.clamp(value, 1, 300)
    jumpBox.Text = tostring(value)

    State.originalUseJumpPower = hum.UseJumpPower
    State.originalJumpPower = hum.JumpPower
    State.originalJumpHeight = hum.JumpHeight
    State.superJump = true

    if hum.UseJumpPower then
        hum.JumpPower = value
    else
        hum.JumpHeight = math.clamp(value / 4, 1, 100)
    end

    jumpButton.Text = "Super Pulo: ON"
end

connect(jumpButton.MouseButton1Click, function()
    if State.superJump then
        stopSuperJump()
    else
        startSuperJump()
    end
end)

-- Gerenciador de pontos de teleporte locais
label("PONTOS DE TELEPORTE")
local savePointButton = button("Salvar posição atual")
local pointNameBox = textbox("Nome do ponto", "Meu ponto")
local renameButton = button("Renomear ponto selecionado")
local teleportButton = button("Ir ao ponto selecionado",
    Color3.fromRGB(35, 90, 145))
local deleteButton = button("Excluir ponto selecionado",
    Color3.fromRGB(145, 45, 45))
local pointStatus = label("Nenhum ponto selecionado", 22)
local pointList = make("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
}, content)

make("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, pointList)

local function refreshPoints()
    for _, child in ipairs(pointList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for i, point in ipairs(State.points) do
        local b = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = State.selectedPoint == i
                and Color3.fromRGB(55, 90, 65)
                or Color3.fromRGB(32, 32, 43),
            Text = point.name,
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            BorderSizePixel = 0,
            LayoutOrder = i,
        }, pointList)

        connect(b.MouseButton1Click, function()
            if State.closed then return end
            State.selectedPoint = i
            pointNameBox.Text = point.name
            pointStatus.Text = "Selecionado: " .. point.name
            refreshPoints()
        end)
    end
end

connect(savePointButton.MouseButton1Click, function()
    if not State.humanoid or not State.character then return end

    local root = State.character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local name = pointNameBox.Text
    if name == "" then name = "Ponto " .. (#State.points + 1) end

    table.insert(State.points, {
        name = name,
        cframe = root.CFrame,
    })

    State.selectedPoint = #State.points
    pointStatus.Text = "Ponto salvo: " .. name
    refreshPoints()
end)

connect(renameButton.MouseButton1Click, function()
    local index = State.selectedPoint
    local point = index and State.points[index]
    if not point then
        pointStatus.Text = "Selecione um ponto primeiro"
        return
    end

    local name = pointNameBox.Text:match("^%s*(.-)%s*$")
    if name == "" then
        pointStatus.Text = "Digite um nome válido"
        return
    end

    point.name = string.sub(name, 1, 32)
    pointStatus.Text = "Ponto renomeado: " .. point.name
    refreshPoints()
end)

connect(teleportButton.MouseButton1Click, function()
    local index = State.selectedPoint
    local point = index and State.points[index]
    local root = State.character
        and State.character:FindFirstChild("HumanoidRootPart")

    if not point or not root then
        pointStatus.Text = "Selecione um ponto e aguarde o personagem"
        return
    end

    root.CFrame = point.cframe
    pointStatus.Text = "Teleportado para: " .. point.name
end)

connect(deleteButton.MouseButton1Click, function()
    local index = State.selectedPoint
    if not index or not State.points[index] then
        pointStatus.Text = "Selecione um ponto primeiro"
        return
    end

    table.remove(State.points, index)
    State.selectedPoint = nil
    pointStatus.Text = "Ponto excluído"
    refreshPoints()
end)

-- Configurações do menu
label("CONFIGURAÇÕES")
local settingsStatus = label("Configurações desta sessão", 22)

local function onCharacterAdded(character)
    if State.closed then return end

    State.character = character
    State.humanoid = character:WaitForChild("Humanoid", 10)

    if not State.humanoid then return end

    State.humanoid.WalkSpeed = CFG.walkSpeed

    if State.superJump then
        State.superJump = false
        startSuperJump()
    end

    speedStatus.Text = "Velocidade atual: " ..
        tostring(State.humanoid.WalkSpeed)
end

connect(player.CharacterAdded, onCharacterAdded)

if player.Character then
    task.spawn(onCharacterAdded, player.Character)
end

-- Minimizar e restaurar
local expandedSize = UDim2.fromOffset(300, 440)

connect(minimize.MouseButton1Click, function()
    if State.closed then return end

    State.minimized = not State.minimized
    if State.minimized then
        expandedSize = main.Size
        main.Size = UDim2.fromOffset(300, 42)
        content.Visible = false
        minimize.Text = "+"
    else
        main.Size = expandedSize
        content.Visible = true
        minimize.Text = "-"
    end
end)

-- Encerramento seguro
local function shutdown()
    if State.closed then return end
    State.closed = true

    if State.superJump then
        stopSuperJump()
    end

    disconnectAll()
    gui:Destroy()
end

connect(close.MouseButton1Click, shutdown)

print("WallBlackBR carregado.")
