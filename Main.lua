local _, addonTable = ...
---
-- The main application. Contains the event callbacks that control the flow of
-- the application.
---

local L = addonTable.GetLocale()

-- Create the Main WheelchairLevel object and the main frame (used to listen to events.)
WheelchairLevel = {}
WheelchairLevel.version = "2.0.501_1"
WheelchairLevel.releaseDate = "2021-05-15T19:27:39Z"

WheelchairLevel.frame = CreateFrame("FRAME", "WheelchairLevel", UIParent)
WheelchairLevel.frame:RegisterEvent("PLAYER_LOGIN")

WheelchairLevel.timer = LibStub:GetLibrary("AceTimer-3.0")

--
-- Member variables
WheelchairLevel.playerHasXpLossRequest = false
WheelchairLevel.playerHasResurrectRequest = false
WheelchairLevel.hasLfgProposalSucceeded = false
WheelchairLevel.onUpdateTotal = 0

WheelchairLevel.questCompleteDialogOpen = false
WheelchairLevel.questCompleteDialogLastOpen = 0
---
-- Temporary variables
local targetList = {}
local regenEnabled = true

local targetUpdatePending = false -- Used if the chat message is fired before the combat log, to update the target's XP value in the targetList

---
-- ON_EVENT handler. Set in the WheelchairLevelDisplay XML file. Called for every event
-- and only used to attach the callback functions to their respective event.
function WheelchairLevel:MainOnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:OnPlayerLogin()
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        self:OnChatXPGain(select(1, ...))
    elseif event == "CHAT_MSG_OPENING" then
        self:OnChatMsgOpening(select(1, ...))
    elseif event == "PLAYER_LEVEL_UP" then
        self:OnPlayerLevelUp(select(1, ...))
    elseif event == "PLAYER_XP_UPDATE" then
        self:OnPlayerXPUpdate()
    elseif event == "UNIT_NAME_UPDATE" then
        self:OnUnitNameUpdate(select(1, ...))
    elseif event == "PLAYER_ENTERING_BATTLEGROUND" then
        self:OnPlayerEnteringBattleground()
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:OnPlayerEnteringWorld()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED" then
        self:OnAreaChanged()
    elseif event == "PLAYER_UNGHOST" then
        self:OnPlayerUnghost()
    elseif event == "CONFIRM_XP_LOSS" then
        self:OnConfirmXpLoss()
    elseif event == "RESURRECT_REQUEST" then
        self:OnResurrectRequest()
    elseif event == "PLAYER_ALIVE" then
        self:OnPlayerAlive()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        self:OnEquipmentChanged(select(1, ...), select(2, ...))
    elseif event == "TIME_PLAYED_MSG" then
        self:OnTimePlayedMsg(select(1, ...), select(2, ...))
    elseif event == "QUEST_COMPLETE" then
        self:OnQuestComplete()
    elseif event == "QUEST_FINISHED" then
        self:OnQuestFinished()
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:OnPlayerTargetChanged()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:OnCombatLogEventUnfiltered(...)
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:OnPlayerRegenEnabled()
    end
end
WheelchairLevel.frame:SetScript(
    "OnEvent",
    function(self, ...)
        WheelchairLevel:MainOnEvent(...)
    end
)

