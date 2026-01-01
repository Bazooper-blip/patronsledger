--[[
Patron's Ledger - Tales of Tribute Companion for PS5
Version: 1.0.0

BASED ON:
- TributeImprovedLeaderboard by @andy.s
  (Rank tracking, leaderboard UI enhancements)
- ExoYsTributesEnhancement by @ExoY94
  (Match statistics tracking structure)

Enhanced Features:
- Leaderboard enhancements (rank display, colorization)
- Match statistics tracking (wins, losses, time, victory types)
- Post-match summaries with detailed stats
- Slash command configuration (no dependencies needed)
- Fully optimized for PS5/console gamepad UI
- Extensive bug fixes and safety improvements

Original Authors: @andy.s, @ExoY94
PS5 Enhancement & Integration: @svammy

This addon combines and enhances code from the above addons.
If you are an original author and wish this to be removed, please contact me.
]]

local NAME = "PatronsLedger"
local EM = EVENT_MANAGER

--[[ ==================== ]]
--[[   CONSTANTS           ]]
--[[ ==================== ]]

local PENDING_NONE = 0
local PENDING_START = 1
local PENDING_END = 2

local OUTCOME_UNKNOWN = 0
local OUTCOME_VICTORY = 1
local OUTCOME_DEFEAT = 2

--[[ ==================== ]]
--[[   STATE VARIABLES     ]]
--[[ ==================== ]]

-- Leaderboard tracking
local leaderboardSize = 0
local rankState, scoreState = PENDING_NONE, PENDING_NONE
local rankStart, scoreStart, rankEnd, scoreEnd = 0, 0, 0, 0
local rankSignPlus = "00ff00"
local rankSignMinus = "ff1c1c"

-- Match tracking
local matchData = {}

-- Settings (configurable via slash commands)
local settings = {
	-- Leaderboard features
	enabled = true,
	showChatNotifications = true,
	colorizeLeaderboard = true,

	-- Statistics tracking
	trackStatistics = true,
	showMatchSummary = true,
}

-- SavedVariables
local savedVars = nil

--[[ ==================== ]]
--[[   MATCH TYPE NAMES    ]]
--[[ ==================== ]]

local matchTypeName = {
	[TRIBUTE_MATCH_TYPE_CASUAL] = "Casual",
	[TRIBUTE_MATCH_TYPE_CLIENT] = "NPC",
	[TRIBUTE_MATCH_TYPE_COMPETITIVE] = "Ranked",
	[TRIBUTE_MATCH_TYPE_PRIVATE] = "Friendly",
}

-- Victory type names (for potential future use)
-- local victoryTypeName = {
-- 	[TRIBUTE_VICTORY_TYPE_PRESTIGE] = "Prestige",
-- 	[TRIBUTE_VICTORY_TYPE_PATRON] = "Patron",
-- 	[TRIBUTE_VICTORY_TYPE_CONCESSION] = "Concession",
-- 	[TRIBUTE_VICTORY_TYPE_EARLY_CONCESSION] = "Early Concession",
-- 	[TRIBUTE_VICTORY_TYPE_SYSTEM_DISBAND] = "System Disband",
-- }

--[[ ==================== ]]
--[[   UTILITY FUNCTIONS   ]]
--[[ ==================== ]]

-- Return current rank, total players and percent
local function GetPlayerStats()
	local playerLeaderboardRank, totalLeaderboardPlayers = GetTributeLeaderboardRankInfo()
	local topPercent = totalLeaderboardPlayers == 0 and 100 or playerLeaderboardRank * 100 / totalLeaderboardPlayers
	return playerLeaderboardRank, totalLeaderboardPlayers, topPercent
end

-- Print colored chat message
local function PrintMessage(message)
	if settings.showChatNotifications then
		d(message)
	end
end

-- Format time in MM:SS or HH:MM:SS
local function FormatTime(milliseconds)
	local totalSeconds = math.floor(milliseconds / 1000)
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60

	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, seconds)
	else
		return string.format("%d:%02d", minutes, seconds)
	end
end

--[[ ==================== ]]
--[[   MATCH DATA MANAGER  ]]
--[[ ==================== ]]

