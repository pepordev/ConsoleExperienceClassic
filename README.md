# ConsoleExperience Classic

A comprehensive controller-style interface addon for World of Warcraft: Vanilla (1.12.1) that transforms the game into a fully playable experience using a gamepad or controller-style keyboard navigation.

> **⚠️ WARNING: This addon is in a really early alpha development stage. Expect bugs, incomplete features, and potential issues. Use at your own risk.**

## Overview

ConsoleExperience Classic provides a complete controller-friendly interface for WoW Vanilla, featuring gamepad-style action bars, cursor navigation, radial menus, virtual keyboard, and extensive customization options. The addon enables players to enjoy World of Warcraft with a controller or keyboard-only navigation system, making it perfect for couch gaming or accessibility needs.

## Features

### 🎮 Controller-Style Action Bars
- **Gamepad Layout**: Two-star action bar layout (D-pad and face buttons) with 40 action slots
- **Modifier Support**: Four action bar pages using LT, RT, and LT+RT modifiers
- **Visual Controller Icons**: Each button displays controller button icons (A, B, X, Y, LB, RB, D-pad)
- **Customizable Layout**: Adjustable button size, padding, position, and scale
- **Jump Binding**: Optional direct jump binding for the A button

![Action Bars](docs/images/bars.png)

### 🖱️ Cursor Navigation System
- **Fake Cursor**: Visual cursor overlay for navigating UI elements
- **Automatic Frame Detection**: Automatically hooks into major UI frames including:
  - Character Frame, Spellbook, Talents, Skills
  - Bags, Bank, Quest Log, World Map
  - Merchant, Auction House, Trade Frame
  - Mailbox (including mail detail view)
  - Trainer Frames (ClassTrainerFrame)
  - Profession Frames (TradeSkillFrame - First Aid, Cooking, etc.)
  - Static Popups, Gossip, Quest Frames
  - And many more!
- **Directional Navigation**: Navigate UI elements using D-pad (UP, DOWN, LEFT, RIGHT)
- **Smart Wrapping**: When reaching the edge of a grid, automatically wraps to the opposite side on the same row/column
- **Context-Sensitive Actions**: Different actions available based on the hovered element (Pickup, Place, Clear, Bind, Use, etc.)
- **Visual Feedback**: Highlighted buttons and tooltips showing available actions with controller button icons
- **Dropdown Menu Support**: Full navigation support for dropdown menus - when a dropdown opens, cursor automatically navigates through all options
- **Enhanced Tooltips**: Detailed tooltips for spells, items, mail, trainer skills, profession skills, and more

### 📋 Spell & Item Placement
- **Placement Frame**: Visual grid for organizing spells, macros, and items
- **Drag & Drop**: Intuitive drag-and-drop interface for action bar management
- **Controller Icon Overlays**: Each slot shows which controller button activates it
- **Modifier Indicators**: Visual indicators for LT, RT, and LT+RT combinations

![Placement Frame](docs/images/placement.png)

### 🎯 Radial Menu
- **Quick Access Menu**: Circular menu for fast access to common game functions
- **13 Menu Items**: Character, Inventory, Spellbook, Talents, Quest Log, World Map, Social, Guild, LFG, and more
- **Controller Navigation**: Navigate menu items using controller input
- **Toggle Binding**: Accessible via SHIFT+ESCAPE

![Radial Menu](docs/images/menu.png)
![Radial Menu Detail](docs/images/radial.png)

### ⌨️ Virtual Keyboard
- **Full QWERTY Layout**: Complete virtual keyboard with all standard keys
- **Automatic Activation**: Appears automatically when chat edit box or any text input field is focused
- **Controller Navigation**: Navigate keys using D-pad, select with A button
- **Shift Mode**: Toggle between lowercase and uppercase characters using LT button
- **Send Text**: Press X button (or RT) to send/confirm text input
- **Smart Positioning**: Keyboard occupies lower 48% of screen for optimal visibility
- **Visual Feedback**: Highlighted keys show current selection
- **Text Preview**: Real-time text preview in integrated edit box
- **Universal Support**: Works with chat, config text fields, and any EditBox in the game

![Virtual Keyboard](docs/images/keyboard.png)

### ⌨️ Keybinding Management
- **Default Bindings**: Pre-configured bindings for controller-style gameplay
- **Reset Function**: One-click reset to restore default bindings
- **Jump Configuration**: Toggle between jump action and custom action for A button
- **Binding Persistence**: All bindings are saved and restored automatically