---
-- Registers events listeners and slash commands. Note, the callbacks for
-- the events are defined in the MainOnEvent function.
function WheelchairLevel:RegisterEvents(level)
    if not level then
        level = UnitLevel("player")
    end

    -- Register Events
    if level < WheelchairLevel.Player:GetMaxLevel() then
        self.frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
        self.frame:RegisterEvent("CHAT_MSG_OPENING")
        self.frame:RegisterEvent("PLAYER_LEVEL_UP")
        self.frame:RegisterEvent("PLAYER_XP_UPDATE")
        self.frame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
        self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
        self.frame:RegisterEvent("ZONE_CHANGED_INDOORS")
        self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self.frame:RegisterEvent("ZONE_CHANGED")
        self.frame:RegisterEvent("PLAYER_UNGHOST")
        self.frame:RegisterEvent("CONFIRM_XP_LOSS")
        self.frame:RegisterEvent("CANCEL_SUMMON")
        self.frame:RegisterEvent("RESURRECT_REQUEST")
        self.frame:RegisterEvent("CONFIRM_SUMMON")
        self.frame:RegisterEvent("PLAYER_ALIVE")
        self.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self.frame:RegisterEvent("TIME_PLAYED_MSG")
        self.frame:RegisterEvent("QUEST_FINISHED")
        self.frame:RegisterEvent("QUEST_COMPLETE")
        self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    end

    -- Register slash commands
    SLASH_WheelchairLevel1 = "/WheelchairLevel"
    SLASH_WheelchairLevel2 = "/wcl"
    SlashCmdList["WheelchairLevel"] = function(arg1)
        WheelchairLevel:OnSlashCommand(arg1)
    end
end

---
-- Clears all registered events from the addon.
function WheelchairLevel:UnregisterEvents()
    self.frame:UnregisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
    self.frame:UnregisterEvent("CHAT_MSG_SYSTEM")
    self.frame:UnregisterEvent("PLAYER_LEVEL_UP")
    self.frame:UnregisterEvent("PLAYER_XP_UPDATE")
    self.frame:UnregisterEvent("PLAYER_ENTERING_BATTLEGROUND")
    self.frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
    self.frame:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self.frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self.frame:UnregisterEvent("ZONE_CHANGED")
    self.frame:UnregisterEvent("PLAYER_UNGHOST")
    self.frame:UnregisterEvent("CONFIRM_XP_LOSS")
    self.frame:UnregisterEvent("CANCEL_SUMMON")
    self.frame:UnregisterEvent("RESURRECT_REQUEST")
    self.frame:UnregisterEvent("CONFIRM_SUMMON")
    self.frame:UnregisterEvent("PLAYER_ALIVE")
    self.frame:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self.frame:UnregisterEvent("TIME_PLAYED_MSG")
    self.frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
end

--- PLAYER_LOGIN callback. Initializes the config, locale and c Objects.
function WheelchairLevel:OnPlayerLogin()
    -- If the player is at max level, then there is no reason to load the addon.
    if UnitLevel("player") >= WheelchairLevel.Player:GetMaxLevel() then
        WheelchairLevel:Unload()
        return false
    end

    self.db = LibStub("AceDB-3.0"):New("WheelchairLevelDB", self.Config:GetDefaults())
    WheelchairLevel.Config:Verify()

    self:RegisterEvents()

    if not addonTable.SetLocale(WheelchairLevel.db.profile.general.displayLocale) then
        console:log(
            "Attempted to load unknown locale '" ..
                tostring(WheelchairLevel.db.profile.general.displayLocale) .. "'. Falling back on 'enUS'."
        )
        WheelchairLevel.db.profile.general.displayLocale = "enUS"
        if not addonTable.SetLocale("enUS") then
            WheelchairLevel.Messages:Print(
                "|cFFaaaaaaWheelchairLevel - |r|cFFFF5533Fatal error:|r Locale files not found. (Try re-installing the addon.)"
            )
            return
        end
    end
    addonTable.WipeLocales() -- Removing the extra locale tables. They're just a waste of memory.

    WheelchairLevel.Player:Initialize(WheelchairLevel.db.char.data.killAverage, WheelchairLevel.db.char.data.questAverage)
    WheelchairLevel.Config:Initialize()

    self.timer:ScheduleTimer(WheelchairLevel.TimePlayedTriggerCallback, 2)

    WheelchairLevel.Average:Initialize()
    WheelchairLevel.Tooltip:Initialize()
end

