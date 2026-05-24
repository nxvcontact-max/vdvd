MachoMenuNotification("S1Dev", "S1Dev Menu\n\nCapsLock=Menu | F3=Safe Noclip | F7=Crash")

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
--   SAFE NOCLIP (Anti-Ban - RECOMMENDED)
-- ============================================================
local safeNoclipActive = false
local safeNoclipSpeed = 3.0
local noclipSpeed = 3.0

local originalGetEntityCoords = GetEntityCoords
local originalSetEntityCoords = SetEntityCoords
local originalGetEntityVelocity = GetEntityVelocity

local function HookedGetEntityCoords(entity)
    if safeNoclipActive and entity == PlayerPedId() then
        return _G.fakeCoords or originalGetEntityCoords(entity)
    end
    return originalGetEntityCoords(entity)
end

local function HookedSetEntityCoords(entity, x, y, z, xAxis, yAxis, zAxis, clearArea)
    if safeNoclipActive and entity == PlayerPedId() then
        _G.fakeCoords = vector3(x, y, z)
        return
    end
    return originalSetEntityCoords(entity, x, y, z, xAxis, yAxis, zAxis, clearArea)
end

local function HookedGetEntityVelocity(entity)
    if safeNoclipActive and entity == PlayerPedId() then
        return 0.0, 0.0, 0.0
    end
    return originalGetEntityVelocity(entity)
end

rawset(_G, 'GetEntityCoords', HookedGetEntityCoords)
rawset(_G, 'SetEntityCoords', HookedSetEntityCoords)
rawset(_G, 'GetEntityVelocity', HookedGetEntityVelocity)

local safeNoclipThread = nil

function ToggleSafeNoclip()
    safeNoclipActive = not safeNoclipActive
    
    if safeNoclipActive then
        local ped = PlayerPedId()
        _G.fakeCoords = originalGetEntityCoords(ped)
        MachoMenuNotification("S1Dev", "Safe Noclip ~g~ACTIVE~w~ (Anti-Ban)")
        print("^2[S1Dev]^7 Safe Noclip ENABLED")
        
        if safeNoclipThread then return end
        safeNoclipThread = Citizen.CreateThread(function()
            while safeNoclipActive do
                Citizen.Wait(0)
                local ped = PlayerPedId()
                local speed = safeNoclipSpeed
                if IsControlPressed(0, 21) then speed = speed * 3 end
                
                local camRot = GetGameplayCamRot(2)
                local lastCoords = _G.fakeCoords or originalGetEntityCoords(ped)
                
                local forward = vector3(
                    -math.sin(math.rad(camRot.z)) * math.cos(math.rad(camRot.x)),
                    math.cos(math.rad(camRot.z)) * math.cos(math.rad(camRot.x)),
                    math.sin(math.rad(camRot.x))
                )
                local right = vector3(
                    math.cos(math.rad(camRot.z)),
                    math.sin(math.rad(camRot.z)),
                    0.0
                )
                
                if IsDisabledControlPressed(0, 32) then lastCoords = lastCoords + forward * speed end
                if IsDisabledControlPressed(0, 33) then lastCoords = lastCoords - forward * speed end
                if IsDisabledControlPressed(0, 30) then lastCoords = lastCoords + right * speed end
                if IsDisabledControlPressed(0, 34) then lastCoords = lastCoords - right * speed end
                if IsDisabledControlPressed(0, 22) then lastCoords = lastCoords + vector3(0, 0, speed) end
                if IsDisabledControlPressed(0, 36) then lastCoords = lastCoords - vector3(0, 0, speed) end
                
                _G.fakeCoords = lastCoords
                
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    originalSetEntityCoords(veh, lastCoords.x, lastCoords.y, lastCoords.z, true, true, true, false)
                else
                    originalSetEntityCoords(ped, lastCoords.x, lastCoords.y, lastCoords.z, true, true, true, false)
                end
            end
            safeNoclipThread = nil
        end)
    else
        _G.fakeCoords = nil
        MachoMenuNotification("S1Dev", "Safe Noclip ~r~OFF")
        print("^2[S1Dev]^7 Safe Noclip DISABLED")
    end
end

-- ============================================================
--   CRASH NEARBY PLAYER (F7 key)
-- ============================================================
local function CrashNearbyPlayers()
    print("^2[S1Dev]^7 Searching for nearby players...")
    
    -- Find nearest player
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
--   KEYBIND CHECK USING DIFFERENT METHOD
--   Using RegisterCommand and IsControlPressed with delays
-- ============================================================

-- F3 key (0x72) for Safe Noclip
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(50) -- Check every 50ms instead of 0
        -- Use IsControlJustReleased to avoid menu conflicts
        if IsControlJustReleased(0, 0x72) or IsDisabledControlJustPressed(0, 0x72) then
            ToggleSafeNoclip()
        end
        
        -- F7 key (0x76) for Crash
        if IsControlJustReleased(0, 0x76) or IsDisabledControlJustPressed(0, 0x76) then
            CrashNearbyPlayers()
        end
    end
end)

-- Also register commands as backup
RegisterCommand("noclip", function()
    ToggleSafeNoclip()
end, false)

RegisterCommand("crash", function()
    CrashNearbyPlayers()
end, false)

-- ============================================================
--   MENU SYSTEM (CapsLock to open)
-- ============================================================
local MenuSize = vec2(480, 420) 
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

local function GetSectionCoords(col, row, colspan, rowspan)
    colspan = colspan or 1
    rowspan = rowspan or 1
    local startX = TabsBarWidth + (SectionsPadding * col) + (TwoByTwoSectionWidth * (col - 1))
    local startY = (SectionsPadding * row) + (TwoByTwoSectionHeight * (row - 1)) + MachoPaneGap
    return startX, startY
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
local MainSection = MachoMenuGroup(MainTab, 'S1Dev Features', GetSectionCoords(1, 1))

-- Safe Noclip (Anti-Ban - RECOMMENDED)
MachoMenuButton(MainSection, 'Safe Noclip [F3] (Anti-Ban)', function()
    ToggleSafeNoclip()
end)

-- Noclip Speed Slider
MachoMenuSlider(MainSection, "Noclip Speed", noclipSpeed, 0, 25, "", 1, function(Value)
    noclipSpeed = Value
    safeNoclipSpeed = Value
    print("^2[S1Dev]^7 Noclip Speed: " .. Value)
end)

-- Crash button
MachoMenuButton(MainSection, 'Crash Nearby Player [F7]', function()
    CrashNearbyPlayers()
end)

-- Revive & Heal
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
local TeleportSection = MachoMenuGroup(TeleportTab, 'Teleport', GetSectionCoords(1, 1))

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
local WeaponsSection = MachoMenuGroup(WeaponsTab, 'Weapons', GetSectionCoords(1, 1))

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
local SettingsSection = MachoMenuGroup(SettingsTab, 'Settings', GetSectionCoords(1, 1))

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
print("^2[S1Dev]^7 F3 = Safe Noclip (Anti-Ban)")
print("^2[S1Dev]^7 F7 = Crash Nearby Player")
print("^2[S1Dev]^7 Also available: /noclip and /crash commands")
print("^2[S1Dev]^7 ========================================")
