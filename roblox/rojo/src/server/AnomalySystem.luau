--!strict
-- Stub. Step 8 turns the slice's one poster into the full catalog.
-- The first slice schedules poster_changed from the server ride script.
-- Do not add types beyond GameData.Anomalies.types.

local AnomalySystem = {}

function AnomalySystem.types(): { string }
	return { "poster_changed" }
end

return AnomalySystem
