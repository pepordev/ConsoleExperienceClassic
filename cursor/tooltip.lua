--[[
    ConsoleExperienceClassic - Tooltip Module
    
    Handles tooltip display for cursor navigation with controller button icons
]]

-- Get localized text (with fallback)
local function L(key)
    if ConsoleExperience.locale and ConsoleExperience.locale.T then
        return ConsoleExperience.locale.T(key)
    end
    return key
end

-- Create tooltip module namespace
ConsoleExperience.cursor = ConsoleExperience.cursor or {}
ConsoleExperience.cursor.tooltip = ConsoleExperience.cursor.tooltip or {}
local Tooltip = ConsoleExperience.cursor.tooltip

-- Create a child frame of GameTooltip to hook show/hide events
local TooltipHookFrame = CreateFrame("Frame", nil, GameTooltip)

-- Function to get icon path based on controller type
local function GetIconPath(iconName)
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

-- Text padding to make room for icon (must have enough space for 16px icon)
local textPadding = "        "

-- Create button icon textures on GameTooltip
local aIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
aIcon:SetWidth(16)
aIcon:SetHeight(16)
aIcon:Hide()

local bIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
bIcon:SetWidth(16)
bIcon:SetHeight(16)
bIcon:Hide()

local xIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
xIcon:SetWidth(16)
xIcon:SetHeight(16)
xIcon:Hide()

local yIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
yIcon:SetWidth(16)
yIcon:SetHeight(16)
yIcon:Hide()

local lbIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
lbIcon:SetWidth(16)
lbIcon:SetHeight(16)
lbIcon:Hide()

local rbIcon = GameTooltip:CreateTexture(nil, "OVERLAY")
rbIcon:SetWidth(16)
rbIcon:SetHeight(16)
rbIcon:Hide()

-- Function to update icon textures when controller type changes
local function UpdateIconTextures()
    aIcon:SetTexture(GetIconPath("a"))
    bIcon:SetTexture(GetIconPath("b"))
    xIcon:SetTexture(GetIconPath("x"))
    yIcon:SetTexture(GetIconPath("y"))
    lbIcon:SetTexture(GetIconPath("lb"))
    rbIcon:SetTexture(GetIconPath("rb"))
end