local function InitializeMatchData()
	local function InitPlayerOpponentTable()
		return {
			[TRIBUTE_PLAYER_PERSPECTIVE_SELF] = 0,
			[TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT] = 0,
		}
	end

	local opponentName, opponentType = GetTributePlayerInfo(TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT)

	matchData = {
		matchType = GetTributeMatchType(),
		opponentName = opponentName,
		opponentType = opponentType,
		outcome = OUTCOME_UNKNOWN,
		matchStart = GetGameTimeMilliseconds(),
		matchDuration = 0,
		turns = InitPlayerOpponentTable(),
	}
end

local function IsMatchDataInitialized()
	return not ZO_IsTableEmpty(matchData)
end

local function ClearMatchData()
	matchData = {}
end

-- Removed unused function IsPlayerTurn()

--[[ ==================== ]]
--[[   STATISTICS MANAGER  ]]
--[[ ==================== ]]

local function CreateCharStatistics(charId)
	local function VictoryDefeatStatsTableStructure()
		local tableStructure = {}
		for i = 1, 4 do
			tableStructure[i] = {}
			for j = 0, 5 do
				tableStructure[i][j] = 0
			end
		end
		return tableStructure
	end

	savedVars.statistics.character[charId] = {
		name = GetUnitName("player"),
		server = GetWorldName(),
		games = {
			[TRIBUTE_MATCH_TYPE_CASUAL] = {time = 0, played = 0, won = 0},
			[TRIBUTE_MATCH_TYPE_CLIENT] = {time = 0, played = 0, won = 0},
			[TRIBUTE_MATCH_TYPE_COMPETITIVE] = {time = 0, played = 0, won = 0},
			[TRIBUTE_MATCH_TYPE_PRIVATE] = {time = 0, played = 0, won = 0},
		},
		victory = VictoryDefeatStatsTableStructure(),
		defeat = VictoryDefeatStatsTableStructure(),
	}
end

local function PostMatchProcess()
	if not settings.trackStatistics then return end
	if not IsMatchDataInitialized() then return end

	local victoryPerspective, victoryType = GetTributeResultsWinnerInfo()
	local victory = victoryPerspective == TRIBUTE_PLAYER_PERSPECTIVE_SELF

	matchData.outcome = victory and OUTCOME_VICTORY or OUTCOME_DEFEAT
	matchData.matchDuration = GetGameTimeMilliseconds() - matchData.matchStart

	local charId = GetCurrentCharacterId()
	if not savedVars.statistics.character[charId] then
		CreateCharStatistics(charId)
	end

	-- Record match data (with safety checks)
	local store = savedVars.statistics.character[charId]
	local matchTypeData = store.games[matchData.matchType]

	if not matchTypeData then
		-- Fallback: create entry if somehow missing
		matchTypeData = {time = 0, played = 0, won = 0}
		store.games[matchData.matchType] = matchTypeData
	end

	matchTypeData.played = matchTypeData.played + 1
	if victory then
		matchTypeData.won = matchTypeData.won + 1
	end
	matchTypeData.time = matchTypeData.time + matchData.matchDuration

	-- Record victory/defeat type (with validation)
	if victory then
		if not store.victory[matchData.matchType] then
			store.victory[matchData.matchType] = {}
		end
		store.victory[matchData.matchType][victoryType] = (store.victory[matchData.matchType][victoryType] or 0) + 1
	else
		if not store.defeat[matchData.matchType] then
			store.defeat[matchData.matchType] = {}
		end
		store.defeat[matchData.matchType][victoryType] = (store.defeat[matchData.matchType][victoryType] or 0) + 1
	end
end

