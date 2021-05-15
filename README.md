# **Wheelchair Level**

Tracks quest, dungeon, mob kill and session xp data to provide a summary and estimates for leveling time.

_requires Ace3 lib - https://github.com/keatanb/Ace3/tree/classic-tbc_

## Tracks the following :
- Mobs 
- Quests
- Dungeons 

## Display Options
- A basic movable frame showing average counts of quest / dungeon / mob kills / time needed to level, based on default amounts until data is collected
- Tooltips on the frame show more detailed average and historical information for each element when individually hovered
- Dungeon tooltip contain current dungeon details if in progress, last completed dungeon if not in progress and best historical dungeon run (by xp/h) within 5 character levels

## Configuration
configured via the configuration panel, which is accessible in the Interface/AddOns window, or via commands

## Commands
    /wcl ==> open config panel
    /wcl dlist ==> list dungeon history detail for session
    /wcl ed ==> manually trigger end dungeon (may be needed for doing logout instance tele bug resets)
    /wcl sd ==> manually trigger start dungeon (may be needed for doing logout instance tele bug resets)

