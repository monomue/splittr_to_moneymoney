-- This script based on the given example on https://moneymoney-app.com/api/import/
-- It is more or less a working in progress thing

--[[Splittr offers the possibility to split the given amount to one, to some or
to all members of that group. BUT it is not YOUR amount, ist just a part of that.
This importscript imports only your part of the complete amount as negative numbers.
For me it works, because every transaction in splittr is a spending.

]]

Importer{version          = 0.03,
         format           = "Import from Splittr",
         fileExtension    = "csv",
         description      = "Import transactions from CSV file exported by Splittr"
        }


-- configuration:
local splittr_user_name = "Test 01"
local user_number = 0

local function get_key_of_user (table, user_name)
    -- Helper function to get the index (number of row) for a given user
    for index, value in ipairs(table) do
        if value == user_name then
            return index
        end
    end
end

local function dezimal_sub (str)
    -- Helper function to substitute comma(,) with period (.)
    -- returns a number
    result = string.gsub(str, ",", ".")

    return tonumber(result)
end

local function strToDate (str)
-- Helper function for converting localized date strings to timestamps.
    local d, m, y = string.match(str, "(%d%d).(%d%d).(%d%d%d%d)")
    return os.time{year=y, month=m, day=d}
end

function split_string (line, separator)
    -- Helper function for splitting a string by a separator (default ";" into its components
    local splits = {}
    local position = 1
    -- parsing the "line" start with position 1
    separator = separator or ";"
    while true do
        local start_position ,end_position = string.find(line, separator, position, true)
        -- string.find returns the start_position and end_position of a given string/pattern
        -- if called with one variable x = string.find... just the start
        -- last argument plain/true: no pattern search

        if start_position then
            -- number => true
            -- nil => flase
            split = string.sub(line, position, start_position - 1)
            table.insert(splits, split)
            position = end_position + 1
        else
            -- no separator found -> use rest of string and terminate
            table.insert(splits, string.sub(line, position, -1))
            break
        end
    end
    return splits
    -- returns a table of splits
end

function ReadTransactions (account)
    -- Read transactions from a file exported by Splittr
    -- with the following format :
    -- Titel;Datum;Kategorie;Notizen;Foto;;Währung;Betrag in Währung;Umrechnungskurs;Betrag (EUR);;USERNAME_01;Guthaben;Schulden;;USERNAME_n;Guthaben;Schulden
    -- os.setlocale("de_DE.UTF-8") does nothing obious in MoneyMoney
    --so do your own localizing: decimal, bringt nichts ....

    -- print("Lua-Version: " .. _VERSION)
    local transactions = {}
    local linecount = 0
    -- linecount to pass first line
    -- popping the first table Element seems to "cost" more
    for line in assert(io.lines()) do
        if linecount == 0 then
            local title = {}
            local titles = split_string(line, ";")

            index_user = get_key_of_user(titles, splittr_user_name)
            if index_user == nil then
                print("User " .. splittr_user_name .. " not found, i returns please check splittr_user_name probably arround line 20 in the code")
                return nil
            else
                print("Using " .. splittr_user_name .. " as User, with cell_ID: " .. index_user)
            end

            -- search for splittr_user_name
            -- #TODO : nach Name suchen, wenn gefunden import weiter, wenn nicht fehlermeldung
        print("line: >>> " .. line)
        end
        if linecount ~= 0 then
            local values = {}
            local values = split_string(line, ";")

            for i=1, #values, 1  do
                print("values[" .. i .. "]: " .. values[i])
            end

            if #values >= 18 and values[1] ~= "Gesamt" then
                -- get the user part of the total-amount

                amount_user_part = values[index_user]
                amount_user_part = dezimal_sub(amount_user_part)
                if amount_user_part > 0 then
                    amount_user_part = amount_user_part * -1
                end

                local transaction = {
                    -- name = splittr_user_name,
                    name = splittr_user_name .. "'s Anteil von:    " .. values[1],
                    -- WENN Name nicht gestzt wird er purpose -> Name ... v1.0?
                    purpose = values[1],
                    bookingDate = strToDate(values[2]),
                    category = values[3],
                    comment = values[4],
                    -- values[5] : Foto
                    -- values[6] : double ";"             NOT USED
                    currency = values[7],
                    -- values[8] : Betrag in Währung
                    -- values[9] : Umrechnungskurs
                    amount = amount_user_part,

                    -- the following lines n-times for each user
                    -- values[] : User betrag     NOT USED     #TODO
                    -- values[] : Guthaben        NOT USED
                    -- values[] : Schulden        NOT USED
                    bookingText = "from Splittr"
                }

                table.insert(transactions, transaction)
            end
        end
        linecount = linecount + 1
    end
    return transactions
end



--[[ comment


for value in string.gmatch(line, "[^;]+") do

  table.insert(values, value)
end

    MoneyMoney Transfers:
        String name: Name des Auftraggebers/Zahlungsempfängers
        String accountNumber: Kontonummer oder IBAN des Auftraggebers/Zahlungsempfängers
        String bankCode: Bankzeitzahl oder BIC des Auftraggebers/Zahlungsempfängers
        Number amount: Betrag
        (+) String currency: Währung
        Number bookingDate: Buchungstag; Die Angabe erfolgt in Form eines POSIX-Zeitstempels.
        Number valueDate: Wertstellungsdatum; Die Angabe erfolgt in Form eines POSIX-Zeitstempels.
        (+) String purpose: Verwendungszweck; Mehrere Zeilen können durch Zeilenumbrüche ("\n") getrennt werden.
        Number transactionCode: Geschäftsvorfallcode
        Number textKeyExtension: Textschlüsselergänzung
        String purposeCode: SEPA-Verwendungsschlüssel
        String bookingKey: SWIFT-Buchungsschlüssel
        (+) String bookingText: Umsatzart
        String primanotaNumber: Primanota-Nummer
        String batchReference: Sammlerreferenz
        String endToEndReference: SEPA-Ende-zu-Ende-Referenz
        String mandateReference: SEPA-Mandatsreferenz
        String creditorId: SEPA-Gläubiger-ID
        String returnReason: Rückgabegrund
        Boolean booked: Gebuchter oder vorgemerkter Umsatz
        (+) String category: Kategorienname
        (+) String comment: Notiz


Splittr-Export:
Titel;Datum;Kategorie;Notizen;Foto;;Währung;Betrag in Währung;Umrechnungskurs;Betrag (EUR);;Tobias Münster;Guthaben;Schulden

Conclusio:
Splittr               MoneyMoney
=======================
(1) Titel                 String purpose: Verwendungszweck; Mehrere Zeilen können durch Zeilenumbrüche ("\n") getrennt werden.
(2) Datum                 (???) Number bookingDate: Buchungstag; Die Angabe erfolgt in Form eines POSIX-Zeitstempels.
                      (???) Number valueDate: Wertstellungsdatum; Die Angabe erfolgt in Form eines POSIX-Zeitstempels.
(3) Kategorie             String category: Kategorienname
(4)Notizen               String comment: Notiz
(5)Foto                  ---
(6)???                   ???
(7)Währung               String currency: Währung
(8)Betrag in Währung     Number amount: Betrag ?
(9)Umrechnungskurs
(10)Betrag (EUR)          Number amount: Betrag ?
(11)???
(12)(???)USERNAME
(13)-Guthaben
(14)-Schulden
                      Boolean booked: Gebuchter oder vorgemerkter Umsatz
                      String bookingText: Umsatzart

]]