--- Disables the addon for this session. Basically, this hides all frames and
-- wipes the WheelchairLevel table.
function WheelchairLevel:Unload()
    for name, ref in pairs(self.AverageFrameAPI) do
        ref:Hide()
    end
    wipe(WheelchairLevel)
end

--------------------------------------------------------------------------------
-- PLAYER XP stuff
--------------------------------------------------------------------------------

---
-- Used to keep track of the player's targets while in combat. Once they die,
-- the chat and combat log events can then be used to match the targets and the
-- data stored and used to calculate the kills needed to level. - This is needed
-- because none of those messages pass along the level of a mob, but the GUIDs
-- are the same so I can record the levels here and match them in those events.
function WheelchairLevel:OnPlayerTargetChanged()
    if not regenEnabled then
        local target_guid = UnitGUID("target")
        if target_guid ~= nil then
            local target_name = UnitName("target")
            local target_level = UnitLevel("target")
            local target_classification = UnitClassification("target")
            local exists = false

            -- Look for an existing entry and updated it if it does.
            for i, data in ipairs(targetList) do
                if data.guid == target_guid then
                    exists = true
                    targetList[i].name = target_name
                    targetList[i].level = target_level
                    targetList[i].classification = target_classification
                end
            end

            -- Add the target if it doesn't exist.
            if not exists then
                table.insert(
                    targetList,
                    {
                        guid = target_guid,
                        name = target_name,
                        level = target_level,
                        classification = target_classification,
                        dead = false,
                        xp = nil
                    }
                )
            end
        end
    end
end

---
-- Look for the combat log event that tells of a NPC death.
function WheelchairLevel:OnCombatLogEventUnfiltered(...)
    local cl_event = select(2, ...)
    if cl_event ~= nil then
        if cl_event == "UNIT_DIED" then
            local npc_guid = select(8, ...)
            ---- 4.1 backwards compatibility fix but this shouldnt be needed classic api should be honoring 7+
            --if tonumber(select(4, GetBuildInfo())) < 40200 then
            --    npc_guid = select(7, ...)
            --end
            for i, data in ipairs(targetList) do
                if data.guid == npc_guid then
                    data.dead = true
                    if type(targetUpdatePending) == "number" and targetUpdatePending > 0 then
                        data.xp = targetUpdatePending
                        targetUpdatePending = nil
                        WheelchairLevel:AddMobXpRecord(
                            data.name,
                            data.level,
                            UnitLevel("player"),
                            data.xp,
                            data.classification
                        )
                    end
                end
            end
        end
    end
end

function WheelchairLevel:OnPlayerRegenDisabled()
    regenEnabled = false
    self:OnPlayerTargetChanged() -- So if a target is already targetted, it will not be overlooked.
end

--- Reset the target list. No point keeping a list of targets out of combat.
function WheelchairLevel:OnPlayerRegenEnabled()
    regenEnabled = true
    table.wipe(targetList)
end

---
-- Adds the mob to the permenant list of known NPCs and their XP value.
-- Used to calculate the Kills To Level values for the tooltip.
function WheelchairLevel:AddMobXpRecord(mobName, mobLevel, playerLevel, xp, mobClassification)
    -- Validate the mob classification. Default to normal if none is given
    if type(mobClassification) ~= "string" then
        mobClassification = "normal"
    end
    local mobClassIndex = WheelchairLevel.Lib:ConvertClassification(mobClassification)
    if mobClassIndex == nil then
        console:log(
            "AddMobXpRecord: Invalid mobClassification passed. Defaulting to 'normal'. ('" ..
                tostring(mobClassification) .. "')"
        )
        mobClassIndex = 1
    end

    -- Make sure the tables exist
    if type(WheelchairLevel.db.char.data.npcXP) ~= "table" then
        WheelchairLevel.db.char.data.npcXP = {}
    end
    if WheelchairLevel.db.char.data.npcXP[playerLevel] == nil then
        WheelchairLevel.db.char.data.npcXP[playerLevel] = {}
    end
    if WheelchairLevel.db.char.data.npcXP[playerLevel][mobLevel] == nil then
        WheelchairLevel.db.char.data.npcXP[playerLevel][mobLevel] = {}
    end
    if WheelchairLevel.db.char.data.npcXP[playerLevel][mobLevel][mobClassIndex] == nil then
        WheelchairLevel.db.char.data.npcXP[playerLevel][mobLevel][mobClassIndex] = {}
    end

    -- Add the data
    local alreadyRecorded = false
    if #WheelchairLevel.db.char.data.npcXP[playerLevel][mobLevel][mobClassIndex] > 0 then
        for i, v in ipairs(WheelchairLevel.db.char.data.npcXP[playerLevel][mobLevel][mobClassIndex]) do
            if v == xp then
                alreadyRecorded = true
            end
        end
    end

    if not alreadyRecorded then
        table.insert(WheelchairLevel.db.char.data.npcXP[playerLevel][mobLevel][mobClassIndex], xp)
    end
