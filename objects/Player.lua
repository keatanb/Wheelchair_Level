local _, addonTable = ...
---
-- Controls all Player related functionality.
---

local L = addonTable.GetLocale()

---
-- Control object for player functionality and calculations.
-- @class table
-- @name WheelchairLevel.Player
-- @field isActive Indicates whether the object has been sucessfully initialized.
-- @field level The current level of the player.
-- @field maxLevel The max level for the player, according to the account type.
-- @field currentXP The current XP of the player.
-- @field restedXP The amount of extra "rested" XP the player has accumulated.
-- @field maxXP The total XP required for the current level.
-- @field killAverage Holds the latest value of the GetAverageKillXP method. Do
--        not use this field directly. Call the funciton instead.
-- @field killRange Holds the lates value of the GetKillXpRange method. Do not
--        use this field directly. Call the function instead.
-- @field questAverage Holds the latest value of the GetAverageQuestXP method.
--        Do not use this field directly. Call the funciton instead.
-- @field questRange Holds the lates value of the GetQuestXpRange method. Do not
--        use this field directly. Call the function instead.
-- @field bgAverage Holds the latest value of the GetAverageBGXP method. Do not
--        use this field directly. Call the funciton instead.
-- @field bgAverageObj Holds the latest value of the GetAverageBGObjectiveXP
--        method. Do not use this field directly. Call the funciton instead.
-- @field dungeonAverage Holds the latest value of the GetAverageDungeonXP method.
--        Do not use this field directly. Call the funciton instead.
-- @field killListLength The max number of kills to record.
-- @field questListLength The max number of quests to record.
-- @field bgListLength The max number of battlegrounds to record.
-- @field dungeonListLength The max number of dungeons to record.
-- @field hasEnteredBG Indicates whether the player is in a bg.
-- @field dungeonList A list of dungeon names. Set by the GetDungeonsListed function
-- @field latestDungeonData The data for the lates/current dungeon.
-- @field bgList A list of bg names. Set by the GetBattlegroundsListed
-- @field latestBgData The data for the latest bg.
---
WheelchairLevel.Player = {
    -- Members
    isActive = false,
    level = nil,
    maxLevel = nil, -- Assume WotLK-enabled. Will be corrected once properly initialized.
    class = nil,
    currentXP = nil,
    restedXP = 0,
    maxXP = nil,
    killAverage = nil,
    killRange = {low = nil, high = nil, average = nil},
    questAverage = nil,
    questRange = {low = nil, high = nil, average = nil},
    petBattleAverage = nil,
    bgAverage = nil,
    bgObjAverage = nil,
    dungeonAverage = nil,
    killListLength = 100, -- The max allowed value, not the current selection.
    questListLength = 100,
    petBattleListLength = 50,
    bgListLength = 300,
    dungeonListLength = 500,
    digListLength = 100,
    hasEnteredBG = true,
    guildLevel = nil,
    guildXP = nil,
    guildXPMax = nil,
    guildXPDaily = nil,
    guildXPDailyMax = nil,
    guildHasQueried = false,
    timePlayedTotal = nil,
    timePlayedLevel = nil,
    timePlayedUpdated = nil,
    dungeonList = {},
    latestDungeonData = {totalXP = nil, killCount = nil, xpPerKill = nil, otherXP = nil},
    bgList = {},
    latestBgData = {
        totalXP = nil,
        objCount = nil,
        killCount = nil,
        xpPerObj = nil,
        xpPerKill = nil,
        otherXP = nil,
        inProgress = nil,
        name = nil
    },
    lastSync = time(),
    lastXpPerHourUpdate = time() - 60,
    xpPerSec = nil,
    xpPerSecTimeout = 2, -- The number of seconds between re-calculating the xpPerSec
    timerHandler = nil,
    percentage = nil,
    lastKnownXP = nil,
    guildPercentage = nil,
    guildLastKnownXP = nil,
    guildDailyPercentage = nil,
    guildDailyLastKnownXP = nil
}

-- Constructor
function WheelchairLevel.Player:Initialize()
    self:SyncData()

    self:GetMaxLevel()

    if self.level == self.maxLevel then
        self.isActive = false
    else
        self.isActive = true
    end

    self.killAverage = nil
    self.bgObjAverage = nil
    self.questAverage = nil

    if WheelchairLevel.db.profile.timer.enabled then
        self.timerHandler =
            WheelchairLevel.timer:ScheduleRepeatingTimer(WheelchairLevel.Player.TriggerTimerUpdate, self.xpPerSecTimeout)
    end
end

---
-- Calculates the max level for the player, based on the expansion level
-- available to the player.
---
function WheelchairLevel.Player:GetMaxLevel()
    if self.maxLevel == nil then
        self.maxLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
    end
    return self.maxLevel
end

---
-- Returns the player class in English, fully capitalized. For example:
-- "HUNTER", "WARRIOR".
function WheelchairLevel.Player:GetClass()
    if self.class == nil then
        local playerClass, englishClass = UnitClass("player")
        self.class = englishClass
    end
    return self.class
end

---
-- Creates an empty template entry for the bg list.
-- @return The empty template table.
---
function WheelchairLevel.Player:CreateBgDataArray()
    return {
        inProgress = false,
        level = nil,
        name = nil,
        totalXP = 0,
        objTotal = 0,
        objCount = 0,
        killCount = 0,
        killTotal = 0,
        objMinorTotal = 0,
        objMinorCount = 0
    }
end

---
-- Creates an empty template entry for the dungeon list.
-- @return The empty template table.
---
function WheelchairLevel.Player:CreateDungeonDataArray()
    return {
        inProgress = false,
        level = nil,
        name = nil,
        totalXP = 0,
        killCount = 0,
        killTotal = 0,
        rested = 0,
        startTime = nil,
        endTime = nil
    }
end

---
-- Updates the level and XP values in the table with the actual values on
-- the server.
---
function WheelchairLevel.Player:SyncData()
    self.level = UnitLevel("player")
    self.currentXP = UnitXP("player")
    self.maxXP = UnitXPMax("player")
    self.lastSync = time() -- Used for the XP/hr calculations. May be altered elsewhere!

    local rested = GetXPExhaustion() or 0
    self.restedXP = rested / 2
end

---
-- Updates the guild XP info.
---
function WheelchairLevel.Player:SyncGuildData()
    if IsInGuild() then
        self.guildLevel = GetGuildLevel()

        local currentXP, remainingXP, dailyXP, maxDailyXP = UnitGetGuildXP("player")
        -- maxDailyXP is the only field that *should* always be positive.
        if maxDailyXP > 0 then
            self.guildXP = currentXP
            self.guildXPMax = currentXP + remainingXP
            self.guildXPDaily = dailyXP
            self.guildXPDailyMax = maxDailyXP
        elseif not self.guildHasQueried then
            QueryGuildXP()
            self.guildHasQueried = true
        end
    else
        self.guildLevel = nil
        self.guildXP = nil
        self.guildXPMax = nil
        self.guildXPDaily = nil
        self.guildXPDailyMax = nil
    end
