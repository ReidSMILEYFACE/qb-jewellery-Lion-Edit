local QBCore = exports['qb-core']:GetCoreObject()
local timeOut = false

-- Callback

QBCore.Functions.CreateCallback('qb-jewellery:server:getCops', function(source, cb)
	local amount = 0
    for k, v in pairs(QBCore.Functions.GetQBPlayers()) do
        if v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            amount = amount + 1
        end
    end
    cb(amount)
end)

-- Events
RegisterNetEvent('qb-jewellery:server:ThermitePtfx', function()
    TriggerClientEvent('qb-jewellery:client:ThermitePtfx', -1)
end)

RegisterNetEvent('qb-jewellery:server:setVitrineState', function(stateType, state, k)
    Config.Locations[k][stateType] = state
    TriggerClientEvent('qb-jewellery:client:setVitrineState', -1, stateType, state, k)
end)

RegisterNetEvent('qb-jewellery:server:vitrineReward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local otherchance = math.random(1, 4)
    local odd = math.random(1, 4)

    if otherchance == odd then
        local item = math.random(1, #Config.VitrineRewards)
        local amount = math.random(Config.VitrineRewards[item]["amount"]["min"], Config.VitrineRewards[item]["amount"]["max"])
        if Player.Functions.AddItem(Config.VitrineRewards[item]["item"], amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.VitrineRewards[item]["item"]], 'add')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You have to much in your pocket', 'error')
        end
    else
        local amount = math.random(2, 4)
        if Player.Functions.AddItem("10kgoldchain", amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["10kgoldchain"], 'add')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You have to much in your pocket..', 'error')
        end
    end
end)

RegisterNetEvent('qb-jewellery:server:Safe', function()
    local chance = math.random(1, 5)
    local Player = QBCore.Functions.GetPlayer(source)
    if chance == 1 then
        QBCore.Functions.Notify('You Found Nothing!', 'error', 7500)
    elseif chance == 2 then
        QBCore.Functions.Notify('You Found a Pistol!', 'success', 7500)
        Player.Functions.AddItem('weapon_pistol', 1)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["weapon_pistol"], "add")
    elseif chance == 3 then
        QBCore.Functions.Notify('You Found Some Goods', 'success', 7500)
        Player.Functions.AddItem('specialrolex', 1)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["specialrolex"], "add")
        Player.Functions.AddItem('blueusb', 1)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["blueusb"], "add")
    elseif chance == 4 then
        QBCore.Functions.Notify('You Found Cash!', 'success', 7500)
        Player.Functions.AddMoney('cash', 1500)
    elseif chance == 5 then
        QBCore.Functions.Notify('You Found Some Counterfiet Money!', 'success', 7500)
        Player.Functions.AddItem('markedbills', 35)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["markedbills"], "add")
    end
    Player.Functions.RemoveItem('stethascope', 1)
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["stethascope"], "remove")
end)

RegisterNetEvent('qb-jewellery:server:thermiteremove', function()
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.RemoveItem('thermite', 1)
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["thermite"], "remove")
end)

RegisterNetEvent('qb-jewellery:server:gatecrackremove', function()
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.RemoveItem('gatecrack', 1)
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items["gatecrack"], "remove")
end)

RegisterNetEvent('qb-jewellery:server:setTimeout', function()
    if not timeOut then
        timeOut = true
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', "jewellery", true)
        Citizen.CreateThread(function()
            Citizen.Wait(Config.Timeout)

            for k, v in pairs(Config.Locations) do
                Config.Locations[k]["isOpened"] = false
                TriggerClientEvent('qb-jewellery:client:setVitrineState', -1, 'isOpened', false, k)
                TriggerClientEvent('qb-jewellery:client:setAlertState', -1, false)
                TriggerEvent('qb-scoreboard:server:SetActivityBusy', "jewellery", false)
            end
            timeOut = false
        end)
    end
end)