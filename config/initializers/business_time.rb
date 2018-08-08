# adding exceptions to the business time calculation for the next 20 years of bank holidays
# Easter monday & summer bank hol are only in gb_eng so both settings are needed
Holidays.between(Date.civil(2018), Date.civil(2038), :gb, :gb_eng).map do |holiday|
  BusinessTime::Config.holidays << holiday[:date]
end