end

--- Updates the time played values.
-- @param total The total time played on this char, in seconds.
-- @param level The total time played this level, in seconds.
function WheelchairLevel.Player:UpdateTimePlayed(total, level)
    if type(level) == "number" and level > 0 then
        self.timePlayedLevel = level
    end
    if type(total) == "number" and total > 0 then
        self.timePlayedTotal = total
    end
    self.timePlayedUpdated = GetTime()
end

--- Callback for the timer registration function.
function WheelchairLevel.Player:TriggerTimerUpdate()
    WheelchairLevel.Player:UpdateTimer()
end
function WheelchairLevel.Player:UpdateTimer()
    self = WheelchairLevel.Player
    self.lastXpPerHourUpdate = GetTime()
    WheelchairLevel.db.char.data.timer.lastUpdated = self.lastXpPerHourUpdate

    local useMode = WheelchairLevel.db.profile.timer.mode

    -- Use the session data
    if useMode == 1 then
        if
            type(WheelchairLevel.db.char.data.timer.start) == "number" and type(WheelchairLevel.db.char.data.timer.total) == "number" and
                WheelchairLevel.db.char.data.timer.total > 0
         then
            WheelchairLevel.db.char.data.timer.xpPerSec =
                WheelchairLevel.db.char.data.timer.total /
                (WheelchairLevel.db.char.data.timer.lastUpdated - WheelchairLevel.db.char.data.timer.start)
            local secondsToLevel = (self.maxXP - self.currentXP) / WheelchairLevel.db.char.data.timer.xpPerSec
            WheelchairLevel.Average:UpdateTimer(secondsToLevel)
        elseif type(WheelchairLevel.db.char.data.timer.xpPerSec) == "number" and WheelchairLevel.db.char.data.timer.xpPerSec > 0 then
            -- Fallback method #1, in case no XP has been gained this session, but data remains from the last session.
            local secondsToLevel = (self.maxXP - self.currentXP) / WheelchairLevel.db.char.data.timer.xpPerSec
            WheelchairLevel.Average:UpdateTimer(secondsToLevel)
        else
            -- Fallback method #2. Use level data.
            useMode = 2
        end
    end

    -- Use the level data.
    if useMode == 2 then
        if
            type(self.timePlayedLevel) == "number" and
                (self.timePlayedLevel + (WheelchairLevel.db.char.data.timer.lastUpdated - self.timePlayedUpdated)) > 0
         then
            local xpPerSec =
                self.currentXP /
                (self.timePlayedLevel + (WheelchairLevel.db.char.data.timer.lastUpdated - self.timePlayedUpdated))
            if xpPerSec > 0 then
                local secondsToLevel = (self.maxXP - self.currentXP) / xpPerSec
                WheelchairLevel.Average:UpdateTimer(secondsToLevel)
            end
        else
            useMode = false
        end
    end

    -- Fallback, in case both above failed.
    if useMode == false then
        WheelchairLevel.db.char.data.timer.xpPerSec = 0
        WheelchairLevel.Average:UpdateTimer(nil)
    end
end

--- Returns details about the estimated time remaining.
-- @return mode, timeToLevel, timePlayed, xpPerHour, totalXP, warning
function WheelchairLevel.Player:GetTimerData()
    local mode = WheelchairLevel.db.profile.timer.mode == 1 and (L["Session"] or "Session") or (L["Level"] or "Level")
    local timePlayed, totalXP, xpPerSecond, xpPerHour, timeToLevel, warning
    if WheelchairLevel.db.profile.timer.mode == 1 and tonumber(WheelchairLevel.db.char.data.timer.total) > 0 then
        mode = 1
        warning = 0
        timePlayed = GetTime() - WheelchairLevel.db.char.data.timer.start
        totalXP = WheelchairLevel.db.char.data.timer.total
        xpPerSecond = totalXP / timePlayed
        xpPerHour = ceil(xpPerSecond * 3600)
        timeToLevel = (self.maxXP - self.currentXP) / xpPerSecond
    elseif
        WheelchairLevel.db.profile.timer.mode == 1 and WheelchairLevel.db.char.data.timer.xpPerSec ~= nil and
            tonumber(WheelchairLevel.db.char.data.timer.xpPerSec) > 0
     then
        mode = 1
        warning = 1
        timePlayed = GetTime() - WheelchairLevel.db.char.data.timer.start
        totalXP = self.currentXP
        xpPerSecond = WheelchairLevel.db.char.data.timer.xpPerSec
        xpPerHour = ceil(xpPerSecond * 3600)
        timeToLevel = (self.maxXP - self.currentXP) / xpPerSecond
    elseif WheelchairLevel.Player.timePlayedLevel then
        if WheelchairLevel.Player.currentXP > 0 then
            mode = 2
            if WheelchairLevel.db.profile.timer.mode ~= 2 then
                warning = 2
            else
                warning = 0
            end
            timePlayed = self.timePlayedLevel + (GetTime() - self.timePlayedUpdated)
            totalXP = self.currentXP
            xpPerSecond = totalXP / timePlayed
            xpPerHour = ceil(xpPerSecond * 3600)
            timeToLevel = (self.maxXP - self.currentXP) / xpPerSecond
        else
            mode = nil
            warning = 3
            timePlayed = self.timePlayedLevel + (GetTime() - self.timePlayedUpdated)
            totalXP = 0
            xpPerSecond = nil
            xpPerHour = nil
            timeToLevel = 0
        end
    else
        mode = nil
        warning = 3
        timePlayed = 0
        totalXP = nil
        xpPerSecond = nil
        xpPerHour = nil
        timeToLevel = 0
    end

    return mode, timeToLevel, timePlayed, xpPerHour, totalXP, warning
end

---
-- Calculatest the unrested XP. If a number is passed, it will be used instead of
-- the player's remaining XP.
-- @param totalXP The total XP gained from a kill
function WheelchairLevel.Player:GetUnrestedXP(totalXP)
    if totalXP == nil then
        totalXP = self.maxXP - self.currentXP
    end
    local killXP = totalXP
    if self.restedXP > 0 then
        if self.restedXP > totalXP / 2 then
            --self.restedXP = self.restedXP - killXP
            killXP = totalXP / 2
        else
            --self.restedXP = 0
            killXP = totalXP - self.restedXP
        end
    end
    return killXP
end

