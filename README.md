# Patron's Ledger

**A comprehensive Tales of Tribute companion addon for Elder Scrolls Online (PS5 optimized)**

Version 1.0.0 | Author: @svammy

BASED ON:
- TributeImprovedLeaderboard by @andy.s
  (Rank tracking, leaderboard UI enhancements)
- ExoYsTributesEnhancement by @ExoY94
  (Match statistics tracking structure)

---

## Description

Patron's Ledger enhances your Tales of Tribute experience with rank tracking, detailed match statistics, and post-game summaries. Fully optimized for PS5/console gamepad UI with zero dependencies.

### Key Features

✅ **Rank Tracking** - See your rank changes after every competitive match  
✅ **Match Statistics** - Track wins, losses, and playtime across all match types  
✅ **Post-Match Summaries** - Detailed breakdown after every game  
✅ **Leaderboard Enhancements** - Colorized rankings and extended displays  
✅ **Slash Commands** - Configure everything via chat (no GUI needed)  
✅ **PS5 Optimized** - Full gamepad UI support, no dependencies  

---

## Commands

### Basic Commands
- `/totlb` or `/totlb help` - Show all available commands
- `/totlb on/off` - Enable/disable addon
- `/totlb status` - Show current settings

### Statistics
- `/totlb stats` - Show overall statistics across all match types
- `/totlb stats casual` - Show casual match statistics
- `/totlb stats ranked` - Show ranked match statistics
- `/totlb stats npc` - Show NPC match statistics
- `/totlb stats friendly` - Show friendly match statistics

### Display Settings
- `/totlb chat on/off` - Toggle chat notifications
- `/totlb color on/off` - Toggle leaderboard colorization
- `/totlb summary on/off` - Toggle post-match summaries

### Tracking
- `/totlb track stats on/off` - Toggle statistics tracking

---

## What You'll See

### After a Ranked Match
```
[ToT Match Summary] Victory - Ranked
  Duration: 12:34 | Your Turns: 8 | Opponent Turns: 7
  Opponent: @PlayerName

[ToT Ranked] Rank: 1247/5832 (+23). Score: 1856 (+18). Top 21.4%
```

### Statistics Overview
```
[Patron's Ledger] Overall Statistics:
  Ranked: 47 played, 28 won (59.6%)
  Casual: 12 played, 8 won (66.7%)
  NPC: 5 played, 5 won (100.0%)
```

### Leaderboard UI Enhancements
- Rank display shows: `1247/5832 (Top 21.4%)` instead of just `1247`
- Score colors:
  - **Gold** for top 2% players
  - **Bright Green** for top 10% players
  - White for others

---

## Credits & Attribution

This addon is based on code from:

- **TributeImprovedLeaderboard** by @andy.s
  - Rank tracking and leaderboard UI enhancements

- **ExoYsTributesEnhancement** by @ExoY94
  - Match statistics tracking structure

### What's New in Patron's Ledger?

✨ **Combined Features** - Best of both original addons
✨ **Zero Dependencies** - Removed LibAddonMenu and LibExoYsUtilities requirements
✨ **Slash Commands** - Full configuration via chat
✨ **Match Summaries** - Detailed post-game breakdowns
✨ **PS5 Optimization** - Full gamepad UI support with safety checks

---

## Technical Details

- **API Version**: 101044, 101045
- **Dependencies**: None
- **SavedVariables**: PatronsLedgerSV (account-wide)
- **Lua Version**: 5.1 (ESO standard)
- **Platform**: PC, PS5 (via PC addon management), Xbox

---

## Support & Feedback

If you encounter issues or have suggestions:
- Check existing commands with `/totlb help`
- Ensure addon is enabled with `/totlb status`
- Try `/reloadui` to reload the addon

---

## File Structure

```
PatronsLedger/
├── PatronsLedger.txt        # Addon manifest
├── PatronsLedger.lua        # Main addon code
└── README.md                # This file
```

---

## Version History

### Version 1.0.0 (2026-01-01)
- Initial release
- Combined TributeImprovedLeaderboard + ExoYsTributesEnhancement
- Added slash command configuration
- Added match summaries
- Added extensive bug fixes and safety improvements
- Optimized for PS5/console gamepad UI
- Removed all external dependencies

---

## License & Usage

This addon combines and enhances code from the above-mentioned addons. If you are an original author and wish this to be removed or modified, please contact @svammy.

**For personal use.** If you wish to redistribute or modify, please contact the original authors for permission.

---

## Companion Addons

Check out my other addon:
- **Trader's Ledger** - Trading and marketplace companion

---

**Enjoy your Tales of Tribute matches with Patron's Ledger!** 🎴✨
