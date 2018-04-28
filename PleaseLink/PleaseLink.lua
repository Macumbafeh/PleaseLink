--[[
	TODO:
		* Eternal Earthstorm meta gem - handle "block" when searching for gems
--]]

----------------------------------------------------------------------------------------------------
-- variables / constants
----------------------------------------------------------------------------------------------------
-- saved settinge - defaults set up during ADDON_LOADED event
PleaseLinkSave = nil

-- cancel a specific search if there's more than this many matches
local SEARCH_MATCH_LIMIT = 8

-- events used for each chat group type - for registering events and for use as a list of groups
local chatGroupEvents = {
	["channel"] = {"CHAT_MSG_CHANNEL"},
	["group"]   = {"CHAT_MSG_PARTY", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER"},
	["guild"]   = {"CHAT_MSG_GUILD", "CHAT_MSG_OFFICER"},
	["say"]     = {"CHAT_MSG_SAY"},
	["whisper"] = {"CHAT_MSG_WHISPER"},
	["yell"]    = {"CHAT_MSG_YELL"},
}

-- which group each chat event belongs to - for looking it up easily when an event happens
local chatEventGroup = {
	["CHAT_MSG_CHANNEL"]             = "channel",
	["CHAT_MSG_PARTY"]               = "group",
	["CHAT_MSG_RAID"]                = "group",
	["CHAT_MSG_RAID_LEADER"]         = "group",
	["CHAT_MSG_BATTLEGROUND"]        = "group",
	["CHAT_MSG_BATTLEGROUND_LEADER"] = "group",
	["CHAT_MSG_GUILD"]               = "guild",
	["CHAT_MSG_OFFICER"]             = "guild",
	["CHAT_MSG_SAY"]                 = "say",
	["CHAT_MSG_WHISPER"]             = "whisper",
	["CHAT_MSG_YELL"]                = "yell",
}

-- possible settings for each chat group.
local ChatReaction = {OFF=1, SHORT=2, LONG=3, WHISPER=4, SHOW=5}

-- anonymous frame for handling events
local pleaseLinkFrame = CreateFrame("frame")

-- table storing all the lists and keyword data - should be built before this file is read
local data = PleaseLinkData

-- ignore messages containing these phrases - they're probably wanting a link of a quest or like
-- "link some staff from karazhan" or "link vashj's healing ring." These are only checked if a link
-- request is found, not every message.
local blackListText = {
	-- Miscellaneous
	"quest",
	"%f[%w]bo[pe]%f[%W]", -- bop/boe

	-- Creatures
	-- T6: BT
	"%f[%w]naj",   -- High Warlord Naj'entus
	"supremus",
	"akama",
	"gurtogg",     -- Gurtogg Bloodboil
	"bloodboil",
	"%f[%w]ros",   -- Reliquary of Souls: Essence of Suffering/Desire/Anger
	"essence",
	"teron",       -- Teron Gorefiend
	"gorefiend",
	"mother",      -- Mother Shahraz
	"shahraz",
	"council",     -- Illidari Council
	"illidan",
	-- T6: Hyjal
	"winterchill",
	"anetheron",
	"kazrogal",
	"azgalor",
	"%f[%w]archi", -- Archimonde
	-- T6.5: Sunwell
	"kalecgos",
	"brutallus",
	"twins",       -- Eredar twins
	"muru",
	"%f[%w]kilj",  -- Kil'Jaeden
	-- Zul'Aman
	"nalorakk",
	"bear god",
	"bear boss",
	"akilzon",
	"eagle god",
	"eagle boss",
	"janalai",
	"dragonhawk",
	"halazzi",
	"lynx",
	"hex lord",    -- Hex Lord Malacrass
	"malacrass",
	"%f[%w]zul",   -- Zul'jin
	-- T5: SSC
	"hydross",
	"lurker",
	"%f[%w]leo",
	"%f[%w]moro",
	"vashj",
	-- T5: The Eye
	"alar",
	"reaver",
	"solarian",
	"kael",
	-- T4: Karazhan
	"attumen",     -- Attumen the Huntsman
	"huntsman",
	"moroes",
	"maiden",      -- Maiden of Virtue
	"opera",
	"romulo",
	"wizard of oz",
	"%f[%w]oz%f[%W]",
	"riding hood",
	"nightbane",
	"curator",
	"terestian",   -- Terestian Illhoof
	"illhoof",
	"%f[%w]aran",  -- Shade of Aran
	"netherspite",
	"chess",       -- Chess Event
	"prince",      -- Prince Malchezaar
	"malch",
	-- Vanilla
	"hakkar",
	"ragnaros",
	"onyxia",
	"cthun",
	"sapphiron",
	"%f[%w]kel",   -- Kel'Thuzad
	-- Instances
	"anzu",
	"murmur",
	"quag",        -- Quagmirran
	"black stalk", -- Black Stalker
	-- Others
	"boss",
	"kaz[z]?ak",   -- Doom Lord Kazzak
	"doomwalker",
	"azuregos",
	"nightmare",   -- Dragons of Nightmare
	"lethon",
	"emeriss",
	"taerar",
	"ysondre",
	"terokk",

	-- Locations
	"%f[%w]swp%f[%W]",       -- Sunwell Plateau
	"sunwell",
	"%f[%w]bt%f[%W]",        -- Black Temple
	"temple",
	"%f[%w]hs%f[%W]",        -- Hyjal Summit
	"hyjal",
	"%f[%w]za%f[%W]",        -- Zul'Aman
	"ssc",                   -- Sepentshrine Cavern
	"serpent%s?shrine",
	"%f[%w]tk%f[%W]",        -- Tempest Keep: The Eye
	"tempest",
	"the eye",
	"gruul",                 -- Gruul's Lair
	"magther",               -- Magtheridon's Lair
	"kara",                  -- Karazhan
	"%f[%w]ac%f[%W]",        -- Auchenai Crypts
	"crypt",
	"%f[%w]mt%f[%W]",        -- Mana-Tombs
	"mana%s?tomb",
	"%f[%w]sh%f[%W]",        -- Sethekk Halls
	"%f[%w]hall",
	"%f[%w]sl%f[%W]",        -- Shadow Labrinth
	"labrinth",
	"%f[%w]labs",
	"%f[%w]ohf%f[%W]",       -- Old Hillsbrad Foothills
	"hills",
	"%f[%w]bm%f[%W]",        -- Black Morass
	"morass",
	"%f[%w]sp%f[%W]",        -- Slave Pens
	"slave",
	"%f[%w]sv%f[%W]",        -- Steamvault
	"steam",
	"%f[%w]ub%f[%W]",        -- Underbog
	"underbog",
	"%f[%w]rp%f[%W]",        -- Hellfire Ramparts
	"%f[%w]rampart",
	"%f[%w]ramps",
	"%f[%w]bf%f[%W]",        -- Blood Furnace
	"furnace",
	"%f[%w]shh%f[%W]",       -- Shattered Halls
	"%f[%w]mgt%f[%W]",       -- Magisters' Terrace
	"terrace",
	"%f[%w]arc%f[%W]",       -- Arcatraz
	"arcatraz",
	"%f[%w]bot%f[%W]",       -- Botanica
	"botanica",
	"%f[%w]mech%f[%W]",      -- Mechanar
	"mechanar",
	"scholo",                -- Scholomance
	"strat",                 -- Stratholme
	"%f[%w]aq%d?[0]?%f[%W]", -- Ruins of Ahn'Qiraj / Temple of Ahn'Qiraj
	"qiraj",
	"%f[%w]zg%f[%W]",        -- Zul'Gurub
	"%f[%w]bwl%f[%W]",       -- Blackwing Lair
	"%f[%w]lair",
	"naxx",                  -- Naxxramas
	-- Molten Core not added because it's part of some craft keywords
}

----------------------------------------------------------------------------------------------------
-- keyword setup
----------------------------------------------------------------------------------------------------
-- This is an automatically built table of minor keywords that will make parsing requests easier by
-- skipping over useless words. Gem keywords have a different value because they'll also be used to
-- handle special cases of "and" like in: link agi and hit gem
local minorKeywords = {}
local GEM_MINOR_KEYWORD = 13 -- any value other than 1 so lucky 13 is picked
for major_name,list in pairs(data.craftKeywordList) do
	for i=1,#list do
		for keyword in pairs(list[i][5]) do
			minorKeywords[keyword] = major_name == "gem" and GEM_MINOR_KEYWORD or minorKeywords[keyword] or 1
		end
	end
end

-- This is an automatically built table of all words found in the non-keyword-based lists. This will
-- make it possible to figure out what to actually search for when there are extra things at the
-- beginning and end of the link request (like "please").
local nameKeyWords = {}
for _,list in pairs({data.spellList, data.talentList, data.craftNameList}) do
	for name in pairs(list) do
		for keyword in name:gmatch("%w+") do
			nameKeyWords[keyword] = 1
		end
	end
end

----------------------------------------------------------------------------------------------------
-- searches by full name
----------------------------------------------------------------------------------------------------
local function ParseNameRequest(text)
	-- build a possible name from the text. Examples of the building rules:
	-- text:me omen of clarity please       / omen of clarity (skips "me" because it's not a word in any name, then stops at "please" for the same reason)
	-- text:me omen of that clarity please  / omen of (stops building because "that" isn't a word in any names)
	-- text:me omen of that mongoose please / omen of (cancels the search at "mongoose" because that's a craft keyword)
	local word_table
	local finished_building
	for keyword in text:gmatch("%w+") do
		if not nameKeyWords[keyword] then
			if minorKeywords[keyword] then
				return
			end
			-- "talent" won't end the building because of special case #9999999 where certain talents
			-- like Surefooted and Vitality (which are names of enchantments) could be asked for like
			-- "the hunter talent surefooted" - talent can't be added to those names or else things
			-- like "link the talent brambles" wouldn't work!
			if word_table and keyword ~= "talent" then
				finished_building = true
			end
		-- "the" is a special case keyword and shouldn't be accepted for the beginning or else things
		-- link "link the talent brambles" won't work.
		elseif not finished_building and (word_table or keyword ~= "the") then
			word_table = word_table or {}
			word_table[#word_table+1] = keyword
		end
	end
	if not word_table then
		return
	end

	local search_text = table.concat(word_table, " ")
	local match

	-- try to find a player spell
	match = data.spellList[search_text]
	if match then
		return { string.format("|cff71d5ff|Hspell:%d|h[%s]|h|r", match, (GetSpellInfo(match))) }
	end
	-- try to find a player talent
	match = data.talentList[search_text]
	if match then
		-- with some talents that share names with enchantments (like Surefooted), the word "talent"
		-- must be in the request
		if not match[4] or text:find("talent%f[%W]") then
			return { string.format("|cff4e96f7|Htalent:%d:%d|h[%s]|h|r", match[2], match[3], match[1]) }
		end
		return nil
	end
	-- try to find a craftable thing
	match = data.craftNameList[search_text]
	if match then
		return { string.format("|cffffd000|Henchant:%d|h[%s%s]|h|r", match[1], (match[2] or ""), (GetSpellInfo(match[1]))) }
	end
end

----------------------------------------------------------------------------------------------------
-- searches by keywords
----------------------------------------------------------------------------------------------------
----------------------------------------
-- return tables from data.craftKeywordList that match keywords
----------------------------------------
local function GetCraftMatches(major_keyword, minor_keywords)
	local matches = nil -- table holding references to data.craftKeywordList tables that matched
	local is_single_minor_keyword = (not major_keyword and #minor_keywords == 1)
	for i=1,#minor_keywords do
		-- searching through previous matches - they must now have all keywords or they're removed
		if matches then
			for j=#matches,1,-1 do
				if not matches[j][5][minor_keywords[i]] then
					table.remove(matches, j)
				 end
			end
		-- searching through only a major keyword table
		elseif major_keyword then
			for k,v in pairs(data.craftKeywordList[major_keyword]) do
				if v[5][minor_keywords[i]] and PleaseLinkSave.maxContent >= v[3] and (not is_single_minor_keyword or v[2]) then
					matches = matches or {}
					matches[#matches+1] = v
				end
			end
			if not matches then
				return
			end -- have to iterate through each major keyword table
		else
			for major_name,list in pairs(data.craftKeywordList) do
				if major_name ~= "set" then -- special case - sets must be searched for specifically
					for k,v in pairs(list) do
						if v[5][minor_keywords[i]] and PleaseLinkSave.maxContent >= v[3] and (not is_single_minor_keyword or v[2]) then
							matches = matches or {}
							matches[#matches+1] = v
						end
					end
				end
			end
			if not matches then
				return
			end
		end
	end
	local limit = major_keyword == "set" and 7 or SEARCH_MATCH_LIMIT -- make sure sets allow at least 7 because of cloth arcane resistance
	return (matches and matches[1] ~= nil and #matches <= limit) and matches or nil
end

----------------------------------------
-- parse the link request text and return a table of chat messages with all the matching links
----------------------------------------
local function ParseKeywordRequest(text, suggestions)
	----------------------------------------
	-- formatting fixes
	----------------------------------------
		text = text:gsub("metagem", "metagem gem") -- to make special "and" cases work with meta gems
			:gsub("meta%f[%W]", "metagem gem")
			:gsub(" gem gem", " gem")
			-- some things have a major keyword in the name that might mess up searches
			:gsub("2[%- ]+hand", "2h ")
			:gsub("two[%- ]+hand", "2h ")
			:gsub("1[%- ]+hand", "1h ")
			:gsub("one[%- ]+hand", "1h ")
			:gsub("leg arm[o]?[r]?", "legarmor legs")
			:gsub("legs leg[s]?", "legs")
			:gsub("we[a]?p[o]?[n]? d[a]?m[a]?[g]?[e]?", "weapondamage")
			:gsub("we[a]?p[o]?[n]? chain", "weaponchain")

	----------------------------------------
	-- Splitting text into keyword searches
	----------------------------------------
	-- Each search can have a major keyword and a list of minor ones. Major keywords are words like
	-- "boots" or "legs" which narrow down the search a lot, and minor keywords are words like "hit"
	-- or "agility" that details what is wanted.
	-- Examples of some supported formats that the text may be in:
	--    <minor>                             : link mongoose
	--    <minor> <major>                     : link fort boot
	--    <minor> <major> <major>             : link agi hands back (any <major> without <minor> will use the last <minor> available)
	--    <minor> <major> <minor> <major>     : link agi hands healing weapon
	--    <major> <minor>                     : link chest 6 stat
	--    <major> <minor> <major> <minor>     : link chest 6 stat boot fort
	--    <major> <minor> and <minor> <major> : link chest 6 stat and fort boot (the and is required here)
	--    "and" will also separate searches   : link mongoose and fort on boots
	--    "and" has a special case for gems   : link agi and hit gem (combined into one search)
	--    long example: (heal food) and (agi and hit gem) and (mongoose) and (agi on back) and (hand) (12 agi meta gem) (fiery wep)
	local searches = { {{}, nil, nil}, } -- searches[1] = {{minor keywords}, major keyword, true if NOT 2-part gem search}
	local on_search = 1                  -- the search currenly being built

	local number, word
	local minor_keywords = searches[on_search][1]
	for keyword in text:gmatch("%w+") do
		-- split things like 25agi - numbers are never major keywords so can be checked and added now
		if keyword ~= "2h" and keyword ~= "1h" then
			number, word = keyword:match("(%d+)(%l+)")
			if number then
				if minorKeywords[number] then
					minor_keywords[#minor_keywords+1] = number
				end
				keyword = word
			end
		end
		keyword = data.keywordFixes[keyword] or keyword

		-- major keyword or search separator word found
		if data.craftKeywordList[keyword] or keyword == "and" then
			-- special "and" handling for gems - combine this and the previous search if the last one
			-- has no major keyword and all minor ones are from gem lists
			if keyword == "gem" and on_search > 1 and not searches[on_search-1][2] and not searches[on_search][2] and not searches[on_search-1][3] then
				-- the current major keyword and minor keywords are added to the last search and then this one is cleared
				searches[on_search-1][2] = keyword
				local last_keywords = searches[on_search-1][1]
				for i=1,#minor_keywords do
					last_keywords[#last_keywords+1] = minor_keywords[i]
				end
				searches[on_search][3] = nil
				searches[on_search][1] = {}
				minor_keywords = searches[on_search][1]
			elseif searches[on_search][2] then
				-- if there's already a keyword, then this search must already be done, so create a new
				-- one and add the major keyword there (if it really is one)
				searches[on_search+1] = {{}, nil}
				on_search = on_search + 1
				minor_keywords = searches[on_search][1]
				if keyword ~= "and" then
					searches[on_search][2] = keyword
					searches[on_search][3] = true -- can't be a 2-part gem search since it has a major keyword
				end
			else
				-- this search doesn't have a major keyword, so add it now (if it really is one)
				if keyword ~= "and" then
					searches[on_search][2] = keyword
					searches[on_search][3] = true -- can't be a 2-part gem search since it has a major keyword
				end
				-- if there are already minor keywords, then set up the next search and move on to it.
				-- if there aren't any, then the format may be <major> <minor> so stay on this search
				if next(minor_keywords) then
					searches[on_search+1] = {{}, nil}
					on_search = on_search + 1
					minor_keywords = searches[on_search][1]
				end
			end
		-- just a minor keyword to add to the current search - any other word is just skipped over
		elseif minorKeywords[keyword] then
			if minorKeywords[keyword] ~= GEM_MINOR_KEYWORD then
				searches[on_search][3] = true -- can't be a 2-part gem search since it has a non-gem minor keyword
			end
			minor_keywords[#minor_keywords+1] = keyword
		-- add most words from named things so that this search will fail (for example: link omen of mongoose - that would show mongoose if omen wasn't added)
		elseif nameKeyWords[keyword] and #keyword > 3 then
			minor_keywords[#minor_keywords+1] = keyword
		end
	end

	----------------------------------------
	-- More special case fixes
	----------------------------------------
	for i=1,#searches do
		local minor = searches[i][1]

		-- if searching for just "hit" without specifying physical or spell hit, then assume they mean physical
		local just_hit
		for j=1,#minor do
			if minor[j] == "hit" then
				just_hit = true
			elseif minor[j] == "spell" or minor[j] == "spellhit" then
				just_hit = nil
				break
			end
		end
		if just_hit then
			table.insert(searches[i][1], "physical")
		end
		-- narrowing down gem matches
		if searches[i][2] == "gem" then
			local only_stamina = nil -- searching for only stamina on gems - change to pure stamina
			local is_meta      = nil -- searching for a meta gem
			for j=1,#minor do
				if minor[j] == "stamina" then
					if only_stamina == nil then
						only_stamina = true
					end
				elseif minor[j] == "metagem" then
					is_meta = true
					only_stamina = false
				elseif minor[j] ~= "rare" and minor[j] ~= "epic"and minor[j] ~= "blue" and
				       minor[j] ~= "red" and minor[j] ~= "yellow" and minor[j] ~= "green" and
				       minor[j] ~= "orange" and minor[j] ~= "purple" then
					only_stamina = false
				end
			end
			if only_stamina then
				table.insert(searches[i][1], "pure") -- only pure stamina gems will match
			end
			if not is_meta then
				table.insert(searches[i][1], "nometa") -- only non-meta gems will match
			end
		-- cloak resistances - if not specifying a resistance type, then only show resist all
		elseif searches[i][2] == "cloak" then
			local is_resistance -- if resistance is being searched for
			local is_specific   -- if a specific resistance type was used
			for j=1,#minor do
				if minor[j] == "resistance" or minor[j] == "res" then
					is_resistance = true
				elseif minor[j] == "arcane" or minor[j] == "fire" or minor[j] == "nature"  or minor[j] == "shadow" then
					is_specific = true
					break
				end
			end
			if is_resistance and not is_specific then
				table.insert(searches[i][1], "allres") -- only resist all will match
			end
		end
	end

	----------------------------------------
	-- Executing each search
	----------------------------------------
	local match_list = {}
	local last_minor_list_used = nil
	for i=1,#searches do
		local matches
		if next(searches[i][1]) == nil then -- no minor keywords
			if not searches[i][2] then -- no major keyword either, so stop searching
				break
			elseif not last_minor_list_used then -- haven't searched yet so there's no past keywords to use
				matches = nil
			else -- use previous keywords to handle things like: link agi on back and hands
				matches = GetCraftMatches(searches[i][2], searches[last_minor_list_used][1])
			end
		-- only search if it's not just a profession name or "enchant"
		elseif searches[i][2] or #searches[i][1] > 1 or (not data.professionNames[searches[i][1][1]] and searches[i][1][1] ~= "enchant")  then
			matches = GetCraftMatches(searches[i][2], searches[i][1])
			last_minor_list_used = i
		end
		-- add any recieved matches to a key table so that duplicates can't exist
		if matches then
			for i=1,#matches do
				match_list[matches[i][1]] = matches[i]
			end
		end
	end

	----------------------------------------
	-- If no matches, stop or suggest some
	----------------------------------------
	if next(match_list) == nil then
		if suggestions then
			for i=1,#searches do
				if searches[i][2] and PleaseLinkData.suggestions[searches[i][2]] then
					return {"Unknown! If you want " .. searches[i][2] .. " enchantments, try: " .. PleaseLinkData.suggestions[searches[i][2]]}
				end
			end
			-- check for shield/ring in minor keywords if no major keywords were found
			for i=1,#searches do
				if searches[i][1] then
					for j=1,#searches[i][1] do
						if searches[i][1][j] == "shield" or searches[i][1][j] == "ring" then
							return {"Unknown! If you want " .. searches[i][1][j] .. " enchantments, try: " .. PleaseLinkData.suggestions[searches[i][1][j]]}
						end
					end
				end
			end
		end
		return
	end

	----------------------------------------
	-- Build the table of messages
	----------------------------------------
	local message_list = {""}
	local total_length = 0
	for _,v in pairs(match_list) do
		link = string.format("|cffffd000|Henchant:%d|h[%s%s]|h|r", v[1], (v[4] or ""), (GetSpellInfo(v[1])))
		local length = #link
		if total_length + length > 255 then
			if #message_list >= PleaseLinkSave.maxMessages then
				message_list[#message_list] = message_list[#message_list] .. "..." -- it's OK if "..." goes over 255 characters
				break
			end
			message_list[#message_list+1] = link
			total_length = length
		else
			message_list[#message_list] = message_list[#message_list] .. link
			total_length = total_length + length
		end
	end
	return message_list
end

----------------------------------------------------------------------------------------------------
-- handle chat events
----------------------------------------------------------------------------------------------------
----------------------------------------
-- register or unregister chat events based on the settings of a chat group
----------------------------------------
function pleaseLinkFrame:SetChatEvents(chat_group)
	local events = chatGroupEvents[chat_group]
	if events then
		local register_function = PleaseLinkSave.chatGroups[chat_group] == ChatReaction.OFF and self.UnregisterEvent or self.RegisterEvent
		for i=1,#events do
			register_function(self, events[i])
		end
	end
end

----------------------------------------
-- received an event
----------------------------------------
pleaseLinkFrame:SetScript("OnEvent", function(self, event, addon_name)
	----------------------------------------
	-- a chat event
	-- arg1 = message, arg2 = sender, arg8 = channel number
	----------------------------------------
	local group = chatEventGroup[event]
	if group then
		local text = arg1:lower()
		local search_request -- the text to parse to find links
		-- matches things like link ___ / what are the mats for ___ / what's the mats on ___ / show me mats ___
		search_request = text:match("%f[%w]link (.+)") or
		                 text:match("%f[%w]w[h]?[au]t[']?[s]? %l*%s*%l*%s*mat[s]? (.+)") or
		                 text:match("%f[%w]show %l*%s*%l*%s*mat[s]? (.+)") or nil
		if not search_request then
			return
		end

		-- check for blacklisted text - they're probably asking about an item from a location or a
		-- quest link or something like that not known about
		for i=1,#blackListText do
			if text:find(blackListText[i]) then
				return
			end
		end

		-- figure out how to reply - nil chat_type will print it
		local chat_type, channel -- channel is extra info like the whisper name or channel number
		if PleaseLinkSave.chatGroups[group] ~= ChatReaction.SHOW then
			if PleaseLinkSave.chatGroups[group] == ChatReaction.WHISPER then
				chat_type = "WHISPER"
			else
				chat_type = event:match("^CHAT_MSG_(%w+)")
			end
			if chat_type == "WHISPER" then
				channel = arg2 -- arg2 is a global set by Blizzard when receiving chat - the chatter's name
			elseif chat_type == "CHANNEL" then
				channel = arg8 -- arg8 is a global set by Blizzard when receiving chat - the channel number
			end
		end

		-- build the message(s)
		-- the first gsub here is to change links into plain names since some people say things like "10 hit [Lionseye]"
		search_request = search_request:gsub("|c.-%[(.-)]|h|r", " %1 ") -- add spaces around it for safety
			:gsub("<3","") -- before punctuation is removed
			:gsub("[,/&]", " and ")
			:gsub("%p+", "")
			:gsub("%s+", " ")
			-- normal speech things that shouldn't use keywords
			:gsub("%f[%w]at it%f[%W]", "atit")
			:gsub("%f[%w]at the", "atthe")
			:gsub("%f[%w]at all", "atall")
			:gsub("%f[%w]at once", "atonce")
			:gsub("%f[%w]you[r]?[e]? at%f[%W]", "youreat")
			:gsub("%f[%w]ur at%f[%W]", "youreat")
			:gsub("any one", "anyone")
			:gsub("any1%f[%W]", "anyone")
			:gsub("%f[%w]ne1%f[%W]", "anyone")
			:gsub("some one", "someone")
			:gsub("some1%f[%W]", "someone")
			:gsub("my gear", "mygear")

		local message_list = ParseNameRequest(search_request)
		if not message_list and not search_request:find("talent%f[%W]") then
			message_list = ParseKeywordRequest(search_request, (event == "CHAT_MSG_WHISPER" and PleaseLinkSave.suggestions))
		end

		-- send or show the messages
		if message_list then
			for i=1,#message_list do
				if not chat_type then
					DEFAULT_CHAT_FRAME:AddMessage(message_list[i])
				elseif PleaseLinkSave.chatGroups[group] == ChatReaction.LONG or #message_list == 1 then
					SendChatMessage(message_list[i], chat_type, nil, channel)
				else -- SHORT setting and the message is too long, so whisper them
					SendChatMessage(message_list[i], "WHISPER", nil, arg2)
				end
			end
		end
		return
	end

	----------------------------------------
	-- set up default settings and events
	----------------------------------------
	if event == "ADDON_LOADED" and addon_name == "PleaseLink" then
		pleaseLinkFrame:UnregisterEvent(event)
		if PleaseLinkSave                    == nil then PleaseLinkSave                    = {}                   end
		if PleaseLinkSave.chatGroups         == nil then PleaseLinkSave.chatGroups         = {}                   end
		if PleaseLinkSave.maxMessages        == nil then PleaseLinkSave.maxMessages        = 2                    end
		if PleaseLinkSave.maxContent         == nil then PleaseLinkSave.maxContent         = data.Content.SW      end
		if PleaseLinkSave.suggestions        == nil then PleaseLinkSave.suggestions        = false                end
		if PleaseLinkSave.chatGroups.whisper == nil then PleaseLinkSave.chatGroups.whisper = ChatReaction.WHISPER end
		for name in pairs(chatGroupEvents) do
			if PleaseLinkSave.chatGroups[name] == nil then
				PleaseLinkSave.chatGroups[name] = ChatReaction.OFF
			end
			pleaseLinkFrame:SetChatEvents(name)
		end
		return
	end
end)
pleaseLinkFrame:RegisterEvent("ADDON_LOADED") -- temporary - to set up default settings and events

----------------------------------------------------------------------------------------------------
-- slash command
----------------------------------------------------------------------------------------------------
_G.SLASH_PLEASELINK1 = "/pleaselink"
function SlashCmdList.PLEASELINK(input)
	input = input or ""

	local command, value = input:match("(%w+)%s*(.*)")
	command = command and command:lower() or ""
	value = value and value:upper() or nil

	----------------------------------------
	-- max messages
	----------------------------------------
	if command:find("maxmessage[s]?$") then
		local amount = tonumber(value)
		if not amount or amount < 1 then
			DEFAULT_CHAT_FRAME:AddMessage("The max messages amount must be 1 or more.")
		else
			PleaseLinkSave.maxMessages = amount
			DEFAULT_CHAT_FRAME:AddMessage("The max messages amount is now " .. value .. ".")
		end
		return
	end

	----------------------------------------
	-- content restriction
	----------------------------------------
	if command == "content" then
		local content = data.Content[value or ""]
		if content then
			PleaseLinkSave.maxContent = content
			DEFAULT_CHAT_FRAME:AddMessage("The latest content level linked is now: " .. value)
		else
			DEFAULT_CHAT_FRAME:AddMessage('Syntax: /pleaselink content <"T4"|"T5"|"T6"|"ZA"|"SW">')
		end
		return
	end

	----------------------------------------
	-- suggest enchantments when possible
	----------------------------------------
	if command == "suggest" or command == "suggestions" then
		if value == "ON" then
			PleaseLinkSave.suggestions = true
		elseif value == "OFF" then
			PleaseLinkSave.suggestions = false
		else
			DEFAULT_CHAT_FRAME:AddMessage('Syntax: /pleaselink suggest <"on"|"off">')
		end
		DEFAULT_CHAT_FRAME:AddMessage("Replying with some enchantment suggestions is now " .. (PleaseLinkSave.suggestions and "on." or "off."))
		return
	end

	----------------------------------------
	-- change the setting of a chat group
	----------------------------------------
	local reaction_setting = value and ChatReaction[value] or nil
	if reaction_setting then
		-- set all chat types
		if command == "all" then
			for chat_type in pairs(chatGroupEvents) do
				PleaseLinkSave.chatGroups[chat_type] = reaction_setting
				pleaseLinkFrame:SetChatEvents(chat_type)
			end
			DEFAULT_CHAT_FRAME:AddMessage("All chat settings are now: " .. value)
			return
		end
		-- specific chat type
		local events = chatGroupEvents[command]
		if events then
			PleaseLinkSave.chatGroups[command] = reaction_setting
			pleaseLinkFrame:SetChatEvents(command)
			DEFAULT_CHAT_FRAME:AddMessage("The " .. command .. " chat setting is now: " .. value)
			return
		end
	end

	----------------------------------------
	-- bad or no command, so show syntax
	----------------------------------------
	-- find the name of a constant value, like "T4" for 10 in the Content table
	function GetValueName(search_table, value)
		for k,v in pairs(search_table) do
			if value == v then
				return k
			end
		end
		return "unset"
	end

	DEFAULT_CHAT_FRAME:AddMessage('PleaseLink commands:', 1, 1, 0)
	DEFAULT_CHAT_FRAME:AddMessage('/pleaselink maxmessages <amount>  ' .. '|cffffff00(now ' .. PleaseLinkSave.maxMessages .. ')|r')
	DEFAULT_CHAT_FRAME:AddMessage('/pleaselink suggest <"on"|"off">  ' .. '|cffffff00(now ' .. (PleaseLinkSave.suggestions and "ON" or "OFF") .. ')|r')
	DEFAULT_CHAT_FRAME:AddMessage('/pleaselink content <"T4"|"T5"|"T6"|"ZA"|"SW">  |cffffff00(now ' .. GetValueName(data.Content, PleaseLinkSave.maxContent) .. ')|r')
	DEFAULT_CHAT_FRAME:AddMessage(' ')
	for chat_type in pairs(chatGroupEvents) do
		DEFAULT_CHAT_FRAME:AddMessage('/pleaselink ' .. chat_type .. ' <setting>  ' .. '|cffffff00(now ' .. GetValueName(ChatReaction, PleaseLinkSave.chatGroups[chat_type]) .. ')|r')
	end
	DEFAULT_CHAT_FRAME:AddMessage('/pleaselink all <setting>')
	DEFAULT_CHAT_FRAME:AddMessage('<setting> can be: off, short, long, whisper, show', 1, 1, 0)
end