end

--- Fires when the player's equipment changes
-- @param slot The number of the slot that changed.
-- @param hasItem Whether or not the slot is filled.
function WheelchairLevel:OnEquipmentChanged(slot, hasItem)
    table.wipe(WheelchairLevel.Tooltip.OnShow_XpData)
end

---
-- PLAYER_LEVEL_UP callback. Displays the level up messages, updates the player,
-- and updates the average and LDB displays.
-- @param newLevel The new level of the player. Passed from the event parameters.
function WheelchairLevel:OnPlayerLevelUp(newLevel)
    console:log("New level reaced: " .. tostring(newLevel) .. " / " .. tostring(WheelchairLevel.Player:GetMaxLevel()))

    WheelchairLevel.Player.level = newLevel
    WheelchairLevel.Player.timePlayedLevel = 0
    WheelchairLevel.Player.timePlayedUpdated = time()

    if newLevel >= WheelchairLevel.Player:GetMaxLevel() then
        WheelchairLevel.Player.isActive = false
        WheelchairLevel:UnregisterEvents()
        WheelchairLevel:RegisterEvents(newLevel)
    end

    WheelchairLevel.Average:Update()
end

--- Used to handle Gathering profession XP gains. This stores the info so the
-- CHAT_MSG_COMBAT_XP_GAIN can direct the XP gain in the right direction.
--
function WheelchairLevel:OnChatMsgOpening(message)
    local regexp = string.gsub(OPEN_LOCK_SELF, "%%%d?%$?s", "(.+)")
    local action, target = strmatch(message, regexp)

    WheelchairLevel.gatheringAction = action
    WheelchairLevel.gatheringTarget = target
    WheelchairLevel.gatheringTime = GetTime()
end

