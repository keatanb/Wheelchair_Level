local _, addonTable = ...
---
-- Contains definitions for the Tooltip display.
---

local L = addonTable.GetLocale()

WheelchairLevel.Tooltip = {
    initialized = false,
    OnShow_Before = nil,
    OnShow_XpData = {},
    labelColor = {},
    dataColor = {},
    footerColor = {},
    verticalMargin = 2,
    horizontalMargin = 20
}

---
-- function description
function WheelchairLevel.Tooltip:Initialize()
    --if WheelchairLevel.db.profile.ldb.allowTextColor then
        self.labelColor = {r = 0.75, g = 0.75, b = 0.75}
        self.dataColor = {r = 0.9, g = 1, b = 0.9}
        self.footerColor = {r = 0.6, g = 0.6, b = 0.6}
    --end
    self.initialized = true

    GameTooltip:HookScript("OnTooltipSetUnit", self.OnTooltipSetUnit_HookCallback)
end

---
-- Used to resize the GameTooltip after adding a new line to it.
function WheelchairLevel.Tooltip:ResizeTooltip()
    local str = _G[GameTooltip:GetName() .. "TextLeft" .. GameTooltip:NumLines()]
    if str ~= nil then
        local width = str:GetStringWidth() + self.horizontalMargin
        GameTooltip:SetHeight(GameTooltip:GetHeight() + str:GetStringHeight() + self.verticalMargin)
        if (GameTooltip:GetWidth() < width) then
            GameTooltip:SetWidth(width)
        end
    else
        -- Fallback in case the line couldn't be found.
        GameTooltip:Show()
        console:log("WheelchairLevel.Tooltip::ResizeTooltip - Primary resize method failed, falling back on GameTooltip::Show")
    end
end

---
-- Callback for the GameTooltip:OnShow hook
-- Adds the number of kills needed to unfriendly NPC tooltips.
function WheelchairLevel.Tooltip:OnTooltipSetUnit_HookCallback(...)
    if WheelchairLevel.db.profile.general.showNpcTooltipData and WheelchairLevel.Player.level < WheelchairLevel.Player.maxLevel then
        local name, unit = GameTooltip:GetUnit()
        if
            unit and not UnitIsPlayer(unit) and not UnitIsFriend("player", unit) and UnitLevel(unit) > 0 and
                not UnitIsTrivial(unit) and
                UnitHealthMax(unit) > -1
         then
            local level = UnitLevel(unit)
            local classification = UnitClassification(unit)

            local thexp = WheelchairLevel.Lib:MobXP(WheelchairLevel.Player.level, level, classification)

            local requiredText = ""
            local cl

            if thexp == 0 then
                -- Search for an approximation from lower levels.
                cl = WheelchairLevel.Player.level - 1
                while thexp == 0 and cl > WheelchairLevel.Player.level - 5 do
                    thexp = WheelchairLevel.Lib:MobXP(cl, level)
                    cl = cl - 1
                end
            end

            if thexp > 0 then
                local killsRequired = WheelchairLevel.Player:GetKillsRequired(thexp)
                if killsRequired > 0 then
                    local output = WheelchairLevel.Player:GetKillsRequired(thexp)
                    if cl ~= nil then
                        output = "~" .. output
                    end

                    local color = "888888"
                    local diff = WheelchairLevel.Player.level - level

                    local percent = 50 + (diff * 10)
                    if percent <= 100 then
                        if percent < 0 then
                            percent = 0
                        end
                        color = WheelchairLevel.Lib:GetProgressColor(percent)
                    end

                    GameTooltip:AddLine(
                        "|cFFAAAAAA" .. L["Kills to level"] .. ": |r |cFF" .. color .. output .. "|r",
                        0.75,
                        0.75,
                        0.75
                    )
                    WheelchairLevel.Tooltip:ResizeTooltip()
                else
                    requiredText = nil
                end
            else
                requiredText = nil
            end

            if requiredText then
            end
        end
    end
