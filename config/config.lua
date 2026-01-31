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
    crosshairEnabled = true,
    crosshairX = 0,
    crosshairY = 50,
    crosshairSize = 24,
    crosshairType = "cross",  -- "cross" or "dot"
    crosshairColorR = 1.0,    -- Red component (0-1)
    crosshairColorG = 1.0,    -- Green component (0-1)
    crosshairColorB = 1.0,    -- Blue component (0-1)
    crosshairColorA = 0.8,    -- Alpha component (0-1)
    controllerType = "xbox",  -- "xbox" or "ps"
    healerMode = false,  -- Healer mode (affects targeting and gameplay)
    -- Action Bar settings
    barButtonSize = 60,
    barXOffset = 0,
    barYOffset = 70,
    barPadding = 65,
    barStarPadding = 600,  -- Padding between left and right star centers
    barScale = 1.0,
    barAppearance = "classic",  -- "classic" or "modern"
    autoRankEnabled = true,  -- Automatically update spells to highest rank
    druidStealth = false,  -- Use travel form bar when prowl/stealth is active in cat form
    -- Side Action Bars (touch screen)
    sideBarLeftEnabled = false,  -- Left side bar disabled by default
    sideBarRightEnabled = false,  -- Right side bar disabled by default
    sideBarLeftButtons = 3,  -- Number of buttons on left bar (1-5)
    sideBarRightButtons = 3,  -- Number of buttons on right bar (1-5)
    -- Chat settings
    chatEnabled = true,  -- If true, enable chat module functionality
    chatWidth = 400,
    chatHeight = 150,
    chatBottomY = 20,  -- Y position from bottom (adjusted for XP/Rep bars)
    keyboardEnabled = true,  -- If true, show virtual keyboard when chat edit box is visible
    -- XP/Rep Bar settings
    xpBarWidth = nil,  -- nil = use chat width
    xpBarHeight = 20,  -- Default height (minimum is 20 for border texture)
    xpBarDisplay = "XP",  -- "XP", "PETXP", "REP", "FLEX", "XPFLEX"
    xpBarAlways = true,  -- XP bar visible by default
    xpBarTimeout = 5.0,  -- Seconds before bar fades out
    xpBarTextShow = true,
    xpBarTextMouse = false,
    xpBarTextOffsetY = 0,
    xpBarColor = "0.0,1.0,0.0,1.0",  -- WoW default green for XP
    xpBarRestColor = "0.0,0.5,1.0,1.0",  -- WoW default blue for rested
    xpBarDontOverlap = false,
    repBarWidth = nil,  -- nil = use chat width
    repBarHeight = 20,  -- Default height (minimum is 20 for border texture)
    repBarDisplay = "REP",  -- "REP", "FLEX"
    repBarAlways = false,  -- Rep bar hidden by default
    repBarTimeout = 5.0,  -- Seconds before bar fades out
    repBarTextShow = true,
    repBarTextMouse = false,
    repBarTextOffsetY = 0,
    -- Castbar settings
    castbarEnabled = true,  -- Castbar enabled by default
    castbarHeight = 20,     -- Default height
    castbarColorR = 0.0,    -- Blue by default (for regular casts)
    castbarColorG = 0.5,
    castbarColorB = 1.0,
    castbarChannelColorR = 1.0,    -- Gold by default (for channeling)
    castbarChannelColorG = 0.75,
    castbarChannelColorB = 0.25,
    -- Keybinding settings (proxied actions are now managed by config/proxied.lua)
    -- Locale settings
    language = nil,  -- nil = use game locale, otherwise "enUS", "deDE", etc.
    -- Bag settings
    openAllBagsAtVendor = true,  -- Open all bags when interacting with merchants/auction house
}

-- ============================================================================
-- Configuration Get/Set Functions
-- ============================================================================

function Config:InitializeDB()
    -- Ensure ConsoleExperienceDB exists
    if not ConsoleExperienceDB then
        ConsoleExperienceDB = {}
    end
    
    -- Initialize profiles system first (handles migration from legacy config)
    if ConsoleExperience.profiles and ConsoleExperience.profiles.Initialize then
        ConsoleExperience.profiles:Initialize()
    end
    
    -- Initialize config section if it doesn't exist (profiles migration should have done this, but be safe)
    if not ConsoleExperienceDB.config then
        ConsoleExperienceDB.config = {}
    end
    
    -- Set defaults for any missing values (generic - automatically adds new defaults)
    for key, defaultValue in pairs(self.DEFAULTS) do
        if ConsoleExperienceDB.config[key] == nil then
            ConsoleExperienceDB.config[key] = defaultValue
            CE_Debug("Config: Added missing default '" .. key .. "' = " .. tostring(defaultValue))
        end
    end
    
    -- Initialize locale if available
    if ConsoleExperience.locale then
        ConsoleExperience.locale:Initialize()
    end
    
    -- Apply debug setting to global variable
    ConsoleExperience_DEBUG_KEYS = ConsoleExperienceDB.config.debugEnabled
    
    -- Apply crosshair setting
    self:UpdateCrosshair()
    
    -- Apply action bar layout
    self:UpdateActionBarLayout()
    
    -- Apply chat module state (only if chat is enabled)
    -- Note: Don't call UpdateChatLayout here as chat module might not be initialized yet
    -- The initialization will happen in main.lua after VARIABLES_LOADED
    if not ConsoleExperienceDB.config.chatEnabled and ConsoleExperience.chat then
        -- Disable chat module if chatEnabled is false
        if ConsoleExperience.chat.Disable then
            ConsoleExperience.chat:Disable()
        end
    end
    
    -- Apply XP/Rep bar layout
    if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
        ConsoleExperience.xpbar:UpdateAllBars()
    end
    
    -- Apply castbar layout
    if ConsoleExperience.castbar and ConsoleExperience.castbar.ReloadConfig then
        ConsoleExperience.castbar:ReloadConfig()
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

Config.FRAME_WIDTH = 900
Config.FRAME_HEIGHT = 650
Config.SIDEBAR_WIDTH = 150
Config.BUTTON_HEIGHT = 28
Config.PADDING = 15

-- Section definitions
Config.SECTIONS = {
    { id = "interface", name = "Interface" },
    { id = "bars", name = "Bars" },
    { id = "bindings", name = "Bindings" },
    { id = "profiles", name = "Profiles" },
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
    
    -- Background - use pfUI styling if available
    if pfUI and CreateBackdrop then
        -- Use pfUI's CreateBackdrop for consistent styling
        CreateBackdrop(frame, nil, true, .75)
        if CreateBackdropShadow then
            CreateBackdropShadow(frame)
        end
    else
        -- Default Blizzard styling
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
    end
    
    -- Title bar for dragging (full width like UIOptionsFrame)
    local titleRegion = CreateFrame("Frame", nil, frame)
    titleRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
    titleRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -5)
    titleRegion:SetHeight(30)
    titleRegion:EnableMouse(true)
    titleRegion:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    titleRegion:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    
    -- Header texture (like DialogFrame - sits on top of the border)
    local headerTexture = frame:CreateTexture(nil, "ARTWORK")
    headerTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    headerTexture:SetWidth(300)
    headerTexture:SetHeight(64)
    headerTexture:SetPoint("TOP", frame, "TOP", 0, 12)
    frame.headerTexture = headerTexture
    
    -- Title text (positioned on the header texture like UIOptionsFrame)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", headerTexture, "TOP", 0, -14)
    -- Title will be set after locale is initialized, store reference
    frame.titleText = title
    
    -- Footer height for buttons
    local footerHeight = 40
    
    -- Sidebar frame (adjusted to leave room for footer)
    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", self.PADDING + 5, -45)
    sidebar:SetWidth(self.SIDEBAR_WIDTH)
    sidebar:SetHeight(self.FRAME_HEIGHT - 45 - footerHeight - self.PADDING)
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
    
    -- Content frame (outer container with backdrop, leaves room for footer)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", self.PADDING, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -self.PADDING - 5, footerHeight + self.PADDING)
    content:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    content:SetBackdropColor(0.05, 0.05, 0.05, 0.3)
    frame.content = content
    
    -- Footer buttons (like UIOptionsFrame)
    -- Close button (right side, like UIOptionsFrame Cancel button)
    local closeButton = CreateFrame("Button", "ConsoleExperienceConfigCloseButton", frame, "GameMenuButtonTemplate")
    closeButton:SetWidth(96)
    closeButton:SetHeight(21)
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -self.PADDING - 5, self.PADDING)
    closeButton:SetText(CLOSE or "Close")
    closeButton:SetScript("OnClick", function()
        PlaySound("gsTitleOptionExit")
        -- Save current profile before closing
        if ConsoleExperience.profiles and ConsoleExperience.profiles.SaveCurrentProfile then
            ConsoleExperience.profiles:SaveCurrentProfile()
        end
        ConsoleExperience.config.frame:Hide()
    end)
    -- Apply pfUI styling if available
    if pfUI and SkinButton then
        SkinButton(closeButton)
    end
    frame.closeButton = closeButton
    
    -- Debug button (left side)
    local debugButton = CreateFrame("Button", "ConsoleExperienceConfigDebugButton", frame, "GameMenuButtonTemplate")
    debugButton:SetWidth(96)
    debugButton:SetHeight(21)
    debugButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", self.PADDING + 5, self.PADDING)
    
    -- Update debug button text based on current state
    local function UpdateDebugButtonText()
        local debugEnabled = Config:Get("debugEnabled")
        if debugEnabled then
            debugButton:SetText("Debug: ON")
        else
            debugButton:SetText("Debug: OFF")
        end
    end
    UpdateDebugButtonText()
    frame.UpdateDebugButtonText = UpdateDebugButtonText
    
    debugButton:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        local debugEnabled = Config:Get("debugEnabled")
        Config:Set("debugEnabled", not debugEnabled)
        UpdateDebugButtonText()
        if not debugEnabled then
            CE_Debug("Debug output ENABLED")
        else
            CE_Debug("Debug output DISABLED")
        end
    end)
    frame.debugButton = debugButton
    
    
    -- Store reference
    self.frame = frame
    
    -- Set title text after locale is available
    if frame.titleText then
        local Locale = ConsoleExperience.locale
        local T = Locale and Locale.T or function(key) return key end
        frame.titleText:SetText(T("Console Experience"))
    end
    
    -- Apply pfUI styling to title text if available
    if pfUI and pfUI.font_default and frame.titleText then
        frame.titleText:SetFont(pfUI.font_default, 14, "OUTLINE")
    end
    
    -- Add to special frames so Escape closes it
    table.insert(UISpecialFrames, "ConsoleExperienceConfigFrame")
    
    -- Create sidebar buttons
    self:CreateSidebarButtons()
    
    -- Create content sections
    self:CreateContentSections()
    
    -- Show first section by default
    self:ShowSection("interface")
    
    -- Hook frame for cursor navigation
    if ConsoleExperience.hooks and ConsoleExperience.hooks.HookDynamicFrame then
        ConsoleExperience.hooks:HookDynamicFrame(frame, "Console Experience Config")
    end
    
    -- Apply pfUI styling will be done via the periodic check
    
    return frame
end

-- ============================================================================
-- Sidebar Buttons
-- ============================================================================

function Config:CreateSidebarButtons()
    local sidebar = self.frame.sidebar
    self.sidebarButtons = {}
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
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
        
        -- Button text (use translation)
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", button, "CENTER", 0, 0)
        text:SetText(T(section.name))
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
    
    -- Create Interface section
    self:CreateInterfaceSection()
    
    -- Create Bars section
    self:CreateBarsSection()
    
    -- Create Bindings section
    self:CreateBindingsSection()
    
    -- Create Profiles section
    self:CreateProfilesSection()
end

