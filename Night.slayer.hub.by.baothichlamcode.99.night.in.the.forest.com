-- Check Executor Environment
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local timeFile = "NightslayerTime.txt"
local testUsedFile = "NightslayerTestUsed.txt"
local correctKey = "Baothichlamcode"
local SESSION_DURATION = 3600 -- 1 hour in seconds (3600s)

-- Forward declaration of UI functions
local createKeyGui, createMainHub

-- Check if active session is valid
local function getValidExpiry()
    if readfile and isfile and isfile(timeFile) then
        local content = readfile(timeFile)
        local expiry = tonumber(content)
        if expiry and os.time() < expiry then
            return expiry
        end
    end
    return nil
end

-- ==================== 1. MAIN HUB INTERFACE ====================
createMainHub = function(expiryTime)
    -- Remove existing UIs
    if CoreGui:FindFirstChild("NightslayerHubGui") then
        CoreGui.NightslayerHubGui:Destroy()
    end
    if CoreGui:FindFirstChild("NightslayerKeyGui") then
        CoreGui.NightslayerKeyGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NightslayerHubGui"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Floating Toggle Button (Draggable on Mobile/PC)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Parent = ScreenGui
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ToggleBtn.Position = UDim2.new(0, 20, 0.5, -25)
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.Text = "Hub"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 14
    ToggleBtn.Active = true
    ToggleBtn.Draggable = true

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBtn

    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = Color3.fromRGB(100, 100, 150)
    ToggleStroke.Thickness = 2
    ToggleStroke.Parent = ToggleBtn

    -- Main Hub Frame
    local HubFrame = Instance.new("Frame")
    HubFrame.Name = "HubFrame"
    HubFrame.Parent = ScreenGui
    HubFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    HubFrame.Position = UDim2.new(0.5, -175, 0.5, -110)
    HubFrame.Size = UDim2.new(0, 350, 0, 220)
    HubFrame.Active = true
    HubFrame.Draggable = true
    HubFrame.Visible = true

    local HubCorner = Instance.new("UICorner")
    HubCorner.CornerRadius = UDim.new(0, 12)
    HubCorner.Parent = HubFrame

    local HubStroke = Instance.new("UIStroke")
    HubStroke.Color = Color3.fromRGB(80, 80, 120)
    HubStroke.Thickness = 2
    HubStroke.Parent = HubFrame

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Parent = HubFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 0, 0, 15)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "NIGHTSLAYER HUB - MAIN MENU"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16

    -- Test Script Button
    local TestScriptBtn = Instance.new("TextButton")
    TestScriptBtn.Parent = HubFrame
    TestScriptBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 220)
    TestScriptBtn.Position = UDim2.new(0.1, 0, 0, 65)
    TestScriptBtn.Size = UDim2.new(0.8, 0, 0, 45)
    TestScriptBtn.Font = Enum.Font.GothamBold
    TestScriptBtn.Text = "Test Script"
    TestScriptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TestScriptBtn.TextSize = 15

    local TestCorner = Instance.new("UICorner")
    TestCorner.CornerRadius = UDim.new(0, 8)
    TestCorner.Parent = TestScriptBtn

    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Parent = HubFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 0, 130)
    StatusLabel.Size = UDim2.new(1, 0, 0, 30)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = "Status: Key Active (1 hour session)"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    StatusLabel.TextSize = 13

    -- Hide/Show menu when clicking floating toggle button
    ToggleBtn.MouseButton1Click:Connect(function()
        HubFrame.Visible = not HubFrame.Visible
    end)

    -- Check if Test Script was used within the last hour
    local function hasUsedTest()
        if readfile and isfile and isfile(testUsedFile) then
            local content = readfile(testUsedFile)
            local t = tonumber(content)
            if t and os.time() < t then
                return true
            end
        end
        return false
    end

    if hasUsedTest() then
        TestScriptBtn.Text = "Test Script (On Cooldown)"
        TestScriptBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end

    -- Test Script Button Click Logic (Usable once per hour)
    TestScriptBtn.MouseButton1Click:Connect(function()
        if hasUsedTest() then
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            StatusLabel.Text = "Test script can only be used once per hour!"
            return
        end

        -- Save usage timestamp (1 hour cooldown)
        if writefile then
            pcall(function()
                writefile(testUsedFile, tostring(os.time() + SESSION_DURATION))
            end)
        end

        TestScriptBtn.Text = "Test Script (On Cooldown)"
        TestScriptBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        StatusLabel.Text = "Running test script..."

        -- Execute your script
        local success, err = pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/baothichlamcode/NightslayerhubBaothichlamcode/refs/heads/main/99nightintheforest'))()
        end)

        if not success then
            warn("Error loading script: " .. tostring(err))
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            StatusLabel.Text = "Error executing script!"
        end
    end)

    -- Expiration timer (After 1 hour, resets back to Get Key interface)
    task.spawn(function()
        while task.wait(1) do
            if os.time() >= expiryTime then
                if delfile then
                    pcall(function() delfile(timeFile) end)
                    pcall(function() delfile(testUsedFile) end)
                end
                ScreenGui:Destroy()
                createKeyGui()
                break
            end
        end
    end)
