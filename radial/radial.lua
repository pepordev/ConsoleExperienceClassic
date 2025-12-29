--[[
    ConsoleExperienceClassic - Radial Menu Module
    
    A circular menu for quick access to game functions
    Similar to modern WoW's radial menu
]]

-- Create radial module namespace
ConsoleExperience.radial = ConsoleExperience.radial or {}
local Radial = ConsoleExperience.radial

-- Menu configuration
local MENU_SIZE = 400
local INNER_RADIUS = 80
local OUTER_RADIUS = 160
local BUTTON_SIZE = 44
local NUM_SEGMENTS = 13

-- Menu items (clockwise from top)
local menuItems = {
    {
        name = "Character",
        icon = "Interface\\Icons\\INV_Shirt_White_01",
        action = function() ToggleCharacter("PaperDollFrame") end
    },
    {
        name = "Inventory",
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        action = function()
            if IsBagOpen(0) then
                CloseAllBags()
            else
                OpenAllBags()
            end
        end
    },
    {
        name = "Spellbook",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        action = function() ToggleSpellBook(BOOKTYPE_SPELL) end
    },
    {
        name = "Talents",
        icon = "Interface\\Icons\\Ability_Marksmanship",
        action = function() ToggleTalentFrame() end
    },
    {
        name = "Quest Log",
        icon = "Interface\\Icons\\INV_Misc_Note_01",
        action = function() ToggleQuestLog() end
    },
    {
        name = "World Map",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        action = function() ToggleWorldMap() end
    },
    {
        name = "Social",
        icon = "Interface\\Icons\\INV_Letter_02",
        action = function() ToggleFriendsFrame(1) end
    },
    {
        name = "Guild",
        icon = "Interface\\Icons\\Spell_Holy_PrayerOfSpirit",
        action = function() 
            if IsInGuild() then
                ToggleFriendsFrame(3)
            else
                CE_Debug("You are not in a guild")
            end
        end
    },
    {
        name = "LFG",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        action = function() 
            if ToggleLFGFrame then
                ToggleLFGFrame()
            elseif LFGParentFrame then
                if LFGParentFrame:IsVisible() then
                    HideUIPanel(LFGParentFrame)
                else
                    ShowUIPanel(LFGParentFrame)
                end
            else
                CE_Debug("LFG not available")
            end
        end
    },
    {
        name = "Chat",
        icon = "Interface\\Icons\\INV_Misc_Note_02",
        action = function() 
            if ChatFrameEditBox then
                if ChatFrameEditBox:IsVisible() then
                    ChatFrameEditBox:Hide()
                else
                    ChatFrameEditBox:Show()
                    ChatFrameEditBox:Raise()
                end
            end
        end
    },
    {
        name = "CE Options",
        icon = "Interface\\Icons\\Trade_Engineering",
        action = function() 
            if ConsoleExperience.config then
                ConsoleExperience.config:Toggle()
            end
        end
    },
    {
        name = "Key Bindings",
        icon = "Interface\\Icons\\Spell_Nature_Lightning",
        action = function() 
            if KeyBindingFrame then
                if KeyBindingFrame:IsVisible() then
                    HideUIPanel(KeyBindingFrame)
                else
                    ShowUIPanel(KeyBindingFrame)
                end
            end
        end
    },
}

-- ============================================================================
-- Create Main Frame
-- ============================================================================

function Radial:CreateFrame()
    if self.frame then return self.frame end
    
    local frame = CreateFrame("Frame", "ConsoleExperienceRadialMenu", UIParent)
    frame:SetWidth(MENU_SIZE)
    frame:SetHeight(MENU_SIZE)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)
    frame:EnableMouse(true)
    frame:Hide()
    
    -- Dark overlay background for the whole screen
    local overlay = CreateFrame("Frame", "ConsoleExperienceRadialOverlay", UIParent)
    overlay:SetAllPoints(UIParent)
    overlay:SetFrameStrata("FULLSCREEN")
    overlay:SetFrameLevel(99)
    overlay:EnableMouse(true)
    overlay:Hide()
    
    local overlayBg = overlay:CreateTexture(nil, "BACKGROUND")
    overlayBg:SetAllPoints(overlay)
    overlayBg:SetTexture(0, 0, 0, 0.7)
    overlay.bg = overlayBg
    
    -- Click overlay to close
    overlay:SetScript("OnMouseDown", function()
        Radial:Hide()
    end)
    
    self.overlay = overlay
    
    -- Center circle background
    local centerBg = frame:CreateTexture(nil, "BACKGROUND")
    centerBg:SetWidth(INNER_RADIUS * 2 + 20)
    centerBg:SetHeight(INNER_RADIUS * 2 + 20)
    centerBg:SetPoint("CENTER", frame, "CENTER", 0, 0)
    centerBg:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    centerBg:SetVertexColor(0.1, 0.1, 0.1, 0.9)
    frame.centerBg = centerBg
    
    -- Outer ring background
    local ringBg = frame:CreateTexture(nil, "ARTWORK")
    ringBg:SetWidth(OUTER_RADIUS * 2 + 40)
    ringBg:SetHeight(OUTER_RADIUS * 2 + 40)
    ringBg:SetPoint("CENTER", frame, "CENTER", 0, 0)
    ringBg:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    ringBg:SetVertexColor(0.15, 0.12, 0.08, 0.95)
    frame.ringBg = ringBg
    
    -- Player portrait in center
    local portrait = frame:CreateTexture(nil, "OVERLAY")
    portrait:SetWidth(64)
    portrait:SetHeight(64)
    portrait:SetPoint("CENTER", frame, "CENTER", 0, 0)
    SetPortraitTexture(portrait, "player")
    frame.portrait = portrait
    
    -- Portrait border
    local portraitBorder = frame:CreateTexture(nil, "OVERLAY")
    portraitBorder:SetWidth(72)
    portraitBorder:SetHeight(72)
    portraitBorder:SetPoint("CENTER", frame, "CENTER", 0, 0)
    portraitBorder:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    portraitBorder:SetVertexColor(0.3, 0.25, 0.2, 1)
    frame.portraitBorder = portraitBorder
    
    -- Close button (X in center)
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetWidth(24)
    closeBtn:SetHeight(24)
    closeBtn:SetPoint("CENTER", frame, "CENTER", 0, -45)
    
    local closeTex = closeBtn:CreateTexture(nil, "OVERLAY")
    closeTex:SetAllPoints(closeBtn)
    closeTex:SetTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up")
    closeBtn:SetNormalTexture(closeTex)
    
    closeBtn:SetScript("OnClick", function()
        Radial:Hide()
    end)
    frame.closeBtn = closeBtn
    
    self.frame = frame
    
    -- Create menu buttons
    self:CreateButtons()
    
    -- Add to special frames for Escape to close
    tinsert(UISpecialFrames, "ConsoleExperienceRadialMenu")
    
    -- When frame is hidden (by Escape or other means), also hide the overlay
    frame:SetScript("OnHide", function()
        if Radial.overlay then
            Radial.overlay:Hide()
        end
    end)
    
    return frame
