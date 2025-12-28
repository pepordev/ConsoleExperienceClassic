--[[
    ConsoleExperienceClassic - Configuration Module
    
    Provides a configuration UI with sidebar navigation
]]

-- Create the config module namespace
ConsoleExperience.config = ConsoleExperience.config or {}
local Config = ConsoleExperience.config

-- ============================================================================
-- Default Configuration Values
-- ============================================================================

Config.DEFAULTS = {
    debugEnabled = false,
    -- Interface settings
    crosshairEnabled = false,
    crosshairX = 0,
    crosshairY = 0,
    crosshairSize = 24,
    -- Action Bar settings
    barButtonSize = 60,
    barXOffset = 0,
    barYOffset = 70,
    barPadding = 65,
    barStarPadding = 600,  -- Padding between left and right star centers
    barScale = 1.0,
    -- Chat settings
    chatWidth = 400,
    chatHeight = 150,
    keyboardEnabled = true,  -- If true, show virtual keyboard when chat edit box is visible
    -- Keybinding settings
    useAForJump = true,  -- If true, A button (key 1) is bound to JUMP instead of CE_ACTION_1
}

-- ============================================================================
-- Configuration Get/Set Functions
-- ============================================================================

function Config:InitializeDB()
    -- Ensure ConsoleExperienceDB exists
    if not ConsoleExperienceDB then
        ConsoleExperienceDB = {}
    end
    
    -- Initialize config section if it doesn't exist
    if not ConsoleExperienceDB.config then
        ConsoleExperienceDB.config = {}
    end
    
    -- Set defaults for any missing values
    for key, defaultValue in pairs(self.DEFAULTS) do
        if ConsoleExperienceDB.config[key] == nil then
            ConsoleExperienceDB.config[key] = defaultValue
        end
    end
    
    -- Apply debug setting to global variable
    ConsoleExperience_DEBUG_KEYS = ConsoleExperienceDB.config.debugEnabled
    
    -- Apply crosshair setting
    self:UpdateCrosshair()
    
    -- Apply action bar layout
    self:UpdateActionBarLayout()
    
    -- Apply chat layout
    if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
        ConsoleExperience.chat:UpdateChatLayout()
    end
    
end

function Config:Get(key)
    if ConsoleExperienceDB and ConsoleExperienceDB.config then
        if ConsoleExperienceDB.config[key] ~= nil then
            return ConsoleExperienceDB.config[key]
        end
    end
    return self.DEFAULTS[key]
end

function Config:Set(key, value)
    if not ConsoleExperienceDB then
        ConsoleExperienceDB = {}
    end
    if not ConsoleExperienceDB.config then
        ConsoleExperienceDB.config = {}
    end
    ConsoleExperienceDB.config[key] = value
    
    -- Apply certain settings immediately
    if key == "debugEnabled" then
        ConsoleExperience_DEBUG_KEYS = value
    end
end

-- ============================================================================
-- Constants
-- ============================================================================

Config.FRAME_WIDTH = 520
Config.FRAME_HEIGHT = 420
Config.SIDEBAR_WIDTH = 120
Config.BUTTON_HEIGHT = 25
Config.PADDING = 10

-- Section definitions
Config.SECTIONS = {
    { id = "general", name = "General" },
    { id = "interface", name = "Interface" },
    { id = "keybindings", name = "Keybindings" },
    { id = "bars", name = "Action Bars" },
    { id = "chat", name = "Chat" },
}

-- ============================================================================
-- Main Config Frame
-- ============================================================================