function Config:CreateInterfaceSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    -- Main section container (attached to content)
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    
    -- ==================== General Settings Box ====================
    local generalBox = self:CreateSectionBox(section, T("General"))
    generalBox:SetPoint("TOP", section, "TOP", 0, -25)
    
    -- Controller Type dropdown (left side)
    local controllerTypeLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    controllerTypeLabel:SetPoint("TOPLEFT", generalBox, "TOPLEFT", generalBox.contentLeft, generalBox.contentTop)
    controllerTypeLabel:SetText(T("Controller Type") .. ":")
    
    local controllerTypeDropdown = CreateFrame("Frame", "CEConfigControllerTypeDropdown", generalBox, "UIDropDownMenuTemplate")
    controllerTypeDropdown:SetPoint("LEFT", controllerTypeLabel, "RIGHT", -15, -3)
    
    -- Initialize function for controller type dropdown
    local function InitializeControllerTypeDropdown()
        local selectedValue = UIDropDownMenu_GetSelectedValue(controllerTypeDropdown) or (Config:Get("controllerType") or "xbox")
        local info
        
        info = {}
        info.text = "Xbox"
        info.value = "xbox"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(controllerTypeDropdown, "xbox")
            UIDropDownMenu_SetText("Xbox", controllerTypeDropdown)
            Config:Set("controllerType", "xbox")
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
            if ConsoleExperience.placement and ConsoleExperience.placement.RefreshIcons then
                ConsoleExperience.placement:RefreshIcons()
            end
            if Config.RefreshBindingIcons then
                Config:RefreshBindingIcons()
            end
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
        
        info = {}
        info.text = "PlayStation"
        info.value = "ps"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(controllerTypeDropdown, "ps")
            UIDropDownMenu_SetText("PlayStation", controllerTypeDropdown)
            Config:Set("controllerType", "ps")
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
            if ConsoleExperience.placement and ConsoleExperience.placement.RefreshIcons then
                ConsoleExperience.placement:RefreshIcons()
            end
            if Config.RefreshBindingIcons then
                Config:RefreshBindingIcons()
            end
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(controllerTypeDropdown, InitializeControllerTypeDropdown)
    UIDropDownMenu_SetWidth(120, controllerTypeDropdown)
    local currentControllerType = Config:Get("controllerType") or "xbox"
    UIDropDownMenu_SetSelectedValue(controllerTypeDropdown, currentControllerType)
    UIDropDownMenu_SetText(currentControllerType == "xbox" and "Xbox" or "PlayStation", controllerTypeDropdown)
    
    -- Healer Mode checkbox (below controller type, left side)
    local healerModeCheck = self:CreateCheckbox(generalBox, T("Healer Mode"),
        function() return Config:Get("healerMode") end,
        function(checked)
            Config:Set("healerMode", checked)
            CE_Debug("Healer mode " .. (checked and "enabled" or "disabled"))
            -- Update party/raid frame hooks when healer mode changes
            if ConsoleExperience.hooks and ConsoleExperience.hooks.HookPartyRaidFrames then
                ConsoleExperience.hooks:HookPartyRaidFrames()
            end
            -- Update action bar buttons (to hide/show D-pad buttons)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
        end,
        T("Enable healer mode for improved healing and targeting."))
    healerModeCheck:SetPoint("TOPLEFT", controllerTypeLabel, "BOTTOMLEFT", 0, -15)
    
    -- Language dropdown (center)
    local langLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    langLabel:SetPoint("TOP", generalBox, "TOP", -80, generalBox.contentTop)
    langLabel:SetText(T("Language") .. ":")
    
    local langDropdown = CreateFrame("Frame", "CEConfigLanguageDropdown", generalBox, "UIDropDownMenuTemplate")
    langDropdown:SetPoint("LEFT", langLabel, "RIGHT", -15, -3)
    
    -- Initialize function for language dropdown
    local function InitializeLanguageDropdown()
        if not Locale then 
            CE_Debug("Language dropdown: Locale module not found")
            return 
        end
        
        local available = Locale:GetAvailableLanguages()
        
        if table.getn(available) == 0 then 
            local info = {}
            info.text = "English"
            info.value = "enUS"
            info.func = function()
                UIDropDownMenu_SetSelectedValue(langDropdown, "enUS")
                UIDropDownMenu_SetText("English", langDropdown)
                Locale:SetLanguage("enUS")
                StaticPopup_Show("CE_RELOAD_UI")
            end
            info.checked = 1
            UIDropDownMenu_AddButton(info)
            return
        end
        
        local selectedValue = UIDropDownMenu_GetSelectedValue(langDropdown) or (Config:Get("language") or GetLocale() or "enUS")
        local info
        
        for _, lang in ipairs(available) do
            info = {}
            info.text = Locale:GetLanguageName(lang)
            info.value = lang
            info.func = function()
                UIDropDownMenu_SetSelectedValue(langDropdown, lang)
                UIDropDownMenu_SetText(Locale:GetLanguageName(lang), langDropdown)
                Locale:SetLanguage(lang)
                StaticPopup_Show("CE_RELOAD_UI")
            end
            if info.value == selectedValue then
                info.checked = 1
            end
            UIDropDownMenu_AddButton(info)
        end
    end
    
    langDropdown.initialize = InitializeLanguageDropdown
    UIDropDownMenu_Initialize(langDropdown, InitializeLanguageDropdown)
    UIDropDownMenu_SetWidth(120, langDropdown)
    local currentLang = Config:Get("language") or GetLocale() or "enUS"
    UIDropDownMenu_SetSelectedValue(langDropdown, currentLang)
    local langName = Locale and Locale:GetLanguageName(currentLang) or currentLang
    UIDropDownMenu_SetText(langName, langDropdown)
    
    -- Open All Bags at Vendor checkbox (right side, same row)
    local openBagsLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    openBagsLabel:SetPoint("TOP", controllerTypeLabel, "TOP", 0, 0)
    openBagsLabel:SetPoint("RIGHT", generalBox, "RIGHT", -50, 0)
    openBagsLabel:SetText(T("Open all bags at vendor"))
    
    local openBagsCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), generalBox, "UICheckButtonTemplate")
    openBagsCheck:SetWidth(24)
    openBagsCheck:SetHeight(24)
    openBagsCheck:SetPoint("LEFT", openBagsLabel, "RIGHT", 5, 0)
    openBagsCheck.label = T("Open all bags at vendor")
    openBagsCheck.tooltipText = T("Automatically open all bags when interacting with merchants, auction house, or bank.")
    openBagsCheck:SetChecked(Config:Get("openAllBagsAtVendor"))
    openBagsCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("openAllBagsAtVendor", checked)
        if checked then
            CE_Debug("Open all bags at vendor ENABLED")
        else
            CE_Debug("Open all bags at vendor DISABLED")
        end
    end)
    
    -- Ensure dropdown buttons are navigable and have tooltips
    local generalDelayFrame = CreateFrame("Frame")
    generalDelayFrame:SetScript("OnUpdate", function()
        generalDelayFrame:Hide()
        local ctrlBtn = getglobal("CEConfigControllerTypeDropdownButton")
        if ctrlBtn then 
            ctrlBtn:Enable()
            ctrlBtn:Show()
            ctrlBtn.label = T("Controller Type")
            ctrlBtn.tooltipText = T("Select which controller button icons to display (Xbox or PlayStation style).")
        end
        local langBtn = getglobal("CEConfigLanguageDropdownButton")
        if langBtn then 
            langBtn:Enable()
            langBtn:Show()
            langBtn.label = T("Language")
            langBtn.tooltipText = T("Select the language for the addon interface. Requires a UI reload to take effect.")
        end
        if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
            ConsoleExperience.cursor:RefreshFrame()
        end
    end)
    generalDelayFrame:Show()
    
    -- ==================== Crosshair Settings Box ====================
    local crosshairBox = self:CreateSectionBox(section, T("Crosshair"))
    crosshairBox:SetPoint("TOP", generalBox, "BOTTOM", 0, -30)
    
    -- ===== ROW 1: Enable, Type, Color (spread across width) =====
    
    -- Enable Crosshair checkbox (left)
    local crosshairCheck = self:CreateCheckbox(crosshairBox, T("Enable"), 
        function() return Config:Get("crosshairEnabled") end,
        function(checked)
            Config:Set("crosshairEnabled", checked)
            Config:UpdateCrosshair()
            if checked then
                CE_Debug("Crosshair ENABLED")
            else
                CE_Debug("Crosshair DISABLED")
            end
        end,
        T("Show a crosshair overlay in the center of the screen for easier targeting."))
    crosshairCheck:SetPoint("TOPLEFT", crosshairBox, "TOPLEFT", crosshairBox.contentLeft, crosshairBox.contentTop)
    
    -- Type dropdown (center)
    local typeLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeLabel:SetPoint("TOP", crosshairBox, "TOP", -80, crosshairBox.contentTop)
    typeLabel:SetText(T("Type") .. ":")
    
    local typeDropdown = CreateFrame("Frame", "CEConfigCrosshairTypeDropdown", crosshairBox, "UIDropDownMenuTemplate")
    typeDropdown:SetPoint("LEFT", typeLabel, "RIGHT", -15, -3)
    
    local function InitializeTypeDropdown()
        local selectedValue = UIDropDownMenu_GetSelectedValue(typeDropdown) or (Config:Get("crosshairType") or "cross")
        local info
        
        info = {}
        info.text = T("Cross")
        info.value = "cross"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(typeDropdown, "cross")
            UIDropDownMenu_SetText(T("Cross"), typeDropdown)
            Config:Set("crosshairType", "cross")
            Config:UpdateCrosshair()
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
        
        info = {}
        info.text = T("Dot")
        info.value = "dot"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(typeDropdown, "dot")
            UIDropDownMenu_SetText(T("Dot"), typeDropdown)
            Config:Set("crosshairType", "dot")
            Config:UpdateCrosshair()
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(typeDropdown, InitializeTypeDropdown)
    UIDropDownMenu_SetWidth(90, typeDropdown)
    local currentType = Config:Get("crosshairType") or "cross"
    UIDropDownMenu_SetSelectedValue(typeDropdown, currentType)
    UIDropDownMenu_SetText(currentType == "cross" and T("Cross") or T("Dot"), typeDropdown)
    
    -- Color button (right)
    local colorLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colorLabel:SetPoint("TOPRIGHT", crosshairBox, "TOPRIGHT", -100, crosshairBox.contentTop)
    colorLabel:SetText(T("Color") .. ":")
    
    local colorButton = CreateFrame("Button", "CEConfigCrosshairColor", crosshairBox)
    colorButton:SetWidth(60)
    colorButton:SetHeight(20)
    colorButton:SetPoint("LEFT", colorLabel, "RIGHT", 5, 0)
    colorButton.label = T("Crosshair Color")
    colorButton.tooltipText = T("Click to open the color picker and choose the crosshair color and opacity.")
    
    colorButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
    local colorPreview = colorButton:CreateTexture(nil, "OVERLAY")
    colorPreview:SetPoint("TOPLEFT", colorButton, "TOPLEFT", 2, -2)
    colorPreview:SetPoint("BOTTOMRIGHT", colorButton, "BOTTOMRIGHT", -2, 2)
    colorButton.colorPreview = colorPreview
    
    local function UpdateColorPreview()
        local r = Config:Get("crosshairColorR") or 1.0
        local g = Config:Get("crosshairColorG") or 1.0
        local b = Config:Get("crosshairColorB") or 1.0
        local a = Config:Get("crosshairColorA") or 0.8
        colorPreview:SetTexture(r, g, b, a)
        colorButton:SetBackdropColor(r, g, b, 1)
    end
    
    colorButton:SetScript("OnClick", function()
        local r = Config:Get("crosshairColorR") or 1.0
        local g = Config:Get("crosshairColorG") or 1.0
        local b = Config:Get("crosshairColorB") or 1.0
        local a = Config:Get("crosshairColorA") or 0.8
        
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ColorPickerFrame:SetFrameLevel(2000)
        if ColorPickerOkayButton then
            ColorPickerOkayButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerOkayButton:SetFrameLevel(2001)
        end
        if ColorPickerCancelButton then
            ColorPickerCancelButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerCancelButton:SetFrameLevel(2001)
        end
        
        ColorPickerFrame.func = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            local newA = 1 - OpacitySliderFrame:GetValue()
            Config:Set("crosshairColorR", newR)
            Config:Set("crosshairColorG", newG)
            Config:Set("crosshairColorB", newB)
            Config:Set("crosshairColorA", newA)
            UpdateColorPreview()
            Config:UpdateCrosshair()
        end
        
        ColorPickerFrame.opacityFunc = function()
            local newA = 1 - OpacitySliderFrame:GetValue()
            Config:Set("crosshairColorA", newA)
            UpdateColorPreview()
            Config:UpdateCrosshair()
        end
        
        ColorPickerFrame:SetColorRGB(r, g, b)
        OpacitySliderFrame:SetValue(1 - a)
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = 1 - a
        
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            ColorPickerFrame:Show()
        end)
        delayFrame:Show()
    end)
    UpdateColorPreview()
    
    -- ===== ROW 2: Position controls (X, Y, Size) =====
    
    local xLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xLabel:SetPoint("TOPLEFT", crosshairCheck, "BOTTOMLEFT", 0, -15)
    xLabel:SetText(T("X Offset") .. ":")
    
    local xEditBox = self:CreateEditBox(crosshairBox, 50, 
        function() return tostring(Config:Get("crosshairX")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("crosshairX", num)
            Config:UpdateCrosshair()
        end,
        T("X Offset"),
        T("Horizontal offset from screen center. Negative values move left, positive values move right."))
    xEditBox:SetPoint("LEFT", xLabel, "RIGHT", 5, 0)
    xEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("crosshairX", num)
        Config:UpdateCrosshair()
    end)
    
    local yLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    yLabel:SetPoint("LEFT", xEditBox, "RIGHT", 30, 0)
    yLabel:SetText(T("Y Offset") .. ":")
    
    local yEditBox = self:CreateEditBox(crosshairBox, 50, 
        function() return tostring(Config:Get("crosshairY")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("crosshairY", num)
            Config:UpdateCrosshair()
        end,
        T("Y Offset"),
        T("Vertical offset from screen center. Negative values move down, positive values move up."))
    yEditBox:SetPoint("LEFT", yLabel, "RIGHT", 5, 0)
    yEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("crosshairY", num)
        Config:UpdateCrosshair()
    end)
    
    local sizeLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("LEFT", yEditBox, "RIGHT", 30, 0)
    sizeLabel:SetText(T("Size") .. ":")
    
    local sizeEditBox = self:CreateEditBox(crosshairBox, 50, 
        function() return tostring(Config:Get("crosshairSize")) end,
        function(value)
            local num = tonumber(value) or 24
            if num < 4 then num = 4 end
            if num > 100 then num = 100 end
            Config:Set("crosshairSize", num)
            Config:UpdateCrosshair()
        end,
        T("Crosshair Size"),
        T("Size of the crosshair in pixels. Range: 4-100 pixels."))
    sizeEditBox:SetPoint("LEFT", sizeLabel, "RIGHT", 5, 0)
    sizeEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 24
        if num < 4 then num = 4 end
        if num > 100 then num = 100 end
        Config:Set("crosshairSize", num)
        Config:UpdateCrosshair()
    end)
    
    
    -- Ensure dropdown button is navigable and has tooltip
    local crosshairDelayFrame = CreateFrame("Frame")
    crosshairDelayFrame:SetScript("OnUpdate", function()
        crosshairDelayFrame:Hide()
        local dropdownButton = getglobal("CEConfigCrosshairTypeDropdownButton")
        if dropdownButton then
            dropdownButton:Enable()
            dropdownButton:Show()
            dropdownButton.label = T("Crosshair Type")
            dropdownButton.tooltipText = T("Choose the crosshair style: Cross shows a traditional + shape, Dot shows a single circular dot.")
        end
        if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
            ConsoleExperience.cursor:RefreshFrame()
        end
    end)
    crosshairDelayFrame:Show()
    
    -- ==================== Chat Settings Box ====================
    local chatBox = self:CreateSectionBox(section, T("Chat"))
    chatBox:SetPoint("TOP", crosshairBox, "BOTTOM", 0, -30)
    
    -- Row 1: Width, Height inputs and Reset button
    local chatWidthLabel = chatBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chatWidthLabel:SetPoint("TOPLEFT", chatBox, "TOPLEFT", chatBox.contentLeft, chatBox.contentTop)
    chatWidthLabel:SetText(T("Width") .. ":")
    
    local chatWidthEditBox = self:CreateEditBox(chatBox, 50, 
        function() return tostring(Config:Get("chatWidth")) end,
        function(value)
            local num = tonumber(value) or 400
            if num < 100 then num = 100 end
            if num > 2000 then num = 2000 end
            Config:Set("chatWidth", num)
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end,
        T("Chat Width"),
        T("Width of the chat frame in pixels. Range: 100-2000."))
    chatWidthEditBox:SetPoint("LEFT", chatWidthLabel, "RIGHT", 5, 0)
    
    local chatHeightLabel = chatBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chatHeightLabel:SetPoint("LEFT", chatWidthEditBox, "RIGHT", 30, 0)
    chatHeightLabel:SetText(T("Height") .. ":")
    
    local chatHeightEditBox = self:CreateEditBox(chatBox, 50, 
        function() return tostring(Config:Get("chatHeight")) end,
        function(value)
            local num = tonumber(value) or 200
            if num < 50 then num = 50 end
            if num > 1000 then num = 1000 end
            Config:Set("chatHeight", num)
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end,
        T("Chat Height"),
        T("Height of the chat frame in pixels. Range: 50-1000."))
    chatHeightEditBox:SetPoint("LEFT", chatHeightLabel, "RIGHT", 5, 0)
    
    -- Reset Chat button (right side of row 1)
    local resetChatButton = CreateFrame("Button", "CEConfigResetChat", chatBox, "UIPanelButtonTemplate")
    resetChatButton:SetWidth(100)
    resetChatButton:SetHeight(24)
    resetChatButton:SetPoint("TOP", chatWidthLabel, "TOP", 0, 2)
    resetChatButton:SetPoint("RIGHT", chatBox, "RIGHT", chatBox.contentRight, 0)
    resetChatButton:SetText(T("Reset"))
    resetChatButton.label = T("Reset Chat Settings")
    resetChatButton.tooltipText = T("Reset chat module, width, height, and keyboard settings to defaults.")
    
    -- Row 2: Chat Module toggle
    -- Note: We need to declare keyboardCheck variable first so it can be referenced in the callback
    local keyboardCheck = nil
    
    local chatEnabledCheck = self:CreateCheckbox(chatBox, T("Enable Chat Module"), 
        function() return Config:Get("chatEnabled") end,
        function(checked)
            Config:Set("chatEnabled", checked)
            CE_Debug("Chat module " .. (checked and "enabled" or "disabled"))
            
            if checked then
                -- Enable chat module
                if ConsoleExperience.chat and ConsoleExperience.chat.Enable then
                    ConsoleExperience.chat:Enable()
                end
            else
                -- Disable chat module and also disable keyboard
                Config:Set("keyboardEnabled", false)
                if ConsoleExperience.chat and ConsoleExperience.chat.Disable then
                    ConsoleExperience.chat:Disable()
                end
                -- Hide keyboard if visible
                if ConsoleExperience.keyboard and ConsoleExperience.keyboard:IsVisible() then
                    ConsoleExperience.keyboard:Hide()
                end
                -- Update keyboard checkbox to reflect disabled state
                if keyboardCheck then
                    keyboardCheck:SetChecked(false)
                end
            end
        end,
        T("When enabled, the chat module manages chat frame positioning and behavior. Disabling also disables the virtual keyboard."))
    chatEnabledCheck:SetPoint("TOPLEFT", chatWidthLabel, "BOTTOMLEFT", 0, -15)
    
    -- Row 3: Virtual Keyboard toggle
    keyboardCheck = self:CreateCheckbox(chatBox, T("Enable Virtual Keyboard"), 
        function() return Config:Get("keyboardEnabled") and Config:Get("chatEnabled") end,
        function(checked)
            -- Only allow enabling keyboard if chat is enabled
            if not Config:Get("chatEnabled") then
                keyboardCheck:SetChecked(false)
                return
            end
            Config:Set("keyboardEnabled", checked)
            CE_Debug("Virtual keyboard " .. (checked and "enabled" or "disabled"))
            if not checked and ConsoleExperience.keyboard and ConsoleExperience.keyboard:IsVisible() then
                ConsoleExperience.keyboard:Hide()
            end
            if not checked and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                ChatFrameEditBox:EnableKeyboard(true)
                local focusFrame = CreateFrame("Frame")
                focusFrame:SetScript("OnUpdate", function()
                    this.elapsed = (this.elapsed or 0) + arg1
                    if this.elapsed > 0.1 then
                        this:SetScript("OnUpdate", nil)
                        if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                            ChatFrameEditBox:SetFocus()
                        end
                    end
                end)
            end
        end,
        T("When enabled, a virtual keyboard appears when typing in chat. Requires chat module to be enabled."))
    keyboardCheck:SetPoint("TOPLEFT", chatEnabledCheck, "BOTTOMLEFT", 0, -10)
    resetChatButton:SetScript("OnClick", function()
        Config:Set("chatWidth", Config.DEFAULTS.chatWidth)
        Config:Set("chatHeight", Config.DEFAULTS.chatHeight)
        Config:Set("chatEnabled", Config.DEFAULTS.chatEnabled)
        Config:Set("keyboardEnabled", Config.DEFAULTS.keyboardEnabled)
        if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
            ConsoleExperience.chat:UpdateChatLayout()
        end
        chatWidthEditBox:SetText(tostring(Config.DEFAULTS.chatWidth))
        chatHeightEditBox:SetText(tostring(Config.DEFAULTS.chatHeight))
        chatEnabledCheck:SetChecked(Config.DEFAULTS.chatEnabled)
        keyboardCheck:SetChecked(Config.DEFAULTS.keyboardEnabled)
        CE_Debug("Chat settings reset to defaults")
    end)
    
    self.contentSections["interface"] = section
