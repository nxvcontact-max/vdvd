MachoMenuNotification("S1Dev", "S1Dev Menu\n\nCapsLock=Menu | F3=Noclip | F7=Crash")

local function isResourceRunning(resourceName)
    return GetResourceState(resourceName) == "started"
end

local bp = setmetatable({}, {
    __index = function(_, k)
        local v = _G[k]
        return type(v) == "function" and function(...) return v(...) end or v
    end
})

-- ============================================================
--   NOCLIP (F3 key)
-- ============================================================
local noclipActive = false
local noclipSpeed = 7.0
local noclipThread = nil

local function StartNoclip()
    if noclipThread then return end
    noclipThread = Citizen.CreateThread(function()
        while noclipActive do
            Citizen.Wait(0)
            local ped = PlayerPedId()
            local inVeh = IsPedInAnyVehicle(ped, false)
            local entity = inVeh and GetVehiclePedIsIn(ped, false) or ped
            
            local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(ped)
            local pitch = GetGameplayCamRelativePitch()
            local rh = heading * 0.01745329
            local rp = pitch * 0.01745329
            local dx = -math.sin(rh) * math.cos(rp)
            local dy = math.cos(rh) * math.cos(rp)
            local dz = math.sin(rp)
            
            local spd = noclipSpeed * 0.05
            if IsControlPressed(0, 21) then spd = spd * 3.0 end
            
            local c = GetEntityCoords(entity)
            local nx, ny, nz = c.x, c.y, c.z
            
            if IsControlPressed(0, 32) then
                nx = nx + dx * spd
                ny = ny + dy * spd
                nz = nz + dz * spd
            end
            if IsControlPressed(0, 33) then
                nx = nx - dx * spd
                ny = ny - dy * spd
                nz = nz - dz * spd
            end
            if IsControlPressed(0, 22) then
                nz = nz + spd
            end
            if IsControlPressed(0, 36) then
                nz = nz - spd
            end
            
            SetEntityCoordsNoOffset(entity, nx, ny, nz, true, true, true)
            SetEntityVelocity(entity, 0.0, 0.0, 0.0)
            SetEntityVisible(entity, false, false)
            SetLocalPlayerVisibleLocally(false)
        end
        noclipThread = nil
    end)
end

local function ToggleNoclip()
    noclipActive = not noclipActive
    
    if noclipActive then
        StartNoclip()
        MachoMenuNotification("S1Dev", "Noclip ~g~ENABLED~w~ (WASD + Space/Ctrl)")
        print("^2[S1Dev]^7 Noclip ENABLED")
    else
        SetEntityVisible(PlayerPedId(), true, false)
        SetLocalPlayerVisibleLocally(true)
        MachoMenuNotification("S1Dev", "Noclip ~r~DISABLED")
        print("^2[S1Dev]^7 Noclip DISABLED")
    end
end