function Config:CreateMainFrame()
    if self.frame then return self.frame end
    
    -- Main frame
    local frame = CreateFrame("Frame", "ConsoleExperienceConfigFrame", UIParent)
    frame:SetWidth(self.FRAME_WIDTH)
    frame:SetHeight(self.FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Title bar for dragging (leave space for close button)
    local titleRegion = CreateFrame("Frame", nil, frame)
    titleRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
    titleRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -35, -5)  -- Leave room for close button
    titleRegion:SetHeight(25)
    titleRegion:EnableMouse(true)
    titleRegion:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    titleRegion:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Console Experience")
    
    -- Close button
    local closeButton = CreateFrame("Button", "ConsoleExperienceConfigCloseButton", frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    closeButton:SetScript("OnClick", function()
        ConsoleExperience.config.frame:Hide()
    end)
    closeButton:Show()
    
    -- Sidebar frame
    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", self.PADDING + 5, -40)
    sidebar:SetWidth(self.SIDEBAR_WIDTH)
    sidebar:SetHeight(self.FRAME_HEIGHT - 60)
    sidebar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    sidebar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    frame.sidebar = sidebar
    
    -- Content frame (outer container with backdrop)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", self.PADDING, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -self.PADDING - 5, self.PADDING + 5)
    content:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    content:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    frame.content = content
    
    -- Create scroll frame using native ScrollFrame type (like pfUI)
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, 5)  -- Leave room for buttons
    frame.scrollFrame = scrollFrame
    
    -- Create scroll child container
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(900)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild
    
    -- Create scroll up button (like quest frames)
    local scrollUpButton = CreateFrame("Button", nil, scrollFrame)
    scrollUpButton:SetWidth(24)
    scrollUpButton:SetHeight(24)
    scrollUpButton:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
    scrollUpButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    scrollUpButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    scrollUpButton:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
    scrollUpButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
    scrollUpButton:SetScript("OnClick", function()
        local current = scrollFrame:GetVerticalScroll()
        local new = current - 30
        if new < 0 then new = 0 end
        scrollFrame:SetVerticalScroll(new)
        scrollFrame:UpdateScrollState()
    end)
    frame.scrollUpButton = scrollUpButton
    
    -- Create scroll down button (like quest frames)
    local scrollDownButton = CreateFrame("Button", nil, scrollFrame)
    scrollDownButton:SetWidth(24)
    scrollDownButton:SetHeight(24)
    scrollDownButton:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
    scrollDownButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    scrollDownButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    scrollDownButton:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
    scrollDownButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
    scrollDownButton:SetScript("OnClick", function()
        local current = scrollFrame:GetVerticalScroll()
        local max = scrollFrame:GetVerticalScrollRange()
        local new = current + 30
        if new > max then new = max end
        scrollFrame:SetVerticalScroll(new)
        scrollFrame:UpdateScrollState()
    end)
    frame.scrollDownButton = scrollDownButton
    
    -- Update scroll state function
    scrollFrame.UpdateScrollState = function()
        local range = scrollFrame:GetVerticalScrollRange()
        local current = scrollFrame:GetVerticalScroll()
        
        -- Enable/disable buttons based on scroll position
        if current <= 0 then
            scrollUpButton:Disable()
        else
            scrollUpButton:Enable()
        end
        
        if current >= range then
            scrollDownButton:Disable()
        else
            scrollDownButton:Enable()
        end
        
        -- Hide buttons if no scrolling needed
        if range <= 0 then
            scrollUpButton:Hide()
            scrollDownButton:Hide()
        else
            scrollUpButton:Show()
            scrollDownButton:Show()
        end
    end
    
    -- Scroll function (like pfUI)
    scrollFrame.Scroll = function(self, step)
        local step = step or 0
        local current = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        local new = current - step
        
        if new >= max then
            self:SetVerticalScroll(max)
        elseif new <= 0 then
            self:SetVerticalScroll(0)
        else
            self:SetVerticalScroll(new)
        end
        
        self:UpdateScrollState()
    end
    
    -- Mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        this:Scroll(arg1 * 10)
    end)
    
    -- Update scroll child on frame show
    frame:SetScript("OnShow", function()
        scrollChild:SetWidth(scrollFrame:GetWidth())
        scrollFrame:UpdateScrollState()
    end)
    
    -- Update content reference
    frame.content = scrollChild
    
    -- Store reference
    self.frame = frame
    
    -- Add to special frames so Escape closes it
    table.insert(UISpecialFrames, "ConsoleExperienceConfigFrame")
    
    -- Create sidebar buttons
    self:CreateSidebarButtons()
    
    -- Create content sections
    self:CreateContentSections()
    
    -- Show first section by default
    self:ShowSection("general")
    
    -- Hook frame for cursor navigation
    if ConsoleExperience.hooks and ConsoleExperience.hooks.HookDynamicFrame then
        ConsoleExperience.hooks:HookDynamicFrame(frame, "Console Experience Config")
    end
    
    return frame
end

-- ============================================================================
-- Sidebar Buttons
-- ============================================================================

function Config:CreateSidebarButtons()
    local sidebar = self.frame.sidebar
    self.sidebarButtons = {}
    
    for i, section in ipairs(self.SECTIONS) do
        local buttonName = "CEConfigSidebar" .. section.id
        local button = CreateFrame("Button", buttonName, sidebar)
        button:SetWidth(self.SIDEBAR_WIDTH - 10)
        button:SetHeight(self.BUTTON_HEIGHT)
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 5, -5 - (i-1) * (self.BUTTON_HEIGHT + 2))
        
        -- Button background
        button:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        
        -- Button text
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", button, "CENTER", 0, 0)
        text:SetText(section.name)
        button.text = text
        
        -- Store section id
        button.sectionId = section.id
        
        -- Click handler
        button:SetScript("OnClick", function()
            Config:ShowSection(this.sectionId)
        end)
        
        -- Hover effects
        button:SetScript("OnEnter", function()
            if Config.currentSection ~= this.sectionId then
                this:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
            end
        end)
        button:SetScript("OnLeave", function()
            if Config.currentSection ~= this.sectionId then
                this:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            end
        end)
        
        self.sidebarButtons[section.id] = button
    end
end

-- ============================================================================
-- Content Sections
-- ============================================================================