end

function Config:CreateBarsSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    
    -- ==================== General Action Bars Box ====================
    local generalBox = self:CreateSectionBox(section, T("General Action Bars"))
    generalBox:SetPoint("TOP", section, "TOP", 0, -25)
    
    -- Row 1: Appearance dropdown (left) and Auto-rank checkbox (right)
    local appearanceLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    appearanceLabel:SetPoint("TOPLEFT", generalBox, "TOPLEFT", generalBox.contentLeft, generalBox.contentTop)
    appearanceLabel:SetText(T("Appearance") .. ":")
    
    local appearanceDropdown = CreateFrame("Frame", "CEConfigBarAppearanceDropdown", generalBox, "UIDropDownMenuTemplate")
    appearanceDropdown:SetPoint("LEFT", appearanceLabel, "RIGHT", -15, -3)
    
    local function InitializeAppearanceDropdown()
        local selectedValue = UIDropDownMenu_GetSelectedValue(appearanceDropdown) or (Config:Get("barAppearance") or "classic")
        local info
        
        info = {}
        info.text = T("Classic")
        info.value = "classic"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(appearanceDropdown, "classic")
            UIDropDownMenu_SetText(T("Classic"), appearanceDropdown)
            Config:Set("barAppearance", "classic")
            Config:UpdateActionBarLayout()
        end
        if info.value == selectedValue then info.checked = 1 end
        UIDropDownMenu_AddButton(info)
        
        info = {}
        info.text = T("Modern")
        info.value = "modern"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(appearanceDropdown, "modern")
            UIDropDownMenu_SetText(T("Modern"), appearanceDropdown)
            Config:Set("barAppearance", "modern")
            Config:UpdateActionBarLayout()
        end
        if info.value == selectedValue then info.checked = 1 end
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(appearanceDropdown, InitializeAppearanceDropdown)
    UIDropDownMenu_SetWidth(100, appearanceDropdown)
    local currentAppearance = Config:Get("barAppearance") or "classic"
    UIDropDownMenu_SetSelectedValue(appearanceDropdown, currentAppearance)
    UIDropDownMenu_SetText(currentAppearance == "classic" and T("Classic") or T("Modern"), appearanceDropdown)
    
    -- Druid stealth option (middle of row 1, only visible to druids)
    local _, playerClass = UnitClass("player")
    local isDruid = (playerClass == "DRUID")
    
    local druidStealthLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    druidStealthLabel:SetPoint("TOP", appearanceLabel, "TOP", 0, 0)
    druidStealthLabel:SetPoint("LEFT", appearanceDropdown, "RIGHT", 50, 0)
    druidStealthLabel:SetText(T("Use travel form bar in prowl"))
    
    local druidStealthCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), generalBox, "UICheckButtonTemplate")
    druidStealthCheck:SetWidth(24)
    druidStealthCheck:SetHeight(24)
    druidStealthCheck:SetPoint("LEFT", druidStealthLabel, "RIGHT", 5, 0)
    druidStealthCheck.label = T("Use travel form bar in prowl")
    druidStealthCheck.tooltipText = T("When enabled, druids in cat form will use the travel form action bar when prowl/stealth is active.")
    druidStealthCheck:SetChecked(Config:Get("druidStealth"))
    druidStealthCheck:SetScript("OnClick", function()
        if not isDruid then return end  -- Prevent clicking if not druid
        local checked = this:GetChecked() == 1
        Config:Set("druidStealth", checked)
        -- Update buttons immediately when toggled
        if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
            ConsoleExperience.actionbars:UpdateAllButtons()
        end
    end)
    
    -- Show/hide based on class
    if not isDruid then
        druidStealthLabel:Hide()
        druidStealthCheck:Hide()
    end
    
    -- Auto-rank label and checkbox (right side of row 1, label on left of toggle)
    local autoRankLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoRankLabel:SetPoint("TOP", appearanceLabel, "TOP", 0, 0)
    autoRankLabel:SetPoint("RIGHT", generalBox, "RIGHT", -50, 0)
    autoRankLabel:SetText(T("Auto-update spell ranks"))
    
    local autoRankCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), generalBox, "UICheckButtonTemplate")
    autoRankCheck:SetWidth(24)
    autoRankCheck:SetHeight(24)
    autoRankCheck:SetPoint("LEFT", autoRankLabel, "RIGHT", 5, 0)
    autoRankCheck.label = T("Auto-update spell ranks")
    autoRankCheck.tooltipText = T("When enabled, spells on action bars will automatically be updated to the highest rank when you learn a new spell rank.")
    autoRankCheck:SetChecked(Config:Get("autoRankEnabled"))
    autoRankCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("autoRankEnabled", checked)
    end)
    
    -- Row 2: Positioning options (Size, Pad, X, Y, Star, Scale) + Reset button
    local sizeLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("TOPLEFT", appearanceLabel, "BOTTOMLEFT", 0, -15)
    sizeLabel:SetText(T("Size") .. ":")
    
    local sizeEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barButtonSize")) end,
        function(value)
            local num = tonumber(value) or 40
            if num < 20 then num = 20 end
            if num > 80 then num = 80 end
            Config:Set("barButtonSize", num)
            Config:UpdateActionBarLayout()
        end,
        T("Button Size"),
        T("Size of action bar buttons in pixels. Range: 20-80."))
    sizeEditBox:SetPoint("LEFT", sizeLabel, "RIGHT", 5, 0)
    sizeEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 40
        if num >= 20 and num <= 80 then
            Config:Set("barButtonSize", num)
            Config:UpdateActionBarLayout()
        end
    end)
    
    local padLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    padLabel:SetPoint("LEFT", sizeEditBox, "RIGHT", 35, 0)
    padLabel:SetText(T("Pad") .. ":")
    
    local paddingEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barPadding")) end,
        function(value)
            local num = tonumber(value) or 4
            if num < 0 then num = 0 end
            if num > 100 then num = 100 end
            Config:Set("barPadding", num)
            Config:UpdateActionBarLayout()
        end,
        T("Button Padding"),
        T("Space between buttons in pixels. Range: 0-100."))
    paddingEditBox:SetPoint("LEFT", padLabel, "RIGHT", 5, 0)
    paddingEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 4
        if num >= 0 and num <= 100 then
            Config:Set("barPadding", num)
            Config:UpdateActionBarLayout()
        end
    end)
    
    local xLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xLabel:SetPoint("LEFT", paddingEditBox, "RIGHT", 35, 0)
    xLabel:SetText("X:")
    
    local xEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barXOffset")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("barXOffset", num)
            Config:UpdateActionBarLayout()
        end,
        T("X Offset"),
        T("Horizontal offset from screen center."))
    xEditBox:SetPoint("LEFT", xLabel, "RIGHT", 5, 0)
    xEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("barXOffset", num)
        Config:UpdateActionBarLayout()
    end)
    
    local yLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    yLabel:SetPoint("LEFT", xEditBox, "RIGHT", 35, 0)
    yLabel:SetText("Y:")
    
    local yEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barYOffset")) end,
        function(value)
            local num = tonumber(value) or 70
            Config:Set("barYOffset", num)
            Config:UpdateActionBarLayout()
        end,
        T("Y Offset"),
        T("Vertical offset from screen bottom."))
    yEditBox:SetPoint("LEFT", yLabel, "RIGHT", 5, 0)
    yEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 70
        Config:Set("barYOffset", num)
        Config:UpdateActionBarLayout()
    end)
    
    local starLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    starLabel:SetPoint("LEFT", yEditBox, "RIGHT", 35, 0)
    starLabel:SetText(T("Gap") .. ":")
    
    local starPaddingEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barStarPadding")) end,
        function(value)
            local num = tonumber(value) or 200
            if num < 50 then num = 50 end
            if num > 1000 then num = 1000 end
            Config:Set("barStarPadding", num)
            Config:UpdateActionBarLayout()
        end,
        T("Center Gap"),
        T("Space between left and right button groups. Range: 50-1000."))
    starPaddingEditBox:SetPoint("LEFT", starLabel, "RIGHT", 5, 0)
    starPaddingEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 200
        if num >= 50 and num <= 1000 then
            Config:Set("barStarPadding", num)
            Config:UpdateActionBarLayout()
        end
    end)
    
    local scaleLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLabel:SetPoint("LEFT", starPaddingEditBox, "RIGHT", 35, 0)
    scaleLabel:SetText(T("Scale") .. ":")
    
    local scaleEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barScale")) end,
        function(value)
            local num = tonumber(value) or 1.0
            if num < 0.5 then num = 0.5 end
            if num > 2.0 then num = 2.0 end
            Config:Set("barScale", num)
            Config:UpdateActionBarLayout()
        end,
        T("Scale"),
        T("Overall scale of action bars. Range: 0.5-2.0."))
    scaleEditBox:SetPoint("LEFT", scaleLabel, "RIGHT", 5, 0)
    scaleEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 1.0
        if num >= 0.5 and num <= 2.0 then
            Config:Set("barScale", num)
            Config:UpdateActionBarLayout()
        end
    end)
    
    -- Row 3: Reset button (left) and Update Spell Ranks button (right)
    local resetButton = CreateFrame("Button", "CEConfigResetLayout", generalBox, "UIPanelButtonTemplate")
    resetButton:SetWidth(100)
    resetButton:SetHeight(22)
    resetButton:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -15)
    resetButton:SetText(T("Reset"))
    resetButton.label = T("Reset Layout")
    resetButton.tooltipText = T("Reset all action bar settings to defaults.")
    resetButton:SetScript("OnClick", function()
        Config:Set("barButtonSize", Config.DEFAULTS.barButtonSize)
        Config:Set("barPadding", Config.DEFAULTS.barPadding)
        Config:Set("barStarPadding", Config.DEFAULTS.barStarPadding)
        Config:Set("barXOffset", Config.DEFAULTS.barXOffset)
        Config:Set("barYOffset", Config.DEFAULTS.barYOffset)
        Config:Set("barScale", Config.DEFAULTS.barScale)
        Config:Set("barAppearance", Config.DEFAULTS.barAppearance)
        Config:UpdateActionBarLayout()
        sizeEditBox:SetText(tostring(Config.DEFAULTS.barButtonSize))
        paddingEditBox:SetText(tostring(Config.DEFAULTS.barPadding))
        starPaddingEditBox:SetText(tostring(Config.DEFAULTS.barStarPadding))
        xEditBox:SetText(tostring(Config.DEFAULTS.barXOffset))
        yEditBox:SetText(tostring(Config.DEFAULTS.barYOffset))
        scaleEditBox:SetText(tostring(Config.DEFAULTS.barScale))
        local defAppearance = Config.DEFAULTS.barAppearance or "classic"
        UIDropDownMenu_SetSelectedValue(appearanceDropdown, defAppearance)
        UIDropDownMenu_SetText(defAppearance == "classic" and T("Classic") or T("Modern"), appearanceDropdown)
        CE_Debug("Action bar layout reset to defaults")
    end)
    
    local updateRanksButton = CreateFrame("Button", "CEConfigUpdateRanks", generalBox, "UIPanelButtonTemplate")
    updateRanksButton:SetWidth(140)
    updateRanksButton:SetHeight(22)
    updateRanksButton:SetPoint("TOP", resetButton, "TOP", 0, 0)
    updateRanksButton:SetPoint("RIGHT", generalBox, "RIGHT", generalBox.contentRight, 0)
    updateRanksButton:SetText(T("Update Spell Ranks"))
    updateRanksButton.label = T("Update Spell Ranks")
    updateRanksButton.tooltipText = T("Manually update all spells on action bars to their highest learned rank.")
    updateRanksButton:SetScript("OnClick", function()
        if ConsoleExperience.autorank and ConsoleExperience.autorank.ManualUpdate then
            ConsoleExperience.autorank:ManualUpdate()
        end
    end)
    
    -- Ensure dropdown button is navigable
    local barsDelayFrame = CreateFrame("Frame")
    barsDelayFrame:SetScript("OnUpdate", function()
        barsDelayFrame:Hide()
        local btn = getglobal("CEConfigBarAppearanceDropdownButton")
        if btn then
            btn:Enable()
            btn:Show()
            btn.label = T("Appearance")
            btn.tooltipText = T("Choose the visual style of action bar buttons: Classic (traditional WoW look) or Modern (cleaner style).")
        end
        if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
            ConsoleExperience.cursor:RefreshFrame()
        end
    end)
    barsDelayFrame:Show()
    
    -- ==================== Left Side Bar Box ====================
    local leftSideBox = self:CreateSectionBox(section, T("Left Action Bar (Touch)"))
    leftSideBox:ClearAllPoints()
    leftSideBox:SetPoint("TOPLEFT", generalBox, "BOTTOMLEFT", 0, -30)
    leftSideBox:SetPoint("RIGHT", section, "CENTER", -10, 0)
    leftSideBox:SetHeight(70)
    leftSideBox.heightCalculated = true  -- Don't auto-calculate
    
    local leftBarCheck = self:CreateCheckbox(leftSideBox, T("Enable"),
        function() return Config:Get("sideBarLeftEnabled") end,
        function(checked)
            Config:Set("sideBarLeftEnabled", checked)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
            -- Update sidebar binding visibility in config panel
            if Config.UpdateSidebarBindingVisibility then
                Config:UpdateSidebarBindingVisibility()
            end
        end,
        T("Enable vertical action bar on the left edge of the screen for touch input."))
    leftBarCheck:SetPoint("TOPLEFT", leftSideBox, "TOPLEFT", leftSideBox.contentLeft, leftSideBox.contentTop)
    
    local leftCountLabel = leftSideBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leftCountLabel:SetPoint("LEFT", leftBarCheck, "RIGHT", 60, 0)
    leftCountLabel:SetText(T("Buttons") .. ":")
    
    local leftCountEditBox = self:CreateEditBox(leftSideBox, 30,
        function() return tostring(Config:Get("sideBarLeftButtons") or 3) end,
        function(value)
            local num = tonumber(value) or 3
            if num < 1 then num = 1 end
            if num > 5 then num = 5 end
            Config:Set("sideBarLeftButtons", num)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
            -- Update sidebar binding visibility in config panel
            if Config.UpdateSidebarBindingVisibility then
                Config:UpdateSidebarBindingVisibility()
            end
        end,
        T("Left Bar Buttons"),
        T("Number of buttons on the left side bar. Range: 1-5."))
    leftCountEditBox:SetPoint("LEFT", leftCountLabel, "RIGHT", 5, 0)
    leftCountEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 3
        if num >= 1 and num <= 5 then
            Config:Set("sideBarLeftButtons", num)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
            -- Update sidebar binding visibility in config panel
            if Config.UpdateSidebarBindingVisibility then
                Config:UpdateSidebarBindingVisibility()
            end
        end
    end)
    
    -- ==================== Right Side Bar Box ====================
    local rightSideBox = self:CreateSectionBox(section, T("Right Action Bar (Touch)"))
    rightSideBox:ClearAllPoints()
    rightSideBox:SetPoint("TOPRIGHT", generalBox, "BOTTOMRIGHT", 0, -30)
    rightSideBox:SetPoint("LEFT", section, "CENTER", 10, 0)
    rightSideBox:SetHeight(70)
    rightSideBox.heightCalculated = true  -- Don't auto-calculate
    
    local rightBarCheck = self:CreateCheckbox(rightSideBox, T("Enable"),
        function() return Config:Get("sideBarRightEnabled") end,
        function(checked)
            Config:Set("sideBarRightEnabled", checked)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
            -- Update sidebar binding visibility in config panel
            if Config.UpdateSidebarBindingVisibility then
                Config:UpdateSidebarBindingVisibility()
            end
        end,
        T("Enable vertical action bar on the right edge of the screen for touch input."))
    rightBarCheck:SetPoint("TOPLEFT", rightSideBox, "TOPLEFT", rightSideBox.contentLeft, rightSideBox.contentTop)
    
    local rightCountLabel = rightSideBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rightCountLabel:SetPoint("LEFT", rightBarCheck, "RIGHT", 60, 0)
    rightCountLabel:SetText(T("Buttons") .. ":")
    
    local rightCountEditBox = self:CreateEditBox(rightSideBox, 30,
        function() return tostring(Config:Get("sideBarRightButtons") or 3) end,
        function(value)
            local num = tonumber(value) or 3
            if num < 1 then num = 1 end
            if num > 5 then num = 5 end
            Config:Set("sideBarRightButtons", num)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
            -- Update sidebar binding visibility in config panel
            if Config.UpdateSidebarBindingVisibility then
                Config:UpdateSidebarBindingVisibility()
            end
        end,
        T("Right Bar Buttons"),
        T("Number of buttons on the right side bar. Range: 1-5."))
    rightCountEditBox:SetPoint("LEFT", rightCountLabel, "RIGHT", 5, 0)
    rightCountEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 3
        if num >= 1 and num <= 5 then
            Config:Set("sideBarRightButtons", num)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
            -- Update sidebar binding visibility in config panel
            if Config.UpdateSidebarBindingVisibility then
                Config:UpdateSidebarBindingVisibility()
            end
        end
    end)
    
    -- ==================== XP Bar Box ====================
    local xpBox = self:CreateSectionBox(section, T("XP Bar"))
    xpBox:ClearAllPoints()
    xpBox:SetPoint("TOPLEFT", leftSideBox, "BOTTOMLEFT", 0, -30)
    xpBox:SetPoint("RIGHT", section, "CENTER", -10, 0)
    xpBox:SetHeight(95)
    xpBox.heightCalculated = true  -- Don't auto-calculate
    
    -- Row 1: Always Visible and Text checkboxes
    local xpAlwaysCheck = self:CreateCheckbox(xpBox, T("Always Visible"),
        function() return Config:Get("xpBarAlways") or false end,
        function(checked)
            Config:Set("xpBarAlways", checked)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.xpBar then
                ConsoleExperience.xpbar.xpBar.always = checked
                if checked then
                    ConsoleExperience.xpbar.xpBar:SetAlpha(1)
                    ConsoleExperience.xpbar.xpBar:Show()
                end
            end
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end,
        T("When enabled, the XP bar is always visible instead of fading out."))
    xpAlwaysCheck:SetPoint("TOPLEFT", xpBox, "TOPLEFT", xpBox.contentLeft, xpBox.contentTop)
    
    local xpTextLabel = xpBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpTextLabel:SetPoint("TOP", xpAlwaysCheck, "TOP", 0, 0)
    xpTextLabel:SetPoint("RIGHT", xpBox, "RIGHT", -50, 0)
    xpTextLabel:SetText(T("Text"))
    
    local xpTextShowCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), xpBox, "UICheckButtonTemplate")
    xpTextShowCheck:SetWidth(24)
    xpTextShowCheck:SetHeight(24)
    xpTextShowCheck:SetPoint("LEFT", xpTextLabel, "RIGHT", 5, 0)
    xpTextShowCheck.label = T("XP Text")
    xpTextShowCheck.tooltipText = T("Show XP text on the bar.")
    local xpTextValue = Config:Get("xpBarTextShow")
    xpTextShowCheck:SetChecked(xpTextValue == nil and true or xpTextValue)
    xpTextShowCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("xpBarTextShow", checked)
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.xpBar then
            ConsoleExperience.xpbar:ReloadBarConfig(ConsoleExperience.xpbar.xpBar, "XP")
            if ConsoleExperience.xpbar.xpBar.always then
                event = "PLAYER_XP_UPDATE"
                ConsoleExperience.xpbar.xpBar:GetScript("OnEvent")(ConsoleExperience.xpbar.xpBar)
            end
            if ConsoleExperience.xpbar.xpBar.bar and ConsoleExperience.xpbar.xpBar.bar.text then
                if checked then
                    ConsoleExperience.xpbar.xpBar.bar.text:Show()
                else
                    ConsoleExperience.xpbar.xpBar.bar.text:Hide()
                end
            end
        end
    end)
    
    -- Row 2: Width, Height, Timeout
    local xpWidthLabel = xpBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpWidthLabel:SetPoint("TOPLEFT", xpAlwaysCheck, "BOTTOMLEFT", 0, -10)
    xpWidthLabel:SetText(T("Width") .. ":")
    
    local xpWidthEditBox = self:CreateEditBox(xpBox, 40,
        function() 
            local val = Config:Get("xpBarWidth")
            return val and tostring(val) or "0"
        end,
        function(value)
            local num = tonumber(value)
            if num == 0 then num = nil end
            if num and num < 50 then num = 50 end
            if num and num > 2000 then num = 2000 end
            Config:Set("xpBarWidth", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end,
        T("XP Bar Width"),
        T("Width of XP bar in pixels. Set to 0 to match chat width."))
    xpWidthEditBox:SetPoint("LEFT", xpWidthLabel, "RIGHT", 5, 0)
    
    local xpHeightLabel = xpBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpHeightLabel:SetPoint("LEFT", xpWidthEditBox, "RIGHT", 35, 0)
    xpHeightLabel:SetText(T("Height") .. ":")
    
    local xpHeightEditBox = self:CreateEditBox(xpBox, 30,
        function() return tostring(Config:Get("xpBarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end
            if num > 100 then num = 100 end
            Config:Set("xpBarHeight", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end,
        T("XP Bar Height"),
        T("Height of XP bar in pixels. Range: 20-100."))
    xpHeightEditBox:SetPoint("LEFT", xpHeightLabel, "RIGHT", 5, 0)
    
    local xpTimeoutLabel = xpBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpTimeoutLabel:SetPoint("LEFT", xpHeightEditBox, "RIGHT", 35, 0)
    xpTimeoutLabel:SetText(T("Timeout") .. ":")
    
    local xpTimeoutEditBox = self:CreateEditBox(xpBox, 30,
        function() return tostring(Config:Get("xpBarTimeout") or 5.0) end,
        function(value)
            local num = tonumber(value) or 5.0
            if num < 0 then num = 0 end
            if num > 60 then num = 60 end
            Config:Set("xpBarTimeout", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.xpBar then
                ConsoleExperience.xpbar.xpBar.timeout = num
            end
        end,
        T("XP Bar Timeout"),
        T("Seconds before the bar fades out. Range: 0-60."))
    xpTimeoutEditBox:SetPoint("LEFT", xpTimeoutLabel, "RIGHT", 5, 0)
    
    -- ==================== Rep Bar Box ====================
    local repBox = self:CreateSectionBox(section, T("Rep Bar"))
    repBox:ClearAllPoints()
    repBox:SetPoint("TOPRIGHT", rightSideBox, "BOTTOMRIGHT", 0, -30)
    repBox:SetPoint("LEFT", section, "CENTER", 10, 0)
    repBox:SetHeight(95)
    repBox.heightCalculated = true  -- Don't auto-calculate
    
    -- Row 1: Always Visible and Text checkboxes
    local repAlwaysCheck = self:CreateCheckbox(repBox, T("Always Visible"),
        function() return Config:Get("repBarAlways") or false end,
        function(checked)
            Config:Set("repBarAlways", checked)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.repBar then
                ConsoleExperience.xpbar.repBar.always = checked
                if checked then
                    ConsoleExperience.xpbar.repBar:SetAlpha(1)
                    ConsoleExperience.xpbar.repBar:Show()
                end
            end
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end,
        T("When enabled, the Reputation bar is always visible instead of fading out."))
    repAlwaysCheck:SetPoint("TOPLEFT", repBox, "TOPLEFT", repBox.contentLeft, repBox.contentTop)
    
    local repTextLabel = repBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repTextLabel:SetPoint("TOP", repAlwaysCheck, "TOP", 0, 0)
    repTextLabel:SetPoint("RIGHT", repBox, "RIGHT", -50, 0)
    repTextLabel:SetText(T("Text"))
    
    local repTextShowCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), repBox, "UICheckButtonTemplate")
    repTextShowCheck:SetWidth(24)
    repTextShowCheck:SetHeight(24)
    repTextShowCheck:SetPoint("LEFT", repTextLabel, "RIGHT", 5, 0)
    repTextShowCheck.label = T("Rep Text")
    repTextShowCheck.tooltipText = T("Show Reputation text on the bar.")
    local repTextValue = Config:Get("repBarTextShow")
    repTextShowCheck:SetChecked(repTextValue == nil and true or repTextValue)
    repTextShowCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("repBarTextShow", checked)
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.repBar then
            ConsoleExperience.xpbar.repBar.text_show = checked
            ConsoleExperience.xpbar:ReloadBarConfig(ConsoleExperience.xpbar.repBar, "REP")
            if ConsoleExperience.xpbar.repBar.always then
                event = "UPDATE_FACTION"
                ConsoleExperience.xpbar.repBar:GetScript("OnEvent")(ConsoleExperience.xpbar.repBar)
            end
            if ConsoleExperience.xpbar.repBar.bar and ConsoleExperience.xpbar.repBar.bar.text then
                if checked then
                    ConsoleExperience.xpbar.repBar.bar.text:Show()
                else
                    ConsoleExperience.xpbar.repBar.bar.text:Hide()
                end
            end
        end
    end)
    
    -- Row 2: Width, Height, Timeout
    local repWidthLabel = repBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repWidthLabel:SetPoint("TOPLEFT", repAlwaysCheck, "BOTTOMLEFT", 0, -10)
    repWidthLabel:SetText(T("Width") .. ":")
    
    local repWidthEditBox = self:CreateEditBox(repBox, 40,
        function() 
            local val = Config:Get("repBarWidth")
            return val and tostring(val) or "0"
        end,
        function(value)
            local num = tonumber(value)
            if num == 0 then num = nil end
            if num and num < 50 then num = 50 end
            if num and num > 2000 then num = 2000 end
            Config:Set("repBarWidth", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end,
        T("Rep Bar Width"),
        T("Width of Reputation bar in pixels. Set to 0 to match chat width."))
    repWidthEditBox:SetPoint("LEFT", repWidthLabel, "RIGHT", 5, 0)
    
    local repHeightLabel = repBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repHeightLabel:SetPoint("LEFT", repWidthEditBox, "RIGHT", 35, 0)
    repHeightLabel:SetText(T("Height") .. ":")
    
    local repHeightEditBox = self:CreateEditBox(repBox, 30,
        function() return tostring(Config:Get("repBarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end
            if num > 100 then num = 100 end
            Config:Set("repBarHeight", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end,
        T("Rep Bar Height"),
        T("Height of Reputation bar in pixels. Range: 20-100."))
    repHeightEditBox:SetPoint("LEFT", repHeightLabel, "RIGHT", 5, 0)
    
    local repTimeoutLabel = repBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repTimeoutLabel:SetPoint("LEFT", repHeightEditBox, "RIGHT", 35, 0)
    repTimeoutLabel:SetText(T("Timeout") .. ":")
    
    local repTimeoutEditBox = self:CreateEditBox(repBox, 30,
        function() return tostring(Config:Get("repBarTimeout") or 5.0) end,
        function(value)
            local num = tonumber(value) or 5.0
            if num < 0 then num = 0 end
            if num > 60 then num = 60 end
            Config:Set("repBarTimeout", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.repBar then
                ConsoleExperience.xpbar.repBar.timeout = num
            end
        end,
        T("Rep Bar Timeout"),
        T("Seconds before the bar fades out. Range: 0-60."))
    repTimeoutEditBox:SetPoint("LEFT", repTimeoutLabel, "RIGHT", 5, 0)
    
    -- ==================== Cast Bar Box ====================
    local castBox = self:CreateSectionBox(section, T("Cast Bar"))
    castBox:ClearAllPoints()
    castBox:SetPoint("TOPLEFT", xpBox, "BOTTOMLEFT", 0, -30)
    castBox:SetPoint("RIGHT", section, "RIGHT", -5, 0)
    
    -- Row 1: Enable checkbox, Height, Color button
    local castEnabledCheck = self:CreateCheckbox(castBox, T("Enable"),
        function() return Config:Get("castbarEnabled") end,
        function(checked)
            Config:Set("castbarEnabled", checked)
            if ConsoleExperience.castbar and ConsoleExperience.castbar.ReloadConfig then
                ConsoleExperience.castbar:ReloadConfig()
            end
        end,
        T("Enable the custom cast bar that appears above chat."))
    castEnabledCheck:SetPoint("TOPLEFT", castBox, "TOPLEFT", castBox.contentLeft, castBox.contentTop)
    
    local castHeightLabel = castBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castHeightLabel:SetPoint("LEFT", castEnabledCheck, "RIGHT", 60, 0)
    castHeightLabel:SetText(T("Height") .. ":")
    
    local castHeightEditBox = self:CreateEditBox(castBox, 35,
        function() return tostring(Config:Get("castbarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end
            if num > 100 then num = 100 end
            Config:Set("castbarHeight", num)
            if ConsoleExperience.castbar and ConsoleExperience.castbar.UpdatePosition then
                ConsoleExperience.castbar:UpdatePosition()
            end
        end,
        T("Cast Bar Height"),
        T("Height of cast bar in pixels. Range: 20-100."))
    castHeightEditBox:SetPoint("LEFT", castHeightLabel, "RIGHT", 5, 0)
    
    local castColorLabel = castBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castColorLabel:SetPoint("LEFT", castHeightEditBox, "RIGHT", 20, 0)
    castColorLabel:SetText(T("Color") .. ":")
    
    local castColorBtn = CreateFrame("Button", self:GetNextElementName("ColorBtn"), castBox)
    castColorBtn:SetWidth(40)
    castColorBtn:SetHeight(20)
    castColorBtn:SetPoint("LEFT", castColorLabel, "RIGHT", 5, 0)
    castColorBtn.label = T("Cast Bar Color")
    castColorBtn.tooltipText = T("Click to choose the cast bar fill color.")
    
    local castColorPreview = castColorBtn:CreateTexture(nil, "BACKGROUND")
    castColorPreview:SetAllPoints()
    
    local function UpdateCastColorPreview()
        local r = Config:Get("castbarColorR") or 0.0
        local g = Config:Get("castbarColorG") or 0.5
        local b = Config:Get("castbarColorB") or 1.0
        castColorPreview:SetTexture(r, g, b)
    end
    UpdateCastColorPreview()
    
    castColorBtn:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    castColorBtn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    castColorBtn:SetScript("OnClick", function()
        local r = Config:Get("castbarColorR") or 0.0
        local g = Config:Get("castbarColorG") or 0.5
        local b = Config:Get("castbarColorB") or 1.0
        
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ColorPickerFrame:SetFrameLevel(2000)
        
        if ColorPickerOkayButton then
            ColorPickerOkayButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerOkayButton:SetFrameLevel(2001)
        end
        if ColorPickerCancelButton then
            ColorPickerCancelButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerCancelButton:SetFrameLevel(2001)
        end
        
        ColorPickerFrame.func = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            Config:Set("castbarColorR", newR)
            Config:Set("castbarColorG", newG)
            Config:Set("castbarColorB", newB)
            UpdateCastColorPreview()
            if ConsoleExperience.castbar and ConsoleExperience.castbar.UpdateColor then
                ConsoleExperience.castbar:UpdateColor()
            end
        end
        
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.hasOpacity = false
        
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            ColorPickerFrame:Show()
        end)
        delayFrame:Show()
    end)
    
    -- Channel color picker
    local channelColorLabel = castBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    channelColorLabel:SetPoint("LEFT", castColorBtn, "RIGHT", 20, 0)
    channelColorLabel:SetText(T("Channel") .. ":")
    
    local channelColorBtn = CreateFrame("Button", self:GetNextElementName("ColorBtn"), castBox)
    channelColorBtn:SetWidth(40)
    channelColorBtn:SetHeight(20)
    channelColorBtn:SetPoint("LEFT", channelColorLabel, "RIGHT", 5, 0)
    channelColorBtn.label = T("Channel Color")
    channelColorBtn.tooltipText = T("Click to choose the color for channeling spells (bandages, etc).")
    
    local channelColorPreview = channelColorBtn:CreateTexture(nil, "BACKGROUND")
    channelColorPreview:SetAllPoints()
    
    local function UpdateChannelColorPreview()
        local r = Config:Get("castbarChannelColorR") or 1.0
        local g = Config:Get("castbarChannelColorG") or 0.75
        local b = Config:Get("castbarChannelColorB") or 0.25
        channelColorPreview:SetTexture(r, g, b)
    end
    UpdateChannelColorPreview()
    
    channelColorBtn:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    channelColorBtn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    channelColorBtn:SetScript("OnClick", function()
        local r = Config:Get("castbarChannelColorR") or 1.0
        local g = Config:Get("castbarChannelColorG") or 0.75
        local b = Config:Get("castbarChannelColorB") or 0.25
        
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ColorPickerFrame:SetFrameLevel(2000)
        
        if ColorPickerOkayButton then
            ColorPickerOkayButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerOkayButton:SetFrameLevel(2001)
        end
        if ColorPickerCancelButton then
            ColorPickerCancelButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerCancelButton:SetFrameLevel(2001)
        end
        
        ColorPickerFrame.func = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            Config:Set("castbarChannelColorR", newR)
            Config:Set("castbarChannelColorG", newG)
            Config:Set("castbarChannelColorB", newB)
            UpdateChannelColorPreview()
        end
        
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.hasOpacity = false
        
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            ColorPickerFrame:Show()
        end)
        delayFrame:Show()
    end)
    
    self.contentSections["bars"] = section
end

function Config:CreateBindingsSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    
    -- ==================== System Bindings Box ====================
    local bindingsBox = self:CreateSectionBox(section, T("System Bindings"))
    bindingsBox:SetPoint("TOP", section, "TOP", 0, -25)
    bindingsBox:SetHeight(400)
    bindingsBox.heightCalculated = true
    
    -- Description text
    local descText = bindingsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descText:SetPoint("TOPLEFT", bindingsBox, "TOPLEFT", bindingsBox.contentLeft, bindingsBox.contentTop)
    descText:SetPoint("TOPRIGHT", bindingsBox, "TOPRIGHT", bindingsBox.contentRight, bindingsBox.contentTop)
    descText:SetJustifyH("LEFT")
    descText:SetText(T("Assign controller buttons to system actions instead of action bar slots."))
    descText:SetTextColor(0.7, 0.7, 0.7)
    
    -- Create scroll frame for bindings list
    local scrollFrame = CreateFrame("ScrollFrame", "CEBindingsScrollFrame", bindingsBox, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", descText, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", bindingsBox, "BOTTOMRIGHT", -30, 15)
    
    -- Create scroll child for content
    local scrollChild = CreateFrame("Frame", "CEBindingsScrollChild", scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 20)
    scrollChild:SetHeight(1)  -- Will be adjusted
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Storage for dropdown frames and icon textures for refresh
    self.bindingDropdowns = {}
    self.bindingIcons = {}
    
    -- Button icon names (matches controller texture files)
    local buttonIcons = { "a", "x", "y", "b", "down", "left", "up", "right", "rb", "lb" }
    -- Modifier icon names
    local modifierIcons = {
        [1] = {},           -- No modifier
        [2] = {"lt"},       -- LT (Shift)
        [3] = {"rt"},       -- RT (Ctrl)
        [4] = {"lt", "rt"}, -- LT+RT (Ctrl+Shift)
    }
    
    -- Helper to get controller icon path
    local function GetIconPath(iconName)
        local controllerType = "xbox"
        if Config.Get then
            controllerType = Config:Get("controllerType") or "xbox"
        elseif ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.controllerType then
            controllerType = ConsoleExperienceDB.config.controllerType
        end
        
        -- D-pad icons are shared, controller-specific icons are in controllers/<type>/
        local dPadIcons = {down = true, left = true, right = true, up = true}
        if dPadIcons[iconName] then
            return "Interface\\AddOns\\ConsoleExperienceClassic\\textures\\controllers\\" .. iconName
        else
            return "Interface\\AddOns\\ConsoleExperienceClassic\\textures\\controllers\\" .. controllerType .. "\\" .. iconName
        end
    end
    
    local ICON_SIZE = 16
    
    -- Create binding rows for all 40 slots
    local rowHeight = 28
    local currentY = 0
    
    -- Group by page (modifier)
    for page = 1, 4 do
        -- Page header with modifier icons
        local pageHeaderFrame = CreateFrame("Frame", "CEBindingPageHeader" .. page, scrollChild)
        pageHeaderFrame:SetWidth(scrollChild:GetWidth())
        pageHeaderFrame:SetHeight(20)
        pageHeaderFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
        
        -- Create modifier icons for page header
        local headerIconX = 10
        local pageModIcons = modifierIcons[page]
        pageHeaderFrame.icons = {}
        
        if table.getn(pageModIcons) > 0 then
            for i, iconName in ipairs(pageModIcons) do
                local modIcon = pageHeaderFrame:CreateTexture(nil, "OVERLAY")
                modIcon:SetWidth(ICON_SIZE)
                modIcon:SetHeight(ICON_SIZE)
                modIcon:SetTexture(GetIconPath(iconName))
                modIcon:SetPoint("LEFT", pageHeaderFrame, "LEFT", headerIconX, 0)
                table.insert(pageHeaderFrame.icons, {texture = modIcon, iconName = iconName})
                headerIconX = headerIconX + ICON_SIZE + 2
            end
            
            -- Add " + " text after modifier icons
            local plusText = pageHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            plusText:SetPoint("LEFT", pageHeaderFrame, "LEFT", headerIconX, 0)
            plusText:SetText("...")
            plusText:SetTextColor(1, 0.82, 0)
        else
            -- No modifier - show "No Modifier" text
            local noModText = pageHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            noModText:SetPoint("LEFT", pageHeaderFrame, "LEFT", headerIconX, 0)
            noModText:SetText("-- " .. T("No Modifier") .. " --")
            noModText:SetTextColor(1, 0.82, 0)
        end
        
        -- Store for refresh
        if not self.bindingIcons.pageHeaders then
            self.bindingIcons.pageHeaders = {}
        end
        self.bindingIcons.pageHeaders[page] = pageHeaderFrame
        
        currentY = currentY + 20
        
        -- Buttons in this page
        for btn = 1, 10 do
            local slot = ((page - 1) * 10) + btn
            local iconName = buttonIcons[btn]
            
            -- Create row
            local rowFrame = CreateFrame("Frame", "CEBindingRow" .. slot, scrollChild)
            rowFrame:SetWidth(scrollChild:GetWidth())
            rowFrame:SetHeight(rowHeight)
            rowFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
            rowFrame.icons = {}
            
            -- Create icon container for button label
            local iconX = 10
            
            -- Add modifier icons first
            local mods = modifierIcons[page]
            for i, modIconName in ipairs(mods) do
                local modIcon = rowFrame:CreateTexture(nil, "OVERLAY")
                modIcon:SetWidth(ICON_SIZE)
                modIcon:SetHeight(ICON_SIZE)
                modIcon:SetTexture(GetIconPath(modIconName))
                modIcon:SetPoint("LEFT", rowFrame, "LEFT", iconX, 0)
                table.insert(rowFrame.icons, {texture = modIcon, iconName = modIconName})
                iconX = iconX + ICON_SIZE + 2
            end
            
            -- Add main button icon
            local mainIcon = rowFrame:CreateTexture(nil, "OVERLAY")
            mainIcon:SetWidth(ICON_SIZE)
            mainIcon:SetHeight(ICON_SIZE)
            mainIcon:SetTexture(GetIconPath(iconName))
            mainIcon:SetPoint("LEFT", rowFrame, "LEFT", iconX, 0)
            table.insert(rowFrame.icons, {texture = mainIcon, iconName = iconName})
            iconX = iconX + ICON_SIZE + 10
            
            -- Store row for icon refresh
            if not self.bindingIcons.rows then
                self.bindingIcons.rows = {}
            end
            self.bindingIcons.rows[slot] = rowFrame
            
            -- Dropdown for action selection (positioned after icons)
            local dropdownName = "CEBindingDropdown" .. slot
            local dropdown = CreateFrame("Frame", dropdownName, rowFrame, "UIDropDownMenuTemplate")
            dropdown:SetPoint("LEFT", rowFrame, "LEFT", iconX, -3)
            dropdown.slot = slot
            
            -- Capture slot value for closure (WoW 1.12 closure fix)
            local capturedSlot = slot
            local capturedDropdown = dropdown
            
            -- Initialize dropdown
            local function InitializeBindingDropdown()
                local currentValue = nil
                if ConsoleExperience.proxied and ConsoleExperience.proxied.GetSlotBinding then
                    currentValue = ConsoleExperience.proxied:GetSlotBinding(capturedSlot)
                end
                
                -- None option
                local info = {}
                info.text = T("None (Action Bar)")
                info.value = nil
                info.func = function()
                    if ConsoleExperience.proxied and ConsoleExperience.proxied.SetSlotBinding then
                        ConsoleExperience.proxied:SetSlotBinding(capturedSlot, nil)
                    end
                    UIDropDownMenu_SetSelectedValue(capturedDropdown, nil)
                    UIDropDownMenu_SetText(T("None (Action Bar)"), capturedDropdown)
                end
                if currentValue == nil then
                    info.checked = 1
                end
                UIDropDownMenu_AddButton(info)
                
                -- Add all proxied actions
                if ConsoleExperience.proxied and ConsoleExperience.proxied.ACTIONS then
                    for _, action in ipairs(ConsoleExperience.proxied.ACTIONS) do
                        if action.headerKey then
                            -- Header (disabled)
                            info = {}
                            info.text = "-- " .. ConsoleExperience.proxied:GetHeaderName(action) .. " --"
                            info.disabled = true
                            info.notCheckable = true
                            UIDropDownMenu_AddButton(info)
                        elseif action.nameKey then
                            -- Action item - capture action values for closure
                            local actionId = action.id
                            local actionName = ConsoleExperience.proxied:GetActionName(action)
                            info = {}
                            info.text = actionName
                            info.value = actionId
                            info.func = function()
                                if ConsoleExperience.proxied and ConsoleExperience.proxied.SetSlotBinding then
                                    ConsoleExperience.proxied:SetSlotBinding(capturedSlot, actionId)
                                end
                                UIDropDownMenu_SetSelectedValue(capturedDropdown, actionId)
                                UIDropDownMenu_SetText(actionName, capturedDropdown)
                            end
                            if currentValue == actionId then
                                info.checked = 1
                            end
                            UIDropDownMenu_AddButton(info)
                        end
                    end
                end
            end
            
            UIDropDownMenu_Initialize(dropdown, InitializeBindingDropdown)
            UIDropDownMenu_SetWidth(180, dropdown)
            
            -- Set initial text
            local currentValue = nil
            if ConsoleExperience.proxied and ConsoleExperience.proxied.GetSlotBinding then
                currentValue = ConsoleExperience.proxied:GetSlotBinding(slot)
            end
            
            if currentValue then
                local action = ConsoleExperience.proxied:GetActionByID(currentValue)
                if action then
                    UIDropDownMenu_SetText(action.name, dropdown)
                else
                    UIDropDownMenu_SetText(currentValue, dropdown)
                end
            else
                UIDropDownMenu_SetText(T("None (Action Bar)"), dropdown)
            end
            
            self.bindingDropdowns[slot] = dropdown
            currentY = currentY + rowHeight
        end
        
        -- Add spacing between pages
        currentY = currentY + 10
    end
    
    -- ==================== Sidebar Bindings ====================
    -- Add sidebar binding options (slots 41-50)
    
    -- Left Sidebar Header
    local leftSidebarHeader = CreateFrame("Frame", "CEBindingSidebarLeftHeader", scrollChild)
    leftSidebarHeader:SetWidth(scrollChild:GetWidth())
    leftSidebarHeader:SetHeight(20)
    leftSidebarHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
    
    local leftSidebarText = leftSidebarHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leftSidebarText:SetPoint("LEFT", leftSidebarHeader, "LEFT", 10, 0)
    leftSidebarText:SetText("-- " .. T("Left Sidebar") .. " --")
    leftSidebarText:SetTextColor(1, 0.82, 0)
    
    -- Store for visibility toggle and dynamic repositioning
    self.sidebarBindingFrames = self.sidebarBindingFrames or {}
    self.sidebarBindingFrames.leftHeader = leftSidebarHeader
    self.sidebarBindingFrames.leftRows = {}
    self.sidebarBindingFrames.scrollChild = scrollChild
    self.sidebarBindingFrames.scrollFrame = scrollFrame
    self.sidebarBindingFrames.rowHeight = rowHeight
    self.sidebarBindingFrames.headerHeight = 20
    self.sidebarBindingFrames.spacing = 10
    
    currentY = currentY + 20
    
    -- Left sidebar buttons (slots 41-45)
    for i = 1, 5 do
        local slot = 40 + i
        
        local rowFrame = CreateFrame("Frame", "CEBindingRow" .. slot, scrollChild)
        rowFrame:SetWidth(scrollChild:GetWidth())
        rowFrame:SetHeight(rowHeight)
        rowFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
        
        -- Button label
        local buttonLabel = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        buttonLabel:SetPoint("LEFT", rowFrame, "LEFT", 10, 0)
        buttonLabel:SetText(T("Left") .. " " .. i)
        buttonLabel:SetTextColor(1, 1, 1)
        
        -- Dropdown for action selection
        local dropdownName = "CEBindingDropdown" .. slot
        local dropdown = CreateFrame("Frame", dropdownName, rowFrame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", rowFrame, "LEFT", 80, -3)
        dropdown.slot = slot
        
        -- Capture slot value for closure
        local capturedSlot = slot
        local capturedDropdown = dropdown
        
        -- Initialize dropdown
        local function InitializeSidebarBindingDropdown()
            local currentValue = nil
            if ConsoleExperience.proxied and ConsoleExperience.proxied.GetSlotBinding then
                currentValue = ConsoleExperience.proxied:GetSlotBinding(capturedSlot)
            end
            
            -- None option
            local info = {}
            info.text = T("None (Action Bar)")
            info.value = nil
            info.func = function()
                if ConsoleExperience.proxied and ConsoleExperience.proxied.SetSlotBinding then
                    ConsoleExperience.proxied:SetSlotBinding(capturedSlot, nil)
                end
                UIDropDownMenu_SetSelectedValue(capturedDropdown, nil)
                UIDropDownMenu_SetText(T("None (Action Bar)"), capturedDropdown)
            end
            if currentValue == nil then
                info.checked = 1
            end
            UIDropDownMenu_AddButton(info)
            
            -- Add all proxied actions
            if ConsoleExperience.proxied and ConsoleExperience.proxied.ACTIONS then
                for _, action in ipairs(ConsoleExperience.proxied.ACTIONS) do
                    if action.headerKey then
                        info = {}
                        info.text = "-- " .. ConsoleExperience.proxied:GetHeaderName(action) .. " --"
                        info.disabled = true
                        info.notCheckable = true
                        UIDropDownMenu_AddButton(info)
                    elseif action.nameKey then
                        local actionId = action.id
                        local actionName = ConsoleExperience.proxied:GetActionName(action)
                        info = {}
                        info.text = actionName
                        info.value = actionId
                        info.func = function()
                            if ConsoleExperience.proxied and ConsoleExperience.proxied.SetSlotBinding then
                                ConsoleExperience.proxied:SetSlotBinding(capturedSlot, actionId)
                            end
                            UIDropDownMenu_SetSelectedValue(capturedDropdown, actionId)
                            UIDropDownMenu_SetText(actionName, capturedDropdown)
                        end
                        if currentValue == actionId then
                            info.checked = 1
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end
            end
        end
        
        UIDropDownMenu_Initialize(dropdown, InitializeSidebarBindingDropdown)
        UIDropDownMenu_SetWidth(180, dropdown)
        
        -- Set initial text
        local currentValue = nil
        if ConsoleExperience.proxied and ConsoleExperience.proxied.GetSlotBinding then
            currentValue = ConsoleExperience.proxied:GetSlotBinding(slot)
        end
        
        if currentValue then
            local action = ConsoleExperience.proxied:GetActionByID(currentValue)
            if action then
                UIDropDownMenu_SetText(action.name, dropdown)
            else
                UIDropDownMenu_SetText(currentValue, dropdown)
            end
        else
            UIDropDownMenu_SetText(T("None (Action Bar)"), dropdown)
        end
        
        self.bindingDropdowns[slot] = dropdown
        self.sidebarBindingFrames.leftRows[i] = rowFrame
        
        currentY = currentY + rowHeight
    end
    
    currentY = currentY + 10
    
    -- Right Sidebar Header
    local rightSidebarHeader = CreateFrame("Frame", "CEBindingSidebarRightHeader", scrollChild)
    rightSidebarHeader:SetWidth(scrollChild:GetWidth())
    rightSidebarHeader:SetHeight(20)
    rightSidebarHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
    
    local rightSidebarText = rightSidebarHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rightSidebarText:SetPoint("LEFT", rightSidebarHeader, "LEFT", 10, 0)
    rightSidebarText:SetText("-- " .. T("Right Sidebar") .. " --")
    rightSidebarText:SetTextColor(1, 0.82, 0)
    
    self.sidebarBindingFrames.rightHeader = rightSidebarHeader
    self.sidebarBindingFrames.rightRows = {}
    
    currentY = currentY + 20
    
    -- Right sidebar buttons (slots 46-50)
    for i = 1, 5 do
        local slot = 45 + i
        
        local rowFrame = CreateFrame("Frame", "CEBindingRow" .. slot, scrollChild)
        rowFrame:SetWidth(scrollChild:GetWidth())
        rowFrame:SetHeight(rowHeight)
        rowFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
        
        -- Button label
        local buttonLabel = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        buttonLabel:SetPoint("LEFT", rowFrame, "LEFT", 10, 0)
        buttonLabel:SetText(T("Right") .. " " .. i)
        buttonLabel:SetTextColor(1, 1, 1)
        
        -- Dropdown for action selection
        local dropdownName = "CEBindingDropdown" .. slot
        local dropdown = CreateFrame("Frame", dropdownName, rowFrame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", rowFrame, "LEFT", 80, -3)
        dropdown.slot = slot
        
        -- Capture slot value for closure
        local capturedSlot = slot
        local capturedDropdown = dropdown
        
        -- Initialize dropdown
        local function InitializeSidebarBindingDropdown()
            local currentValue = nil
            if ConsoleExperience.proxied and ConsoleExperience.proxied.GetSlotBinding then
                currentValue = ConsoleExperience.proxied:GetSlotBinding(capturedSlot)
            end
            
            -- None option
            local info = {}
            info.text = T("None (Action Bar)")
            info.value = nil
            info.func = function()
                if ConsoleExperience.proxied and ConsoleExperience.proxied.SetSlotBinding then
                    ConsoleExperience.proxied:SetSlotBinding(capturedSlot, nil)
                end
                UIDropDownMenu_SetSelectedValue(capturedDropdown, nil)
                UIDropDownMenu_SetText(T("None (Action Bar)"), capturedDropdown)
            end
            if currentValue == nil then
                info.checked = 1
            end
            UIDropDownMenu_AddButton(info)
            
            -- Add all proxied actions
            if ConsoleExperience.proxied and ConsoleExperience.proxied.ACTIONS then
                for _, action in ipairs(ConsoleExperience.proxied.ACTIONS) do
                    if action.headerKey then
                        info = {}
                        info.text = "-- " .. ConsoleExperience.proxied:GetHeaderName(action) .. " --"
                        info.disabled = true
                        info.notCheckable = true
                        UIDropDownMenu_AddButton(info)
                    elseif action.nameKey then
                        local actionId = action.id
                        local actionName = ConsoleExperience.proxied:GetActionName(action)
                        info = {}
                        info.text = actionName
                        info.value = actionId
                        info.func = function()
                            if ConsoleExperience.proxied and ConsoleExperience.proxied.SetSlotBinding then
                                ConsoleExperience.proxied:SetSlotBinding(capturedSlot, actionId)
                            end
                            UIDropDownMenu_SetSelectedValue(capturedDropdown, actionId)
                            UIDropDownMenu_SetText(actionName, capturedDropdown)
                        end
                        if currentValue == actionId then
                            info.checked = 1
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end
            end
        end
        
        UIDropDownMenu_Initialize(dropdown, InitializeSidebarBindingDropdown)
        UIDropDownMenu_SetWidth(180, dropdown)
        
        -- Set initial text
        local currentValue = nil
        if ConsoleExperience.proxied and ConsoleExperience.proxied.GetSlotBinding then
            currentValue = ConsoleExperience.proxied:GetSlotBinding(slot)
        end
        
        if currentValue then
            local action = ConsoleExperience.proxied:GetActionByID(currentValue)
            if action then
                UIDropDownMenu_SetText(action.name, dropdown)
            else
                UIDropDownMenu_SetText(currentValue, dropdown)
            end
        else
            UIDropDownMenu_SetText(T("None (Action Bar)"), dropdown)
        end
        
        self.bindingDropdowns[slot] = dropdown
        self.sidebarBindingFrames.rightRows[i] = rowFrame
        
        currentY = currentY + rowHeight
    end
    
    -- Set scroll child height (add scroll frame height so last items can scroll to top)
    local scrollFrameHeight = scrollFrame:GetHeight()
    scrollChild:SetHeight(currentY + 20 + scrollFrameHeight)

    -- Update sidebar binding visibility based on config
    self:UpdateSidebarBindingVisibility()
    
    -- Ensure dropdown buttons are navigable
    local bindingsDelayFrame = CreateFrame("Frame")
    bindingsDelayFrame:SetScript("OnUpdate", function()
        bindingsDelayFrame:Hide()
        -- Main action bar dropdowns
        for slot = 1, 40 do
            local dropdownButton = getglobal("CEBindingDropdown" .. slot .. "Button")
            if dropdownButton then
                dropdownButton:Enable()
                dropdownButton:Show()
            end
        end
        -- Sidebar dropdowns
        for slot = 41, 50 do
            local dropdownButton = getglobal("CEBindingDropdown" .. slot .. "Button")
            if dropdownButton then
                dropdownButton:Enable()
                dropdownButton:Show()
            end
        end
        if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
            ConsoleExperience.cursor:RefreshFrame()
        end
    end)
    bindingsDelayFrame:Show()
    
    -- ==================== Actions Box ====================
    local actionsBox = self:CreateSectionBox(section, T("Actions"))
    actionsBox:SetPoint("TOP", bindingsBox, "BOTTOM", 0, -30)
    
    -- Reset Default Bindings button (left)
    local resetBindingsButton = CreateFrame("Button", "CEConfigResetBindings", actionsBox, "UIPanelButtonTemplate")
    resetBindingsButton:SetWidth(160)
    resetBindingsButton:SetHeight(24)
    resetBindingsButton:SetPoint("TOPLEFT", actionsBox, "TOPLEFT", actionsBox.contentLeft, actionsBox.contentTop)
    resetBindingsButton:SetText(T("Reset Bindings"))
    resetBindingsButton.label = T("Reset Default Bindings")
    resetBindingsButton.tooltipText = T("Resets all keybindings to default (1-0 keys).")
    resetBindingsButton:SetScript("OnClick", function()
        -- Reset keybindings
        ConsoleExperienceKeybindings:ResetAllBindings()
        
        -- Update action bar display
        if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
            ConsoleExperience.actionbars:UpdateAllButtons()
        end
        
        CE_Debug("Default bindings have been reset!")
    end)
    
    -- Show Placement Frame button (right, same row as reset button)
    local showPlacementButton = CreateFrame("Button", "CEConfigShowPlacement", actionsBox, "UIPanelButtonTemplate")
    showPlacementButton:SetWidth(160)
    showPlacementButton:SetHeight(24)
    showPlacementButton:SetPoint("TOP", resetBindingsButton, "TOP", 0, 0)
    showPlacementButton:SetPoint("RIGHT", actionsBox, "RIGHT", actionsBox.contentRight, 0)
    showPlacementButton:SetText(T("Spell Placement"))
    showPlacementButton.label = T("Show Placement Frame")
    showPlacementButton.tooltipText = T("Opens the spell placement frame where you can drag and drop spells and items onto action bar slots.")
    showPlacementButton:SetScript("OnClick", function()
        if ConsoleExperience.placement then
            -- Show placement frame and close config frame
            ConsoleExperience.placement:Show()
            Config:Hide()
        else
            CE_Debug("Placement module not loaded!")
        end
    end)
    
    self.contentSections["bindings"] = section
end

function Config:CreateProfilesSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    -- Main section container
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    
    -- ==================== Current Profile Box ====================
    local currentBox = self:CreateSectionBox(section, T("Current Profile"))
    currentBox:SetPoint("TOP", section, "TOP", 0, -25)
    
    -- Profile selector dropdown
    local profileLabel = currentBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    profileLabel:SetPoint("TOPLEFT", currentBox, "TOPLEFT", currentBox.contentLeft, currentBox.contentTop)
    profileLabel:SetText(T("Active Profile") .. ":")
    
    local profileDropdown = CreateFrame("Frame", "CEConfigProfileDropdown", currentBox, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("LEFT", profileLabel, "RIGHT", -15, -3)
    
    -- Function to refresh profile dropdown
    local function RefreshProfileDropdown()
        local selectedValue = ConsoleExperience.profiles:GetCurrentProfileName()
        local info
        
        -- Clear existing menu
        UIDropDownMenu_Initialize(profileDropdown, function()
            local profiles = ConsoleExperience.profiles:ListProfiles()
            for _, profileName in ipairs(profiles) do
                info = {}
                info.text = profileName
                info.value = profileName
                info.func = function()
                    -- Save current profile before switching
                    ConsoleExperience.profiles:SaveCurrentProfile()
                    -- Switch to selected profile
                    ConsoleExperience.profiles:SetProfile(this.value)
                    -- Refresh dropdown
                    RefreshProfileDropdown()
                    -- Update delete button state
                    if Config.UpdateDeleteButtonState then
                        Config:UpdateDeleteButtonState()
                    end
                    -- Update UI to reflect new profile
                    if ConsoleExperience.config and ConsoleExperience.config.frame then
                        ConsoleExperience.config:ShowSection("profiles")
                    end
                end
                if profileName == selectedValue then
                    info.checked = 1
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        UIDropDownMenu_SetWidth(200, profileDropdown)
        UIDropDownMenu_SetSelectedValue(profileDropdown, selectedValue)
        UIDropDownMenu_SetText(selectedValue, profileDropdown)
    end
    
    RefreshProfileDropdown()
    self.profileDropdown = profileDropdown
    self.RefreshProfileDropdown = RefreshProfileDropdown
    
    -- ==================== Profile Management Box ====================
    local managementBox = self:CreateSectionBox(section, T("Profile Management"))
    managementBox:SetPoint("TOP", currentBox, "BOTTOM", 0, -20)
    
    -- Create New Profile button
    local createButton = CreateFrame("Button", "CEConfigCreateProfile", managementBox, "UIPanelButtonTemplate")
    createButton:SetWidth(140)
    createButton:SetHeight(24)
    createButton:SetPoint("TOPLEFT", managementBox, "TOPLEFT", managementBox.contentLeft, managementBox.contentTop)
    createButton:SetText(T("Create New"))
    createButton:SetScript("OnClick", function()
        -- Show input dialog
        StaticPopup_Show("CE_CREATE_PROFILE")
    end)
    
    -- Clone Current Profile button
    local cloneButton = CreateFrame("Button", "CEConfigCloneProfile", managementBox, "UIPanelButtonTemplate")
    cloneButton:SetWidth(140)
    cloneButton:SetHeight(24)
    cloneButton:SetPoint("LEFT", createButton, "RIGHT", 35, 0)
    cloneButton:SetText(T("Clone Current"))
    cloneButton:SetScript("OnClick", function()
        -- Show input dialog
        StaticPopup_Show("CE_CLONE_PROFILE")
    end)
    
    -- Delete Profile button
    local deleteButton = CreateFrame("Button", "CEConfigDeleteProfile", managementBox, "UIPanelButtonTemplate")
    deleteButton:SetWidth(140)
    deleteButton:SetHeight(24)
    deleteButton:SetPoint("LEFT", cloneButton, "RIGHT", 35, 0)
    deleteButton:SetText(T("Delete"))
    
    -- Function to update delete button state
    local function UpdateDeleteButtonState()
        local currentProfile = ConsoleExperience.profiles:GetCurrentProfileName()
        if currentProfile == ConsoleExperience.profiles.DEFAULT_PROFILE_NAME then
            deleteButton:Disable()
            deleteButton:SetAlpha(0.5)
        else
            deleteButton:Enable()
            deleteButton:SetAlpha(1.0)
        end
    end
    
    deleteButton:SetScript("OnClick", function()
        local currentProfile = ConsoleExperience.profiles:GetCurrentProfileName()
        if currentProfile == ConsoleExperience.profiles.DEFAULT_PROFILE_NAME then
            -- Can't delete default
            return
        end
        -- Show confirmation dialog with profile name
        local dialog = StaticPopup_Show("CE_DELETE_PROFILE", currentProfile)
        if dialog then
            dialog.data = currentProfile
        end
    end)
    
    -- Update state initially
    UpdateDeleteButtonState()
    
    -- Store update function for refresh
    self.UpdateDeleteButtonState = UpdateDeleteButtonState
    
    -- Store references for refresh
    self.profileListScrollFrame = scrollFrame
    
    self.contentSections["profiles"] = section
end

-- Update sidebar binding visibility based on sidebar enabled state and button count
function Config:UpdateSidebarBindingVisibility()
    if not self.sidebarBindingFrames then return end
    
    local leftEnabled = self:Get("sideBarLeftEnabled")
    local rightEnabled = self:Get("sideBarRightEnabled")
    local leftCount = self:Get("sideBarLeftButtons") or 3
    local rightCount = self:Get("sideBarRightButtons") or 3
    
    -- Clamp counts
    if leftCount < 1 then leftCount = 1 end
    if leftCount > 5 then leftCount = 5 end
    if rightCount < 1 then rightCount = 1 end
    if rightCount > 5 then rightCount = 5 end
    
    local scrollChild = self.sidebarBindingFrames.scrollChild
    local scrollFrame = self.sidebarBindingFrames.scrollFrame
    if not scrollChild then return end
    
    local rowHeight = self.sidebarBindingFrames.rowHeight or 28
    local headerHeight = self.sidebarBindingFrames.headerHeight or 20
    local spacing = self.sidebarBindingFrames.spacing or 10
    
    -- Calculate base Y from main action bar bindings
    -- 4 pages × (header 20px + 10 rows × 28px + spacing 10px) = 4 × 310 = 1240
    local mainBarHeight = 4 * (headerHeight + (10 * rowHeight) + spacing)
    local currentY = mainBarHeight
    
    -- Update left sidebar visibility and position
    if self.sidebarBindingFrames.leftHeader then
        if leftEnabled then
            self.sidebarBindingFrames.leftHeader:ClearAllPoints()
            self.sidebarBindingFrames.leftHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
            self.sidebarBindingFrames.leftHeader:Show()
            currentY = currentY + headerHeight
        else
            self.sidebarBindingFrames.leftHeader:Hide()
        end
    end
    
    if self.sidebarBindingFrames.leftRows then
        for i, rowFrame in ipairs(self.sidebarBindingFrames.leftRows) do
            if leftEnabled and i <= leftCount then
                rowFrame:ClearAllPoints()
                rowFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
                rowFrame:Show()
                currentY = currentY + rowHeight
            else
                rowFrame:Hide()
            end
        end
    end
    
    -- Add spacing between left and right if left is enabled
    if leftEnabled then
        currentY = currentY + spacing
    end
    
    -- Update right sidebar visibility and position
    if self.sidebarBindingFrames.rightHeader then
        if rightEnabled then
            self.sidebarBindingFrames.rightHeader:ClearAllPoints()
            self.sidebarBindingFrames.rightHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
            self.sidebarBindingFrames.rightHeader:Show()
            currentY = currentY + headerHeight
        else
            self.sidebarBindingFrames.rightHeader:Hide()
        end
    end
    
    if self.sidebarBindingFrames.rightRows then
        for i, rowFrame in ipairs(self.sidebarBindingFrames.rightRows) do
            if rightEnabled and i <= rightCount then
                rowFrame:ClearAllPoints()
                rowFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -currentY)
                rowFrame:Show()
                currentY = currentY + rowHeight
            else
                rowFrame:Hide()
            end
        end
    end
    
    -- Update scroll child height to fit all visible content
    -- Add scroll frame height so last items can scroll to top for dropdown visibility
    if scrollFrame then
        local scrollFrameHeight = scrollFrame:GetHeight()
        local newHeight = currentY + 20 + scrollFrameHeight
        scrollChild:SetHeight(newHeight)

        -- Update scroll frame's scroll bar range
        local scrollBar = getglobal(scrollFrame:GetName() .. "ScrollBar")
        if scrollBar then
            -- maxScroll = total content height (without the extra padding)
            local maxScroll = currentY + 20
            if maxScroll < 0 then maxScroll = 0 end
            scrollBar:SetMinMaxValues(0, maxScroll)
        end
    end
end

-- Refresh binding icons when controller type changes
function Config:RefreshBindingIcons()
    if not self.bindingIcons then return end
    
    -- Helper to get controller icon path
    local function GetIconPath(iconName)
        local controllerType = "xbox"
        if self.Get then
            controllerType = self:Get("controllerType") or "xbox"
        elseif ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.controllerType then
            controllerType = ConsoleExperienceDB.config.controllerType
        end
        
        local dPadIcons = {down = true, left = true, right = true, up = true}
        if dPadIcons[iconName] then
            return "Interface\\AddOns\\ConsoleExperienceClassic\\textures\\controllers\\" .. iconName
        else
            return "Interface\\AddOns\\ConsoleExperienceClassic\\textures\\controllers\\" .. controllerType .. "\\" .. iconName
        end
    end
    
    -- Refresh page header icons
    if self.bindingIcons.pageHeaders then
        for page, headerFrame in pairs(self.bindingIcons.pageHeaders) do
            if headerFrame.icons then
                for _, iconInfo in ipairs(headerFrame.icons) do
                    iconInfo.texture:SetTexture(GetIconPath(iconInfo.iconName))
                end
            end
        end
    end
    
    -- Refresh row icons
    if self.bindingIcons.rows then
        for slot, rowFrame in pairs(self.bindingIcons.rows) do
            if rowFrame.icons then
                for _, iconInfo in ipairs(rowFrame.icons) do
                    iconInfo.texture:SetTexture(GetIconPath(iconInfo.iconName))
                end
            end
        end
    end
end

-- Refresh proxied action dropdowns to reflect current proxied action bindings
function Config:RefreshProxiedDropdowns()
    if not self.bindingDropdowns then return end
    if not ConsoleExperience.proxied then return end
    
    -- Get translation function
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    -- Refresh all dropdowns (main action bar and sidebars)
    for slot, dropdown in pairs(self.bindingDropdowns) do
        if dropdown then
            -- Get current binding for this slot
            local currentValue = nil
            if ConsoleExperience.proxied.GetSlotBinding then
                currentValue = ConsoleExperience.proxied:GetSlotBinding(slot)
            end
            
            -- Update dropdown text and selected value
            if currentValue then
                local action = ConsoleExperience.proxied:GetActionByID(currentValue)
                if action then
                    local actionName = ConsoleExperience.proxied:GetActionName(action)
                    UIDropDownMenu_SetText(actionName, dropdown)
                    UIDropDownMenu_SetSelectedValue(dropdown, currentValue)
                else
                    UIDropDownMenu_SetText(currentValue, dropdown)
                    UIDropDownMenu_SetSelectedValue(dropdown, currentValue)
                end
            else
                UIDropDownMenu_SetText(T("None (Action Bar)"), dropdown)
                UIDropDownMenu_SetSelectedValue(dropdown, nil)
            end
        end
    end
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

-- Create a section box with title (like UIOptionsFrame's OptionFrameBoxTemplate)
-- If height is nil, call box:CalculateHeight() after adding all children
function Config:CreateSectionBox(parent, title, height)
    local name = self:GetNextElementName("Section")
    local box = CreateFrame("Frame", name, parent)
    box:SetHeight(height or 50)  -- Initial height, will be recalculated if needed
    
    -- Use anchor points for full width (5px padding on each side)
    box:SetPoint("LEFT", parent, "LEFT", 5, 0)
    box:SetPoint("RIGHT", parent, "RIGHT", -5, 0)
    
    -- Backdrop (like OptionFrameBoxTemplate)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    box:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
    
    -- Title (positioned ABOVE the box, not overlapping the border)
    local titleText = parent:CreateFontString(name .. "Title", "OVERLAY", "GameFontNormal")
    titleText:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 5, 2)
    titleText:SetText(title)
    titleText:SetTextColor(1, 1, 1, 1)  -- White text
    box.title = titleText
    
    -- Content inset (area inside the box for controls)
    box.contentTop = -18  -- Y offset from box top for content (more padding)
    box.contentLeft = 15  -- X offset from box left for content
    box.contentRight = -15  -- X offset from box right for content
    box.bottomPadding = 15  -- Padding at the bottom of the box
    
    -- Method to calculate height based on children (call after layout settles)
    -- Only calculates once to prevent growing on repeated calls
    box.CalculateHeight = function(self)
        -- Only calculate once
        if self.heightCalculated then return end
        
        local boxTop = self:GetTop()
        if not boxTop then return end
        
        local lowestPoint = boxTop  -- Start at top
        
        -- Scan all child frames
        local children = {self:GetChildren()}
        for _, child in ipairs(children) do
            local bottom = child:GetBottom()
            if bottom and bottom < lowestPoint then
                lowestPoint = bottom
            end
        end
        
        -- Also scan font strings (they're not frames)
        local regions = {self:GetRegions()}
        for _, region in ipairs(regions) do
            if region.GetBottom then
                local bottom = region:GetBottom()
                if bottom and bottom < lowestPoint then
                    lowestPoint = bottom
                end
            end
        end
        
        -- Calculate needed height
        local neededHeight = (boxTop - lowestPoint) + self.bottomPadding
        if neededHeight < 40 then neededHeight = 40 end  -- Minimum height
        
        self:SetHeight(neededHeight)
        self.heightCalculated = true
    end
    
    return box
end

function Config:CreateCheckbox(parent, label, getFunc, setFunc, tooltipText)
    local name = self:GetNextElementName("Check")
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    
    local text = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", check, "RIGHT", 5, 0)
    text:SetText(label)
    
    -- Store label for tooltip/debug
    check.label = label
    -- Store tooltip help text
    check.tooltipText = tooltipText
    -- Store getFunc so we can refresh the checkbox state
    check.getFunc = getFunc
    
    -- Set initial state
    check:SetChecked(getFunc() and 1 or 0)
    
    -- Click handler
    check:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        setFunc(checked)
    end)
    
    return check
end

-- Refresh all checkboxes in a section
function Config:RefreshCheckboxes(section)
    if not section then return end
    
    -- Find all checkboxes in the section
    local function RefreshCheckboxRecursive(frame)
        if frame and frame.getFunc then
            -- This is a checkbox with a getFunc, refresh it
            local value = frame.getFunc()
            frame:SetChecked(value and 1 or 0)
        end
        
        -- Recursively check children
        local children = {frame:GetChildren()}
        for _, child in ipairs(children) do
            RefreshCheckboxRecursive(child)
        end
    end
    
    RefreshCheckboxRecursive(section)
end

function Config:CreateEditBox(parent, width, getFunc, setFunc, label, tooltipText)
    local name = self:GetNextElementName("Edit")
    local editBox = CreateFrame("EditBox", name, parent)
    editBox:SetWidth(width)
    editBox:SetHeight(20)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetJustifyH("CENTER")
    
	-- initial value
    editBox:SetText(getFunc() or "0")
	
    --  Create an increase button (Up)
    local btnUp = CreateFrame("Button", name.."Up", editBox)
    btnUp:SetWidth(18)
    btnUp:SetHeight(10)
    btnUp:SetPoint("TOPLEFT", editBox, "TOPRIGHT", -1, 0)
    
    -- Use the built-in up arrow texture in the system
    local upTex = btnUp:CreateTexture(nil, "ARTWORK")
    upTex:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    upTex:SetTexCoord(0.2, 0.8, 0.2, 0.8)
    upTex:SetAllPoints(btnUp)
    btnUp:SetNormalTexture(upTex)
    
    btnUp:SetScript("OnClick", function()
        local val = tonumber(editBox:GetText()) or 0
        editBox:SetText(val + 1)
        -- Trigger the OnTextChanged logic of the EditBox to save data
        if editBox:GetScript("OnTextChanged") then
            -- In version 1.12, manually invoke script logic using this method
            local script = editBox:GetScript("OnTextChanged")
            arg1 = true -- Analog input
            script()
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)

     -- Create a decrease button (Down)
    local btnDown = CreateFrame("Button", name.."Down", editBox)
    btnDown:SetWidth(18)
    btnDown:SetHeight(10)
    btnDown:SetPoint("BOTTOMLEFT", editBox, "BOTTOMRIGHT", -1, 0)
    
    -- Use the built-in downward arrow image in the system
    local downTex = btnDown:CreateTexture(nil, "ARTWORK")
    downTex:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    downTex:SetTexCoord(0.2, 0.8, 0.2, 0.8)
    downTex:SetAllPoints(btnDown)
    btnDown:SetNormalTexture(downTex)
    
    btnDown:SetScript("OnClick", function()
        local val = tonumber(editBox:GetText()) or 0
        editBox:SetText(val - 1)
        -- Trigger the OnTextChanged logic of the EditBox
        if editBox:GetScript("OnTextChanged") then
            local script = editBox:GetScript("OnTextChanged")
            arg1 = true -- Analog input
            script()
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)
    -- end
    
    -- Store label and tooltip for cursor tooltip
    editBox.label = label or T("Text Input")
    editBox.tooltipText = tooltipText
    
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
    -- Refresh profile dropdown if showing profiles section
    if sectionId == "profiles" then
        if self.RefreshProfileDropdown then
            self:RefreshProfileDropdown()
        end
        if self.UpdateDeleteButtonState then
            self:UpdateDeleteButtonState()
        end
    end
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
        local section = self.contentSections[sectionId]
        section:Show()
        
        -- Refresh all checkboxes in this section to reflect current config values
        self:RefreshCheckboxes(section)
        
        -- Refresh proxied dropdowns if showing keybindings section
        if sectionId == "keybindings" then
            if self.RefreshProxiedDropdowns then
                self:RefreshProxiedDropdowns()
            end
        end
        
        -- Recalculate box heights after layout settles
        local calcFrame = CreateFrame("Frame")
        calcFrame.section = section
        calcFrame:SetScript("OnUpdate", function()
            this:Hide()
            local section = this.section
            -- Find all boxes in this section and recalculate their heights
            local children = {section:GetChildren()}
            for _, child in ipairs(children) do
                if child.CalculateHeight then
                    child:CalculateHeight()
                end
            end
        end)
        calcFrame:Show()
    end
    
    -- Highlight selected sidebar button
    if self.sidebarButtons[sectionId] then
        self.sidebarButtons[sectionId]:SetBackdropColor(0.4, 0.4, 0.6, 0.8)
    end
    
    self.currentSection = sectionId
    
    -- Refresh cursor navigation to detect dropdown buttons and other elements
    if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
                ConsoleExperience.cursor:RefreshFrame()
            end
        end)
        delayFrame:Show()
    end
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
    
    -- Refresh cursor navigation to include dropdown buttons
    if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
                ConsoleExperience.cursor:RefreshFrame()
            end
        end)
        delayFrame:Show()
    end
end

function Config:Hide()
    -- Save current profile before hiding
    if ConsoleExperience.profiles and ConsoleExperience.profiles.SaveCurrentProfile then
        ConsoleExperience.profiles:SaveCurrentProfile()
    end
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
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    button:SetText(T("Console Experience"))
    
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
    
    -- Apply pfUI styling if pfUI is loaded (will be applied later via ApplyPfUIStyling)
    
    -- Move buttons below us down
    if GameMenuButtonKeybindings then
        GameMenuButtonKeybindings:SetPoint("TOP", button, "BOTTOM", 0, -1)
    end
    
    -- Increase frame height
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 25)
end

-- Helper function to recursively find all buttons and dropdowns in a frame
local function FindAllButtonsAndDropdowns(parent, results)
    results = results or {}
    if not parent then return results end
    
    -- Check all children
    local children = {parent:GetChildren()}
    for _, child in ipairs(children) do
        local objType = child:GetObjectType()
        local name = child:GetName() or ""
        
        -- Check if it's a Frame with UIDropDownMenuTemplate (dropdowns are Frames, not Buttons)
        if objType == "Frame" then
            -- Check if it has a button child (indicating it's a dropdown)
            local buttonName = name .. "Button"
            local button = _G[buttonName]
            if button then
                -- This is a dropdown frame
                table.insert(results, {frame = child, type = "dropdown"})
            else
                -- Regular frame, check its children
                FindAllButtonsAndDropdowns(child, results)
            end
        elseif objType == "Button" then
            -- Regular button (not a dropdown)
            table.insert(results, {frame = child, type = "button"})
        elseif objType == "CheckButton" then
            -- Checkbox
            table.insert(results, {frame = child, type = "checkbox"})
        else
            -- Other frame types, check their children
            FindAllButtonsAndDropdowns(child, results)
        end
    end
    
    return results
end

-- Function to apply pfUI styling to config frame and buttons
function Config:ApplyPfUIStyling()
    if not pfUI or not pfUI.GetEnvironment then 
        CE_Debug("ApplyPfUIStyling: pfUI not found or GetEnvironment not available")
        return 
    end
    
    local frame = self.frame
    if not frame then 
        CE_Debug("ApplyPfUIStyling: frame not found")
        return 
    end
    
    -- Try to get pfUI environment functions
    local env = pfUI:GetEnvironment()
    if not env then 
        CE_Debug("ApplyPfUIStyling: Could not get pfUI environment")
        return 
    end
    
    CE_Debug("ApplyPfUIStyling: Got pfUI environment")
    
    -- Check if functions exist in environment
    local CreateBackdrop = env.CreateBackdrop
    local CreateBackdropShadow = env.CreateBackdropShadow
    local SkinButton = env.SkinButton
    
    CE_Debug("ApplyPfUIStyling: CreateBackdrop=" .. tostring(CreateBackdrop ~= nil) .. 
             ", CreateBackdropShadow=" .. tostring(CreateBackdropShadow ~= nil) .. 
             ", SkinButton=" .. tostring(SkinButton ~= nil))
    
    -- Apply pfUI styling to main frame if CreateBackdrop is available
    if CreateBackdrop then
        -- Remove default backdrop if it exists
        if frame.backdrop then
            frame.backdrop = nil
        end
        -- Call CreateBackdrop from pfUI's environment
        local success, err = pcall(function()
            CreateBackdrop(frame, nil, true, .75)
            if CreateBackdropShadow then
                CreateBackdropShadow(frame)
            end
        end)
        if success then
            CE_Debug("ApplyPfUIStyling: Successfully applied backdrop")
        else
            CE_Debug("ApplyPfUIStyling: Failed to apply backdrop: " .. tostring(err))
        end
    end
    
    -- Apply pfUI styling to all buttons and dropdowns
    local SkinDropDown = env.SkinDropDown
    local SkinCheckbox = env.SkinCheckbox
    if SkinButton or SkinDropDown or SkinCheckbox then
        local success, err = pcall(function()
            -- Find all buttons and dropdowns in the config frame
            local allElements = FindAllButtonsAndDropdowns(frame)
            local styledCount = 0
            
            for _, element in ipairs(allElements) do
                if element.frame and not element.frame.pfUISkinned then
                    if element.type == "dropdown" and SkinDropDown then
                        -- Use SkinDropDown for dropdowns (this styles the frame, button, text, and arrow)
                        SkinDropDown(element.frame)
                        element.frame.pfUISkinned = true
                        styledCount = styledCount + 1
                    elseif element.type == "checkbox" and SkinCheckbox then
                        -- Use SkinCheckbox for checkboxes (this properly styles the checkbox texture)
                        SkinCheckbox(element.frame)
                        element.frame.pfUISkinned = true
                        styledCount = styledCount + 1
                    elseif element.type == "button" and SkinButton then
                        -- Use SkinButton for regular buttons only
                        SkinButton(element.frame)
                        element.frame.pfUISkinned = true
                        styledCount = styledCount + 1
                    end
                end
            end
            
            -- Also style specific known buttons
            if frame.closeButton and not frame.closeButton.pfUISkinned and SkinButton then
                SkinButton(frame.closeButton)
                frame.closeButton.pfUISkinned = true
                styledCount = styledCount + 1
            end
            if frame.debugButton and not frame.debugButton.pfUISkinned and SkinButton then
                SkinButton(frame.debugButton)
                frame.debugButton.pfUISkinned = true
                styledCount = styledCount + 1
            end
            
            -- Style sidebar buttons
            if self.sidebarButtons and SkinButton then
                for _, button in pairs(self.sidebarButtons) do
                    if button and not button.pfUISkinned then
                        SkinButton(button)
                        button.pfUISkinned = true
                        styledCount = styledCount + 1
                    end
                end
            end
            
            CE_Debug("ApplyPfUIStyling: Styled " .. styledCount .. " buttons/dropdowns")
        end)
        if success then
            CE_Debug("ApplyPfUIStyling: Successfully applied button styling")
        else
            CE_Debug("ApplyPfUIStyling: Failed to apply button styling: " .. tostring(err))
        end
    end
    
    -- Apply pfUI font to title if available
    if pfUI.font_default and frame.titleText then
        frame.titleText:SetFont(pfUI.font_default, 14, "OUTLINE")
        CE_Debug("ApplyPfUIStyling: Applied pfUI font to title")
    end
end

-- Function to apply pfUI styling to main menu button
function Config:ApplyPfUIStylingToMainMenuButton()
    if not pfUI or not pfUI.GetEnvironment then return end
    
    local env = pfUI:GetEnvironment()
    if not env or not env.SkinButton then return end
    
    if GameMenuButtonConsoleExperience then
        pcall(function()
            env.SkinButton(GameMenuButtonConsoleExperience)
            CE_Debug("ApplyPfUIStylingToMainMenuButton: Styled main menu button")
        end)
    end
end

-- Create the game menu button when the addon loads
Config:CreateGameMenuButton()

-- Apply pfUI styling after pfUI loads (check periodically)
local pfUICheckFrame = CreateFrame("Frame")
local pfUICheckElapsed = 0
local pfUICheckAttempts = 0
pfUICheckFrame:SetScript("OnUpdate", function()
    pfUICheckElapsed = pfUICheckElapsed + arg1
    if pfUICheckElapsed > 0.5 then
        pfUICheckElapsed = 0
        pfUICheckAttempts = pfUICheckAttempts + 1
        
        if pfUI and pfUI.GetEnvironment then
            local env = pfUI:GetEnvironment()
            if env and env.SkinButton then
                -- Apply styling to config frame
                if Config.frame and not Config.frame.pfUIStyled then
                    Config:ApplyPfUIStyling()
                    Config.frame.pfUIStyled = true
                end
                
                -- Apply styling to main menu button
                Config:ApplyPfUIStylingToMainMenuButton()
                
                -- Stop checking once both are styled
                if Config.frame and Config.frame.pfUIStyled then
                    this:SetScript("OnUpdate", nil)
                end
            end
        end
        
        -- Stop checking after 20 attempts (10 seconds)
        if pfUICheckAttempts >= 20 then
            this:SetScript("OnUpdate", nil)
        end
    end
end)

-- Create reload UI popup
StaticPopupDialogs["CE_RELOAD_UI"] = {
    text = "Language changed. Reload UI to apply?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Helper function to trim whitespace (WoW 1.12 doesn't have string.trim)
local function trimString(s)
    if not s then return "" end
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

-- Create profile popups
StaticPopupDialogs["CE_CREATE_PROFILE"] = {
    text = "Enter profile name:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 20,
    OnAccept = function()
        local dialog = getglobal("StaticPopup1")
        local editBox = getglobal("StaticPopup1EditBox")
        if editBox then
            local name = editBox:GetText()
            if name and name ~= "" then
                name = trimString(name)
                if name ~= "" then
                    local success, error = ConsoleExperience.profiles:CreateProfile(name, nil)
                    if success then
                        -- Switch to new profile
                        ConsoleExperience.profiles:SetProfile(name)
                    -- Refresh UI
                    if ConsoleExperience.config and ConsoleExperience.config.RefreshProfileDropdown then
                        ConsoleExperience.config:RefreshProfileDropdown()
                    end
                    if ConsoleExperience.config and ConsoleExperience.config.UpdateDeleteButtonState then
                        ConsoleExperience.config:UpdateDeleteButtonState()
                    end
                else
                    StaticPopup_Show("CE_PROFILE_ERROR", error or "Failed to create profile")
                    end
                end
            end
        end
    end,
    OnShow = function()
        local editBox = getglobal("StaticPopup1EditBox")
        if editBox then
            editBox:SetText("")
            -- If virtual keyboard is enabled, show it automatically
            local config = ConsoleExperience.config
            if config and config:Get("keyboardEnabled") and ConsoleExperience.keyboard then
                -- Use a small delay to ensure editbox is fully created and focused
                local showKeyboardFrame = CreateFrame("Frame")
                showKeyboardFrame:SetScript("OnUpdate", function()
                    this:SetScript("OnUpdate", nil)
                    if editBox and editBox:IsVisible() then
                        ConsoleExperience.keyboard:Show(editBox)
                    end
                end)
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["CE_CLONE_PROFILE"] = {
    text = "Enter name for cloned profile:",
    button1 = "Clone",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 20,
    OnAccept = function()
        local editBox = getglobal("StaticPopup1EditBox")
        if editBox then
            local name = editBox:GetText()
            if name and name ~= "" then
                name = trimString(name)
                if name ~= "" then
                    local currentProfile = ConsoleExperience.profiles:GetCurrentProfileName()
                    -- Save current profile first
                    ConsoleExperience.profiles:SaveCurrentProfile()
                    -- Clone it
                    local success, error = ConsoleExperience.profiles:CreateProfile(name, currentProfile)
                    if success then
                        -- Switch to the newly cloned profile
                        ConsoleExperience.profiles:SetProfile(name)
                        -- Refresh UI
                        if ConsoleExperience.config and ConsoleExperience.config.RefreshProfileDropdown then
                            ConsoleExperience.config:RefreshProfileDropdown()
                        end
                        if ConsoleExperience.config and ConsoleExperience.config.UpdateDeleteButtonState then
                            ConsoleExperience.config:UpdateDeleteButtonState()
                        end
                        -- Refresh the profiles section to show the new profile is selected
                        if ConsoleExperience.config and ConsoleExperience.config.frame and ConsoleExperience.config.frame:IsVisible() then
                            if ConsoleExperience.config.ShowSection then
                                ConsoleExperience.config:ShowSection("profiles")
                            end
                        end
                    else
                        StaticPopup_Show("CE_PROFILE_ERROR", error or "Failed to clone profile")
                    end
                end
            end
        end
    end,
    OnShow = function()
        local editBox = getglobal("StaticPopup1EditBox")
        if editBox then
            editBox:SetText("")
            -- If virtual keyboard is enabled, show it automatically
            local config = ConsoleExperience.config
            if config and config:Get("keyboardEnabled") and ConsoleExperience.keyboard then
                -- Use a small delay to ensure editbox is fully created and focused
                local showKeyboardFrame = CreateFrame("Frame")
                showKeyboardFrame:SetScript("OnUpdate", function()
                    this:SetScript("OnUpdate", nil)
                    if editBox and editBox:IsVisible() then
                        ConsoleExperience.keyboard:Show(editBox)
                    end
                end)
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["CE_DELETE_PROFILE"] = {
    text = "Delete profile '%s'? This cannot be undone.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function()
        local dialog = getglobal("StaticPopup1")
        local profileName = dialog and dialog.data
        if profileName then
            local success, error = ConsoleExperience.profiles:DeleteProfile(profileName)
            if success then
                -- Refresh UI
                if ConsoleExperience.config and ConsoleExperience.config.RefreshProfileDropdown then
                    ConsoleExperience.config:RefreshProfileDropdown()
                end
                if ConsoleExperience.config and ConsoleExperience.config.UpdateDeleteButtonState then
                    ConsoleExperience.config:UpdateDeleteButtonState()
                end
            else
                StaticPopup_Show("CE_PROFILE_ERROR", error or "Failed to delete profile")
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["CE_PROFILE_ERROR"] = {
    text = "%s",
    button1 = "OK",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

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
    local crosshairType = self:Get("crosshairType") or "cross"
    local r = self:Get("crosshairColorR") or 1.0
    local g = self:Get("crosshairColorG") or 1.0
    local b = self:Get("crosshairColorB") or 1.0
    local a = self:Get("crosshairColorA") or 0.8
    local thickness = math.max(2, math.floor(size / 12))
    
    -- Update position
    self.crosshairFrame:ClearAllPoints()
    self.crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
    self.crosshairFrame:SetWidth(size + 8)
    self.crosshairFrame:SetHeight(size + 8)
    
    -- Update crosshair based on type
    if crosshairType == "dot" then
        -- Dot only - hide lines, show dot with configured color
        if self.crosshairFrame.hLine then
            self.crosshairFrame.hLine:Hide()
        end
        if self.crosshairFrame.vLine then
            self.crosshairFrame.vLine:Hide()
        end
        if self.crosshairFrame.dot then
            local dotSize = math.max(2, math.floor(size / 6))
            self.crosshairFrame.dot:SetWidth(dotSize)
            self.crosshairFrame.dot:SetHeight(dotSize)
            self.crosshairFrame.dot:SetTexture(r, g, b, a)
            self.crosshairFrame.dot:Show()
        end
    else
        -- Cross - show lines and dot (dot uses red tint for visibility in cross mode)
        if self.crosshairFrame.hLine then
            self.crosshairFrame.hLine:SetWidth(size)
            self.crosshairFrame.hLine:SetHeight(thickness)
            self.crosshairFrame.hLine:SetTexture(r, g, b, a)
            self.crosshairFrame.hLine:Show()
        end
        if self.crosshairFrame.vLine then
            self.crosshairFrame.vLine:SetWidth(thickness)
            self.crosshairFrame.vLine:SetHeight(size)
            self.crosshairFrame.vLine:SetTexture(r, g, b, a)
            self.crosshairFrame.vLine:Show()
        end
        if self.crosshairFrame.dot then
            local dotSize = math.max(2, math.floor(size / 6))
            self.crosshairFrame.dot:SetWidth(dotSize)
            self.crosshairFrame.dot:SetHeight(dotSize)
            -- Dot uses red tint for visibility when lines are present (original behavior)
            self.crosshairFrame.dot:SetTexture(r, g * 0.2, b * 0.2, a)
            self.crosshairFrame.dot:Show()
        end
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
        if button and button:IsVisible() ~= nil then  -- Ensure button exists and is valid
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
                -- For modern appearance, icon size will be adjusted below
                -- For classic, use full size minus padding
                local appearance = self:Get("barAppearance") or "classic"
                if appearance == "modern" then
                    -- Modern: Larger icon to better fill the circular overlay
                    -- Increase size slightly to eliminate gaps
                    icon:SetWidth(buttonSize * 0.84)  -- 70% of button size
                    icon:SetHeight(buttonSize * 0.84)  -- Square for better fit
                else
                    icon:SetWidth(buttonSize - 4)
                    icon:SetHeight(buttonSize - 4)
                end
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
            
            -- Apply button appearance styling (delegated to actionbars module)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.ApplyButtonAppearance then
                ConsoleExperience.actionbars:ApplyButtonAppearance(button)
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
    
    -- Update side action bars to match new settings
    if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
        ConsoleExperience.actionbars:UpdateSideBars()
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

SLASH_CEHEALER1 = "/cehealer"
SLASH_CEHEALER2 = "/ceheal"
SlashCmdList["CEHEALER"] = function(msg)
    local currentValue = Config:Get("healerMode")
    local newValue = currentValue
    local msgLower = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"))
    
    if msgLower == "on" or msgLower == "enable" or msgLower == "1" or msgLower == "true" then
        newValue = true
    elseif msgLower == "off" or msgLower == "disable" or msgLower == "0" or msgLower == "false" then
        newValue = false
    elseif msgLower == "" or msgLower == "toggle" then
        -- Toggle if no argument or "toggle" is provided
        newValue = not currentValue
    else
        -- Show current state and usage
        CE_Print("Healer mode is currently: " .. (currentValue and "ENABLED" or "DISABLED"))
        CE_Print("Usage: /cehealer [on|off|toggle]")
        return
    end
    
    -- Only update if value changed
    if newValue ~= currentValue then
        Config:Set("healerMode", newValue)
        if newValue then
            CE_Print("Healer mode ENABLED")
        else
            CE_Print("Healer mode DISABLED")
        end
        -- Update party/raid frame hooks when healer mode changes
        if ConsoleExperience.hooks and ConsoleExperience.hooks.HookPartyRaidFrames then
            ConsoleExperience.hooks:HookPartyRaidFrames()
        end
        -- Update action bar buttons (to hide/show D-pad buttons)
        if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
            ConsoleExperience.actionbars:UpdateAllButtons()
        end
    else
        -- Value didn't change, just show current state
        CE_Print("Healer mode is already: " .. (currentValue and "ENABLED" or "DISABLED"))
    end
end

