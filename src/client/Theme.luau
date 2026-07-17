--!strict
-- Shared visual tokens (matches the playbook's field-green + pylon-orange look).

local Theme = {
	field = Color3.fromRGB(16, 30, 26),
	field2 = Color3.fromRGB(23, 50, 42),
	field3 = Color3.fromRGB(11, 21, 18),
	flag = Color3.fromRGB(228, 87, 31),
	chalk = Color3.fromRGB(243, 245, 242),
	chalkSoft = Color3.fromRGB(159, 178, 169),
	gold = Color3.fromRGB(231, 178, 58),
	line = Color3.fromRGB(40, 60, 52),
}

-- "#RRGGBB" -> Color3
function Theme.hex(hex: string): Color3
	local r = tonumber(hex:sub(2, 3), 16) or 255
	local g = tonumber(hex:sub(4, 5), 16) or 255
	local b = tonumber(hex:sub(6, 7), 16) or 255
	return Color3.fromRGB(r, g, b)
end

return Theme
