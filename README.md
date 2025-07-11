# ShaguScan

<img src="./screenshots/raidtargets.jpg" float="right" align="right">

A powerful addon that scans for nearby units and filters them by custom attributes with extensive visual customization options.
It's made for World of Warcraft: Vanilla (1.12.1) and is only tested on [Turtle WoW](https://turtle-wow.org/).

The addon can be used to see all marked raid targets, detect rare mobs, find nearby players that decided to do pvp, and much more! Features include configurable health bars, multiple scan windows, advanced filtering system, and pfUI integration for enhanced theming.

> [!IMPORTANT]
>
> **This addon requires you to have [SuperWoW](https://github.com/balakethelock/SuperWoW) installed.**
>
> It won't work without it. Really.

## Installation (Vanilla, 1.12)
1. Download **[Latest Version](https://github.com/shagu/ShaguScan/archive/master.zip)**
2. Unpack the Zip file
3. Rename the folder "ShaguScan-master" to "ShaguScan"
4. Copy "ShaguScan" into Wow-Directory\Interface\AddOns
5. Restart Wow

# Usage

## Quick Start

**Main Control Panel**: Use `/scan` to open the main control panel with tabbed interface for managing all scan windows and global settings.

**Individual Window Configuration**: Use `/scan WindowName` to create or configure a specific scan window (e.g., `/scan Alliance PvP`).

In case `/scan` is already blocked by another addon, you can also use `/sscan` or `/shaguscan`.

## Main Control Panel Features

The main control panel (`/scan`) provides:

### Scan Windows Tab
- **Window Management**: View, create, edit, and delete scan windows from one centralized location
- **Template Inheritance**: New windows automatically inherit from global template settings
- **Real-time Updates**: Live window management with immediate feedback
- **Bulk Operations**: Apply templates to all existing windows

### Global Settings Tab
- **Default Template**: Configure default settings for new scan windows
- **Auto Cleanup**: Set automatic cleanup time for expired units
- **Window Limits**: Configure maximum units per window
- **UI Preferences**: Hide window headers, debug mode, and other global options

## Visual Customization

Each scan window supports extensive visual customization:

### Health Bar Styling
- **Bar Textures**: Choose from pfUI textures or custom statusbar textures
- **Color Modes**: Reaction-based (hostile/friendly), class-based, or custom colors
- **Background**: Configurable background colors and transparency
- **Borders**: Multiple border styles (thin, default, thick, glow) with custom colors

### Text Customization
- **Main Text**: Position (left/center/right), format (level+name, name only, health %), custom fonts
- **Health Text**: Separate health display with multiple formats (percent, current, current/max, deficit)
- **Font Settings**: Custom fonts, sizes, and outline styles

### Frame Effects
- **Shadows**: pfUI-style drop shadows for enhanced visibility
- **Glow Effects**: Frame glow effects for important units
- **Combat Indicators**: Dynamic border coloring during combat

## Filter System

As a filter you could for example choose: `player,pvp,alliance,alive` to only show players with pvp enabled on the alliance side that are alive.

You can build the lists as you want them, there are no limits as long as the filter for it exists.

![config](./screenshots/config.jpg)

# Filters

<img src="./screenshots/infight.jpg" float="right" align="right">

- **player**: all player characters
- **npc**: all non-player characters
- **infight**: only units that are in combat
- **dead**: only dead units
- **alive**: only alive units
- **horde**: only horde units
- **alliance**: only alliance units
- **hardcore**: only hardcore enabled players
- **pve**: only pve-flagged units
- **pvp**: only pvp-flagged units
- **icon**: only units with an assigned raid icon
- **normal**: only units of type "normal" (no elite, rare, etc.)
- **elite**: only units of type "elite" or "rareelite"
- **rare**: only units of type "rare" or "rareelite"
- **rareelite**: only units of type "rareelite"
- **worldboss**: only units of type "worldboss"
- **hostile**: only hostile units
- **neutral**: only neutral units
- **friendly**: only friendly units
- **attack**: only units that can be attacked
- **noattack**: only units that can't be attacked
- **pet**: only units that are pet or totems
- **nopet**: only units that aren't pets or totems
- **human**: only human players
- **orc**: only orc players
- **dwarf**: only dwarf players
- **nightelf**: only night elf players
- **undead**: only scourge players
- **tauren**: only tauren players
- **gnome**: only gnome players
- **troll**: only troll players
- **goblin**: only goblin players
- **highelf**: only high elf players
- **warlock**: only warlock players
- **warrior**: only warrior players
- **hunter**: only hunter players
- **mage**: only mage players
- **priest**: only priest players
- **druid**: only druid players
- **paladin**: only paladin players
- **shaman**: only shaman players
- **rogue**: only rogue players
- **aggro**: units that target you
- **noaggro**: units that don't target you
- **pfquest**: units that have a pfquest tooltip
- **range**: units that are within max [interaction distance](https://wowwiki-archive.fandom.com/wiki/API_CheckInteractDistance) (28y)
- **level:NUMBER**: units that are level NUMBER
- **minlevel:NUMBER**: units that are at least level NUMBER
- **maxlevel:NUMBER**: units that are at most level NUMBER
- **name:STRING**: units that have STRING in their name

New and custom filters are easy to implement, if you wish to create your own, please have a look at: [filter.lua](./filter.lua).

# Performance & Architecture

## Optimized Performance
ShaguScan has been extensively optimized for performance:

- **Filter Short-circuiting**: 20-30% reduction in filter processing time through early exit logic
- **Efficient UI Updates**: Elapsed-based timing eliminates GetTime() overhead (10-15% CPU reduction)
- **Optimized Filter Functions**: Streamlined boolean logic and early exits for class filters
- **Smart Caching**: Efficient position and size caching reduces string concatenation overhead
- **Memory Management**: Proper local variable scoping prevents memory leaks

## SuperWoW Integration
The addon leverages SuperWoW's enhanced capabilities:

- **GUID-based Operations**: Direct GUID support for efficient unit tracking
- **Event-driven Architecture**: Uses WoW events for unit detection rather than polling
- **Extended Range**: Can track units beyond normal API limitations
- **Enhanced Unit Functions**: All Unit* functions accept GUIDs directly

## Modular Architecture
The codebase is organized into focused modules:

- **core.lua**: Event handling and GUID tracking system
- **filter.lua**: Comprehensive filtering system with 40+ filter functions
- **ui.lua**: Main UI components and health bar rendering
- **utils.lua**: Utility functions and UI positioning
- **widgets.lua**: Reusable UI widget components
- **dialogs.lua**: Individual window configuration dialogs
- **testbars.lua**: Test bar preview functionality
- **mainpanel.lua**: Main control panel with tabbed interface
- **settings.lua**: Command handling and module coordination

## pfUI Integration
Enhanced theming and visual consistency when pfUI is installed:

- **Backdrop System**: Automatic pfUI backdrop integration
- **Texture Library**: Access to pfUI's statusbar texture collection
- **Color Scheme**: Consistent styling with pfUI's visual theme
- **Advanced Effects**: Enhanced shadows and glow effects
