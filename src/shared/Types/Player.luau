--!strict
-- The typed player struct the whole game shares (playbook §03).
-- Add fields as later phases call for them; keep this the single source of truth.

export type Player = {
	id: string,
	name: string,
	position: string, -- "QB" | "RB" | "WR" ...
	age: number,
	overall: number,
	speed: number,
	strength: number,
	awareness: number,
	potential: number,
	contractYears: number,
	salary: number,
	morale: number, -- add depth in Phase 6
}

return {}
