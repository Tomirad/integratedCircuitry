-- @module Surface for compact-combinator
-- @usage local Surface = require('compact-combinator-surface')

-- global data used:
-- integratedCircuitry.surface = {
--		chunks = {
--			[x][y] = bool    -- true if chunk is used
--		}
--	}


local Surface = {} -- exported interface
local private = {} -- private methods

-- returns the coordinates of a new chunk to be used for a compact-combinator
function Surface.newSpot(x, y)
	local data = private.data()
	
	local c = { math.floor(x/32), math.floor(y/32) }
	if not private.isChunkUsed(c) then
		private.markChunk(c, true)
		return c
	end
	
	for x=-1,1 do for y=-1,1 do
		if math.abs(x)+math.abs(y) == 1 then
			local c2 = {c[1]+x, c[2]+y}
			if not private.isChunkUsed(c2) then
				private.markChunk(c2, true)
				return c2
			end
		end
	end end
	return nil -- could not find a free chunk nearby
end

function Surface.placeTiles(chunkPosition, size)
	local tiles = {}
	local start = 16 - math.ceil((size-1)/2)
	local to = start + (size-1)
	for dx=start,to do for dy=start,to do
		local x = chunkPosition[1] * 32 + dx
		local y = chunkPosition[2] * 32 + dy
		table.insert(tiles,{name="refined-concrete",position={x,y}})
	end end
	Surface.get().set_tiles(tiles)
end

function Surface.chunkMiddle(chunkPos)
	return {chunkPos[1] * 32 + 16, chunkPos[2] * 32 + 16}
end


function Surface.freeSpot(chunkPosition)
	Surface.removeEntities(chunkPosition)
	local size = 32
	local tiles = {}
	local start = 16 - math.ceil((size-1)/2)
	local to = start + (size-1)
	for dx=start,to do for dy=start,to do
		local x = chunkPosition[1] * 32 + dx
		local y = chunkPosition[2] * 32 + dy
		table.insert(tiles, {name="out-of-map",position={x,y}})
	end end
	Surface.get().set_tiles(tiles)
	private.markChunk(chunkPosition, false)
end

function Surface.removeEntities(chunkPosition)
	local pos = {chunkPosition[1]*32, chunkPosition[2]*32}
	local entities = Surface.get().find_entities({{pos[1],pos[2]},{pos[1]+32,pos[2]+32}})
	for _,x in pairs(entities) do
		x.destroy()
	end
end

Surface.name = "compact-circuits"
function Surface.get()
	private.init()
	return game.surfaces[Surface.name]
end

function private.init()
	local d = global.integratedCircuitry
	if not d.surface then
		d.surface = {
			chunks = {}
		}
	end
	local surface = game.surfaces[Surface.name]
	if surface~=nil then return end
	game.create_surface(Surface.name,{width=1,height=1,peaceful_mode=true})
	surface = game.surfaces[Surface.name]
	surface.always_day = true
	surface.wind_speed = 0
	surface.request_to_generate_chunks({0,0}, 1)
	surface.force_generate_chunk_requests()
	-- remove 1 tile which was generated by mapgen
	local tiles = {}
	table.insert(tiles, {name="out-of-map",position={0,0}})
	surface.set_tiles(tiles)
	surface.create_entity{name="steel-chest",position={0,0},force=game.forces.player}
end

function private.data()
	private.init()
	return global.integratedCircuitry.surface
end

function private.isChunkUsed(chunk)
	local x = chunk[1]
	local y = chunk[2]
	local data = private.data().chunks
	--info("check chunk used: "..tostring(x)..", "..tostring(y))
	return data[x] and data[x][y]
end

function private.markChunk(chunk, used)
	local x = chunk[1]
	local y = chunk[2]
	local data = private.data().chunks
	--info("mark chunk used: "..tostring(x)..", "..tostring(y)..", "..tostring(used))
	if not data[x] then data[x] = {} end
	data[x][y] = used
end

return Surface