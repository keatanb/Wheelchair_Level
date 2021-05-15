local _, addonTable = ...

---
-- Defines all data and functionality related to the configuration and per-char
---

local L = addonTable.GetLocale()

-- ----------------------------------------------------------------------------
-- Config GUI Initialization
-- ----------------------------------------------------------------------------
WheelchairLevel.Config = {}
WheelchairLevel.Config.frames = {}

function WheelchairLevel.Config:Initialize()
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("WheelchairLevel", WheelchairLevel.Config.GetOptions)

    StaticPopupDialogs["WheelchairLevelConfig_MessageColorsReset"] = {
        text = L["Color Reset Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            WheelchairLevel.db.profile.messages.colors = {
                playerKill = {0.72, 1, 0.71, 1},
                playerQuest = {0.5, 1, 0.7, 1},
                playerBattleground = {1, 0.5, 0.5, 1},
                playerDungeon = {1, 0.75, 0.35, 1},
                playerLevel = {0.35, 1, 0.35, 1}
            }
            WheelchairLevel.Config:Open("Messages")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }

    StaticPopupDialogs["WheelchairLevelConfig_ResetPlayerKills"] = {
        text = L["Reset Player Kill Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            WheelchairLevel.Player:ClearKills()
            WheelchairLevel.Average:Update()

        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }
    StaticPopupDialogs["WheelchairLevelConfig_ResetPlayerQuests"] = {
        text = L["Reset Player Quest Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            WheelchairLevel.Player:ClearQuests()
            WheelchairLevel.Average:Update()

        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }
    StaticPopupDialogs["WheelchairLevelConfig_ResetDungeons"] = {
        text = L["Reset Dungeon Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            WheelchairLevel.Player:ClearDungeonList()
            WheelchairLevel.Average:Update()

        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }
    StaticPopupDialogs["WheelchairLevelConfig_ResetTimer"] = {
        text = L["Reset Timer Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            WheelchairLevel.db.char.data.timer.start = GetTime()
            WheelchairLevel.db.char.data.timer.total = 0
            WheelchairLevel.Average:UpdateTimer()
            --WheelchairLevel.LDB:UpdateTimer()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }
    StaticPopupDialogs["WheelchairLevelConfig_LdbReload"] = {
        text = L["LDB Reload Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true
    }

    local head_frame_str = "WheelchairLevel"
    local A3CFG = LibStub("AceConfigDialog-3.0")
    self.frames.Information = A3CFG:AddToBlizOptions("WheelchairLevel", head_frame_str, nil, "Information")
    self.frames.General = A3CFG:AddToBlizOptions("WheelchairLevel", L["General Tab"], head_frame_str, "General")
    self.frames.Messages = A3CFG:AddToBlizOptions("WheelchairLevel", L["Messages Tab"], head_frame_str, "Messages")
    self.frames.Window = A3CFG:AddToBlizOptions("WheelchairLevel", L["Window Tab"], head_frame_str, "Window")
    self.frames.Data = A3CFG:AddToBlizOptions("WheelchairLevel", L["Data Tab"], head_frame_str, "Data")
    self.frames.Tooltip = A3CFG:AddToBlizOptions("WheelchairLevel", L["Tooltip"], head_frame_str, "Tooltip")
    self.frames.Timer = A3CFG:AddToBlizOptions("WheelchairLevel", L["Timer"], head_frame_str, "Timer")
end

function WheelchairLevel.Config:Open(frameName)
    if self.frames[frameName] then
        InterfaceOptionsFrame_OpenToCategory(self.frames[frameName])
        InterfaceOptionsFrame_OpenToCategory(self.frames[frameName])
    end
end

WheelchairLevel.Config.options = nil
function WheelchairLevel.Config:GetOptions()
    return {
        name = "WheelchairLevel",
        type = "group",
        handler = WheelchairLevel.Config,
        args = {
            Information = {
                type = "group",
                name = "General",
                args = {
                    addonDescription = {
                        order = 0,
                        type = "description",
                        name = L["MainDescription"]
                    },
                    infoHeader = {
                        order = 1,
                        type = "header",
                        name = "AddOn Information"
                    },
                    infoVersion = {
                        order = 2,
                        type = "description",
                        name = "|cFFFFAA00" ..
                            L["Version"] ..
                                ":|r |cFF00FF00" ..
                                    tostring(WheelchairLevel.version) ..
                                        "|r |cFFAAFFAA(" .. tostring(WheelchairLevel.releaseDate) .. ")"
                    },
                    infoAuthor = {
                        order = 3,
                        type = "description",
                        name = "|cFFFFAA00" .. L["Author"] .. ":|r |cFFE07B02" .. "Keatan Bauer"
                    },
                    infoWebsite = {
                        order = 5,
                        type = "description",
                        name = "|cFFFFAA00" ..
                            L["Website"] .. ":|r |cFFFFFFFF" .. "https://github.com/keatanb/Wheelchair_Level"
                    }
                }
            },
            General = {
                type = "group",
                name = "General",
                args = {
                    localeHeader = {
                        order = 0,
                        type = "header",
                        name = L["Locale Header"]
                    },
                    localeSelect = {
                        order = 1,
                        type = "select",
                        name = L["Locale Select"],
                        desc = L["Locale Select Description"],
                        style = "dropdown",
                        values = WheelchairLevel.DISPLAY_LOCALES,
                        get = "GetLocale",
                        set = "SetLocale"
                    },
                    debugHeader = {
                        order = 2,
                        type = "header",
                        name = L["Misc Header"]
                    },
                    debugEnabled = {
                        order = 3,
                        type = "toggle",
                        name = L["Show Debug Info"],
                        desc = L["Debug Info Description"],
                        get = function(info)
                            return WheelchairLevel.db.profile.general.showDebug
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.general.showDebug = value
                        end
                    }
                }
            },
            Messages = {
                type = "group",
                name = L["Messages Tab"],
                args = {
                    playerHeader = {
                        order = 0,
                        type = "header",
                        name = L["Player Messages"]
                    },
                    playerFloating = {
                        order = 1,
                        type = "toggle",
                        name = L["Show Floating"],
                        get = function(info)
                            return WheelchairLevel.db.profile.messages.playerFloating
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.messages.playerFloating = value
                        end
                    },
                    playerChat = {
                        order = 2,
                        type = "toggle",
                        name = L["Show In Chat"],
                        get = function(info)
                            return WheelchairLevel.db.profile.messages.playerChat
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.messages.playerChat = value
                        end
                    },
                    colorsHeader = {
                        order = 3,
                        type = "header",
                        name = L["Message Colors"]
                    },
                    colorKills = {
                        order = 4,
                        type = "color",
                        name = L["Player Kills"],
                        hasAlpha = true,
                        get = function(info)
                            return unpack(WheelchairLevel.db.profile.messages.colors.playerKill)
                        end,
                        set = function(info, r, g, b, a)
                            WheelchairLevel.db.profile.messages.colors.playerKill = { r, g, b, a}
                        end
                    },
                    colorQuests = {
                        order = 5,
                        type = "color",
                        name = L["Player Quests"],
                        hasAlpha = true,
                        get = function(info)
                            return unpack(WheelchairLevel.db.profile.messages.colors.playerQuest)
                        end,
                        set = function(info, r, g, b, a)
                            WheelchairLevel.db.profile.messages.colors.playerQuest = { r, g, b, a}
                        end
                    },
                    colorDungeons = {
                        order = 6,
                        type = "color",
                        name = L["Player Dungeons"],
                        hasAlpha = true,
                        get = function(info)
                            return unpack(WheelchairLevel.db.profile.messages.colors.playerDungeon)
                        end,
                        set = function(info, r, g, b, a)
                            WheelchairLevel.db.profile.messages.colors.playerDungeon = { r, g, b, a}
                        end
                    },
                    colorLevelup = {
                        order = 7,
                        type = "color",
                        name = L["Player Levelup"],
                        hasAlpha = true,
                        get = function(info)
                            return unpack(WheelchairLevel.db.profile.messages.colors.playerLevel)
                        end,
                        set = function(info, r, g, b, a)
                            WheelchairLevel.db.profile.messages.colors.playerLevel = { r, g, b, a}
                        end
                    },
                    colorResetHeader = {
                        order = 8,
                        type = "header",
                        name = ""
                    },
                    colorResetBtn = {
                        order = 9,
                        type = "execute",
                        name = L["Color Reset"],
                        func = function()
                            StaticPopup_Show("WheelchairLevelConfig_MessageColorsReset")
                        end
                    }
                }
            },
            Window = {
                type = "group",
                name = L["Window Tab"],
                args = {
                    windowSelect = {
                        order = 0,
                        type = "select",
                        style = "dropdown",
                        name = L["Active Window Header"],
                        desc = L["Active Window Description"],
                        values = WheelchairLevel.AVERAGE_WINDOWS,
                        get = "GetActiveWindow",
                        set = "SetActiveWindow"
                    },
                    windowScale = {
                        order = 1,
                        type = "range",
                        name = L["Window Size"] .. " (%)",
                        min = 0.5,
                        max = 2.0,
                        step = 0.05,
                        isPercent = true,
                        width = "full",
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.scale
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.scale = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    classicHeader = {
                        order = 2,
                        type = "header",
                        name = L["Classic Specific Options"]
                    },
                    classicShowBackdrop = {
                        order = 3,
                        type = "toggle",
                        name = L["Show Window Frame"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.backdrop
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.backdrop = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    classicShowHeader = {
                        order = 4,
                        type = "toggle",
                        name = L["Show WheelchairLevel Header"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.header
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.header = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    classicShowVerbose = {
                        order = 5,
                        type = "toggle",
                        name = L["Show Verbose Text"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.verbose
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.verbose = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    classicShowColored = {
                        order = 6,
                        type = "toggle",
                        name = L["Show Colored Text"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.colorText
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.colorText = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    behaviorHeader = {
                        order = 9,
                        type = "header",
                        name = L["Window Behavior Header"]
                    },
                    behaviorLocked = {
                        order = 10,
                        type = "toggle",
                        name = L["Lock Avarage Display"],
                        get = function(info)
                            return not WheelchairLevel.db.profile.general.allowDrag
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.general.allowDrag = not value
                        end
                    },
                    behaviorAlloWheelchairLevelick = {
                        order = 11,
                        type = "toggle",
                        name = L["Allow Average Click"],
                        get = function(info)
                            return WheelchairLevel.db.profile.general.allowSettingsClick
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.general.allowSettingsClick = value
                        end
                    },
                    behaviorShowTooltip = {
                        order = 12,
                        type = "toggle",
                        name = L["Show Tooltip"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.tooltip
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.tooltip = value
                        end
                    },
                    behaviorCombineTooltip = {
                        order = 13,
                        type = "toggle",
                        name = L["Combine Tooltip Data"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.combineTooltip
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.combineTooltip = value
                        end
                    },
                    behaviorProgressAsBars = {
                        order = 14,
                        type = "toggle",
                        name = L["Progress As Bars"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.progressAsBars
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.progressAsBars = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    dataHeader = {
                        order = 15,
                        type = "header",
                        name = L["LDB Player Data Header"]
                    },
                    dataKills = {
                        order = 16,
                        type = "toggle",
                        name = L["Kills"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.playerKills
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.playerKills = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    dataQuests = {
                        order = 17,
                        type = "toggle",
                        name = L["Player Quests"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.playerQuests
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.playerQuests = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    dataDungeons = {
                        order = 18,
                        type = "toggle",
                        name = L["Player Dungeons"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.playerDungeons
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.playerDungeons = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    dataProgress = {
                        order = 21,
                        type = "toggle",
                        name = L["Player Progress"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.playerProgress
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.playerProgress = value
                            WheelchairLevel.Average:Update()
                        end
                    },
                    dataTimer = {
                        order = 22,
                        type = "toggle",
                        name = L["Player Timer"],
                        get = function(info)
                            return WheelchairLevel.db.profile.averageDisplay.playerTimer
                        end,
                        set = function(info, value)
                            WheelchairLevel.db.profile.averageDisplay.playerTimer = value
                            WheelchairLevel.Average:Update()
                        end
                    }
                }
            },
            Data = {
                type = "group",
                name = L["Data Tab"],
                args = {
                    dataRangeHeader = {
                        order = 0,
                        type = "header",
                        name = L["Data Range Header"]
                    },
                    dataRangeDescription = {
                        order = 1,
                        type = "description",
                        name = L["Data Range Subheader"]
                    },
                    dataRangeKills = {
                        order = 2,
                        type = "range",
                        name = L["Player Kills"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function()
                            return WheelchairLevel.db.profile.averageDisplay.playerKillListLength
                        end,
                        set = function(i, v)
                            WheelchairLevel.Player:SetKillAverageLength(v)
                        end
                    },
                    dataRangeQuests = {
                        order = 3,
                        type = "range",
                        name = L["Player Quests"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function()
                            return WheelchairLevel.db.profile.averageDisplay.playerQuestListLength
                        end,
                        set = function(i, v)
                            WheelchairLevel.Player:SetQuestAverageLength(v)
                        end
                    },
                    dataRangeDungeons = {
                        order = 4,
                        type = "range",
                        name = L["Player Dungeons"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function()
                            return WheelchairLevel.db.profile.averageDisplay.playerDungeonListLength
                        end,
                        set = function(i, v)
                            WheelchairLevel.Player:SetDungeonAverageLength(v)
                        end
                    },
                    dataClearHeader = {
                        order = 5,
                        type = "header",
                        name = L["Clear Data Header"]
                    },
                    dataClearDescription = {
                        order = 6,
                        type = "description",
                        name = L["Clear Data Subheader"]
                    },
                    dataClearKills = {
                        order = 7,
                        type = "execute",
                        name = L["Reset Player Kills"],
                        func = function()
                            StaticPopup_Show("WheelchairLevelConfig_ResetPlayerKills")
                        end
                    },
                    dataClearQuests = {
                        order = 8,
                        type = "execute",
                        name = L["Reset Player Quests"],
                        func = function()
                            StaticPopup_Show("WheelchairLevelConfig_ResetPlayerQuests")
                        end
                    },
                    dataClearDungeons = {
                        order = 9,
                        type = "execute",
                        name = L["Reset Dungeons"],
                        func = function()
                            StaticPopup_Show("WheelchairLevelConfig_ResetDungeons")
                        end
                    }
                }
            },
            Tooltip = {
                type = "group",
                name = L["Tooltip"],
                args = {
                    sectionsHeader = {
                        order = 1,
                        type = "header",
                        name = L["Tooltip Sections Header"]
                    },
                    playerDetails = {
                        order = 2,
                        type = "toggle",
                        name = L["Show Player Details"],
                        get = function(i)
                            return WheelchairLevel.db.profile.ldb.tooltip.showDetails
                        end,
                        set = function(i, v)
                            WheelchairLevel.db.profile.ldb.tooltip.showDetails = v
                        end
                    },
                    playerExperience = {
                        order = 3,
                        type = "toggle",
                        name = L["Show Player Experience"],
                        get = function(i)
                            return WheelchairLevel.db.profile.ldb.tooltip.showExperience
                        end,
                        set = function(i, v)
                            WheelchairLevel.db.profile.ldb.tooltip.showExperience = v
                        end
                    },
                    dungeonInfo = {
                        order = 5,
                        type = "toggle",
                        name = L["Show Dungeon Info"],
                        get = function(i)
                            return WheelchairLevel.db.profile.ldb.tooltip.showDungeonInfo
                        end,
                        set = function(i, v)
                            WheelchairLevel.db.profile.ldb.tooltip.showDungeonInfo = v
                        end
                    },
                    timerDetails = {
                        order = 8,
                        type = "toggle",
                        name = L["Show Timer Details"],
                        get = function(i)
                            return WheelchairLevel.db.profile.ldb.tooltip.showTimerInfo
                        end,
                        set = function(i, v)
                            WheelchairLevel.db.profile.ldb.tooltip.showTimerInfo = v
                        end
                    },
                    miscHeader = {
                        order = 9,
                        type = "header",
                        name = L["Misc Header"]
                    },
                    npcTooltipData = {
                        order = 10,
                        type = "toggle",
                        name = L["Show kills needed in NPC tooltips"],
                        get = function(i)
                            return WheelchairLevel.db.profile.general.showNpcTooltipData
                        end,
                        set = function(i, v)
                            WheelchairLevel.db.profile.general.showNpcTooltipData = v
                        end
                    }
                }
            },
            Timer = {
                type = "group",
                name = L["Timer"],
                args = {
                    enableTimer = {
                        order = 0,
                        type = "toggle",
                        name = L["Enable Timer"],
                        get = function()
                            return WheelchairLevel.db.profile.timer.enabled
                        end,
                        set = "SetTimerEnabled"
                    },
                    modeHeader = {
                        order = 1,
                        type = "header",
                        name = L["Mode"]
                    },
                    modeSelect = {
                        order = 2,
                        type = "select",
                        style = "dropdown",
                        values = WheelchairLevel.TIMER_MODES,
                        name = L["Mode"],
                        desc = L["Timer mode description"],
                        get = function()
                            return WheelchairLevel.db.profile.timer.mode
                        end,
                        set = function(i, v)
                            WheelchairLevel.db.profile.timer.mode = v
                        end
                    },
                    timerReset = {
                        order = 3,
                        type = "execute",
                        name = L["Timer Reset"],
                        desc = L["Timer Reset Description"],
                        func = function()
                            StaticPopup_Show("WheelchairLevelConfig_ResetTimer")
                        end
                    },
                    timeoutHeader = {
                        order = 4,
                        type = "header",
                        name = L["Session Timeout Header"]
                    },
                    timoutRange = {
                        order = 5,
                        type = "range",
                        name = L["Session Timeout Label"],
                        desc = L["Session Timeout Description"],
                        min = 0,
                        max = 60,
                        step = 1,
                        get = function()
                            return WheelchairLevel.db.profile.timer.sessionDataTimeout
                        end,
                        set = function(i, v)
                            WheelchairLevel.db.profile.timer.sessionDataTimeout = v
                        end
                    }
                }
            }
        }
    }
end

-- ----------------------------------------------------------------------------
-- Config GUI callbacks
-- ----------------------------------------------------------------------------

function WheelchairLevel.Config:SetLocale(info, value)
    StaticPopupDialogs["WheelchairLevelConfig_LocaleReload"] = {
        text = L["Config Language Reload Prompt"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            WheelchairLevel.db.profile.general.displayLocale = value
            ReloadUI()
        end,
        timeout = 30,
        whileDead = true,
        hideOnEscape = true
    }
    StaticPopup_Show("WheelchairLevelConfig_LocaleReload")
end
function WheelchairLevel.Config:GetLocale(info)
    return WheelchairLevel.db.profile.general.displayLocale
end

function WheelchairLevel.Config:SetActiveWindow(info, value)
    WheelchairLevel.db.profile.averageDisplay.mode = value
    WheelchairLevel.Average:Update()
end
function WheelchairLevel.Config:GetActiveWindow(info)
    return WheelchairLevel.db.profile.averageDisplay.mode
end

function WheelchairLevel.Config:SetTimerEnabled(info, value)
    WheelchairLevel.db.profile.timer.enabled = value
    if WheelchairLevel.db.profile.timer.enabled then
        WheelchairLevel.Player.timerHandler =
            WheelchairLevel.timer:ScheduleRepeatingTimer(WheelchairLevel.Player.TriggerTimerUpdate, WheelchairLevel.Player.xpPerSecTimeout)
    else
        WheelchairLevel.timer:CancelTimer(WheelchairLevel.Player.timerHandler)
    end
    WheelchairLevel.Average:UpdateTimer(nil)
    --WheelchairLevel.LDB:UpdateTimer()
end
-- ----------------------------------------------------------------------------
-- Default config values.
-- ----------------------------------------------------------------------------

function WheelchairLevel.Config:GetDefaults()
    return {
        profile = {
            general = {
                allowDrag = true,
                allowSettingsClick = true,
                displayLocale = GetLocale(),
                showDebug = false,
                rafEnabled = false,
                showNpcTooltipData = true
            },
            messages = {
                playerFloating = true,
                playerChat = false,
                bgObjectives = true,
                colors = {
                    playerKill = {0.72, 1, 0.71, 1},
                    playerQuest = {0.5, 1, 0.7, 1},
                    playerBattleground = {1, 0.5, 0.5, 1},
                    playerDungeon = {1, 0.75, 0.35, 1},
                    playerLevel = {0.35, 1, 0.35, 1}
                }
            },
            averageDisplay = {
                visible = true,
                mode = 1,
                scale = 1.5,
                backdrop = true,
                verbose = true,
                colorText = true,
                header = true,
                tooltip = true,
                combineTooltip = false,
                orientation = "v",
                playerKills = true,
                playerQuests = true,
                playerDungeons = true,
                playerProgress = true,
                playerTimer = true,
                progress = true, -- Duplicate?
                progressAsBars = false,
                playerKillListLength = 10,
                playerQuestListLength = 10,
                playerPetBattleListLength = 10,
                playerBGListLength = 15,
                playerBGOListLength = 15,
                playerDungeonListLength = 15,
                guildProgress = true,
                guildProgressType = 1 -- 1 = Level, 2 = Daily, (3 = Overall... maybe later)
            },
            ldb = {
                enabled = true,
                allowTextColor = true,
                showIcon = true,
                showLabel = false,
                showText = true,
                textPattern = "default",
                text = {
                    kills = true,
                    quests = true,
                    dungeons = true,
                    bgs = true,
                    bgo = false,
                    gather = true,
                    digs = true,
                    xp = true,
                    xpnum = true,
                    xpnumFormat = true,
                    xpAsBars = false,
                    xpCountdown = false,
                    timer = true,
                    guildxp = true,
                    guilddaily = true,
                    colorValues = true,
                    verbose = true,
                    rested = true,
                    restedp = true
                },
                tooltip = {
                    showDetails = true,
                    showExperience = true,
                    showDungeonInfo = true,
                    showTimerInfo = true,
                }
            },
            timer = {
                enabled = true,
                mode = 1, -- 1 = session, 2 = level, 3 = kill range (3 is not implemented yet!)
                allowLevelFallback = true,
                -- The time the session data will remain after the UI is unloaded, in minutes.
                sessionDataTimeout = 5.0
            }
        },
        char = {
            data = {
                total = {
                    startedRecording = time(),
                    mobKills = 0,
                    dungeonKills = 0,
                    pvpKills = 0,
                    quests = 0,
                    objectives = 0
                },
                killAverage = 0,
                questAverage = 0,
                killList = {},
                questList = {},
                bgList = {},
                dungeonList = {},
                petBattleList = {},
                timer = {
                    start = nil,
                    total = nil,
                    xpPerSec = nil
                },
                gathering = {},
                digs = {},
                npcXP = {}
            },
            customPattern = nil
        }
    }
end

---
-- Verifies that the config and data values are in order.
-- This is mostly used to make sure changes to the permanent storage
-- don't cause regression bugs.
function WheelchairLevel.Config:Verify()
    -- If the old sData and sConfig tables are set, overwrite the current Ace3
    -- DB tables with them, then clear them out.
    if sData and type(sData) == "table" then
        WheelchairLevel.db.char.customPattern = sData.customPattern
        WheelchairLevel.db.char.data = sData.player
        sData = nil
    -- print("|cFF00FFAAWheelchairLevel:|r Character database saved.")
    end
    if sConfig and type(sConfig) == "table" then
        -- NOTE! Simply overwriting the db.profile table doesn't seem to
        -- permanently store the table. The profile keys must be set induvidually.
        WheelchairLevel.db.profile.general = sConfig.general
        WheelchairLevel.db.profile.messages = sConfig.messages
        WheelchairLevel.db.profile.averageDisplay = sConfig.averageDisplay
        WheelchairLevel.db.profile.ldb = sConfig.ldb
        WheelchairLevel.db.profile.timer = sConfig.timer
        sConfig = nil
    -- print("|cFF00FFAAWheelchairLevel:|r Profile settings saved.")
    end

    if
        type(WheelchairLevel.db.char.data.timer.lastUpdated) ~= "number" or
            GetTime() - WheelchairLevel.db.char.data.timer.lastUpdated > (WheelchairLevel.db.profile.timer.sessionDataTimeout * 60) or
            GetTime() - WheelchairLevel.db.char.data.timer.start <= 0
     then
        WheelchairLevel.db.char.data.timer.start = GetTime()
        WheelchairLevel.db.char.data.timer.total = 0
        WheelchairLevel.db.char.data.timer.lastUpdated = GetTime()
    end

    -- Dungeon data
    --for index, value in ipairs(WheelchairLevel.db.char.data.dungeonList) do
    for index = 1, #WheelchairLevel.db.char.data.dungeonList, 1 do
        if not WheelchairLevel.db.char.data.dungeonList[index].rested then
            WheelchairLevel.db.char.data.dungeonList[index].rested = 0
        end
    end
end
