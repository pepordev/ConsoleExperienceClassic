--[[
    ConsoleExperienceClassic - Tooltip Module
    
    Handles tooltip display for cursor navigation with controller button icons
]]

-- Create tooltip module namespace
ConsoleExperience.cursor = ConsoleExperience.cursor or {}
ConsoleExperience.cursor.tooltip = ConsoleExperience.cursor.tooltip or {}
local Tooltip = ConsoleExperience.cursor.tooltip

-- Create a child frame of GameTooltip to hook show/hide events
local TooltipHookFrame = CreateFrame("Frame", nil, GameTooltip)

-- Icon path
local iconPath = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\"

-- Text padding to make room for icon (must have enough space for 16px icon)
local textPadding = "        "

-- Create button icon textures on GameTooltip
local aIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
aIcon:SetWidth(16)
aIcon:SetHeight(16)
aIcon:SetTexture(iconPath .. "a")
aIcon:Hide()

local bIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
bIcon:SetWidth(16)
bIcon:SetHeight(16)
bIcon:SetTexture(iconPath .. "b")
bIcon:Hide()

local xIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
xIcon:SetWidth(16)
xIcon:SetHeight(16)
xIcon:SetTexture(iconPath .. "x")
xIcon:Hide()

local yIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
yIcon:SetWidth(16)
yIcon:SetHeight(16)
yIcon:SetTexture(iconPath .. "y")
yIcon:Hide()

local lbIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
lbIcon:SetWidth(16)
lbIcon:SetHeight(16)
lbIcon:SetTexture(iconPath .. "lb")
lbIcon:Hide()

local rbIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
rbIcon:SetWidth(16)
rbIcon:SetHeight(16)
rbIcon:SetTexture(iconPath .. "rb")
rbIcon:Hide()

-- Map icon names to textures
local tooltipIcons = {
    ["a"] = aIcon,
    ["b"] = bIcon,
    ["x"] = xIcon,
    ["y"] = yIcon,
    ["lb"] = lbIcon,
    ["rb"] = rbIcon,
}

-- Hide all tooltip icons
local function HideAllIcons()
    for _, icon in pairs(tooltipIcons) do
        icon:Hide()
    end
end

-- Add action prompts with icons to tooltip (called AFTER tooltip content is set)
local function AddPrompts(prompts)
    if not prompts or table.getn(prompts) == 0 then return end
    
    -- Hide all icons first
    HideAllIcons()
    
    -- Add separator line
    GameTooltip:AddLine(" ")
    
    -- Add each prompt with its icon
    for i = 1, table.getn(prompts) do
        local prompt = prompts[i]
        local icon = tooltipIcons[prompt.icon]
        local text = prompt.prompt
        
        -- Add line with padding for icon
        GameTooltip:AddLine(textPadding .. text)
        
        -- Position icon at the left of this line
        if icon then
            local lineNum = GameTooltip:NumLines()
            local lineFrame = getglobal("GameTooltipTextLeft" .. lineNum)
            if lineFrame then
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", lineFrame, "LEFT", 0, 0)
                icon:Show()
            end
        end
        
        -- Add spacing line after each prompt
        GameTooltip:AddLine(" ")
    end
end

-- Hook GameTooltip show to add our prompts
TooltipHookFrame:SetScript("OnShow", function()
    -- Only add prompts if cursor is active
    if not ConsoleExperience.cursor then return end
    if not ConsoleExperience.cursor.keybindings then return end
    if not ConsoleExperience.cursor.keybindings:IsCursorModeActive() then return end
    
    local button = ConsoleExperience.cursor.navigationState.currentButton
    if not button then return end
    
    local buttonName = button:GetName() or ""
    local elementType = nil
    if button:IsObjectType("EditBox") then
        elementType = "editbox"
    elseif button:IsObjectType("Slider") then
        elementType = "slider"
    elseif button:IsObjectType("CheckButton") then
        elementType = "checkbox"
    end
    
    local actions = Tooltip:GetActions(buttonName, elementType)
    
    -- If keyboard is visible, add X = Send action
    if ConsoleExperience.keyboard and ConsoleExperience.keyboard.frame and ConsoleExperience.keyboard.frame:IsVisible() then
        -- Add X = Send action to any button when keyboard is visible
        if not actions then
            actions = {}
        end
        -- Check if X action already exists
        local hasXAction = false
        for _, action in ipairs(actions) do
            if action.icon == "x" then
                hasXAction = true
                break
            end
        end
        if not hasXAction then
            table.insert(actions, {icon = "x", prompt = "Send"})
        end
    end
    
    if actions then
        AddPrompts(actions)
    end
    
    GameTooltip:Show()
end)

