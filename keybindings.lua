--[[
    ConsoleExperienceClassic - Keybindings Module
    
    Handles keybindings like pfUI does:
    - Creates binding names dynamically with _G["BINDING_NAME_..."]
    - Overrides ActionButtonDown/Up to redirect to our buttons
    - Uses runOnUp="true" in Bindings.xml
    
    40 action slots mapped to keys:
    - Actions 1-10: No modifier (keys 1-0)
    - Actions 11-20: Shift (Shift+1-0)
    - Actions 21-30: Ctrl (Ctrl+1-0)
    - Actions 31-40: Ctrl+Shift (Ctrl+Shift+1-0)
]]

-- ============================================================================
-- Create Binding Names Dynamically (like pfUI does)
-- ============================================================================

-- Binding header
_G["BINDING_HEADER_CONSOLEEXPERIENCE"] = "Console Experience"

-- Controller button names for each position (1-10)
local buttonNames = {
    [1] = "A",
    [2] = "X",
    [3] = "Y",
    [4] = "B",
    [5] = "Down",
    [6] = "Left",
    [7] = "Up",
    [8] = "Right",
    [9] = "RB",
    [10] = "LB",
}

-- Modifier prefixes for each page
local modifierPrefixes = {
    [1] = "",           -- 1-10: No modifier
    [2] = "LT + ",      -- 11-20: Shift = LT
    [3] = "RT + ",      -- 21-30: Ctrl = RT
    [4] = "LT + RT + ", -- 31-40: Shift+Ctrl = LT + RT
}

-- Create all 40 binding names with controller button combos
for i = 1, 40 do
    local page = math.floor((i - 1) / 10) + 1
    local buttonIndex = math.mod(i - 1, 10) + 1
    local buttonName = buttonNames[buttonIndex]
    local modifier = modifierPrefixes[page]
    _G["BINDING_NAME_CE_ACTION_" .. i] = "Action " .. i .. " (" .. modifier .. buttonName .. ")"
end

-- Cursor header and binding names
_G["BINDING_HEADER_CECURSOR"] = "CE Cursor"
_G["BINDING_NAME_CE_CURSOR_MOVE_UP"] = "Cursor Up"
_G["BINDING_NAME_CE_CURSOR_MOVE_DOWN"] = "Cursor Down"
_G["BINDING_NAME_CE_CURSOR_MOVE_LEFT"] = "Cursor Left"
_G["BINDING_NAME_CE_CURSOR_MOVE_RIGHT"] = "Cursor Right"
_G["BINDING_NAME_CE_CURSOR_CLICK_LEFT"] = "Cursor Click"
_G["BINDING_NAME_CE_CURSOR_CLICK_RIGHT"] = "Cursor Right-Click"
_G["BINDING_NAME_CE_CURSOR_PICKUP"] = "Cursor Pickup"
_G["BINDING_NAME_CE_CURSOR_BIND"] = "Cursor Bind"
_G["BINDING_NAME_CE_CURSOR_DELETE"] = "Cursor Delete"
_G["BINDING_NAME_CE_CURSOR_UNEQUIP"] = "Cursor Unequip"
_G["BINDING_NAME_CE_CURSOR_CLOSE"] = "Cursor Close"

-- Radial menu header and binding name
_G["BINDING_HEADER_CERADIAL"] = "CE Radial Menu"
_G["BINDING_NAME_CE_TOGGLE_RADIAL"] = "Toggle Radial Menu"

