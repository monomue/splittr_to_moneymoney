-- This script based on the given example on https://moneymoney-app.com/api/import/
-- It is more or less a working in progress thing

Importer{version          = 0.01,
         format           = "Import from Splittr",
         fileExtension    = "csv",
         description      = "Import transactions from CSV file exported by Splittr"
        }

local function strToDate (str)
-- Helper function for converting localized date strings to timestamps.
  local d, m, y = string.match(str, "(%d%d).(%d%d).(%d%d%d%d)")
  return os.time{year=y, month=m, day=d}
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
    if linecount ~= 0 then
      local values = {}
      for value in string.gmatch(line, "[^;]*") do
        table.insert(values, value)
      end

      -- finding the values ... why are there some empty cells?
      --[[
      for i=1, #values, 1  do
        print("values[" .. i .. "]: " .. values[i])
      end
      ]]

      if #values >= 23 and values[1] ~= "Gesamt" then
        local amount_string = string.gsub(values[12], ",", ".")
        local transaction = {
          -- name = , WENN Name nicht gestzt wird er purpose -> Name ... v1.0?
          purpose = values[1],
          -- values[2] leer? WARUM ????
          bookingDate = strToDate(values[3]),
          -- values[4]
          category = values[5],
          -- values[6]
          comment = values[7],
          -- values[8]
          -- values[9] : Foto             NOT USED
          -- values[10]
          currency = values[11],
          -- values[12]
          -- values[13] : leer             NOT USED

          amount = tonumber(amount_string), -- tonumber hat Probleme mit dezimaltrenner ","
          -- oder mit ... str = MM.localizeAmount([format, ]amount[, currency])
          -- arbeiten V 1.0 ?????

          -- values[] : Umrechnungskurs  NOT USED
          -- values[] : Betrag (EUR)    NOT USED
          -- values[] : leer            NOT USED
          -- the following lines n-times for each user
          -- values[] : User            NOT USED
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
