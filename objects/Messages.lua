local _, addonTable = ...
---
-- Contains definitions for Chat and Floating Error window message controls.
---

local L = addonTable.GetLocale()

WheelchairLevel.Messages = {
    printStyle = {
        white = {r = 1.0, g = 1.0, b = 1.0, group = 54, addToStart = false},
        gray = {r = 0.5, g = 0.5, b = 0.5, group = 53, addToStart = false},
        red = {r = 1.0, g = 0, b = 0, group = 53, addToStart = false}
    }
}

---
-- function description
function WheelchairLevel.Messages:Print(message, style, color)
    r, g, b = unpack(color or {1, 1, 1})
    if style == nil then
        style = self.printStyle.white
    end
    DEFAULT_CHAT_FRAME:AddMessage(message, r, g, b, style.group, style.addToStart)
end

---
-- function description
function WheelchairLevel.Messages:Debug(message)
    if WheelchairLevel.db.profile.general.showDebug then
        self:Print(message, self.printStyle.gray, {0.5, 0.5, 0.5})
    end
end

---
-- Controls for the floating display
-- The settings check is added here to simplify the calling code.
WheelchairLevel.Messages.Floating = {
    killStyle = {r = 0.5, g = 1.0, b = 0.7, group = 56, fade = 5},
    questStyle = {r = 0.5, g = 1.0, b = 0.7, group = 56, fade = 5},
    levelStyle = {r = 0.35, g = 1.0, b = 0.35, group = 56, fade = 6}
}

---
-- function description
function WheelchairLevel.Messages.Floating:PrintKill(mobName, mobsRequired)
    if WheelchairLevel.db.profile.messages.playerFloating then
        local message = mobsRequired .. " " .. mobName .. L["Kills Needed"]
        self:Print(message, WheelchairLevel.db.profile.messages.colors.playerKill, self.killStyle)
    end
end

---
-- function description
function WheelchairLevel.Messages.Floating:PrintQuest(questsRequired)
    if WheelchairLevel.db.profile.messages.playerFloating then
        local message = questsRequired .. L["Quests Needed"]
        self:Print(message, WheelchairLevel.db.profile.messages.colors.playerQuest, self.questStyle)
    end
end

---
-- function description
function WheelchairLevel.Messages.Floating:PrintDungeon(remaining)
    if WheelchairLevel.db.profile.messages.playerFloating then
        local message = remaining .. L["Dungeons Needed"]
        self:Print(message, WheelchairLevel.db.profile.messages.colors.playerDungeon, self.questStyle)
    end
end

---
-- function description
function WheelchairLevel.Messages.Floating:Print(text, color, style)
    local r, g, b = unpack(color or {1, 0.75, 0.35})
    if type(style) ~= "table" then
        style = self.questStyle
    end
    UIErrorsFrame:AddMessage(text, r, g, b, style.group, style.fade)
end

---
-- Controls for the chat display
---
WheelchairLevel.Messages.Chat = {
    killStyle = {r = 0.5, g = 1.0, b = 0.7, group = 56, addToStart = false},
    questStyle = {r = 0.5, g = 1.0, b = 0.7, group = 56, addToStart = false},
    levelStyle = {r = 0.35, g = 1.0, b = 0.35, group = 56, addToStart = false}
}

---
-- function description
function WheelchairLevel.Messages.Chat:PrintKill(mobName, mobsRequired)
    if WheelchairLevel.db.profile.messages.playerChat then
        local message = mobsRequired .. " " .. mobName .. L["Kills Needed"]
        WheelchairLevel.Messages:Print(message, self.killStyle, WheelchairLevel.db.profile.messages.colors.playerKill)
    end
end

---
-- function description
function WheelchairLevel.Messages.Chat:PrintQuest(questsRequired)
    if WheelchairLevel.db.profile.messages.playerChat then
        local message = questsRequired .. L["Quests Needed"]
        WheelchairLevel.Messages:Print(message, self.questStyle, WheelchairLevel.db.profile.messages.colors.playerQuest)
    end
end

---
-- function description
function WheelchairLevel.Messages.Chat:PrintDungeon(remaining)
    if WheelchairLevel.db.profile.messages.playerChat then
        local message = remaining .. L["Dungeons Needed"]
        WheelchairLevel.Messages:Print(message, self.questStyle, WheelchairLevel.db.profile.messages.colors.playerDungeon)
    end
end