end

-- ============================================================================
-- Create Menu Buttons
-- ============================================================================

function Radial:CreateButtons()
    self.buttons = {}
    
    local numItems = table.getn(menuItems)
    local angleStep = 360 / numItems
    
    for i, item in ipairs(menuItems) do
        local button = self:CreateMenuButton(i, item, angleStep)
        table.insert(self.buttons, button)
    end
end

function Radial:CreateMenuButton(index, item, angleStep)
    local frame = self.frame
    
    -- Calculate position on the circle
    -- Start from top (-90 degrees) and go clockwise
    local angle = (index - 1) * angleStep - 90
    local radian = math.rad(angle)
    local radius = (INNER_RADIUS + OUTER_RADIUS) / 2 + 10
    local x = radius * math.cos(radian)
    local y = radius * math.sin(radian)
    
    -- Create button
    local button = CreateFrame("Button", "CERadialButton" .. index, frame)
    button:SetWidth(BUTTON_SIZE)
    button:SetHeight(BUTTON_SIZE)
    button:SetPoint("CENTER", frame, "CENTER", x, y)
    
    -- Button background (segment look)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetWidth(BUTTON_SIZE + 8)
    bg:SetHeight(BUTTON_SIZE + 8)
    bg:SetPoint("CENTER", button, "CENTER", 0, 0)
    bg:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    bg:SetVertexColor(0.2, 0.18, 0.15, 0.8)
    button.bg = bg
    
    -- Icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(BUTTON_SIZE - 4)
    icon:SetHeight(BUTTON_SIZE - 4)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexture(item.icon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon
    
    -- Icon border
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetWidth(BUTTON_SIZE + 2)
    border:SetHeight(BUTTON_SIZE + 2)
    border:SetPoint("CENTER", button, "CENTER", 0, 0)
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetVertexColor(0.6, 0.5, 0.4, 0.5)
    button.border = border
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetWidth(BUTTON_SIZE + 4)
    highlight:SetHeight(BUTTON_SIZE + 4)
    highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
    highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    highlight:SetBlendMode("ADD")
    highlight:SetVertexColor(1, 0.8, 0.2, 1)
    button:SetHighlightTexture(highlight)
    
    -- Label (positioned outside the circle)
    local labelRadius = OUTER_RADIUS + 30
    local labelX = labelRadius * math.cos(radian)
    local labelY = labelRadius * math.sin(radian)
    
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", frame, "CENTER", labelX, labelY)
    label:SetText(item.name)
    label:SetTextColor(1, 0.9, 0.7)
    button.label = label
    
    -- Store action
    button.item = item
    button.index = index
    
    -- Click handler
    button:SetScript("OnClick", function()
        if this.item and this.item.action then
            this.item.action()
        end
        Radial:Hide()
    end)
    
    -- Hover effects
    button:SetScript("OnEnter", function()
        this.label:SetTextColor(1, 1, 1)
        this.border:SetVertexColor(1, 0.8, 0.2, 1)
        
        -- Show tooltip
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(this.item.name)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        this.label:SetTextColor(1, 0.9, 0.7)
        this.border:SetVertexColor(0.6, 0.5, 0.4, 0.5)
        GameTooltip:Hide()
    end)
    
    return button
end

-- ============================================================================
-- Show/Hide
-- ============================================================================

function Radial:Show()
    if not self.frame then
        self:CreateFrame()
    end
    
    -- Update portrait
    if self.frame.portrait then
        SetPortraitTexture(self.frame.portrait, "player")
    end
    
    self.overlay:Show()
    self.frame:Show()
    
    -- Hook into cursor system
    if ConsoleExperience.hooks then
        ConsoleExperience.hooks:HookDynamicFrame(self.frame, "Radial Menu")
    end
end

function Radial:Hide()
    if self.overlay then
        self.overlay:Hide()
    end
    if self.frame then
        self.frame:Hide()
    end
end

function Radial:IsVisible()
    return self.frame and self.frame:IsVisible()
end

-- ============================================================================
-- Initialize
-- ============================================================================

function Radial:Initialize()
    self:CreateFrame()
    CE_Debug("Radial menu loaded.")
end

-- Module loaded silently

