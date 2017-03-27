json.keyword do
  json.value @keyword
  json.description do
    json.rus @rusdescription[:description].value
    json.eng @engdescription[:description].value
  end
  json.uri do
    json.rus @rusdescription[:concept].value
    json.eng @engdescription[:concept].value
  end
end
