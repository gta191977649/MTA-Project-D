setCloudsEnabled(false)
setHeatHaze(0)

addEventHandler("onPlayerJoin",root,function() 
    fadeCamera(source,true)
    setCameraTarget(source)
    spawnPlayer(source,0,0,10)
    setElementPosition(source,0,0,10)
end)