
Time::DATE_FORMATS[:long] = lambda do |time|
  time.strftime("%A #{time.day.ordinalize} %B, %Y, %H:%M%P")
end

Time::DATE_FORMATS[:short] = "%a %d %b %H:%M"
