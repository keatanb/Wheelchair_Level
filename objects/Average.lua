---
-- Contains definitions for the Average Information windows
---
WheelchairLevel.Average = {
    activeAPI = "Classic",
    knownAPIs = {
        [1] = "Classic"
    }
}

---
-- Initialize the Average control methods. This basically just sets
-- which API should be used.
function WheelchairLevel.Average:Initialize()
    self.activeAPI = self.knownAPIs[WheelchairLevel.db.profile.averageDisplay.mode]
    for index, name in ipairs(self.knownAPIs) do
        WheelchairLevel.AverageFrameAPI[name]:Initialize()
    end

    self:Update()
end

---
-- Updates the active AverageFrame window.
function WheelchairLevel.Average:Update()
    if WheelchairLevel.Player.level < WheelchairLevel.Player:GetMaxLevel() then
        if self.activeAPI ~= self.knownAPIs[WheelchairLevel.db.profile.averageDisplay.mode] then
            for index, name in ipairs(self.knownAPIs) do
                WheelchairLevel.AverageFrameAPI[name]:Update()
            end
            if self.knownAPIs[WheelchairLevel.db.profile.averageDisplay.mode] ~= nil then
                self:AlignBoxes(self.activeAPI, self.knownAPIs[WheelchairLevel.db.profile.averageDisplay.mode])
                self.activeAPI = self.knownAPIs[WheelchairLevel.db.profile.averageDisplay.mode]
            end
        end
        if self.knownAPIs[WheelchairLevel.db.profile.averageDisplay.mode] ~= nil then
            if WheelchairLevel.Player.isActive then
                WheelchairLevel.AverageFrameAPI[self.activeAPI]:SetKills(WheelchairLevel.Player:GetAverageKillsRemaining() or nil)
                WheelchairLevel.AverageFrameAPI[self.activeAPI]:SetQuests(WheelchairLevel.Player:GetAverageQuestsRemaining() or nil)
                WheelchairLevel.AverageFrameAPI[self.activeAPI]:SetDungeons(
                    WheelchairLevel.Player:GetAverageDungeonsRemaining() or nil
                )
                WheelchairLevel.AverageFrameAPI[self.activeAPI]:SetProgress(
                    WheelchairLevel.Lib:round((WheelchairLevel.Player.currentXP or 0) / (WheelchairLevel.Player.maxXP or 1) * 100, 1)
                )

                WheelchairLevel.Player:UpdateTimer()
            end
            WheelchairLevel.AverageFrameAPI[self.activeAPI]:Update()
        end
    elseif WheelchairLevel.AverageFrameAPI[self.activeAPI] ~= nil then
        WheelchairLevel.AverageFrameAPI[self.activeAPI]:Hide()
    end
end

do
    local function formatSeconds(seconds)
        return ("%ds"):format(seconds)
    end
    local function formatMinutes(seconds)
        local m = math.floor(seconds / 60 + 0.5)
        return ("%dm"):format(m)
    end
    local function formatHours(seconds)
        local h = math.floor(seconds / 3600 + 0.5)
        return ("%dh"):format(h)
    end
    local function formatDays(seconds)
        local d = math.floor(seconds / 86400 + 0.5)
        return ("%dd"):format(d)
    end
    function WheelchairLevel.Average:UpdateTimer(secondsToLevel)
        if self.knownAPIs[WheelchairLevel.db.profile.averageDisplay.mode] ~= nil then
            local short, long = "N/A", "N/A"
            if type(secondsToLevel) == "number" and secondsToLevel > 0 and secondsToLevel ~= math.huge then
                if secondsToLevel < 60 then
                    short = formatSeconds(secondsToLevel)
                    long = short
                elseif secondsToLevel < 3600 then
                    short = formatMinutes(secondsToLevel)
                    long = short .. " " .. formatSeconds(math.fmod(secondsToLevel, 60))
                elseif secondsToLevel < 86400 then
                    short = formatHours(secondsToLevel)
                    long = short .. " " .. formatMinutes(math.fmod(secondsToLevel, 3600))
                else
                    short = formatDays(secondsToLevel)
                    long = short .. " " .. formatHours(math.fmod(secondsToLevel, 86400))
                end
            end
            WheelchairLevel.AverageFrameAPI[self.activeAPI]:SetTimer(short, long)
        end
    end
end

---
-- Aligns the boxes, placing the "child" on top of the "parent"
-- @param parent The box that marks where the child should be placed.
-- @param child The box that should be moved.
function WheelchairLevel.Average:AlignBoxes(parent, child)
    if parent ~= child and parent ~= nil and child ~= nil then
        local parentAPI = WheelchairLevel.AverageFrameAPI[parent]
        local childAPI = WheelchairLevel.AverageFrameAPI[child]
        childAPI:AlignTo(parentAPI)
    end
end