--- CHAT_XP_GAIN callback. Triggered whenever a XP message is displayed in the chat
-- window, indicating that the player has gained XP (both kill, quest and BG objectives).
-- Parses the message and updates the WheelchairLevel.Player and WheelchairLevel.Display objects according
-- to the type of message received.
-- @param message The message string passed by the event, as displayed in the chat window.
function WheelchairLevel:OnChatXPGain(message)
    -- If the quest dialog was open in the last 2 seconds, assume this is a quest reward.
    local isQuest = self.questCompleteDialogOpen or (GetTime() - self.questCompleteDialogLastOpen) < 2
    local xp, mobName = WheelchairLevel.Lib:ParseChatXPMessage(message, isQuest)
    xp = tonumber(xp)
    if not xp then
        console:log("Failed to parse XP Gain message: '" .. tostring(message) .. "'")
        return false
    end

    -- Update the timer total
    if WheelchairLevel.db.profile.timer.enabled then
        -- TODO: Figure out a way to work rested kills into the timer without breaking everything!
        --local unrestedXP = WheelchairLevel.Player:GetUnrestedXP(xp)
        WheelchairLevel.db.char.data.timer.total = WheelchairLevel.db.char.data.timer.total + xp
    end

    -- See if it is a kill or a quest (no mob name means it is a quest or BG objective.)
    if mobName ~= nil then
        if WheelchairLevel.Player:IsBattlegroundInProgress() then
            console:log("Battleground Kill detected: " .. tostring(xp) .. "(" .. mobName .. ")")
            WheelchairLevel.Player:AddBattlegroundKill(xp, mobName)
        else
            local unrestedXP = WheelchairLevel.Player:AddKill(xp, mobName)

            -- Update the temporary target list.
            local found = false
            for i, data in ipairs(targetList) do
                if data.name == mobName and data.dead and data.xp == nil then
                    targetList[i].xp = unrestedXP
                    found = true
                    WheelchairLevel:AddMobXpRecord(data.name, data.level, UnitLevel("player"), data.xp, data.classification)
                end
            end
            if not found then
                targetUpdatePending = unrestedXP
            end

            if WheelchairLevel.db.profile.messages.playerFloating or WheelchairLevel.db.profile.messages.playerChat then
                local killsRequired = WheelchairLevel.Player:GetKillsRequired(unrestedXP)
                if killsRequired > 0 then
                    WheelchairLevel.Messages.Floating:PrintKill(
                        mobName,
                        ceil(killsRequired / ((WheelchairLevel.Lib:IsRafApplied() and 3) or 1))
                    )
                    WheelchairLevel.Messages.Chat:PrintKill(mobName, killsRequired)
                end
            end

            if WheelchairLevel.Player:IsDungeonInProgress() then
                console:log("Dungeon Kill detected: " .. tostring(unrestedXP) .. "(" .. mobName .. ")")
                WheelchairLevel.Player:AddDungeonKill(unrestedXP, mobName, (xp - unrestedXP))
            end
        end
    else
            -- Only register as a quest if the quest complete dialog is open.
            -- (Note, I have not tested the effects of latency on the order of the
            --  events, so there *may* be a problem in high latency situations.)
            -- a safety in case xp gets put in for other random shit into classic
            if isQuest then
                WheelchairLevel.Player:AddQuest(xp)
                if WheelchairLevel.db.profile.messages.playerFloating or WheelchairLevel.db.profile.messages.playerChat then
                    local questsRequired = WheelchairLevel.Player:GetQuestsRequired(xp)
                    if questsRequired > 0 then
                        WheelchairLevel.Messages.Floating:PrintQuest(
                            ceil(questsRequired / ((WheelchairLevel.Lib:IsRafApplied() and 3) or 1))
                        )
                        WheelchairLevel.Messages.Chat:PrintQuest(questsRequired)
                    end
                end
            end
    end
end

--- Callback for the QUEST_COMPLETE event.
-- Note that this is NOT fired when a quest is completed, but rather when the
-- player is given the last dialog to complete a quest. This event firing does
-- not mean a quest has been completed!
function WheelchairLevel:OnQuestComplete()
    self.questCompleteDialogOpen = true
end

--- Callback for the QUEST_FINISHED event.
-- This event is called when ANY quest related dialog is closed. It does NOT mean
-- a quest has been completed.
function WheelchairLevel:OnQuestFinished()
    self.questCompleteDialogOpen = false
    self.questCompleteDialogLastOpen = GetTime()
end

--- PLAYER_XP_UPDATE callback. Triggered when the player's XP changes.
-- Syncronizes the XP of the WheelchairLevel.Player object and updates the average and ldb
-- displays. Also updates the sData.player values with the current once.
function WheelchairLevel:OnPlayerXPUpdate()
    WheelchairLevel.Player:SyncData()
    WheelchairLevel.Average:Update()

    WheelchairLevel.db.char.data.killAverage = WheelchairLevel.Player:GetAverageKillXP()
    WheelchairLevel.db.char.data.questAverage = WheelchairLevel.Player:GetAverageQuestXP()
