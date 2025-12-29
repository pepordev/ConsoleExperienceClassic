--[[
    ConsoleExperienceClassic - Hooks Module
    
    Hooks into UI frames to enable cursor navigation
]]

-- Create hooks module namespace
ConsoleExperience.hooks = ConsoleExperience.hooks or {}
local Hooks = ConsoleExperience.hooks

-- List of frames to hook
Hooks.frames = {
    {frame = "GameMenuFrame", name = "Main Menu"},
    {frame = "CharacterFrame", name = "Character Frame"},
    {frame = "SpellBookFrame", name = "Spellbook"},
    {frame = "TalentFrame", name = "Talents"},
    {frame = "SkillFrame", name = "Skills"},
    {frame = "FriendsFrame", name = "Social Frame"},
    {frame = "WorldMapFrame", name = "World Map"},
    {frame = "TaxiFrame", name = "Flight Path"},
    {frame = "QuestLogFrame", name = "Quest Log"},
    {frame = "QuestFrame", name = "Quest Frame"},
    {frame = "QuestFrameGreetingPanel", name = "Quest Greeting"},
    {frame = "QuestFrameDetailPanel", name = "Quest Details"},
    {frame = "QuestFrameProgressPanel", name = "Quest Progress"},
    {frame = "QuestFrameRewardPanel", name = "Quest Reward"},
    {frame = "StaticPopup1", name = "Dialog 1"},
    {frame = "StaticPopup2", name = "Dialog 2"},
    {frame = "StaticPopup3", name = "Dialog 3"},
    {frame = "StaticPopup4", name = "Dialog 4"},
    {frame = "GossipFrame", name = "Gossip"},
    {frame = "GossipGreetingScrollFrame", name = "Gossip Scroll"},
    {frame = "ItemTextFrame", name = "Item Text"},
    {frame = "MerchantFrame", name = "Merchant"},
    {frame = "AuctionFrame", name = "Auction House"},
    {frame = "TradeFrame", name = "Trade"},
    {frame = "TradeSkillFrame", name = "Profession"},
    {frame = "ClassTrainerFrame", name = "Trainer"},
    {frame = "ContainerFrame1", name = "Bag 1"},
    {frame = "ContainerFrame2", name = "Bag 2"},
    {frame = "ContainerFrame3", name = "Bag 3"},
    {frame = "ContainerFrame4", name = "Bag 4"},
    {frame = "ContainerFrame5", name = "Bag 5"},
    {frame = "ContainerFrame6", name = "Bank Bag 1"},
    {frame = "ContainerFrame7", name = "Bank Bag 2"},
    {frame = "ContainerFrame8", name = "Bank Bag 3"},
    {frame = "ContainerFrame9", name = "Bank Bag 4"},
    {frame = "ContainerFrame10", name = "Bank Bag 5"},
    {frame = "ContainerFrame11", name = "Bank Bag 6"},
    {frame = "ContainerFrame12", name = "Bank Bag 7"},
    {frame = "LootFrame", name = "Loot"},
    {frame = "MailFrame", name = "Mail"},
    {frame = "OpenMailFrame", name = "Open Mail"},
    {frame = "BankFrame", name = "Bank"},
    {frame = "GroupLootFrame1", name = "Roll 1"},
    {frame = "GroupLootFrame2", name = "Roll 2"},
    {frame = "GroupLootFrame3", name = "Roll 3"},
    {frame = "GroupLootFrame4", name = "Roll 4"},
    {frame = "ConsoleExperienceConfigFrame", name = "Console Experience Config"},
    {frame = "ConsoleExperienceRadialMenu", name = "Radial Menu"},
    {frame = "ConsoleExperiencePlacementFrame", name = "Spell Placement"},
    {frame = "MacroFrame", name = "Macros"},
}

-- ============================================================================
-- Frame Hooking
-- ============================================================================