### 🛠️ Configuration System
- **In-Game Config Menu**: Access via `/ce` command
- **Multiple Sections**: General, Interface, Keybindings, and Action Bars
- **Real-Time Updates**: Changes apply immediately without reload
- **Debug Mode**: Optional debug output for troubleshooting

### 📝 Macro Management
- **Default Macros**: Pre-configured macros for common actions
- **CE_Interact Macro**: Interact with nearest target/object (requires Interact.dll for a full integration (autoloot, skineables, etc.))
- **Auto-Placement**: Macros automatically placed on action bars
- **Reset Function**: Restore default macros with one click

### 🎨 Customization Options
- **Action Bar Layout**: Adjust size, padding, position, and scale
- **Crosshair Display**: Optional crosshair for screen center reference
- **Tooltip System**: Enhanced tooltips with controller button icons
- **Visual Feedback**: Highlighted elements and action prompts

## Installation

1. Download the latest release from the repository
2. Extract the `ConsoleExperienceClassic` folder
3. Copy it to your `World of Warcraft/Interface/AddOns/` directory
4. Restart World of Warcraft
5. Enable the addon in the character selection screen

### Optional: Install Interact.dll (Recommended)

For full functionality of the `CE_Interact` macro (interact with nearest target/object), it's recommended to install the [Interact.dll](https://github.com/luskanek/Interact) mod:

1. Download the latest release from [Interact repository](https://github.com/luskanek/Interact)
2. Extract `Interact.dll` from the `.zip` file to your World of Warcraft root folder (the same folder where `WoW.exe` is located)

**If your launcher handles mods automatically**, you're done! Configure the launcher to load the DLL.

**If you're launching the game directly with VanillaFixes.exe** (launcher doesn't handle mods), complete these additional steps:

3. Open `dlls.txt` in your World of Warcraft folder (included with VanillaFixes)
4. Add `Interact.dll` on a new line at the end of the file
5. Save and close the file
6. Launch the game using `VanillaFixes.exe`

**Note**: The `CE_Interact` macro will still work without Interact.dll, but will fall back to `TargetNearestEnemy()` instead of interacting with objects.

## Usage

### Steam Input Setup

**Important**: For the best experience, name your game "TurtleWoW" in your steam library, search and use the **"WoW Vanilla Console experience by p3p0 v1.2"** Steam Input distribution.

1. Launch World of Warcraft through Steam
2. Open Steam Big Picture mode or Steam overlay
3. Navigate to Controller Settings
4. Select "Browse Configs" → "Community"
5. Search for: **"WoW Vanilla Console experience by p3p0 v1"**
6. Apply the configuration
7. **Important**: Reconfigure the right joystick action (move cursor) to match your screen resolution. The profile is configured for 1920x1200 resolution, so you'll need to adjust the cursor movement coordinates in the right joystick settings to match your display resolution and the crosshair position.
8. The addon will automatically detect and work with this configuration

### Basic Controls

- **D-Pad**: Navigate UI elements, move cursor, navigate virtual keyboard, and navigate dropdown menus
- **A Button**: Confirm/Click/Place items, select keyboard keys, select dropdown options
- **B Button**: Cancel/Back/Clear slots, close menus, use items (context-dependent)
- **X Button**: Pickup items/spells, bind to action bars, send text (when keyboard is visible)
- **Y Button**: Additional actions (context-dependent, e.g., drop items)
- **LT/RT**: Modifier keys for additional action bar pages
- **LB**: Interact with nearest target/object (CE_Interact macro)
- **LT+MENU**: Toggle radial menu
- **LT (virtual keyboard)**: Toggle keyboard shift mode (uppercase/lowercase)
- **RT/X (virtual keyboard)**: Send text/confirm input

### Opening Configuration

Type `/ce` in chat to open the configuration menu.

### Action Bar Pages

- **Page 1** (No modifiers): Base action bar (slots 1-10)
- **Page 2** (LT): Left Trigger modifier (slots 11-20)
- **Page 3** (RT): Right Trigger modifier (slots 21-30)
- **Page 4** (LT+RT): Both triggers (slots 31-40)

### Cursor Navigation