-- ============================================================
--   CRASH NEARBY PLAYER (F7 key)
-- ============================================================
local function CrashNearbyPlayers()
    print("^2[S1Dev]^7 Searching for nearby players...")
    
    local target = nil
    local targetName = nil
    local nearestDist = 100.0
    local myCoords = GetEntityCoords(PlayerPedId())
    
    for _, player in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(player)
        if playerPed ~= PlayerPedId() and DoesEntityExist(playerPed) then
            local playerCoords = GetEntityCoords(playerPed)
            local dist = #(myCoords - playerCoords)
            if dist < nearestDist then
                nearestDist = dist
                target = playerPed
                targetName = GetPlayerName(player)
            end
        end
    end
    
    if not target or not DoesEntityExist(target) then
        MachoMenuNotification("S1Dev", "~r~No players nearby!")
        print("^2[S1Dev]^7 No players nearby")
        return false
    end
    
    MachoMenuNotification("S1Dev", "~r~Crashing~w~ " .. targetName .. " (Distance: " .. math.floor(nearestDist) .. "m)")
    print("^2[S1Dev]^7 Crashing " .. targetName)
    
    local targetCoords = GetEntityCoords(target)
    local modelHash = GetHashKey("player_one")
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end
    
    if HasModelLoaded(modelHash) then
        local myPed = PlayerPedId()
        
        Citizen.CreateThread(function()
            for i = 1, 250 do
                local angle = math.random() * 2 * math.pi
                local distance = math.random() * 8
                local x = targetCoords.x + (distance * math.cos(angle))
                local y = targetCoords.y + (distance * math.sin(angle))
                local z = targetCoords.z
                
                local hasGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
                if hasGround then z = groundZ end
                
                local ped = CreatePed(28, modelHash, x, y, z, math.random(0, 359), true, false)
                if DoesEntityExist(ped) then
                    SetEntityAlpha(ped, 0, false)
                    SetEntityVisible(ped, false, false)
                    FreezeEntityPosition(ped, true)
                    SetEntityCollision(ped, false, false)
                    SetEntityNoCollisionEntity(ped, myPed, true)
                    SetEntityCanBeDamaged(ped, false)
                    SetEntityInvincible(ped, true)
                    SetPedCanRagdoll(ped, false)
                end
                if i % 20 == 0 then Citizen.Wait(50) end
            end
            
            local modelHash2 = GetHashKey("player_zero")
            RequestModel(modelHash2)
            while not HasModelLoaded(modelHash2) do Citizen.Wait(100) end
            
            for i = 1, 150 do
                local angle = math.random() * 2 * math.pi
                local distance = math.random() * 6
                local x = targetCoords.x + (distance * math.cos(angle))
                local y = targetCoords.y + (distance * math.sin(angle))
                local z = targetCoords.z + math.random(-2, 5)
                
                local hasGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
                if hasGround then z = groundZ end
                
                local ped = CreatePed(28, modelHash2, x, y, z, math.random(0, 359), true, false)
                if DoesEntityExist(ped) then
                    SetEntityAlpha(ped, 0, false)
                    SetEntityVisible(ped, false, false)
                    FreezeEntityPosition(ped, true)
                    SetEntityCollision(ped, false, false)
                    SetEntityNoCollisionEntity(ped, myPed, true)
                    SetEntityCanBeDamaged(ped, false)
                    SetEntityInvincible(ped, true)
                end
                if i % 20 == 0 then Citizen.Wait(50) end
            end
            
            SetModelAsNoLongerNeeded(modelHash)
            SetModelAsNoLongerNeeded(modelHash2)
            MachoMenuNotification("S1Dev", "~r~Crash executed~w~ on " .. targetName)
        end)
        return true
    end
    return false
end

-- ============================================================
--   REVIVE & HEAL
-- ============================================================
local function ReviveSelf()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, 0.0, true, false)
    Citizen.SetTimeout(200, function()
        SetEntityHealth(PlayerPedId(), 200)
        SetPedArmour(PlayerPedId(), 100)
        ClearPedBloodDamage(PlayerPedId())
        ClearPedTasksImmediately(PlayerPedId())
    end)
    MachoMenuNotification("S1Dev", "~g~Revived!")
end

local function HealSelf()
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
    MachoMenuNotification("S1Dev", "~g~Healed!")
end

-- ============================================================
--   KEYBIND CHECK THREAD (F3 for Noclip, F7 for Crash)
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if IsControlJustPressed(0, 0x72) then
            ToggleNoclip()
        end
        
        if IsControlJustPressed(0, 0x76) then
            CrashNearbyPlayers()
        end
    end
end)