end

---
-- Shows the given message when the given frame is rolled over by the mouse.
-- This is tailored to config option error details, such as the low level
-- warning for battleground options, and is displayed in red at the mouse.
-- @param frame The frame that should trigger the message tooltip
-- @param text The text to show in the tooltip.
function WheelchairLevel.Tooltip:SetConfigInfo(frame, text)
    frame:SetScript(
        "OnEnter",
        function()
            WheelchairLevel.Tooltip:ShowConfigDescription(text)
        end
    )
    frame:SetScript(
        "OnLeave",
        function()
            WheelchairLevel.Tooltip:HideConfigDescription()
        end
    )
end

---
-- The callback for when a config option, set by the SetConfigInfo() function
-- is rolled over by the mouse. Shows the given text at the mosue posistion.
-- The text is displayed in red, at 75% the normal size.
-- NOTE! Use the HideConfigDescription method to hide this tooltip, or you
-- risk that the scale bleeds over to the next tooltip that is shown.
-- @param text The text to show.
function WheelchairLevel.Tooltip:ShowConfigDescription(text)
    GameTooltip:SetOwner(WheelchairLevel.frame, "ANCHOR_CURSOR")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(text, 1, 0.25, 0.25, true)
    GameTooltip:Show()
end

---
-- Hides the tooltip, setting hte scale back to normal.
function WheelchairLevel.Tooltip:HideConfigDescription()
    GameTooltip:Hide()
end

---
-- Shows the tooltip for the Average and LDB windows. When given, the
-- mode parameter sets what exactly should be shown. If no valid mode
-- is give, all the info is shown. The user config is taken into account
-- and unchecned Tooltip options will be hidden.
-- @param frame The parent frame, if any. This will be the anchor frame
--        for the tooltip. If none is given, the default position is used.
-- @param anchorPoint The point of the tooltip that should be anchored to
--        the relative fram.
-- @param relativeFrame The frame to which the tooltip should be attached.
-- @param relativePoint The point of the relative frame that the tooltip
--        should be anchored to.
-- @param footerText The text to display at the foot of the tooltip.
-- @param mode A string to indicate what info should be shown in the tooltip.
--        This is one of: "bg", "kills", "quests", "dungeons", "experience",
--        "all". ("all" is the default, if an invalid mode
--        is passed.)
function WheelchairLevel.Tooltip:Show(frame, anchorPont, relativeFrame, relativePoint, footerText, mode)
    -- Initialize
    if not self.initialized then
        self:Initialize()
    end

    GameTooltip:Hide()

    if false and frame ~= nil then
        GameTooltip:SetOwner(frame, "ANCHOR_NONE")
    end
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    if anchorPont ~= nil or relativeFrame ~= nil or relativePoint ~= nil then
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint(anchorPont, relativeFrame, relativePoint)
    end
    GameTooltip:ClearLines()

    if mode == "bg" then
        GameTooltip:AddLine(L["Battlegrounds"])
        self:AddBattlegroundInfo()
        GameTooltip:AddLine(" ")
        self:AddBattles()
        GameTooltip:AddLine(" ")
    elseif mode == "kills" then
        GameTooltip:AddLine(L["Kills"])
        self:AddKillRange()
        GameTooltip:AddLine(" ")
    elseif mode == "quests" then
        GameTooltip:AddLine(L["Quests"])
        self:AddQuestRange()
        GameTooltip:AddLine(" ")
    elseif mode == "dungeons" then
        GameTooltip:AddLine(L["Dungeons"])
        self:AddDungeonInfo()
        GameTooltip:AddLine(" ")
        self:AddDungeons()
        GameTooltip:AddLine(" ")
    elseif mode == "experience" then
        GameTooltip:AddLine(L["Experience"])
        self:AddExperience()
        GameTooltip:AddLine(" ")
    elseif mode == "timer" then
        GameTooltip:AddLine("Time to level")
        self:AddTimerDetails(false)
        GameTooltip:AddLine(" ")
    else
        -- The old "overall" tootip
        GameTooltip:AddLine(L["WheelchairLevel"])

        if WheelchairLevel.Player.level < WheelchairLevel.Player:GetMaxLevel() then
            if WheelchairLevel.db.profile.ldb.tooltip.showDetails then
                self:AddKills()
                self:AddQuests()
            end
            if WheelchairLevel.Lib:ShowDungeonData() then -- Overall Dungeon Info
                self:AddDungeonInfo()
            end
            GameTooltip:AddLine(" ")
            if WheelchairLevel.db.profile.ldb.tooltip.showExperience then
                GameTooltip:AddLine(L["Experience"] .. ": ")
                self:AddExperience()
                GameTooltip:AddLine(" ")
            end
            if WheelchairLevel.Lib:ShowDungeonData() then
                self:AddDungeons()
                GameTooltip:AddLine(" ")
            end
            if WheelchairLevel.Lib:ShowBattlegroundData() then
                self:AddBattles()
                GameTooltip:AddLine(" ")
            end
            if WheelchairLevel.db.profile.timer.enabled and WheelchairLevel.db.profile.ldb.tooltip.showTimerInfo then
                GameTooltip:AddLine(L["Timer"] .. ":")
                self:AddTimerDetails(true)
                GameTooltip:AddLine(" ")
            end
        else
            GameTooltip:AddLine(L["Max Level LDB Message"], 255, 255, 255)
        end
    end -- END "Overall" tooltip creation

    if footerText ~= nil then
        GameTooltip:AddLine(tostring(footerText), self.footerColor.r, self.footerColor.g, self.footerColor.b)
    end

    GameTooltip:Show()