local function PrintMatchSummary()
	if not settings.showMatchSummary then return end
	if not IsMatchDataInitialized() then return end

	-- Ensure we have a valid outcome set
	if not matchData.outcome or matchData.outcome == OUTCOME_UNKNOWN then return end

	-- Validate turn data exists
	if not matchData.turns then return end

	local playerTurns = matchData.turns[TRIBUTE_PLAYER_PERSPECTIVE_SELF] or 0
	local opponentTurns = matchData.turns[TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT] or 0
	local totalTime = matchData.matchDuration or 0

	local outcome = matchData.outcome == OUTCOME_VICTORY and "|c00ff00Victory|r" or "|cff1c1cDefeat|r"
	local matchType = matchTypeName[matchData.matchType] or "Unknown"

	PrintMessage(string.format("|cFFFF00[ToT Match Summary]|r %s - %s", outcome, matchType))
	PrintMessage(string.format("  Duration: %s | Your Turns: %d | Opponent Turns: %d",
		FormatTime(totalTime), playerTurns, opponentTurns))

	if matchData.opponentName and matchData.opponentName ~= "" then
		PrintMessage(string.format("  Opponent: %s", matchData.opponentName))
	end
end

--[[ ==================== ]]
--[[   RANK TRACKING       ]]
--[[ ==================== ]]

local function PrintScore()
	if not settings.enabled then return end

	if rankEnd > 0 then
		local rankChange = rankStart - rankEnd
		local scoreChange = scoreEnd - scoreStart
		local topPercent = leaderboardSize == 0 and 100 or rankEnd * 100 / leaderboardSize

		local rankColor = rankChange < 0 and rankSignMinus or rankSignPlus
		local scoreColor = scoreChange < 0 and rankSignMinus or rankSignPlus

		if rankStart > 0 then
			PrintMessage(string.format("[ToT Ranked] Rank: |cffffff%d/%d|r (|c%s%+d|r). Score: |cffffff%d|r (|c%s%+d|r). Top |cffffff%.1f%%|r",
				rankEnd, leaderboardSize, rankColor, rankChange, scoreEnd, scoreColor, scoreChange, topPercent))
		else
			PrintMessage(string.format("|c00ff00[ToT Ranked] Rank gained!|r Rank: |cffffff%d/%d|r. Score: |cffffff%d|r (|c%s%+d|r). Top |cffffff%.1f%%|r",
				rankEnd, leaderboardSize, scoreEnd, scoreColor, scoreChange, topPercent))
		end
	else
		if rankStart > 0 then
			PrintMessage(string.format("|cFF0000[ToT Ranked] Rank lost!|r Current score: |cffffff%d|r", scoreEnd))
		else
			PrintMessage(string.format("[ToT Ranked] Unranked. Current score: |cffffff%d|r", scoreEnd))
		end
	end
end

local function UpdateRank(type, skipRequest)
	if skipRequest or RequestTributeLeaderboardRank() == LEADERBOARD_DATA_READY then
		local rank, size = GetTributeLeaderboardRankInfo()
		-- Validate that we got valid data
		if rank and size then
			if type == PENDING_START then
				rankStart, leaderboardSize = rank, size
			elseif type == PENDING_END then
				rankEnd, leaderboardSize = rank, size
			end
			if type == PENDING_END and scoreState == PENDING_NONE then
				PrintScore()
			end
			rankState = PENDING_NONE
			return true
		end
	end
	rankState = type
	return false
end

local function UpdateScore(type, skipRequest)
	if skipRequest or QueryTributeLeaderboardData() == LEADERBOARD_DATA_READY then
		local _, score = GetTributeLeaderboardLocalPlayerInfo(TRIBUTE_LEADERBOARD_TYPE_RANKED)
		-- Validate that we got valid score data
		if score then
			if type == PENDING_START then
				scoreStart = score
			elseif type == PENDING_END then
				scoreEnd = score
			end
		end

		if RequestTributeLeaderboardRank() == LEADERBOARD_DATA_READY then
			local rank, size = GetTributeLeaderboardRankInfo()
			if rank and size then
				if type == PENDING_START then
					rankStart, leaderboardSize = rank, size
				elseif type == PENDING_END then
					rankEnd, leaderboardSize = rank, size
				end
			end
		end

		if type == PENDING_END and rankState == PENDING_NONE then
			PrintScore()
		end
		scoreState = PENDING_NONE
		return true
	else
		scoreState = type
		return false
	end
end

local function UpdateData(type)
	rankState = type
	scoreState = type
	local rank = UpdateRank(type)
	local score = UpdateScore(type)
	return rank and score
end

local function GameStart()
	UpdateData(PENDING_START)
end

