setCloudsEnabled(false)
setHeatHaze(0)

addEventHandler("onPlayerJoin",root,function() 
    fadeCamera(source,true)
    setCameraTarget(source)
    spawnPlayer(source,0,0,10)
    setElementPosition(source,-5787.43,214.568,24.4615)
end)