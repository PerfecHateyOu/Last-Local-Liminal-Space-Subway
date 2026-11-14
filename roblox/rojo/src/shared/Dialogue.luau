--!strict
-- Parent chats and mask lines from src/constants.ts (CHATS, CALM_CHATS,
-- MASK_DIALOGUES high/calm tier). Critical-tier glitch copy stays out.

local Dialogue = {}

export type ChatLine = { who: number, line: string }
export type ChatExchange = { ChatLine }

export type MaskLine = {
	who: number,
	line: string,
	calm: string,
	off: { string },
	needsSus: boolean,
}

-- who: 0 Mom, 1 Dad. Indices match web SEGS.chat.
local CHATS: { ChatExchange } = {
	{
		{ who = 1, line = "Did you ever call your sister back?" },
		{ who = 0, line = "Tonight. Remind me." },
	},
	{
		{ who = 0, line = "Your cousin’s gonna be so tall now." },
		{ who = 1, line = "Everybody’s tall now." },
	},
	{
		{ who = 1, line = "We should’ve taken the bus." },
		{ who = 0, line = "The bus takes forever." },
	},
	{
		{ who = 0, line = "Did you ever call your sister back?" },
		{ who = 1, line = "Did you ever call your sister back?" },
	},
	{
		{ who = 1, line = "Is it always this empty?" },
		{ who = 0, line = "It’s always this empty." },
	},
}

local CALM_CHATS: { ChatExchange } = {
	{
		{ who = 0, line = "Don’t lean against the doors." },
		{ who = 1, line = "Should be in Queens in twenty minutes." },
	},
	{
		{ who = 0, line = "Did they change the schedule?" },
		{ who = 1, line = "It feels slower today." },
	},
	{
		{ who = 0, line = "I always hated this curve." },
		{ who = 1, line = "Check your bag." },
	},
}

-- First tier only (High / Calm set). needsSus lines need Suspicion >= 10.
local MASK_TIER0: { MaskLine } = {
	{
		who = 0,
		line = "You've been quiet. You okay, hon?",
		calm = "Yeah, just tired.",
		off = { "Why? Do I look weird?", "Did the lights just change?" },
		needsSus = false,
	},
	{
		who = 1,
		line = "How many more stops, you think?",
		calm = "A few. We’re fine.",
		off = { "Why are you asking me?", "Wait, which train is this?" },
		needsSus = false,
	},
	{
		who = 0,
		line = "Did you eat anything today?",
		calm = "Had a bagel earlier.",
		off = { "Why does everyone keep asking that?", "Sorry, what?" },
		needsSus = false,
	},
	{
		who = 0,
		line = "You look warm. Are you warm?",
		calm = "Just stuffy in here.",
		off = { "Is it hot to you?", "Stop looking at me like that." },
		needsSus = false,
	},
	{
		who = 1,
		line = "You’re staring at something.",
		calm = "Just zoning out.",
		off = { "No I’m not.", "Don’t you see it?" },
		needsSus = true,
	},
	{
		who = 0,
		line = "Did you drop something on the floor?",
		calm = "No, just adjusting my bag.",
		off = { "Why are you staring?", "Leave me alone." },
		needsSus = false,
	},
	{
		who = 1,
		line = "You want the window seat?",
		calm = "Nah, I’m good here.",
		off = { "Why, what’s out there?", "Don’t make me move." },
		needsSus = false,
	},
	{
		who = 0,
		line = "Text your aunt we’re on the train.",
		calm = "Sending it now.",
		off = { "There’s no signal down here.", "Which train do I tell her?" },
		needsSus = false,
	},
}

function Dialogue.parentName(who: number): string
	if who == 1 then
		return "Dad"
	end
	return "Mom"
end

function Dialogue.chatLine(who: number, line: string): string
	return Dialogue.parentName(who) .. ": " .. line
end

function Dialogue.maskPrompt(who: number, line: string): string
	return Dialogue.parentName(who) .. ": " .. line
end

function Dialogue.youAnswer(text: string, parentWho: number): string
	return "You: " .. text .. " (" .. Dialogue.parentName(parentWho) .. " nods.)"
end

function Dialogue.maskHesitate(parentWho: number): string
	return "You don’t answer fast enough. " .. Dialogue.parentName(parentWho) .. ": Hon?"
end

function Dialogue.maskOdd(parentWho: number): string
	return Dialogue.parentName(parentWho) .. " keeps looking at you."
end

-- Swap some of chat indices 0–2 for calm small talk (web chatSwap).
function Dialogue.buildChatPlan(rng: () -> number): { [number]: ChatExchange }
	local plan: { [number]: ChatExchange } = {}
	local extras = table.clone(CALM_CHATS)
	for i = 0, 2 do
		if #extras > 0 and rng() < 0.5 then
			local index = math.clamp(math.floor(rng() * #extras) + 1, 1, #extras)
			plan[i] = extras[index]
			table.remove(extras, index)
		else
			plan[i] = CHATS[i + 1]
		end
	end
	for i = 3, #CHATS - 1 do
		plan[i] = CHATS[i + 1]
	end
	return plan
end

function Dialogue.chatFor(plan: { [number]: ChatExchange }, chatIndex: number): ChatExchange?
	return plan[chatIndex]
end

function Dialogue.maskPool(suspicion: number, needSusAt: number): { MaskLine }
	local pool = {}
	for _, entry in MASK_TIER0 do
		if not entry.needsSus or suspicion >= needSusAt then
			table.insert(pool, entry)
		end
	end
	return pool
end

function Dialogue.pickMask(
	pool: { MaskLine },
	used: { [string]: boolean },
	lastLine: string?,
	rng: () -> number
): MaskLine?
	if #pool == 0 then
		return nil
	end
	local fresh = {}
	for _, entry in pool do
		if used[entry.line] ~= true then
			table.insert(fresh, entry)
		end
	end
	if #fresh == 0 then
		table.clear(used)
		fresh = table.clone(pool)
	end
	local candidates = {}
	for _, entry in fresh do
		if entry.line ~= lastLine then
			table.insert(candidates, entry)
		end
	end
	if #candidates == 0 then
		candidates = fresh
	end
	local index = math.clamp(math.floor(rng() * #candidates) + 1, 1, #candidates)
	return candidates[index]
end

function Dialogue.shuffleAnswers(calm: string, offA: string, offB: string, rng: () -> number): { { text: string, val: string } }
	local items = {
		{ text = calm, val = "calm" },
		{ text = offA, val = "off" },
		{ text = offB, val = "off" },
	}
	for i = #items, 2, -1 do
		local j = math.clamp(math.floor(rng() * i) + 1, 1, i)
		items[i], items[j] = items[j], items[i]
	end
	return items
end

return Dialogue
