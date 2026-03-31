local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local cfg = {
    enabled = true,
    outlineColor = Color3.fromRGB(0, 255, 0),
    fillColor = Color3.fromRGB(0, 255, 0),
    fillTransparency = 0.85,
    showName = true,
    showDistance = true,
    maxDistance = 750,
    guiVisible = true,
    espToggleKey = Enum.KeyCode.F,
    guiToggleKey = Enum.KeyCode.RightControl,
    guiPosition = {X = 1, Y = 0, OffsetX = -240, OffsetY = 12}
}

local espObjects = {}
local gui = nil
local activeColorPicker = nil
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function savePosition()
    if gui and gui.MainFrame then
        local pos = gui.MainFrame.Position
        cfg.guiPosition = {
            X = pos.X.Scale,
            Y = pos.Y.Scale,
            OffsetX = pos.X.Offset,
            OffsetY = pos.Y.Offset
        }
    end
end

local function updateESPColors()
    for _, data in pairs(espObjects) do
        if data.highlight then
            data.highlight.OutlineColor = cfg.outlineColor
            data.highlight.FillColor = cfg.fillColor
            data.highlight.FillTransparency = cfg.fillTransparency
        end
        if data.nameLabel then
            data.nameLabel.TextColor3 = cfg.outlineColor
        end
    end
end

