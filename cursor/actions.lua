--[[
    ConsoleExperienceClassic - Actions Module
    
    Defines cursor actions that can be bound to keys
]]

-- ============================================================================
-- Cursor Movement
-- ============================================================================

function CE_MoveCursor(direction)
    local Cursor = ConsoleExperience.cursor
    
    if not Cursor.navigationState.currentButton then
        CE_Debug("MoveCursor: No current button")
        return
    end
    
    if not Cursor.navigationState.closest then
        CE_Debug("MoveCursor: No closest buttons calculated")
        return
    end
    
    local targetButton = nil
    local oppositeDirection = nil
    
    -- Determine opposite direction first (always set it)
    if direction == "UP" then
        oppositeDirection = "down"
        if Cursor.navigationState.closest.up then
            targetButton = Cursor.navigationState.closest.up.button
        end
    elseif direction == "DOWN" then
        oppositeDirection = "up"
        if Cursor.navigationState.closest.down then
            targetButton = Cursor.navigationState.closest.down.button
        end
    elseif direction == "LEFT" then
        oppositeDirection = "right"
        if Cursor.navigationState.closest.left then
            targetButton = Cursor.navigationState.closest.left.button
        end
    elseif direction == "RIGHT" then
        oppositeDirection = "left"
        if Cursor.navigationState.closest.right then
            targetButton = Cursor.navigationState.closest.right.button
        end
    end
    
    -- If no button found in requested direction, wrap to farthest button in opposite direction
    if not targetButton and oppositeDirection then
        CE_Debug("Wrapping: No button in " .. direction .. ", searching for farthest " .. oppositeDirection)
        
        local currentButton = Cursor.navigationState.currentButton
        local currentFrame = Cursor.navigationState.currentFrame
        
        -- Refresh navigation state to ensure allButtons is up to date
        if currentButton and currentFrame then
            Cursor:UpdateNavigationState(currentButton, currentFrame)
        end
        
        local allButtons = Cursor.navigationState.allButtons
        local currentX, currentY = currentButton:GetCenter()
        
        local buttonCount = 0
        if allButtons then
            buttonCount = table.getn(allButtons)
        end
        
        CE_Debug("Total buttons available: " .. buttonCount)
        CE_Debug("Wrapping: No button in " .. direction .. ", searching for farthest " .. oppositeDirection .. " (total buttons: " .. buttonCount .. ")")
        
        if currentX and currentY and allButtons and table.getn(allButtons) > 0 then
            local farthestButton = nil
            local maxAxisDistance = 0
            
            -- Debug: show current button info
            local currentButtonName = currentButton:GetName() or "unnamed"
            CE_Debug("Current button: " .. currentButtonName .. " at (" .. string.format("%.1f", currentX) .. ", " .. string.format("%.1f", currentY) .. ")")
            
            -- Tolerance for considering buttons on the same row/column (in pixels)
            local axisTolerance = 36  -- Allow differences due to UI scaling and button spacing
            
            -- Find farthest button in opposite direction along the same axis
            for _, buttonInfo in ipairs(allButtons) do
                local buttonName = buttonInfo.name or "unnamed"
                local isCurrentButton = (buttonInfo.button == currentButton)
                CE_Debug("Checking button " .. buttonName .. ": isCurrent=" .. tostring(isCurrentButton) .. ", visible=" .. tostring(buttonInfo.button:IsVisible()))
                
                if not isCurrentButton and buttonInfo.button:IsVisible() then
                    local dx = buttonInfo.x - currentX
                    local dy = buttonInfo.y - currentY
                    local angle = math.atan2(dy, dx)
                    local degrees = angle * 180 / math.pi
                    
                    local onSameAxis = false
                    local axisDistance = 0
                    
                    if oppositeDirection == "left" or oppositeDirection == "right" then
                        -- For LEFT/RIGHT wrapping, find buttons on the same row (same Y)
                        local yDiff = math.abs(buttonInfo.y - currentY)
                        CE_Debug("Button " .. buttonName .. ": yDiff=" .. string.format("%.1f", yDiff) .. ", tolerance=" .. axisTolerance)
                        if yDiff <= axisTolerance then
                            onSameAxis = true
                            -- Distance along X axis (positive = right, negative = left)
                            axisDistance = dx
                            
                            -- For LEFT wrapping (oppositeDirection="right"), we want the rightmost button (positive dx)
                            -- For RIGHT wrapping (oppositeDirection="left"), we want the leftmost button (negative dx)
                            if oppositeDirection == "right" then
                                -- Wrapping LEFT - looking for rightmost button (positive dx)
                                CE_Debug("Button " .. buttonName .. ": axisDistance=" .. string.format("%.1f", axisDistance) .. ", maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ", condition=" .. tostring(axisDistance > 0 and axisDistance > maxAxisDistance))
                                if axisDistance > 0 and axisDistance > maxAxisDistance then
                                    maxAxisDistance = axisDistance
                                    farthestButton = buttonInfo.button
                                    CE_Debug("SELECTED as farthest: " .. buttonName .. " (new maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ")")
                                end
                            elseif oppositeDirection == "left" then
                                -- Wrapping RIGHT - looking for leftmost button (negative dx)
                                CE_Debug("Button " .. buttonName .. ": axisDistance=" .. string.format("%.1f", axisDistance) .. ", maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ", condition=" .. tostring(axisDistance < 0 and math.abs(axisDistance) > maxAxisDistance))
                                if axisDistance < 0 and math.abs(axisDistance) > maxAxisDistance then
                                    maxAxisDistance = math.abs(axisDistance)
                                    farthestButton = buttonInfo.button
                                    CE_Debug("SELECTED as farthest: " .. buttonName .. " (new maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ")")
                                end
                            end
                        end
                    elseif oppositeDirection == "up" or oppositeDirection == "down" then
                        -- For UP/DOWN wrapping, find buttons on the same column (same X)
                        local xDiff = math.abs(buttonInfo.x - currentX)
                        CE_Debug("Button " .. buttonName .. ": xDiff=" .. string.format("%.1f", xDiff) .. ", tolerance=" .. axisTolerance)
                        if xDiff <= axisTolerance then
                            onSameAxis = true
                            -- Distance along Y axis (positive = up, negative = down)
                            axisDistance = dy
                            
                            -- For UP wrapping (oppositeDirection="down"), we want the bottommost button (negative dy)
                            -- For DOWN wrapping (oppositeDirection="up"), we want the topmost button (positive dy)
                            if oppositeDirection == "down" then
                                -- Wrapping UP - looking for bottommost button (negative dy)
                                CE_Debug("Button " .. buttonName .. ": axisDistance=" .. string.format("%.1f", axisDistance) .. ", maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ", condition=" .. tostring(axisDistance < 0 and math.abs(axisDistance) > maxAxisDistance))
                                if axisDistance < 0 and math.abs(axisDistance) > maxAxisDistance then
                                    maxAxisDistance = math.abs(axisDistance)
                                    farthestButton = buttonInfo.button
                                    CE_Debug("SELECTED as farthest: " .. buttonName .. " (new maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ")")
                                end
                            elseif oppositeDirection == "up" then
                                -- Wrapping DOWN - looking for topmost button (positive dy)
                                CE_Debug("Button " .. buttonName .. ": axisDistance=" .. string.format("%.1f", axisDistance) .. ", maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ", condition=" .. tostring(axisDistance > 0 and axisDistance > maxAxisDistance))
                                if axisDistance > 0 and axisDistance > maxAxisDistance then
                                    maxAxisDistance = axisDistance
                                    farthestButton = buttonInfo.button
                                    CE_Debug("SELECTED as farthest: " .. buttonName .. " (new maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ")")
                                end
                            end
                        end
                    end
                    
                    if onSameAxis then
                        local buttonName = buttonInfo.name or "unnamed"
                        local axisName = (oppositeDirection == "left" or oppositeDirection == "right") and "row" or "column"
                        CE_Debug("Found button " .. buttonName .. " on same " .. axisName .. ": axisDist=" .. string.format("%.1f", axisDistance))
                        CE_Debug("  Found button " .. buttonName .. " on same axis: axisDist=" .. string.format("%.1f", axisDistance))
                    end
                end
            end
            
            CE_Debug("After loop: farthestButton=" .. tostring(farthestButton ~= nil) .. ", maxAxisDistance=" .. string.format("%.1f", maxAxisDistance))
            
            if farthestButton then
                targetButton = farthestButton
                local axisName = (oppositeDirection == "left" or oppositeDirection == "right") and "row" or "column"
                CE_Debug("Wrapping to farthest " .. oppositeDirection .. " button on same " .. axisName .. " (axis distance: " .. string.format("%.1f", maxAxisDistance) .. ")")
            else
                local axisName = (oppositeDirection == "left" or oppositeDirection == "right") and "row" or "column"
                CE_Debug("No buttons found on same " .. axisName .. " for wrapping (maxAxisDistance=" .. string.format("%.1f", maxAxisDistance) .. ")")
            end
        else
            CE_Debug("Cannot wrap: currentX=" .. tostring(currentX) .. ", currentY=" .. tostring(currentY) .. ", allButtons=" .. tostring(allButtons) .. ", buttonCount=" .. (allButtons and table.getn(allButtons) or 0))
            CE_Debug("Cannot wrap: currentX=" .. tostring(currentX) .. ", currentY=" .. tostring(currentY) .. ", allButtons=" .. tostring(allButtons))
        end
    end
    
    if targetButton then
        CE_Debug("Moving to: " .. (targetButton:GetName() or "unnamed"))
        Cursor:MoveCursorToButton(targetButton)
    else
        CE_Debug("No button in direction: " .. direction .. " (and no opposite direction available)")
    end
end

-- ============================================================================
-- Cursor Click
-- ============================================================================

function CE_ClickCursor(mouseButton)
    local Cursor = ConsoleExperience.cursor
    
    if not Cursor.navigationState.currentButton then
        return
    end
    
    local element = Cursor.navigationState.currentButton
    
    -- Hide tooltip before clicking
    if Cursor.tooltip then
        Cursor.tooltip:HideButtonTooltip()
    end
    
    -- Handle placement buttons specially
    local buttonName = element:GetName()
    if buttonName and string.find(buttonName, "CEPlacementButton%d+") then
        local actionSlot = element.actionSlot
        if actionSlot then
            if mouseButton == "LeftButton" then
                -- A button: Pickup if slot has item and cursor is empty, Place if cursor has item
                local hasCursorItem = CursorHasItem() or CursorHasSpell()
                local hasSlotAction = HasAction(actionSlot)
                
                if hasCursorItem then
                    -- Place item from cursor into slot
                    PlaceAction(actionSlot)
                    CE_Debug("Placed item in action slot " .. actionSlot)
                    
                    -- Update button display
                    if ConsoleExperience.placement and ConsoleExperience.placement.UpdateButton then
                        ConsoleExperience.placement:UpdateButton(element)
                    end
                    
                    -- Update main action bar
                    if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                        ConsoleExperience.actionbars:UpdateAllButtons()
                    end
                    
                    -- Clear fake cursor held item
                    if ConsoleExperience.cursor then
                        ConsoleExperience.cursor:ClearHeldItemTexture()
                    end
                elseif hasSlotAction then
                    -- Pickup item from slot (only if slot has action and cursor is empty)
                    -- Get texture BEFORE picking up (slot will be empty after PickupAction)
                    local texture = GetActionTexture(actionSlot)
                    if texture then
                        PickupAction(actionSlot)
                        CE_Debug("Picked up item from action slot " .. actionSlot .. " (texture: " .. texture .. ")")
                        
                        -- Update button display
                        if ConsoleExperience.placement and ConsoleExperience.placement.UpdateButton then
                            ConsoleExperience.placement:UpdateButton(element)
                        end
                        
                        -- Show held item on fake cursor (use texture we got before pickup)
                        if ConsoleExperience.cursor and ConsoleExperience.cursor.SetHeldItemTexture then
                            ConsoleExperience.cursor:SetHeldItemTexture(texture)
                        end
                    else
                        CE_Debug("Slot " .. actionSlot .. " has action but no texture - skipping pickup")
                    end
                else
                    CE_Debug("Slot " .. actionSlot .. " is empty and cursor is empty - no action")
                end
            elseif mouseButton == "RightButton" then
                -- B button: Clear slot
                CE_PLACEMENT_CLEAR()
            end
            return
        end
    end
    
    -- Handle different element types
    if element:IsObjectType("EditBox") then
        -- Focus the EditBox for text input
        element:SetFocus()
        CE_Debug("EditBox focused")
    elseif element:IsObjectType("Slider") then
        -- For sliders, left/right click could adjust value
        if mouseButton == "LeftButton" then
            local min, max = element:GetMinMaxValues()
            local current = element:GetValue()
            local step = element:GetValueStep() or ((max - min) / 10)
            element:SetValue(current + step)
        else
            local min, max = element:GetMinMaxValues()
            local current = element:GetValue()
            local step = element:GetValueStep() or ((max - min) / 10)
            element:SetValue(current - step)
        end
    elseif buttonName and string.find(buttonName, "ContainerFrame%d+Item%d+") then
        -- Container items: A button picks up item (or places/swaps if cursor has item)
        -- B button uses the item directly without picking up
        if mouseButton == "LeftButton" then
            -- Check cursor state before clicking
            local hadCursorItem = CursorHasItem() or CursorHasSpell()
            
            if hadCursorItem then
                -- Cursor has item - check if slot has item (for swapping)
                local slotItemTexture = nil
                local _, _, bagID = string.find(buttonName, "ContainerFrame(%d+)")
                if bagID then
                    bagID = tonumber(bagID) - 1
                    local slotID = element:GetID()
                    -- Get slot item texture before clicking (in case we swap)
                    slotItemTexture = GetContainerItemInfo(bagID, slotID)
                end
                
                -- Regular click will place cursor item (and swap if slot has item)
                if element.Click then
                    element:Click(mouseButton)
                end
                
                -- Update fake cursor based on result
                if CursorHasItem() or CursorHasSpell() then
                    -- Item swap occurred - show the swapped item on fake cursor
                    if slotItemTexture and Cursor and Cursor.SetHeldItemTexture then
                        Cursor:SetHeldItemTexture(slotItemTexture)
                    end
                else
                    -- Item was placed (slot was empty) - clear fake cursor
                    if Cursor and Cursor.ClearHeldItemTexture then
                        Cursor:ClearHeldItemTexture()
                    end
                end
            else
                -- Cursor is empty - use CE_PickupItem to pick up and show on fake cursor
                CE_PickupItem()
            end
        elseif mouseButton == "RightButton" then
            -- Right click (B button) should use the item directly without picking up
            -- Use CE_UseItem which uses the item without picking it up
            CE_UseItem()
            return -- Return early to skip the regular refresh/tooltip logic
        end
    elseif buttonName and string.find(buttonName, "Character[A-Za-z0-9]+Slot") then
        -- Character equipment slots: "Select" (A button) should NOT pick up the item
        -- Only "Bind" (X button via CE_PickupItem) should pick it up
        -- So we skip the regular click for equipment slots on left click
        if mouseButton == "LeftButton" then
            -- Just refresh tooltip, don't click (which might pick up the item)
            CE_Debug("Select action on equipment slot - skipping click to prevent pickup")
        elseif mouseButton == "RightButton" then
            -- Right click (B button) should unequip directly without picking up
            -- Use CE_UnequipItem which puts item directly in backpack
            CE_UnequipItem()
            return -- Return early to skip the regular refresh/tooltip logic
        end
    elseif element.Click then
        -- Regular button click
        element:Click(mouseButton)
    end
    
    -- Refresh frame state after click
    Cursor:RefreshFrame()
    
    -- Show tooltip again if element is still visible
    if Cursor.navigationState.currentButton and Cursor.navigationState.currentButton:IsVisible() then
        if Cursor.tooltip then
            Cursor.tooltip:ShowButtonTooltip(Cursor.navigationState.currentButton)
        end
    end
end

-- ============================================================================
-- Specific Actions
-- ============================================================================

function CE_DeleteItem()
    local Cursor = ConsoleExperience.cursor
    local button = Cursor.navigationState.currentButton
    
    if not button then return end
    
    local buttonName = button:GetName()
    if not buttonName then return end
    
    -- Check if this is a bag item
    if string.find(buttonName, "ContainerFrame%d+Item%d+") then
        local _, _, bagID = string.find(buttonName, "ContainerFrame(%d+)")
        if bagID then
            bagID = tonumber(bagID) - 1
            local slotID = button:GetID()
            
            -- Pick up and delete the item
            PickupContainerItem(bagID, slotID)
            if CursorHasItem() then
                DeleteCursorItem()
            end
            
            -- Clear cursor state after deletion (item is destroyed, not placed)
            -- This prevents the placement frame from showing
            if CursorHasItem() or CursorHasSpell() then
                ClearCursor()
            end
            
            -- Clear fake cursor texture if it exists
            if Cursor and Cursor.ClearHeldItemTexture then
                Cursor:ClearHeldItemTexture()
            end
            
            -- Ensure placement frame is hidden since item was deleted
            if ConsoleExperience.placement and ConsoleExperience.placement.Hide then
                ConsoleExperience.placement:Hide()
            end
            
            -- Refresh frame state
            if Cursor then
                Cursor:RefreshFrame()
            end
        end
    end
end

function CE_UseItem()
    local Cursor = ConsoleExperience.cursor
    local button = Cursor.navigationState.currentButton
    
    if not button then return end
    
    local buttonName = button:GetName()
    if not buttonName then return end
    
    -- Check if this is a container item
    if string.find(buttonName, "ContainerFrame%d+Item%d+") then
        local _, _, bagID = string.find(buttonName, "ContainerFrame(%d+)")
        if bagID then
            bagID = tonumber(bagID) - 1
            local slotID = button:GetID()
            
            -- Use the item directly without picking it up
            UseContainerItem(bagID, slotID)
            
            
            -- Refresh frame state
            if Cursor then
                Cursor:RefreshFrame()
            end
        end
    end
end

function CE_UnequipItem()
    local Cursor = ConsoleExperience.cursor
    local button = Cursor.navigationState.currentButton
    
    if not button then return end
    
    local buttonName = button:GetName()
    if not buttonName then return end
    
    -- Check if this is an equipment slot
    if string.find(buttonName, "Character[A-Za-z0-9]+Slot") then
        local slotId = button:GetID()
        if slotId then
            PickupInventoryItem(slotId)
            PutItemInBackpack()
            
            -- Clear cursor state after unequipping (item goes directly to backpack)
            -- This prevents the placement frame from showing
            if CursorHasItem() or CursorHasSpell() then
                ClearCursor()
            end
            
            -- Clear fake cursor texture if it exists
            if Cursor and Cursor.ClearHeldItemTexture then
                Cursor:ClearHeldItemTexture()
            end
            
            -- Ensure placement frame is hidden since item went directly to backpack
            if ConsoleExperience.placement and ConsoleExperience.placement.Hide then
                ConsoleExperience.placement:Hide()
            end
            
            -- Refresh frame state
            if Cursor then
                Cursor:RefreshFrame()
            end
        end
    end
end

function CE_PickupItem()
    local Cursor = ConsoleExperience.cursor
    local button = Cursor.navigationState.currentButton
    
    if not button then return end
    
    local buttonName = button:GetName()
    if not buttonName then return end
    local id = button:GetID()
    
    local pickedUpTexture = nil
    
    -- Handle different button types
    if string.find(buttonName, "ContainerFrame%d+Item%d+") then
        -- Bag item
        local _, _, bagID = string.find(buttonName, "ContainerFrame(%d+)")
        if bagID then
            bagID = tonumber(bagID) - 1
            -- Get the item texture before picking up
            pickedUpTexture = GetContainerItemInfo(bagID, id)
            PickupContainerItem(bagID, id)
        end
    elseif string.find(buttonName, "Character[A-Za-z0-9]+Slot") then
        -- Equipment slot
        pickedUpTexture = GetInventoryItemTexture("player", id)
        PickupInventoryItem(id)
    elseif string.find(buttonName, "SpellButton%d+") then
        -- Spellbook spell
        if SpellBookFrame and SpellBookFrame.bookType then
            local spellID = id
            if SpellBookFrame.bookType ~= BOOKTYPE_PET then
                spellID = id + SpellBookFrame.selectedSkillLineOffset + 
                    (SPELLS_PER_PAGE * (SPELLBOOK_PAGENUMBERS[SpellBookFrame.selectedSkillLine] - 1))
            end
            -- Get the spell texture before picking up
            pickedUpTexture = GetSpellTexture(spellID, SpellBookFrame.bookType)
            PickupSpell(spellID, SpellBookFrame.bookType)
        end
    elseif string.find(buttonName, "MacroButton%d+") then
        -- Macro button
        local macroName, macroTexture = GetMacroInfo(id)
        if macroTexture then
            pickedUpTexture = macroTexture
        end
        PickupMacro(id)
    elseif string.find(buttonName, "CEPlacementButton%d+") then
        -- Placement frame button - use action slot from button
        local actionSlot = button.actionSlot
        if actionSlot then
            pickedUpTexture = GetActionTexture(actionSlot)
            PickupAction(actionSlot)
        end
    elseif string.find(buttonName, "ConsoleActionButton%d+") then
        -- Main action bar button
        local actionSlot = button.actionSlot
        if actionSlot then
            pickedUpTexture = GetActionTexture(actionSlot)
            PickupAction(actionSlot)
        end
    end
    
    -- Update fake cursor to show held item
    if pickedUpTexture and Cursor.SetHeldItemTexture then
        Cursor:SetHeldItemTexture(pickedUpTexture)
    end

    Cursor:RefreshFrame()
end

-- ============================================================================
-- Bind Action (Pickup + Show Placement Frame)
-- ============================================================================

function CE_Bind()
    local Cursor = ConsoleExperience.cursor
    
    -- Use the same pickup logic as CE_PickupItem
    CE_PickupItem()
    
    -- Show placement frame when binding items to action bars
    if CursorHasSpell() or CursorHasItem() then
        if ConsoleExperience.placement then
            ConsoleExperience.placement:Show()
        end
    end
end

-- ============================================================================
-- Close Frame Action
-- ============================================================================

function CE_CloseFrame()
    local Cursor = ConsoleExperience.cursor
    
    -- Find the topmost active frame and close it
    local frameToClose = nil
    
    for frame, _ in pairs(Cursor.navigationState.activeFrames) do
        if frame:IsVisible() then
            frameToClose = frame
            break
        end
    end
    
    if frameToClose then
        local frameName = frameToClose:GetName() or "Unknown"
        CE_Debug("Closing frame: " .. frameName)
        
        -- Use HideUIPanel for standard UI frames, Hide for others
        if frameName == "WorldMapFrame" then
            ToggleWorldMap()
        elseif frameName == "CharacterFrame" then
            ToggleCharacter("PaperDollFrame")
        elseif frameName == "SpellBookFrame" then
            ToggleSpellBook(BOOKTYPE_SPELL)
        elseif frameName == "QuestLogFrame" then
            ToggleQuestLog()
        elseif frameName == "FriendsFrame" then
            ToggleFriendsFrame()
        elseif HideUIPanel then
            HideUIPanel(frameToClose)
        else
            frameToClose:Hide()
        end
    end
end

-- ============================================================================
-- Placement Frame Actions
-- ============================================================================

function CE_PLACEMENT_CLEAR()
    local Cursor = ConsoleExperience.cursor
    local button = Cursor.navigationState.currentButton
    
    if not button then 
        CE_Debug("CE_PLACEMENT_CLEAR: No current button")
        return 
    end
    
    local buttonName = button:GetName()
    if not buttonName or not string.find(buttonName, "CEPlacementButton%d+") then
        CE_Debug("CE_PLACEMENT_CLEAR: Not a placement button: " .. (buttonName or "nil"))
        return
    end
    
    -- Get the action slot from the button
    local actionSlot = button.actionSlot
    if not actionSlot then 
        CE_Debug("CE_PLACEMENT_CLEAR: No action slot")
        return 
    end
    
    -- Check if slot actually has an action
    if not HasAction(actionSlot) then
        CE_Debug("CE_PLACEMENT_CLEAR: Slot " .. actionSlot .. " is already empty")
        return
    end
    
    -- Clear the action slot
    -- Method: Pick up the action, then clear cursor
    -- First ensure cursor is empty (clear any existing cursor item)
    if CursorHasItem() or CursorHasSpell() then
        ClearCursor()
    end
    
    -- Pick up the action from the slot
    PickupAction(actionSlot)
    
    -- Now clear the cursor (this should remove the action from the slot)
    -- Note: ClearCursor() should work for actions in WoW 1.12
    ClearCursor()
    
    CE_Debug("Cleared action slot " .. actionSlot)
    
    -- Update the button display
    if ConsoleExperience.placement and ConsoleExperience.placement.UpdateButton then
        ConsoleExperience.placement:UpdateButton(button)
    end
    
    -- Update main action bar if on current page
    if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
        ConsoleExperience.actionbars:UpdateAllButtons()
    end
    
    -- Refresh cursor frame to update tooltip
    Cursor:RefreshFrame()
end

-- ============================================================================
-- Radial Menu Toggle
-- ============================================================================

function CE_ToggleRadialMenu()
    CE_Debug("Radial menu toggle triggered")
    if ConsoleExperience.radial then
        ConsoleExperience.radial:Toggle()
    else
        CE_Debug("Radial module not found!")
    end
end

-- Module loaded silently

