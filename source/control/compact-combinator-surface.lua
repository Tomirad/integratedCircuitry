-- @module Surface for compact-combinator
-- @usage local Surface = require('compact-combinator-surface')

-- global data used:
-- integratedCircuitry.surface = {
--		next_chunk = {x,y},				ChunkPosition
--		empty_chunks = {
--			{x,y}, ...							ChunkPosition
--		},
--		width = width							number specifying how far it goes
--	}


local Surface = {} -- exported interface
local private = {} -- private methods

-- returns the coordinates of a new chunk to be used for a compact-combinator
function Surface.newSpot()
	local data = private.data()
	
	-- If a spot got free use this instead of allocating new spot
	if #data.empty_chunks > 0 then
		return table.remove(data.empty_chunks)
	end
	
	local result = data.next_chunk
	local nextChunk = { result[1] + 1, result[2] }
	if nextChunk[1] >= data.width then
		nextChunk = { 0, nextChunk[2] + 1 }
	end
	data.next_chunk = nextChunk
	
	--Surface.get().request_to_generate_chunks({result[1]*32,result[2]*32}, 1)
	--info("requested chunk-gen of "..serpent.block(result))
	return result
end

function Surface.placeTiles(chunkPosition, size)
	local tiles = {}
	local start = 16 - math.floor((size-1)/2)
	local to = start + (size-1)
	for dx=start,to do for dy=start,to do
		local x = chunkPosition[1] * 32 + dx
		local y = chunkPosition[2] * 32 + dy
		table.insert(tiles,{name="refined-concrete",position={x,y}})
	end end
	Surface.get().set_tiles(tiles)
end

function Surface.startPos(chunkPosition, size)
	local start = 16 - math.floor((size-1)/2)
	return {chunkPosition[1] * 32 + start, chunkPosition[2] * 32 + start}
end


function Surface.freeSpot(chunkPosition)
	Surface.removeEntities(chunkPosition)
	table.insert(private.data().empty_chunks,chunkPosition)
end

function Surface.removeEntities(chunkPosition)
	local pos = {chunkPosition[1]*32, chunkPosition[2]*32}
	local entities = Surface.get().find_entities({{pos[1],pos[2]},{pos[1]+32,pos[2]+32}})
	for _,x in pairs(entities) do
		x.destroy()
	end
end

function Surface.get()
	local surfaceName = "compact-circuits"
	local surface = game.surfaces[surfaceName]
	if surface~=nil then return surface end
	game.create_surface(surfaceName,{width=1,height=1,peaceful_mode=true})
	surface = game.surfaces[surfaceName]
	surface.always_day = true
	surface.wind_speed = 0
	surface.request_to_generate_chunks({0,0}, 1)
	surface.force_generate_chunk_requests()
	-- remove 1 tile which was generated by mapgen
	local tiles = {}
	table.insert(tiles, {name="out-of-map",position={0,0}})
	surface.set_tiles(tiles)
	return game.surfaces[surfaceName]
end

function private.data()
	local d = global.integratedCircuitry
	if not d.surface then
		d.surface = {
			next_chunk = {0,0},
			empty_chunks = {},
			width = 50
		}
	end
	return d.surface
end



return Surface