function Config:CreateContentSections()
    self.contentSections = {}
    
    -- Create General section
    self:CreateGeneralSection()
    
    -- Create Interface section
    self:CreateInterfaceSection()
    
    -- Create Keybindings section
    self:CreateKeybindingsSection()
    
    -- Create Bars section
    self:CreateBarsSection()
    
    -- Create Chat section
    self:CreateChatSection()
    
    -- Update scroll child height based on content
    self:UpdateScrollChildHeight()
end

function Config:UpdateScrollChildHeight()
    if not self.frame or not self.frame.scrollChild or not self.frame.scrollFrame then return end
    
    -- Calculate maximum height needed for all sections
    -- Action Bars section is the tallest with all the controls
    local maxHeight = 900  -- Enough height for all sections including Action Bars
    
    -- Ensure scroll child width matches scroll frame width to prevent overflow
    self.frame.scrollChild:SetWidth(self.frame.scrollFrame:GetWidth())
    
    -- Set scroll child height to accommodate all content
    self.frame.scrollChild:SetHeight(maxHeight)
    
    -- Update scroll state using ScrollFrame's UpdateScrollState method
    if self.frame.scrollFrame.UpdateScrollState then
        self.frame.scrollFrame:UpdateScrollState()
    end
end

function Config:CreateGeneralSection()
    local content = self.frame.content
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText("General Settings")
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure general addon settings.")
    
    -- Debug checkbox (saved to DB)
    local debugCheck = self:CreateCheckbox(section, "Enable Debug Output", 
        function() return Config:Get("debugEnabled") end,
        function(checked)
            Config:Set("debugEnabled", checked)
            if checked then
                CE_Debug("Debug output ENABLED (saved)")
            else
                CE_Debug("Debug output DISABLED (saved)")
            end
        end)
    debugCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    
    -- Version info
    local version = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    version:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", 15, 15)
    version:SetText("Version: 1.0")
    
    self.contentSections["general"] = section
end

function Config:CreateInterfaceSection()
    local content = self.frame.content
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText("Interface Settings")
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure interface elements.")
    
    -- Enable Crosshair checkbox
    local crosshairCheck = self:CreateCheckbox(section, "Enable Crosshair", 
        function() return Config:Get("crosshairEnabled") end,
        function(checked)
            Config:Set("crosshairEnabled", checked)
            Config:UpdateCrosshair()
            if checked then
                CE_Debug("Crosshair ENABLED")
            else
                CE_Debug("Crosshair DISABLED")
            end
        end)
    crosshairCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    
    -- Crosshair X Position
    local xLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xLabel:SetPoint("TOPLEFT", crosshairCheck, "BOTTOMLEFT", 0, -20)
    xLabel:SetText("Crosshair X Offset:")
    
    local xEditBox = self:CreateEditBox(section, 60, 
        function() return tostring(Config:Get("crosshairX")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("crosshairX", num)
            Config:UpdateCrosshair()
        end)
    xEditBox:SetPoint("LEFT", xLabel, "RIGHT", 10, 0)
    
    -- Crosshair Y Position
    local yLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yLabel:SetPoint("TOPLEFT", xLabel, "BOTTOMLEFT", 0, -15)
    yLabel:SetText("Crosshair Y Offset:")
    
    local yEditBox = self:CreateEditBox(section, 60, 
        function() return tostring(Config:Get("crosshairY")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("crosshairY", num)
            Config:UpdateCrosshair()
        end)
    yEditBox:SetPoint("LEFT", yLabel, "RIGHT", 10, 0)
    
    -- Crosshair Size
    local sizeLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", yLabel, "BOTTOMLEFT", 0, -15)
    sizeLabel:SetText("Crosshair Size:")
    
    local sizeEditBox = self:CreateEditBox(section, 60, 
        function() return tostring(Config:Get("crosshairSize")) end,
        function(value)
            local num = tonumber(value) or 24
            if num < 4 then num = 4 end
            if num > 100 then num = 100 end
            Config:Set("crosshairSize", num)
            Config:UpdateCrosshair()
        end)
    sizeEditBox:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)
    
    -- Help text
    local helpText = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -20)
    helpText:SetWidth(260)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("X/Y offset from screen center. Use negative values to move left/down. Size: 4-100 pixels.")
    
    self.contentSections["interface"] = section
end