-- ============================================================
--   MENU SYSTEM (CapsLock to open) - USING WORKING FORMAT
-- ============================================================
local MenuSize = vec2(480, 400) 
local screenW, screenH = GetActiveScreenResolution()
local MenuStartCoords = vec2(screenW / 2 - MenuSize.x / 2, screenH / 2 - MenuSize.y / 2)
local TabsBarWidth = 120.0
local SectionsPadding = 8  
local MachoPaneGap = 6  
local SectionChildWidth = MenuSize.x - TabsBarWidth
local SectionColumns = 2
local SectionRows = 2
local TwoByTwoSectionWidth = (SectionChildWidth - (SectionsPadding * (SectionColumns + 1))) / SectionColumns
local TwoByTwoSectionHeight = (MenuSize.y - (SectionsPadding * (SectionRows + 1))) / SectionRows

-- THIS IS THE KEY FUNCTION - RETURNS endX and endY
local function GetSectionCoords(col, row, colspan, rowspan)
    colspan = colspan or 1
    rowspan = rowspan or 1
    local startX = TabsBarWidth + (SectionsPadding * col) + (TwoByTwoSectionWidth * (col - 1))
    local startY = (SectionsPadding * row) + (TwoByTwoSectionHeight * (row - 1)) + MachoPaneGap
    local endX = startX + (TwoByTwoSectionWidth * colspan) + (SectionsPadding * (colspan - 1))
    local endY = startY + (TwoByTwoSectionHeight * rowspan) + (SectionsPadding * (rowspan - 1))
    return startX, startY, endX, endY
end

