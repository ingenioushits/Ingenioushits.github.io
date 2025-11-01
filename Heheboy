local placeId = game.PlaceId

local scripts = {
    [109983668079237] = "https://raw.githubusercontent.com/ingenioushits/Spawner/refs/heads/main/Steal-A-Brainrot-spawner.lua", -- Steal-A-Brainrot
    [7709344486]      = "https://raw.githubusercontent.com/ingenioushits/Spawner/refs/heads/main/Steal-A-Brainrot-spawner.lua", -- Steal-A-Brainrot
    [920587237]       = "https://raw.githubusercontent.com/ingenioushits/Spawner/refs/heads/main/Adopt-Me-Spawner.lua"           -- Adopt Me
}

if scripts[placeId] then
    loadstring(game:HttpGet(scripts[placeId], true))()
else
    warn("No script configured for this PlaceId: " .. placeId)
end