function Hooks:Initialize()
    -- Hook all existing frames
    local hookedCount = 0
    for _, frameInfo in ipairs(self.frames) do
        local frame = getglobal(frameInfo.frame)
        if frame then
            self:HookFrame(frame, frameInfo.name)
            hookedCount = hookedCount + 1
        end
    end
    
    -- Hook dropdown menus (DropDownList1, DropDownList2, etc.)
    self:HookDropdownMenus()
    
    -- Create event frame to hook load-on-demand frames
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("ADDON_LOADED")
        self.eventFrame:RegisterEvent("WORLD_MAP_UPDATE")
        self.eventFrame:RegisterEvent("TAXIMAP_OPENED")
        self.eventFrame:RegisterEvent("MAIL_SHOW")
        self.eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
        self.eventFrame:RegisterEvent("TRAINER_SHOW")
        self.eventFrame:SetScript("OnEvent", function()
            Hooks:TryHookPendingFrames()
        end)
    end
    
    CE_Debug("Hooks initialized for " .. hookedCount .. " frames.")
end

-- Hook dropdown menu frames (DropDownList1, DropDownList2, etc.)
function Hooks:HookDropdownMenus()
    -- Hook up to 10 dropdown lists (should be enough)
    for i = 1, 10 do
        local dropdownName = "DropDownList" .. i
        local dropdown = getglobal(dropdownName)
        if dropdown then
            self:HookDropdownFrame(dropdown)
        end
    end
    
    -- Also hook dynamically created dropdowns via OnUpdate check
    if not self.dropdownCheckFrame then
        self.dropdownCheckFrame = CreateFrame("Frame")
        self.dropdownCheckFrame:SetScript("OnUpdate", function()
            -- Check for dropdown lists every 0.1 seconds
            this.elapsed = (this.elapsed or 0) + arg1
            if this.elapsed > 0.1 then
                this.elapsed = 0
                Hooks:CheckForNewDropdowns()
            end
        end)
    end
end

-- Hook a specific dropdown frame
function Hooks:HookDropdownFrame(dropdown)
    if not dropdown or dropdown.ceHooked then return end
    
    local oldOnShow = dropdown:GetScript("OnShow")
    local oldOnHide = dropdown:GetScript("OnHide")
    
    dropdown:SetScript("OnShow", function()
        -- Run original OnShow first
        if oldOnShow then
            oldOnShow()
        end
        
        -- Add dropdown to active frames so its buttons are navigable
        local Cursor = ConsoleExperience.cursor
        Cursor.navigationState.activeFrames[dropdown] = true
        CE_Debug("Dropdown menu opened: " .. (dropdown:GetName() or "unnamed"))
        
        -- Ensure cursor appears above dropdown menu
        -- Get dropdown's frame level and set cursor higher
        local dropdownLevel = dropdown:GetFrameLevel()
        Cursor.frame:SetFrameLevel(dropdownLevel + 100)
        Cursor.highlight:SetFrameLevel(dropdownLevel + 99)
        
        -- Refresh button collection to include dropdown buttons
        Cursor:RefreshFrame()
        
        -- Move cursor to first dropdown button if available
        local firstButton = Cursor:FindFirstVisibleButton(dropdown)
        if firstButton then
            Cursor:MoveCursorToButton(firstButton)
        end
    end)
    
    dropdown:SetScript("OnHide", function()
        -- Run original OnHide first
        if oldOnHide then
            oldOnHide()
        end
        
        -- Remove dropdown from active frames
        local Cursor = ConsoleExperience.cursor
        Cursor.navigationState.activeFrames[dropdown] = nil
        CE_Debug("Dropdown menu closed: " .. (dropdown:GetName() or "unnamed"))
        
        -- Restore cursor frame levels to default
        Cursor.frame:SetFrameLevel(1001)
        Cursor.highlight:SetFrameLevel(1000)
        
        -- Refresh button collection
        Cursor:RefreshFrame()
        
        -- Move cursor back to the frame that opened the dropdown if available
        local mostRecentFrame = nil
        for activeFrame, _ in pairs(Cursor.navigationState.activeFrames) do
            if activeFrame:IsVisible() and activeFrame ~= dropdown then
                mostRecentFrame = activeFrame
                break
            end
        end
        
        if mostRecentFrame then
            local firstButton = Cursor:FindFirstVisibleButton(mostRecentFrame)
            if firstButton then
                Cursor:MoveCursorToButton(firstButton)
            end
        end
    end)
    
    dropdown.ceHooked = true