local function GameOver()
	UpdateData(PENDING_END)
end

--[[ ==================== ]]
--[[   TURN TRACKING       ]]
--[[ ==================== ]]

local function OnPlayerTurnStart(_, isPlayer)
	if not IsMatchDataInitialized() then return end
	if not matchData.turns then return end

	local perspective = isPlayer and TRIBUTE_PLAYER_PERSPECTIVE_SELF or TRIBUTE_PLAYER_PERSPECTIVE_OPPONENT
	if matchData.turns[perspective] then
		matchData.turns[perspective] = matchData.turns[perspective] + 1
	end
end

--[[ ==================== ]]
--[[   EVENT HANDLERS      ]]
--[[ ==================== ]]

local function OnGameFlowStateChange(_, flowState)
	if flowState == TRIBUTE_GAME_FLOW_STATE_INTRO then
		InitializeMatchData()

		-- Only track rank for competitive (ranked) matches
		if GetTributeMatchType() == TRIBUTE_MATCH_TYPE_COMPETITIVE then
			GameStart()
		end

	elseif flowState == TRIBUTE_GAME_FLOW_STATE_GAME_OVER then
		-- Only track rank for competitive (ranked) matches
		if GetTributeMatchType() == TRIBUTE_MATCH_TYPE_COMPETITIVE then
			-- GameOver will trigger async rank updates, so we need to wait for them
			-- before processing match data
			GameOver()
		end

		-- Wait for rank data to be received (if ranked) before processing
		-- The EVENT_TRIBUTE_LEADERBOARD_RANK_RECEIVED and
		-- EVENT_TRIBUTE_LEADERBOARD_DATA_RECEIVED handlers will complete the updates
		-- For non-ranked matches, this delay just ensures clean processing
		zo_callLater(function()
			PostMatchProcess()
			PrintMatchSummary()
			-- Wait a bit more before clearing to ensure all processing is done
			zo_callLater(function()
				ClearMatchData()
			end, 100)
		end, 500)

	elseif flowState == TRIBUTE_GAME_FLOW_STATE_INACTIVE then
		ClearMatchData()
	end
end

--[[ ==================== ]]
--[[   UI ENHANCEMENTS     ]]
--[[ ==================== ]]

