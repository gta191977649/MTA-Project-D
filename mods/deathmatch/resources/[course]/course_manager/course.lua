COURSE = {
    "free",
    "myogi",
    "fukuoka",
}

addEventHandler ( "onPlayerJoin", root, function()
    for k, v in ipairs(COURSE) do 
        exports["streamer"]:loadmap(source,v)
    end

end)