end

--------------------------------------------------------------------------------
-- BATTLEGROUND and INSTANCE stuff
--------------------------------------------------------------------------------

--- PLAYER_ENTERING_BATTLEGROUND callback.
function WheelchairLevel:OnPlayerEnteringBattleground()
    if WheelchairLevel.Player.isActive then
        WheelchairLevel.Player:BattlegroundStart(false)
    else
        console:log("Entered BG. Player counter inactive. Count cancelled.")
    end
end

--- PLAYER_LEAVING_Instance callback.
function WheelchairLevel:PlayerLeavingInstance(force)
    if force == true or (WheelchairLevel.Player:IsDungeonInProgress() and (not UnitIsDeadOrGhost("player"))) then
        local zoneName = select(1,GetInstanceInfo())
        local success = WheelchairLevel.Player:DungeonEnd(zoneName)

        if success and WheelchairLevel.Player.isActive then
            local remaining = WheelchairLevel.Player.maxXP - WheelchairLevel.Player.currentXP
            local lastTotalXP = WheelchairLevel.db.char.data.dungeonList[1].totalXP
            local dungeonsRemaining = WheelchairLevel.Player:GetKillsRequired(lastTotalXP)

            if dungeonsRemaining > 0 then
                local name = WheelchairLevel.db.char.data.dungeonList[1].name
                WheelchairLevel.Messages.Floating:PrintDungeon(dungeonsRemaining)
                WheelchairLevel.Messages.Chat:PrintDungeon(dungeonsRemaining)
                WheelchairLevel.Average:Update()
            end
        end
    else
        console:log("PlayerLeavingInstance cancelled.")
    end
end

--- PLAYER_ENTERING_WORLD callback. Triggered whenever a loading screen completes.
-- Determines whether the player has left an battleground (a loading screen is
-- only shown in a BG when leaving) and closes the WheelchairLevel.Player bg instance, printing
-- the "bgs required" message. It also checks if the player has entered or
-- left an instance and calls the appropriate functions.
function WheelchairLevel:OnPlayerEnteringWorld()
    if self.hasLfgProposalSucceeded then
        local inInstance, type = IsInInstance()
        if WheelchairLevel.Player:IsDungeonInProgress() and inInstance and type == "party" then
            self:PlayerLeavingInstance()
            WheelchairLevel.Player:DungeonStart()
        end
        self.hasLfgProposalSucceeded = false
    end
    if GetRealZoneText() ~= "" then
        -- GetRealZoneText is set to an empty string the first time this even fires,
        -- making IsInBattleground return a false negative when actually in bg.
        if WheelchairLevel.Player:IsBattlegroundInProgress() and not WheelchairLevel.Lib:IsInBattleground() then
            if WheelchairLevel.Player.isActive then
                local bgsRequired = WheelchairLevel.Player:GetQuestsRequired(WheelchairLevel.db.char.data.bgList[1].totalXP)
                WheelchairLevel.Player:BattlegroundEnd()
                WheelchairLevel.Average:Update()
                if bgsRequired > 0 then
                    WheelchairLevel.Messages.Floating:PrintBattleground(bgsRequired)
                    WheelchairLevel.Messages.Chat:PrintBattleground(bgsRequired)
                end
            end
        else
            local inInstance, type = IsInInstance()
            if not WheelchairLevel.Player:IsDungeonInProgress() and inInstance and type == "party" then
                WheelchairLevel.Player:DungeonStart()
            elseif not inInstance and WheelchairLevel.Player:IsDungeonInProgress() then
                self:PlayerLeavingInstance()
            end
        end
    end
end