end

-- Check for newly created dropdown menus
function Hooks:CheckForNewDropdowns()
    for i = 1, 10 do
        local dropdownName = "DropDownList" .. i
        local dropdown = getglobal(dropdownName)
        if dropdown and not dropdown.ceHooked then
            self:HookDropdownFrame(dropdown)
        end
    end
end

-- Try to hook frames that weren't available at init time
function Hooks:TryHookPendingFrames()
    for _, frameInfo in ipairs(self.frames) do
        local frame = getglobal(frameInfo.frame)
        if frame and not frame.ceHooked then
            self:HookFrame(frame, frameInfo.name)
            CE_Debug("Late hook: " .. frameInfo.frame)
            
            -- If the frame is already visible, trigger OnShow
            if frame:IsVisible() then
                self:OnFrameShow(frame)
            end
        end
    end
    
    -- Special handling for WorldMapFrame - check if it's visible and not yet initialized
    local worldMap = getglobal("WorldMapFrame")
    if worldMap and worldMap:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[worldMap] then
            CE_Debug("WorldMapFrame detected visible, initializing cursor")
            self:OnFrameShow(worldMap)
        end
    end
    
    -- Special handling for TaxiFrame - check if it's visible and not yet initialized
    local taxiFrame = getglobal("TaxiFrame")
    if taxiFrame and taxiFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[taxiFrame] then
            CE_Debug("TaxiFrame detected visible, initializing cursor")
            self:OnFrameShow(taxiFrame)
        end
    end
    
    -- Special handling for OpenMailFrame - check if it's visible and not yet initialized
    local openMailFrame = getglobal("OpenMailFrame")
    if openMailFrame and openMailFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[openMailFrame] then
            CE_Debug("OpenMailFrame detected visible, initializing cursor")
            self:OnFrameShow(openMailFrame)
        end
    end
    
    -- Special handling for TradeSkillFrame - check if it's visible and not yet initialized
    local tradeSkillFrame = getglobal("TradeSkillFrame")
    if tradeSkillFrame and tradeSkillFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[tradeSkillFrame] then
            CE_Debug("TradeSkillFrame detected visible, initializing cursor")
            self:OnFrameShow(tradeSkillFrame)
        end
    end
    
    -- Special handling for ClassTrainerFrame - check if it's visible and not yet initialized
    local classTrainerFrame = getglobal("ClassTrainerFrame")
    if classTrainerFrame and classTrainerFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[classTrainerFrame] then
            CE_Debug("ClassTrainerFrame detected visible, initializing cursor")
            self:OnFrameShow(classTrainerFrame)
        end
    end
end

function Hooks:HookFrame(frame, frameName)
    if not frame or frame.ceHooked then return end
    
    local oldOnShow = frame:GetScript("OnShow")
    local oldOnHide = frame:GetScript("OnHide")
    
    frame:SetScript("OnShow", function()
        -- Run original OnShow first
        if oldOnShow then
            oldOnShow()
        end
        
        -- Initialize cursor on this frame
        Hooks:OnFrameShow(frame)
    end)
    
    frame:SetScript("OnHide", function()
        -- Run original OnHide first
        if oldOnHide then
            oldOnHide()
        end
        
        -- Handle frame hide
        Hooks:OnFrameHide(frame)
    end)
    
    frame.ceHooked = true
end