function Config:CreateKeybindingsSection()
    local content = self.frame.content
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText("Keybinding Settings")
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(300)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure special keybindings for controller-style gameplay.")
    
    -- Use A for Jump checkbox
    local jumpCheck = self:CreateCheckbox(section, "Use A button for Jump", 
        function() return Config:Get("useAForJump") end,
        function(checked)
            Config:Set("useAForJump", checked)
            
            -- Determine the new binding for key 1
            local key = "1"
            local newBinding
            if checked then
                newBinding = "JUMP"
                CE_Debug("A button now bound to JUMP")
            else
                newBinding = "CE_ACTION_1"
                CE_Debug("A button now bound to Action Slot 1")
            end
            
            -- Check if cursor mode is active
            local cursorModeActive = false
            if ConsoleExperience.cursor and ConsoleExperience.cursor.keybindings then
                cursorModeActive = ConsoleExperience.cursor.keybindings.cursorModeActive
            end
            
            if cursorModeActive then
                -- Cursor mode is active - update the saved original binding
                local cursorKeys = ConsoleExperience.cursor.keybindings
                if not cursorKeys.originalBindings then
                    cursorKeys.originalBindings = {}
                end
                cursorKeys.originalBindings[key] = newBinding
                CE_Debug("Updated cursor original binding for key " .. key .. " to " .. newBinding)
            else
                -- Cursor mode not active, set binding directly
                SetBinding(key, newBinding)
                SaveBindings(1)
                CE_Debug("Set binding directly: key " .. key .. " to " .. newBinding)
            end
            
            -- Update action bar display
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
        end)
    jumpCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    
    -- Help text
    local helpText = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", jumpCheck, "BOTTOMLEFT", 0, -10)
    helpText:SetWidth(300)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("When enabled, pressing the A button (key 1) will jump. When disabled, it will use whatever action is in slot 1 of the action bar.")
    
    -- Separator
    local separator = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    separator:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -25)
    separator:SetText("Reset Bindings")
    
    -- Reset Default Bindings button
    local resetBindingsButton = CreateFrame("Button", "CEConfigResetBindings", section, "UIPanelButtonTemplate")
    resetBindingsButton:SetWidth(160)
    resetBindingsButton:SetHeight(24)
    resetBindingsButton:SetPoint("TOPLEFT", separator, "BOTTOMLEFT", 0, -10)
    resetBindingsButton:SetText("Reset Default Bindings")
    resetBindingsButton:SetScript("OnClick", function()
        -- Reset keybindings
        ConsoleExperienceKeybindings:ResetAllBindings()
        
        -- Reset macros and place them on action bar
        local macrosCreated, macrosPlaced = ConsoleExperience.macros:ResetMacrosToDefaults()
        
        -- Update action bar display
        if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
            ConsoleExperience.actionbars:UpdateAllButtons()
        end
        
        CE_Debug("Default bindings and macros have been reset!")
        CE_Debug("Macros created: " .. macrosCreated .. ", placed on action bar: " .. macrosPlaced)
    end)
    
    -- Reset help text
    local resetHelp = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetHelp:SetPoint("TOPLEFT", resetBindingsButton, "BOTTOMLEFT", 0, -5)
    resetHelp:SetWidth(300)
    resetHelp:SetJustifyH("LEFT")
    resetHelp:SetText("Resets all keybindings to default (1-0 keys) and places default macros (Target) on the action bar.")
    
    -- Separator for Placement Frame
    local separator2 = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    separator2:SetPoint("TOPLEFT", resetHelp, "BOTTOMLEFT", 0, -25)
    separator2:SetText("Spell Placement")
    
    -- Show Placement Frame button
    local showPlacementButton = CreateFrame("Button", "CEConfigShowPlacement", section, "UIPanelButtonTemplate")
    showPlacementButton:SetWidth(160)
    showPlacementButton:SetHeight(24)
    showPlacementButton:SetPoint("TOPLEFT", separator2, "BOTTOMLEFT", 0, -10)
    showPlacementButton:SetText("Show Placement Frame")
    showPlacementButton:SetScript("OnClick", function()
        if ConsoleExperience.placement then
            -- Show placement frame and close config frame
            ConsoleExperience.placement:Show()
            Config:Hide()
        else
            CE_Debug("Placement module not loaded!")
        end
    end)
    
    -- Placement help text
    local placementHelp = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placementHelp:SetPoint("TOPLEFT", showPlacementButton, "BOTTOMLEFT", 0, -5)
    placementHelp:SetWidth(300)
    placementHelp:SetJustifyH("LEFT")
    placementHelp:SetText("Opens the spell placement frame where you can drag and drop spells, macros, and items onto action bar slots.")
    
    self.contentSections["keybindings"] = section
end