---
-- Adds a kill to the kill list and updates the recorded XP value.
-- @param xpGained The TOTAL amount of XP gained, including bonuses.
-- @param mobName The name of the killed mob.
-- @return The gained XP without any rested bounses.
---
function WheelchairLevel.Player:AddKill(xpGained, mobName)
    self.currentXP = self.currentXP + xpGained

    local killXP = self:GetUnrestedXP(xpGained)

    if self.restedXP > killXP then
        self.restedXP = self.restedXP - killXP
    elseif self.restedXP > 0 then
        self.restedXP = 0
    end

    self.killAverage = nil
    table.insert(WheelchairLevel.db.char.data.killList, 1, { mob = mobName, xp = killXP})
    if (#WheelchairLevel.db.char.data.killList > self.killListLength) then
        table.remove(WheelchairLevel.db.char.data.killList)
    end
    WheelchairLevel.db.char.data.total.mobKills = (WheelchairLevel.db.char.data.total.mobKills or 0) + 1

    return killXP
end

---
-- Start recording a battleground. If a battleground is already in progress
-- the function fails.
-- @param bgName The name of the battleground. (This will be updated later.)
-- @return boolean
---
function WheelchairLevel.Player:BattlegroundStart(bgName)
    if (#WheelchairLevel.db.char.data.bgList) > 0 and WheelchairLevel.db.char.data.bgList[1].inProgress == true then
        console:log("Attempted to start a BG while another one is in progress.")
        return false
    else
        local bgDataArray = self:CreateBgDataArray()
        table.insert(WheelchairLevel.db.char.data.bgList, 1, bgDataArray)
        if (#WheelchairLevel.db.char.data.bgList > self.bgListLength) then
            table.remove(WheelchairLevel.db.char.data.bgList)
        end
        WheelchairLevel.db.char.data.bgList[1].inProgress = true
        WheelchairLevel.db.char.data.bgList[1].name = bgName or false
        WheelchairLevel.db.char.data.bgList[1].level = self.level
        console:log("BG Started! (" .. tostring(WheelchairLevel.db.char.data.bgList[1].name) .. ")")
        return true
    end
end

---
-- Attempts to end the battleground currently in progress. If no battleground
-- is in progress it fails. If the entry that is in progress has recorded no
-- honor, the function fails and removes the entry from the list.
-- @return boolean
---
function WheelchairLevel.Player:BattlegroundEnd()
    if WheelchairLevel.db.char.data.bgList[1].inProgress == true then
        WheelchairLevel.db.char.data.bgList[1].inProgress = false
        console:log("BG Ended! (" .. tostring(WheelchairLevel.db.char.data.bgList[1].name) .. ")")

        self.bgAverage = nil
        self.bgObjAverage = nil

        if WheelchairLevel.db.char.data.bgList[1].totalXP == 0 then
            table.remove(WheelchairLevel.db.char.data.bgList, 1)
            console:log("BG ended without any honor gain. Disregarding it.)")
            return false
        else
            return true
        end
    else
        console:log("Attempted to end a BG before one was started.")
        return false
    end
end

---
-- Checks whether a battleground is currently in progress.
-- @return A boolean, indicating whether a battleground is in progress.
---
function WheelchairLevel.Player:IsBattlegroundInProgress()
    if #WheelchairLevel.db.char.data.bgList > 0 then
        return WheelchairLevel.db.char.data.bgList[1].inProgress
    else
        return false
    end
end

---
-- Adds a battleground objective to the currently active battleground entry.
-- If the xpGained is less than the minimum required XP for an objective,
-- the objective is recorded as a kill. (AV centry kills are often not
-- reported as kills, but as quests/objectives, and thus far below what actual
-- objectives reward.)
-- @param xpGained The XP gained from the objective.
-- @return boolean
---
function WheelchairLevel.Player:AddBattlegroundObjective(xpGained)
    if WheelchairLevel.db.char.data.bgList[1].inProgress then
        if xpGained > WheelchairLevel.Lib:GetBGObjectiveMinXP() then
            self.bgObjAverage = nil
            WheelchairLevel.db.char.data.bgList[1].totalXP = WheelchairLevel.db.char.data.bgList[1].totalXP + xpGained
            WheelchairLevel.db.char.data.bgList[1].objTotal = WheelchairLevel.db.char.data.bgList[1].objTotal + xpGained
            WheelchairLevel.db.char.data.bgList[1].objCount = WheelchairLevel.db.char.data.bgList[1].objCount + 1
            WheelchairLevel.db.char.data.total.objectives = (WheelchairLevel.db.char.data.total.objectives or 0) + 1
            return true
        else
            return self:AddBattlegroundKill(xpGained, "Unknown")
        end
    else
        console:log("Attempt to add a BG objective without starting a BG.")
        return false
    end
end

---
-- Adds a kill to the currently active battleground entry. If no entry is
-- in progress then the function fails.
-- @param xpGained The XP gained from the kill.
-- @param name The name of the mob killed.
-- @return boolean
---
function WheelchairLevel.Player:AddBattlegroundKill(xpGained, name)
    if WheelchairLevel.db.char.data.bgList[1].inProgress then
        WheelchairLevel.db.char.data.bgList[1].totalXP = WheelchairLevel.db.char.data.bgList[1].totalXP + xpGained
        WheelchairLevel.db.char.data.bgList[1].killCount = WheelchairLevel.db.char.data.bgList[1].killCount + 1
        WheelchairLevel.db.char.data.bgList[1].killTotal = WheelchairLevel.db.char.data.bgList[1].killTotal + xpGained
        WheelchairLevel.db.char.data.total.pvpKills = (WheelchairLevel.db.char.data.total.pvpKills or 0) + 1
    else
        console:log("Attempt to add a BG kill without starting a BG.")
    end
end

---
-- Starts recording a dungeon. Fails if already recording a dungeon.
-- @return boolean
---
function WheelchairLevel.Player:DungeonStart()
    if self.isActive and not self:IsDungeonInProgress() then
        local dungeonName = select(1,GetInstanceInfo())
        local dungeonDataArray = self:CreateDungeonDataArray()
        table.insert(WheelchairLevel.db.char.data.dungeonList, 1, dungeonDataArray)
        if (#WheelchairLevel.db.char.data.dungeonList > self.dungeonListLength) then
            table.remove(WheelchairLevel.db.char.data.dungeonList)
        end

        WheelchairLevel.db.char.data.dungeonList[1].inProgress = true
        WheelchairLevel.db.char.data.dungeonList[1].name = dungeonName or false
        WheelchairLevel.db.char.data.dungeonList[1].level = self.level
        WheelchairLevel.db.char.data.dungeonList[1].startTime = time()
        local hours, mins = GetGameTime();
        local dateInfo = C_Calendar.GetDate();
        WheelchairLevel.db.char.data.dungeonList[1].timeStamp = string.format("%02d",dateInfo.monthDay) .."-"..string.format("%02d",dateInfo.month).."-"..dateInfo.year.." "..string.format("%02d",hours)..":"..string.format("%02d",mins)
        console:log("Dungeon Started! (" .. tostring(WheelchairLevel.db.char.data.dungeonList[1].name) .. ")")
        return true
    else
        console:log("Attempt to start a dungeon failed. Player either not active or already in a dungeon.")
        return false
    end
end

---
-- Stops recording a dungeon. If not recording a dungeon, the function fails.
-- If the dungeon being recorded has yielded no XP, the entry is removed and
-- the function fails.
-- @return boolean
---
function WheelchairLevel.Player:DungeonEnd()
    if WheelchairLevel.db.char.data.dungeonList[1].inProgress == true then
        WheelchairLevel.db.char.data.dungeonList[1].inProgress = false
        self:UpdateDungeonName()
        console:log("Dungeon Ended! (" .. tostring(WheelchairLevel.db.char.data.dungeonList[1].name) .. ")")

        self.dungeonAverage = nil

        if WheelchairLevel.db.char.data.dungeonList[1].totalXP == 0 then
            table.remove(WheelchairLevel.db.char.data.dungeonList, 1)
            console:log("Dungeon ended without any XP gain. Disregarding it.)")
            return false
        else
            console:log("Dungeon ended successfully")
            return true
        end
    else
        console:log("Attempted to end a Dungeon before one was started.")
        return false
    end
end

---
-- Checks whether a dungeon is in progress.
-- @return boolean
---
function WheelchairLevel.Player:IsDungeonInProgress()
    if #WheelchairLevel.db.char.data.dungeonList > 0 then
        return WheelchairLevel.db.char.data.dungeonList[1].inProgress
    else
        return false
    end
end

---
-- Update the name of the dungeon currently being recorded. If not recording
-- a dungeon, or if the name does not need to be updated, the function fails.
-- @return boolean
---
function WheelchairLevel.Player:UpdateDungeonName()
    local name = select(1,GetInstanceInfo())
    local type = select(2, GetInstanceInfo())
    if self:IsDungeonInProgress() and type == "party" then
        if WheelchairLevel.db.char.data.dungeonList[1].name ~= name then
            WheelchairLevel.db.char.data.dungeonList[1].name = name
            console:log("Dungeon name updated (" .. tostring(name) .. ")")
            return true
        else
            return false
        end
    else
        return false
    end
end

---
-- Adds a kill to the dungeon being recorded. If no dungeon is being recorded
-- the function fails. Note, this function triggers the UpdateDungeonName
-- method, so all dungeons that have a single kill can be asumed to have the
-- correct name associated with it. (Those who do not are discarded anyways)
-- @param xpGained The UNRESTED XP gained from the kill. Ideally, the return
--        value of the AddKill function should be used.
-- @param name The name of the killed mob.
-- @param rested The amount of rested bonus that was gained on top of the
--        base XP.
-- @return boolean
---
function WheelchairLevel.Player:AddDungeonKill(xpGained, name, rested)
    if self:IsDungeonInProgress() then
        WheelchairLevel.db.char.data.dungeonList[1].totalXP = WheelchairLevel.db.char.data.dungeonList[1].totalXP + xpGained
        WheelchairLevel.db.char.data.dungeonList[1].killCount = WheelchairLevel.db.char.data.dungeonList[1].killCount + 1
        WheelchairLevel.db.char.data.dungeonList[1].killTotal = WheelchairLevel.db.char.data.dungeonList[1].killTotal + xpGained
        if type(rested) == "number" and rested > 0 then
            WheelchairLevel.db.char.data.dungeonList[1].rested = WheelchairLevel.db.char.data.dungeonList[1].rested + rested
        end
        WheelchairLevel.db.char.data.total.dungeonKills = (WheelchairLevel.db.char.data.total.dungeonKills or 0) + 1
        self:UpdateDungeonName()
        return true
    else
        console:log("Attempt to add a Dungeon kill without starting a Dungeon.")
        return false
    end
end

---
-- Gets the amount of kills required to reach the next level, based on the
-- passed XP value. The rested bonus is taken into account.
-- @param xp The XP assumed per kill
-- @return An integer or -1 if the input parameter is invalid.
---
function WheelchairLevel.Player:GetKillsRequired(xp)
    if xp > 0 then
        local xpRemaining = self.maxXP - self.currentXP
        local xpRested = self:IsRested()
        if xpRested then
            if ((xpRemaining / 2) > xpRested) then
                xpRemaining = xpRemaining - xpRested
            else
                xpRemaining = xpRemaining / 2
            end
        end
        return ceil(xpRemaining / xp)
    else
        return -1
    end
end

---
-- Gets the amount of quests required to reach the next level, based on the
-- passed XP value.
-- @param xp The XP assumed per quest
-- @return An integer or -1 if the input parameter is invalid.
---
function WheelchairLevel.Player:GetQuestsRequired(xp)
    local xpRemaining = self.maxXP - self.currentXP
    if (xp > 0) then
        return ceil(xpRemaining / xp)
    else
        return -1
    end
end

---
-- Gets the percentage of XP already gained towards the next level.
-- @param fractions The number of fraction digits to be used. Defaults to 1.
-- @return A number between 0 and 100, representing the percentage.
---
function WheelchairLevel.Player:GetProgressAsPercentage(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 1
    end
    if self.percentage == nil or self.lastKnownXP == nil or self.lastKnownXP ~= self.currentXP then
        self.lastKnownXP = self.currentXP
        self.percentage = (self.currentXP or 0) / (self.maxXP or 1) * 100
    end
    return WheelchairLevel.Lib:round(self.percentage, fractions)
end

---
-- Get the number of "bars" remaining until the next level is reached. Each
-- "bar" represents 5% of the total value.
-- This has become a common measurement used by players when referring
-- to their progress, inspired by the default WoW UI, where the XP progress
-- bar is split into 20 induvidual cells.
-- @param fractions The number of fraction digits to be used. Defautls to 0.
---
function WheelchairLevel.Player:GetProgressAsBars(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 0
    end
    local barsRemaining = ceil((100 - ((self.currentXP or 0) / (self.maxXP or 1) * 100)) / 5, fractions)
    return barsRemaining
end

function WheelchairLevel.Player:GetXpRemaining()
    return self.maxXP - self.currentXP
end

function WheelchairLevel.Player:GetRestedPercentage(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 0
    end
    return WheelchairLevel.Lib:round((self.restedXP * 2) / self.maxXP * 100, fractions, true)
end

----------------------------------------------------------------------------
-- Guild methods
----------------------------------------------------------------------------
---
-- Gets the percentage the player's guild has gained towards it's next level.
-- @param fractions The number of fractions to include. Defaults to 1.
-- @return A number between 0 and 100.
function WheelchairLevel.Player:GetGuildProgressAsPercentage(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 1
    end
    if self.guildPercentage == nil or self.guildLastKnownXP == nil or self.guildLastKnownXP ~= self.guildXP then
        self.guildLastKnownXP = self.guildXP
        self.guildPercentage = (self.guildXP or 0) / (self.guildXPMax or 1) * 100
    end
    return WheelchairLevel.Lib:round(self.guildPercentage, fractions)
end

function WheelchairLevel.Player:GetGuildXpRemaining()
    return self.guildXPMax - self.guildXP
end

function WheelchairLevel.Player:GetGuildDailyProgressAsPercentage(fractions)
    if type(fractions) ~= "number" or fractions <= 0 then
        fractions = 1
    end
    if
        self.guildDailyPercentage == nil or self.guildDailyLastKnownXP == nil or
            self.guildDailyLastKnownXP ~= self.guildXP
     then
        self.guildDailyLastKnownXP = self.guildXPDaily
        self.guildDailyPercentage = (self.guildXPDaily or 0) / (self.guildXPDailyMax or 1) * 100
    end
    return WheelchairLevel.Lib:round(self.guildDailyPercentage, fractions)
end
function WheelchairLevel.Player:GetGuildDailyXpRemaining()
    return self.guildXPDailyMax - self.guildXPDaily
end

---
-- Get the average XP per kill. The number of kills used is limited by the
-- WheelchairLevel.db.profile.averageDisplay.playerKillListLength configuration directive.
-- The value returned is stored in the killAverage member, so calling this
-- function twice only calculates the value once. If no data is avaiable, a
-- level based estimate  is used.
-- Note that the function applies the Recruit-A-Friend bonus when applicable
-- but that does not affect the actual value stored. It is applied only when
-- the value is about to be returned.
-- @return A number.
---
function WheelchairLevel.Player:GetAverageKillXP()
    if self.killAverage == nil then
        if (#WheelchairLevel.db.char.data.killList > 0) then
            local total = 0
            local maxUsed = #WheelchairLevel.db.char.data.killList
            if maxUsed > WheelchairLevel.db.profile.averageDisplay.playerKillListLength then
                maxUsed = WheelchairLevel.db.profile.averageDisplay.playerKillListLength
            end
            for index, value in ipairs(WheelchairLevel.db.char.data.killList) do
                if index > maxUsed then
                    break
                end
                total = total + value.xp
            end
            self.killAverage = (total / maxUsed)
        else
            self.killAverage = WheelchairLevel.Lib:MobXP()
        end
    end

    -- Recruit A Friend beta test.
    -- Simply tripples the DISPLAY value. The actual data remains intact.
    if WheelchairLevel.Lib:IsRafApplied() then
        return (self.killAverage * 3)
    else
        return self.killAverage
    end
end

---
-- Calculates the average, highest and lowest XP values recorded for kills.
-- The range of data used is limited by the
-- WheelchairLevel.db.profile.averageDisplay.playerKillListLength config directive. If no data
-- is available, a level based estimate is used. Note that the function
-- applies the Recruit-A-Friend bonus when applicable but that does not
-- affect the actual value stored. It is applied only when the value is
-- about to be returned.
-- @return A table as : { 'average', 'high', 'low' }
---
function WheelchairLevel.Player:GetKillXpRange()
    if (#WheelchairLevel.db.char.data.killList > 0) then
        self.killRange.high = 0
        self.killRange.low = 0
        self.killRange.average = 0
        local total = 0
        local maxUsed = #WheelchairLevel.db.char.data.killList
        if maxUsed > WheelchairLevel.db.profile.averageDisplay.playerKillListLength then
            maxUsed = WheelchairLevel.db.profile.averageDisplay.playerKillListLength
        end
        for index, value in ipairs(WheelchairLevel.db.char.data.killList) do
            if index > maxUsed then
                break
            end
            if value.xp < self.killRange.low or self.killRange.low == 0 then
                self.killRange.low = value.xp
            end
            if value.xp > self.killRange.high then
                self.killRange.high = value.xp
            end
            total = total + value.xp
        end
        self.killRange.average = (total / maxUsed)
    else
        self.killRange.average = WheelchairLevel.Lib:MobXP()
        self.killRange.high = self.killRange.average
        self.killRange.low = self.killRange.average
    end

    -- Recruit A Friend beta test.
    -- Simply tripples the DISPLAY value. The actual data remains intact.
    if WheelchairLevel.Lib:IsRafApplied() then
        return {
            high = self.killRange.high * 3,
            low = self.killRange.low * 3,
            average = self.killRange.average * 3
        }
    else
        return self.killRange
    end
end

---
-- Gets the average number of kills needed to reache the next level, based
-- on the XP value returned by the GetAverageKillXP function.
-- @return A number. -1 if the function fails.
---
function WheelchairLevel.Player:GetAverageKillsRemaining()
    if (self:GetAverageKillXP() > 0) then
        return self:GetKillsRequired(self:GetAverageKillXP())
    else
        return -1
    end
end

---
-- Get the average XP per quest. The number of quests used is limited by the
-- WheelchairLevel.db.profile.averageDisplay.playerQuestListLength configuration directive. -
-- The value returned is stored in the questAverage member, so calling this
-- function twice only calculates the value once. If no data is avaiable,
-- a level based estimate is used.
-- Note that the function applies the Recruit-A-Friend bonus when applicable
-- but that does not affect the actual value stored. It is applied only when
-- the value is about to be returned.
-- @return A number.
---
function WheelchairLevel.Player:GetAverageQuestXP()
    if self.questAverage == nil then
        if (#WheelchairLevel.db.char.data.questList > 0) then
            local total = 0
            local maxUsed = #WheelchairLevel.db.char.data.questList
            if maxUsed > WheelchairLevel.db.profile.averageDisplay.playerQuestListLength then
                maxUsed = WheelchairLevel.db.profile.averageDisplay.playerQuestListLength
            end
            for index, value in ipairs(WheelchairLevel.db.char.data.questList) do
                if index > maxUsed then
                    break
                end
                total = total + value
            end
            self.questAverage = (total / maxUsed)
        else
            -- A very VERY rought and quite possibly very wrong estimate.
            -- But it is accurate for the first few levels, which is where the inaccuracy would be most visible, so...
            self.questAverage = WheelchairLevel.Lib:MobXP() * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)
        end
    end
    -- Recruit A Friend beta test.
    -- Simply tripples the DISPLAY value. The actual data remains intact.
    if WheelchairLevel.Lib:IsRafApplied() then
        return (self.questAverage * 3)
    else
        return self.questAverage
    end
end

---
-- Calculates the average, highest and lowest XP values recorded for quests.
-- The range of data used is limited by the
-- WheelchairLevel.db.profile.averageDisplay.playerQuestListLength config directive. If no data
-- is available, a level based estimate is used. Note that the function
-- applies the Recruit-A-Friend bonus when applicable but that does not
-- affect the actual value stored. It is applied only whenthe value is about
-- to be returned.
-- @return A table as : { 'average', 'high', 'low' }
---
function WheelchairLevel.Player:GetQuestXpRange()
    if (#WheelchairLevel.db.char.data.questList > 0) then
        self.questRange.high = 0
        self.questRange.low = 0
        self.questRange.average = 0
        local total = 0
        local maxUsed = #WheelchairLevel.db.char.data.questList
        if maxUsed > WheelchairLevel.db.profile.averageDisplay.playerQuestListLength then
            maxUsed = WheelchairLevel.db.profile.averageDisplay.playerQuestListLength
        end
        for index, value in ipairs(WheelchairLevel.db.char.data.questList) do
            if index > maxUsed then
                break
            end
            if value < self.questRange.low or self.questRange.low == 0 then
                self.questRange.low = value
            end
            if value > self.questRange.high then
                self.questRange.high = value
            end
            total = total + value
        end
        self.questAverage = (total / maxUsed)
        self.questRange.average = self.questAverage
    else
        -- A very VERY rought and quite possibly very wrong estimate.
        -- But it is accurate for the first few levels, which is where the inaccuracy would be most visible, so...
        self.questAverage = WheelchairLevel.Lib:MobXP() * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)
        self.questRange.high = self.questAverage
        self.questRange.low = self.questAverage
        self.questRange.average = self.questAverage
    end

    -- Recruit A Friend beta test.
    -- Simply tripples the DISPLAY value. The actual data remains intact.
    if WheelchairLevel.Lib:IsRafApplied() then
        return {
            high = self.questRange.high * 3,
            low = self.questRange.low * 3,
            average = self.questRange.average * 3
        }
    else
        return self.questRange
    end
end

---
-- Gets the average number of quests needed to reache the next level, based
-- on the XP value returned by the GetAverageQuestXP function.
-- @return A number. -1 if the function fails.
---
function WheelchairLevel.Player:GetAverageQuestsRemaining()
    if (self:GetAverageQuestXP() > 0) then
        return self:GetQuestsRequired(self:GetAverageQuestXP())
    else
        return -1
    end
end
---
-- Checks whether any battleground data has been recorded yet.
-- @return boolean
---
function WheelchairLevel.Player:HasBattlegroundData()
    return (#WheelchairLevel.db.char.data.bgList > 0)
end

---
-- Get the average XP per BG. The number of BGs used is limited by the
-- WheelchairLevel.db.profile.averageDisplay.playerBGListLength configuration directive.
-- The value returned is stored in the bgAverage member, so calling this
-- function twice only calculates the value once. If no data is avaiable,
-- a rough level based estimate is used.
-- @return A number.
---
function WheelchairLevel.Player:GetAverageBGXP()
    if self.bgAverage == nil then
        if (#WheelchairLevel.db.char.data.bgList > 0) then
            local total = 0
            local maxUsed = #WheelchairLevel.db.char.data.bgList
            if maxUsed > WheelchairLevel.db.profile.averageDisplay.playerBGListLength then
                maxUsed = WheelchairLevel.db.profile.averageDisplay.playerBGListLength
            end
            local usedCounter = 0
            for index, value in ipairs(WheelchairLevel.db.char.data.bgList) do
                if usedCounter >= maxUsed then
                    break
                end
                -- To compensate for the fact that levels were not recorded before 3.3.3_12r.
                if value.level == nil then
                    WheelchairLevel.db.char.data.bgList[index].level = self.level
                    value.level = self.level
                end
                if self.level - value.level < 5 then
                    total = total + value.totalXP
                    usedCounter = usedCounter + 1
                end
            end
            if usedCounter > 0 then
                self.bgAverage = (total / usedCounter)
            else
                self.bgAverage = WheelchairLevel.Lib:MobXP() * 50 --(WheelchairLevel.Lib:MobXP() * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)) * 2
            end
        else
            self.bgAverage = WheelchairLevel.Lib:MobXP() * 50 --(WheelchairLevel.Lib:MobXP() * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)) * 2
        end
    end
    return self.bgAverage
end

---
-- Gets the average number of BGs needed to reache the next level, based
-- on the XP value returned by the GetAverageBGXP function.
-- @return A number. nil if the function fails.
---
function WheelchairLevel.Player:GetAverageBGsRemaining()
    local bgAverage = self:GetAverageBGXP()
    if (bgAverage > 0) then
        local xpRemaining = self.maxXP - self.currentXP
        return ceil(xpRemaining / bgAverage)
    else
        return nil
    end
end

---
-- Get the average XP per BG objective. The number of BG objectives used is
-- limited by the WheelchairLevel.db.profile.averageDisplay.playerBGOListLength config directive.
-- The value returned is stored in the bgObjAverage member, so calling this
-- function twice only calculates the value once. If no data is avaiable,
-- a rough level based estimate is used.
-- @return A number.
---
function WheelchairLevel.Player:GetAverageBGObjectiveXP()
    if self.bgObjAverage == nil then
        if (#WheelchairLevel.db.char.data.bgList > 0) then
            local total = 0
            local count = 0
            local maxcount = WheelchairLevel.db.profile.averageDisplay.playerBGOListLength
            for index, value in ipairs(WheelchairLevel.db.char.data.bgList) do
                if count >= maxcount then
                    break
                end
                if value.level == nil then
                    WheelchairLevel.db.char.data.bgList[index].level = self.level
                    value.level = self.level
                end
                if (value.objTotal > 0) and (value.objCount > 0) and (self.level - value.level < 5) then
                    total = total + (value.objTotal / value.objCount)
                    count = count + 1
                end
            end
            if count == 0 then
                self.bgObjAverage = self:GetAverageQuestXP() -- * math.floor(((self.level + 9) / (self.maxLevel + 9)) * 20)
            else
                self.bgObjAverage = (total / count)
            end
        else
            self.bgObjAverage = self:GetAverageQuestXP()
        end
    end
    return self.bgObjAverage
end

---
-- Gets the average number of BG Objectives needed to reache the next level,
-- based on the XP value returned by the GetAverageBGObjectiveXP function.
-- @return A number. -1 if the function fails.
---
function WheelchairLevel.Player:GetAverageBGObjectivesRemaining()
    local objAverage = self:GetAverageBGObjectiveXP()
    if (objAverage > 0) then
        local xpRemaining = self.maxXP - self.currentXP
        return ceil(xpRemaining / objAverage)
    else
        return nil
    end
end

---
-- Gets the names of all battlegrounds that have been recorded so far.
-- @return A { 'name' = count, ... } table on success or nil if no data exists.
---
function WheelchairLevel.Player:GetBattlegroundsListed()
    if (#WheelchairLevel.db.char.data.bgList > 0) then
        local count = 0
        for index, value in ipairs(WheelchairLevel.db.char.data.bgList) do
            if value.level == nil then
                value.level = self.level
                WheelchairLevel.db.char.data.bgList[index].level = self.level
            end
            if self.level - value.level < 5 and value.totalXP > 0 and not value.inProgress then
                self.bgList[value.name] = (self.bgList[value.name] or 0) + 1
                count = count + 1
            end
        end
        if count > 0 then
            return self.bgList
        else
            return nil
        end
    else
        return nil
    end
end

---
-- Returns the average XP for the given battleground. The data is limited by
-- the WheelchairLevel.db.profile.averageDisplay.playerBGListLength config directive. Note that
-- battlegrounds currently in progress will not be counted.
-- @param name The name of the battleground to be used.
-- @return A number. If the database has no entries, it returns 0.
---
function WheelchairLevel.Player:GetBattlegroundAverage(name)
    if (#WheelchairLevel.db.char.data.bgList > 0) then
        local total = 0
        local count = 0
        local maxcount = WheelchairLevel.db.profile.averageDisplay.playerBGListLength
        for index, value in ipairs(WheelchairLevel.db.char.data.bgList) do
            if count >= maxcount then
                break
            end
            if value.level == nil then
                WheelchairLevel.db.char.data.bgList[index].level = self.level
                value.level = self.level
            end
            if value.name == name and not value.inProgress and (self.level - value.level < 5) then
                total = total + value.totalXP
                count = count + 1
            end
        end
        if count == 0 then
            return 0
        else
            return WheelchairLevel.Lib:round(total / count, 0)
        end
    else
        return 0
    end
end

---
-- Gets details for the last entry in the battleground list.
-- @return A table matching the CreateBgDataArray template, or nil if no
--         battlegrounds have been recorded yet.
---
function WheelchairLevel.Player:GetLatestBattlegroundDetails()
    if #WheelchairLevel.db.char.data.bgList > 0 then
        -- Make sure to get the latest BG in a 5 level range.
        for index, value in ipairs(WheelchairLevel.db.char.data.bgList) do
            if WheelchairLevel.Player.level - tonumber(value.level) < 5 then
                self.latestBgData.name = value.name
                self.latestBgData.totalXP = value.totalXP
                self.latestBgData.objCount = value.objCount
                self.latestBgData.killCount = value.killCount
                self.latestBgData.xpPerObj = 0
                self.latestBgData.xpPerKill = 0
                self.latestBgData.inProgress = value.inProgress
                self.latestBgData.otherXP = value.totalXP - (value.objTotal + value.killTotal)
                if self.latestBgData.objCount > 0 then
                    self.latestBgData.xpPerObj = WheelchairLevel.Lib:round(value.objTotal / self.latestBgData.objCount, 0)
                end
                if self.latestBgData.killCount > 0 then
                    self.latestBgData.xpPerKill = WheelchairLevel.Lib:round(value.killTotal / self.latestBgData.killCount, 0)
                end
                return self.latestBgData
            end
        end
    end
    return nil
end

---
-- Checks whether any dungeon data has been recorded yet.
-- @return boolean
---
function WheelchairLevel.Player:HasDungeonData()
    return (#WheelchairLevel.db.char.data.dungeonList > 0)
end

---
-- Get the average XP per dungeon. The number of dungeons used is limited by
-- the WheelchairLevel.db.profile.averageDisplay.playerDungeonListLength configuration directive.
-- The value returned is stored in the dungeonAverage member, so calling
-- this function twice only calculates the value once. If no data is,
-- avaiable a rough level based estimate is used.
-- @return A number.
---
function WheelchairLevel.Player:GetAverageDungeonXP()
    if self.dungeonAverage == nil then
        if
            (#WheelchairLevel.db.char.data.dungeonList > 0) and
                not ((#WheelchairLevel.db.char.data.dungeonList == 1) and WheelchairLevel.db.char.data.dungeonList[1].inProgress)
         then
            local total = 0
            local maxUsed = #WheelchairLevel.db.char.data.dungeonList
            if maxUsed > WheelchairLevel.db.profile.averageDisplay.playerDungeonListLength then
                maxUsed = WheelchairLevel.db.profile.averageDisplay.playerDungeonListLength
            end
            local usedCounter = 0
            for index, value in ipairs(WheelchairLevel.db.char.data.dungeonList) do
                if usedCounter >= maxUsed then
                    break
                end
                -- To compensate for the fact that levels were not recorded before 3.3.3_12r.
                if value.level == nil then
                    WheelchairLevel.db.char.data.dungeonList[index].level = self.level
                    value.level = self.level
                end
                if self.level - value.level < 5 then
                    total = total + value.totalXP
                    usedCounter = usedCounter + 1
                end
            end
            if usedCounter > 0 then
                self.dungeonAverage = (total / usedCounter)
            else
                self.dungeonAverage = WheelchairLevel.Lib:MobXP() * 100
            end
        else
            self.dungeonAverage = WheelchairLevel.Lib:MobXP() * 100
        end
    end
    return self.dungeonAverage
end

---
-- Gets the average number of dungeons needed to reache the next level,
-- basedon the XP value returned by the GetAverageDungeonXP function.
-- @return A number. nil if the function fails.
---
function WheelchairLevel.Player:GetAverageDungeonsRemaining()
    local dungeonAverage = self:GetAverageDungeonXP()
    if (dungeonAverage > 0) then
        return self:GetKillsRequired(dungeonAverage)
    else
        return nil
    end
end

---
-- Gets the names of all dungeons that have been recorded so far.
-- @return A { 'name' = count, ... } table on success or nil if no data exists.
---
function WheelchairLevel.Player:GetDungeonsListed()
    if #WheelchairLevel.db.char.data.dungeonList > 0 then
        -- Clear list in a memory efficient way.
        for index, value in pairs(self.dungeonList) do
            self.dungeonList[index] = 0
        end
        local count = 0
        for index, value in ipairs(WheelchairLevel.db.char.data.dungeonList) do
            if value.level == nil then
                WheelchairLevel.db.char.data.dungeonList[index].level = self.level
                value.level = self.level
            end
            if self.level - value.level < 5 and value.totalXP > 0 and not value.inProgress then
                self.dungeonList[value.name] = (self.dungeonList[value.name] or 0) + 1
                count = count + 1
            end
        end
        if count > 0 then
            return self.dungeonList
        else
            return nil
        end
    else
        return nil
    end
end

---
-- Returns the average XP for the given dungeon. The data is limited by
-- the WheelchairLevel.db.profile.averageDisplay.playerDungeonListLength config directive. Note
-- that dungeons currently in progress will not be counted.
-- @param name The name of the dungeon to be used.
-- @return A number. If the database has no entries, it returns 0.
---
function WheelchairLevel.Player:GetDungeonAverage(name)
    if (#WheelchairLevel.db.char.data.dungeonList > 0) then
        local total = 0
        local count = 0
        local maxcount = WheelchairLevel.db.profile.averageDisplay.playerDungeonListLength
        for index, value in ipairs(WheelchairLevel.db.char.data.dungeonList) do
            if count >= maxcount then
                break
            end
            if value.level == nil then
                WheelchairLevel.db.char.data.dungeonList[index].level = self.level
                value.level = self.level
            end
            if value.name == name and not value.inProgress and (self.level - value.level < 5) then
                total = total + value.totalXP
                count = count + 1
            end
        end
        if count == 0 then
            return 0
        else
            return WheelchairLevel.Lib:round(total / count, 0)
        end
    else
        return 0
    end
end

---
-- Gets details for the last entry in the dungeon list.
-- @return A table matching the CreateDungeonDataArray template, or nil if
--         no battlegrounds have been recorded yet.
---
function WheelchairLevel.Player:GetLatestDungeonDetails()
    if #WheelchairLevel.db.char.data.dungeonList > 0 then
        self.latestDungeonData.totalXP = WheelchairLevel.db.char.data.dungeonList[1].totalXP
        self.latestDungeonData.killCount = WheelchairLevel.db.char.data.dungeonList[1].killCount
        self.latestDungeonData.xpPerKill = 0
        self.latestDungeonData.rested = WheelchairLevel.db.char.data.dungeonList[1].rested
        self.latestDungeonData.otherXP =
            WheelchairLevel.db.char.data.dungeonList[1].totalXP - WheelchairLevel.db.char.data.dungeonList[1].killTotal
        if self.latestDungeonData.killCount > 0 then
            self.latestDungeonData.xpPerKill =
                WheelchairLevel.Lib:round(WheelchairLevel.db.char.data.dungeonList[1].killTotal / self.latestDungeonData.killCount, 0)
        end

        return self.latestDungeonData
    else
        return nil
    end
end

---
--- gets the count of resets in the last hour and the timestamp of the oldest (next resetting one)
---
function WheelchairLevel.Player:GetResetsInLastHour()
    local anHourAgo = time() - 3600
    local resetCount = 0
    local oldestStart
    if #WheelchairLevel.db.char.data.dungeonList > 0 then
        for index, value in ipairs(WheelchairLevel.db.char.data.dungeonList) do
            if value.startTime > anHourAgo then
                resetCount = resetCount + 1
                if oldestStart == nil or oldestStart > value.startTime then
                    oldestStart = value.startTime
                end
            end
        end
    else
        return 0, oldestStart
    end
    return resetCount, oldestStart
end

--get the best dungeon based on xpPerHour within the last 5 levels
function WheelchairLevel.Player:GetBestDungeon()
    if #WheelchairLevel.db.char.data.dungeonList > 0 then
        local bestDungeon
        local bestXpPerHour = 0

        for index, value in ipairs(WheelchairLevel.db.char.data.dungeonList) do
            if value.level == nil then
                WheelchairLevel.db.char.data.dungeonList[index].level = self.level
                value.level = self.level
            end
            if self.level - value.level < 5 and value.totalXP > 0 and not value.inProgress then
                local xpPerHour = value.totalXP / ((value.endTime - value.startTime) / 3600)
                if xpPerHour > bestXpPerHour then
                    bestDungeon = value
                    bestXpPerHour = xpPerHour
                end
            end
        end
        return bestDungeon, bestXpPerHour
    else
        return nil, nil
    end
end

---
-- Clears the kill list. If the initialValue parameter is passed, a single
-- entry with that value is added.
-- @param initalValue The inital value for the list. [optional]
function WheelchairLevel.Player:ClearKills(initialValue)
    WheelchairLevel.db.char.data.killList = {}
    self.killAverage = nil
    if initialValue ~= nil and tonumber(initialValue) > 0 then
        table.insert(WheelchairLevel.db.char.data.killList, { mob = "Initial", xp = tonumber(initialValue)})
    end
end

---
-- Clears the quest list. If the initialValue parameter is passed, a single
-- entry with that value is added.
-- @param initalValue The inital value for the list. [optional]
function WheelchairLevel.Player:ClearQuests(initialValue)
    WheelchairLevel.db.char.data.questList = {}
    self.questAverage = nil
    if initialValue ~= nil and tonumber(initialValue) > 0 then
        table.insert(WheelchairLevel.db.char.data.questList, tonumber(initialValue))
    end
end

---
-- Clears the dungeon list. If the initialValue parameter is passed, a
-- single entry with that value is added.
function WheelchairLevel.Player:ClearDungeonList(initialValue)
    WheelchairLevel.db.char.data.dungeonList = {}
    self.dungeonAverage = nil

    local inInstance, type = IsInInstance()
    if inInstance and type == "party" then
        self:DungeonStart()
    end
end

---
-- Checks whether the player is rested.
-- @return The additional XP the player will get until he is unrested again
--         or FALSE if the player is not rested.
---
function WheelchairLevel.Player:IsRested()
    if self.restedXP > 0 then
        return self.restedXP
    else
        return false
    end
end

---
-- Sets the number of kills used for average calculations
function WheelchairLevel.Player:SetKillAverageLength(newValue)
    WheelchairLevel.db.profile.averageDisplay.playerKillListLength = newValue
    self.killAverage = nil
    WheelchairLevel.Average:Update()

end

---
-- Sets the number of quests used for average calculations
function WheelchairLevel.Player:SetQuestAverageLength(newValue)
    WheelchairLevel.db.profile.averageDisplay.playerQuestListLength = newValue
    self.questAverage = nil
    WheelchairLevel.Average:Update()

end

---
-- Sets the number of pet battles used for average calculations
function WheelchairLevel.Player:SetPetBattleAverageLength(newValue)
    WheelchairLevel.db.profile.averageDisplay.playerPetBattleListLength = newValue
    self.petBattleAverage = nil
    WheelchairLevel.Average:Update()

end

---
-- Sets the number of battleground used for average calculations
function WheelchairLevel.Player:SetBattleAverageLength(newValue)
    WheelchairLevel.db.profile.averageDisplay.playerBGListLength = newValue
    self.bgAverage = nil
    WheelchairLevel.Average:Update()

end

---
-- Sets the number of quest objectives used for average calculations
function WheelchairLevel.Player:SetObjectiveAverageLength(newValue)
    WheelchairLevel.db.profile.averageDisplay.playerBGOListLength = newValue
    self.bgObjAverage = nil
    WheelchairLevel.Average:Update()

end

---
-- Sets the number of dungeon used for average calculations
function WheelchairLevel.Player:SetDungeonAverageLength(newValue)
    WheelchairLevel.db.profile.averageDisplay.playerDungeonListLength = newValue
    self.dungeonAverage = nil
    WheelchairLevel.Average:Update()

end