--- PLAYER_UNGHOST callback. Called when the a player returns from ghost mode.
-- Determines whether the player returned to life ouside of an instance after
-- dying inside an instance. Note that when resurected by another player inside
-- the instance, after releasing, the player momentarily comes back to life
-- outside the instance, which would cause the instance to be closed.
-- To avoid that, I only close the instance if a player has asked for a spirit
-- heal and no resurection requests have been detected.
function WheelchairLevel:OnPlayerUnghost()
    if self.playerHasXpLossRequest and not self.playerHasResurrectRequest then
        if WheelchairLevel.Player:IsDungeonInProgress() then
            self:PlayerLeavingInstance(true)
        else
            console:log("Spirit heal without being inside an instance. Action cancelled.")
        end
        self.playerHasXpLossRequest = false
    end
end

--- CONFIRM_XP_LOSS callback. Triggered when a spirit healer dialog is opened.
-- Note that does NOT mean a spirit heal has been accepted, only the dialog showed.
function WheelchairLevel:OnConfirmXpLoss()
    self.playerHasXpLossRequest = true
end

--- RESURECT_REQUEST callback. Triggered when a player resurection dialog is opened.
function WheelchairLevel:OnResurrectRequest()
    self.playerHasResurrectRequest = true
end

--- PLAYER_ALIVE callback. Triggered on spirit realease, or after aceppting resurection
-- before releasing. It also fires after entering or leaving an instance.
-- (Possibly even after every load screen, but I haven't confirmed that.)
function WheelchairLevel:OnPlayerAlive()
    self.playerHasXpLossRequest = false
    self.playerHasResurrectRequest = false
end

--- callback for ZONE_CHANGED_NEW_AREA, ZONE_CHANGED_INDOORS and ZONE_CHANGED.
-- Basically fired everytime the player moves into a new area, sub-area or the
-- indoor/outdoor status changes.
-- Determines whether the zone name of the BG in progres needs to be set, and if
-- not it checks if the name of the BG matches the zone. If not the player has
-- left the BG are and the BG in progress is stopped.
function WheelchairLevel:OnAreaChanged()
    if WheelchairLevel.Player:IsBattlegroundInProgress() and WheelchairLevel.Player.isActive then
        local oldZone = WheelchairLevel.db.char.data.bgList[1].name
        local newZone = GetRealZoneText()
        if oldZone == false then
            WheelchairLevel.db.char.data.bgList[1].name = newZone
            console:log(" - BG name set. ")
        else
            if oldZone ~= newZone then
                console:log(" - BG names don't match (" .. oldZone .. " vs " .. newZone .. ").")
                local bgsRequired = WheelchairLevel.Player:GetQuestsRequired(WheelchairLevel.db.char.data.bgList[1].totalXP)
                WheelchairLevel.Player:BattlegroundEnd()
                WheelchairLevel.Average:Update()
                if bgsRequired > 0 then
                    WheelchairLevel.Messages.Floating:PrintBattleground(bgsRequired)
                    WheelchairLevel.Messages.Chat:PrintBattleground(bgsRequired)
                end
                if WheelchairLevel.Lib:IsInBattleground() then
                    console:log(" - Player switched battlegrounds. Starting new.")
                    WheelchairLevel.Player:BattlegroundStart()
                else
                    console:log(" - Player not in a battleground. Ending")
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- TIMER stuff
--------------------------------------------------------------------------------

--- Passes the time played info into the Player object.
function WheelchairLevel:OnTimePlayedMsg(total, level)
    -- Possible that the argument order gets mixed up?
    -- (See bug #7)
    if total < level then
        local tmp = level
        level = total
        total = tmp
    end

    WheelchairLevel.Player:UpdateTimePlayed(total, level)
end

--- Called to trigger an update of the time played. Causes the time to be flushed into the chat,
-- triggering the TIME_PLAYED_MSG event, from which the info can be retrieved.
function WheelchairLevel:TimePlayedTriggerCallback()
    if WheelchairLevel.Player.timePlayedTotal == nil or WheelchairLevel.Player.timePlayedLevel == nil then
        RequestTimePlayed()
    end
end

-- --------------------------------------------------------------------------------
-- -- Pet Battle
-- --------------------------------------------------------------------------------
-- function WheelchairLevel:OnPetBattleOver()
--     WheelchairLevel.petBattleOver = GetTime()
-- end

--------------------------------------------------------------------------------
-- SLASH command stuff
--------------------------------------------------------------------------------

--- Callback for the /wcl slash commands.
-- Without parametes, it simply opens the configuration dialog.
-- Various commands may exist for debuggin purposes, but none are essential to
-- the application.
function WheelchairLevel:OnSlashCommand(arg1)
    if arg1 == "clear kills" then
        WheelchairLevel.Player:ClearKillList()
        WheelchairLevel.Player.killAverage = nil
        WheelchairLevel.Messages:Print("Player kill records cleared.")
        WheelchairLevel.Average:Update()
    elseif arg1 == "clear quests" then
        WheelchairLevel.Player:ClearQuestList()
        WheelchairLevel.Player.questAverage = nil
        WheelchairLevel.Messages:Print("Player quests records cleared.")
        WheelchairLevel.Average:Update()
    elseif arg1 == "clear dungeons" then
        WheelchairLevel.Player:ClearDungeonList()
        WheelchairLevel.Messages:Print("Player dungeon records cleared.")
        WheelchairLevel.Average:Update()
    elseif arg1 == "fd" or arg1 == "ed" or arg1 == "end dungeon" then
        if WheelchairLevel.Player:IsDungeonInProgress() then
            WheelchairLevel.Player:DungeonEnd()
            WheelchairLevel.Messages:Print("Player dungeon manually finished.")
            WheelchairLevel.Average:Update()
        else
            WheelchairLevel.Messages:Print("Error: No dungeon currently in progress",{1,0,0},WheelchairLevel.Messages.printStyle.red,5)
        end
    elseif arg1 == "sd" or arg1 = "start dungeon" then
        local inInstance, type = IsInInstance()
        if WheelchairLevel.Player:IsDungeonInProgress() then
            WheelchairLevel.Messages:Print("Error: Dungeon currently in progress",{1,0,0},WheelchairLevel.Messages.printStyle.red,5)
        elseif inInstance and type == "party" then
            WheelchairLevel.Player:DungeonStart()
            WheelchairLevel.Messages:Print("Player dungeon manually started.")
            WheelchairLevel.Average:Update()
        else
            WheelchairLevel.Messages:Print("Error: Not in a party instance",{1,0,0},WheelchairLevel.Messages.printStyle.red,5)
        end

    elseif arg1 == "dlist" or arg1 == "dungeon list" then
        console:log("-- Dungeon list--")
        for index, data in ipairs(WheelchairLevel.db.char.data.dungeonList) do
            console:log("#" .. tostring(index))
            console:log("  inProgress: " .. tostring(data.inProgress))
            console:log("  name: " .. tostring(data.name))
            console:log("  level: " .. tostring(data.level))
            console:log("  totalXP: " .. tostring(data.totalXP))
            console:log("  rested: " .. tostring(data.rested))
            console:log("  killCount: " .. tostring(data.killCount))
            console:log("  killTotal: " .. tostring(data.killTotal))
        end
    elseif arg1 == "debug" then
        if type(WheelchairLevel.db.char.data.npcXP) == "table" then
            for playerLevel, playerData in pairs(WheelchairLevel.db.char.data.npcXP) do
                console:log(playerLevel .. ": ")
                for mobLevel, mobData in pairs(playerData) do
                    console:log("  " .. mobLevel .. ": ")
                    for classification, xpData in pairs(mobData) do
                        console:log("    " .. classification .. ": ")
                        for __, xp in ipairs(xpData) do
                            console:log("      " .. xp)
                        end
                    end
                end
            end
        else
            console:log("No mob data")
        end
    else
        WheelchairLevel.Config:Open("Messages")
    end
end