local function createHighlight(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Parent = character
    highlight.Adornee = character
    highlight.FillColor = cfg.fillColor
    highlight.FillTransparency = cfg.fillTransparency
    highlight.OutlineColor = cfg.outlineColor
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true

    return highlight
end

local function createBillboard(character, targetPlayer)
    if not character or not character:FindFirstChild("Head") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Parent = character.Head
    billboard.Size = UDim2.new(0, 140, 0, 28)
    billboard.StudsOffset = Vector3.new(0, 2.2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = cfg.maxDistance

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = cfg.outlineColor
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.TextScaled = true
    nameLabel.Visible = cfg.showName
    nameLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = ""
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0.2
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 9
    distanceLabel.TextScaled = true
    distanceLabel.Visible = cfg.showDistance
    distanceLabel.Parent = billboard

    return {billboard = billboard, nameLabel = nameLabel, distanceLabel = distanceLabel}
end

local function updateDistance()
    if not camera or not cfg.enabled then return end

    for _, data in pairs(espObjects) do
        if data.billboard and data.character and data.character:FindFirstChild("HumanoidRootPart") then
            local distance = (camera.CFrame.Position - data.character.HumanoidRootPart.Position).Magnitude
            if data.distanceLabel and cfg.showDistance then
                if distance <= cfg.maxDistance then
                    data.distanceLabel.Text = string.format("%.0fm", distance)
                    if distance < 50 then
                        data.distanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    elseif distance < 100 then
                        data.distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        data.distanceLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
                    end
                    data.distanceLabel.Visible = true
                else
                    data.distanceLabel.Visible = false
                end
            end
        end
    end
end

local function addESP(targetPlayer)
    if targetPlayer == player then return end
    if espObjects[targetPlayer] then return end

    local character = targetPlayer.Character
    if not character then return end

    local highlight = createHighlight(character)
    local billboardData = nil

    if cfg.showName or cfg.showDistance then
        billboardData = createBillboard(character, targetPlayer)
    end

    espObjects[targetPlayer] = {
        character = character,
        highlight = highlight,
        billboard = billboardData and billboardData.billboard,
        nameLabel = billboardData and billboardData.nameLabel,
        distanceLabel = billboardData and billboardData.distanceLabel,
        player = targetPlayer
    }
    
    local function onCharacterRemoved()
        removeESP(targetPlayer)
    end
    
    local function onCharacterAdded(newChar)
        task.wait(0.5)
        if cfg.enabled and targetPlayer ~= player then
            addESP(targetPlayer)
        end
    end
    
    targetPlayer.CharacterRemoving:Connect(onCharacterRemoved)
    targetPlayer.CharacterAdded:Connect(onCharacterAdded)
end

local function removeESP(targetPlayer)
    local data = espObjects[targetPlayer]
    if data then
        if data.highlight then data.highlight:Destroy() end
        if data.billboard then data.billboard:Destroy() end
        espObjects[targetPlayer] = nil
    end
end

local function refreshAllESP()
    for targetPlayer, _ in pairs(espObjects) do
        removeESP(targetPlayer)
    end
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            addESP(targetPlayer)
        end
    end
end

local function toggleESP(state)
    cfg.enabled = state
    if state then
        refreshAllESP()
    else
        for targetPlayer, _ in pairs(espObjects) do
            removeESP(targetPlayer)
        end
    end
end

local function updateBillboardVisibility()
    for _, data in pairs(espObjects) do
        if data.nameLabel then
            data.nameLabel.Visible = cfg.showName
        end
        if data.distanceLabel then
            data.distanceLabel.Visible = cfg.showDistance
        end
    end
end

local function createTransparencyInput(parent, name, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -16, 0, 38)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(0.85, 0.85, 0.85)
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0, 75, 0, 24)
    inputBox.Position = UDim2.new(1, -79, 0, -2)
    inputBox.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
    inputBox.Text = string.format("%.3f", getter())
    inputBox.TextColor3 = Color3.new(1, 1, 1)
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextSize = 10
    inputBox.PlaceholderText = "0.000-1.000"
    inputBox.BorderSizePixel = 0
    inputBox.Parent = frame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = inputBox

    inputBox.FocusLost:Connect(function(enterPressed)
        local val = tonumber(inputBox.Text)
        if val then
            val = math.clamp(val, 0, 1)
            setter(val)
            inputBox.Text = string.format("%.3f", val)
            updateESPColors()
        else
            inputBox.Text = string.format("%.3f", getter())
        end
    end)

    return frame
end

local function createColorPicker(parent, name, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -16, 0, 38)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(0.85, 0.85, 0.85)
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local colorDisplay = Instance.new("Frame")
    colorDisplay.Size = UDim2.new(0, 45, 0, 22)
    colorDisplay.Position = UDim2.new(1, -49, 0, -1)
    colorDisplay.BackgroundColor3 = getter()
    colorDisplay.BorderSizePixel = 0
    colorDisplay.Parent = frame

    local displayCorner = Instance.new("UICorner")
    displayCorner.CornerRadius = UDim.new(0, 4)
    displayCorner.Parent = colorDisplay

    local pickerFrame = Instance.new("Frame")
    pickerFrame.Size = UDim2.new(0, 160, 0, 150)
    pickerFrame.Position = UDim2.new(0, 0, 0, 24)
    pickerFrame.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
    pickerFrame.BackgroundTransparency = 0.05
    pickerFrame.BorderSizePixel = 0
    pickerFrame.Visible = false
    pickerFrame.ZIndex = 20
    pickerFrame.Parent = frame

    local pickerCorner = Instance.new("UICorner")
    pickerCorner.CornerRadius = UDim.new(0, 6)
    pickerCorner.Parent = pickerFrame

    local scrollPick = Instance.new("ScrollingFrame")
    scrollPick.Size = UDim2.new(1, -8, 1, -8)
    scrollPick.Position = UDim2.new(0, 4, 0, 4)
    scrollPick.BackgroundTransparency = 1
    scrollPick.BorderSizePixel = 0
    scrollPick.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollPick.ScrollBarThickness = 4
    scrollPick.Parent = pickerFrame

    local colorContainer = Instance.new("Frame")
    colorContainer.Size = UDim2.new(1, 0, 0, 0)
    colorContainer.BackgroundTransparency = 1
    colorContainer.Parent = scrollPick

    local colors = {
        Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 200, 200), Color3.fromRGB(255, 150, 150), Color3.fromRGB(255, 100, 100), Color3.fromRGB(255, 50, 50), Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 255, 200), Color3.fromRGB(255, 255, 150), Color3.fromRGB(255, 255, 100), Color3.fromRGB(255, 255, 50), Color3.fromRGB(255, 255, 0), Color3.fromRGB(200, 200, 0),
        Color3.fromRGB(200, 255, 200), Color3.fromRGB(150, 255, 150), Color3.fromRGB(100, 255, 100), Color3.fromRGB(50, 255, 50), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 200, 0),
        Color3.fromRGB(200, 255, 255), Color3.fromRGB(150, 255, 255), Color3.fromRGB(100, 255, 255), Color3.fromRGB(50, 255, 255), Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 200, 200),
        Color3.fromRGB(200, 200, 255), Color3.fromRGB(150, 150, 255), Color3.fromRGB(100, 100, 255), Color3.fromRGB(50, 50, 255), Color3.fromRGB(0, 0, 255), Color3.fromRGB(0, 0, 200),
        Color3.fromRGB(255, 200, 255), Color3.fromRGB(255, 150, 255), Color3.fromRGB(255, 100, 255), Color3.fromRGB(255, 50, 255), Color3.fromRGB(255, 0, 255), Color3.fromRGB(200, 0, 200),
    }

    local btnSize = 26
    local spacing = 2
    local cols = 5
    local row = 0
    local col = 0

    for i, color in ipairs(colors) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, btnSize, 0, btnSize)
        btn.Position = UDim2.new(0, col * (btnSize + spacing), 0, row * (btnSize + spacing))
        btn.BackgroundColor3 = color
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.ZIndex = 21
        btn.Parent = colorContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            setter(color)
            colorDisplay.BackgroundColor3 = color
            updateESPColors()
            pickerFrame.Visible = false
            activeColorPicker = nil
        end)

        col = col + 1
        if col >= cols then
            col = 0
            row = row + 1
        end
    end

    local totalHeight = (row + 1) * (btnSize + spacing) - spacing
    colorContainer.Size = UDim2.new(0, cols * (btnSize + spacing) - spacing, 0, totalHeight)
    scrollPick.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 8)

    colorDisplay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if activeColorPicker and activeColorPicker ~= pickerFrame then
                activeColorPicker.Visible = false
            end
            pickerFrame.Visible = not pickerFrame.Visible
            activeColorPicker = pickerFrame.Visible and pickerFrame or nil
        end
    end)

    return frame
