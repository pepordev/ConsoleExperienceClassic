--[[
    ConsoleExperienceClassic - Action Bars Module
    
    Button Layout (Key = Button ID):
    - 1 = A, 2 = X, 3 = Y, 4 = B  (Face buttons)
    - 5 = Down, 6 = Left, 7 = Up, 8 = Right  (D-Pad)
    - 9 = RB, 10 = LB  (Bumpers)
    
    Page System (based on modifier keys):
    - Page 1: No modifiers (default)
    - Page 2: Shift held
    - Page 3: Ctrl held
    - Page 4: Shift+Ctrl held
]]

-- Create the actionbars module namespace
if ConsoleExperience.actionbars == nil then
    ConsoleExperience.actionbars = {}
end

local ActionBars = ConsoleExperience.actionbars

-- ============================================================================
-- Constants
-- ============================================================================

ActionBars.NUM_BUTTONS = 10
ActionBars.NUM_PAGES = 4  -- 4 pages accessible via modifier keys
ActionBars.TOOLTIP_UPDATE_TIME = 0.2
ActionBars.RANGE_CHECK_TIME = 0.2  -- Check range every 200ms (like pfUI)
ActionBars.FLASH_TIME = 0.4
ActionBars.MODIFIER_CHECK_TIME = 0.05  -- Check modifiers every 50ms

-- Color configurations for button states (matching pfUI defaults)
ActionBars.RANGE_COLOR = {1.0, 0.1, 0.1, 1.0}  -- Red for out of range
ActionBars.OOM_COLOR = {0.5, 0.5, 1.0, 1.0}    -- Blue for out of mana
ActionBars.NA_COLOR = {0.4, 0.4, 0.4, 1.0}     -- Gray for not usable
ActionBars.NORMAL_COLOR = {1.0, 1.0, 1.0, 1.0} -- White for normal

-- Event caching system (like pfUI)
ActionBars.eventCache = {}
ActionBars.updateCache = {}

-- Action slot offsets for each page (each page uses 10 consecutive action slots)
-- WoW 1.12 has 120 action slots total (12 action bar pages of 12 buttons each)
-- Warriors/Druids/Rogues use bonus bars for stances/forms (slots 73+)
-- We use modifier keys to access additional pages for non-stance abilities
ActionBars.PAGE_OFFSETS = {
    [1] = 0,    -- Page 1: slots 1-10 (no modifier, no stance)
    [2] = 10,   -- Page 2: slots 11-20 (Shift)
    [3] = 20,   -- Page 3: slots 21-30 (Ctrl)
    [4] = 30,   -- Page 4: slots 31-40 (Shift+Ctrl)
}

-- Bonus bar offset calculation for stances/forms
-- Formula: (NUM_ACTIONBAR_PAGES + bonusBarOffset - 1) * 12
-- Where NUM_ACTIONBAR_PAGES = 6, so base offset is 60 + (bonusBarOffset * 12)
-- Battle Stance (bonus=1): 72, Defensive (bonus=2): 84, Berserker (bonus=3): 96
ActionBars.BONUS_BAR_BASE = 60  -- (6 pages * 12 buttons) - 12 = 60

-- Current active page
ActionBars.currentPage = 1

-- Get current druid form name (returns nil if not druid or in caster form)
function ActionBars:GetCurrentDruidForm()
    local _, class = UnitClass("player")
    if class ~= "DRUID" then return nil end
    
    local numForms = GetNumShapeshiftForms() or 0
    for i = 1, numForms do
        local texture, name, isActive = GetShapeshiftFormInfo(i)
        if isActive == 1 and name then
            return name
        end
    end
    
    return nil  -- Caster form
end

-- Check if druid is in cat form with stealth/prowl active
-- Based on pfUI's IsCatStealth() function
function ActionBars:IsCatStealth()
    local _, class = UnitClass("player")
    if class ~= "DRUID" then return nil end
    
    local cat, stealth = nil, nil
    
    -- Check player buffs for cat form and stealth
    -- In WoW 1.12, we need to check buff textures
    for i = 0, 31 do
        local texture = nil
        
        -- Try different methods to get buff texture (WoW 1.12 compatibility)
        if GetPlayerBuffTexture then
            texture = GetPlayerBuffTexture(i)
        elseif GetPlayerBuff then
            -- GetPlayerBuff returns texture, rank, and other info
            texture = GetPlayerBuff(i)
        end
        
        if not texture then break end
        
        -- Cat form icon detected
        if string.find(texture, "Ability_Druid_CatForm") then
            if stealth then 
                return true 
            end
            cat = true
        end
        
        -- Stealth/prowl icon detected (uses Ambush icon)
        if string.find(texture, "Ability_Ambush") then
            if cat then 
                return true 
            end
            stealth = true
        end
    end
    
    return nil
end

-- Function to get controller icon path based on controller type
function ActionBars:GetControllerIconPath(iconName)
    local controllerType = "xbox"  -- Default
    if ConsoleExperience.config and ConsoleExperience.config.Get then
        controllerType = ConsoleExperience.config:Get("controllerType") or "xbox"
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

-- Controller button icon mapping (Button ID matches keyboard key)
-- Button 1-9 = keys 1-9, Button 10 = key 0
-- Icons are loaded dynamically based on controller type
function ActionBars:GetButtonIcons()
    return {
        [1] = self:GetControllerIconPath("a"),      -- Key 1
        [2] = self:GetControllerIconPath("x"),      -- Key 2
        [3] = self:GetControllerIconPath("y"),      -- Key 3
        [4] = self:GetControllerIconPath("b"),      -- Key 4
        [5] = self:GetControllerIconPath("down"),   -- Key 5
        [6] = self:GetControllerIconPath("left"),   -- Key 6
        [7] = self:GetControllerIconPath("up"),     -- Key 7
        [8] = self:GetControllerIconPath("right"),  -- Key 8
        [9] = self:GetControllerIconPath("rb"),     -- Key 9
        [10] = self:GetControllerIconPath("lb"),    -- Key 0
    }
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

function ActionBars:Initialize()
    self:HideDefaultBars()
    self:CreateModifierFrame()
    self:UpdateAllButtons()
    self:CreateSideBars()
    self:InitializeBagBar()
    self:HookCooldownFrame()
end

-- Hook CooldownFrame_SetTimer to hide default cooldowns for our buttons
function ActionBars:HookCooldownFrame()
    if not self.cooldownHookSet then
        -- Store original function
        local originalSetTimer = CooldownFrame_SetTimer
        -- Replace with our version
        CooldownFrame_SetTimer = function(cooldown, start, duration, enable)
            -- Hide cooldown if it belongs to one of our action buttons
            -- We use our own cooldown system (darkened icon + timer text)
            if cooldown and cooldown:GetParent() then
                local parent = cooldown:GetParent()
                local parentName = parent:GetName() or ""
                if string.find(parentName, "ConsoleActionButton") then
                    -- Hide default cooldown - we handle it ourselves
                    cooldown:Hide()
                    return
                end
            end
            -- For non-ConsoleActionButton cooldowns, call original
            originalSetTimer(cooldown, start, duration, enable)
        end
        self.cooldownHookSet = true
    end
end

-- ============================================================================
-- Custom Circular Cooldown for Modern Style
-- ============================================================================

