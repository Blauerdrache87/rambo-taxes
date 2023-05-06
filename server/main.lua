local QBCore = exports['qb-core']:GetCoreObject()
local Day = os.date("%A")
local Time = Config.TaxDay
local TaxStatus = 'Not Started'
local Disbursement = 'Not Started'

QBCore.Commands.Add('runtax', 'Help Text', {}, false, function(source, args)
    local players = getAllPlayers()
            for k, v in pairs(players) do
                calculateVehicleAssetFees(v)
            end
end)

CreateThread(function()
    while TaxStatus == 'Not Started' do
        if Day == Config.TaxDay then
            local isPaid = MySQL.Sync.fetchScalar('SELECT paid FROM taxes')
            print(isPaid)
            if tonumber(isPaid) == 1 then return end
            TaxStatus = 'In Progress'
            local players = getAllPlayers()
            for k, v in pairs(players) do
                calculateVehicleAssetFees(v)
            end
            MySQL.Async.execute('UPDATE taxes SET paid = @isPaid', {["@isPaid"] = 1})
        elseif Day ~= Config.TaxDay then
            TaxStatus = 'In Progress'
            MySQL.Async.execute('UPDATE taxes SET paid = @isPaid', {["@isPaid"] = 0})
        else return end
        Wait(0)
    end
end)

-- CreateThread(function()
--     while Disbursement == 'Not Started' do 
--         if Day == Config.DisbursementDay then
--             Disbursement = 'In Progress'
--             local TaxBalance = exports['qb-management']:GetAccount('State of San Andreas')
--             for k, v in pairs(Config.TaxRecievers) do 
--                 local payAmount = TaxBalance * v
--                 exports['qb-management']:AddMoney(k, payAmount)
--                 exports['qb-management']:RemoveMoney('State of San Andreas', payAmount)
--                 TriggerEvent('qb-log:server:CreateLog', 'bossmenu', 'Tax Disbursement', 'green', '**'..k..'** has received **$'..payAmount..'** from the tax disbursement.', false)
--             end
--         else return end
--         Wait(0)
--     end
-- end)

function getAllPlayers()
    local players = {}
    local result = MySQL.query.await('SELECT citizenid FROM players')
    for k, v in pairs(result) do
        table.insert(players, v.citizenid)
    end
    return players
end

function calculateVehicleAssetFees(citizenID)
    local taxBills = {}
    local lateFee = Config.LateFee

    local currentBills = MySQL.query.await('SELECT * FROM gksphone_invoices WHERE citizenid = @citizenid AND sender = @sender', {['@citizenid'] = citizenID, ['@sender'] = "govt"})
    local currentBillPlates = {}
    for k, v in pairs(currentBills) do
        local currentAmount = v.amount
        local newAmount = currentAmount + lateFee
        local plate = v.plate
        table.insert(currentBillPlates, plate)
        MySQL.update('UPDATE gksphone_invoices SET amount = @newAmount WHERE citizenid = @citizenid AND sender = @sender AND plate = @plate', {['@citizenid'] = citizenID, ['@sender'] = "govt", ['@newAmount'] = newAmount, ['@plate'] = plate})
    end

    local result = MySQL.query.await('SELECT vehicle, plate FROM player_vehicles WHERE citizenid = @citizenid', {['@citizenid'] = citizenID})

    for k, v in pairs(result) do
        if not table_contains(currentBillPlates, v.plate) then
            model = string.lower(v.vehicle)
            if QBCore.Shared.Vehicles[model] then
                local vehicleFee = QBCore.Shared.Vehicles[v.vehicle]["price"] * Config.VehicleTaxRate
                table.insert(taxBills, {citizenID = citizenID, amount = vehicleFee, label = "Asset Fee for "..QBCore.Shared.Vehicles[v.vehicle].name, plate = v.plate})
            else
                print('[srp-taxes]: VEHICLE MISSING PRICE IN VEHICLES.lua')
            end
        end
    end

    for k, v in pairs(taxBills) do
        sendVehicleTaxBill(v.citizenID, v.amount, v.label, v.plate)
    end
end

function table_contains(tbl, x)
    found = false
    for _, v in pairs(tbl) do
        if v == x then 
            found = true 
        end
    end
    return found
end

function sendVehicleTaxBill(citizenID, amount, label, plate)
    MySQL.Async.execute('INSERT INTO gksphone_invoices (citizenid, amount, society, sender, sendercitizenid, label, plate) VALUES (@citizenid, @amount, @society, @sender, @sendercitizenid, @label, @plate)'
        , {
        ['@citizenid'] = citizenID,
        ['@amount'] = amount,
        ['@society'] = "State of San Andreas",
        ['@sender'] = "govt",
        ['@sendercitizenid'] = "GOVTXXX",
        ['@label'] = label,
        ['@plate'] = plate
    })

end

function isVehicleTaxPaid(plate)
    local result = MySQL.query.await('SELECT * FROM gksphone_invoices WHERE plate = @plate', {['@plate'] = plate})
    if result[1] ~= nil then
        return false
    else
        return true
    end
end exports('isVehicleTaxPaid', isVehicleTaxPaid)