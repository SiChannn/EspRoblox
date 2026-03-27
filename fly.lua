local Players=game:GetService"Players"
local RunService=game:GetService"RunService"
local UserInputService=game:GetService"UserInputService"
local Workspace=game:GetService"Workspace"
local CoreGui=game:GetService"CoreGui"

local player=Players.LocalPlayer
local camera=Workspace.CurrentCamera

local cfg={
    speed=100,
    minSpeed=10,
    maxSpeed=500,
    rotSpeed=12,
    noclip=true,
    toggleKey=Enum.KeyCode.F,
    guiToggleKey=Enum.KeyCode.RightControl
}

local char,hum,root=nil,nil,nil
local flying=false
local speedMult=1
local keys={W=false,A=false,S=false,D=false,Space=false,LeftShift=false}
local guiVisible=true
local gui=nil

local function createGUI()
    gui=Instance.new("ScreenGui")
    gui.Name="FlyGUI"
    gui.Parent=CoreGui
    gui.ResetOnSpawn=false
    
    local main=Instance.new("Frame")
    main.Size=UDim2.new(0,200,0,110)
    main.Position=UDim2.new(0,12,0,12)
    main.BackgroundColor3=Color3.new(0.08,0.08,0.08)
    main.BackgroundTransparency=0.25
    main.BorderSizePixel=0
    main.Parent=gui
    
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,8)
    corner.Parent=main
    
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,32)
    title.Position=UDim2.new(0,0,0,0)
    title.BackgroundTransparency=1
    title.Text="✈ Fly - by SiChan"
    title.TextColor3=Color3.new(0.4,0.9,0.4)
    title.Font=Enum.Font.GothamBold
    title.TextSize=14
    title.Parent=main
    
    local line=Instance.new("Frame")
    line.Size=UDim2.new(1,-20,0,1)
    line.Position=UDim2.new(0,10,0,32)
    line.BackgroundColor3=Color3.new(0.3,0.3,0.3)
    line.BorderSizePixel=0
    line.Parent=main
    
    local speedFrame=Instance.new("Frame")
    speedFrame.Size=UDim2.new(1,-20,0,40)
    speedFrame.Position=UDim2.new(0,10,0,38)
    speedFrame.BackgroundTransparency=1
    speedFrame.Parent=main
    
    local speedLabel=Instance.new("TextLabel")
    speedLabel.Size=UDim2.new(0,50,0,18)
    speedLabel.Position=UDim2.new(0,0,0,0)
    speedLabel.BackgroundTransparency=1
    speedLabel.Text="SPEED"
    speedLabel.TextColor3=Color3.new(0.8,0.8,0.8)
    speedLabel.Font=Enum.Font.GothamBold
    speedLabel.TextSize=11
    speedLabel.TextXAlignment=Enum.TextXAlignment.Left
    speedLabel.Parent=speedFrame
    
    local speedVal=Instance.new("TextLabel")
    speedVal.Size=UDim2.new(0,60,0,18)
    speedVal.Position=UDim2.new(1,-60,0,0)
    speedVal.BackgroundTransparency=1
    speedVal.Text="100"
    speedVal.TextColor3=Color3.new(0.4,0.8,1)
    speedVal.Font=Enum.Font.GothamBold
    speedVal.TextSize=12
    speedVal.TextXAlignment=Enum.TextXAlignment.Right
    speedVal.Parent=speedFrame
    
    local sliderBg=Instance.new("Frame")
    sliderBg.Size=UDim2.new(1,0,0,4)
    sliderBg.Position=UDim2.new(0,0,0,22)
    sliderBg.BackgroundColor3=Color3.new(0.25,0.25,0.25)
    sliderBg.BorderSizePixel=0
    sliderBg.Parent=speedFrame
    
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((cfg.speed-cfg.minSpeed)/(cfg.maxSpeed-cfg.minSpeed),0,1,0)
    fill.BackgroundColor3=Color3.new(0.3,0.7,1)
    fill.BorderSizePixel=0
    fill.Parent=sliderBg
    
    local sliderHitbox=Instance.new("TextButton")
    sliderHitbox.Size=UDim2.new(1,0,1,2)
    sliderHitbox.Position=UDim2.new(0,0,-1,0)
    sliderHitbox.BackgroundTransparency=1
    sliderHitbox.Text=""
    sliderHitbox.AutoButtonColor=false
    sliderHitbox.Parent=sliderBg
    
    local keyFrame=Instance.new("Frame")
    keyFrame.Size=UDim2.new(1,-20,0,28)
    keyFrame.Position=UDim2.new(0,10,0,82)
    keyFrame.BackgroundTransparency=1
    keyFrame.Parent=main
    
    local keyLabel=Instance.new("TextLabel")
    keyLabel.Size=UDim2.new(0,50,1,0)
    keyLabel.BackgroundTransparency=1
    keyLabel.Text="TOGGLE"
    keyLabel.TextColor3=Color3.new(0.8,0.8,0.8)
    keyLabel.Font=Enum.Font.GothamBold
    keyLabel.TextSize=11
    keyLabel.TextXAlignment=Enum.TextXAlignment.Left
    keyLabel.Parent=keyFrame
    
    local keyBtn=Instance.new("TextButton")
    keyBtn.Size=UDim2.new(0,55,0,24)
    keyBtn.Position=UDim2.new(1,-55,0,2)
    keyBtn.Text="F"
    keyBtn.TextColor3=Color3.new(1,1,1)
    keyBtn.BackgroundColor3=Color3.new(0.25,0.25,0.25)
    keyBtn.Font=Enum.Font.GothamBold
    keyBtn.TextSize=12
    keyBtn.BorderSizePixel=0
    keyBtn.Parent=keyFrame
    
    local keyCorner=Instance.new("UICorner")
    keyCorner.CornerRadius=UDim.new(0,4)
    keyCorner.Parent=keyBtn
    
    local guiHint=Instance.new("TextLabel")
    guiHint.Size=UDim2.new(1,0,0,18)
    guiHint.Position=UDim2.new(0,0,1,-18)
    guiHint.BackgroundTransparency=1
    guiHint.Text="[Right Ctrl] hide/show"
    guiHint.TextColor3=Color3.new(0.5,0.5,0.5)
    guiHint.Font=Enum.Font.Gotham
    guiHint.TextSize=9
    guiHint.Parent=main
    
    local binding=false
    
    local function updateDisplay()
        local currentSpeed=cfg.speed*speedMult
        speedVal.Text=math.floor(currentSpeed)
    end
    
    keyBtn.MouseButton1Click:Connect(function()
        binding=true
        keyBtn.Text="..."
        local conn
        conn=UserInputService.InputBegan:Connect(function(input,proc)
            if proc or not binding then return end
            if input.KeyCode~=Enum.KeyCode.Unknown then
                cfg.toggleKey=input.KeyCode
                keyBtn.Text=input.KeyCode.Name
                binding=false
                conn:Disconnect()
            end
        end)
        task.wait(3)
        if binding then
            binding=false
            keyBtn.Text=cfg.toggleKey.Name
        end
    end)
    
    local dragging=false
    sliderHitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
        end
    end)
    sliderHitbox.InputEnded:Connect(function()
        dragging=false
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local pos=math.clamp((inp.Position.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X,0,1)
            cfg.speed=cfg.minSpeed+(cfg.maxSpeed-cfg.minSpeed)*pos
            fill.Size=UDim2.new(pos,0,1,0)
            updateDisplay()
        end
    end)
    
    updateDisplay()
    return {update=updateDisplay}
end

local guiControls=createGUI()

local function toggleGUI()
    guiVisible=not guiVisible
    gui.Enabled=guiVisible
end

local function freezeChar()
    if not hum then return end
    hum.PlatformStand=true
    hum.AutoRotate=false
    hum.Sit=false
    local states={
        Enum.HumanoidStateType.Jumping,
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.GettingUp,
        Enum.HumanoidStateType.Stunned,
        Enum.HumanoidStateType.Climbing,
        Enum.HumanoidStateType.Landed,
        Enum.HumanoidStateType.Physics,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.Swimming,
        Enum.HumanoidStateType.Running,
        Enum.HumanoidStateType.Sprinting
    }
    for _,s in ipairs(states) do hum:SetStateEnabled(s,false) end
    for _,a in ipairs(hum:GetPlayingAnimationTracks()) do a:Stop() end
    if root then
        root.Velocity=Vector3.zero
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end
end

local function unfreezeChar()
    if not hum then return end
    hum.PlatformStand=false
    hum.AutoRotate=true
    local states={
        Enum.HumanoidStateType.Jumping,
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.GettingUp,
        Enum.HumanoidStateType.Stunned,
        Enum.HumanoidStateType.Climbing,
        Enum.HumanoidStateType.Landed,
        Enum.HumanoidStateType.Physics,
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.Swimming,
        Enum.HumanoidStateType.Running,
        Enum.HumanoidStateType.Sprinting
    }
    for _,s in ipairs(states) do hum:SetStateEnabled(s,true) end
end

local function enableNoclip()
    if not cfg.noclip or not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA"BasePart" then
            p.CanCollide=false
        end
    end
    char.DescendantAdded:Connect(function(d)
        if d:IsA"BasePart" then d.CanCollide=false end
    end)
end

local function disableNoclip()
    if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA"BasePart" then
            p.CanCollide=true
        end
    end
end

function startFlight()
    if flying or not char or not hum or not root then return end
    flying=true
    freezeChar()
    if cfg.noclip then enableNoclip() end
    UserInputService.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
    UserInputService.MouseIconEnabled=false
    guiControls.update()
end

function stopFlight()
    if not flying then return end
    flying=false
    unfreezeChar()
    if cfg.noclip then disableNoclip() end
    if root then
        root.Velocity=Vector3.zero
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end
    UserInputService.MouseBehavior=Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled=true
    guiControls.update()
end

local function updateMovement(dt)
    if not flying or not camera or not root then return end
    dt=math.min(dt or 0.016,0.033)
    
    local cf=camera.CFrame
    local move=Vector3.zero
    
    if keys.W then move=move+cf.LookVector end
    if keys.S then move=move-cf.LookVector end
    if keys.D then move=move+cf.RightVector end
    if keys.A then move=move-cf.RightVector end
    if keys.Space then move=move+cf.UpVector end
    if keys.LeftShift then move=move-cf.UpVector end
    
    local mag=move.Magnitude
    
    if mag>0.01 then
        move=move/mag
        local spd=cfg.speed*speedMult
        root.AssemblyLinearVelocity=move*spd
    else
        root.AssemblyLinearVelocity=Vector3.new(0,0,0)
        root.Velocity=Vector3.new(0,0,0)
        root.AssemblyAngularVelocity=Vector3.new(0,0,0)
    end
    
    local targetCF=CFrame.new(root.Position, root.Position + cf.LookVector)
    local newCF=root.CFrame:Lerp(targetCF, math.min(1, dt*cfg.rotSpeed))
    root.CFrame=CFrame.new(root.Position, newCF.Position + newCF.LookVector)
    
    if math.abs(root.AssemblyLinearVelocity.Y)>0.05 and mag<0.01 then
        root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
    end
end

local function onInput(input,proc)
    if proc then return end
    local k=input.KeyCode
    if k==Enum.KeyCode.W then keys.W=true
    elseif k==Enum.KeyCode.A then keys.A=true
    elseif k==Enum.KeyCode.S then keys.S=true
    elseif k==Enum.KeyCode.D then keys.D=true
    elseif k==Enum.KeyCode.Space then keys.Space=true
    elseif k==Enum.KeyCode.LeftShift then keys.LeftShift=true
    elseif k==cfg.toggleKey then
        if flying then stopFlight() else startFlight() end
    elseif k==cfg.guiToggleKey then
        toggleGUI()
    end
end

local function onInputEnd(input,proc)
    if proc then return end
    local k=input.KeyCode
    if k==Enum.KeyCode.W then keys.W=false
    elseif k==Enum.KeyCode.A then keys.A=false
    elseif k==Enum.KeyCode.S then keys.S=false
    elseif k==Enum.KeyCode.D then keys.D=false
    elseif k==Enum.KeyCode.Space then keys.Space=false
    elseif k==Enum.KeyCode.LeftShift then keys.LeftShift=false
    end
end

local function onWheel(input,proc)
    if proc or not flying then return end
    if input.UserInputType==Enum.UserInputType.MouseWheel then
        local d=input.Position.Z
        if d>0 then speedMult=math.min(speedMult*1.15,8)
        elseif d<0 then speedMult=math.max(speedMult/1.15,0.2)
        end
        guiControls.update()
    end
end

local function setupChar(newChar)
    if flying then stopFlight() end
    char=newChar
    hum=char:WaitForChild"Humanoid"
    root=char:WaitForChild"HumanoidRootPart"
    if flying then task.wait(0.5) startFlight() end
end

if player.Character then setupChar(player.Character) end
player.CharacterAdded:Connect(setupChar)
player.CharacterRemoving:Connect(function()
    if flying then stopFlight() end
    char,hum,root=nil,nil,nil
end)

UserInputService.InputBegan:Connect(onInput)
UserInputService.InputEnded:Connect(onInputEnd)
UserInputService.InputChanged:Connect(onWheel)

local lt=tick()
RunService.Heartbeat:Connect(function()
    local now=tick()
    updateMovement(now-lt)
    lt=now
end)

print("[FLY] Loaded | "..cfg.toggleKey.Name.." to toggle flight | Right Ctrl to toggle GUI")