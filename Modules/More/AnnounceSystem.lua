-- 原创模块
local E, L, V, P, G = unpack(ElvUI)
local WT = E:GetModule("WindTools")
local AS = E:NewModule('Wind_AnnounceSystem', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0');

local gsub = string.gsub
local format = string.format
local pairs = pairs

local player_name = UnitName("player")

function AS:SendMessage(text, channel)
	-- 忽视不通告讯息
	if channel == "NONE" then return end
	-- 聊天框输出
	if channel == "SELF" then print(text) return end
	-- 表情频道前置冒号以优化显示
	if channel == "EMOTE" then text = ": "..text end

	SendChatMessage(text, channel)
end

function AS:Interrupt(...)
	local config = self.db.interrupt

	-- 如果设定了仅在副本中启用，在开放世界中就直接关闭
	if config.only_instance and select(2, IsInInstance()) == "none" then return end

	-- 获取打断通告所需的信息
	local _, _, _, sourceGUID, sourceName, _, _, _, destName, _, _, sourceSpellId, _, _, targetSpellID = ...
	
	-- 格式化自定义字符串
	local function FormatMessage(custom_message)
		custom_message = gsub(custom_message, "%%player%%", sourceName)
		custom_message = gsub(custom_message, "%%target%%", destName)
		custom_message = gsub(custom_message, "%%player_spell%%", GetSpellLink(sourceSpellId))
		custom_message = gsub(custom_message, "%%target_spell%%", GetSpellLink(targetSpellID))
		return custom_message
	end

	-- 从配置中取得频道设置
	local function GetChannel(channel_db)
		if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
			return channel_db.instance
		elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
			return channel_db.raid
		elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
			return channel_db.party
		elseif channel_db.solo then
			return channel_db.solo
		end
		return "NONE"
	end

	-- 如果无法获取到打断法术及被打断法术ID时就终止，否则在某些情况下可能出错
	if not (sourceSpellId and targetSpellID) then return end

	-- 自己及宠物打断
	if sourceGUID == UnitGUID("player") or sourceGUID == UnitGUID("pet") then
		if config.player.enabled then
			self:SendMessage(FormatMessage(config.player.text), GetChannel(config.player.channel))
		end
		return
	end

	-- 他人打断
	if config.others.enabled then
		-- 为了防止在开放世界时刷屏，在团队或是队伍中才会开启。
		if (IsInRaid() and UnitInRaid(sourceGUID)) or (IsInGroup() and UnitInParty(sourceGUID)) then
			self:SendMessage(FormatMessage(config.others.text), GetChannel(self.db.others.channel))
		end
	end
end

function AS:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	-- 参数信息：https://wow.gamepedia.com/COMBAT_LOG_EVENT
	local event = select(2, CombatLogGetCurrentEventInfo())
    
    -- 打断
    if event == "SPELL_INTERRUPT" and self.db.interrupt.enabled then
		self:Interrupt(CombatLogGetCurrentEventInfo())
    end
end

function AS:Initialize()
	self.db = E.db.WindTools["More Tools"]["Announce System"]
	if not self.db.enabled then return end
	-- 监视战斗日志
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

local function InitializeCallback()
	AS:Initialize()
end

E:RegisterModule(AS:GetName(), InitializeCallback)