function Config:CreateBarsSection()
    local content = self.frame.content
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText("Action Bar Settings")
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure the gamepad-style action bar layout.")
    
    -- Button Size
    local sizeLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    sizeLabel:SetText("Button Size:")
    
    local sizeEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barButtonSize")) end,
        function(value)
            local num = tonumber(value) or 40
            if num < 20 then num = 20 end
            if num > 80 then num = 80 end
            Config:Set("barButtonSize", num)
            Config:UpdateActionBarLayout()
        end)
    sizeEditBox:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)
    
    -- Padding
    local paddingLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    paddingLabel:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -15)
    paddingLabel:SetText("Button Padding:")
    
    local paddingEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barPadding")) end,
        function(value)
            local num = tonumber(value) or 40
            if num < 0 then num = 0 end
            if num > 100 then num = 100 end
            Config:Set("barPadding", num)
            Config:UpdateActionBarLayout()
        end)
    paddingEditBox:SetPoint("LEFT", paddingLabel, "RIGHT", 10, 0)
    
    -- X Offset
    local xLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xLabel:SetPoint("TOPLEFT", paddingLabel, "BOTTOMLEFT", 0, -15)
    xLabel:SetText("X Offset:")
    
    local xEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barXOffset")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("barXOffset", num)
            Config:UpdateActionBarLayout()
        end)
    xEditBox:SetPoint("LEFT", xLabel, "RIGHT", 10, 0)
    
    -- Y Offset
    local yLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yLabel:SetPoint("TOPLEFT", xLabel, "BOTTOMLEFT", 0, -15)
    yLabel:SetText("Y Offset:")
    
    local yEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barYOffset")) end,
        function(value)
            local num = tonumber(value) or 70
            Config:Set("barYOffset", num)
            Config:UpdateActionBarLayout()
        end)
    yEditBox:SetPoint("LEFT", yLabel, "RIGHT", 10, 0)
    
    -- Star Padding (between left and right sides)
    local starPaddingLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    starPaddingLabel:SetPoint("TOPLEFT", yLabel, "BOTTOMLEFT", 0, -15)
    starPaddingLabel:SetText("Star Padding:")
    
    local starPaddingEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barStarPadding")) end,
        function(value)
            local num = tonumber(value) or 200
            if num < 50 then num = 50 end
            if num > 1000 then num = 1000 end
            Config:Set("barStarPadding", num)
            Config:UpdateActionBarLayout()
        end)
    starPaddingEditBox:SetPoint("LEFT", starPaddingLabel, "RIGHT", 10, 0)
    
    -- Scale
    local scaleLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", starPaddingLabel, "BOTTOMLEFT", 0, -15)
    scaleLabel:SetText("Scale:")
    
    local scaleEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barScale")) end,
        function(value)
            local num = tonumber(value) or 1.0
            if num < 0.5 then num = 0.5 end
            if num > 2.0 then num = 2.0 end
            Config:Set("barScale", num)
            Config:UpdateActionBarLayout()
        end)
    scaleEditBox:SetPoint("LEFT", scaleLabel, "RIGHT", 10, 0)
    
    -- Help text
    local helpText = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -25)
    helpText:SetWidth(260)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("Size: 20-80, Padding: 0-100, Star Padding: 50-1000, Scale: 0.5-2.0. X/Y offset from bottom center.")
    
    -- Reset to defaults button
    local resetButton = CreateFrame("Button", "CEConfigResetLayout", section, "UIPanelButtonTemplate")
    resetButton:SetWidth(120)
    resetButton:SetHeight(22)
    resetButton:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -15)
    resetButton:SetText("Reset Layout")
    resetButton:SetScript("OnClick", function()
        Config:Set("barButtonSize", Config.DEFAULTS.barButtonSize)
        Config:Set("barPadding", Config.DEFAULTS.barPadding)
        Config:Set("barStarPadding", Config.DEFAULTS.barStarPadding)
        Config:Set("barXOffset", Config.DEFAULTS.barXOffset)
        Config:Set("barYOffset", Config.DEFAULTS.barYOffset)
        Config:Set("barScale", Config.DEFAULTS.barScale)
        Config:UpdateActionBarLayout()
        -- Refresh edit boxes
        sizeEditBox:SetText(tostring(Config.DEFAULTS.barButtonSize))
        paddingEditBox:SetText(tostring(Config.DEFAULTS.barPadding))
        starPaddingEditBox:SetText(tostring(Config.DEFAULTS.barStarPadding))
        xEditBox:SetText(tostring(Config.DEFAULTS.barXOffset))
        yEditBox:SetText(tostring(Config.DEFAULTS.barYOffset))
        scaleEditBox:SetText(tostring(Config.DEFAULTS.barScale))
        CE_Debug("Action bar layout reset to defaults")
    end)
    
    self.contentSections["bars"] = section
end

