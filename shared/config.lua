Config = {}

Config.VehicleTaxRate = 0.02 -- 5% of the vehicle price

Config.LateFee = 300 -- 300$ late fee

Config.TaxDay = "Monday" -- Day of the week that taxes are due

Config.DisbursementDay = "Friday" -- Day of the week that taxes are disbursed

Config.TaxRecievers = {
    ["police"] = 0.33, -- 33% of the taxes go to the police
    ["ambulance"] = 0.33, -- 33% of the taxes go to the ambulance
    ["doj"] = 0.33, -- 33% of the taxes go to the DOJ
}