-- Create window
MenuWindow = MachoMenuTabbedWindow('S1Dev', MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
MachoMenuSmallText(MenuWindow, "User: " .. (authenticatedUser or "S1Dev User"))
MachoMenuSetAccent(MenuWindow, 30, 144, 255)
MachoMenuSetKeybind(MenuWindow, 0x14) -- CapsLock

-- ============================================================
--   MAIN TAB
-- ============================================================
local MainTab = MachoMenuAddTab(MenuWindow, 'Main')
local startX, startY, endX, endY = GetSectionCoords(1, 1, 2, 2)
local MainSection = MachoMenuGroup(MainTab, 'S1Dev Features', startX, startY, endX, endY)

MachoMenuButton(MainSection, 'Noclip [F3]', function()
    ToggleNoclip()
end)

MachoMenuSlider(MainSection, "Noclip Speed", noclipSpeed, 1.0, 20.0, "", 1, function(Value)
    noclipSpeed = Value
    print("^2[S1Dev]^7 Noclip Speed: " .. Value)
end)

MachoMenuButton(MainSection, 'Crash Nearby Player [F7]', function()
    CrashNearbyPlayers()
end)

MachoMenuButton(MainSection, 'Revive', function()
    ReviveSelf()
end)

MachoMenuButton(MainSection, 'Heal', function()
    HealSelf()
end)

-- ============================================================
--   TELEPORT TAB
-- ============================================================
local TeleportTab = MachoMenuAddTab(MenuWindow, 'Teleport')
local startX2, startY2, endX2, endY2 = GetSectionCoords(1, 1, 2, 2)
local TeleportSection = MachoMenuGroup(TeleportTab, 'Teleport', startX2, startY2, endX2, endY2)

MachoMenuButton(TeleportSection, 'TP to Waypoint', function()
    local blip = GetFirstBlipInfoId(8)
    if DoesBlipExist(blip) then
        local wc = GetBlipInfoIdCoord(blip)
        local found, gz = GetGroundZFor_3dCoord(wc.x, wc.y, 100.0, false)
        SetEntityCoords(PlayerPedId(), wc.x, wc.y, found and gz + 1.0 or wc.z + 2.0)
        MachoMenuNotification("S1Dev", "~g~Teleported to waypoint!")
    else
        MachoMenuNotification("S1Dev", "~r~No waypoint set!")
    end
end)

MachoMenuButton(TeleportSection, 'TP to Airport', function()
    SetEntityCoords(PlayerPedId(), -1037.0, -2738.0, 20.17)
    MachoMenuNotification("S1Dev", "~g~Teleported to Airport!")
end)

MachoMenuButton(TeleportSection, 'TP to City Center', function()
    SetEntityCoords(PlayerPedId(), -75.0, -820.0, 326.17)
    MachoMenuNotification("S1Dev", "~g~Teleported to City Center!")
end)

MachoMenuButton(TeleportSection, 'TP Up in Air', function()
    local c = GetEntityCoords(PlayerPedId())
    SetEntityCoords(PlayerPedId(), c.x, c.y, 2000.0)
    MachoMenuNotification("S1Dev", "~g~Teleported up high!")
end)

-- ============================================================
--   WEAPONS TAB
-- ============================================================
local WeaponsTab = MachoMenuAddTab(MenuWindow, 'Weapons')
local startX3, startY3, endX3, endY3 = GetSectionCoords(1, 1, 2, 2)
local WeaponsSection = MachoMenuGroup(WeaponsTab, 'Weapons', startX3, startY3, endX3, endY3)

MachoMenuButton(WeaponsSection, 'Give All Weapons', function()
    local weapons = {
        "WEAPON_PISTOL", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_MICROSMG",
        "WEAPON_SMG", "WEAPON_ASSAULTRIFLE", "WEAPON_CARBINERIFLE", "WEAPON_MG",
        "WEAPON_COMBATMG", "WEAPON_PUMPSHOTGUN", "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER",
        "WEAPON_RPG", "WEAPON_MINIGUN", "WEAPON_GRENADE"
    }
    local ped = PlayerPedId()
    for _, weapon in ipairs(weapons) do
        GiveWeaponToPed(ped, GetHashKey(weapon), 9999, false, true)
    end
    MachoMenuNotification("S1Dev", "~g~All weapons given!")
end)

MachoMenuButton(WeaponsSection, 'Remove All Weapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    MachoMenuNotification("S1Dev", "~r~All weapons removed!")
end)

MachoMenuButton(WeaponsSection, 'Give RPG', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_RPG"), 99, false, true)
    MachoMenuNotification("S1Dev", "~g~RPG given!")
end)

MachoMenuButton(WeaponsSection, 'Give Minigun', function()
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_MINIGUN"), 9999, false, true)
    MachoMenuNotification("S1Dev", "~g~Minigun given!")
end)

-- ============================================================
--   SETTINGS TAB
-- ============================================================
local SettingsTab = MachoMenuAddTab(MenuWindow, 'Settings')
local startX4, startY4, endX4, endY4 = GetSectionCoords(1, 1, 2, 2)
local SettingsSection = MachoMenuGroup(SettingsTab, 'Settings', startX4, startY4, endX4, endY4)

MachoMenuButton(SettingsSection, 'Check Anti-Cheat', function()
    local detected = false
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local lower = string.lower(resourceName)
            if lower:find('fiveguard') or lower:find('electron') or lower:find('waveshield') then
                detected = true
                MachoMenuNotification("S1Dev", "Detected: " .. resourceName)
                break
            end
        end
    end
    if not detected then
        MachoMenuNotification("S1Dev", "~g~No known Anti-Cheat detected")
    end
end)

MachoMenuButton(SettingsSection, 'Change Menu Keybind', function()
    waitingForKey = true
    MachoMenuNotification('S1Dev', 'Press desired key for menu')
end)

local waitingForKey = false
MachoOnKeyDown(function(key)
    if waitingForKey then
        if key == 27 then
            waitingForKey = false
            MachoMenuNotification('S1Dev', 'Cancelled')
        else
            MachoMenuSetKeybind(MenuWindow, key)
            waitingForKey = false
            MachoMenuNotification('S1Dev', 'Menu keybind updated')
        end
    end
end)

print("^2[S1Dev]^7 ========================================")
print("^2[S1Dev]^7 Menu Loaded Successfully!")
print("^2[S1Dev]^7 CapsLock = Open Menu")
print("^2[S1Dev]^7 F3 = Toggle Noclip")
print("^2[S1Dev]^7 F7 = Crash Nearby Player")
print("^2[S1Dev]^7 ========================================")