function Config:CreateChatSection()
    local content = self.frame.content
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText("Chat Settings")
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText("Configure the chat frame position and size. The chat frame is centered at the bottom of the screen.")
    
    -- Chat Width
    local chatWidthLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatWidthLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    chatWidthLabel:SetText("Chat Width:")
    
    local chatWidthEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("chatWidth")) end,
        function(value)
            local num = tonumber(value) or 400
            if num < 100 then num = 100 end
            if num > 2000 then num = 2000 end
            Config:Set("chatWidth", num)
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end)
    chatWidthEditBox:SetPoint("LEFT", chatWidthLabel, "RIGHT", 10, 0)
    
    -- Chat Height
    local chatHeightLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatHeightLabel:SetPoint("TOPLEFT", chatWidthLabel, "BOTTOMLEFT", 0, -15)
    chatHeightLabel:SetText("Chat Height:")
    
    local chatHeightEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("chatHeight")) end,
        function(value)
            local num = tonumber(value) or 200
            if num < 50 then num = 50 end
            if num > 1000 then num = 1000 end
            Config:Set("chatHeight", num)
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end)
    chatHeightEditBox:SetPoint("LEFT", chatHeightLabel, "RIGHT", 10, 0)
    
    -- Keyboard Enabled checkbox
    local keyboardCheck = CreateFrame("CheckButton", "CEConfigKeyboardEnabled", section, "UICheckButtonTemplate")
    keyboardCheck:SetPoint("TOPLEFT", chatHeightLabel, "BOTTOMLEFT", 0, -15)
    keyboardCheck:SetChecked(Config:Get("keyboardEnabled"))
    keyboardCheck:SetScript("OnClick", function()
        local checked = keyboardCheck:GetChecked() == 1
        Config:Set("keyboardEnabled", checked)
        CE_Debug("Virtual keyboard " .. (checked and "enabled" or "disabled"))
        -- If keyboard is disabled and currently visible, hide it immediately
        if not checked and ConsoleExperience.keyboard and ConsoleExperience.keyboard:IsVisible() then
            ConsoleExperience.keyboard:Hide()
        end
    end)
    
    -- Refresh checkbox state when section is shown
    section:SetScript("OnShow", function()
        keyboardCheck:SetChecked(Config:Get("keyboardEnabled"))
    end)
    
    local keyboardLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyboardLabel:SetPoint("LEFT", keyboardCheck, "RIGHT", 5, 0)
    keyboardLabel:SetText("Enable Virtual Keyboard")
    
    -- Keyboard help text
    local keyboardHelp = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    keyboardHelp:SetPoint("TOPLEFT", keyboardCheck, "BOTTOMLEFT", 0, -5)
    keyboardHelp:SetWidth(260)
    keyboardHelp:SetJustifyH("LEFT")
    keyboardHelp:SetText("When enabled, a virtual keyboard appears when typing in chat. Disable to use an external keyboard.")
    
    -- Help text
    local helpText = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", keyboardHelp, "BOTTOMLEFT", 0, -10)
    helpText:SetWidth(260)
    helpText:SetJustifyH("LEFT")
    helpText:SetText("Width: 100-2000, Height: 50-1000. The chat frame is centered at the bottom of the screen.")
    
    -- Reset to defaults button
    local resetButton = CreateFrame("Button", "CEConfigResetChat", section, "UIPanelButtonTemplate")
    resetButton:SetWidth(120)
    resetButton:SetHeight(22)
    resetButton:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -15)
    resetButton:SetText("Reset Chat")
    resetButton:SetScript("OnClick", function()
        Config:Set("chatWidth", Config.DEFAULTS.chatWidth)
        Config:Set("chatHeight", Config.DEFAULTS.chatHeight)
        Config:Set("keyboardEnabled", Config.DEFAULTS.keyboardEnabled)
        if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
            ConsoleExperience.chat:UpdateChatLayout()
        end
        -- Refresh edit boxes and checkbox
        chatWidthEditBox:SetText(tostring(Config.DEFAULTS.chatWidth))
        chatHeightEditBox:SetText(tostring(Config.DEFAULTS.chatHeight))
        keyboardCheck:SetChecked(Config.DEFAULTS.keyboardEnabled)
        CE_Debug("Chat settings reset to defaults")
    end)
    
    self.contentSections["chat"] = section
end

-- ============================================================================
-- UI Helpers
-- ============================================================================

-- Counter for generating unique names
Config.elementCounter = 0

function Config:GetNextElementName(prefix)
    self.elementCounter = self.elementCounter + 1
    return "CEConfig" .. prefix .. self.elementCounter
end

function Config:CreateCheckbox(parent, label, getFunc, setFunc)
    local name = self:GetNextElementName("Check")
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    
    local text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", check, "RIGHT", 5, 0)
    text:SetText(label)
    
    -- Store label for tooltip/debug
    check.label = label
    
    -- Set initial state
    check:SetChecked(getFunc())
    
    -- Click handler
    check:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        setFunc(checked)
    end)
    
    return check
end

function Config:CreateEditBox(parent, width, getFunc, setFunc)
    local name = self:GetNextElementName("Edit")
    local editBox = CreateFrame("EditBox", name, parent)
    editBox:SetWidth(width)
    editBox:SetHeight(20)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetJustifyH("CENTER")
    
    -- Background
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Set initial value
    editBox:SetText(getFunc())
    
    -- Focus handlers
    editBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        this:SetText(getFunc())
    end)
    
    editBox:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        setFunc(this:GetText())
    end)
    
    editBox:SetScript("OnEditFocusLost", function()
        setFunc(this:GetText())
    end)
    
    return editBox
end

-- ============================================================================
-- Section Management
-- ============================================================================

