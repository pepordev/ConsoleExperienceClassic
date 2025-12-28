--[[
    ConsoleExperienceClassic - Spell Placement Frame
    
    Opens when picking up a spell/macro/item to allow placing on action bars
    Shows all 4 pages (40 slots) in a grid layout with controller button icons
]]

-- Create placement module namespace
ConsoleExperience.placement = ConsoleExperience.placement or {}
local Placement = ConsoleExperience.placement

-- Constants
local NUM_BUTTONS = 10
local NUM_PAGES = 4
local BUTTON_SIZE = 60
local BUTTON_SPACING = 8
local FRAME_PADDING = 25
local ICON_SIZE = 14

-- Icon path
local iconPath = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\"

-- Button layout info (matches action bar layout)
-- Format: { id, icon, name }
Placement.BUTTON_INFO = {
    { id = 1,  icon = "a",     name = "A" },
    { id = 2,  icon = "x",     name = "X" },
    { id = 3,  icon = "y",     name = "Y" },
    { id = 4,  icon = "b",     name = "B" },
    { id = 5,  icon = "down",  name = "Down" },
    { id = 6,  icon = "left",  name = "Left" },
    { id = 7,  icon = "up",    name = "Up" },
    { id = 8,  icon = "right", name = "Right" },
    { id = 9,  icon = "rb",    name = "RB" },
    { id = 10, icon = "lb",    name = "LB" },
}

-- Page modifiers (with icons)
Placement.PAGE_MODIFIERS = {
    [1] = { text = "", icons = {} },
    [2] = { text = "LT", icons = {"lt"} },
    [3] = { text = "RT", icons = {"rt"} },
    [4] = { text = "LT+RT", icons = {"lt", "rt"} },
}

-- ============================================================================
-- Frame Creation
-- ============================================================================