-- Initialize textures on load
UpdateIconTextures()

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
    
    -- Add tooltip help text FIRST (above actions)
    if button.tooltipText then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(button.tooltipText, 1, 1, 1, true)
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
            table.insert(actions, {icon = "x", prompt = L("Send")})
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
            actions = {{icon = "a", prompt = L("Pickup")}, {icon = "x", prompt = L("Bind")}, {icon = "b", prompt = L("Use")}, {icon = "y", prompt = L("Drop")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}, {key = "3", action = "CE_CURSOR_DELETE"}}
        },
        -- pfUI bag items - A = Pickup, X = Bind, B = Use, Y = Drop
        {
            pattern = "pfBag%-?%d+item%d+",
            actions = {{icon = "a", prompt = L("Pickup")}, {icon = "x", prompt = L("Bind")}, {icon = "b", prompt = L("Use")}, {icon = "y", prompt = L("Drop")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}, {key = "3", action = "CE_CURSOR_DELETE"}}
        },
        -- Bagshui bag items - A = Pickup, X = Bind, B = Use, Y = Drop
        {
            pattern = "BagshuiBagsItem%d+",
            actions = {{icon = "a", prompt = L("Pickup")}, {icon = "x", prompt = L("Bind")}, {icon = "b", prompt = L("Use")}, {icon = "y", prompt = L("Drop")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}, {key = "3", action = "CE_CURSOR_DELETE"}}
        },
        -- Bagshui bank items - A = Pickup, X = Bind, B = Use, Y = Drop
        {
            pattern = "BagshuiBankItem%d+",
            actions = {{icon = "a", prompt = L("Pickup")}, {icon = "x", prompt = L("Bind")}, {icon = "b", prompt = L("Use")}, {icon = "y", prompt = L("Drop")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}, {key = "3", action = "CE_CURSOR_DELETE"}}
        },
        -- Bagnon bag items - A = Pickup, X = Bind, B = Use, Y = Drop
        {
            pattern = "BagnonItem%d+",
            actions = {{icon = "a", prompt = L("Pickup")}, {icon = "x", prompt = L("Bind")}, {icon = "b", prompt = L("Use")}, {icon = "y", prompt = L("Drop")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}, {key = "3", action = "CE_CURSOR_DELETE"}}
        },
        -- Bagnon bank items - A = Pickup, X = Bind, B = Use, Y = Drop
        {
            pattern = "BanknonItem%d+",
            actions = {{icon = "a", prompt = L("Pickup")}, {icon = "x", prompt = L("Bind")}, {icon = "b", prompt = L("Use")}, {icon = "y", prompt = L("Drop")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}, {key = "3", action = "CE_CURSOR_DELETE"}}
        },
        -- Character equipment slots - B = Unequip
        {
            pattern = "Character[A-Za-z0-9]+Slot",
            actions = {{icon = "a", prompt = L("Select")}, {icon = "b", prompt = L("Unequip")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_UNEQUIP"}}
        },
        -- Spellbook tabs
        {
            pattern = "SpellBookFrameTabButton%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Spellbook skill line tabs
        {
            pattern = "SpellBookSkillLineTab%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Spellbook buttons
        {
            pattern = "SpellButton%d+",
            actions = {{icon = "a", prompt = L("Cast")}, {icon = "x", prompt = L("Bind")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}}
        },
        -- Talent frame
        {
            pattern = "TalentFrameTalent%d+",
            actions = {{icon = "a", prompt = L("Learn")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Quest log titles
        {
            pattern = "QuestLogTitle%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Static popup buttons
        {
            pattern = "StaticPopup%d+Button%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Gossip buttons
        {
            pattern = "GossipTitleButton%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Quest title buttons
        {
            pattern = "QuestTitleButton%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Merchant items - B = Buy (right click)
        {
            pattern = "MerchantItem%d+ItemButton",
            actions = {{icon = "a", prompt = L("Select")}, {icon = "b", prompt = L("Buy")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Bank items - B = Withdraw
        {
            pattern = "BankFrameItem%d+",
            actions = {{icon = "a", prompt = L("Select")}, {icon = "b", prompt = L("Withdraw")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Auction house browse buttons - B = Bid
        {
            pattern = "BrowseButton%d+",
            actions = {{icon = "a", prompt = L("Select")}, {icon = "b", prompt = L("Bid")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Auction house auctions buttons
        {
            pattern = "AuctionsButton%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- WorldMap buttons - B = Zoom Out
        {
            pattern = "WorldMap.*",
            actions = {{icon = "a", prompt = L("Zoom In")}, {icon = "b", prompt = L("Zoom Out")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_CURSOR_CLICK_RIGHT"}}
        },
        -- Game menu buttons
        {
            pattern = "GameMenuButton.*",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Console Experience config buttons
        {
            pattern = "ConsoleExperience.*",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Radial menu buttons
        {
            pattern = "CERadialButton%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Spell placement buttons
        {
            pattern = "CEPlacementButton%d+",
            actions = {{icon = "a", prompt = L("Pickup / Place")}, {icon = "b", prompt = L("Clear")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "4", action = "CE_PLACEMENT_CLEAR"}}
        },
        -- Macro buttons
        {
            pattern = "MacroButton%d+",
            actions = {{icon = "a", prompt = L("Select")}, {icon = "x", prompt = L("Bind")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}}
        },
        -- Friends list
        {
            pattern = "FriendsFrameFriendButton%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Mail items
        {
            pattern = "MailItem%d+Button",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Trainer skill buttons
        {
            pattern = "ClassTrainerSkill%d+",
            actions = {{icon = "a", prompt = L("Learn")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Profession skill buttons
        {
            pattern = "TradeSkillSkill%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Profession reagent buttons
        {
            pattern = "TradeSkillReagent%d+",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Roll frame buttons
        {
            pattern = "GroupLootFrame%d+.*Button",
            actions = {{icon = "a", prompt = L("Select")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Trade items
        {
            pattern = "TradePlayerItem%d+ItemButton",
            actions = {{icon = "a", prompt = L("Trade")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- UICheckButton (checkboxes)
        {
            pattern = ".*CheckButton.*",
            actions = {{icon = "a", prompt = L("Toggle")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Loot buttons
        {
            pattern = "LootButton%d+",
            actions = {{icon = "a", prompt = L("Loot")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}}
        },
        -- Keyboard keys
        {
            pattern = "CEKeyboardKey.*",
            actions = {{icon = "a", prompt = L("Type")}, {icon = "x", prompt = L("Send")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}}
        },
        -- Keyboard special keys (Shift, Space, Backspace, etc.)
        {
            pattern = "CEKeyboardSpecialKey.*",
            actions = {{icon = "a", prompt = L("Press")}, {icon = "x", prompt = L("Send")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}}
        },
        -- Keyboard emote buttons
        {
            pattern = "CEKeyboardEmote.*",
            actions = {{icon = "a", prompt = L("Emote")}, {icon = "x", prompt = L("Send")}},
            bindings = {{key = "1", action = "CE_CURSOR_CLICK_LEFT"}, {key = "2", action = "CE_CURSOR_BIND"}}
        },
    }
    
    -- Special actions for element types (not pattern based)
    self.elementTypeActions = {
        editbox = {{icon = "a", prompt = L("Edit Text")}},
        slider = {{icon = "a", prompt = L("Increase")}, {icon = "b", prompt = L("Decrease")}},
        checkbox = {{icon = "a", prompt = L("Toggle")}},
    }
end

function Tooltip:GetActions(buttonName, elementType)
    -- Check button name patterns FIRST (more specific than element type)
    if buttonName then
        for _, config in ipairs(self.frameActions) do
            if string.find(buttonName, config.pattern) then
                -- Special handling for container items - dynamic B button text
                if config.pattern == "ContainerFrame%d+Item%d+" or config.pattern == "pfBag%-?%d+item%d+" then
                    return self:GetContainerItemActions()
                end
                return config.actions
            end
        end
    end
    
    -- Fall back to element type for generic handling (editbox, slider, checkbox)
    if elementType and self.elementTypeActions and self.elementTypeActions[elementType] then
        return self.elementTypeActions[elementType]
    end
    
    return {{icon = "a", prompt = L("Click")}}
end

-- Get dynamic actions for container (bag) items based on open frames
function Tooltip:GetContainerItemActions()
    local bAction = L("Use")  -- Default action
    
    -- Check if merchant frame is visible
    if MerchantFrame and MerchantFrame:IsVisible() then
        bAction = L("Sell")
    -- Check if auction frame is visible
    elseif AuctionFrame and AuctionFrame:IsVisible() then
        bAction = L("Auction")
    -- Check if trade frame is visible
    elseif TradeFrame and TradeFrame:IsVisible() then
        bAction = L("Trade")
    -- Check if mail frame is visible (send mail)
    elseif SendMailFrame and SendMailFrame:IsVisible() then
        bAction = L("Attach")
    -- Check if bank frame is visible
    elseif BankFrame and BankFrame:IsVisible() then
        bAction = L("Deposit")
    end
    
    return {
        {icon = "a", prompt = L("Pickup")},
        {icon = "x", prompt = L("Bind")},
        {icon = "b", prompt = bAction},
        {icon = "y", prompt = L("Drop")}
    }
end

function Tooltip:GetBindings(buttonName)
    local bindings = {}
    local isKeyboardButton = false
    
    -- Check if this is a party/raid/player frame (healer mode - D-pad only)
    local isHealerModeFrame = false
    if buttonName and ConsoleExperience.hooks and ConsoleExperience.hooks.IsPartyRaidFrame then
        isHealerModeFrame = ConsoleExperience.hooks:IsPartyRaidFrame(buttonName)
    end
    
    -- Always include base navigation bindings (these never change)
    local CursorKeys = ConsoleExperience.cursor.keybindings
    if CursorKeys then
        table.insert(bindings, {key = CursorKeys.CURSOR_CONTROLS.up, action = "CE_CURSOR_MOVE_UP"})
        table.insert(bindings, {key = CursorKeys.CURSOR_CONTROLS.down, action = "CE_CURSOR_MOVE_DOWN"})
        table.insert(bindings, {key = CursorKeys.CURSOR_CONTROLS.left, action = "CE_CURSOR_MOVE_LEFT"})
        table.insert(bindings, {key = CursorKeys.CURSOR_CONTROLS.right, action = "CE_CURSOR_MOVE_RIGHT"})
    end
    
    -- For healer mode frames, only return D-pad bindings (no action buttons)
    if isHealerModeFrame then
        return bindings
    end
    
    -- Get context-specific bindings for this button
    local contextBindings = nil
    if buttonName then
        for _, config in ipairs(self.frameActions) do
            if string.find(buttonName, config.pattern) then
                contextBindings = config.bindings
                -- Check if this is a keyboard button (already has key "2" binding)
                if string.find(buttonName, "CEKeyboard") then
                    isKeyboardButton = true
                end
                break
            end
        end
    end
    
    -- Add context-specific bindings (these override base bindings for same keys)
    if contextBindings then
        for _, binding in ipairs(contextBindings) do
            -- Replace existing binding if key already exists, otherwise add
            local found = false
            for i, existingBinding in ipairs(bindings) do
                if existingBinding.key == binding.key then
                    bindings[i] = binding
                    found = true
                    break
                end
            end
            if not found then
                table.insert(bindings, binding)
            end
        end
    else
        -- Default binding if no pattern matched
        table.insert(bindings, {key = "1", action = "CE_CURSOR_CLICK_LEFT"})
    end
    
    -- If keyboard is visible, add X = Send binding (key "2" = CE_CURSOR_BIND)
    -- But skip this for keyboard buttons themselves (they already have it in frameActions)
    if not isKeyboardButton and ConsoleExperience.keyboard and ConsoleExperience.keyboard.frame and ConsoleExperience.keyboard.frame:IsVisible() then
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
    
    -- Default cancel binding if not set
    local hasCancelBinding = false
    if CursorKeys then
        for _, binding in ipairs(bindings) do
            if binding.key == CursorKeys.CURSOR_CONTROLS.cancel then
                hasCancelBinding = true
                break
            end
        end
        if not hasCancelBinding then
            table.insert(bindings, {key = CursorKeys.CURSOR_CONTROLS.cancel, action = "CE_CURSOR_CLOSE"})
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
        -- Blizzard bag item
        local _, _, bagID = string.find(buttonName, "ContainerFrame(%d+)")
        if bagID then
            bagID = tonumber(bagID) - 1
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(bagID, button:GetID())
        end
    elseif string.find(buttonName, "pfBag%-?%d+item%d+") then
        -- pfUI bag item: "pfBag{bag}item{slot}"
        local _, _, bagNum, slotNum = string.find(buttonName, "pfBag(%-?%d+)item(%d+)")
        if bagNum and slotNum then
            local bagID = tonumber(bagNum)
            local slotID = tonumber(slotNum)
            if bagID and slotID then
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:SetBagItem(bagID, slotID)
            end
        end
    elseif string.find(buttonName, "BagshuiBagsItem%d+") or string.find(buttonName, "BagshuiBankItem%d+") then
        -- Bagshui bag/bank item: "BagshuiBagsItem{num}" or "BagshuiBankItem{num}"
        -- Bag and slot info is stored in bagshuiData
        if button.bagshuiData and button.bagshuiData.bagNum and button.bagshuiData.slotNum then
            local bagID = button.bagshuiData.bagNum
            local slotID = button.bagshuiData.slotNum
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(bagID, slotID)
        end
    elseif string.find(buttonName, "BagnonItem%d+") or string.find(buttonName, "BanknonItem%d+") then
        -- Bagnon bag/bank item: "BagnonItem{num}" or "BanknonItem{num}"
        -- Uses same structure as Blizzard: GetID() for slot, GetParent():GetID() for bag
        local parent = button:GetParent()
        if parent then
            local bagID = parent:GetID()
            local slotID = button:GetID()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(bagID, slotID)
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
            local label = button.label or L("Text Input")
            local currentText = button:GetText() or ""
            GameTooltip:SetText(tostring(label))
            if currentText ~= "" then
                GameTooltip:AddLine(L("Current: ") .. currentText, 0.7, 0.7, 0.7)
            end
            -- tooltipText is added in OnShow handler (above actions)
            GameTooltip:Show()
            return
        end
        
        -- Handle Slider specially
        if elementType == "slider" then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local label = button.label or "Slider"
            local value = button:GetValue() or 0
            local min, max = button:GetMinMaxValues()
            GameTooltip:SetText(tostring(label))
            GameTooltip:AddLine(string.format("Value: %.1f (%.1f - %.1f)", value, min, max), 0.7, 0.7, 0.7)
            -- tooltipText is added in OnShow handler (above actions)
            GameTooltip:Show()
            return
        end
        
        -- Handle CheckButton specially
        if elementType == "checkbox" then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            -- Try to get label from stored property or button text
            local label = nil
            -- If label is a FontString (has GetText), get the text from it
            if button.label and type(button.label) == "table" and button.label.GetText then
                label = button.label:GetText()
            -- If label is already a string, use it directly
            elseif button.label and type(button.label) == "string" then
                label = button.label
            end
            if not label or label == "" then
                label = button.GetText and button:GetText()
            end
            if not label or label == "" then
                label = buttonName
            end
            if not label or label == "" then
                label = "Checkbox"
            end
            local checked = button:GetChecked() and L("Enabled") or L("Disabled")
            GameTooltip:SetText(tostring(label))
            GameTooltip:AddLine(L("Status: ") .. checked, 0.7, 0.7, 0.7)
            -- tooltipText is added in OnShow handler (above actions)
            GameTooltip:Show()
            return
        end
        
        -- Check if button has custom tooltip text (config controls, dropdowns, etc.)
        if button.tooltipText or button.label or button.keyChar then
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            local label = nil
            -- For keyboard keys, use keyChar
            if button.keyChar then
                label = button.keyChar
            -- If label is a FontString (has GetText), get the text from it
            elseif button.label and type(button.label) == "table" and button.label.GetText then
                label = button.label:GetText()
            -- If label is already a string, use it directly
            elseif button.label and type(button.label) == "string" then
                label = button.label
            end
            if not label or label == "" then
                label = button.GetText and button:GetText()
            end
            if not label or label == "" then
                label = buttonName
            end
            if not label or label == "" then
                label = "Option"
            end
            GameTooltip:SetText(tostring(label))
            -- tooltipText is added in OnShow handler (above actions)
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
                GameTooltip:SetText(tostring(buttonText))
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