function Config:ShowSection(sectionId)
    -- Hide all sections
    for id, section in pairs(self.contentSections) do
        section:Hide()
    end
    
    -- Reset all sidebar button colors
    for id, button in pairs(self.sidebarButtons) do
        button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    end
    
    -- Show selected section
    if self.contentSections[sectionId] then
        self.contentSections[sectionId]:Show()
        -- Update scroll child height when showing section
        self:UpdateScrollChildHeight()
    end
    
    -- Highlight selected sidebar button
    if self.sidebarButtons[sectionId] then
        self.sidebarButtons[sectionId]:SetBackdropColor(0.4, 0.4, 0.6, 0.8)
    end
    
    self.currentSection = sectionId
end

-- ============================================================================
-- Toggle/Show/Hide
-- ============================================================================

function Config:Toggle()
    if not self.frame then
        self:CreateMainFrame()
    end
    
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function Config:Show()
    if not self.frame then
        self:CreateMainFrame()
    end
    self.frame:Show()
end

function Config:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- ============================================================================
-- Game Menu Button
-- ============================================================================

function Config:CreateGameMenuButton()
    -- Don't create if already exists
    if GameMenuButtonConsoleExperience then return end
    
    -- Create button using GameMenuButtonTemplate
    local button = CreateFrame("Button", "GameMenuButtonConsoleExperience", GameMenuFrame, "GameMenuButtonTemplate")
    button:SetText("Console Experience")
    
    -- Position after UIOptions (Interface Options) button
    if GameMenuButtonUIOptions then
        button:SetPoint("TOP", GameMenuButtonUIOptions, "BOTTOM", 0, -1)
    elseif GameMenuButtonOptions then
        button:SetPoint("TOP", GameMenuButtonOptions, "BOTTOM", 0, -1)
    else
        button:SetPoint("TOP", GameMenuFrame, "TOP", 0, -30)
    end
    
    -- Click handler
    button:SetScript("OnClick", function()
        ConsoleExperience.config:Toggle()
        HideUIPanel(GameMenuFrame)
    end)
    
    -- Move buttons below us down
    if GameMenuButtonKeybindings then
        GameMenuButtonKeybindings:SetPoint("TOP", button, "BOTTOM", 0, -1)
    end
    
    -- Increase frame height
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 25)
end

-- Create the game menu button when the addon loads
Config:CreateGameMenuButton()

-- ============================================================================
-- Crosshair
-- ============================================================================

function Config:CreateCrosshair()
    if self.crosshairFrame then return self.crosshairFrame end
    
    local frame = CreateFrame("Frame", "ConsoleExperienceCrosshair", UIParent)
    frame:SetWidth(32)
    frame:SetHeight(32)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    
    -- Create crosshair texture (simple cross)
    local size = 24
    local thickness = 2
    
    -- Horizontal line
    local hLine = frame:CreateTexture(nil, "OVERLAY")
    hLine:SetTexture(1, 1, 1, 0.8)
    hLine:SetWidth(size)
    hLine:SetHeight(thickness)
    hLine:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.hLine = hLine
    
    -- Vertical line
    local vLine = frame:CreateTexture(nil, "OVERLAY")
    vLine:SetTexture(1, 1, 1, 0.8)
    vLine:SetWidth(thickness)
    vLine:SetHeight(size)
    vLine:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.vLine = vLine
    
    -- Center dot
    local dot = frame:CreateTexture(nil, "OVERLAY")
    dot:SetTexture(1, 0.2, 0.2, 1)
    dot:SetWidth(4)
    dot:SetHeight(4)
    dot:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.dot = dot
    
    frame:Hide()
    self.crosshairFrame = frame
    
    return frame
end

function Config:UpdateCrosshair()
    if not self.crosshairFrame then
        self:CreateCrosshair()
    end
    
    local enabled = self:Get("crosshairEnabled")
    local xOffset = self:Get("crosshairX") or 0
    local yOffset = self:Get("crosshairY") or 0
    local size = self:Get("crosshairSize") or 24
    local thickness = math.max(2, math.floor(size / 12))
    
    -- Update position
    self.crosshairFrame:ClearAllPoints()
    self.crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
    self.crosshairFrame:SetWidth(size + 8)
    self.crosshairFrame:SetHeight(size + 8)
    
    -- Update crosshair line sizes
    if self.crosshairFrame.hLine then
        self.crosshairFrame.hLine:SetWidth(size)
        self.crosshairFrame.hLine:SetHeight(thickness)
    end
    if self.crosshairFrame.vLine then
        self.crosshairFrame.vLine:SetWidth(thickness)
        self.crosshairFrame.vLine:SetHeight(size)
    end
    if self.crosshairFrame.dot then
        local dotSize = math.max(2, math.floor(size / 6))
        self.crosshairFrame.dot:SetWidth(dotSize)
        self.crosshairFrame.dot:SetHeight(dotSize)
    end
    
    if enabled then
        self.crosshairFrame:Show()
    else
        self.crosshairFrame:Hide()
    end
end