When UI frames are open (Character, Spellbook, Bags, Mailbox, Trainer, Profession frames, etc.), the cursor navigation system automatically activates:
- Use D-pad to move between interactive elements
- A button to select/click
- B button to cancel/close (or use items/unequip in some contexts)
- X button to pickup/bind items and spells
- The cursor will automatically wrap around grids (e.g., inventory bags)
- **Dropdown Menus**: When you click a dropdown, the cursor automatically navigates through all dropdown options
- **Enhanced Tooltips**: Hover over any element to see detailed information with controller button action prompts

### Placing Spells/Items

1. Open the Spellbook or Inventory
2. Navigate to the spell/item using cursor navigation
3. Press X button to pick up
4. The Placement Frame will automatically appear
5. Navigate to desired slot using D-pad
6. Press A button to place
7. Press B button on a slot to clear it

### Using the Virtual Keyboard

1. Open chat by pressing Enter, clicking the chat input box, or accessing from the radial menu
2. The virtual keyboard will automatically appear in the lower half of the screen
3. Navigate keys using the D-pad
4. Press A button to type the selected key
5. Press LT to toggle between lowercase and uppercase
6. Press B button or Escape to close the keyboard and cancel typing
7. Press **X button or RT** to send the message/confirm input

The keyboard supports full QWERTY layout including numbers, letters, and common punctuation marks. The keyboard also works with any text input field in the game, including configuration menus and other EditBoxes.

### Working with Mailbox

1. Open mailbox using cursor navigation
2. Navigate through mail items with D-pad
3. Press A button to select a mail
4. When mail detail opens, navigate through:
   - Mail item buttons (A = Select, X = Take item)
   - Reply, Delete, Cancel buttons
   - Money button (if present)
5. Press B button to close mail detail and return to inbox

### Working with Trainer Frames

1. Open trainer frame using cursor navigation
2. Navigate through available skills with D-pad
3. Press A button to learn a skill
4. Tooltips show detailed skill information including cost and requirements

### Working with Profession Frames

1. Open profession frame (First Aid, Cooking, etc.) using cursor navigation
2. Navigate through profession skills with D-pad
3. Press A button to select a skill
4. View skill reagents and requirements in tooltips
5. Navigate through reagent buttons to see item details

### Working with Dropdown Menus

1. When you click any dropdown menu in the game, the cursor automatically navigates to it
2. Use D-pad to navigate through all dropdown options
3. Press A button to select an option
4. The cursor automatically returns to the parent frame when dropdown closes
5. Cursor appears above dropdown menus for optimal visibility

## Recent Updates

### Latest Features

- **Dropdown Menu Navigation**: Full cursor navigation support for all dropdown menus in the game
- **Mailbox Support**: Complete navigation for mailbox frames including mail detail view (OpenMailFrame)
- **Trainer Frame Support**: Navigate and interact with class trainer frames (ClassTrainerFrame)
- **Profession Frame Support**: Navigate and interact with profession frames (TradeSkillFrame - First Aid, Cooking, etc.)
- **Enhanced Tooltips**: Improved tooltip support for spellbook tabs, mail items, trainer skills, profession skills, and reagents
- **Keyboard X Button**: X button now sends text when virtual keyboard is visible (in addition to RT button)
- **Improved Frame Detection**: Better detection and hooking of dynamically loaded frames
- **Better Z-Ordering**: Cursor now appears above dropdown menus and other UI elements

## Roadmap

### Planned Features

- **Increased Frame Support**: Expand automatic hooking to more UI frames and addons
- **Auto Targeting System**: Intelligent target selection and management for combat
- **Healer Mode**: Specialized interface and targeting system for healing classes
- **Ring Menus**: Additional ring menus to expand the bindings and capabilities.

## Support & Donations

If you enjoy using ConsoleExperience Classic and want to support its development, consider buying me a coffee:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/pepordev)

Your support helps maintain and improve the addon!

## Compatibility

- **WoW Version**: Vanilla (1.12.1)
- **Dependencies**: None (standalone addon)
- **Optional Dependencies**: [Interact.dll](https://github.com/luskanek/Interact) for full CE_Interact macro functionality
- **Saved Variables**: Per-character configuration storage
- **Steam Input**: Compatible with Steam Input configurations for controller support

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## Credits

- **Author**: pepordev
- **Version**: 0.0.1
- **Special Thanks**: 
  - @luskanek for his support, help, guidance and the awesome Interact addon
  - @Shagu for being an inspiration
  - The rest of the addon developer community, and the user community for feedback and testing


**Note**: This addon is designed specifically for World of Warcraft: Vanilla (1.12.1). It may not work correctly with other WoW versions or private server modifications.