function Hooks:OnFrameShow(frame)
    if not frame then return end
    
    local frameName = frame:GetName() or "Unknown"
    CE_Debug("OnFrameShow: " .. frameName)
    
    local Cursor = ConsoleExperience.cursor
    
    -- Add to active frames
    Cursor.navigationState.activeFrames[frame] = true
    
    -- Special handling for WorldMapFrame - disable its keyboard capture
    if frameName == "WorldMapFrame" then
        frame:EnableKeyboard(false)
        CE_Debug("Disabled WorldMapFrame keyboard capture")
    end
    
    -- Special handling for TaxiFrame - disable its keyboard capture
    if frameName == "TaxiFrame" then
        frame:EnableKeyboard(false)
        CE_Debug("Disabled TaxiFrame keyboard capture")
    end
    
    -- Ensure cursor is on top
    Cursor:EnsureOnTop(frame)
    
    -- Find first visible button and move cursor to it
    local firstButton = Cursor:FindFirstVisibleButton(frame)
    
    if firstButton then
        CE_Debug("Found button: " .. (firstButton:GetName() or "unnamed"))
        Cursor:MoveCursorToButton(firstButton)
        
        -- Set up cursor navigation bindings
        if ConsoleExperience.cursor.keybindings then
            ConsoleExperience.cursor.keybindings:SetupCursorBindings()
        end
    else
        CE_Debug("No buttons found in " .. frameName)
        
        -- Still set up cursor bindings so user can navigate if buttons appear later
        if ConsoleExperience.cursor.keybindings then
            ConsoleExperience.cursor.keybindings:SetupCursorBindings()
        end
    end
end

function Hooks:OnFrameHide(frame)
    if not frame then return end
    
    local frameName = frame:GetName() or "Unknown"
    
    -- Use a short delay to check if the frame is really hidden
    -- This handles frames that do show/hide cycles during initialization
    local checkFrame = CreateFrame("Frame")
    checkFrame:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + arg1
        if this.elapsed > 0.1 then
            this:SetScript("OnUpdate", nil)
            
            -- Now check if frame is actually hidden
            if frame:IsVisible() then
                CE_Debug("OnFrameHide ignored (frame visible after delay): " .. frameName)
                return
            end
            
            CE_Debug("OnFrameHide confirmed: " .. frameName)
            Hooks:ProcessFrameHide(frame)
        end
    end)
end

function Hooks:ProcessFrameHide(frame)
    if not frame then return end
    
    local Cursor = ConsoleExperience.cursor
    
    -- Remove from active frames
    Cursor.navigationState.activeFrames[frame] = nil
    
    -- Find another active frame
    local mostRecentFrame = nil
    for activeFrame, _ in pairs(Cursor.navigationState.activeFrames) do
        if activeFrame:IsVisible() then
            mostRecentFrame = activeFrame
            break
        end
    end
    
    if mostRecentFrame then
        -- Move cursor to the other active frame
        local firstButton = Cursor:FindFirstVisibleButton(mostRecentFrame)
        if firstButton then
            Cursor:MoveCursorToButton(firstButton)
        end
    else
        -- No active frames, hide cursor and restore bindings
        Cursor:Hide()
        
        if GameTooltip then
            GameTooltip:Hide()
        end
        
        -- Restore original bindings
        if ConsoleExperience.cursor.keybindings then
            ConsoleExperience.cursor.keybindings:RestoreOriginalBindings()
        end
        
        -- Clear navigation state
        Cursor:ClearNavigationState()
    end
end

-- Manual hook for frames that are created dynamically
function Hooks:HookDynamicFrame(frame, frameName)
    if not frame then return end
    
    self:HookFrame(frame, frameName or "Dynamic Frame")
    
    -- If frame is already visible, initialize cursor
    if frame:IsVisible() then
        self:OnFrameShow(frame)
    end
end

-- Check if any hooked frames are visible
function Hooks:HasActiveFrames()
    local Cursor = ConsoleExperience.cursor
    for frame, _ in pairs(Cursor.navigationState.activeFrames) do
        if frame:IsVisible() then
            return true
        end
    end
    return false
end

-- Module loaded silently