-- Create a circular cooldown overlay for a button
function ActionBars:CreateCircularCooldown(button)
    local buttonName = button:GetName()
    local frameName = buttonName .. "CircularCooldown"
    
    -- Check if already created
    if button.circularCooldown then
        return button.circularCooldown
    end
    
    -- Create the main cooldown frame (just for text, we'll darken the icon directly)
    local frame = CreateFrame("Frame", frameName, button)
    frame:SetFrameLevel(button:GetFrameLevel() + 5)
    frame:SetAllPoints(button)
    frame:Hide()
    
    -- Store cooldown state
    frame.start = 0
    frame.duration = 0
    frame.enabled = false
    
    -- Store reference to the icon texture (we'll darken it during cooldown)
    frame.icon = getglobal(buttonName .. "Icon") or button.icon
    
    -- Create cooldown text (remaining time) - like OmniCC
    local text = frame:CreateFontString(frameName .. "Text", "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("CENTER", button, "CENTER", 0, 0)
    text:SetTextColor(1, 0.8, 0, 1)  -- Gold color
    text:SetText("")
    frame.text = text
    
    -- OnUpdate handler for animation
    frame:SetScript("OnUpdate", function()
        ActionBars:UpdateCircularCooldown(this)
    end)
    
    button.circularCooldown = frame
    return frame
end

-- Update the circular cooldown animation
function ActionBars:UpdateCircularCooldown(frame)
    if not frame.enabled or frame.duration == 0 then
        frame:Hide()
        -- Restore icon color when cooldown ends
        if frame.icon then
            frame.icon:SetVertexColor(1, 1, 1, 1)
        end
        return
    end
    
    local now = GetTime()
    local elapsed = now - frame.start
    local remaining = frame.duration - elapsed
    
    if remaining <= 0 then
        -- Cooldown finished
        frame.enabled = false
        frame:Hide()
        
        -- Restore icon color
        if frame.icon then
            frame.icon:SetVertexColor(1, 1, 1, 1)
        end
        return
    end
    
    -- Calculate progress (0 = just started, 1 = almost done)
    local progress = elapsed / frame.duration
    
    -- Darken the icon based on cooldown progress
    -- Start very dark (0.3) and gradually brighten to (0.7) as cooldown ends
    if frame.icon then
        local brightness = 0.3 + (progress * 0.4)
        frame.icon:SetVertexColor(brightness, brightness, brightness, 1)
    end
    
    -- Update cooldown text (no decimals)
    if frame.text then
        if remaining > 60 then
            frame.text:SetText(math.floor(remaining / 60) .. "m")
        elseif remaining > 0 then
            frame.text:SetText(math.ceil(remaining))
        else
            frame.text:SetText("")
        end
    end
end

-- Start the circular cooldown
function ActionBars:StartCircularCooldown(button, start, duration)
    if not button.circularCooldown then
        self:CreateCircularCooldown(button)
    end
    
    local frame = button.circularCooldown
    if not frame then return end
    
    if duration > 0 and start > 0 then
        frame.start = start
        frame.duration = duration
        frame.enabled = true
        frame:Show()
        
        -- Position text at icon center
        local buttonSize = button:GetWidth()
        if frame.text then
            frame.text:ClearAllPoints()
            frame.text:SetPoint("CENTER", button, "CENTER", -buttonSize * 0.02, 0)
        end
        
        -- Immediately darken the icon
        if frame.icon then
            frame.icon:SetVertexColor(0.3, 0.3, 0.3, 1)
        end
    else
        frame.enabled = false
        frame:Hide()
        -- Restore icon color
        if frame.icon then
            frame.icon:SetVertexColor(1, 1, 1, 1)
        end
    end
end

-- Stop/hide the circular cooldown
function ActionBars:StopCircularCooldown(button)
    if button.circularCooldown then
        button.circularCooldown.enabled = false
        button.circularCooldown:Hide()
        -- Restore icon color
        if button.circularCooldown.icon then
            button.circularCooldown.icon:SetVertexColor(1, 1, 1, 1)
        end
    end
end

function ActionBars:OnPlayerEnteringWorld()
    -- Re-hide bars on login/reload/zone change
    self:HideDefaultBars()
    self:UpdateAllButtons()
end

-- ============================================================================
-- Modifier Key Checking (Page Switching)
-- ============================================================================

function ActionBars:CreateModifierFrame()
    -- Create a frame to check modifier keys on update
    if self.modifierFrame then return end
    
    self.modifierFrame = CreateFrame("Frame", "ConsoleExperienceModifierFrame", UIParent)
    self.modifierFrame.timeSinceLastUpdate = 0
    self.modifierFrame.stealthCheckTime = 0
    self.modifierFrame.lastStealthState = nil
    
    self.modifierFrame:SetScript("OnUpdate", function()
        this.timeSinceLastUpdate = this.timeSinceLastUpdate + arg1
        if this.timeSinceLastUpdate >= ActionBars.MODIFIER_CHECK_TIME then
            this.timeSinceLastUpdate = 0
            ActionBars:CheckModifiers()
        end
        
        -- Check for druid stealth state changes (check less frequently)
        this.stealthCheckTime = this.stealthCheckTime + arg1
        if this.stealthCheckTime >= 0.1 then  -- Check every 100ms
            this.stealthCheckTime = 0
            
            -- Only check if druid stealth feature is enabled
            local useDruidStealth = false
            if ConsoleExperience.config and ConsoleExperience.config.Get then
                useDruidStealth = ConsoleExperience.config:Get("druidStealth") or false
            elseif ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.druidStealth then
                useDruidStealth = ConsoleExperienceDB.config.druidStealth
            end
            
            if useDruidStealth then
                local _, class = UnitClass("player")
                if class == "DRUID" then
                    local bonusBar = GetBonusBarOffset() or 0
                    
                    if bonusBar == 1 then
                        -- In cat form, check stealth state
                        local currentStealth = ActionBars:IsCatStealth()
                        
                        -- If stealth state changed, update buttons
                        if currentStealth ~= this.lastStealthState then
                            CE_Debug("Stealth state changed: " .. tostring(this.lastStealthState) .. " -> " .. tostring(currentStealth))
                            this.lastStealthState = currentStealth
                            -- Force update all buttons when stealth state changes
                            ActionBars:UpdateAllButtons()
                        end
                    else
                        -- Not in cat form, reset stealth state tracking
                        if this.lastStealthState ~= nil then
                            this.lastStealthState = nil
                        end
                    end
                end
            end
        end
    end)
end

function ActionBars:GetCurrentModifierPage()
    local shift = IsShiftKeyDown()
    local ctrl = IsControlKeyDown()

    if shift and ctrl then
        return 4  -- Shift+Ctrl
    elseif ctrl then
        return 3  -- Ctrl only
    elseif shift then
        return 2  -- Shift only
    else
        return 1  -- No modifiers (WoW handles stance swapping internally)
    end
end

function ActionBars:CheckModifiers()
    local newPage = self:GetCurrentModifierPage()
    
    if newPage ~= self.currentPage then
        -- Clear all active states from previous page before switching
        -- This prevents buttons from showing glow/flash from actions on the old page
        for i = 1, self.NUM_BUTTONS do
            local button = getglobal("ConsoleActionButton"..i)
            if button then
                -- Stop flashing (red overlay) - reset state completely
                button.flashing = 0
                button.flashtime = 0
                local flash = getglobal(button:GetName().."Flash")
                if flash then
                    flash:Hide()
                end
                
                -- Force hide active glow/border when switching pages
                if button.activeFrame then
                    button.activeFrame.glow:Hide()
                    if button.activeFrame.border then
                        button.activeFrame.border:Hide()
                    end
                end
                
                -- Reset checked state
                button:SetChecked(0)
            end
        end
        
        self.currentPage = newPage
        -- Force full update of all buttons when page changes
        -- This ensures icons, cooldowns, states, etc. are all refreshed
        self:UpdateAllButtons()
        -- Debug message (optional)
        -- DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CE]|r Switched to page " .. newPage)
    end
end

function ActionBars:GetActionOffset()
    -- If using modifier keys (pages 2-4), use those offsets
    if self.currentPage > 1 then
        return self.PAGE_OFFSETS[self.currentPage] or self.PAGE_OFFSETS[1]
    end
    
    -- For page 1 (no modifier), check for bonus bar (stances/forms)
    -- Warriors: Battle=1, Defensive=2, Berserker=3
    -- Druids: Cat=1, Aquatic=2, Bear=3, Travel=4, Moonkin=5
    -- Rogues: Stealth=1
    local bonusBar = GetBonusBarOffset()
    CE_Debug("GetActionOffset: bonusBar=" .. tostring(bonusBar) .. ", currentPage=" .. tostring(self.currentPage))
    
    -- Check for druid forms that don't use bonus bars (like Travel Form, Aquatic Form)
    local _, class = UnitClass("player")
    if class == "DRUID" then
        local currentForm = self:GetCurrentDruidForm()
        if currentForm then
            local formLower = string.lower(currentForm)
            CE_Debug("GetActionOffset: Current form: " .. currentForm)
            
            -- Travel form doesn't use a bonus bar, but we want to use travel form bar slots
            if string.find(formLower, "travel") then
                CE_Debug("GetActionOffset: Using travel form bar (bonus bar 4)")
                return self.BONUS_BAR_BASE + (4 * 12)
            end
            
            -- Aquatic form doesn't use a bonus bar, but we want to use aquatic form bar slots
            if string.find(formLower, "aquatic") then
                CE_Debug("GetActionOffset: Using aquatic form bar (bonus bar 2)")
                return self.BONUS_BAR_BASE + (2 * 12)
            end
        end
    end
    
    if bonusBar and bonusBar > 0 then
        -- Check if druid stealth feature is enabled and druid is in cat form with stealth
        -- When enabled, use travel form bar (bonus bar 4) instead of cat form bar (bonus bar 1)
        local useDruidStealth = false
        if ConsoleExperience.config and ConsoleExperience.config.Get then
            useDruidStealth = ConsoleExperience.config:Get("druidStealth") or false
        elseif ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.druidStealth then
            useDruidStealth = ConsoleExperienceDB.config.druidStealth
        end
        
        if useDruidStealth and bonusBar == 1 then
            local isStealth = self:IsCatStealth()
            if isStealth then
                -- In cat form with stealth active, use travel form bar (bonus bar 4)
                CE_Debug("GetActionOffset: Using travel form bar (stealth active)")
                return self.BONUS_BAR_BASE + (4 * 12)
            end
        end
        
        -- Bonus bar slots start at 73 (offset 72)
        -- Formula: 60 + (bonusBar * 12) = offset for first slot
        -- But we use 10 buttons, so: 60 + (bonusBar * 12)
        return self.BONUS_BAR_BASE + (bonusBar * 12)
    end
    
    -- No bonus bar active, use page 1 (slots 1-10)
    return self.PAGE_OFFSETS[1]
end

-- ============================================================================
-- Hide Default Action Bars
-- ============================================================================

function ActionBars:HideDefaultBars()
    -- Main action bar and related frames
    if MainMenuBar then MainMenuBar:Hide() end
    if MainMenuBarArtFrame then MainMenuBarArtFrame:Hide() end
    -- Hide exp bar
    if MainMenuExpBar then MainMenuExpBar:Hide() end
    if MainMenuBarMaxLevelBar then MainMenuBarMaxLevelBar:Hide() end
    -- Hide reputation bar
    if ReputationWatchBar then ReputationWatchBar:Hide() end
    if MainMenuBarPerformanceBarFrame then MainMenuBarPerformanceBarFrame:Hide() end
    
    -- Bottom left/right multi bars
    if MultiBarBottomLeft then MultiBarBottomLeft:Hide() end
    if MultiBarBottomRight then MultiBarBottomRight:Hide() end
    
    -- Side multi bars
    if MultiBarLeft then MultiBarLeft:Hide() end
    if MultiBarRight then MultiBarRight:Hide() end
    
    -- Bonus action bar (shapeshifting, stealth, etc)
    if BonusActionBarFrame then BonusActionBarFrame:Hide() end
    
    -- Shapeshift/stance bar
    if ShapeshiftBarFrame then ShapeshiftBarFrame:Hide() end
    
    -- Pet action bar
    if PetActionBarFrame then PetActionBarFrame:Hide() end
    
    -- Bag bar (will be shown/hidden dynamically when bags are opened)
    -- Don't hide here - managed by InitializeBagBar
    
    -- Micro menu buttons
    if CharacterMicroButton then CharacterMicroButton:Hide() end
    if SpellbookMicroButton then SpellbookMicroButton:Hide() end
    if TalentMicroButton then TalentMicroButton:Hide() end
    if QuestLogMicroButton then QuestLogMicroButton:Hide() end
    if SocialsMicroButton then SocialsMicroButton:Hide() end
    if WorldMapMicroButton then WorldMapMicroButton:Hide() end
    if MainMenuMicroButton then MainMenuMicroButton:Hide() end
    if HelpMicroButton then HelpMicroButton:Hide() end
end

-- ============================================================================
-- Action Button Functions
-- ============================================================================

function ActionBars:GetActionID(button)
    local id = button:GetID()
    if id == 0 then
        -- Extract ID from button name
        local name = button:GetName()
        id = tonumber(string.sub(name, 20)) -- "ConsoleActionButton" = 19 chars
    end
    return self:GetActionOffset() + id
end

function ActionBars:ButtonOnLoad(button)
    local id = button:GetID()
    if id == 0 then
        local name = button:GetName()
        id = tonumber(string.sub(name, 20))
        button:SetID(id)
    end
    
    -- Initialize button state
    button.flashing = 0
    button.flashtime = 0
    button.rangeTimer = nil
    button.updateTooltip = nil
    
    -- Vertex state tracking (like pfUI: 0=normal, 1=out of range, 2=oom, 3=not usable)
    button.vertexstate = 0
    button.outofrange = nil
    
    -- Create active state glow frame (for casting indicator)
    local activeFrameName = button:GetName().."Active"
    local activeFrame = getglobal(activeFrameName)
    if not activeFrame then
        activeFrame = CreateFrame("Frame", activeFrameName, button)
        activeFrame:SetAllPoints(button)
        activeFrame:SetFrameLevel(button:GetFrameLevel() + 1)
        
        -- Create colored border overlay (like pfUI's active indicator)
        local border = activeFrame:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(button)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:Hide()
        activeFrame.border = border
        
        -- Create glow overlay using CheckButtonHilight texture
        local glow = activeFrame:CreateTexture(nil, "OVERLAY")
        glow:SetAllPoints(button)
        glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0.6)
        glow:Hide()
        activeFrame.glow = glow
        
        button.activeFrame = activeFrame
    end
    
    -- Create cooldown frame if it doesn't exist
    local cooldownName = button:GetName().."Cooldown"
    local cooldown = getglobal(cooldownName)
    if not cooldown then
        cooldown = CreateFrame("Model", cooldownName, button, "CooldownFrameTemplate")
        -- Cooldown will be sized in UpdateActionBarLayout to match button
        -- Use SetAllPoints to fill the button
        cooldown:SetAllPoints(button)
    end
    
    -- Set controller icon
    local controllerIcon = getglobal(button:GetName().."ControllerIcon")
    if controllerIcon then
        local buttonIcons = self:GetButtonIcons()
        if buttonIcons[id] then
            controllerIcon:SetTexture(buttonIcons[id])
        end
    end
    
    -- Register for drag and click
    button:RegisterForDrag("LeftButton", "RightButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Register events
    button:RegisterEvent("PLAYER_ENTERING_WORLD")
    button:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    button:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    button:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    button:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    button:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    button:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    button:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    button:RegisterEvent("PLAYER_ENTER_COMBAT")
    button:RegisterEvent("PLAYER_LEAVE_COMBAT")
    button:RegisterEvent("PLAYER_AURAS_CHANGED")
    button:RegisterEvent("PLAYER_TARGET_CHANGED")
    button:RegisterEvent("START_AUTOREPEAT_SPELL")
    button:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    button:RegisterEvent("UNIT_INVENTORY_CHANGED")
    button:RegisterEvent("UPDATE_INVENTORY_ALERTS")
end

function ActionBars:UpdateButton(button)
    local actionID = self:GetActionID(button)
    local buttonID = button:GetID()
    local icon = getglobal(button:GetName().."Icon")
    local cooldown = getglobal(button:GetName().."Cooldown")
    local texture = GetActionTexture(actionID)
    
    -- Check if D-pad buttons (5, 6, 7, 8) should be hidden in healer mode
    -- Only hide base D-pad buttons on page 1 (no modifiers), and only when in party/raid
    -- Modified D-pad buttons (Shift/Ctrl) should remain visible
    local shouldHideDPad = false
    if buttonID >= 5 and buttonID <= 8 then
        -- Only hide on page 1 (no modifiers)
        local currentPage = self.currentPage or 1
        if currentPage == 1 then
            local config = ConsoleExperience.config
            local healerMode = false
            if config and config.Get then
                healerMode = config:Get("healerMode") or false
            end
            
            if healerMode then
                -- Check if player is in party or raid
                local inParty = GetNumPartyMembers() > 0
                local inRaid = GetNumRaidMembers() > 0
                
                if inParty or inRaid then
                    -- Hide D-pad buttons when in healer mode and in party/raid (page 1 only)
                    shouldHideDPad = true
                end
            end
        end
    end
    
    -- Update controller icon based on current controller type
    local controllerIcon = getglobal(button:GetName().."ControllerIcon")
    if controllerIcon then
        local buttonIcons = self:GetButtonIcons()
        if buttonIcons[buttonID] then
            controllerIcon:SetTexture(buttonIcons[buttonID])
        end
    end
    
    -- Check for proxied actions (like JUMP, AUTORUN, etc.)
    -- These are WoW bindings assigned to controller buttons instead of action bar slots
    local proxiedAction = nil
    local actionSlot = self:GetActionOffset() + buttonID
    
    if ConsoleExperience.proxied and ConsoleExperience.proxied.IsSlotProxied then
        if ConsoleExperience.proxied:IsSlotProxied(actionSlot) then
            proxiedAction = ConsoleExperience.proxied:GetSlotActionInfo(actionSlot)
        end
    end
    
    -- Get appearance setting
    local appearance = "classic"
    if ConsoleExperience.config and ConsoleExperience.config.Get then
        appearance = ConsoleExperience.config:Get("barAppearance") or "classic"
    elseif ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.barAppearance then
        appearance = ConsoleExperienceDB.config.barAppearance
    end
    
    -- Determine normal texture based on appearance
    local normalTexture = "Interface\\Buttons\\UI-Quickslot2"
    local emptyTexture = "Interface\\Buttons\\UI-Quickslot"
    
    -- If slot has a proxied action, show that icon (priority over action slot)
    if proxiedAction then
        icon:SetTexture(proxiedAction.icon)
        icon:Show()
        button.rangeTimer = nil
        button.isProxiedAction = proxiedAction
        cooldown:Hide()
        -- Stop any flashing/glow effects since this is a proxied action, not an action slot
        self:StopFlash(button)
        button:SetChecked(0)
    elseif texture then
        icon:SetTexture(texture)
        icon:Show()
        button.isProxiedAction = nil
        
        -- Reset range state when updating button
        -- Use -1 to force UpdateButtonUsable to refresh colors (since valid states are 0-3)
        button.outofrange = nil
        button.vertexstate = -1
        
        self:UpdateButtonState(button)
        self:UpdateButtonUsable(button)
        self:UpdateButtonCooldown(button)
        self:UpdateButtonCount(button)
        self:UpdateButtonFlash(button)
        
        -- Initialize range timer for range checking (only if action has range)
        if HasAction(actionID) and ActionHasRange(actionID) then
            button.rangeTimer = self.RANGE_CHECK_TIME
        else
            button.rangeTimer = nil
        end
    else
        icon:Hide()
        cooldown:Hide()
        button.rangeTimer = nil
        button.isProxiedAction = nil
        -- Reset color state for empty slots
        button.outofrange = nil
        button.vertexstate = -1
        -- Reset colors to normal (white) for normalTexture and overlay
        local normalTexture = getglobal(button:GetName().."NormalTexture")
        local overlay = getglobal(button:GetName().."Overlay")
        if normalTexture then
            normalTexture:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        end
        if overlay then
            overlay:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        end
    end
    
    -- Apply button appearance styling after updating button content
    -- This handles normal texture, icon sizing/positioning, overlay, flash, etc.
    self:ApplyButtonAppearance(button)
    
    -- Show or hide button based on healer mode
    if shouldHideDPad then
        button:Hide()
    else
        -- Always keep button visible so we can drop actions onto it
        button:Show()
    end
    
    -- Update equipped border (only if not a proxied action)
    local border = getglobal(button:GetName().."Border")
    if border then
        if button.isProxiedAction then
            -- Hide border for proxied actions
            border:Hide()
        elseif IsEquippedAction(actionID) then
            border:SetVertexColor(0, 1.0, 0, 0.35)
            border:Show()
        else
            border:Hide()
        end
    end
    
    -- Update tooltip if shown
    if GameTooltip:IsOwned(button) then
        self:SetButtonTooltip(button)
    end
    
    -- Update macro name
    local macroName = getglobal(button:GetName().."Name")
    if macroName then
        if button.isProxiedAction then
            macroName:SetText(button.isProxiedAction.name)
        else
            macroName:SetText(GetActionText(actionID))
        end
    end
end

function ActionBars:ApplyButtonAppearance(button)
    -- Apply button appearance styling (modern/classic) based on config
    -- This function handles all visual styling, not just layout/positioning
    local appearance = "classic"
    if ConsoleExperience.config and ConsoleExperience.config.Get then
        appearance = ConsoleExperience.config:Get("barAppearance") or "classic"
    elseif ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.barAppearance then
        appearance = ConsoleExperienceDB.config.barAppearance
    end
    
    local buttonSize = button:GetWidth()
    if buttonSize == 0 then
        buttonSize = button:GetHeight()
    end
    if buttonSize == 0 then
        buttonSize = 40  -- Default fallback
    end
    
    local icon = getglobal(button:GetName() .. "Icon")
    local bg = getglobal(button:GetName() .. "Background")
    local normalTex = getglobal(button:GetName() .. "NormalTexture")
    local flash = getglobal(button:GetName() .. "Flash")
    local overlayName = button:GetName() .. "Overlay"
    local overlay = getglobal(overlayName)
    local controllerIcon = getglobal(button:GetName() .. "ControllerIcon")
    
    if appearance == "modern" then
        -- Modern: Create/show circular overlay texture (like Bartender2_Circled)
        local circularTexture = "Interface\\AddOns\\ConsoleExperienceClassic\\textures\\actionbars\\serenity"
        
        -- Create overlay texture if it doesn't exist
        if not overlay then
            overlay = button:CreateTexture(overlayName, "ARTWORK")
        end
        
        -- Configure overlay
        local overlaySize = buttonSize * 1.075  -- ~43px for 40px button
        overlay:SetTexture(circularTexture)
        overlay:SetWidth(overlaySize)
        overlay:SetHeight(overlaySize)
        overlay:ClearAllPoints()
        overlay:SetPoint("CENTER", button, "CENTER", -buttonSize * 0.02, 0)
        overlay:SetVertexColor(1.0, 1.0, 1.0, 1.0)
        overlay:Show()
        
        -- Hide square background
        if bg then
            bg:Hide()
        end
        
        -- Minimize normal texture
        if normalTex then
            normalTex:SetTexture(nil)
            normalTex:SetWidth(1)
            normalTex:SetHeight(1)
            normalTex:ClearAllPoints()
            normalTex:SetPoint("TOPLEFT", button, "TOPLEFT", -4, 4)
            button:SetNormalTexture(normalTex)
        end
        
        -- Update HighlightTexture
        local highlightTex = button:GetHighlightTexture()
        if highlightTex then
            highlightTex:SetVertexColor(75/255, 216/255, 241/255)
            highlightTex:SetTexture(circularTexture)
            highlightTex:SetWidth(overlaySize)
            highlightTex:SetHeight(overlaySize)
            highlightTex:ClearAllPoints()
            highlightTex:SetBlendMode("BLEND")
            highlightTex:SetPoint("CENTER", button, "CENTER", -buttonSize * 0.02, 0)
            button:SetHighlightTexture(highlightTex)
        end
        
        -- Update PushedTexture
        local pushedTex = button:GetPushedTexture()
        if pushedTex then
            pushedTex:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
            pushedTex:SetWidth(overlaySize * 0.88)
            pushedTex:SetHeight(overlaySize * 0.86)
            pushedTex:ClearAllPoints()
            if icon then
                pushedTex:SetPoint("CENTER", icon, "CENTER", 0, -1)
            end
            pushedTex:SetDrawLayer("HIGHLIGHT")
            pushedTex:SetBlendMode("ADD")
            button:SetPushedTexture(pushedTex)
        end
        
        -- Update CheckedTexture - use circular serenity texture
        local checkedTex = button:GetCheckedTexture()
        if checkedTex then
            checkedTex:SetTexture("Interface\\AddOns\\ConsoleExperienceClassic\\textures\\actionbars\\serenity")
            checkedTex:SetVertexColor(1, 1, 0.3, 0.8)  -- Yellow/gold glow
            checkedTex:SetWidth(overlaySize)
            checkedTex:SetHeight(overlaySize)
            checkedTex:ClearAllPoints()
            checkedTex:SetPoint("CENTER", button, "CENTER", -buttonSize * 0.02, 0)
            checkedTex:SetDrawLayer("OVERLAY")
            checkedTex:SetBlendMode("ADD")
            button:SetCheckedTexture(checkedTex)
        end
        
        -- Icon size and position for modern
        if icon then
            icon:SetWidth(buttonSize * 0.84)
            icon:SetHeight(buttonSize * 0.84)
            icon:ClearAllPoints()
            -- Move icon slightly to the left (negative X offset)
            icon:SetPoint("CENTER", button, "CENTER", -buttonSize * 0.02, 0)
            icon:SetTexCoord(0.12, 0.88, 0.12, 0.88)
        end
        
        -- Flash texture (red overlay when attacking) - use circular texture
        if flash then
            -- Use the same serenity texture with red color for circular flash
            flash:SetTexture("Interface\\AddOns\\ConsoleExperienceClassic\\textures\\actionbars\\serenity")
            flash:SetVertexColor(1, 0, 0, 1)  -- Red color
            local flashSize = buttonSize * 0.85
            flash:SetWidth(flashSize)
            flash:SetHeight(flashSize)
            flash:ClearAllPoints()
            flash:SetPoint("CENTER", button, "CENTER", -buttonSize * 0.02, 0)
            flash:SetTexCoord(0, 1, 0, 1)
            flash:SetBlendMode("ADD")
        end

        -- Active frame glow/border - use circular textures for modern
        if button.activeFrame then
            local iconSize = buttonSize * 0.84
            local glowSize = iconSize * 1.15
            
            if button.activeFrame.glow then
                button.activeFrame.glow:SetTexture("Interface\\AddOns\\ConsoleExperienceClassic\\textures\\actionbars\\serenity")
                button.activeFrame.glow:SetWidth(glowSize)
                button.activeFrame.glow:SetHeight(glowSize)
                button.activeFrame.glow:ClearAllPoints()
                button.activeFrame.glow:SetPoint("CENTER", button, "CENTER", -buttonSize * 0.02, 0)
                button.activeFrame.glow:SetVertexColor(1, 1, 0.5, 0.8)  -- Yellow glow
            end
            
            if button.activeFrame.border then
                button.activeFrame.border:SetTexture("Interface\\AddOns\\ConsoleExperienceClassic\\textures\\actionbars\\serenity")
                button.activeFrame.border:SetWidth(glowSize)
                button.activeFrame.border:SetHeight(glowSize)
                button.activeFrame.border:ClearAllPoints()
                button.activeFrame.border:SetPoint("CENTER", button, "CENTER", -buttonSize * 0.02, 0)
            end
        end

        -- ControllerIcon - move to a high-level frame so it's above highlight
        if controllerIcon then
            local iconSize = math.max(12, buttonSize / 3)
            controllerIcon:SetWidth(iconSize)
            controllerIcon:SetHeight(iconSize)
            
            -- Create or get a frame to hold the controller icon above everything
            if not button.controllerIconFrame then
                local iconFrame = CreateFrame("Frame", button:GetName() .. "ControllerIconFrame", button)
                iconFrame:SetFrameLevel(button:GetFrameLevel() + 10)
                iconFrame:SetAllPoints(button)
                button.controllerIconFrame = iconFrame
            end
            -- Reparent the controller icon to the high-level frame
            controllerIcon:SetParent(button.controllerIconFrame)
            controllerIcon:SetDrawLayer("OVERLAY")
            controllerIcon:ClearAllPoints()
            controllerIcon:SetPoint("TOP", button, "TOP", 0, 0)
            controllerIcon:Show()
        end
    else
        -- Classic: Hide overlay, restore square textures
        if overlay then
            overlay:Hide()
        end
        
        -- Restore square background
        if bg then
            bg:SetTexture("Interface\\Buttons\\UI-Quickslot")
            bg:SetWidth(buttonSize * 1.6)
            bg:SetHeight(buttonSize * 1.6)
            bg:SetVertexColor(1, 1, 1, 1)
            bg:Show()
        end
        
        -- Restore normal texture
        if normalTex then
            normalTex:SetTexture("Interface\\Buttons\\UI-Quickslot2")
            normalTex:SetWidth(buttonSize * 1.6)
            normalTex:SetHeight(buttonSize * 1.6)
            normalTex:SetVertexColor(1, 1, 1, 1)
            normalTex:ClearAllPoints()
            normalTex:SetPoint("CENTER", button, "CENTER", 0, 0)
            normalTex:Show()
        end
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        
        -- Restore HighlightTexture
        local highlightTex = button:GetHighlightTexture()
        if highlightTex then
            highlightTex:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
            highlightTex:SetVertexColor(1, 1, 1, 1)
            highlightTex:SetBlendMode("ADD")
            highlightTex:SetAllPoints(button)
        end
        
        -- Restore PushedTexture
        local pushedTex = button:GetPushedTexture()
        if pushedTex then
            pushedTex:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
            pushedTex:SetAllPoints(button)
            pushedTex:SetDrawLayer("ARTWORK")
            pushedTex:SetBlendMode("BLEND")
        end
        
        -- Restore CheckedTexture
        local checkedTex = button:GetCheckedTexture()
        if checkedTex then
            checkedTex:SetTexture("Interface\\Buttons\\CheckButtonHilight")
            checkedTex:SetVertexColor(1, 1, 1, 1)  -- Reset to white
            checkedTex:SetAllPoints(button)
            checkedTex:SetDrawLayer("ARTWORK")
            checkedTex:SetBlendMode("ADD")
        end
        
        -- Icon size and position for classic
        if icon then
            icon:SetWidth(buttonSize - 4)
            icon:SetHeight(buttonSize - 4)
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", button, "CENTER", 0, 0)
            icon:SetTexCoord(0, 1, 0, 1)
        end
        
        -- Flash texture for classic
        if flash then
            flash:SetTexture("Interface\\Buttons\\UI-QuickslotRed")
            flash:SetVertexColor(1, 1, 1, 1)  -- Reset to white (no tint)
            flash:SetWidth(buttonSize - 4)
            flash:SetHeight(buttonSize - 4)
            flash:ClearAllPoints()
            flash:SetPoint("CENTER", button, "CENTER", 0, 0)
            flash:SetTexCoord(0, 1, 0, 1)
            flash:SetBlendMode("BLEND")  -- Reset blend mode
        end

        -- Active frame glow/border - restore square textures for classic
        if button.activeFrame then
            if button.activeFrame.glow then
                button.activeFrame.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
                button.activeFrame.glow:SetVertexColor(1, 1, 1, 0.6)
                button.activeFrame.glow:ClearAllPoints()
                button.activeFrame.glow:SetAllPoints(button)
            end
            
            if button.activeFrame.border then
                button.activeFrame.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                button.activeFrame.border:ClearAllPoints()
                button.activeFrame.border:SetAllPoints(button)
            end
        end

        -- ControllerIcon - move to a high-level frame so it's above highlight
        if controllerIcon then
            local iconSize = math.max(12, buttonSize / 3)
            controllerIcon:SetWidth(iconSize)
            controllerIcon:SetHeight(iconSize)
            
            -- Create or get a frame to hold the controller icon above everything
            if not button.controllerIconFrame then
                local iconFrame = CreateFrame("Frame", button:GetName() .. "ControllerIconFrame", button)
                iconFrame:SetFrameLevel(button:GetFrameLevel() + 10)
                iconFrame:SetAllPoints(button)
                button.controllerIconFrame = iconFrame
            end
            -- Reparent the controller icon to the high-level frame
            controllerIcon:SetParent(button.controllerIconFrame)
            controllerIcon:SetDrawLayer("OVERLAY")
            controllerIcon:ClearAllPoints()
            controllerIcon:SetPoint("TOP", button, "TOP", 0, 0)
            controllerIcon:Show()
        end
    end
end

function ActionBars:UpdateButtonState(button)
    local actionID = self:GetActionID(button)
    local active = IsCurrentAction(actionID) or IsAutoRepeatAction(actionID)
    
    if active then
        button:SetChecked(1)
        
        -- Show active glow/border (casting indicator)
        if button.activeFrame then
            button.activeFrame.glow:Show()
            if button.activeFrame.border then
                -- Get class color for border (like pfUI)
                local _, class = UnitClass("player")
                local color = RAID_CLASS_COLORS[class]
                if color then
                    button.activeFrame.border:SetVertexColor(color.r, color.g, color.b, 1.0)
                else
                    button.activeFrame.border:SetVertexColor(1.0, 1.0, 0.5, 1.0) -- Default yellow
                end
                button.activeFrame.border:Show()
            end
        end
    else
        button:SetChecked(0)
        
        -- Hide active glow/border
        if button.activeFrame then
            button.activeFrame.glow:Hide()
            if button.activeFrame.border then
                button.activeFrame.border:Hide()
            end
        end
    end
end

function ActionBars:UpdateButtonUsable(button)
    local actionID = self:GetActionID(button)
    local icon = getglobal(button:GetName().."Icon")
    local normalTexture = getglobal(button:GetName().."NormalTexture")
    local overlay = getglobal(button:GetName().."Overlay")  -- Modern style overlay
    if not icon then return end
    
    local isUsable, notEnoughMana = IsUsableAction(actionID)
    local newVertexState = 0
    
    -- Check range first (if out of range, show red)
    if button.outofrange then
        newVertexState = 1
        if button.vertexstate ~= 1 then
            icon:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
            if normalTexture then
                normalTexture:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
            end
            if overlay then
                overlay:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
            end
            button.vertexstate = 1
        end
    -- Usable - Blizzard colors from constants
    elseif isUsable then
        newVertexState = 0
        if button.vertexstate ~= 0 then
            icon:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
            if normalTexture then
                normalTexture:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
            end
            if overlay then
                overlay:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
            end
            button.vertexstate = 0
        end
    -- Not enough mana - Blizzard colors from constants
    elseif notEnoughMana then
        newVertexState = 2
        if button.vertexstate ~= 2 then
            icon:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
            if normalTexture then
                normalTexture:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
            end
            if overlay then
                overlay:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
            end
            button.vertexstate = 2
        end
    -- Not usable - Blizzard behavior: icon gray, border white
    else
        newVertexState = 3
        if button.vertexstate ~= 3 then
            icon:SetVertexColor(self.NA_COLOR[1], self.NA_COLOR[2], self.NA_COLOR[3], self.NA_COLOR[4])
            if normalTexture then
                normalTexture:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
            end
            if overlay then
                overlay:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
            end
            button.vertexstate = 3
        end
    end
end

function ActionBars:UpdateButtonCooldown(button)
    local actionID = self:GetActionID(button)
    local cooldown = getglobal(button:GetName().."Cooldown")
    local start, duration, enable = GetActionCooldown(actionID)
    
    -- Hide default square cooldown - we use our own for both styles
    if cooldown then
        cooldown:Hide()
    end
    
    -- Use our cooldown (darkened icon + timer text) for both modern and classic
    if enable == 1 and duration > 0 then
        self:StartCircularCooldown(button, start, duration)
    else
        self:StopCircularCooldown(button)
    end
end

function ActionBars:UpdateButtonCount(button)
    local actionID = self:GetActionID(button)
    local count = getglobal(button:GetName().."Count")
    if count then
        if IsConsumableAction(actionID) then
            count:SetText(GetActionCount(actionID))
        else
            count:SetText("")
        end
    end
end

function ActionBars:UpdateButtonFlash(button)
    local actionID = self:GetActionID(button)
    if (IsAttackAction(actionID) and IsCurrentAction(actionID)) or IsAutoRepeatAction(actionID) then
        self:StartFlash(button)
    else
        self:StopFlash(button)
    end
end

function ActionBars:StartFlash(button)
    button.flashing = 1
    button.flashtime = 0
    self:UpdateButtonState(button)
end

function ActionBars:StopFlash(button)
    button.flashing = 0
    local flash = getglobal(button:GetName().."Flash")
    if flash then
        flash:Hide()
    end
    self:UpdateButtonState(button)
end

function ActionBars:IsFlashing(button)
    return button.flashing == 1
end

-- ============================================================================
-- Event Handler
-- ============================================================================

function ActionBars:ButtonOnEvent(button, event)
    local actionID = self:GetActionID(button)
    
    -- Skip action-related updates if button has a proxied action (like JUMP, AUTORUN)
    local hasProxiedAction = button.isProxiedAction ~= nil
    
    if event == "PLAYER_ENTERING_WORLD" then
        self:UpdateButton(button)
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        -- Check if this slot change affects any of our pages
        local buttonID = button:GetID()
        for page = 1, self.NUM_PAGES do
            local pageActionID = self.PAGE_OFFSETS[page] + buttonID
            if arg1 == -1 or arg1 == pageActionID then
                if page == self.currentPage then
                    self:UpdateButton(button)
                end
                break
            end
        end
    elseif event == "ACTIONBAR_UPDATE_STATE" then
        if not hasProxiedAction then
            self:UpdateButtonState(button)
        end
    elseif event == "ACTIONBAR_UPDATE_USABLE" then
        if not hasProxiedAction then
            self:UpdateButtonUsable(button)
        end
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "UPDATE_INVENTORY_ALERTS" then
        if not hasProxiedAction then
            self:UpdateButtonCooldown(button)
        end
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_AURAS_CHANGED" then
        self:UpdateButton(button)
        if not hasProxiedAction then
            self:UpdateButtonState(button)
            self:UpdateButtonUsable(button)
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then
            self:UpdateButton(button)
        end
    elseif event == "PLAYER_ENTER_COMBAT" then
        if not hasProxiedAction and IsAttackAction(actionID) then
            self:StartFlash(button)
        end
    elseif event == "PLAYER_LEAVE_COMBAT" then
        if not hasProxiedAction and IsAttackAction(actionID) then
            self:StopFlash(button)
        end
    elseif event == "START_AUTOREPEAT_SPELL" then
        if not hasProxiedAction and IsAutoRepeatAction(actionID) then
            self:StartFlash(button)
        end
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        if not hasProxiedAction and self:IsFlashing(button) and not IsAttackAction(actionID) then
            self:StopFlash(button)
        end
    elseif event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR" or event == "UPDATE_SHAPESHIFT_FORMS" then
        -- Stance or form changed - bonus bar offset changes
        -- Need to update all buttons since they now read from different slots
        -- Use a flag to only trigger once per event (all buttons receive the event)
        if not self._bonusBarUpdatePending then
            self._bonusBarUpdatePending = true
            
            local bonusBar = GetBonusBarOffset() or 0
            CE_Debug("Form changed - bonus bar: " .. bonusBar)
            
            -- Schedule update for next frame to batch all button updates
            if not self._bonusBarUpdateFrame then
                self._bonusBarUpdateFrame = CreateFrame("Frame")
                self._bonusBarUpdateFrame.actionBars = self  -- Store reference
                self._bonusBarUpdateFrame:SetScript("OnUpdate", function()
                    this:Hide()
                    this.actionBars._bonusBarUpdatePending = false
                    -- Force immediate update of all buttons
                    this.actionBars:UpdateAllButtons()
                end)
            end
            -- Show frame to trigger OnUpdate on next frame
            self._bonusBarUpdateFrame:Show()
            
            -- Also update immediately (in case OnUpdate doesn't fire fast enough)
            self:UpdateAllButtons()
        end
    end
end

-- ============================================================================
-- Update Handler (for flashing, range checking, tooltips)
-- ============================================================================

function ActionBars:ButtonOnUpdate(button, elapsed)
    local actionID = self:GetActionID(button)
    
    -- Don't flash if button has a proxied action (like JUMP, AUTORUN)
    if button.isProxiedAction then
        if self:IsFlashing(button) then
            self:StopFlash(button)
        end
    end
    
    -- Handle flashing (attack/auto-repeat) - skip if proxied action
    if not button.isProxiedAction and self:IsFlashing(button) then
        button.flashtime = button.flashtime - elapsed
        if button.flashtime <= 0 then
            local overtime = -button.flashtime
            if overtime >= self.FLASH_TIME then
                overtime = 0
            end
            button.flashtime = self.FLASH_TIME - overtime
            
            local flash = getglobal(button:GetName().."Flash")
            if flash then
                if flash:IsVisible() then
                    flash:Hide()
                else
                    flash:Show()
                end
            end
        end
    end
    
    -- Handle range checking (like pfUI)
    if button.rangeTimer then
        button.rangeTimer = button.rangeTimer - elapsed
        if button.rangeTimer <= 0 then
            -- Check if action has range and is out of range
            if HasAction(actionID) and ActionHasRange(actionID) then
                local inRange = IsActionInRange(actionID)
                if inRange == 0 then -- Out of range
                    if not button.outofrange then
                        button.outofrange = true
                        self:UpdateButtonUsable(button)
                    end
                else -- In range or nil (no target)
                    if button.outofrange then
                        button.outofrange = nil
                        self:UpdateButtonUsable(button)
                    end
                end
            else
                -- Action doesn't have range, clear out of range state
                if button.outofrange then
                    button.outofrange = nil
                    self:UpdateButtonUsable(button)
                end
            end
            
            -- Update hotkey color (legacy support)
            local hotkey = getglobal(button:GetName().."HotKey")
            if hotkey then
                if button.outofrange then
                    hotkey:SetVertexColor(1.0, 0.1, 0.1)
                else
                    hotkey:SetVertexColor(0.6, 0.6, 0.6)
                end
            end
            
            button.rangeTimer = self.RANGE_CHECK_TIME
        end
    end
    
    -- Handle tooltip updates
    if button.updateTooltip then
        button.updateTooltip = button.updateTooltip - elapsed
        if button.updateTooltip <= 0 then
            if GameTooltip:IsOwned(button) then
                self:SetButtonTooltip(button)
            else
                button.updateTooltip = nil
            end
        end
    end
end

-- ============================================================================
-- Healer Mode Helpers
-- ============================================================================

-- Get unit ID from a party/raid/player frame
function ActionBars:GetUnitFromFrame(frame)
    if not frame then 
        CE_Debug("GetUnitFromFrame: frame is nil")
        return nil 
    end
    
    local frameName = frame:GetName()
    if not frameName then 
        CE_Debug("GetUnitFromFrame: frame has no name")
        return nil 
    end
    
    CE_Debug("GetUnitFromFrame: Checking frame name: " .. frameName)
    
    -- Player frame
    if frameName == "PlayerFrame" then
        CE_Debug("GetUnitFromFrame: Matched PlayerFrame -> 'player'")
        return "player"
    end
    
    -- Party frames: PartyMemberFrame1, PartyMemberFrame2, etc.
    local partyStart, partyEnd, partyNumStr = string.find(frameName, "^PartyMemberFrame(%d+)$")
    if partyStart then
        local partyIndex = tonumber(partyNumStr)
        if partyIndex and partyIndex >= 1 and partyIndex <= 4 then
            -- Use GetPartyMember to check if party member exists, then construct unit ID
            local partyMemberIndex = GetPartyMember(partyIndex)
            if partyMemberIndex then
                -- GetPartyMember returns the index (e.g., "1"), construct unit ID as "party" + index
                local unit = "party" .. partyMemberIndex
                CE_Debug("GetUnitFromFrame: Matched PartyMemberFrame" .. partyIndex .. " -> GetPartyMember(" .. partyIndex .. ") = '" .. partyMemberIndex .. "', unit = '" .. unit .. "'")
                return unit
            else
                CE_Debug("GetUnitFromFrame: PartyMemberFrame" .. partyIndex .. " matched but GetPartyMember(" .. partyIndex .. ") returned nil")
            end
        end
    end
    
    -- Also check for PartyFrame1, PartyFrame2 (alternative naming)
    local partyFrameStart, partyFrameEnd, partyFrameNumStr = string.find(frameName, "^PartyFrame(%d+)$")
    if partyFrameStart then
        local partyIndex = tonumber(partyFrameNumStr)
        if partyIndex and partyIndex >= 1 and partyIndex <= 4 then
            -- Use GetPartyMember to check if party member exists, then construct unit ID
            local partyMemberIndex = GetPartyMember(partyIndex)
            if partyMemberIndex then
                -- GetPartyMember returns the index (e.g., "1"), construct unit ID as "party" + index
                local unit = "party" .. partyMemberIndex
                CE_Debug("GetUnitFromFrame: Matched PartyFrame" .. partyIndex .. " -> GetPartyMember(" .. partyIndex .. ") = '" .. partyMemberIndex .. "', unit = '" .. unit .. "'")
                return unit
            else
                CE_Debug("GetUnitFromFrame: PartyFrame" .. partyIndex .. " matched but GetPartyMember(" .. partyIndex .. ") returned nil")
            end
        end
    end
    
    -- Raid frames: RaidGroupButton1, RaidGroupButton2, etc.
    local raidStart, raidEnd, raidNumStr = string.find(frameName, "^RaidGroupButton(%d+)$")
    if raidStart then
        local raidIndex = tonumber(raidNumStr)
        if raidIndex and raidIndex >= 1 and raidIndex <= 40 then
            -- For raid, we can use "raid" .. raidIndex directly, but let's verify it exists
            local unit = "raid" .. raidIndex
            local unitName = UnitName(unit)
            if unitName then
                CE_Debug("GetUnitFromFrame: Matched RaidGroupButton" .. raidIndex .. " -> '" .. unit .. "' (name: " .. unitName .. ")")
                return unit
            else
                CE_Debug("GetUnitFromFrame: RaidGroupButton" .. raidIndex .. " matched but unit '" .. unit .. "' doesn't exist")
            end
        end
    end
    
    CE_Debug("GetUnitFromFrame: No match found for frame name: " .. frameName)
    return nil
end

-- Get spell name from action slot (using tooltip method like AutoRank)
function ActionBars:GetSpellNameFromSlot(slot)
    if not HasAction(slot) then return nil end
    
    -- Use tooltip to get spell name (same approach as AutoRank)
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetAction(slot)
    GameTooltip:Show()
    
    -- Get first line of tooltip (spell name)
    local tooltipText = getglobal("GameTooltipTextLeft1")
    if tooltipText and tooltipText:IsShown() then
        local spellName = tooltipText:GetText()
        if spellName and spellName ~= "" then
            GameTooltip:Hide()
            return spellName
        end
    end
    
    GameTooltip:Hide()
    return nil
end

-- Check if healer mode is enabled and cursor is over a party/raid/player frame
function ActionBars:ShouldCastOnHealerTarget()
    -- Check if healer mode is enabled
    local config = ConsoleExperience.config
    if not config or not config.Get then 
        CE_Debug("ShouldCastOnHealerTarget: Config not available")
        return false 
    end
    
    local healerMode = config:Get("healerMode")
    if not healerMode then 
        CE_Debug("ShouldCastOnHealerTarget: Healer mode disabled")
        return false 
    end
    
    CE_Debug("ShouldCastOnHealerTarget: Healer mode is enabled")
    
    -- Check if cursor is active and over a party/raid/player frame
    local Cursor = ConsoleExperience.cursor
    if not Cursor or not Cursor.navigationState then 
        CE_Debug("ShouldCastOnHealerTarget: Cursor not available")
        return false 
    end
    
    local currentButton = Cursor.navigationState.currentButton
    if not currentButton then 
        CE_Debug("ShouldCastOnHealerTarget: No current button")
        return false 
    end
    
    local frameName = currentButton:GetName()
    CE_Debug("ShouldCastOnHealerTarget: Current button name: " .. (frameName or "nil"))
    
    -- Check if current button is a party/raid/player frame
    local Hooks = ConsoleExperience.hooks
    if not Hooks or not Hooks.IsPartyRaidFrame then 
        CE_Debug("ShouldCastOnHealerTarget: Hooks not available")
        return false 
    end
    
    if not frameName then 
        CE_Debug("ShouldCastOnHealerTarget: Frame has no name")
        return false 
    end
    
    local isPartyRaidFrame = Hooks:IsPartyRaidFrame(frameName)
    CE_Debug("ShouldCastOnHealerTarget: IsPartyRaidFrame('" .. frameName .. "') = " .. tostring(isPartyRaidFrame))
    
    return isPartyRaidFrame
end

-- ============================================================================
-- Click and Drag Handlers
-- ============================================================================

function ActionBars:ButtonOnClick(button, mouseButton)
    -- Check if this is a protected proxied action (like JUMP, AUTORUN)
    -- Protected functions can only be executed via keyboard bindings, not mouse clicks in WoW 1.12
    if button.isProxiedAction then
        local bindingID = button.isProxiedAction.id
        if ConsoleExperience.proxied and ConsoleExperience.proxied.IsProtectedBinding then
            if ConsoleExperience.proxied:IsProtectedBinding(bindingID) then
                local actionName = button.isProxiedAction.name or bindingID or "proxied action"
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[ConsoleExperience]|r " .. actionName .. " can only be used via keyboard binding, not mouse click.")
                return
            end
            -- Non-protected proxied actions (like UI toggles) might work, but we'll let them try
            -- If they fail, it's not a protected function issue
        end
    end
    
    local buttonID = button:GetID()
    local bonusBar = GetBonusBarOffset() or 0
    local currentPage = self.currentPage or 0
    local offset = self:GetActionOffset()
    local actionID = offset + buttonID

    -- Debug output for stance issues
    CE_Debug("Click: Btn=" .. buttonID .. " Page=" .. currentPage .. " Bonus=" .. bonusBar .. " Off=" .. offset .. " Slot=" .. actionID .. " Has=" .. tostring(HasAction(actionID)))

    if MacroFrame_SaveMacro then
        MacroFrame_SaveMacro()
    end

    -- Check if healer mode is enabled and cursor is over a party/raid/player frame
    CE_Debug("ButtonOnClick: Checking healer mode, actionID=" .. actionID)
    if self:ShouldCastOnHealerTarget() then
        CE_Debug("ButtonOnClick: Healer mode check passed")
        local Cursor = ConsoleExperience.cursor
        local currentButton = Cursor.navigationState.currentButton
        CE_Debug("ButtonOnClick: Current button: " .. (currentButton and (currentButton:GetName() or "unnamed") or "nil"))
        
        local unit = self:GetUnitFromFrame(currentButton)
        CE_Debug("ButtonOnClick: Got unit from frame: " .. (unit or "nil"))
        
        if unit then
            -- Verify unit exists
            local unitName = UnitName(unit)
            CE_Debug("ButtonOnClick: Unit '" .. unit .. "' name: " .. (unitName or "nil"))
            
            -- Get spell name from action slot
            local spellName = self:GetSpellNameFromSlot(actionID)
            if spellName then
                CE_Debug("ButtonOnClick: Got spell name: " .. spellName)
                
                -- Save current target if we have one (and it's not the unit we want to cast on)
                local hadTarget = false
                if UnitName("target") and not UnitIsUnit("target", unit) then
                    hadTarget = true
                    CE_Debug("ButtonOnClick: Saving current target before casting")
                end
                
                -- Cast spell by name (this puts us in targeting mode)
                CE_Debug("ButtonOnClick: Calling CastSpellByName('" .. spellName .. "')")
                CastSpellByName(spellName)
                
                -- Target the unit
                CE_Debug("ButtonOnClick: Calling SpellTargetUnit('" .. unit .. "')")
                SpellTargetUnit(unit)
                
                -- Restore previous target if we had one
                if hadTarget then
                    CE_Debug("ButtonOnClick: Restoring previous target")
                    TargetLastTarget()
                end
                
                CE_Debug("ButtonOnClick: Healer mode: Casting " .. spellName .. " on " .. unit)
            else
                -- No spell name found, fall back to UseAction
                CE_Debug("ButtonOnClick: No spell name found, using UseAction")
                UseAction(actionID, 1)
                
                -- If spell is awaiting target selection, check if we can cast on the unit
                if SpellIsTargeting() then
                    CE_Debug("ButtonOnClick: Spell is targeting")
                    -- Check if the spell can target this unit
                    local canTarget = SpellCanTargetUnit(unit)
                    CE_Debug("ButtonOnClick: SpellCanTargetUnit('" .. unit .. "') = " .. tostring(canTarget))
                    
                    if canTarget then
                        -- Cast on the unit
                        CE_Debug("ButtonOnClick: Calling SpellTargetUnit('" .. unit .. "')")
                        SpellTargetUnit(unit)
                        CE_Debug("ButtonOnClick: Healer mode: Casting action " .. actionID .. " on " .. unit)
                    else
                        -- Can't target this unit, let it work normally
                        CE_Debug("ButtonOnClick: Healer mode: Cannot cast action " .. actionID .. " on " .. unit .. " (invalid target, using default behavior)")
                    end
                else
                    -- Spell doesn't require targeting (instant cast, self-buff, etc.)
                    CE_Debug("ButtonOnClick: Healer mode: Used action " .. actionID .. " (no targeting required)")
                end
            end
            
            -- Always update button state and return (action already used)
            self:UpdateButtonState(button)
            return
        else
            CE_Debug("ButtonOnClick: No unit found from frame")
        end
    else
        CE_Debug("ButtonOnClick: Healer mode check failed or not applicable")
    end

    -- Normal action use
    UseAction(actionID, 1)
    self:UpdateButtonState(button)
end

function ActionBars:ButtonOnDragStart(button)
    local actionID = self:GetActionID(button)
    PickupAction(actionID)
    self:UpdateButton(button)
end

function ActionBars:ButtonOnReceiveDrag(button)
    local actionID = self:GetActionID(button)
    PlaceAction(actionID)
    button:SetChecked(0)
    self:UpdateButton(button)
end

-- ============================================================================
-- Tooltip
-- ============================================================================

function ActionBars:SetButtonTooltip(button)
    local actionID = self:GetActionID(button)
    
    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, button)
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    end
    
    -- Check for proxied action
    if button.isProxiedAction then
        GameTooltip:SetText(button.isProxiedAction.name, 1, 1, 1)
        if button.isProxiedAction.desc then
            GameTooltip:AddLine(button.isProxiedAction.desc, 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("Bound to: " .. button.isProxiedAction.id, 0.5, 0.5, 0.5)
        GameTooltip:Show()
        button.updateTooltip = nil
    elseif GameTooltip:SetAction(actionID) then
        button.updateTooltip = self.TOOLTIP_UPDATE_TIME
    else
        button.updateTooltip = nil
    end
end

function ActionBars:ButtonOnEnter(button)
    self:SetButtonTooltip(button)
end

-- ============================================================================
-- Utility: Update all buttons
-- ============================================================================

function ActionBars:UpdateAllButtons()
    for i = 1, self.NUM_BUTTONS do
        local button = getglobal("ConsoleActionButton"..i)
        if button then
            self:UpdateButton(button)
        end
    end
end

-- ============================================================================
-- Bag Bar Management
-- ============================================================================

function ActionBars:InitializeBagBar()
    -- Bag bar buttons
    local bagBarButtons = {
        MainMenuBarBackpackButton,
        CharacterBag0Slot,
        CharacterBag1Slot,
        CharacterBag2Slot,
        CharacterBag3Slot,
        KeyRingButton
    }
    
    -- Hide bag bar initially
    self:UpdateBagBarVisibility()
    
    -- Create update frame to periodically check bag state
    if not self.bagBarUpdateFrame then
        self.bagBarUpdateFrame = CreateFrame("Frame")
        self.bagBarUpdateFrame:RegisterEvent("BAG_UPDATE")
        self.bagBarUpdateFrame:SetScript("OnEvent", function()
            ActionBars:UpdateBagBarVisibility()
        end)
        
        -- Also check periodically
        self.bagBarUpdateFrame:SetScript("OnUpdate", function()
            this.updateTimer = (this.updateTimer or 0) + arg1
            if this.updateTimer >= 0.2 then  -- Check every 200ms
                this.updateTimer = 0
                ActionBars:UpdateBagBarVisibility()
            end
        end)
    end
    
    -- Hook ContainerFrame OnShow/OnHide to detect bag open/close
    -- Check up to 5 container frames (backpack + 4 bags)
    for i = 1, 5 do
        local containerFrame = getglobal("ContainerFrame" .. i)
        if containerFrame then
            local oldOnShow = containerFrame:GetScript("OnShow")
            local oldOnHide = containerFrame:GetScript("OnHide")
            
            containerFrame:SetScript("OnShow", function()
                if oldOnShow then oldOnShow() end
                ActionBars:UpdateBagBarVisibility()
            end)
            
            containerFrame:SetScript("OnHide", function()
                if oldOnHide then oldOnHide() end
                ActionBars:UpdateBagBarVisibility()
            end)
        end
    end
    
    -- Hook bag bar buttons for cursor navigation
    for _, button in ipairs(bagBarButtons) do
        if button then
            -- Enable drag and drop
            button:RegisterForDrag("LeftButton")
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            
            -- Hook for cursor navigation
            if ConsoleExperience.hooks and ConsoleExperience.hooks.HookDynamicFrame then
                ConsoleExperience.hooks:HookDynamicFrame(button, "Bag Bar Button")
            end
        end
    end
end

function ActionBars:UpdateBagBarVisibility()
    -- Check if any bag is open (check up to 5 container frames)
    local anyBagOpen = false
    for i = 1, 5 do
        local containerFrame = getglobal("ContainerFrame" .. i)
        if containerFrame and containerFrame:IsVisible() then
            anyBagOpen = true
            break
        end
    end
    
    -- Also check using IsBagOpen if available
    if not anyBagOpen then
        for i = 0, 4 do
            if IsBagOpen and IsBagOpen(i) then
                anyBagOpen = true
                break
            end
        end
    end
    
    -- Show/hide and position bag bar at bottom right corner
    if anyBagOpen then
        -- Position bag bar at bottom right corner
        local buttonSize = 30  -- Approximate button size
        local spacing = 5  -- Spacing between buttons
        local bottomY = 20  -- Distance from bottom
        local rightX = 20  -- Distance from right
        
        -- Position buttons from right to left
        local currentX = rightX
        
        -- Backpack button (rightmost)
        if MainMenuBarBackpackButton then 
            MainMenuBarBackpackButton:SetParent(UIParent)
            MainMenuBarBackpackButton:ClearAllPoints()
            MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            MainMenuBarBackpackButton:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        -- Bag slots (right to left: bag 3, 2, 1, 0)
        if CharacterBag3Slot then 
            CharacterBag3Slot:SetParent(UIParent)
            CharacterBag3Slot:ClearAllPoints()
            CharacterBag3Slot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            CharacterBag3Slot:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        if CharacterBag2Slot then 
            CharacterBag2Slot:SetParent(UIParent)
            CharacterBag2Slot:ClearAllPoints()
            CharacterBag2Slot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            CharacterBag2Slot:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        if CharacterBag1Slot then 
            CharacterBag1Slot:SetParent(UIParent)
            CharacterBag1Slot:ClearAllPoints()
            CharacterBag1Slot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            CharacterBag1Slot:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        if CharacterBag0Slot then 
            CharacterBag0Slot:SetParent(UIParent)
            CharacterBag0Slot:ClearAllPoints()
            CharacterBag0Slot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            CharacterBag0Slot:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        -- Keyring button (leftmost)
        if KeyRingButton then 
            KeyRingButton:SetParent(UIParent)
            KeyRingButton:ClearAllPoints()
            KeyRingButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            KeyRingButton:Show()
        end
    else
        if MainMenuBarBackpackButton then MainMenuBarBackpackButton:Hide() end
        if CharacterBag0Slot then CharacterBag0Slot:Hide() end
        if CharacterBag1Slot then CharacterBag1Slot:Hide() end
        if CharacterBag2Slot then CharacterBag2Slot:Hide() end
        if CharacterBag3Slot then CharacterBag3Slot:Hide() end
        if KeyRingButton then KeyRingButton:Hide() end
    end
end

-- ============================================================================
-- Global wrapper functions for XML callbacks
-- These are required because WoW 1.12 XML uses 'this' keyword
-- ============================================================================

function ConsoleActionButton_OnLoad()
    ConsoleExperience.actionbars:ButtonOnLoad(this)
end

function ConsoleActionButton_OnEvent(event)
    ConsoleExperience.actionbars:ButtonOnEvent(this, event)
end

function ConsoleActionButton_OnUpdate(elapsed)
    ConsoleExperience.actionbars:ButtonOnUpdate(this, elapsed)
end

function ConsoleActionButton_OnClick(mouseButton)
    ConsoleExperience.actionbars:ButtonOnClick(this, mouseButton)
end

function ConsoleActionButton_OnDragStart()
    ConsoleExperience.actionbars:ButtonOnDragStart(this)
end

function ConsoleActionButton_OnReceiveDrag()
    ConsoleExperience.actionbars:ButtonOnReceiveDrag(this)
end

function ConsoleActionButton_OnEnter()
    ConsoleExperience.actionbars:ButtonOnEnter(this)
end

-- ============================================================================
-- Side Action Bars (Touch Screen)
-- ============================================================================

-- Side bar action slot offsets (using slots 41-50, which are typically unused)
-- Left bar: slots 41-45 (CE_ACTION_41 to CE_ACTION_45)
-- Right bar: slots 46-50 (CE_ACTION_46 to CE_ACTION_50)
ActionBars.SIDE_BAR_LEFT_OFFSET = 40   -- Slots 41-45
ActionBars.SIDE_BAR_RIGHT_OFFSET = 45  -- Slots 46-50

-- Storage for side bar buttons
ActionBars.sideBarLeftButtons = {}
ActionBars.sideBarRightButtons = {}
ActionBars.sideBarLeftFrame = nil
ActionBars.sideBarRightFrame = nil

function ActionBars:CreateSideBarButton(parent, buttonIndex, side)
    local offset = side == "left" and self.SIDE_BAR_LEFT_OFFSET or self.SIDE_BAR_RIGHT_OFFSET
    local actionSlot = offset + buttonIndex
    local buttonName = "CESideBar" .. side .. "Button" .. buttonIndex
    
    -- Create button frame
    local button = CreateFrame("CheckButton", buttonName, parent)
    button:SetWidth(40)
    button:SetHeight(40)
    button.actionSlot = actionSlot
    button.sideBarIndex = buttonIndex
    button.sideBarSide = side
    
    -- Background texture
    local background = button:CreateTexture(buttonName .. "Background", "BACKGROUND")
    background:SetTexture("Interface\\Buttons\\UI-Quickslot")
    background:SetWidth(64)
    background:SetHeight(64)
    background:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.background = background
    
    -- Icon texture
    local icon = button:CreateTexture(buttonName .. "Icon", "BORDER")
    icon:SetWidth(36)
    icon:SetHeight(36)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.icon = icon
    
    -- Flash texture
    local flash = button:CreateTexture(buttonName .. "Flash", "ARTWORK")
    flash:SetTexture("Interface\\Buttons\\UI-QuickslotRed")
    flash:SetWidth(36)
    flash:SetHeight(36)
    flash:SetPoint("CENTER", button, "CENTER", 0, 0)
    flash:Hide()
    button.flash = flash
    
    -- Count text
    local count = button:CreateFontString(buttonName .. "Count", "ARTWORK", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.count = count
    
    -- Normal texture
    local normalTexture = button:CreateTexture(buttonName .. "NormalTexture")
    normalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    normalTexture:SetWidth(64)
    normalTexture:SetHeight(64)
    normalTexture:SetPoint("CENTER", button, "CENTER", 0, 0)
    button:SetNormalTexture(normalTexture)
    
    -- Pushed texture
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    
    -- Highlight texture
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    
    -- Checked texture
    button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
    
    -- Create cooldown frame
    local cooldown = CreateFrame("Model", buttonName .. "Cooldown", button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(button)
    button.cooldown = cooldown
    
    -- Initialize state
    button.flashing = 0
    button.flashtime = 0
    button.rangeTimer = nil
    button.vertexstate = 0
    
    -- Register for clicks and drag
    button:RegisterForDrag("LeftButton", "RightButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Register events
    button:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    button:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    button:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    button:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    button:RegisterEvent("PLAYER_ENTER_COMBAT")
    button:RegisterEvent("PLAYER_LEAVE_COMBAT")
    button:RegisterEvent("UNIT_INVENTORY_CHANGED")
    
    -- Event handler
    button:SetScript("OnEvent", function()
        ActionBars:SideBarButtonOnEvent(this, event)
    end)
    
    -- Update handler
    button:SetScript("OnUpdate", function()
        ActionBars:SideBarButtonOnUpdate(this, arg1)
    end)
    
    -- Click handler
    button:SetScript("OnClick", function()
        ActionBars:SideBarButtonOnClick(this, arg1)
    end)
    
    -- Drag handlers
    button:SetScript("OnDragStart", function()
        if not IsShiftKeyDown() then return end
        PickupAction(this.actionSlot)
        ActionBars:UpdateSideBarButton(this)
    end)
    
    button:SetScript("OnReceiveDrag", function()
        PlaceAction(this.actionSlot)
        ActionBars:UpdateSideBarButton(this)
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function()
        -- Check for proxied action first
        if this.isProxiedAction then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(this.isProxiedAction.name, 1, 1, 1)
            if this.isProxiedAction.desc then
                GameTooltip:AddLine(this.isProxiedAction.desc, 0.7, 0.7, 0.7)
            end
            GameTooltip:AddLine("System Binding: " .. this.isProxiedAction.id, 0.5, 0.5, 0.5)
            GameTooltip:Show()
        elseif HasAction(this.actionSlot) then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetAction(this.actionSlot)
        end
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return button
end

function ActionBars:SideBarButtonOnEvent(button, event)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        if arg1 == 0 or arg1 == button.actionSlot then
            self:UpdateSideBarButton(button)
        end
    elseif event == "ACTIONBAR_UPDATE_STATE" or 
           event == "ACTIONBAR_UPDATE_USABLE" or
           event == "PLAYER_ENTER_COMBAT" or
           event == "PLAYER_LEAVE_COMBAT" or
           event == "UNIT_INVENTORY_CHANGED" then
        self:UpdateSideBarButton(button)
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
        self:UpdateSideBarButtonCooldown(button)
    end
end

function ActionBars:SideBarButtonOnUpdate(button, elapsed)
    -- Range check timer
    if button.rangeTimer then
        button.rangeTimer = button.rangeTimer - elapsed
        if button.rangeTimer <= 0 then
            local inRange = IsActionInRange(button.actionSlot)
            local normalTexture = getglobal(button:GetName() .. "NormalTexture")
            local overlay = getglobal(button:GetName() .. "Overlay")  -- Modern style overlay
            if inRange == 0 then
                -- Out of range: red color (using same constants as main action bar)
                button.icon:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
                if normalTexture then
                    normalTexture:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
                end
                if overlay then
                    overlay:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
                end
                button.outofrange = true
            else
                -- In range: check usability again to get correct color
                button.outofrange = nil
                local isUsable, notEnoughMana = IsUsableAction(button.actionSlot)
                if isUsable then
                    button.icon:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
                    if normalTexture then
                        normalTexture:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
                    end
                    if overlay then
                        overlay:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
                    end
                elseif notEnoughMana then
                    button.icon:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
                    if normalTexture then
                        normalTexture:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
                    end
                    if overlay then
                        overlay:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
                    end
                else
                    button.icon:SetVertexColor(self.NA_COLOR[1], self.NA_COLOR[2], self.NA_COLOR[3], self.NA_COLOR[4])
                    if normalTexture then
                        normalTexture:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
                    end
                    if overlay then
                        overlay:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
                    end
                end
            end
            button.rangeTimer = self.RANGE_CHECK_TIME
        end
    end
    
    -- Flashing
    if button.flashing == 1 then
        button.flashtime = button.flashtime - elapsed
        if button.flashtime <= 0 then
            if button.flash:IsVisible() then
                button.flash:Hide()
            else
                button.flash:Show()
            end
            button.flashtime = self.FLASH_TIME
        end
    end
end

function ActionBars:SideBarButtonOnClick(button, mouseButton)
    -- Check for proxied action first
    if button.isProxiedAction then
        local bindingID = button.isProxiedAction.id
        CE_Debug("SideBar: Executing proxied action: " .. bindingID)
        
        -- Execute the binding
        -- RunBinding() triggers the WoW binding action
        if RunBinding then
            RunBinding(bindingID)
        end
        return
    end
    
    -- Normal action bar slot behavior
    if mouseButton == "LeftButton" then
        if IsShiftKeyDown() and not CursorHasItem() then
            PickupAction(button.actionSlot)
        else
            UseAction(button.actionSlot, 0, 1)
        end
    elseif mouseButton == "RightButton" then
        UseAction(button.actionSlot, 1, 1)
    end
    self:UpdateSideBarButton(button)
end

function ActionBars:UpdateSideBarButton(button)
    local actionSlot = button.actionSlot
    
    -- Check for proxied actions (like JUMP, AUTORUN, etc.)
    local proxiedAction = nil
    if ConsoleExperience.proxied and ConsoleExperience.proxied.IsSlotProxied then
        if ConsoleExperience.proxied:IsSlotProxied(actionSlot) then
            proxiedAction = ConsoleExperience.proxied:GetSlotActionInfo(actionSlot)
        end
    end
    
    -- Store proxied action on button for click handler
    button.isProxiedAction = proxiedAction
    
    local normalTexture = getglobal(button:GetName() .. "NormalTexture")
    local overlay = getglobal(button:GetName() .. "Overlay")  -- Modern style overlay
    
    -- If slot has a proxied action, show that icon (priority over action slot)
    if proxiedAction then
        button.icon:SetTexture(proxiedAction.icon)
        button.icon:Show()
        button:SetAlpha(1.0)
        button.rangeTimer = nil
        button.cooldown:Hide()
        button:SetChecked(0)
        -- Normal colors for proxied actions
        button.icon:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        if normalTexture then
            normalTexture:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        end
        if overlay then
            overlay:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        end
        -- Hide count for proxied actions
        button.count:Hide()
        return
    end
    
    local texture = GetActionTexture(actionSlot)
    
    if texture then
        button.icon:SetTexture(texture)
        button.icon:Show()
        button:SetAlpha(1.0)
    else
        button.icon:Hide()
        button:SetAlpha(0.5)
    end
    
    -- Update count
    local count = GetActionCount(actionSlot)
    if count > 1 then
        button.count:SetText(count)
        button.count:Show()
    else
        button.count:Hide()
    end
    
    -- Update usable state - exact Blizzard behavior (using same constants as main action bar)
    local isUsable, notEnoughMana = IsUsableAction(actionSlot)
    
    -- Check range first (if out of range, show red)
    if button.outofrange then
        button.icon:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
        if normalTexture then
            normalTexture:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
        end
        if overlay then
            overlay:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
        end
    elseif isUsable then
        -- Usable: icon white, border white
        button.icon:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        if normalTexture then
            normalTexture:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        end
        if overlay then
            overlay:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        end
    elseif notEnoughMana then
        -- Not enough mana: icon blue, border blue
        button.icon:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
        if normalTexture then
            normalTexture:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
        end
        if overlay then
            overlay:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
        end
    else
        -- Not usable: icon gray, border white (Blizzard behavior)
        button.icon:SetVertexColor(self.NA_COLOR[1], self.NA_COLOR[2], self.NA_COLOR[3], self.NA_COLOR[4])
        if normalTexture then
            normalTexture:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        end
        if overlay then
            overlay:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
        end
    end
    
    -- Update cooldown
    self:UpdateSideBarButtonCooldown(button)
    
    -- Update checked state (for auto-attack, etc)
    if IsCurrentAction(actionSlot) or IsAutoRepeatAction(actionSlot) then
        button:SetChecked(1)
    else
        button:SetChecked(0)
    end
    
    -- Start range timer if action has range
    if ActionHasRange(actionSlot) then
        button.rangeTimer = self.RANGE_CHECK_TIME
    else
        button.rangeTimer = nil
    end
end

function ActionBars:UpdateSideBarButtonCooldown(button)
    local start, duration, enable = GetActionCooldown(button.actionSlot)
    
    -- Hide default square cooldown - we use our own for both styles
    if button.cooldown then
        button.cooldown:Hide()
    end
    
    -- Use our cooldown (darkened icon + timer text) for both modern and classic
    if enable > 0 and duration > 0 and start > 0 then
        self:StartCircularCooldown(button, start, duration)
    else
        self:StopCircularCooldown(button)
    end
end

function ActionBars:CreateSideBars()
    local config = ConsoleExperience.config
    if not config then return end
    
    local buttonSize = config:Get("barButtonSize") or 40
    local padding = 5
    
    -- Create left side bar frame
    if not self.sideBarLeftFrame then
        self.sideBarLeftFrame = CreateFrame("Frame", "CESideBarLeft", UIParent)
        self.sideBarLeftFrame:SetFrameStrata("MEDIUM")
    end
    
    -- Create right side bar frame
    if not self.sideBarRightFrame then
        self.sideBarRightFrame = CreateFrame("Frame", "CESideBarRight", UIParent)
        self.sideBarRightFrame:SetFrameStrata("MEDIUM")
    end
    
    -- Create/update buttons
    self:UpdateSideBars()
end

function ActionBars:UpdateSideBars()
    local config = ConsoleExperience.config
    if not config then return end
    
    local buttonSize = config:Get("barButtonSize") or 60
    local padding = config:Get("barPadding") or 65
    local scale = config:Get("barScale") or 1.0
    local appearance = config:Get("barAppearance") or "classic"
    local leftEnabled = config:Get("sideBarLeftEnabled")
    local rightEnabled = config:Get("sideBarRightEnabled")
    local leftCount = config:Get("sideBarLeftButtons") or 3
    local rightCount = config:Get("sideBarRightButtons") or 3
    local scaledButtonSize = buttonSize * scale  -- The actual space occupied by the scaled button
    
    -- Clamp counts
    if leftCount < 1 then leftCount = 1 end
    if leftCount > 5 then leftCount = 5 end
    if rightCount < 1 then rightCount = 1 end
    if rightCount > 5 then rightCount = 5 end
    
    -- Release proxied actions for hidden/disabled sidebar slots
    if ConsoleExperience.proxied and ConsoleExperience.proxied.ReleaseSidebarBindings then
        if leftEnabled then
            -- Release bindings for buttons beyond the current count
            ConsoleExperience.proxied:ReleaseSidebarBindings("left", leftCount)
        else
            -- Release all left sidebar bindings when disabled
            ConsoleExperience.proxied:ReleaseSidebarAllBindings("left")
        end
        
        if rightEnabled then
            -- Release bindings for buttons beyond the current count
            ConsoleExperience.proxied:ReleaseSidebarBindings("right", rightCount)
        else
            -- Release all right sidebar bindings when disabled
            ConsoleExperience.proxied:ReleaseSidebarAllBindings("right")
        end
    end
    
    -- Ensure frames exist
    if not self.sideBarLeftFrame then
        self.sideBarLeftFrame = CreateFrame("Frame", "CESideBarLeft", UIParent)
        self.sideBarLeftFrame:SetFrameStrata("MEDIUM")
    end
    if not self.sideBarRightFrame then
        self.sideBarRightFrame = CreateFrame("Frame", "CESideBarRight", UIParent)
        self.sideBarRightFrame:SetFrameStrata("MEDIUM")
    end
    
    -- Helper function to update button appearance
    local function UpdateButtonAppearance(button)
        button:SetWidth(buttonSize)
        button:SetHeight(buttonSize)
        button:SetScale(scale)
        
        -- Update icon size
        if button.icon then
            if appearance == "modern" then
                button.icon:SetWidth(buttonSize * 0.84)
                button.icon:SetHeight(buttonSize * 0.84)
            else
                button.icon:SetWidth(buttonSize - 4)
                button.icon:SetHeight(buttonSize - 4)
            end
        end
        
        -- Update background size
        if button.background then
            button.background:SetWidth(buttonSize * 1.6)
            button.background:SetHeight(buttonSize * 1.6)
        end
        
        -- Update normal texture size
        local normalTex = getglobal(button:GetName() .. "NormalTexture")
        if normalTex then
            normalTex:SetWidth(buttonSize * 1.6)
            normalTex:SetHeight(buttonSize * 1.6)
        end
        
        -- Update flash size
        if button.flash then
            button.flash:SetWidth(buttonSize - 4)
            button.flash:SetHeight(buttonSize - 4)
        end
        
        -- Update cooldown size
        if button.cooldown then
            local defaultCooldownSize = 36
            local scaleFactor = buttonSize / defaultCooldownSize
            button.cooldown:SetScale(scaleFactor)
        end
        
        -- Apply button appearance styling
        if self.ApplyButtonAppearance then
            self:ApplyButtonAppearance(button)
        end
    end
    
    -- Update left side bar
    if leftEnabled then
        -- Use padding as center-to-center distance (same as main action bar)
        local totalHeight = padding * (leftCount - 1) + buttonSize
        self.sideBarLeftFrame:SetWidth(scaledButtonSize)
        self.sideBarLeftFrame:SetHeight(totalHeight)
        self.sideBarLeftFrame:SetScale(1.0)
        self.sideBarLeftFrame:ClearAllPoints()
        self.sideBarLeftFrame:SetPoint("LEFT", UIParent, "LEFT", 5, 0)
        self.sideBarLeftFrame:Show()
        
        -- Create/update buttons
        for i = 1, 5 do
            if i <= leftCount then
                if not self.sideBarLeftButtons[i] then
                    self.sideBarLeftButtons[i] = self:CreateSideBarButton(self.sideBarLeftFrame, i, "left")
                end
                local button = self.sideBarLeftButtons[i]
                UpdateButtonAppearance(button)
                button:ClearAllPoints()
                -- Position using padding as center-to-center distance, vertically centered
                local yOffset = -((i - 1) * padding)
                button:SetPoint("TOP", self.sideBarLeftFrame, "TOP", 0, yOffset)
                button:Show()
                self:UpdateSideBarButton(button)
            else
                if self.sideBarLeftButtons[i] then
                    self.sideBarLeftButtons[i]:Hide()
                end
            end
        end
    else
        self.sideBarLeftFrame:Hide()
        for i = 1, 5 do
            if self.sideBarLeftButtons[i] then
                self.sideBarLeftButtons[i]:Hide()
            end
        end
    end
    
    -- Update right side bar
    if rightEnabled then
        -- Use padding as center-to-center distance (same as main action bar)
        local totalHeight = padding * (rightCount - 1) + buttonSize
        self.sideBarRightFrame:SetWidth(scaledButtonSize)
        self.sideBarRightFrame:SetHeight(totalHeight)
        self.sideBarRightFrame:SetScale(1.0)
        self.sideBarRightFrame:ClearAllPoints()
        self.sideBarRightFrame:SetPoint("RIGHT", UIParent, "RIGHT", -5, 0)
        self.sideBarRightFrame:Show()
        
        -- Create/update buttons
        for i = 1, 5 do
            if i <= rightCount then
                if not self.sideBarRightButtons[i] then
                    self.sideBarRightButtons[i] = self:CreateSideBarButton(self.sideBarRightFrame, i, "right")
                end
                local button = self.sideBarRightButtons[i]
                UpdateButtonAppearance(button)
                button:ClearAllPoints()
                -- Position using padding as center-to-center distance, vertically centered
                local yOffset = -((i - 1) * padding)
                button:SetPoint("TOP", self.sideBarRightFrame, "TOP", 0, yOffset)
                button:Show()
                self:UpdateSideBarButton(button)
            else
                if self.sideBarRightButtons[i] then
                    self.sideBarRightButtons[i]:Hide()
                end
            end
        end
    else
        self.sideBarRightFrame:Hide()
        for i = 1, 5 do
            if self.sideBarRightButtons[i] then
                self.sideBarRightButtons[i]:Hide()
            end
        end
    end
end

function ActionBars:UpdateAllSideBarButtons()
    for i = 1, 5 do
        if self.sideBarLeftButtons[i] then
            self:UpdateSideBarButton(self.sideBarLeftButtons[i])
        end
        if self.sideBarRightButtons[i] then
            self:UpdateSideBarButton(self.sideBarRightButtons[i])
        end
    end
end