function Placement:CreateFrame()
    if self.frame then return self.frame end
    
    -- Calculate frame size (bigger frame)
    -- Add extra width for row labels on the left
    local labelColumnWidth = 50  -- Space for modifier icons column
    local frameWidth = (BUTTON_SIZE * NUM_BUTTONS) + (BUTTON_SPACING * (NUM_BUTTONS - 1)) + (FRAME_PADDING * 2) + labelColumnWidth
    local frameHeight = (BUTTON_SIZE * NUM_PAGES) + (BUTTON_SPACING * (NUM_PAGES - 1)) + (FRAME_PADDING * 2) + 80  -- +80 for title and header row
    
    -- Main frame
    local frame = CreateFrame("Frame", "ConsoleExperiencePlacementFrame", UIParent)
    frame:SetWidth(frameWidth)
    frame:SetHeight(frameHeight)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetAlpha(1.0)  -- Ensure frame itself is fully opaque
    frame:Hide()
    
    -- Create completely solid opaque background
    -- Use backdrop with solid texture and multiple background layers
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    -- Set backdrop to fully opaque black (multiple times to ensure)
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Additional solid background layer behind backdrop for extra opacity
    local solidBg = frame:CreateTexture(nil, "BACKGROUND")
    solidBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    solidBg:SetAllPoints(frame)
    solidBg:SetVertexColor(0, 0, 0, 1.0)  -- Fully opaque black
    frame.solidBg = solidBg
    
    -- Title bar for dragging
    local titleRegion = CreateFrame("Frame", nil, frame)
    titleRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
    titleRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -35, -5)
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
    title:SetText("Place Action")
    
    -- Close button
    local closeButton = CreateFrame("Button", "CEPlacementCloseButton", frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        Placement:Hide()
        ClearCursor()
    end)
    
    -- Create column headers with button icons
    local labelColumnWidth = 50  -- Space for modifier icons column on the left
    
    -- Check if A button should be hidden (useAForJump config)
    local useAForJump = false
    if ConsoleExperience.config and ConsoleExperience.config.Get then
        useAForJump = ConsoleExperience.config:Get("useAForJump") or false
    end
    
    frame.headerIcons = {}  -- Store header icons for visibility control
    for btn = 1, NUM_BUTTONS do
        local btnInfo = self.BUTTON_INFO[btn]
        if btnInfo then
            local xOffset = FRAME_PADDING + labelColumnWidth + ((btn - 1) * (BUTTON_SIZE + BUTTON_SPACING)) + (BUTTON_SIZE / 2)
            
            -- Create header icon (square to prevent stretching)
            local headerIcon = frame:CreateTexture(nil, "OVERLAY")
            headerIcon:SetWidth(ICON_SIZE + 2)
            headerIcon:SetHeight(ICON_SIZE + 2)
            headerIcon:SetTexCoord(0, 1, 0, 1)  -- Ensure proper texture coordinates
            headerIcon:SetTexture(iconPath .. btnInfo.icon)
            headerIcon:SetPoint("TOP", frame, "TOPLEFT", xOffset, -42)
            
            -- Header icon stays visible even if first button is hidden (other A buttons are still visible)
            frame.headerIcons[btn] = headerIcon
        end
    end
    
    -- Create action buttons grid
    self.buttons = {}
    
    for page = 1, NUM_PAGES do
        for btn = 1, NUM_BUTTONS do
            local actionSlot = ((page - 1) * NUM_BUTTONS) + btn
            local button = self:CreateActionButton(frame, actionSlot, btn, page)
            
            -- Hide only the first A button (slot 1, page 1) if useAForJump is enabled
            -- Other A buttons (LT+A, RT+A, LT+RT+A) should remain visible
            if btn == 1 and page == 1 and useAForJump then
                button:Hide()
            end
            
            self.buttons[actionSlot] = button
        end
    end
    
    -- Row labels (page modifiers) with icons
    -- Position them inside the frame, to the left of the buttons
    local labelColumnWidth = 50  -- Space for modifier icons column on the left
    for page = 1, NUM_PAGES do
        local pageInfo = self.PAGE_MODIFIERS[page]
        -- Calculate Y position to center on the row (same coordinate system as buttons)
        -- Buttons use: yOffset = -70 - ((pageIndex - 1) * (BUTTON_SIZE + BUTTON_SPACING))
        -- Row center is at button top + BUTTON_SIZE/2
        local buttonTopY = -70 - ((page - 1) * (BUTTON_SIZE + BUTTON_SPACING))
        local rowCenterY = buttonTopY - (BUTTON_SIZE / 2)  -- Negative because going down from TOP
        
        -- Create icon container for row label
        local labelContainer = CreateFrame("Frame", "CEPlacementRowLabel" .. page, frame)
        labelContainer:SetWidth(40)
        labelContainer:SetHeight(ICON_SIZE)
        -- Position inside frame, to the left of buttons
        -- Use CENTER anchor vertically to align with row center
        -- Position horizontally: FRAME_PADDING + labelColumnWidth/2 (center of label column)
        labelContainer:SetPoint("CENTER", frame, "TOPLEFT", FRAME_PADDING + (labelColumnWidth / 2), rowCenterY)
        
        local xPos = 0
        if pageInfo and pageInfo.icons and table.getn(pageInfo.icons) > 0 then
            for i = 1, table.getn(pageInfo.icons) do
                local iconName = pageInfo.icons[i]
                local modIcon = labelContainer:CreateTexture(nil, "OVERLAY")
                modIcon:SetWidth(ICON_SIZE)
                modIcon:SetHeight(ICON_SIZE)
                modIcon:SetTexCoord(0, 1, 0, 1)  -- Ensure proper texture coordinates
                modIcon:SetTexture(iconPath .. iconName)
                modIcon:SetPoint("RIGHT", labelContainer, "RIGHT", -xPos, 0)
                xPos = xPos + ICON_SIZE + 2
            end
        end
    end
    
    -- Add to special frames so Escape closes it
    table.insert(UISpecialFrames, "ConsoleExperiencePlacementFrame")
    
    self.frame = frame
    
    -- Hook to cursor for cursor navigation
    if ConsoleExperience.hooks and ConsoleExperience.hooks.HookDynamicFrame then
        ConsoleExperience.hooks:HookDynamicFrame(frame, "Spell Placement")
    end
    
    return frame
end

