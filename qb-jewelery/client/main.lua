local QBCore = exports['qb-core']:GetCoreObject()
local firstAlarm = false
local smashing = false
local safecracked = false

-- Functions
local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end
DeleteEntity(Safe)
end)

local function loadParticle()
	if not HasNamedPtfxAssetLoaded("scr_jewelheist") then RequestNamedPtfxAsset("scr_jewelheist") end
    while not HasNamedPtfxAssetLoaded("scr_jewelheist") do Wait(0) end
    SetPtfxAssetNextCall("scr_jewelheist")
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(3)
    end
end

local function validWeapon()
    local ped = PlayerPedId()
    local pedWeapon = GetSelectedPedWeapon(ped)

    for k, v in pairs(Config.WhitelistedWeapons) do
        if pedWeapon == k then
            return true
        end
    end
    return false
end

local function IsWearingHandshoes()
    local armIndex = GetPedDrawableVariation(PlayerPedId(), 3)
    local model = GetEntityModel(PlayerPedId())
    local retval = true
    if model == `mp_m_freemode_01` then
        if Config.MaleNoHandshoes[armIndex] ~= nil and Config.MaleNoHandshoes[armIndex] then
            retval = false
        end
    else
        if Config.FemaleNoHandshoes[armIndex] ~= nil and Config.FemaleNoHandshoes[armIndex] then
            retval = false
        end
    end
    return retval
end

