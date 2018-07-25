
Time::DATE_FORMATS[:long] = lambda do |time|
  time.strftime("%A, #{time.day.ordinalize} %B %Y, %H:%M%P")
end
Date::DATE_FORMATS[:long] = lambda do |time|
  time.strftime("%A, #{time.day.ordinalize} %B %Y")
end

Time::DATE_FORMATS[:short] = "%a %d %b %H:%M"

Time::DATE_FORMATS[:day_only] = lambda do |time|
  time.strftime("%A, #{time.day.ordinalize} %B %Y")
end
