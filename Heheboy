local placeId = game.PlaceId

local scripts = {
    [109983668079237] = "https://raw.githubusercontent.com/ingenioushits/Spawner/refs/heads/main/Steal-A-Brainrot-spawner.lua",  -- Steal-A-Brainrot
    [7709344486]      = "https://raw.githubusercontent.com/ingenioushits/Spawner/refs/heads/main/Steal-A-Brainrot-spawner.lua",  -- Steal-A-Brainrot
    [920587237]       = "https://raw.githubusercontent.com/ingenioushits/Spawner/refs/heads/main/Adopt-Me-Spawner.lua",          -- Adopt Me
    [127742093697776] = "https://raw.githubusercontent.com/ingenioushits/Spawner/refs/heads/main/Plants-Vs-Brainrot-Visual.lua", -- Plants-Vs-Zombie
    [142823291]       = "https://raw.githubusercontent.com/ingenioushits/Spawner/refs/heads/main/Murder-Mystery-2-Visual.lua"    -- Murder-Mystery-2 
}

if scripts[placeId] then
    loadstring(game:HttpGet(scripts[placeId], true))()
else
    warn("No script configured for this PlaceId: " .. placeId)
end
