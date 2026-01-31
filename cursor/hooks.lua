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
    -- System Options Frames
    {frame = "VideoOptionsFrame", name = "Video Options"},
    {frame = "SoundOptionsFrame", name = "Sound Options"},
    {frame = "UIOptionsFrame", name = "Interface Options"},
    {frame = "OptionsFrame", name = "Options"},
    {frame = "KeyBindingFrame", name = "Key Bindings"},
    {frame = "HelpFrame", name = "Help"},
    {frame = "CinematicFrame", name = "Cinematic"},
    {frame = "LFTFrame", name = "Looking For Group"},
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
    
    -- Hook pfUI frames if pfUI is loaded (these are created dynamically)
    self:HookPfUIFrames()
    
    -- Hook Bagshui frames if Bagshui is loaded (these are created dynamically)
    self:HookBagshuiFrames()
    
    -- Hook Bagnon frames if Bagnon is loaded (these are created dynamically)
    self:HookBagnonFrames()
    
    -- Also hook ToggleBackpack to catch when bags are opened (pfUI and Bagshui)
    if not Hooks.backpackHooked then
        local oldToggleBackpack = _G.ToggleBackpack
        if oldToggleBackpack then
            _G.ToggleBackpack = function()
                oldToggleBackpack()
                -- Small delay to let bag addons show their frames
                local checkFrame = CreateFrame("Frame")
                checkFrame:SetScript("OnUpdate", function()
                    this.elapsed = (this.elapsed or 0) + arg1
                    if this.elapsed > 0.1 then
                        this:SetScript("OnUpdate", nil)
                        -- Try to hook pfUI frames if not already hooked
                        Hooks:HookPfUIFrames()
                        -- Check if pfBag is visible and trigger OnFrameShow
                        if pfUI and pfUI.bag and pfUI.bag.right then
                            local frame = pfUI.bag.right
                            if frame:IsVisible() then
                                if frame.ceHooked then
                                    local Cursor = ConsoleExperience.cursor
                                    if not Cursor.navigationState.activeFrames[frame] then
                                        CE_Debug("Hooks: Triggering OnFrameShow for pfBag after ToggleBackpack")
                                        Hooks:OnFrameShow(frame)
                                    end
                                else
                                    CE_Debug("Hooks: pfBag not hooked yet, hooking now")
                                    Hooks:HookFrame(frame, "pfUI Bag")
                                    Hooks:OnFrameShow(frame)
                                end
                            end
                        end
                        
                        -- Try to hook Bagshui frames if not already hooked
                        Hooks:HookBagshuiFrames()
                        -- Check if BagshuiBagsFrame is visible and trigger OnFrameShow
                        local bagsFrame = getglobal("BagshuiBagsFrame")
                        if bagsFrame and bagsFrame:IsVisible() then
                            if bagsFrame.ceHooked then
                                local Cursor = ConsoleExperience.cursor
                                if not Cursor.navigationState.activeFrames[bagsFrame] then
                                    CE_Debug("Hooks: Triggering OnFrameShow for BagshuiBagsFrame after ToggleBackpack")
                                    Hooks:OnFrameShow(bagsFrame)
                                end
                            else
                                CE_Debug("Hooks: BagshuiBagsFrame not hooked yet, hooking now")
                                Hooks:HookFrame(bagsFrame, "Bagshui Bags")
                                Hooks:OnFrameShow(bagsFrame)
                            end
                        end
                        
                        -- Try to hook Bagnon frames if not already hooked
                        Hooks:HookBagnonFrames()
                        -- Check if Bagnon frame is visible and trigger OnFrameShow
                        local bagnonFrame = getglobal("Bagnon")
                        if bagnonFrame and bagnonFrame:IsVisible() then
                            if bagnonFrame.ceHooked then
                                local Cursor = ConsoleExperience.cursor
                                if not Cursor.navigationState.activeFrames[bagnonFrame] then
                                    CE_Debug("Hooks: Triggering OnFrameShow for Bagnon after ToggleBackpack")
                                    Hooks:OnFrameShow(bagnonFrame)
                                end
                            else
                                CE_Debug("Hooks: Bagnon not hooked yet, hooking now")
                                Hooks:HookFrame(bagnonFrame, "Bagnon")
                                Hooks:OnFrameShow(bagnonFrame)
                            end
                        end
                    end
                end)
            end
            Hooks.backpackHooked = true
        end
    end
    
    -- Hook dropdown menus (DropDownList1, DropDownList2, etc.)
    self:HookDropdownMenus()
    
    -- Hook party/raid/player frames if healer mode is enabled
    self:HookPartyRaidFrames()
    
    -- Create event frame to hook load-on-demand frames
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("ADDON_LOADED")
        self.eventFrame:RegisterEvent("WORLD_MAP_UPDATE")
        self.eventFrame:RegisterEvent("TAXIMAP_OPENED")
        self.eventFrame:RegisterEvent("MAIL_SHOW")
        self.eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
        self.eventFrame:RegisterEvent("TRAINER_SHOW")
        self.eventFrame:RegisterEvent("MERCHANT_SHOW")
        self.eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
        self.eventFrame:RegisterEvent("BANKFRAME_OPENED")
        -- Register events for party/raid frame updates (healer mode)
        self.eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        self.eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.eventFrame:SetScript("OnEvent", function()
            -- Check for pfUI when addons load
            if event == "ADDON_LOADED" and (arg1 == "pfUI" or arg1 == "pfUI-master") then
                CE_Debug("Hooks: pfUI addon loaded, hooking frames")
                Hooks:HookPfUIFrames()
            end
            
            -- Check for Bagshui when addons load
            if event == "ADDON_LOADED" and arg1 == "Bagshui" then
                CE_Debug("Hooks: Bagshui addon loaded, hooking frames")
                Hooks:HookBagshuiFrames()
            end
            
            -- Check for Bagnon when addons load
            if event == "ADDON_LOADED" and (arg1 == "Bagnon" or arg1 == "Bagnon_Core") then
                CE_Debug("Hooks: Bagnon addon loaded, hooking frames")
                Hooks:HookBagnonFrames()
            end
            
            -- Check pfUI bags on PLAYER_ENTERING_WORLD (when pfUI creates the bag frames)
            if event == "PLAYER_ENTERING_WORLD" then
                -- Small delay to ensure pfUI has created the frames
                local checkFrame = CreateFrame("Frame")
                checkFrame:SetScript("OnUpdate", function()
                    this.elapsed = (this.elapsed or 0) + arg1
                    if this.elapsed > 0.2 then
                        this:SetScript("OnUpdate", nil)
                        Hooks:HookPfUIFrames()
                        Hooks:HookBagshuiFrames()
                        Hooks:HookBagnonFrames()
                    end
                end)
            end
            
            Hooks:TryHookPendingFrames()
            -- Open all bags when interacting with merchants, auction house, or bank
            if event == "MERCHANT_SHOW" or event == "AUCTION_HOUSE_SHOW" or event == "BANKFRAME_OPENED" then
                Hooks:OnVendorInteraction()
            end
            -- Hook party/raid frames when they change or on world enter (healer mode)
            if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
                Hooks:HookPartyRaidFrames()
                -- Update action bar buttons (to hide/show D-pad buttons in healer mode)
                if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                    ConsoleExperience.actionbars:UpdateAllButtons()
                end
            end
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
    
    -- Try to hook party/raid frames if healer mode is enabled
    self:HookPartyRaidFrames()
    
    -- Try to hook pfUI frames if pfUI is loaded
    self:HookPfUIFrames()
    
    -- Special handling for pfUI bag frames - check if they're visible and not yet initialized
    if pfUI and pfUI.bag then
        -- Check pfBag (right bag frame - backpack/inventory)
        if pfUI.bag.right and pfUI.bag.right:IsVisible() then
            local Cursor = ConsoleExperience.cursor
            if not Cursor.navigationState.activeFrames[pfUI.bag.right] then
                CE_Debug("pfBag detected visible, initializing cursor")
                self:OnFrameShow(pfUI.bag.right)
            end
        end
        
        -- Check pfBank (left bag frame - bank)
        if pfUI.bag.left and pfUI.bag.left:IsVisible() then
            local Cursor = ConsoleExperience.cursor
            if not Cursor.navigationState.activeFrames[pfUI.bag.left] then
                CE_Debug("pfBank detected visible, initializing cursor")
                self:OnFrameShow(pfUI.bag.left)
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
    
    -- Special handling for VideoOptionsFrame
    local videoOptionsFrame = getglobal("VideoOptionsFrame")
    if videoOptionsFrame and videoOptionsFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[videoOptionsFrame] then
            CE_Debug("VideoOptionsFrame detected visible, initializing cursor")
            self:OnFrameShow(videoOptionsFrame)
        end
    end
    
    -- Special handling for SoundOptionsFrame
    local soundOptionsFrame = getglobal("SoundOptionsFrame")
    if soundOptionsFrame and soundOptionsFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[soundOptionsFrame] then
            CE_Debug("SoundOptionsFrame detected visible, initializing cursor")
            self:OnFrameShow(soundOptionsFrame)
        end
    end
    
    -- Special handling for UIOptionsFrame
    local uiOptionsFrame = getglobal("UIOptionsFrame")
    if uiOptionsFrame and uiOptionsFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[uiOptionsFrame] then
            CE_Debug("UIOptionsFrame detected visible, initializing cursor")
            self:OnFrameShow(uiOptionsFrame)
        end
    end
    
    -- Special handling for KeyBindingFrame
    local keyBindingFrame = getglobal("KeyBindingFrame")
    if keyBindingFrame and keyBindingFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[keyBindingFrame] then
            CE_Debug("KeyBindingFrame detected visible, initializing cursor")
            self:OnFrameShow(keyBindingFrame)
        end
    end
end

function Hooks:HookFrame(frame, frameName)
    if not frame or frame.ceHooked then return end
    
    -- Check whether the frame supports the GetScript and SetScript methods
    if not frame.GetScript or not frame.SetScript then
        CE_Debug("Hooks: Skip hooking " .. (frame:GetName() or "Unknown") .. " - script methods not supported")
        return 
    end
    
    local frameNameStr = frame:GetName() or "Unknown"
    CE_Debug("Hooks: Hooking frame " .. frameNameStr)
    
    local oldOnShow = frame:GetScript("OnShow")
    local oldOnHide = frame:GetScript("OnHide")
    
    frame:SetScript("OnShow", function()
        CE_Debug("Hooks: OnShow triggered for " .. frameNameStr)
        -- Run original OnShow first
        if oldOnShow then
            oldOnShow()
        end
        
        -- Initialize cursor on this frame
        Hooks:OnFrameShow(this)
    end)
    
    frame:SetScript("OnHide", function()
        CE_Debug("Hooks: OnHide triggered for " .. frameNameStr)
        -- Run original OnHide first
        if oldOnHide then
            oldOnHide()
        end
        
        -- Handle frame hide
        Hooks:OnFrameHide(this)
    end)
    
    frame.ceHooked = true
end

function Hooks:OnFrameShow(frame)
    if not frame then return end
    
    local frameName = frame:GetName() or "Unknown"
    CE_Debug("OnFrameShow: " .. frameName)
    
    local Cursor = ConsoleExperience.cursor
    
    -- Check if this is a party/raid/player frame (healer mode)
    local isPartyRaidFrame = self:IsPartyRaidFrame(frameName)
    
    -- Add to active frames (store as table to hold metadata for healer mode frames)
    if isPartyRaidFrame then
        Cursor.navigationState.activeFrames[frame] = { healerMode = true }
    else
        Cursor.navigationState.activeFrames[frame] = true
    end
    
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
    
    -- For pfUI, Bagshui, and Bagnon bags, add a small delay to ensure buttons are created
    -- These addons create buttons dynamically which might run after OnShow
    local isPfUIBag = (frameName == "pfBag" or frameName == "pfBank")
    local isBagshuiBag = (frameName == "BagshuiBagsFrame" or frameName == "BagshuiBankFrame")
    local isBagnonBag = (frameName == "Bagnon" or frameName == "Banknon")
    if isPfUIBag or isBagshuiBag or isBagnonBag then
        local addonName = isPfUIBag and "pfUI" or (isBagshuiBag and "Bagshui" or "Bagnon")
        CE_Debug("OnFrameShow: " .. addonName .. " bag frame detected, waiting for buttons to be created")
        local delayFrame = CreateFrame("Frame")
        local attempts = 0
        delayFrame:SetScript("OnUpdate", function()
            this.elapsed = (this.elapsed or 0) + arg1
            attempts = attempts + 1
            -- Check every 0.1 seconds, up to 1 second (10 attempts)
            if this.elapsed > 0.1 and attempts <= 10 then
                this.elapsed = 0
                local Cursor = ConsoleExperience.cursor
                local allButtons = Cursor:CollectVisibleButtons(frame)
                local buttonCount = table.getn(allButtons)
                CE_Debug("OnFrameShow: Found " .. buttonCount .. " buttons in pfUI bag frame (attempt " .. attempts .. ")")
                
                if buttonCount > 0 then
                    this:SetScript("OnUpdate", nil)
                    CE_Debug("OnFrameShow: Buttons found, initializing cursor")
                    Hooks:InitializeCursorOnFrame(frame)
                elseif attempts >= 10 then
                    this:SetScript("OnUpdate", nil)
                    CE_Debug("OnFrameShow: No buttons found after 10 attempts, initializing anyway")
                    Hooks:InitializeCursorOnFrame(frame)
                end
            end
        end)
    else
        -- For other frames, initialize immediately
        self:InitializeCursorOnFrame(frame)
    end
end

function Hooks:InitializeCursorOnFrame(frame)
    if not frame then return end
    
    local frameName = frame:GetName() or "Unknown"
    local Cursor = ConsoleExperience.cursor
    
    -- Find first visible button and move cursor to it
    local firstButton = Cursor:FindFirstVisibleButton(frame)
    
    -- Set up cursor navigation bindings first (before moving to button)
    -- Only setup if cursor mode is not already active (to avoid saving bindings multiple times)
    if ConsoleExperience.cursor.keybindings and not ConsoleExperience.cursor.keybindings:IsCursorModeActive() then
        ConsoleExperience.cursor.keybindings:SetupCursorBindings()
    end
    
    if firstButton then
        CE_Debug("InitializeCursorOnFrame: Found button: " .. (firstButton:GetName() or "unnamed"))
        Cursor:MoveCursorToButton(firstButton)
    else
        CE_Debug("InitializeCursorOnFrame: No buttons found in " .. frameName)
        -- For pfUI, Bagshui, and Bagnon bags, try to find buttons by scanning children more thoroughly
        if frameName == "pfBag" or frameName == "pfBank" or frameName == "BagshuiBagsFrame" or frameName == "BagshuiBankFrame" or frameName == "Bagnon" or frameName == "Banknon" then
            local allButtons = Cursor:CollectVisibleButtons(frame)
            local buttonCount = table.getn(allButtons)
            CE_Debug("InitializeCursorOnFrame: Found " .. buttonCount .. " buttons in " .. frameName)
            if buttonCount > 0 then
                firstButton = allButtons[1].button
                CE_Debug("InitializeCursorOnFrame: Using first button: " .. (firstButton:GetName() or "unnamed"))
                Cursor:MoveCursorToButton(firstButton)
            end
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
    for activeFrame, frameInfo in pairs(Cursor.navigationState.activeFrames) do
        if activeFrame:IsVisible() then
            mostRecentFrame = activeFrame
            break
        end
    end
    
    if mostRecentFrame then
        -- Move cursor to the other active frame
        local firstButton = Cursor:FindFirstVisibleButton(mostRecentFrame)
        if firstButton then
            -- Set up cursor bindings
            if ConsoleExperience.cursor.keybindings then
                ConsoleExperience.cursor.keybindings:RestoreOriginalBindings()
                ConsoleExperience.cursor.keybindings:SetupCursorBindings()
            end
            
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

-- ============================================================================
-- ============================================================================
-- pfUI Frame Hooking
-- ============================================================================

-- Hook pfUI frames if pfUI is loaded
function Hooks:HookPfUIFrames()
    -- Check if pfUI is loaded
    if not pfUI then
        CE_Debug("Hooks:HookPfUIFrames: pfUI not loaded")
        return
    end
    
    -- Check if pfUI.bag exists (pfUI bag module)
    if not pfUI.bag then
        CE_Debug("Hooks:HookPfUIFrames: pfUI.bag not found")
        return
    end
    
    CE_Debug("Hooks: pfUI detected, hooking into pfUI bag frames")
    
    -- Hook pfBag (right bag frame - backpack/inventory)
    -- This frame is created in CreateBags() which is called on PLAYER_ENTERING_WORLD
    if pfUI.bag.right then
        local frame = pfUI.bag.right
        local frameName = frame:GetName() or "unnamed"
        CE_Debug("Hooks: Found pfBag frame: " .. frameName)
        if not frame.ceHooked then
            self:HookFrame(frame, "pfUI Bag")
            CE_Debug("Hooks: Hooked pfBag frame")
            
            -- If frame is already visible, trigger OnFrameShow
            if frame:IsVisible() then
                CE_Debug("Hooks: pfBag is already visible, initializing cursor")
                self:OnFrameShow(frame)
            end
        else
            CE_Debug("Hooks: pfBag frame already hooked")
            -- Frame is already hooked, but check if it's visible and cursor isn't active
            if frame:IsVisible() then
                local Cursor = ConsoleExperience.cursor
                if not Cursor.navigationState.activeFrames[frame] then
                    CE_Debug("Hooks: pfBag is visible but cursor not active, re-initializing")
                    self:OnFrameShow(frame)
                end
            end
        end
    else
        CE_Debug("Hooks: pfBag frame not yet created (will be created on PLAYER_ENTERING_WORLD)")
    end
    
    -- Hook pfBank (left bag frame - bank)
    -- This frame is created in CreateBags("bank") which is called on PLAYER_ENTERING_WORLD
    if pfUI.bag.left then
        local frame = pfUI.bag.left
        local frameName = frame:GetName() or "unnamed"
        CE_Debug("Hooks: Found pfBank frame: " .. frameName)
        if not frame.ceHooked then
            self:HookFrame(frame, "pfUI Bank")
            CE_Debug("Hooks: Hooked pfBank frame")
            
            -- If frame is already visible, trigger OnFrameShow
            if frame:IsVisible() then
                CE_Debug("Hooks: pfBank is already visible, initializing cursor")
                self:OnFrameShow(frame)
            end
        else
            CE_Debug("Hooks: pfBank frame already hooked")
            -- Frame is already hooked, but check if it's visible and cursor isn't active
            if frame:IsVisible() then
                local Cursor = ConsoleExperience.cursor
                if not Cursor.navigationState.activeFrames[frame] then
                    CE_Debug("Hooks: pfBank is visible but cursor not active, re-initializing")
                    self:OnFrameShow(frame)
                end
            end
        end
    else
        CE_Debug("Hooks: pfBank frame not yet created (will be created on PLAYER_ENTERING_WORLD)")
    end
end

-- ============================================================================
-- Bagshui Frame Hooking
-- ============================================================================

-- Hook Bagshui frames if Bagshui is loaded
function Hooks:HookBagshuiFrames()
    -- Check if Bagshui is loaded
    if not Bagshui then
        CE_Debug("Hooks:HookBagshuiFrames: Bagshui not loaded")
        return
    end
    
    -- Check if Bagshui.components exists (Bagshui inventory components)
    if not Bagshui.components then
        CE_Debug("Hooks:HookBagshuiFrames: Bagshui.components not found")
        return
    end
    
    CE_Debug("Hooks: Bagshui detected, hooking into Bagshui bag frames")
    
    -- Hook BagshuiBagsFrame (main bag frame)
    -- This frame is created when Bagshui initializes
    local bagsFrame = getglobal("BagshuiBagsFrame")
    if bagsFrame then
        local frameName = bagsFrame:GetName() or "unnamed"
        CE_Debug("Hooks: Found BagshuiBagsFrame: " .. frameName)
        if not bagsFrame.ceHooked then
            self:HookFrame(bagsFrame, "Bagshui Bags")
            CE_Debug("Hooks: Hooked BagshuiBagsFrame")
            
            -- If frame is already visible, trigger OnFrameShow
            if bagsFrame:IsVisible() then
                CE_Debug("Hooks: BagshuiBagsFrame is already visible, initializing cursor")
                self:OnFrameShow(bagsFrame)
            end
        else
            CE_Debug("Hooks: BagshuiBagsFrame already hooked")
            -- Frame is already hooked, but check if it's visible and cursor isn't active
            if bagsFrame:IsVisible() then
                local Cursor = ConsoleExperience.cursor
                if not Cursor.navigationState.activeFrames[bagsFrame] then
                    CE_Debug("Hooks: BagshuiBagsFrame is visible but cursor not active, re-initializing")
                    self:OnFrameShow(bagsFrame)
                end
            end
        end
    else
        CE_Debug("Hooks: BagshuiBagsFrame not yet created")
    end
    
    -- Hook BagshuiBankFrame (main bank frame)
    -- This frame is created when Bagshui initializes
    local bankFrame = getglobal("BagshuiBankFrame")
    if bankFrame then
        local frameName = bankFrame:GetName() or "unnamed"
        CE_Debug("Hooks: Found BagshuiBankFrame: " .. frameName)
        if not bankFrame.ceHooked then
            self:HookFrame(bankFrame, "Bagshui Bank")
            CE_Debug("Hooks: Hooked BagshuiBankFrame")
            
            -- If frame is already visible, trigger OnFrameShow
            if bankFrame:IsVisible() then
                CE_Debug("Hooks: BagshuiBankFrame is already visible, initializing cursor")
                self:OnFrameShow(bankFrame)
            end
        else
            CE_Debug("Hooks: BagshuiBankFrame already hooked")
            -- Frame is already hooked, but check if it's visible and cursor isn't active
            if bankFrame:IsVisible() then
                local Cursor = ConsoleExperience.cursor
                if not Cursor.navigationState.activeFrames[bankFrame] then
                    CE_Debug("Hooks: BagshuiBankFrame is visible but cursor not active, re-initializing")
                    self:OnFrameShow(bankFrame)
                end
            end
        end
    else
        CE_Debug("Hooks: BagshuiBankFrame not yet created")
    end
end

-- ============================================================================
-- Bagnon Frame Hooking
-- ============================================================================

-- Hook Bagnon frames if Bagnon is loaded
function Hooks:HookBagnonFrames()
    -- Check if Bagnon is loaded (check for Bagnon_Core which is the core addon)
    if not BagnonSets then
        CE_Debug("Hooks:HookBagnonFrames: Bagnon not loaded")
        return
    end
    
    CE_Debug("Hooks: Bagnon detected, hooking into Bagnon bag frames")
    
    -- Hook Bagnon (main inventory frame)
    -- This frame is created when Bagnon loads
    local bagnonFrame = getglobal("Bagnon")
    if bagnonFrame then
        local frameName = bagnonFrame:GetName() or "unnamed"
        CE_Debug("Hooks: Found Bagnon frame: " .. frameName)
        if not bagnonFrame.ceHooked then
            self:HookFrame(bagnonFrame, "Bagnon")
            CE_Debug("Hooks: Hooked Bagnon frame")
            
            -- If frame is already visible, trigger OnFrameShow
            if bagnonFrame:IsVisible() then
                CE_Debug("Hooks: Bagnon is already visible, initializing cursor")
                self:OnFrameShow(bagnonFrame)
            end
        else
            CE_Debug("Hooks: Bagnon frame already hooked")
            -- Frame is already hooked, but check if it's visible and cursor isn't active
            if bagnonFrame:IsVisible() then
                local Cursor = ConsoleExperience.cursor
                if not Cursor.navigationState.activeFrames[bagnonFrame] then
                    CE_Debug("Hooks: Bagnon is visible but cursor not active, re-initializing")
                    self:OnFrameShow(bagnonFrame)
                end
            end
        end
    else
        CE_Debug("Hooks: Bagnon frame not yet created")
    end
    
    -- Hook Banknon (main bank frame)
    -- This frame is created when Banknon loads
    local banknonFrame = getglobal("Banknon")
    if banknonFrame then
        local frameName = banknonFrame:GetName() or "unnamed"
        CE_Debug("Hooks: Found Banknon frame: " .. frameName)
        if not banknonFrame.ceHooked then
            self:HookFrame(banknonFrame, "Bagnon Bank")
            CE_Debug("Hooks: Hooked Banknon frame")
            
            -- If frame is already visible, trigger OnFrameShow
            if banknonFrame:IsVisible() then
                CE_Debug("Hooks: Banknon is already visible, initializing cursor")
                self:OnFrameShow(banknonFrame)
            end
        else
            CE_Debug("Hooks: Banknon frame already hooked")
            -- Frame is already hooked, but check if it's visible and cursor isn't active
            if banknonFrame:IsVisible() then
                local Cursor = ConsoleExperience.cursor
                if not Cursor.navigationState.activeFrames[banknonFrame] then
                    CE_Debug("Hooks: Banknon is visible but cursor not active, re-initializing")
                    self:OnFrameShow(banknonFrame)
                end
            end
        end
    else
        CE_Debug("Hooks: Banknon frame not yet created")
    end
end

-- ============================================================================
-- Party/Raid Frame Hooking (Healer Mode)
-- ============================================================================

-- Check if a frame name is a party/raid/player frame (for healer mode)
function Hooks:IsPartyRaidFrame(frameName)
    if not frameName then return false end
    
    -- Player frame
    if frameName == "PlayerFrame" then
        return true
    end
    
    -- Party frames: PartyMemberFrame1, PartyMemberFrame2, etc.
    if string.find(frameName, "^PartyMemberFrame%d+$") then
        return true
    end
    
    -- Raid frames: RaidGroupButton1, RaidGroupButton2, etc. (WoW 1.12 uses RaidGroupButton)
    if string.find(frameName, "^RaidGroupButton%d+$") then
        return true
    end
    
    -- Also check for PartyFrame1, PartyFrame2 (alternative naming)
    if string.find(frameName, "^PartyFrame%d+$") then
        return true
    end
    
    return false
end

-- Unhook party and raid frames (when leaving party/raid or disabling healer mode)
function Hooks:UnhookPartyRaidFrames()
    CE_Debug("Hooks: Unhooking party/raid/player frames...")
    
    -- Unhook player frame (if it was hooked by healer mode)
    local playerFrame = getglobal("PlayerFrame")
    if playerFrame and playerFrame.ceHooked then
        local frameName = playerFrame:GetName() or ""
        -- Only unhook if it's a party/raid/player frame (healer mode frames)
        if frameName == "PlayerFrame" or self:IsPartyRaidFrame(frameName) then
            -- Restore original scripts
            playerFrame:SetScript("OnShow", nil)
            playerFrame:SetScript("OnHide", nil)
            playerFrame.ceHooked = nil
            CE_Debug("Hooks: Unhooked PlayerFrame")
            
            -- Remove from active frames if present
            local Cursor = ConsoleExperience.cursor
            if Cursor and Cursor.navigationState then
                Cursor.navigationState.activeFrames[playerFrame] = nil
            end
        end
    end
    
    -- Unhook party frames (PartyMemberFrame1-4)
    for i = 1, 4 do
        local frameName = "PartyMemberFrame" .. i
        local frame = getglobal(frameName)
        if frame and frame.ceHooked then
            -- Restore original scripts
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
            frame.ceHooked = nil
            CE_Debug("Hooks: Unhooked " .. frameName)
            
            -- Remove from active frames if present
            local Cursor = ConsoleExperience.cursor
            if Cursor and Cursor.navigationState then
                Cursor.navigationState.activeFrames[frame] = nil
            end
        end
    end
    
    -- Unhook raid frames (RaidGroupButton1-40)
    for i = 1, 40 do
        local frameName = "RaidGroupButton" .. i
        local frame = getglobal(frameName)
        if frame and frame.ceHooked then
            -- Restore original scripts
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
            frame.ceHooked = nil
            CE_Debug("Hooks: Unhooked " .. frameName)
            
            -- Remove from active frames if present
            local Cursor = ConsoleExperience.cursor
            if Cursor and Cursor.navigationState then
                Cursor.navigationState.activeFrames[frame] = nil
            end
        end
    end
    
    -- Unhook PartyFrame1-4 if they exist (alternative naming)
    for i = 1, 4 do
        local frameName = "PartyFrame" .. i
        local frame = getglobal(frameName)
        if frame and frame.ceHooked then
            -- Restore original scripts
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
            frame.ceHooked = nil
            CE_Debug("Hooks: Unhooked " .. frameName)
            
            -- Remove from active frames if present
            local Cursor = ConsoleExperience.cursor
            if Cursor and Cursor.navigationState then
                Cursor.navigationState.activeFrames[frame] = nil
            end
        end
    end
end

-- Hook party and raid frames when healer mode is enabled
function Hooks:HookPartyRaidFrames()
    -- Check if healer mode is enabled
    local config = ConsoleExperience.config
    if not config then
        -- Healer mode disabled or config not available - unhook if needed
        self:UnhookPartyRaidFrames()
        return
    end
    if not config.Get then
        self:UnhookPartyRaidFrames()
        return
    end
    
    local healerMode = config:Get("healerMode")
    if not healerMode then
        -- Healer mode disabled - unhook if needed
        self:UnhookPartyRaidFrames()
        return
    end
    
    -- Check if we're actually in a party or raid
    -- In WoW 1.12, GetNumPartyMembers() returns the number of party members (0-4)
    -- GetNumRaidMembers() returns the number of raid members (0-40)
    local numPartyMembers = GetNumPartyMembers and GetNumPartyMembers() or 0
    local numRaidMembers = GetNumRaidMembers and GetNumRaidMembers() or 0
    local inParty = numPartyMembers > 0
    local inRaid = numRaidMembers > 0
    
    -- If not in party/raid, unhook all party/raid/player frames
    if not inParty and not inRaid then
        CE_Debug("Hooks: Not in party/raid, unhooking all party/raid/player frames")
        self:UnhookPartyRaidFrames()
        return
    end
    
    CE_Debug("Hooks: Healer mode enabled, hooking party/raid/player frames...")
    
    -- Hook player frame
    local playerFrame = getglobal("PlayerFrame")
    if playerFrame then
        local wasAlreadyHooked = playerFrame.ceHooked
        self:HookFrame(playerFrame, "Player Frame")
        CE_Debug("Hooks: Hooked PlayerFrame")
        
        -- If frame is already visible, trigger OnFrameShow
        if playerFrame:IsVisible() then
            if not wasAlreadyHooked then
                CE_Debug("Hooks: Player frame is already visible, initializing cursor")
            else
                CE_Debug("Hooks: Player frame is already visible and hooked, re-initializing cursor")
            end
            self:OnFrameShow(playerFrame)
        end
    else
        CE_Debug("Hooks: PlayerFrame not found")
    end
    
    -- Hook party frames (PartyMemberFrame1-4)
    for i = 1, 4 do
        local frameName = "PartyMemberFrame" .. i
        local frame = getglobal(frameName)
        if frame then
            local wasAlreadyHooked = frame.ceHooked
            self:HookFrame(frame, "Party Member " .. i)
            CE_Debug("Hooks: Hooked " .. frameName)
            
            -- If frame is already visible, trigger OnFrameShow
            if frame:IsVisible() then
                if not wasAlreadyHooked then
                    CE_Debug("Hooks: Party frame " .. frameName .. " is already visible, initializing cursor")
                else
                    CE_Debug("Hooks: Party frame " .. frameName .. " is already visible and hooked, re-initializing cursor")
                end
                self:OnFrameShow(frame)
            end
        else
            CE_Debug("Hooks: Party frame " .. frameName .. " not found")
        end
    end
    
    -- Hook raid frames (RaidGroupButton1-40 in WoW 1.12)
    for i = 1, 40 do
        local frameName = "RaidGroupButton" .. i
        local frame = getglobal(frameName)
        if frame then
            local wasAlreadyHooked = frame.ceHooked
            self:HookFrame(frame, "Raid Member " .. i)
            CE_Debug("Hooks: Hooked " .. frameName)
            
            -- If frame is already visible, trigger OnFrameShow
            if frame:IsVisible() then
                if not wasAlreadyHooked then
                    CE_Debug("Hooks: Raid frame " .. frameName .. " is already visible, initializing cursor")
                else
                    CE_Debug("Hooks: Raid frame " .. frameName .. " is already visible and hooked, re-initializing cursor")
                end
                self:OnFrameShow(frame)
            end
        end
    end
    
    -- Also hook PartyFrame1-4 if they exist (alternative naming)
    for i = 1, 4 do
        local frameName = "PartyFrame" .. i
        local frame = getglobal(frameName)
        if frame then
            local wasAlreadyHooked = frame.ceHooked
            self:HookFrame(frame, "Party " .. i)
            CE_Debug("Hooks: Hooked " .. frameName)
            
            -- If frame is already visible, trigger OnFrameShow
            if frame:IsVisible() then
                if not wasAlreadyHooked then
                    CE_Debug("Hooks: Party frame " .. frameName .. " is already visible, initializing cursor")
                else
                    CE_Debug("Hooks: Party frame " .. frameName .. " is already visible and hooked, re-initializing cursor")
                end
                self:OnFrameShow(frame)
            end
        end
    end
end

-- ============================================================================
-- Vendor/Auction House Bag Opening
-- ============================================================================

-- Open all bags when interacting with merchants, auction house, or bank
function Hooks:OnVendorInteraction()
    -- Check if the feature is enabled in config
    local Config = ConsoleExperience.config
    if Config and Config.Get then
        local enabled = Config:Get("openAllBagsAtVendor")
        if enabled == false then
            return
        end
    end
    
    -- Open all bags (OpenAllBags is a Blizzard API function)
    if OpenAllBags then
        OpenAllBags()
        CE_Debug("Opened all bags for vendor interaction")
    end
end

-- Module loaded silently