local function SetupUIEnhancements()
	-- Show total leaderboard size in activity finder
	ZO_PostHook(ZO_ActivityFinderTemplate_Shared, "RefreshTributeSeasonData", function(self)
		if self.leaderboardRankLabel and GetTributePlayerCampaignRank() == TRIBUTE_TIER_PLATINUM then
			local playerLeaderboardRank, totalLeaderboardPlayers, topPercent = GetPlayerStats()
			local formattedLeaderboardRank = zo_strformat(SI_TRIBUTE_FINDER_LEADERBOARD_RANK_CONTENT_PERCENT,
				zo_strformat("<<1>>/<<2>>", playerLeaderboardRank, totalLeaderboardPlayers), topPercent)
			local colorizedFormattedLeaderboardRank = ZO_SELECTED_TEXT:Colorize(formattedLeaderboardRank)
			self.leaderboardRankLabel:SetText(zo_strformat(SI_TRIBUTE_FINDER_LEADERBOARD_RANK_LABEL, colorizedFormattedLeaderboardRank))
		end
	end)

	-- Keyboard leaderboard header
	if ZO_TributeLeaderboardsManager_Keyboard then
		ZO_TributeLeaderboardsManager_Keyboard.RefreshHeaderPlayerInfo = function(self)
			local playerLeaderboardRank, totalLeaderboardPlayers, topPercent = GetPlayerStats()

			local displayedScore = self.currentScoreData or GetString(SI_LEADERBOARDS_NO_CURRENT_SCORE)
			if self.currentScoreData and topPercent <= 10 and settings.colorizeLeaderboard then
				displayedScore = string.format("|c%s%s|r", topPercent <= 2 and "eeca2a" or "2dc50e", self.currentScoreData)
			end
			self.currentScoreLabel:SetText(zo_strformat(SI_LEADERBOARDS_CURRENT_SCORE, displayedScore))

			local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)
			local displayedRank = playerLeaderboardRank > 0 and zo_strformat(SI_TRIBUTE_FINDER_LEADERBOARD_RANK_CONTENT_PERCENT,
				zo_strformat("<<1>>/<<2>>", playerLeaderboardRank, totalLeaderboardPlayers), topPercent) or GetString(SI_LEADERBOARDS_NOT_RANKED)
			self.currentRankLabel:SetText(zo_strformat(SI_LEADERBOARDS_CURRENT_RANK, rankingTypeText, displayedRank))
		end
	end

	-- Gamepad leaderboard header
	if ZO_TributeLeaderboardsManager_Gamepad then
		ZO_TributeLeaderboardsManager_Gamepad.RefreshHeaderPlayerInfo = function(self)
			local headerData = GAMEPAD_LEADERBOARD_LIST:GetContentHeaderData()
			headerData.data1HeaderText = GetString(SI_GAMEPAD_LEADERBOARDS_CURRENT_SCORE_LABEL)

			local playerLeaderboardRank, totalLeaderboardPlayers, topPercent = GetPlayerStats()
			if self.currentScoreData then
				headerData.data1Text = (topPercent <= 10 and settings.colorizeLeaderboard) and
					string.format("|c%s%s|r", topPercent <= 2 and "eeca2a" or "2dc50e", self.currentScoreData) or self.currentScoreData
			else
				headerData.data1Text = GetString(SI_LEADERBOARDS_NO_SCORE_RECORDED)
			end

			local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)
			headerData.data2HeaderText = zo_strformat(SI_GAMEPAD_LEADERBOARDS_CURRENT_RANK_LABEL, rankingTypeText)
			headerData.data2Text = playerLeaderboardRank > 0 and zo_strformat(SI_TRIBUTE_FINDER_LEADERBOARD_RANK_CONTENT_PERCENT,
				zo_strformat("<<1>>/<<2>>", playerLeaderboardRank, totalLeaderboardPlayers), topPercent) or GetString(SI_LEADERBOARDS_NOT_RANKED)
		end
	end

	-- Colorize points in the ToT leaderboard rows
	local function SetupLeaderboardPlayerEntry(self, control, data)
		if not settings.colorizeLeaderboard then
			control.pointsLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
			return
		end

		-- Safety: Check if GAMEPAD_LEADERBOARDS exists
		local leaderboardData = nil
		if self.GetSelectedLeaderboardData then
			leaderboardData = self:GetSelectedLeaderboardData()
		elseif GAMEPAD_LEADERBOARDS then
			leaderboardData = GAMEPAD_LEADERBOARDS:GetSelectedLeaderboardData()
		end

		if not leaderboardData then
			control.pointsLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
			return
		end
		if leaderboardData.leaderboardRankType == LEADERBOARD_TYPE_TRIBUTE and data.rank > 0 then
			local _, totalLeaderboardPlayers = GetTributeLeaderboardRankInfo()
			local topPercent = totalLeaderboardPlayers == 0 and 100 or data.rank * 100 / totalLeaderboardPlayers
			if topPercent <= 2 then
				control.pointsLabel:SetColor(0.93, 0.79, 0.17)
			elseif topPercent <= 10 then
				control.pointsLabel:SetColor(0.18, 0.77, 0.05)
			else
				control.pointsLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
			end
		else
			control.pointsLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
		end
	end

	if LEADERBOARDS then
		ZO_PostHook(LEADERBOARDS, "SetupLeaderboardPlayerEntry", SetupLeaderboardPlayerEntry)
	end
	if GAMEPAD_LEADERBOARD_LIST then
		ZO_PostHook(GAMEPAD_LEADERBOARD_LIST, "SetupLeaderboardPlayerEntry", SetupLeaderboardPlayerEntry)
	end

	-- Russian language timer adjustment (keyboard only, may not exist on PS5)
	if GetCVar("Language.2") == "ru" then
		if ZO_TributeLeaderboardsInformationArea_KeyboardTimer and ZO_TributeLeaderboardsInformationArea_Keyboard then
			ZO_TributeLeaderboardsInformationArea_KeyboardTimer:ClearAnchors()
			ZO_TributeLeaderboardsInformationArea_KeyboardTimer:SetAnchor(TOPRIGHT, ZO_TributeLeaderboardsInformationArea_Keyboard, TOPRIGHT)
		end
	end