function Placement:CreateActionButton(parent, actionSlot, buttonIndex, pageIndex)
    local buttonName = "CEPlacementButton" .. actionSlot
    local button = CreateFrame("Button", buttonName, parent)
    
    -- Position (accounting for header row and label column)
    local labelColumnWidth = 50  -- Space for modifier icons column on the left
    local xOffset = FRAME_PADDING + labelColumnWidth + ((buttonIndex - 1) * (BUTTON_SIZE + BUTTON_SPACING))
    local yOffset = -70 - ((pageIndex - 1) * (BUTTON_SIZE + BUTTON_SPACING))
    
    button:SetWidth(BUTTON_SIZE)
    button:SetHeight(BUTTON_SIZE)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    
    -- Background
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Quickslot2",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 0,
        edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    button:SetBackdropColor(0.2, 0.2, 0.2, 1.0)  -- Fully opaque background
    button:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)  -- Visible border
    
    -- Icon texture (with padding for controller icons at bottom)
    -- Keep icon square to prevent stretching
    local iconSize = BUTTON_SIZE - 10  -- Padding from edges
    local icon = button:CreateTexture(buttonName .. "Icon", "ARTWORK")
    icon:SetWidth(iconSize)
    icon:SetHeight(iconSize)  -- Square to prevent stretching
    icon:SetPoint("CENTER", button, "CENTER", 0, 4)  -- Slightly above center to leave room for controller icons
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)  -- Slight padding in texture coords to prevent edge clipping
    button.icon = icon
    
    -- Controller button icons overlay
    local btnInfo = self.BUTTON_INFO[buttonIndex]
    local pageInfo = self.PAGE_MODIFIERS[pageIndex]
    
    -- Create icon container (positioned at bottom-left with proper padding)
    local iconContainer = CreateFrame("Frame", nil, button)
    local numModIcons = 0
    if pageInfo and pageInfo.icons then
        numModIcons = table.getn(pageInfo.icons)
    end
    local iconContainerWidth = (numModIcons + 1) * ICON_SIZE + (numModIcons * 2)  -- Icons + spacing
    iconContainer:SetWidth(iconContainerWidth)
    iconContainer:SetHeight(ICON_SIZE)
    iconContainer:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 4, 4)  -- Proper padding from bottom-left corner
    iconContainer:SetFrameLevel(button:GetFrameLevel() + 2)
    button.iconContainer = iconContainer
    
    -- Add modifier icons first (LT, RT) - positioned from left
    local xPos = 0
    if pageInfo and pageInfo.icons then
        for i = 1, table.getn(pageInfo.icons) do
            local modIconName = pageInfo.icons[i]
            local modIcon = iconContainer:CreateTexture(nil, "OVERLAY")
            modIcon:SetWidth(ICON_SIZE)
            modIcon:SetHeight(ICON_SIZE)
            modIcon:SetTexCoord(0, 1, 0, 1)  -- Ensure proper texture coordinates
            modIcon:SetTexture(iconPath .. modIconName)
            modIcon:SetPoint("LEFT", iconContainer, "LEFT", xPos, 0)
            xPos = xPos + ICON_SIZE + 2  -- 2px spacing between icons
        end
    end
    
    -- Add main button icon
    if btnInfo then
        local mainIcon = iconContainer:CreateTexture(nil, "OVERLAY")
        mainIcon:SetWidth(ICON_SIZE)
        mainIcon:SetHeight(ICON_SIZE)
        mainIcon:SetTexCoord(0, 1, 0, 1)  -- Ensure proper texture coordinates
        mainIcon:SetTexture(iconPath .. btnInfo.icon)
        mainIcon:SetPoint("LEFT", iconContainer, "LEFT", xPos, 0)
    end
    
    -- Store action slot
    button.actionSlot = actionSlot
    button.buttonIndex = buttonIndex
    button.pageIndex = pageIndex
    
    -- Highlight texture
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(button)
    
    -- Click handler - place cursor item
    button:SetScript("OnClick", function()
        if CursorHasItem() or CursorHasSpell() then
            PlaceAction(this.actionSlot)
            CE_Debug("Placed item in action slot " .. this.actionSlot)
            
            -- Update the button display
            Placement:UpdateButton(this)
            
            -- Update main action bar if on current page
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
            
            -- Clear fake cursor held item
            if ConsoleExperience.cursor then
                ConsoleExperience.cursor:ClearHeldItemTexture()
            end
            
            -- Don't auto-hide - allow user to continue placing items
        else
            -- No cursor item, maybe pick up from this slot
            PickupAction(this.actionSlot)
            Placement:UpdateButton(this)
            
            -- Show held item on fake cursor
            local texture = GetActionTexture(this.actionSlot)
            if texture and ConsoleExperience.cursor and ConsoleExperience.cursor.SetHeldItemTexture then
                ConsoleExperience.cursor:SetHeldItemTexture(texture)
            end
        end
    end)
    
    -- Right-click to pick up
    button:SetScript("OnMouseDown", function()
        if arg1 == "RightButton" then
            PickupAction(this.actionSlot)
            Placement:UpdateButton(this)
            
            local texture = GetActionTexture(this.actionSlot)
            if texture and ConsoleExperience.cursor and ConsoleExperience.cursor.SetHeldItemTexture then
                ConsoleExperience.cursor:SetHeldItemTexture(texture)
            end
        end
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        if HasAction(this.actionSlot) then
            GameTooltip:SetAction(this.actionSlot)
            -- Prompts will be added automatically by tooltip system: A = Pickup/Place, B = Clear
        else
            local btnInfo = Placement.BUTTON_INFO[this.buttonIndex]
            local pageInfo = Placement.PAGE_MODIFIERS[this.pageIndex]
            local slotName = btnInfo and btnInfo.name or ("Slot " .. this.buttonIndex)
            if pageInfo and pageInfo.text ~= "" then
                slotName = pageInfo.text .. " + " .. slotName
            end
            GameTooltip:SetText(slotName)
            GameTooltip:AddLine("Empty slot", 0.7, 0.7, 0.7)
            -- Prompts will be added automatically by tooltip system: A = Pickup/Place, B = Clear
        end
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Receive drag
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnReceiveDrag", function()
        if CursorHasItem() or CursorHasSpell() then
            PlaceAction(this.actionSlot)
            Placement:UpdateButton(this)
            
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
            
            if ConsoleExperience.cursor and ConsoleExperience.cursor.ClearHeldItemTexture then
                ConsoleExperience.cursor:ClearHeldItemTexture()
            end
        end
    end)
    
    return button