local function smashVitrine(k)
    if validWeapon() then
        local animDict = "missheist_jewel"
        local animName = "smash_case"
        local ped = PlayerPedId()
        local plyCoords = GetOffsetFromEntityInWorldCoords(ped, 0, 0.6, 0)
        local pedWeapon = GetSelectedPedWeapon(ped)
        if math.random(1, 100) <= 80 and not IsWearingHandshoes() then
            TriggerServerEvent("evidence:server:CreateFingerDrop", plyCoords)
        elseif math.random(1, 100) <= 5 and IsWearingHandshoes() then
            TriggerServerEvent("evidence:server:CreateFingerDrop", plyCoords)
            QBCore.Functions.Notify("You've left a fingerprint on the glass", "error")
        end
        smashing = true
        QBCore.Functions.Progressbar("smash_vitrine", "Looting case", Config.WhitelistedWeapons[pedWeapon]["timeOut"], false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            local camId = '31 | 32 | 33 | 34'
            exports['ps-dispatch']:VangelicoRobbery(camId)
            TriggerServerEvent('qb-jewellery:server:setVitrineState', "isOpened", true, k)
            TriggerServerEvent('qb-jewellery:server:setVitrineState', "isBusy", false, k)
            TriggerServerEvent('qb-jewellery:server:vitrineReward')
            TriggerServerEvent('qb-jewellery:server:setTimeout')
            smashing = false
            TaskPlayAnim(ped, animDict, "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        end, function() -- Cancel
            TriggerServerEvent('qb-jewellery:server:setVitrineState', "isBusy", false, k)
            smashing = false
            TaskPlayAnim(ped, animDict, "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        end)
        TriggerServerEvent('qb-jewellery:server:setVitrineState', "isBusy", true, k)

        CreateThread(function()
            while smashing do
                loadAnimDict(animDict)
                TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 2, 0, 0, 0, 0 )
                Wait(500)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "breaking_vitrine_glass", 0.25)
                loadParticle()
                StartParticleFxLoopedAtCoord("scr_jewel_cab_smash", plyCoords.x, plyCoords.y, plyCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                Wait(2500)
            end
        end)
    else
        QBCore.Functions.Notify('Your weapon does not seem strong enough..', 'error')
    end
end

local ThermiteEffect = function()
    local ped = PlayerPedId()
    TriggerServerEvent('qb-jewellery:server:thermiteremove')
    RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
    while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") do Wait(50) end
    Wait(1500)
    TriggerServerEvent("qb-jewellery:server:ThermitePtfx")
    Wait(500)
    TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_intro", 8.0, 8.0, 1000, 36, 1, 0, 0, 0)
    TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 8.0, 8.0, 3000, 49, 1, 0, 0, 0)
    Wait(25000)
    ClearPedTasks(ped)
    Wait(2000)
    TriggerServerEvent('qb-doorlock:server:updateState', Config.Door1, false, false, false, true, false, false)
    QBCore.Functions.Notify("Doors Are Open! You Have 2 Minutes Before they close again", "success")
    Wait(20000)
    TriggerServerEvent('qb-doorlock:server:updateState', Config.Door1, true, true, true, false, false, true)
end

-- DOOR EVENT 1 --
RegisterNetEvent('qb-jewellery:client:door2', function()
    local item2 = QBCore.Functions.HasItem('thermite')
    if item2 then
        exports['ps-ui']:Thermite(function(success)
            if success then
                QBCore.Functions.Notify("Door Opened!", "success")
                TriggerServerEvent('qb-jewellery:server:thermiteremove')
                TriggerServerEvent('qb-doorlock:server:updateState', "vange2-vange2", false, false, false, true, false, false)
            else
                QBCore.Functions.Notify("Failed", "error")
            end
        end, 10, 5, 3) -- Time, Gridsize (5, 6, 7, 8, 9, 10), IncorrectBlocks
    else
        QBCore.Functions.Notify("You Cant Open this..", "error")
    end
end)


local PlantThermite = function()
    RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
    RequestModel("hei_p_m_bag_var22_arm_s")
    RequestNamedPtfxAsset("scr_ornate_heist")
    while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") or not HasModelLoaded("hei_p_m_bag_var22_arm_s") or not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(50) end
    local ped = PlayerPedId()
    local pos = vector4(-596.09, -283.64, 50.42, 301.38)
    SetEntityHeading(ped, pos.w)
    Wait(100)
    local rotx, roty, rotz = table.unpack(vec3(GetEntityRotation(PlayerPedId())))
    local netscene = NetworkCreateSynchronisedScene(pos.x, pos.y, pos.z, rotx, roty, rotz, 2, false, false, 1065353216, 0, 1.3)
    local bag = CreateObject(`hei_p_m_bag_var22_arm_s`, pos.x, pos.y, pos.z,  true,  true, false)
    SetEntityCollision(bag, false, true)
    local x, y, z = table.unpack(GetEntityCoords(ped))
    local thermite = CreateObject(`hei_prop_heist_thermite`, x, y, z + 0.2,  true,  true, true)
    SetEntityCollision(thermite, false, true)
    AttachEntityToEntity(thermite, ped, GetPedBoneIndex(ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
    NetworkAddPedToSynchronisedScene(ped, netscene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, netscene, "anim@heists@ornate_bank@thermal_charge", "bag_thermal_charge", 4.0, -8.0, 1)
    SetPedComponentVariation(ped, 5, 0, 0, 0)
    NetworkStartSynchronisedScene(netscene)
    Wait(5000)
    DetachEntity(thermite, 1, 1)
    FreezeEntityPosition(thermite, true)
    DeleteObject(bag)
    NetworkStopSynchronisedScene(netscene)
    CreateThread(function()
        Wait(15000)
        DeleteEntity(thermite)
    end)
end

-- Events

RegisterNetEvent('qb-jewellery:client:doorunlock', function()
    local gatecrack = QBCore.Functions.HasItem('gatecrack')
    if gatecrack then
        Wait(1200)
        exports['ps-ui']:Scrambler(function(success)
            if success then
                TriggerServerEvent('qb-jewellery:server:gatecrackremove')
                QBCore.Functions.Notify("Door Opened..", "success")
                TriggerServerEvent('qb-doorlock:server:updateState', Config.Door1, false, false, false, true, false, false)
            else
                QBCore.Functions.Notify("Failed..", "error")
            end
        end, "numeric", 30, 0) -- Type (alphabet, numeric, alphanumeric, greek, braille, runes), Time (Seconds), Mirrored (0: Normal, 1: Normal + Mirrored 2: Mirrored only )   
    else
        QBCore.Functions.Notify("You Dont Have The Item..", "error")
    end
end)

RegisterNetEvent('qb-jewellery:client:Thermite', function()
    local result = QBCore.Functions.HasItem('thermite')
        if result then 
            if math.random(1, 100) <= 85 and not IsWearingHandshoes() then
                TriggerServerEvent("evidence:server:CreateFingerDrop", GetEntityCoords(PlayerPedId()))
            end
            QBCore.Functions.TriggerCallback('qb-jewellery:server:getCops', function(cops)
                if cops >= Config.RequiredCops then
                    PlantThermite()
                    exports["memorygame"]:thermiteminigame(3, 4, 4, 120,
                    function()
                        ThermiteEffect()
                    end,
                    function()
                        QBCore.Functions.Notify("Thermite failed..", "error")
                    end)
                else
                    QBCore.Functions.Notify("Not enough police..", "error")
                end
            end)
        else
            QBCore.Functions.Notify("You are missing something..", "error", 2500)
        end
end)

RegisterNetEvent('qb-jewellery:client:ThermitePtfx', function()
    local ptfx = vector3(-596.17, -282.62, 50.32)
    RequestNamedPtfxAsset("scr_ornate_heist")
    while not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(50) end
    SetPtfxAssetNextCall("scr_ornate_heist")
    local effect = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", ptfx, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    Wait(27500)
    StopParticleFxLooped(effect, 0)
end)

RegisterNetEvent("qb-jewellery:client:ThermitePtfx", function(coords)
    if not HasNamedPtfxAssetLoaded("scr_ornate_heist") then 
        RequestNamedPtfxAsset("scr_ornate_heist") 
    end
    while not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(0) end
    SetPtfxAssetNextCall("scr_ornate_heist")
    local effect = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", coords, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    Wait(27500)
    StopParticleFxLooped(effect, 0)
end)

RegisterNetEvent('qb-jewellery:client:setVitrineState', function(stateType, state, k)
    Config.Locations[k][stateType] = state
end)

-- Threads
CreateThread(function()
    local Dealer = AddBlipForCoord(Config.JewelleryLocation["coords"]["x"], Config.JewelleryLocation["coords"]["y"], Config.JewelleryLocation["coords"]["z"])
    SetBlipSprite (Dealer, 617)
    SetBlipDisplay(Dealer, 4)
    SetBlipScale  (Dealer, 0.7)
    SetBlipAsShortRange(Dealer, true)
    SetBlipColour(Dealer, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Vangelico Jewelry")
    EndTextCommandSetBlipName(Dealer)
end)

CreateThread(function()
    for k, v in pairs(Config.Locations) do
        exports['qb-target']:AddBoxZone("JewelleryCase"..k, vector3(v.coords.x, v.coords.y, v.coords.z-1), 0.6, 1.2, {
            name = "JewelleryCase"..k,
            heading = v.coords.w,
            debugPoly = false,
            minZ = 37.65,
            maxZ = 38.35,
            }, {
                options = { 
                {
                    action = function()
                        smashVitrine(k)
                    end,
                    icon = 'fas fa-gem',
                    label = 'Smash Case',
                    canInteract = function()
                        if v["isOpened"] or v["isBusy"] then 
                            return false
                        end
                        return true
                    end,
                }
            },
            distance = 1.5,
        })
    end
    exports['qb-target']:AddBoxZone("JewelleryThermite", vector3(-595.94, -283.74, 50.32), 0.4, 0.8, {
        name = "JewelleryThermite",
        heading = 302.79,
        debugPoly = false,
        minZ = 50.25,
        maxZ = 51.35,
        }, {
            options = { 
            {
                type = "client",
                event = "qb-jewellery:client:Thermite",
                icon = 'fas fa-gem',
                label = 'Disable Security'
            }
        },
        distance = 1.5,
    })
    exports['qb-target']:AddCircleZone("Vange", vector3(-629.4028, -230.4196, 38.5506), 0.5,{ name = "vangedoor2", debugPoly = false, useZ=true, }, { options = { { type = "client", event = "qb-jewellery:client:door2", icon = "	fa fa-laptop", label = "Crack Code"}, }, distance = 1 })
    exports['qb-target']:AddCircleZone("Safe", vector3(-630.7402, -228.3227, 38.2705), 0.5,{ name = "Safe", debugPoly = false, useZ=true, }, { options = { { type = "client", event = "qb-jewelery:client:CrackSafe", icon = "fa fa-laptop", label = "Crack Safe"}, }, distance = 1 })
    exports['qb-target']:AddCircleZone("Vange2", vector3(-631.0305, -230.6305, 38.005), 0.5,{ name = "vangedoor3", debugPoly = false, useZ=true, }, { options = { { type = "client", event = "qb-jewellery:client:doorunlock", icon = "	fa fa-laptop", label = "Unlock Doors"}, }, distance = 1 })
end)

-- Safe Edit --
RegisterNetEvent('qb-jewelery:client:CrackSafe', function()
    local timehack = math.random(20, 60)
    local amount = math.random(4, 9)
    local ped = PlayerPedId()
    local stetha = QBCore.Functions.HasItem('stethascope')
    if stetha then
    if not safecracked then
    loadAnimDict("mini@safe_cracking")
    TaskPlayAnim(PlayerPedId(), "mini@safe_cracking", "dial_turn_anti_fast_1", 3.0, 3.0, -1, 49, 0, 0, 0, 0)
    SetEntityHeading(ped, Safe)
    exports['boii-chiphack']:StartGame(function(success)
        if success then
            safecracked = true
            TriggerServerEvent('qb-jewellery:server:Safe')
            ClearPedTasksImmediately(PlayerPedId())
        else
           QBCore.Functions.Notify('Failed!', 'error', 6000)
           ClearPedTasksImmediately(PlayerPedId())
        end
    end, amount, timehack) -- Made it random
else
    QBCore.Functions.Notify('Safe Already Hacked!', 'error', 6000)
end
else
    QBCore.Functions.Notify('No Stethascope!', 'error', 500)
end
end)

CreateThread(function()
    local Safe = CreateObject(GetHashKey("p_v_43_safe_s"), -631.02, -227.98, 37.06570, true,  true, true)
    FreezeEntityPosition(Safe, true)
    SetEntityHeading(Safe, 38.19)
end)