end

local function createCheckbox(parent, name, getter, setter, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -16, 0, 24)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.Position = UDim2.new(0, 0, 0, 2)
    btn.Text = getter() and "✓ " .. name or "○ " .. name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextStrokeTransparency = 0.5
    btn.BorderSizePixel = 0
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local newState = not getter()
        setter(newState)
        btn.Text = newState and "✓ " .. name or "○ " .. name
        if callback then callback(newState) end
    end)

    return frame
end

local function createKeybind(parent, name, getter, setter)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -16, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 22)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(0.85, 0.85, 0.85)
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 65, 0, 22)
    keyBtn.Position = UDim2.new(1, -69, 0, 0)
    keyBtn.Text = getter().Name
    keyBtn.TextColor3 = Color3.new(1, 1, 1)
    keyBtn.BackgroundColor3 = Color3.new(0.18, 0.18, 0.18)
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 10
    keyBtn.BorderSizePixel = 0
    keyBtn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = keyBtn

    local binding = false

    keyBtn.MouseButton1Click:Connect(function()
        binding = true
        keyBtn.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, proc)
            if proc or not binding then return end
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                setter(input.KeyCode)
                keyBtn.Text = input.KeyCode.Name
                binding = false
                conn:Disconnect()
            end
        end)
        task.wait(3)
        if binding then
            binding = false
            keyBtn.Text = getter().Name
        end
    end)

    return frame
end

local function createGUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "ESP_GUI"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    gui.Enabled = cfg.guiVisible

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 220, 0, 310)
    main.Position = UDim2.new(cfg.guiPosition.X, cfg.guiPosition.OffsetX, cfg.guiPosition.Y, cfg.guiPosition.OffsetY)
    main.BackgroundColor3 = Color3.new(0.08, 0.08, 0.08)
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.Parent = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = main

    local dragBar = Instance.new("Frame")
    dragBar.Size = UDim2.new(1, 0, 0, 28)
    dragBar.BackgroundColor3 = Color3.new(0.12, 0.12, 0.12)
    dragBar.BorderSizePixel = 0
    dragBar.Parent = main

    local dragCorner = Instance.new("UICorner")
    dragCorner.CornerRadius = UDim.new(0, 10)
    dragCorner.Parent = dragBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "👁 ESP"
    title.TextColor3 = Color3.new(0.4, 0.9, 0.4)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = dragBar

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -32)
    scrollFrame.Position = UDim2.new(0, 0, 0, 28)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.new(0.4, 0.4, 0.4)
    scrollFrame.Parent = main

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = scrollFrame

    local yPos = 4

    local function addElement(element)
        element.Position = UDim2.new(0, 8, 0, yPos)
        yPos = yPos + element.Size.Y.Offset + 2
        container.Size = UDim2.new(1, 0, 0, yPos + 4)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 8)
        return element
    end

    addElement(createCheckbox(container, "ESP", function() return cfg.enabled end, function(v) toggleESP(v) end, nil))
    addElement(createTransparencyInput(container, "ALPHA", function() return cfg.fillTransparency end, function(v) cfg.fillTransparency = v end))
    addElement(createColorPicker(container, "OUTLINE", function() return cfg.outlineColor end, function(v) cfg.outlineColor = v end))
    addElement(createColorPicker(container, "FILL", function() return cfg.fillColor end, function(v) cfg.fillColor = v end))
    addElement(createCheckbox(container, "NAMES", function() return cfg.showName end, function(v) cfg.showName = v; updateBillboardVisibility() end, nil))
    addElement(createCheckbox(container, "DISTANCE", function() return cfg.showDistance end, function(v) cfg.showDistance = v; updateBillboardVisibility() end, nil))
    addElement(createKeybind(container, "ESP KEY", function() return cfg.espToggleKey end, function(v) cfg.espToggleKey = v end))
    addElement(createKeybind(container, "GUI KEY", function() return cfg.guiToggleKey end, function(v) cfg.guiToggleKey = v end))

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position

            dragInput = UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = inp.Position - dragStart
                    main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end
    end)

    dragBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if dragInput then dragInput:Disconnect() end
            savePosition()
        end
    end)

    return gui