end

--[[ ==================== ]]
--[[   STATISTICS COMMANDS ]]
--[[ ==================== ]]

local function PrintStatistics(matchType)
	local charId = GetCurrentCharacterId()
	if not savedVars.statistics.character[charId] then
		PrintMessage("|cff1c1c[ToT Stats]|r No statistics recorded yet")
		return
	end

	local stats = savedVars.statistics.character[charId].games

	if matchType then
		local s = stats[matchType]
		if not s then
			PrintMessage(string.format("|cff1c1c[ToT Stats]|r No statistics for %s matches", matchTypeName[matchType] or "Unknown"))
			return
		end

		local winRate = s.played > 0 and (s.won / s.played * 100) or 0
		local avgTime = s.played > 0 and (s.time / s.played) or 0

		PrintMessage(string.format("|c00ff00[ToT Stats]|r %s - Played: %d | Won: %d | Win Rate: %.1f%%",
			matchTypeName[matchType], s.played, s.won, winRate))
		PrintMessage(string.format("  Total Time: %s | Avg Time: %s",
			FormatTime(s.time), FormatTime(avgTime)))
	else
		PrintMessage("|c00ff00[ToT Stats]|r Overall Statistics:")
		for mt, name in pairs(matchTypeName) do
			local s = stats[mt]
			if s.played > 0 then
				local winRate = (s.won / s.played * 100)
				PrintMessage(string.format("  %s: %d played, %d won (%.1f%%)",
					name, s.played, s.won, winRate))
			end
		end
	end
end

--[[ ==================== ]]
--[[   SLASH COMMANDS      ]]
--[[ ==================== ]]

local function SaveSettings()
	savedVars.enabled = settings.enabled
	savedVars.showChatNotifications = settings.showChatNotifications
	savedVars.colorizeLeaderboard = settings.colorizeLeaderboard
	savedVars.trackStatistics = settings.trackStatistics
	savedVars.showMatchSummary = settings.showMatchSummary
end

