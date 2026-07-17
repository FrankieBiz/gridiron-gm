--!strict
-- Shared visual tokens (matches the playbook's field-green + pylon-orange look).

local Theme = {
	field = Color3.fromRGB(16, 30, 26),
	field2 = Color3.fromRGB(26, 52, 45),
	field3 = Color3.fromRGB(11, 21, 18),
	panel = Color3.fromRGB(30, 58, 50),
	flag = Color3.fromRGB(232, 92, 34),
	flagDeep = Color3.fromRGB(178, 62, 18),
	chalk = Color3.fromRGB(244, 246, 243),
	chalkSoft = Color3.fromRGB(150, 172, 162),
	gold = Color3.fromRGB(233, 182, 62),
	green = Color3.fromRGB(74, 168, 120),
	line = Color3.fromRGB(46, 70, 61),
	-- background gradient (top -> bottom)
	bgTop = Color3.fromRGB(22, 40, 34),
	bgBottom = Color3.fromRGB(9, 17, 14),
	-- subtle light edge for strokes
	stroke = Color3.fromRGB(255, 255, 255),
	strokeT = 0.9,
}

Theme.font = {
	display = Enum.Font.GothamBlack,
	bold = Enum.Font.GothamBold,
	medium = Enum.Font.GothamMedium,
	body = Enum.Font.Gotham,
}

-- "#RRGGBB" -> Color3
function Theme.hex(hex: string): Color3
	local r = tonumber(hex:sub(2, 3), 16) or 255
	local g = tonumber(hex:sub(4, 5), 16) or 255
	local b = tonumber(hex:sub(6, 7), 16) or 255
	return Color3.fromRGB(r, g, b)
end

-- Dev-trait accent (normal/star/superstar).
function Theme.devColor(trait: string?): Color3
	if trait == "superstar" then
		return Theme.flag
	elseif trait == "star" then
		return Theme.gold
	end
	return Theme.chalkSoft
end

-- Overall-rating color ramp.
function Theme.ovrColor(ovr: number): Color3
	if ovr >= 85 then
		return Theme.gold
	elseif ovr >= 75 then
		return Theme.chalk
	end
	return Theme.chalkSoft
end

return Theme
