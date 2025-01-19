--- @class SD.Money
SD.Money = {}

--- Converts MoneyType to framework-specific variant, if needed.
---@param moneyType string The original money type.
---@return string The converted money type.
local ConvertMoneyType = function(moneyType)
    if moneyType == 'money' and Framework == 'qb' or Framework == 'qbx' then
        return 'cash'
    elseif moneyType == 'cash' and Framework == 'esx' then
        return 'money'
    else
        return moneyType
    end
end

-- Internal function to dynamically select the appropriate function for adding money based on the framework.
local AddMoney = function()
    if Framework == 'esx' then
        return function(player, moneyType, amount)
            player.addAccountMoney(ConvertMoneyType(moneyType), amount)
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        return function(player, moneyType, amount)
            player.Functions.AddMoney(ConvertMoneyType(moneyType), amount)
        end
    elseif Framework == 'mythic' then
        return function(player, moneyType, amount, transactionData)
            if moneyType == "cash" then
                Wallet:Modify(player.source, math.ceil(amount))
            elseif moneyType == "bank" then
                local char = player:GetData("Character")
                local account = Banking.Accounts:GetPersonal(char:GetData("SID"))?.Balance
                Banking.Balance:Deposit(account, amount, {
                    type = "deposit",
                    title = transactionData and transactionData.title or "Transaction",
                    description = transactionData and transactionData.description or "Money added to account.",
                    transactionAccount = false,
                    data = {
                        character = char:GetData("SID"),
                    },
                })
            end
        end
    else
        return function()
            error("Unsupported framework for AddMoney.")
        end
    end
end

-- Utilize the dynamically selected function for adding money.
local AddMoneyToPlayer = AddMoney()

-- Internal function to dynamically select the appropriate function for removing money based on the framework.
local RemoveMoney = function()
    if Framework == 'esx' then
        return function(player, moneyType, amount)
            player.removeAccountMoney(ConvertMoneyType(moneyType), amount)
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        return function(player, moneyType, amount)
            player.Functions.RemoveMoney(ConvertMoneyType(moneyType), amount)
        end
    elseif Framework == 'mythic' then
        return function(player, moneyType, amount, transactionData)
            if moneyType == "cash" then
                Wallet:Modify(player.source, -math.ceil(amount))
            elseif moneyType == "bank" then
                local char = player:GetData("Character")
                local account = Banking.Accounts:GetPersonal(char:GetData("SID"))?.Balance
                Banking.Balance:Withdraw(account, amount, {
                    type = "withdraw",
                    title = transactionData and transactionData.title or "Transaction",
                    description = transactionData and transactionData.description or "Money removed from account.",
                    transactionAccount = false,
                    data = {
                        character = char:GetData("SID"),
                    },
                })
            end
        end
    else
        return function()
            error("Unsupported framework for RemoveMoney.")
        end
    end
end

-- Utilize the dynamically selected function for removing money.
local RemoveMoneyFromPlayer = RemoveMoney()

-- Internal function to dynamically select the appropriate function for getting player's funds based on the framework.
local GetPlayerFunds = function()
    if Framework == 'esx' then
        return function(player, moneyType)
            local account = player.getAccount(ConvertMoneyType(moneyType))
            return account and account.money or 0
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        return function(player, moneyType)
            return player.PlayerData.money[ConvertMoneyType(moneyType)] or 0
        end
    elseif Framework == 'mythic' then
        return function(player, moneyType)
            if moneyType == "cash" then
                return Wallet:GetBalance(player.source)
            elseif moneyType == "bank" then
                local char = player:GetData("Character")
                return Banking.Accounts:GetPersonal(char:GetData("SID"))?.Balance or 0
            end
            return 0
        end
    else
        return function()
            error("Unsupported framework for GetPlayerFunds.")
        end
    end
end

-- Utilize the dynamically selected function for getting player's funds.
local GetPlayerAccountFunds = GetPlayerFunds()

--- Adds money to a player's account.
---@param source number The player's server ID.
---@param moneyType string The type of money to add.
---@param amount number The amount of money to add.
SD.Money.AddMoney = function(source, moneyType, amount)
    local player = SD.GetPlayer(source)
    if player then AddMoneyToPlayer(player, moneyType, amount) end
end

--- Removes money from a player's account.
---@param source number The player's server ID.
---@param moneyType string The type of money to remove.
---@param amount number The amount of money to remove.
SD.Money.RemoveMoney = function(source, moneyType, amount)
    local player = SD.GetPlayer(source)
    if player then RemoveMoneyFromPlayer(player, moneyType, amount) end
end

--- Gets the amount of money in a player's account of a specific type.
---@param source number The player's server ID.
---@param moneyType string The type of money to check.
---@return number The amount of money.
SD.Money.GetPlayerAccountFunds = function(source, moneyType)
    local player = SD.GetPlayer(source)
    if player then return GetPlayerAccountFunds(player, moneyType) else return 0 end
end

return SD.Money