end

-- ==================== 2. KEY SYSTEM INTERFACE ====================
createKeyGui = function()
    if CoreGui:FindFirstChild("NightslayerKeyGui") then
        CoreGui.NightslayerKeyGui:Destroy()
    end
    if CoreGui:FindFirstChild("NightslayerHubGui") then
        CoreGui.NightslayerHubGui:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NightslayerKeyGui"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -110)
    MainFrame.Size = UDim2.new(0, 350, 0, 220)
    MainFrame.Active = true
    MainFrame.Draggable = true

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(80, 80, 120)
    UIStroke.Thickness = 2
    UIStroke.Parent = MainFrame

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 0, 0, 15)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "NIGHTSLAYER HUB - KEY SYSTEM"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16

    -- Key TextBox
    local KeyBox = Instance.new("TextBox")
    KeyBox.Parent = MainFrame
    KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    KeyBox.Position = UDim2.new(0.1, 0, 0, 60)
    KeyBox.Size = UDim2.new(0.8, 0, 0, 40)
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.PlaceholderText = "Enter key here..."
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.TextSize = 14

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 8)
    BoxCorner.Parent = KeyBox

    -- Get Key Button
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Parent = MainFrame
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    GetKeyBtn.Position = UDim2.new(0.1, 0, 0, 115)
    GetKeyBtn.Size = UDim2.new(0.38, 0, 0, 35)
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.Text = "Get Key"
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.TextSize = 14

    local GetCorner = Instance.new("UICorner")
    GetCorner.CornerRadius = UDim.new(0, 8)
    GetCorner.Parent = GetKeyBtn

    -- Submit Button
    local SubmitBtn = Instance.new("TextButton")
    SubmitBtn.Parent = MainFrame
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 90)
    SubmitBtn.Position = UDim2.new(0.52, 0, 0, 115)
    SubmitBtn.Size = UDim2.new(0.38, 0, 0, 35)
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.Text = "Check Key"
    SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitBtn.TextSize = 14

    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 8)
    SubmitCorner.Parent = SubmitBtn

    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Position = UDim2.new(0, 0, 0, 165)
    StatusLabel.Size = UDim2.new(1, 0, 0, 25)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusLabel.TextSize = 13

    local isWaiting = false

    GetKeyBtn.MouseButton1Click:Connect(function()
        if isWaiting then return end
        isWaiting = true
        
        if setclipboard then
            setclipboard("https://ouo.io/s2U7FGV")
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            StatusLabel.Text = "Link copied to clipboard!"
        else
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            StatusLabel.Text = "Your executor does not support auto-copy."
        end
        
        GetKeyBtn.Text = "Paste to google"
        
        task.delay(10, function()
            GetKeyBtn.Text = "Get Key"
            StatusLabel.Text = ""
            isWaiting = false
        end)
    end)

    SubmitBtn.MouseButton1Click:Connect(function()
        if KeyBox.Text == correctKey then
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            StatusLabel.Text = "Correct key! Loading hub..."
            
            local newExpiry = os.time() + SESSION_DURATION
            if writefile then
                pcall(function()
                    writefile(timeFile, tostring(newExpiry))
                end)
            end
            
            task.wait(1)
            ScreenGui:Destroy()
            createMainHub(newExpiry)
        else
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            StatusLabel.Text = "Incorrect key! Please try again."
        end
    end)
end

-- ==================== LAUNCH CHECK ====================
local currentExpiry = getValidExpiry()
if currentExpiry then
    createMainHub(currentExpiry)
else
    createKeyGui()
end