end

---
-- Wrapper function to hide the frame.
function WheelchairLevel.Tooltip:Hide()
    GameTooltip:Hide()
end

--
-- Add functions
-- Used by the Show function to assemble the requsted tooltip
--
---
-- function description
function WheelchairLevel.Tooltip:AddKills()
    GameTooltip:AddDoubleLine(
        " " .. L["Kills"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetAverageKillsRemaining()) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(WheelchairLevel.Player:GetAverageKillXP(), 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
end
---
-- function description
function WheelchairLevel.Tooltip:AddKillRange()
    local range = WheelchairLevel.Player:GetKillXpRange()
    GameTooltip:AddDoubleLine(
        " " .. L["Average"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetKillsRequired(range.average)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.average, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Min"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetKillsRequired(range.high)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.high, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Max"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetKillsRequired(range.low)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.low, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " ",
        " ",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["XP Rested"] .. ": ",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:IsRested() or 0) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
end

---
-- function description
function WheelchairLevel.Tooltip:AddQuests()
    GameTooltip:AddDoubleLine(
        " " .. L["Quests"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetAverageQuestsRemaining()) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(WheelchairLevel.Player:GetAverageQuestXP(), 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
end
---
-- function description
function WheelchairLevel.Tooltip:AddQuestRange()
    local range = WheelchairLevel.Player:GetQuestXpRange()
    GameTooltip:AddDoubleLine(
        " " .. L["Average"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetQuestsRequired(range.average)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.average, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Min"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetQuestsRequired(range.high)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.high, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Max"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetQuestsRequired(range.low)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.low, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
end

---
-- function description
function WheelchairLevel.Tooltip:AddPetBattleRange()
    local range = WheelchairLevel.Player:GetPetBattleXpRange()
    GameTooltip:AddDoubleLine(
        " " .. L["Average"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetPetBattlesRequired(range.average)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.average, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Min"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetPetBattlesRequired(range.high)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.high, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Max"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetPetBattlesRequired(range.low)) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(range.low, 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
end

---
-- function description
function WheelchairLevel.Tooltip:AddDungeonInfo()
    GameTooltip:AddDoubleLine(
        " " .. L["Dungeons"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetAverageDungeonsRemaining()) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(WheelchairLevel.Player:GetAverageDungeonXP(), 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
end

---
-- function description
function WheelchairLevel.Tooltip:AddDungeons()
    if (#WheelchairLevel.db.char.data.dungeonList) > 0 then
        local dungeons, latestData, averageRaw, averageFormatted, needed

        dungeons = WheelchairLevel.Player:GetDungeonsListed()
        latestData = WheelchairLevel.Player:GetLatestDungeonDetails()

        if dungeons ~= nil then
            GameTooltip:AddLine(L["Dungeons Required"] .. ":")
            for name, count in pairs(dungeons) do
                if name == false then
                    name = "Unknown"
                end
                averageRaw = WheelchairLevel.Player:GetDungeonAverage(name)
                if averageRaw > 0 then
                    averageFormatted = WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(averageRaw, 0))
                    needed = WheelchairLevel.Player:GetKillsRequired(tonumber(averageRaw))
                    GameTooltip:AddDoubleLine(
                        " " .. name .. ": ",
                        needed .. " @ " .. averageFormatted .. " xp",
                        self.labelColor.r,
                        self.labelColor.g,
                        self.labelColor.b,
                        self.dataColor.r,
                        self.dataColor.b,
                        self.dataColor.b
                    )
                end
            end
            GameTooltip:AddLine(" ")
        end

        if WheelchairLevel.db.char.data.dungeonList[1].inProgress then
            GameTooltip:AddLine(L["Current Dungeon"] .. ":")
        else
            GameTooltip:AddLine(L["Last Dungeon"] .. ":")
        end

        local dungeonName
        if type(WheelchairLevel.db.char.data.dungeonList[1].name) ~= "string" then
            if select(1,GetInstanceInfo()) ~= nil then
                WheelchairLevel.db.char.data.dungeonList[1].name = select(1,GetInstanceInfo())
                dungeonName = WheelchairLevel.db.char.data.dungeonList[1].name
            else
                dungeonName = "Unknown"
            end
        else
            dungeonName = WheelchairLevel.db.char.data.dungeonList[1].name
        end

        GameTooltip:AddDoubleLine(
            " " .. L["Name"] .. ": ",
            dungeonName,
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )
        local duration
        if WheelchairLevel.db.char.data.dungeonList[1].endTime == nil then
            duration = time() - WheelchairLevel.db.char.data.dungeonList[1].startTime
        else
            duration = WheelchairLevel.db.char.data.dungeonList[1].endTime - WheelchairLevel.db.char.data.dungeonList[1].startTime
        end
        GameTooltip:AddDoubleLine(
                " Duration: ",
                WheelchairLevel.Lib:TimeFormat(duration),
                self.labelColor.r,
                self.labelColor.g,
                self.labelColor.b,
                self.dataColor.r,
                self.dataColor.b,
                self.dataColor.b
        )
        GameTooltip:AddDoubleLine(
                " XPh: ",
                WheelchairLevel.Lib:NumberFormat(latestData.totalXP / (duration / 60 / 60)) ,
                self.labelColor.r,
                self.labelColor.g,
                self.labelColor.b,
                self.dataColor.r,
                self.dataColor.b,
                self.dataColor.b
        )
        GameTooltip:AddDoubleLine(
            " " .. L["Kills"] .. ": ",
            WheelchairLevel.Lib:NumberFormat(latestData.killCount) ..
                " @ " .. WheelchairLevel.Lib:NumberFormat(latestData.xpPerKill) .. " xp",
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )

        if latestData.rested > 0 then
            local total = latestData.totalXP + latestData.rested
            GameTooltip:AddDoubleLine(
                " " .. L["Total XP"] .. ": ",
                WheelchairLevel.Lib:NumberFormat(total) ..
                    " (" .. WheelchairLevel.Lib:NumberFormat(latestData.rested) .. " " .. L["XP Rested"] .. ")",
                self.labelColor.r,
                self.labelColor.g,
                self.labelColor.b,
                self.dataColor.r,
                self.dataColor.b,
                self.dataColor.b
            )
        else
            GameTooltip:AddDoubleLine(
                " " .. L["Total XP"] .. ": ",
                WheelchairLevel.Lib:NumberFormat(latestData.totalXP),
                self.labelColor.r,
                self.labelColor.g,
                self.labelColor.b,
                self.dataColor.r,
                self.dataColor.b,
                self.dataColor.b
            )
        end

        local bestDungeon, bestXpPerHour = WheelchairLevel.Player:GetBestDungeon()
        if bestDungeon then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Best Dungeon:")
            GameTooltip:AddDoubleLine(
                    " " .. L["Name"] .. ": ",
                    bestDungeon.name,
                    self.labelColor.r,
                    self.labelColor.g,
                    self.labelColor.b,
                    self.dataColor.r,
                    self.dataColor.b,
                    self.dataColor.b
            )
            GameTooltip:AddDoubleLine(
                    " Date: ",
                    bestDungeon.timeStamp,
                    self.labelColor.r,
                    self.labelColor.g,
                    self.labelColor.b,
                    self.dataColor.r,
                    self.dataColor.b,
                    self.dataColor.b
            )
            local bestDuration = bestDungeon.endTime - bestDungeon.startTime
            GameTooltip:AddDoubleLine(
                    " Duration: ",
                    WheelchairLevel.Lib:TimeFormat(bestDuration),
                    self.labelColor.r,
                    self.labelColor.g,
                    self.labelColor.b,
                    self.dataColor.r,
                    self.dataColor.b,
                    self.dataColor.b
            )
            GameTooltip:AddDoubleLine(
                    " XPh: ",
                    WheelchairLevel.Lib:NumberFormat(bestXpPerHour),
                    self.labelColor.r,
                    self.labelColor.g,
                    self.labelColor.b,
                    self.dataColor.r,
                    self.dataColor.b,
                    self.dataColor.b
            )
            GameTooltip:AddDoubleLine(
                    " " .. L["Kills"] .. ": ",
                    WheelchairLevel.Lib:NumberFormat(bestDungeon.killCount) ..
                            " @ " .. WheelchairLevel.Lib:NumberFormat(bestDungeon.killTotal / bestDungeon.killCount) .. " xp",
                    self.labelColor.r,
                    self.labelColor.g,
                    self.labelColor.b,
                    self.dataColor.r,
                    self.dataColor.b,
                    self.dataColor.b
            )

            if bestDungeon.rested > 0 then
                local bestTotal = bestDungeon.totalXP + bestDungeon.rested
                GameTooltip:AddDoubleLine(
                        " " .. L["Total XP"] .. ": ",
                        WheelchairLevel.Lib:NumberFormat(bestTotal) ..
                                " (" .. WheelchairLevel.Lib:NumberFormat(bestDungeon.rested) .. " " .. L["XP Rested"] .. ")",
                        self.labelColor.r,
                        self.labelColor.g,
                        self.labelColor.b,
                        self.dataColor.r,
                        self.dataColor.b,
                        self.dataColor.b
                )
            else
                GameTooltip:AddDoubleLine(
                        " " .. L["Total XP"] .. ": ",
                        WheelchairLevel.Lib:NumberFormat(bestDungeon.totalXP),
                        self.labelColor.r,
                        self.labelColor.g,
                        self.labelColor.b,
                        self.dataColor.r,
                        self.dataColor.b,
                        self.dataColor.b
                )
            end
        end

        local countDungeonsInLastHour, oldestTimeInLastHour = WheelchairLevel.Player:GetResetsInLastHour()
        if countDungeonsInLastHour > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Instances Entered: ")
            GameTooltip:AddDoubleLine(
                    " Last Hour: ",
                    countDungeonsInLastHour,
                    self.labelColor.r,
                    self.labelColor.g,
                    self.labelColor.b,
                    self.dataColor.r,
                    self.dataColor.b,
                    self.dataColor.b
            )
            GameTooltip:AddDoubleLine(
                    " Oldest unlocks in: ",
                    WheelchairLevel.Lib:TimeFormat((oldestTimeInLastHour + 3600) - time()),
                    self.labelColor.r,
                    self.labelColor.g,
                    self.labelColor.b,
                    self.dataColor.r,
                    self.dataColor.b,
                    self.dataColor.b
            )
        end

        dungeons = nil
        latestData = nil
        averageRaw = nil
        averageFormatted = nil
        needed = nil
    else
        GameTooltip:AddLine(L["Dungeons Required"] .. ":")
        GameTooltip:AddLine(" " .. L["No Dungeons Completed"], self.labelColor.r, self.labelColor.g, self.labelColor.b)
    end
end

---
-- function description
function WheelchairLevel.Tooltip:AddExperience()
    local xpProgress = WheelchairLevel.Player:GetProgressAsPercentage()
    local xpProgressBars = WheelchairLevel.Player:GetProgressAsBars()
    local xpNeededTotal = WheelchairLevel.Player.maxXP - WheelchairLevel.Player.currentXP
    local xpNeededActual = WheelchairLevel.Player:GetKillsRequired(1) or "~"

    --GameTooltip:AddLine(L["Experience"] .. ": ")
    GameTooltip:AddDoubleLine(
        " " .. L["XP Progress"] .. ": ",
        WheelchairLevel.Lib:ShrinkNumber(UnitXP("player")) ..
            " / " .. WheelchairLevel.Lib:ShrinkNumber(UnitXPMax("player")) .. " [" .. tostring(xpProgress) .. "%" .. "]",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["XP Bars Remaining"] .. ": ",
        xpProgressBars .. " bars",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["XP Rested"] .. ": ",
        WheelchairLevel.Lib:ShrinkNumber(WheelchairLevel.Player:IsRested() or 0) ..
            " [" .. WheelchairLevel.Lib:round(WheelchairLevel.Player:GetRestedPercentage(1)) .. "%]",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Quest XP Required"] .. ": ",
        WheelchairLevel.Lib:NumberFormat(xpNeededTotal) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Kill XP Required"] .. ": ",
        WheelchairLevel.Lib:NumberFormat(xpNeededActual) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )

    xpProgress = nil
    xpNeededTotal = nil
    xpNeededActual = nil
end

---
-- Guild info
function WheelchairLevel.Tooltip:AddGuildInfo()
    if WheelchairLevel.Player.guildLevel ~= nil and WheelchairLevel.Player.guildXP ~= nil then
        GameTooltip:AddDoubleLine(
            " Level:",
            WheelchairLevel.Player.guildLevel .. " / 25",
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )

        local xpGained = tostring(WheelchairLevel.Lib:ShrinkNumber(WheelchairLevel.Player.guildXP))
        local xpTotal = tostring(WheelchairLevel.Lib:ShrinkNumber(WheelchairLevel.Player.guildXPMax))
        local xpProgress = tostring(WheelchairLevel.Player:GetGuildProgressAsPercentage(1))
        GameTooltip:AddDoubleLine(
            " " .. L["XP Progress"] .. ": ",
            xpGained .. " / " .. xpTotal .. " [" .. xpProgress .. "%]",
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )

        local dialyGained = tostring(WheelchairLevel.Lib:ShrinkNumber(WheelchairLevel.Player.guildXPDaily))
        local dialyTotal = tostring(WheelchairLevel.Lib:ShrinkNumber(WheelchairLevel.Player.guildXPDailyMax))
        local dialyProgress = tostring(WheelchairLevel.Player:GetGuildDailyProgressAsPercentage(1))
        GameTooltip:AddDoubleLine(
            " " .. L["Daily Progress"] .. ": ",
            dialyGained .. " / " .. dialyTotal .. " [" .. dialyProgress .. "%]",
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )
    else
        GameTooltip:AddLine(" No guild leveling info found.", self.labelColor.r, self.labelColor.g, self.labelColor.b)
    end
end

---
-- function description
function WheelchairLevel.Tooltip:AddBattlegroundInfo()
    GameTooltip:AddDoubleLine(
        " " .. L["Battles"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetAverageBGsRemaining() or 0) ..
            " @ " .. WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(WheelchairLevel.Player:GetAverageBGXP(), 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
    GameTooltip:AddDoubleLine(
        " " .. L["Objectives"] .. ":",
        WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player:GetAverageBGObjectivesRemaining() or 0) ..
            " @ " ..
                WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Lib:round(WheelchairLevel.Player:GetAverageBGObjectiveXP(), 0)) .. " xp",
        self.labelColor.r,
        self.labelColor.g,
        self.labelColor.b,
        self.dataColor.r,
        self.dataColor.b,
        self.dataColor.b
    )
end

--- Detailed timer info.
function WheelchairLevel.Tooltip:AddTimerDetails(minimal)
    if WheelchairLevel.db.profile.timer.enabled and WheelchairLevel.Player.level < WheelchairLevel.Player:GetMaxLevel() then
        -- Gather data.
        local mode, timeToLevel, timePlayed, xpPerHour, totalXP, warning = WheelchairLevel.Player:GetTimerData()

        if mode == nil then
            mode = L["Updating..."]
            timeToLevel = 0
            if timePlayed == nil then
                timePlayed = "N/A"
            end
            xpPerHour = "N/A"
            totalXP = "N/A"
        else
            mode = mode == 1 and L["Session"] or L["Level"]
        end
        -- Display data.
        timeToLevel = WheelchairLevel.Lib:TimeFormat(timeToLevel)
        if timeToLevel == "NaN" then
            timeToLevel = "Waiting for data..."
        end
        if warning == 2 then
            GameTooltip:AddDoubleLine(
                " " .. L["Data"] .. ": ",
                mode,
                self.labelColor.r,
                self.labelColor.g,
                self.labelColor.b,
                1.0,
                0.0,
                0.0
            )
        else
            GameTooltip:AddDoubleLine(
                " " .. L["Data"] .. ": ",
                mode,
                self.labelColor.r,
                self.labelColor.g,
                self.labelColor.b,
                self.dataColor.r,
                self.dataColor.b,
                self.dataColor.b
            )
        end
        GameTooltip:AddDoubleLine(
            " " .. L["Time to level"] .. ": ",
            timeToLevel,
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )
        if not minimal then
            GameTooltip:AddLine(" ")
        end

        local fTimePlayed = WheelchairLevel.Lib:TimeFormat(timePlayed)
        if fTimePlayed == "NaN" then
            fTimePlayed = "N/A"
        end

        GameTooltip:AddDoubleLine(
            " " .. L["Time elapsed"] .. ": ",
            fTimePlayed,
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )
        GameTooltip:AddDoubleLine(
            " " .. L["Total XP"] .. ": ",
            WheelchairLevel.Lib:NumberFormat(totalXP),
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )
        GameTooltip:AddDoubleLine(
            " " .. L["XP per hour"] .. ": ",
            WheelchairLevel.Lib:NumberFormat(xpPerHour),
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )
        GameTooltip:AddDoubleLine(
            " " .. L["XP Needed"] .. ": ",
            WheelchairLevel.Lib:NumberFormat(WheelchairLevel.Player.maxXP - WheelchairLevel.Player.currentXP),
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            self.dataColor.r,
            self.dataColor.b,
            self.dataColor.b
        )

        if warning == 2 and not minimal then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["No Kills Recorded. Using Level"], 1.0, 0.0, 0.0, true)
        elseif warning == 1 and not minimal then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["No Kills Recorded. Using Old"], 1.0, 0.0, 0.0, true)
        end
    else
        GameTooltip:AddDoubleLine(
            " Mode",
            "Disabled",
            self.labelColor.r,
            self.labelColor.g,
            self.labelColor.b,
            1.0,
            0.0,
            0.0
        )
    end
end
