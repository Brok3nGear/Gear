--[==[
Author: Brok3nGear
Name: XpHud
Date last modified: Oct 22/2016
Description: This addon allows you to track serveral xp variables. Drag the window with the right click. Left click displays quest location your character should be in.

coded by use of:
http://wowprogramming.com/
http://wowwiki.wikia.com/wiki/World_of_Warcraft_API
and shoutout to Fizzlemizz (from http://wowprogramming.com/) for assistance!

========
FEATURES
display current xp
display needed xp
display xp as percent and bar
display rest xp
display rest xp as percent
display number of "target" to kill before level
display location to quest for level upon left click
commands
	/xphud	help
			show
			hide
			reset
			intro
========
FEATURES TO IMPLEMENT
display current pet xp
display needed pet xp
display pet xp as percent
========
COMMANDS TO IMPLEMENT
/xphud options
--]==]

local unitXp 					= UnitXP("player")-- Returns the number of experience points the specified unit has in their current level. (only works on your player)
local maxXp 					= UnitXPMax("player")-- Returns the number of experience points the specified unit needs to reach their next level. (only works on your player)
local restState 				= GetRestState()-- Returns information about a player's rest state (saved up experience bonus)
local xpDisabled 				= IsXPUserDisabled()-- Returns 1 if the character has disabled experience gain.
local xpExhaustion 				= GetXPExhaustion()-- Returns your character's current rested XP, nil if character is not rested.
local state, name, multiplier	= GetRestState()
local run 						= true
local debugtrue 				= false
local avgItemLevel
local oldxp 					= 0
local oldrestxp					= 0
local pass1						= true
local restXpAmt

if debugtrue then
	print("Starting Info")
	print(unitXp)
	print(oldxp)
	print(maxXp)
	print(oldrestxp)
	print(xpExhaustion)
	print(restState)
	print(xpDisabled)
	print(petXp)
	print ("============")
	print("state: " .. state)
	print("name: " .. name)
	print("multiplier: " .. multiplier)
	print ("============")
end
	
	
--=============================================================
--Updates values when the player logs in
local loginEvent = CreateFrame("FRAME", "LoginAddonFrame");
loginEvent:RegisterEvent("PLAYER_LOGIN");
local function eventHandler(self, event, ...)
	unitXp 			= UnitXP("player")
	maxXp 			= UnitXPMax("player")
	restState 		= GetRestState()
	xpDisabled 		= IsXPUserDisabled()
	petXp		 	= GetPetExperience()
	xpExhaustion 	= GetXPExhaustion()
	print("|cffff1111XpHud Loaded: /xphud help|r")
end

loginEvent:SetScript("OnEvent", eventHandler);

--=============================================================
--sets the oldxp to current xp once at beginning of addon
local function setXp()
	if pass1 then
		oldxp = unitXp
		pass1 = false
		if xpExhaustion ~= nil then
			oldrestxp = xpExhaustion
		end
	end
end

setXp()

--=============================================================
--returns the number of enemies to kill, of last kill, to gain new level
local function killToLevel(player_xp_type,x)
	if x == 1 then
		local xpAmt = unitXp - oldxp
		if xpAmt > 0 and player_xp_type == "playerxp" then
			local killnum = (maxXp - unitXp)/(unitXp - oldxp)
			oldxp = unitXp
			return ceil(killnum)
		else
			oldxp = unitXp
			return 0
		end
	end
end

--=============================================================
--creates nice looking textbox with edges
local XpHudFrame = CreateFrame("frame","XpHudFrameFrame", UIParent)
XpHudFrame:SetBackdrop({
      bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
      edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
      tile=1, tileSize=36, edgeSize=36, 
      insets={left=11, right=12, top=12, bottom=11}
})
windowWidth = 270
windowHeight = 90
XpHudFrame:SetWidth(windowWidth)
XpHudFrame:SetHeight(windowHeight)
XpHudFrame:SetPoint("CENTER",UIParent)
XpHudFrame:EnableMouse(true)
XpHudFrame:SetMovable(true)
XpHudFrame:RegisterForDrag("RightButton")
XpHudFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
XpHudFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
local background = XpHudFrame:CreateTexture("TestFrameBackground", "BACKGROUND")
background:SetTexture(0, 0, 0, 0)
background:SetAllPoints()
XpHudFrame:SetFrameStrata("BACKGROUND")--sets frame z location; BACKGROUND, LOW, MEDIUM, HIGH, DIALOG, FULLSCREEN, FULLSCREEN_DIALOG, TOOLTIP

--=============================================================
--creates all the info to be put into the main frame
local experienceA = XpHudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local experience1 = XpHudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local experienceB = XpHudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local experience2 = XpHudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local experienceC = XpHudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local experience3 = XpHudFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
local unitLevel = UnitLevel("player")
local factionName = UnitFactionGroup("player")
local questLocation = "nowhere"

--=============================================================
--experience bar in frame
Xphud_Status_bar = CreateFrame("StatusBar", nil, XpHudFrame)
Xphud_Status_bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
Xphud_Status_bar:GetStatusBarTexture():SetHorizTile(false)
Xphud_Status_bar:SetMinMaxValues(0, 100)
Xphud_Status_bar:SetWidth(240)
Xphud_Status_bar:SetAlpha(1.0)
Xphud_Status_bar:SetHeight(10)
Xphud_Status_bar:SetPoint("BOTTOM",XpHudFrame, 0, 17)


--=============================================================
--converts passed values to hex values
local function convertNum(STEP_NUMBER, STEP_VALUE)
	local iteration = STEP_NUMBER * STEP_VALUE

	local hexalpha, hexbeta
	local decalpha = math.floor(iteration / 16)
	if decalpha > 9 then
		if decalpha >= 10 then
			hexalpha = "a"
		elseif decalpha == 11 then
			hexalpha = "b"
		elseif decalpha == 12 then
			hexalpha = "c"
		elseif decalpha == 13 then
			hexalpha = "d"
		elseif decalpha == 14 then
			hexalpha = "e"
		elseif decalpha == 15 then
			hexalpha = "f"
		end
	else
		hexalpha = decalpha
	end

	local decbeta = iteration % 15
	if decbeta > 9 then
		if decbeta == 10 then
			hexbeta = "a"
		elseif decbeta == 11 then
			hexbeta = "b"
		elseif decbeta == 12 then
			hexbeta = "c"
		elseif decbeta == 13 then
			hexbeta = "d"
		elseif decbeta == 14 then
			hexbeta = "e"
		elseif decbeta == 15 then
			hexbeta = "f"
		end
	else
		hexbeta = decbeta
	end

	--Green : ff00ff00
	--Red   : ffff0000
	return (hexalpha .. hexbeta) -- 00, ff -> ff, 00
end

--=============================================================
--function that checks player level and returns quest areas
XpHudFrame:SetScript("OnMouseDown", function(self, button)
local questLocation = {}
local i = 0
	unitLevel = UnitLevel("player")
	if button == "LeftButton" then
		print("|cffffff00Player level is " .. unitLevel .. ", and Faction is " .. factionName .. "|r")
		
		if unitLevel <= 10 then
			if factionName == "Horde" then
				i = i + 1
				questLocation[i] = "Durotar"
				i = i + 1
				questLocation[i] = "Eversong Woods"
				i = i + 1
				questLocation[i] = "Mulgore"
				i = i + 1
				questLocation[i] = "Tirisfal Glades"
			elseif factionName == "Alliance" then
				i = i + 1
				questLocation[i] = "Azuremyst Isle"
				i = i + 1
				questLocation[i] = "Dun Morogh"
				i = i + 1
				questLocation[i] = "Elwynn Forest"
				i = i + 1
				questLocation[i] = "Teldrassil"
			end
		end
		
		if unitLevel >= 10 and unitLevel <= 20 then
			if factionName == "Horde" then
				i = i + 1
				questLocation[i] = "Ghostlands"
				i = i + 1
				questLocation[i] = "Silverpine Forest"
			elseif factionName == "Alliance" then
				i = i + 1
				questLocation[i] = "Bloodmyst Isle"
				i = i + 1
				questLocation[i] = "Darkshore"
				i = i + 1
				questLocation[i] = "Westfall"
				i = i + 1
				questLocation[i] = "Loch Modan"
			end
		end
		
		if unitLevel >= 10 and unitLevel <= 25 then
			if factionName == "Horde" then
				i = i + 1
				questLocation[i] = "Barrens"
			end
		end
		
		if unitLevel >= 15 and unitLevel <= 25 then
			if factionName == "Alliance" then
				i = i + 1
				questLocation[i] = "Redridge Mountains"
			end
		end
		
		if unitLevel >= 15 and unitLevel <= 27 then
			if factionName == "Horde" then
				i = i + 1
				questLocation[i] = "Stonetalon Mountains"
			elseif factionName == "Alliance" then
				i = i + 1
				questLocation[i] = "Stonetalon Mountains"
			end
		end

		if unitLevel >= 18 and unitLevel <= 30 then
			if factionName == "Horde" then
				i = i + 1
				questLocation[i] = "Ashenvale"
			elseif factionName == "Alliance" then
				i = i + 1
				questLocation[i] = "Ashenvale"
				i = i + 1
				questLocation[i] = "Duskwood"
			end
		end

		if unitLevel >= 20 and unitLevel <= 30 then
			if factionName == "Horde" then
				i = i + 1
				questLocation[i] = "Hillsbrad Foothills"
			elseif factionName == "Alliance" then
				i = i + 1
				questLocation[i] = "Hillsbrad Foothills"
				i = i + 1
				questLocation[i] = "Wetlands"
			end
		end

		if unitLevel >= 25 and unitLevel <= 35 then
			if factionName == "Horde" then
				i = i + 1
				questLocation[i] = "Thousand Needles"
			end
		end

		if unitLevel >= 30 and unitLevel <= 40 then
			i = i + 1
			questLocation[i] = "Alterac Mountains"
			i = i + 1
			questLocation[i] ="Arathi Highlands"
			i = i + 1
			questLocation[i] ="Desolace"
		end

		if unitLevel >= 30 and unitLevel <= 45 then
			i = i + 1
			questLocation[i] = "Stranglethorn Vale"
		end

		if unitLevel >= 35 and unitLevel <= 45 then
			if factionName == "Horde" then
				i = i + 1
				questLocation[i] = "Dustwallow Marsh"
				i = i + 1
				questLocation[i] = "Badlands"
				i = i + 1
				questLocation[i] = "Swamp of Sorrows"
			elseif factionName == "Alliance" then
				i = i + 1
				questLocation[i] = "Dustwallow Marsh"
			end
		end

		if unitLevel >= 40 and unitLevel <= 50 then
			i = i + 1
			questLocation[i] = "Feralas"
			i = i + 1
			questLocation[i] = "Hinterlands"
			i = i + 1
			questLocation[i] = "Tanaris"
		end

		if unitLevel >= 45 and unitLevel <= 50 then
			i = i + 1
			questLocation[i] = "Searing Gorge"
		end

		if unitLevel >= 45 and unitLevel <= 55 then
			i = i + 1
			questLocation[i] = "Azshara"
			i = i + 1
			questLocation[i] = "Blasted Lands"
		end
		
		if unitLevel >= 48 and unitLevel <= 55 then
			i = i + 1
			questLocation[i] = "Un'goro Crater"
			i = i + 1
			questLocation[i] = "Felwood"
		end

		if unitLevel >= 50 and unitLevel <= 58 then
			i = i + 1
			questLocation[i] = "Burning Steppes"
		end

		if unitLevel >= 51 and unitLevel <= 58 then
			i = i + 1
			questLocation[i] = "Western Plaguelands"
		end

		if unitLevel >= 53 and unitLevel <= 60 then
			i = i + 1
			questLocation[i] = "Eastern Plaguelands"
			i = i + 1
			questLocation[i] = "Winterspring"
		end

		if unitLevel >= 55 and unitLevel <= 58 then
			i = i + 1
			questLocation[i] = "Scarlet Enclave"
		end

		if unitLevel >= 55 and unitLevel <= 60 then
			i = i + 1
			questLocation[i] = "Deadwind Pass"
			i = i + 1
			questLocation[i] = "Moonglade"
			i = i + 1
			questLocation[i] = "Silithus"
		end

		if unitLevel >= 58 and unitLevel <= 63 then
			i = i + 1
			questLocation[i] = "Hellfire Peninsula"
		end

		if unitLevel >= 60 and unitLevel <= 64 then
			i = i + 1
			questLocation[i] = "Zangarmarsh"
		end

		if unitLevel >= 62 and unitLevel <= 65 then
			i = i + 1
			questLocation[i] = "Terokkar Forest"
		end

		if unitLevel >= 64 and unitLevel <= 67 then
			i = i + 1
			questLocation[i] = "Nagrand"
		end

		if unitLevel >= 65 and unitLevel <= 68 then
			i = i + 1
			questLocation[i] = "Blade's Edge Mountains"
		end

		if unitLevel >= 67 and unitLevel <= 70 then
			i = i + 1
			questLocation[i] = "Netherstorm"
			i = i + 1
			questLocation[i] = "Shadowmoon Valley"
		end

		if unitLevel >= 68 and unitLevel <= 70 then
			i = i + 1
			questLocation[i] = "Deadwind Pass"
		end

		if unitLevel >= 68 and unitLevel <= 72 then
			i = i + 1
			questLocation[i] = "Howling Fjord"
			i = i + 1
			questLocation[i] = "Borean Tundra"
		end

		if unitLevel >= 70 and unitLevel <= 73 then
			i = i + 1
			questLocation[i] = "Isle of Quel'Danas"
		end

		if unitLevel >= 71 and unitLevel <= 75 then
			i = i + 1
			questLocation[i] = "Dragonblight"
		end

		if unitLevel >= 73 and unitLevel <= 75 then
			i = i + 1
			questLocation[i] = "Grizzly Hills"
		end

		if unitLevel >= 74 and unitLevel <= 76 then
			i = i + 1
			questLocation[i] = "Zul'Drak"
		end

		if unitLevel >= 76 and unitLevel <= 78 then
			i = i + 1
			questLocation[i] = "Sholazar Basin"
		end

		if unitLevel >= 77 and unitLevel <= 80 then
			i = i + 1
			questLocation[i] = "Crystalsong Forest"
			i = i + 1
			questLocation[i] = "Hrothgar's Landing"
			i = i + 1
			questLocation[i] = "Icecrown"
			i = i + 1
			questLocation[i] = "Storm Peaks"
			i = i + 1
			questLocation[i] = "Wintergrasp"
		end

		if unitLevel == 80 then
			i = i + 1
			questLocation[i] = "nowhere"
		end
		
		print("|cffffff00You should quest in these locations|r")
		local steps = i
		local x = 1
		 if steps <= 0 then
			steps = 1
		end
		local stepValue = ceil(255/steps)
		local y = i-1
		while x <= i do
			local hex1 = convertNum(x, stepValue)
			local hex2 = convertNum(y, stepValue)
			print("|cff" .. hex1 .. hex2 .. "00" .. x .. ": " .. questLocation[x] .. "|r")
			x = x + 1
			y = y - 1
		end
	end
end)


--============================================================
--inputs all the collected values into the frames
local function draw(player_xp_type)
	Xphud_Status_bar:SetValue((unitXp/maxXp)*100)
	local restpercent = 0
	local percentvalue = (unitXp/maxXp) * 100
	experienceA:SetPoint("TOPLEFT", 15, -15)
	experienceA:SetFormattedText("Experience: ")
	
	experience1:SetPoint("TOPRIGHT", -15, -15)
	if xpExhaustion then
		experience1:SetTextColor(0.3, 0.52, 0.9, 1.0)
		Xphud_Status_bar:SetStatusBarColor(0.3, 0.52, 0.9, 1.0)
	else
		experience1:SetTextColor(0.788, 0.259, 0.992, 1.0)
		Xphud_Status_bar:SetStatusBarColor(0.788, 0.259, 0.992, 1.0)
	end
	experience1:SetFormattedText(unitXp .. " / " .. maxXp .. " / " .. ceil(percentvalue) .. "%%")

	experienceB:SetPoint("TOPLEFT", 15, -30)
	experienceB:SetFormattedText("Rest XP:  ")

	experience2:SetPoint("TOPRIGHT", -15, -30)
	experience2:SetTextColor(1, 0, 0, 1.0)
	experience2:SetFormattedText("None")
	if xpExhaustion then
			restpercent = ceil((xpExhaustion / maxXp) * 100)
		if (xpExhaustion + unitXp) >=  maxXp then
			experience2:SetTextColor(0.0, 1.0, 0.0, 1.0)
			experience2:SetFormattedText(xpExhaustion .. " / " .. restpercent .. "%%")
		else
			experience2:SetTextColor(1.0, 1.0, 0.0, 1.0)
			experience2:SetFormattedText(xpExhaustion .. " / " .. restpercent .. "%%")
		end
	else	
		experience2:SetFormattedText("None")
	end

	experienceC:SetPoint("TOPLEFT", 15, -45)
	experienceC:SetFormattedText("Kills to Level/Exhaustion: ")
	
	if xpExhaustion ~= nil and (oldrestxp-xpExhaustion) > 0 then
		restXpAmt =xpExhaustion/(oldrestxp-xpExhaustion)
	end
	if restXpAmt == nil or xpExhaustion == nil then restXpAmt = 0 end;
	
	experience3:SetPoint("TOPRIGHT", -15, -45)
	experience3:SetFormattedText("|cffa335ee" .. killToLevel(player_xp_type, 1) .. "|r / |cff00ccff" .. ceil(restXpAmt) .. "|r")
	oldrestxp 		= xpExhaustion
end

--=============================================================
--updates variables when called
local function updateVariables(x)
	if x == "playerxp" then
		unitXp			= UnitXP("player")
		maxXp			= UnitXPMax("player")
		restState		= GetRestState()
		xpDisabled		= IsXPUserDisabled()
		petXp			= GetPetExperience()
		xpExhaustion	= GetXPExhaustion()
		draw(x)
	elseif x == "exhaustxp" then
		restState		= GetRestState()
		xpExhaustion	= GetXPExhaustion()
		draw(x)
	end
end

--=============================================================
--Updates frames when XP is gained
local xpUpdate = CreateFrame("FRAME", "FooAddonFrame");
xpUpdate:RegisterEvent("PLAYER_XP_UPDATE");
local function eventHandler(self, event, ...)
	updateVariables("playerxp")
end

xpUpdate:SetScript("OnEvent", eventHandler);
--=============================================================
--Fires when the player's rest state or amount of rested XP changes
local updateExhaust = CreateFrame("FRAME", "FooAddonFrame");
updateExhaust:RegisterEvent("UPDATE_EXHAUSTION");
local function eventHandler(self, event, ...)
	xpExhaustion = GetXPExhaustion()
	state, name, multiplier	= GetRestState()
	if xpExhaustion == nil then xpExhaustion = 0 end;
	if oldrestxp == nil then oldrestxp = 0 end;
	if name == "Rested" and oldrestxp < xpExhaustion then
		oldrestxp = xpExhaustion
		updateVariables("exhaustxp")
	end
end

updateExhaust:SetScript("OnEvent", eventHandler);

--=============================================================
--Updates frames when player enters world
local enterWorld = CreateFrame("FRAME", "FooAddonFrame");
enterWorld:RegisterEvent("PLAYER_ENTERING_WORLD");
local function eventHandler(self, event, ...)
	updateVariables()
	draw()
end
enterWorld:SetScript("OnEvent", eventHandler);
--======================================
--slash commands
SLASH_XPHUD1 = '/xphud';
 local function handler(msg, editbox)
    if msg == 'reset' then
        print("|cffff0000XpHud location reset.|r")
		XpHudFrame:ClearAllPoints()
		XpHudFrame:SetPoint("CENTER")
    elseif msg == 'hide' then
        print("|cffff0000XpHud Hidden|r")
		XpHudFrame:Hide()
    elseif msg == 'show' then
        print("|cffff0000XpHud Shown|r")
		XpHudFrame:Show()
    elseif msg == 'help' then
		print("|cffbf65e3..--====List of commands for XpHud====--..|r")
		print("|cffffff00/xphud reset|r - Puts the addon back to the center.")
		print("|cffffff00/xphud hide|r - Hides the addon.")
		print("|cffffff00/xphud show|r - Shows the addon.")
		print("|cffffff00/xphud intro|r - Shows information about the addon.")
    elseif msg == 'intro' then
		print("|cffffff00..--====Thank you for downloading!====--..")
		print("|cffffff00-When the experience is Purple, you have no rest xp. Blue when you do.")
		print("|cffffff00-When the rest experience is green, you have enough to level you up.")
		print("|cffffff00-When you kill something or hand in a quest and ultimately gain experience, 'Kills to level' will show how much source experience you need to level up, and run out of rest experience.")
		print("|cffffff00-Left clicking on the frame will show you the places you should be questing in.")
		print("|cffffff00-Right click dragging moves the frame to the position you want")
		print("|cffffff00")
	else print("|cff808080type '/xphud help' for a list of commands|r")
    end
 end
 SlashCmdList["XPHUD"] = handler;