-- Initialize crosshair on load (will apply saved settings after VARIABLES_LOADED via InitializeDB)
Config:CreateCrosshair()

-- ============================================================================
-- Action Bar Layout
-- ============================================================================

-- Layout positions relative to star center (in units of padding)
-- Format: { buttonId, xMultiplier, yMultiplier }
Config.BUTTON_LAYOUT = {
    -- Left star (D-Pad) - center at negative X offset
    { id = 10, star = "left",  x = 0,  y = 0 },   -- LB (center)
    { id = 7,  star = "left",  x = 0,  y = 1 },   -- Up
    { id = 5,  star = "left",  x = 0,  y = -1 },  -- Down
    { id = 6,  star = "left",  x = -1, y = 0 },   -- Left
    { id = 8,  star = "left",  x = 1,  y = 0 },   -- Right
    -- Right star (Face buttons) - center at positive X offset
    { id = 9,  star = "right", x = 0,  y = 0 },   -- RB (center)
    { id = 3,  star = "right", x = 0,  y = 1 },   -- Y (top)
    { id = 1,  star = "right", x = 0,  y = -1 },  -- A (bottom)
    { id = 2,  star = "right", x = -1, y = 0 },   -- X (left)
    { id = 4,  star = "right", x = 1,  y = 0 },   -- B (right)
}

function Config:UpdateActionBarLayout()
    local buttonSize = self:Get("barButtonSize") or 60
    local padding = self:Get("barPadding") or 65
    local starPadding = self:Get("barStarPadding") or 200
    local xOffset = self:Get("barXOffset") or 0
    local yOffset = self:Get("barYOffset") or 70
    local scale = self:Get("barScale") or 1.0
    
    -- Calculate star center positions
    -- Stars are separated by starPadding (half on each side)
    local starSpacing = starPadding / 2  -- Distance from center to each star center
    
    -- Store star positions for chat positioning
    self.leftStarCenterX = -starSpacing + xOffset
    self.rightStarCenterX = starSpacing + xOffset
    self.starYOffset = yOffset
    
    for _, buttonInfo in ipairs(self.BUTTON_LAYOUT) do
        local button = getglobal("ConsoleActionButton" .. buttonInfo.id)
        if button then
            -- Calculate star center X position
            local starCenterX
            if buttonInfo.star == "left" then
                starCenterX = self.leftStarCenterX
            else
                starCenterX = self.rightStarCenterX
            end
            
            -- Calculate button position relative to star center
            local buttonX = starCenterX + (buttonInfo.x * padding)
            local buttonY = yOffset + (buttonInfo.y * padding)
            
            -- Apply position and scale
            button:ClearAllPoints()
            button:SetPoint("BOTTOM", UIParent, "BOTTOM", buttonX, buttonY)
            button:SetWidth(buttonSize)
            button:SetHeight(buttonSize)
            button:SetScale(scale)
            
            -- Update child elements to match new size
            local icon = getglobal(button:GetName() .. "Icon")
            if icon then
                icon:SetWidth(buttonSize - 4)
                icon:SetHeight(buttonSize - 4)
            end
            
            local bg = getglobal(button:GetName() .. "Background")
            if bg then
                bg:SetWidth(buttonSize * 1.6)
                bg:SetHeight(buttonSize * 1.6)
            end
            
            local normalTex = getglobal(button:GetName() .. "NormalTexture")
            if normalTex then
                normalTex:SetWidth(buttonSize * 1.6)
                normalTex:SetHeight(buttonSize * 1.6)
            end
            
            local flash = getglobal(button:GetName() .. "Flash")
            if flash then
                flash:SetWidth(buttonSize - 4)
                flash:SetHeight(buttonSize - 4)
            end
            
            local controllerIcon = getglobal(button:GetName() .. "ControllerIcon")
            if controllerIcon then
                local iconSize = math.max(12, buttonSize / 2)
                controllerIcon:SetWidth(iconSize)
                controllerIcon:SetHeight(iconSize)
            end
            
            -- Update cooldown to match button size using scale
            -- Default cooldown size in WoW is typically 36 pixels
            -- Scale it to match buttonSize, then anchor it to fill the button
            local cooldown = getglobal(button:GetName() .. "Cooldown")
            if cooldown then
                local defaultCooldownSize = 36
                local scaleFactor = buttonSize / defaultCooldownSize
                
                -- Scale the cooldown to match button size
                cooldown:SetScale(scaleFactor)
                cooldown:ClearAllPoints()
                -- Use TOPLEFT/BOTTOMRIGHT to fill the button area
                cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
                cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
            end
        end
    end
    
    -- Update chat layout after action bars are positioned
    if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
        ConsoleExperience.chat:UpdateChatLayout()
    end
end

-- ============================================================================
-- Slash Command
-- ============================================================================

SLASH_CECONFIG1 = "/ce"
SLASH_CECONFIG2 = "/consoleexperience"
SlashCmdList["CECONFIG"] = function(msg)
    Config:Toggle()
end