end

-- ============================================================================
-- Update Functions
-- ============================================================================

function Placement:UpdateButton(button)
    if not button then return end
    
    local actionSlot = button.actionSlot
    local texture = GetActionTexture(actionSlot)
    
    if texture then
        button.icon:SetTexture(texture)
        button.icon:Show()
        button:SetBackdropColor(0.2, 0.2, 0.2, 1.0)  -- Fully opaque
    else
        button.icon:Hide()
        button:SetBackdropColor(0.15, 0.15, 0.15, 1.0)  -- Fully opaque
    end
end

function Placement:UpdateAllButtons()
    if not self.buttons then return end
    
    for actionSlot, button in pairs(self.buttons) do
        self:UpdateButton(button)
    end
end

-- ============================================================================
-- Show/Hide
-- ============================================================================

function Placement:UpdateButtonVisibility()
    if not self.frame then return end
    
    -- Check if A button should be hidden (useAForJump config)
    local useAForJump = false
    if ConsoleExperience.config and ConsoleExperience.config.Get then
        useAForJump = ConsoleExperience.config:Get("useAForJump") or false
    end
    
    -- Header icon stays visible (column still has LT+A, RT+A, LT+RT+A buttons)
    
    -- Hide/show only the first A button (slot 1, page 1) if useAForJump is enabled
    -- Other A buttons (LT+A, RT+A, LT+RT+A) should remain visible
    if self.buttons then
        local actionSlot = 1  -- Only slot 1 (page 1, button 1)
        local button = self.buttons[actionSlot]
        if button then
            if useAForJump then
                button:Hide()
            else
                button:Show()
            end
        end
    end
end

function Placement:Show()
    if not self.frame then
        self:CreateFrame()
    end
    
    -- Update button visibility based on config
    self:UpdateButtonVisibility()
    
    self:UpdateAllButtons()
    self.frame:Show()
    
    CE_Debug("Placement frame shown")
end

function Placement:Hide()
    if self.frame then
        self.frame:Hide()
    end
    
    -- Clear fake cursor held item texture
    if ConsoleExperience.cursor then
        ConsoleExperience.cursor:ClearHeldItemTexture()
    end
    
    CE_Debug("Placement frame hidden")
end

function Placement:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function Placement:IsShown()
    return self.frame and self.frame:IsShown()
end

-- ============================================================================
-- Auto-show when picking up items
-- ============================================================================

-- Hook into cursor pickup to auto-show
function Placement:OnItemPickedUp()
    -- Small delay to ensure cursor state is updated
    self:Show()
end

-- ============================================================================
-- Event Handling for Auto-Show
-- ============================================================================

function Placement:Initialize()
    -- Event frame creation removed - placement frame now only shows manually
    -- Auto-show on cursor update has been disabled
    -- Frame can only be opened from config menu or via Placement:Show() explicitly
    
    CE_Debug("Placement module initialized")
end

-- Removed OnCursorUpdate() - placement frame no longer auto-shows on item pickup
-- Frame must be manually opened from config menu

-- Module loaded
CE_Debug("Placement module loaded")