TooltipHookFrame:SetScript("OnHide", function()
    HideAllIcons()
end)

-- Frame action definitions
Tooltip.frameActions = {}

function Tooltip:Initialize()
    self.frameActions = {
        -- Container (bag) items - A = Pickup, X = Bind, B = Use, Y = Drop
        {
            pattern = "ContainerFrame%d+Item%d+",
            actions = {{icon = "a", prompt = "Pickup"}, {icon = "x", prompt = "Bind"}, {icon = "b", prompt = "Use"}, {icon = "y", prompt = "Drop"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}, {key = "3", action = "CE_CURSOR_DELETE"}}
        },
        -- Character equipment slots - B = Unequip
        {
            pattern = "Character[A-Za-z0-9]+Slot",
            actions = {{icon = "a", prompt = "Select"}, {icon = "b", prompt = "Unequip"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_UNEQUIP"}}
        },
        -- Spellbook tabs
        {
            pattern = "SpellBookFrameTabButton%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Spellbook skill line tabs
        {
            pattern = "SpellBookSkillLineTab%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Spellbook buttons
        {
            pattern = "SpellButton%d+",
            actions = {{icon = "a", prompt = "Cast"}, {icon = "x", prompt = "Bind"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}}
        },
        -- Talent frame
        {
            pattern = "TalentFrameTalent%d+",
            actions = {{icon = "a", prompt = "Learn"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Quest log titles
        {
            pattern = "QuestLogTitle%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Static popup buttons
        {
            pattern = "StaticPopup%d+Button%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Gossip buttons
        {
            pattern = "GossipTitleButton%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Quest title buttons
        {
            pattern = "QuestTitleButton%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Merchant items - B = Buy (right click)
        {
            pattern = "MerchantItem%d+ItemButton",
            actions = {{icon = "a", prompt = "Select"}, {icon = "b", prompt = "Buy"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Loot buttons - B = Loot (right click for auto-loot)
        {
            pattern = "LootButton%d+",
            actions = {{icon = "a", prompt = "Select"}, {icon = "b", prompt = "Loot"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Bank items - B = Withdraw
        {
            pattern = "BankFrameItem%d+",
            actions = {{icon = "a", prompt = "Select"}, {icon = "b", prompt = "Withdraw"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Auction house browse buttons - B = Bid
        {
            pattern = "BrowseButton%d+",
            actions = {{icon = "a", prompt = "Select"}, {icon = "b", prompt = "Bid"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Auction house auctions buttons
        {
            pattern = "AuctionsButton%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- WorldMap buttons - B = Zoom Out
        {
            pattern = "WorldMap.*",
            actions = {{icon = "a", prompt = "Zoom In"}, {icon = "b", prompt = "Zoom Out"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Game menu buttons
        {
            pattern = "GameMenuButton.*",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Console Experience config buttons
        {
            pattern = "ConsoleExperience.*",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Radial menu buttons
        {
            pattern = "CERadialButton%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Spell placement buttons
        {
            pattern = "CEPlacementButton%d+",
            actions = {{icon = "a", prompt = "Pickup / Place"}, {icon = "b", prompt = "Clear"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_PLACEMENT_CLEAR"}}
        },
        -- Macro buttons
        {
            pattern = "MacroButton%d+",
            actions = {{icon = "a", prompt = "Select"}, {icon = "x", prompt = "Bind"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}}
        },
        -- Friends list
        {
            pattern = "FriendsFrameFriendButton%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Mail items
        {
            pattern = "MailItem%d+Button",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Trainer skill buttons
        {
            pattern = "ClassTrainerSkill%d+",
            actions = {{icon = "a", prompt = "Learn"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Profession skill buttons
        {
            pattern = "TradeSkillSkill%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Profession reagent buttons
        {
            pattern = "TradeSkillReagent%d+",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Roll frame buttons
        {
            pattern = "GroupLootFrame%d+.*Button",
            actions = {{icon = "a", prompt = "Select"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Trade items
        {
            pattern = "TradePlayerItem%d+ItemButton",
            actions = {{icon = "a", prompt = "Trade"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- UICheckButton (checkboxes)
        {
            pattern = ".*CheckButton.*",
            actions = {{icon = "a", prompt = "Toggle"}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
    }
    
    -- Special actions for element types (not pattern based)
    self.elementTypeActions = {
        editbox = {{icon = "a", prompt = "Edit Text"}},
        slider = {{icon = "a", prompt = "Increase"}, {icon = "b", prompt = "Decrease"}},
        checkbox = {{icon = "a", prompt = "Toggle"}},
    }
end

function Tooltip:GetActions(buttonName, elementType)
    -- Check button name patterns FIRST (more specific than element type)
    if buttonName then
        for _, config in ipairs(self.frameActions) do
            if string.find(buttonName, config.pattern) then
                return config.actions
            end
        end
    end
    
    -- Fall back to element type for generic handling (editbox, slider, checkbox)
    if elementType and self.elementTypeActions and self.elementTypeActions[elementType] then
        return self.elementTypeActions[elementType]
    end
    
    return {{icon = "a", prompt = "Click"}}
end

function Tooltip:GetBindings(buttonName)
    local bindings = nil
    
    if buttonName then
        for _, config in ipairs(self.frameActions) do
            if string.find(buttonName, config.pattern) then
                bindings = config.bindings
                break
            end
        end
    end
    
    -- Default binding if no pattern matched
    if not bindings then
        bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
    end
    
    -- If keyboard is visible, add X = Send binding (key "2" = CE_CURSOR_BIND)
    if ConsoleExperience.keyboard and ConsoleExperience.keyboard.frame and ConsoleExperience.keyboard.frame:IsVisible() then
        -- Check if X binding already exists
        local hasXBinding = false
        for _, binding in ipairs(bindings) do
            if binding.key == "2" then
                hasXBinding = true
                break
            end
        end
        if not hasXBinding then
            table.insert(bindings, {key = "2", action = "CE_CURSOR_BIND"})
        end
    end
    
    return bindings
end

-- ============================================================================
-- Tooltip Display
-- ============================================================================

function Tooltip:ShowButtonTooltip(button)
    if not button then return end
    
    -- Hide all icons first
    HideAllIcons()
    
    local buttonName = button:GetName()
    if not buttonName then
        buttonName = ""
    end
    
    -- Handle different button types FIRST (before element type checks)
    -- This ensures specific button types like SpellButton are handled correctly
    if string.find(buttonName, "ContainerFrame%d+Item%d+") then
        -- Bag item
        local _, _, bagID = string.find(buttonName, "ContainerFrame(%d+)")
        if bagID then
            bagID = tonumber(bagID) - 1
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(bagID, button:GetID())
        end
    elseif string.find(buttonName, "Character[A-Za-z0-9]+Slot") then
        -- Equipment slot
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetInventoryItem("player", button:GetID())
    elseif string.find(buttonName, "SpellBookFrameTabButton%d+") or string.find(buttonName, "SpellBookSkillLineTab%d+") then
        -- Spellbook tabs - use button's OnEnter script
        local onEnterScript = button:GetScript("OnEnter")
        if onEnterScript then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local oldThis = this
            this = button
            onEnterScript()
            this = oldThis
        end
    elseif string.find(buttonName, "SpellButton%d+") then
        -- Spellbook spell
        if SpellBookFrame and SpellBookFrame.bookType then
            local id = button:GetID()
            local spellID = id
            if SpellBookFrame.bookType ~= BOOKTYPE_PET then
                spellID = id + SpellBookFrame.selectedSkillLineOffset + 
                    (SPELLS_PER_PAGE * (SPELLBOOK_PAGENUMBERS[SpellBookFrame.selectedSkillLine] - 1))
            end
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetSpell(spellID, SpellBookFrame.bookType)
        end
    elseif string.find(buttonName, "LootButton%d+") then
        -- Loot item
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetLootItem(button:GetID())
    elseif string.find(buttonName, "MerchantItem%d+ItemButton") then
        -- Merchant item
        local _, _, itemIndex = string.find(buttonName, "MerchantItem(%d+)")
        if itemIndex then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetMerchantItem(tonumber(itemIndex))
        end
    elseif string.find(buttonName, "BankFrameItem%d+") then
        -- Bank item
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetInventoryItem("player", button:GetID())
    elseif string.find(buttonName, "MailItem%d+Button") then
        -- Mail item - use button's OnEnter script (Classic WoW doesn't have SetMailItem)
        local onEnterScript = button:GetScript("OnEnter")
        if onEnterScript then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local oldThis = this
            this = button
            onEnterScript()
            this = oldThis
        end
    elseif string.find(buttonName, "ClassTrainerSkill%d+") then
        -- Trainer skill - use button's OnEnter script (Classic WoW doesn't have SetTrainerService)
        local onEnterScript = button:GetScript("OnEnter")
        if onEnterScript then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local oldThis = this
            this = button
            onEnterScript()
            this = oldThis
        end
    elseif string.find(buttonName, "TradeSkillSkill%d+") then
        -- Profession skill - use button's OnEnter script (Classic WoW doesn't have SetTradeSkillSkill)
        local onEnterScript = button:GetScript("OnEnter")
        if onEnterScript then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local oldThis = this
            this = button
            onEnterScript()
            this = oldThis
        end
    elseif string.find(buttonName, "TradeSkillReagent%d+") then
        -- Profession reagent - use button's OnEnter script (Classic WoW doesn't have SetTradeSkillReagent)
        local onEnterScript = button:GetScript("OnEnter")
        if onEnterScript then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local oldThis = this
            this = button
            onEnterScript()
            this = oldThis
        end
    else
        -- Check element types for generic UI elements
        -- Determine element type
        local elementType = nil
        if button:IsObjectType("EditBox") then
            elementType = "editbox"
        elseif button:IsObjectType("Slider") then
            elementType = "slider"
        elseif button:IsObjectType("CheckButton") and not string.find(buttonName, "SpellButton%d+") then
            -- Only treat as checkbox if it's not a SpellButton
            elementType = "checkbox"
        end
        
        -- Handle EditBox specially
        if elementType == "editbox" then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local currentText = button:GetText() or ""
            if currentText ~= "" then
                GameTooltip:SetText("Current: " .. currentText)
            else
                GameTooltip:SetText("Text Input")
            end
            GameTooltip:Show()
            return
        end
        
        -- Handle Slider specially
        if elementType == "slider" then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local value = button:GetValue() or 0
            local min, max = button:GetMinMaxValues()
            GameTooltip:SetText(string.format("Value: %.1f (%.1f - %.1f)", value, min, max))
            GameTooltip:Show()
            return
        end
        
        -- Handle CheckButton specially
        if elementType == "checkbox" then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            -- Try to get label from stored property or button text
            local label = button.label or (button.GetText and button:GetText()) or buttonName or "Checkbox"
            local checked = button:GetChecked() and "Enabled" or "Disabled"
            GameTooltip:SetText(label)
            GameTooltip:AddLine("Status: " .. checked, 0.7, 0.7, 0.7)
            GameTooltip:Show()
            return
        end
        
        -- Try to run the button's OnEnter script
        local onEnterScript = button:GetScript("OnEnter")
        if onEnterScript then
            -- Save current 'this' and set it to button
            local oldThis = this
            this = button
            onEnterScript()
            this = oldThis
        else
            -- Show a simple tooltip with button text if available
            local buttonText = button.GetText and button:GetText()
            if buttonText and buttonText ~= "" then
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:SetText(buttonText)
                GameTooltip:Show()
            end
        end
    end
    
    -- Note: Action prompts are added automatically via TooltipHookFrame OnShow
end

function Tooltip:HideButtonTooltip()
    HideAllIcons()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

-- Module loaded silently