-- ============================================================================
-- Global Action Button Handler (like pfUI's pfActionButton)
-- ============================================================================

-- Debug flag - set to true to see key press debug info
ConsoleExperience_DEBUG_KEYS = true

function ConsoleExperience_ActionButton(slot)
    -- Don't trigger if chat is open
    if ChatFrameEditBox and ChatFrameEditBox:IsShown() then return end
    
    -- Only trigger on key down (keystate is set by WoW for runOnUp bindings)
    if keystate == "down" then
        -- Debug output
        if ConsoleExperience_DEBUG_KEYS then
            local texture = GetActionTexture(slot) or "empty"
            local hasAction = HasAction(slot)
            local iconName = texture
            if texture then
                iconName = string.gsub(texture, ".*\\", "")
            end
            CE_Debug("Slot " .. slot .. " triggered | HasAction: " .. tostring(hasAction) .. " | Icon: " .. tostring(iconName))
        end
        
        -- Use the action (checkCursor=0, onSelf=nil to use normal targeting)
        UseAction(slot, 0)
        
        -- Update button visual
        local buttonNum = math.mod(slot - 1, 10) + 1
        local button = getglobal("ConsoleActionButton" .. buttonNum)
        if button and ConsoleExperience.actionbars then
            ConsoleExperience.actionbars:UpdateButtonState(button)
        end
    end
end

-- ============================================================================
-- Keybindings Module
-- ============================================================================

ConsoleExperienceKeybindings = {}

-- Default key bindings (can be customized)
ConsoleExperienceKeybindings.DEFAULT_KEYS = {
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
}

function ConsoleExperienceKeybindings:SetupDefaultBindings()
    -- Only setup bindings if they haven't been set before
    -- This mimics how pfUI handles initial binding setup
    
    local keys = self.DEFAULT_KEYS
    
    -- Check if useAForJump is enabled in config
    local useAForJump = true  -- Default
    if ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.useAForJump ~= nil then
        useAForJump = ConsoleExperienceDB.config.useAForJump
    end
    
    -- Page 1: No modifier (actions 1-10)
    for i = 1, 10 do
        local currentKey = GetBindingKey("CE_ACTION_" .. i)
        if not currentKey then
            -- Skip key 1 if useAForJump is enabled (will be set to JUMP below)
            if i == 1 and useAForJump then
                CE_Debug("Skipping CE_ACTION_1 setup (useAForJump enabled)")
            else
                SetBinding(keys[i], "CE_ACTION_" .. i)
            end
        end
    end
    
    -- If useAForJump is enabled, ensure key 1 is bound to JUMP
    if useAForJump then
        local currentAction = GetBindingAction(keys[1])
        if currentAction ~= "JUMP" then
            SetBinding(keys[1], "JUMP")
            CE_Debug("Set key 1 to JUMP on startup (useAForJump enabled)")
        end
    end
    
    -- Page 2: Shift (actions 11-20)
    for i = 1, 10 do
        local actionNum = i + 10
        local currentKey = GetBindingKey("CE_ACTION_" .. actionNum)
        if not currentKey then
            SetBinding("SHIFT-" .. keys[i], "CE_ACTION_" .. actionNum)
        end
    end
    
    -- Page 3: Ctrl (actions 21-30)
    for i = 1, 10 do
        local actionNum = i + 20
        local currentKey = GetBindingKey("CE_ACTION_" .. actionNum)
        if not currentKey then
            SetBinding("CTRL-" .. keys[i], "CE_ACTION_" .. actionNum)
        end
    end
    
    -- Page 4: Ctrl+Shift (actions 31-40)
    for i = 1, 10 do
        local actionNum = i + 30
        local currentKey = GetBindingKey("CE_ACTION_" .. actionNum)
        if not currentKey then
            SetBinding("CTRL-SHIFT-" .. keys[i], "CE_ACTION_" .. actionNum)
        end
    end
    
    -- Radial menu: Shift+Escape
    SetBinding("SHIFT-ESCAPE", "CE_TOGGLE_RADIAL")
    CE_Debug("Radial menu bound to SHIFT-ESCAPE")
    
    -- Save bindings (1 = account-wide)
    SaveBindings(1)
    
    CE_Debug("Default keybindings set!")
end

function ConsoleExperienceKeybindings:Initialize()
    -- Check if CE_ACTION_1 binding exists (meaning Bindings.xml loaded correctly)
    local testKey = GetBindingKey("CE_ACTION_1")
    
    if testKey then
        CE_Debug("Keybindings loaded! CE_ACTION_1 bound to: " .. testKey)
    else
        CE_Debug("CE_ACTION_1 not bound yet, setting up defaults...")
        self:SetupDefaultBindings()
    end
    
    -- ALWAYS enforce useAForJump setting on every load/reload
    self:EnforceJumpBinding()
    
    -- Override default action button handlers like pfUI does
    -- This redirects default action bar keypresses to our buttons
    _G.ActionButtonDown = function(id)
        ConsoleExperience_ActionButton(id)
    end
    _G.ActionButtonUp = function(id)
        -- We use runOnUp, so this is handled by ConsoleExperience_ActionButton
    end
    
    CE_Debug("Keybindings module initialized!")
end

-- Enforce the useAForJump config setting (called on every load/reload)
function ConsoleExperienceKeybindings:EnforceJumpBinding()
    local keys = self.DEFAULT_KEYS
    
    -- Check if useAForJump is enabled in config
    local useAForJump = true  -- Default
    if ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.useAForJump ~= nil then
        useAForJump = ConsoleExperienceDB.config.useAForJump
    end
    
    local currentBinding = GetBindingAction(keys[1])
    CE_Debug("EnforceJumpBinding: useAForJump=" .. tostring(useAForJump) .. ", current key 1 binding=" .. tostring(currentBinding))
    
    if useAForJump then
        -- Should be JUMP
        if currentBinding ~= "JUMP" then
            SetBinding(keys[1], "JUMP")
            SaveBindings(1)
            CE_Debug("Enforced key 1 to JUMP")
        end
    else
        -- Should be CE_ACTION_1
        if currentBinding ~= "CE_ACTION_1" then
            SetBinding(keys[1], "CE_ACTION_1")
            SaveBindings(1)
            CE_Debug("Enforced key 1 to CE_ACTION_1")
        end
    end
end

-- Attach to main addon
ConsoleExperience.keybindings = ConsoleExperienceKeybindings

-- Function to force reset all keybindings (called from config menu)
function ConsoleExperienceKeybindings:ResetAllBindings()
    local keys = self.DEFAULT_KEYS
    
    -- Check if A button should be JUMP (from config)
    local useAForJump = true  -- Default
    if ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.useAForJump ~= nil then
        useAForJump = ConsoleExperienceDB.config.useAForJump
    end
    
    -- Set all CE_ACTION bindings
    for i = 1, 10 do
        -- Skip key 1 if useAForJump is enabled (it will be set to JUMP below)
        if i == 1 and useAForJump then
            CE_Debug("Skipping CE_ACTION_1 for key 1 (useAForJump enabled)")
        else
            SetBinding(keys[i], "CE_ACTION_" .. i)
        end
        
        -- Modifier keys always use CE actions
        SetBinding("SHIFT-" .. keys[i], "CE_ACTION_" .. (i + 10))
        SetBinding("CTRL-" .. keys[i], "CE_ACTION_" .. (i + 20))
        SetBinding("CTRL-SHIFT-" .. keys[i], "CE_ACTION_" .. (i + 30))
    end
    
    -- If useAForJump is enabled, bind key 1 to JUMP
    if useAForJump then
        SetBinding(keys[1], "JUMP")
        CE_Debug("Set key 1 to JUMP (useAForJump enabled)")
    end
    
    -- Radial menu binding
    SetBinding("SHIFT-ESCAPE", "CE_TOGGLE_RADIAL")
    
    SaveBindings(1)
end