local function RegisterSlashCommands()
	SLASH_COMMANDS["/totlb"] = function(args)
		args = args:lower()

		if args == "" or args == "help" then
			d("|c00ff00[Patron's Ledger]|r Available commands:")
			d("  |cFFFF00Basic:|r")
			d("    /totlb on/off - Enable/disable addon")
			d("    /totlb status - Show current settings")
			d("    /totlb stats - Show overall statistics")
			d("    /totlb stats <type> - Show stats for: casual, ranked, npc, friendly")
			d("  |cFFFF00Display:|r")
			d("    /totlb chat on/off - Toggle chat notifications")
			d("    /totlb color on/off - Toggle leaderboard colors")
			d("    /totlb summary on/off - Toggle match summary")
			d("  |cFFFF00Tracking:|r")
			d("    /totlb track stats on/off - Track match statistics")

		elseif args == "on" then
			settings.enabled = true
			SaveSettings()
			d("|c00ff00[Patron's Ledger]|r Addon enabled")

		elseif args == "off" then
			settings.enabled = false
			SaveSettings()
			d("|cff1c1c[Patron's Ledger]|r Addon disabled")

		elseif args == "chat on" then
			settings.showChatNotifications = true
			SaveSettings()
			d("|c00ff00[Patron's Ledger]|r Chat notifications enabled")

		elseif args == "chat off" then
			settings.showChatNotifications = false
			SaveSettings()
			d("|cff1c1c[Patron's Ledger]|r Chat notifications disabled")

		elseif args == "color on" then
			settings.colorizeLeaderboard = true
			SaveSettings()
			d("|c00ff00[Patron's Ledger]|r Leaderboard colorization enabled")

		elseif args == "color off" then
			settings.colorizeLeaderboard = false
			SaveSettings()
			d("|cff1c1c[Patron's Ledger]|r Leaderboard colorization disabled")

		elseif args == "summary on" then
			settings.showMatchSummary = true
			SaveSettings()
			d("|c00ff00[Patron's Ledger]|r Match summary enabled")

		elseif args == "summary off" then
			settings.showMatchSummary = false
			SaveSettings()
			d("|cff1c1c[Patron's Ledger]|r Match summary disabled")

		elseif args == "track stats on" then
			settings.trackStatistics = true
			SaveSettings()
			d("|c00ff00[Patron's Ledger]|r Statistics tracking enabled")

		elseif args == "track stats off" then
			settings.trackStatistics = false
			SaveSettings()
			d("|cff1c1c[Patron's Ledger]|r Statistics tracking disabled")

		elseif args == "status" then
			d("|c00ff00[Patron's Ledger]|r Current settings:")
			d("  Addon: " .. (settings.enabled and "|c00ff00Enabled|r" or "|cff1c1cDisabled|r"))
			d("  Chat notifications: " .. (settings.showChatNotifications and "|c00ff00On|r" or "|cff1c1cOff|r"))
			d("  Leaderboard colors: " .. (settings.colorizeLeaderboard and "|c00ff00On|r" or "|cff1c1cOff|r"))
			d("  Match summary: " .. (settings.showMatchSummary and "|c00ff00On|r" or "|cff1c1cOff|r"))
			d("  Track statistics: " .. (settings.trackStatistics and "|c00ff00On|r" or "|cff1c1cOff|r"))

		elseif args == "stats" then
			PrintStatistics()

		elseif args == "stats casual" then
			PrintStatistics(TRIBUTE_MATCH_TYPE_CASUAL)
		elseif args == "stats ranked" then
			PrintStatistics(TRIBUTE_MATCH_TYPE_COMPETITIVE)
		elseif args == "stats npc" then
			PrintStatistics(TRIBUTE_MATCH_TYPE_CLIENT)
		elseif args == "stats friendly" then
			PrintStatistics(TRIBUTE_MATCH_TYPE_PRIVATE)

		else
			d("|cff1c1c[Patron's Ledger]|r Unknown command. Type |cffffff/totlb help|r for available commands")
		end
	end

	d("|c00ff00[Patron's Ledger]|r Tales of Tribute companion loaded. Type |cffffff/totlb help|r for commands")
end

--[[ ==================== ]]
--[[   INITIALIZATION      ]]
--[[ ==================== ]]

local function Initialize()
	-- Load saved variables
	savedVars = ZO_SavedVars:NewAccountWide("PatronsLedgerSV", 1, nil, {
		enabled = true,
		showChatNotifications = true,
		colorizeLeaderboard = true,
		trackStatistics = true,
		showMatchSummary = true,
		statistics = {
			character = {}
		},
	})

	-- Apply saved settings
	settings.enabled = savedVars.enabled
	settings.showChatNotifications = savedVars.showChatNotifications
	settings.colorizeLeaderboard = savedVars.colorizeLeaderboard
	settings.trackStatistics = savedVars.trackStatistics
	settings.showMatchSummary = savedVars.showMatchSummary

	-- Register event handlers
	EM:RegisterForEvent(NAME, EVENT_TRIBUTE_GAME_FLOW_STATE_CHANGE, OnGameFlowStateChange)
	EM:RegisterForEvent(NAME, EVENT_TRIBUTE_PLAYER_TURN_STARTED, OnPlayerTurnStart)

	EM:RegisterForEvent(NAME, EVENT_TRIBUTE_LEADERBOARD_RANK_RECEIVED, function()
		if rankState == PENDING_START or rankState == PENDING_END then
			UpdateRank(rankState, true)
		end
	end)

	EM:RegisterForEvent(NAME, EVENT_TRIBUTE_LEADERBOARD_DATA_RECEIVED, function()
		if scoreState == PENDING_START or scoreState == PENDING_END then
			UpdateScore(scoreState, true)
		end
	end)

	-- Setup UI enhancements
	SetupUIEnhancements()

	-- Register slash commands
	RegisterSlashCommands()
end

-- Load the addon
EM:RegisterForEvent(NAME, EVENT_ADD_ON_LOADED, function(_, name)
	if name == NAME then
		Initialize()
		EM:UnregisterForEvent(NAME, EVENT_ADD_ON_LOADED)
	end
end)