end

local function toggleGUI()
    cfg.guiVisible = not cfg.guiVisible
    if gui then
        gui.Enabled = cfg.guiVisible
    end
    if not cfg.guiVisible and activeColorPicker then
        activeColorPicker.Visible = false
        activeColorPicker = nil
    end
end

createGUI()

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == cfg.guiToggleKey then
        toggleGUI()
    elseif input.KeyCode == cfg.espToggleKey then
        toggleESP(not cfg.enabled)
    end
end)

local function onPlayerAdded(targetPlayer)
    if targetPlayer == player then return end
    if cfg.enabled then
        addESP(targetPlayer)
    end
    targetPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if cfg.enabled and targetPlayer ~= player then
            addESP(targetPlayer)
        end
    end)
end

local function onPlayerRemoving(targetPlayer)
    removeESP(targetPlayer)
end

for _, targetPlayer in ipairs(Players:GetPlayers()) do
    if targetPlayer ~= player then
        onPlayerAdded(targetPlayer)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Первый Heartbeat для обновления ESP
RunService.Heartbeat:Connect(function()
    if not cfg.enabled then return end
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            if targetPlayer.Character and not espObjects[targetPlayer] then
                addESP(targetPlayer)
            elseif not targetPlayer.Character and espObjects[targetPlayer] then
                removeESP(targetPlayer)
            end
        end
    end
    
    updateDistance()
end)

print("[ESP] Loaded | " .. cfg.espToggleKey.Name .. " to toggle | " .. cfg.guiToggleKey.Name .. " to toggle GUI")

-- Сохраняем оригинальные функции
local originalAddESP = addESP
local originalRemoveESP = removeESP

-- Создаем надежную систему отслеживания респавна
local playerRespawnTrack = {}

local function forceRefreshESP(targetPlayer)
    if targetPlayer == player then return end
    if not cfg.enabled then return end
    
    if espObjects[targetPlayer] then
        originalRemoveESP(targetPlayer)
    end
    
    task.wait(0.3)
    
    if targetPlayer.Character then
        originalAddESP(targetPlayer)
    end
end

local function trackPlayerRespawn(targetPlayer)
    if targetPlayer == player then return end
    if playerRespawnTrack[targetPlayer] then return end
    
    playerRespawnTrack[targetPlayer] = true
    
    local function onCharacterAdded(character)
        task.wait(0.8)
        
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            forceRefreshESP(targetPlayer)
        end
    end
    
    local function onCharacterRemoving()
        if espObjects[targetPlayer] then
            originalRemoveESP(targetPlayer)
        end
    end
    
    targetPlayer.CharacterAdded:Connect(onCharacterAdded)
    targetPlayer.CharacterRemoving:Connect(onCharacterRemoving)
    
    if targetPlayer.Character then
        local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            task.wait(0.5)
            forceRefreshESP(targetPlayer)
        end
    end
end

-- Переопределяем функцию добавления игрока
local originalOnPlayerAdded = onPlayerAdded

onPlayerAdded = function(targetPlayer)
    if targetPlayer == player then return end
    
    if originalOnPlayerAdded then
        originalOnPlayerAdded(targetPlayer)
    end
    
    trackPlayerRespawn(targetPlayer)
end

-- Применяем ко всем существующим игрокам
for _, targetPlayer in ipairs(Players:GetPlayers()) do
    if targetPlayer ~= player then
        trackPlayerRespawn(targetPlayer)
    end
end

-- Второй Heartbeat для проверки респавна
RunService.Heartbeat:Connect(function()
    if not cfg.enabled then return end
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local character = targetPlayer.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            local isAlive = humanoid and humanoid.Health > 0
            
            if isAlive and not espObjects[targetPlayer] then
                forceRefreshESP(targetPlayer)
            end
            
            if not isAlive and espObjects[targetPlayer] then
                originalRemoveESP(targetPlayer)
            end
        end
    end
end)

print("[ESP] ESP fully loaded | Players will be highlighted after respawn")
