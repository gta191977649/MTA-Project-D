loadstring(exports.dgs:dgsImportFunction())() 

--render = dgsCreateImage(0,0,1,1,"ref.png",true)
setPlayerHudComponentVisible("all", false )
HUD = {}

HUD.laptime = dgsCreateImage(0,0.07, 0.28, 0.23/2,"data/hud/time_background_extended.png",true)
HUD.record = dgsCreateImage(0.742,0.07, 0.258, 0.18,"data/hud/record_background_extended.png",true)
HUD.player = dgsCreateImage(0.742,0.28, 0.258, 0.067,"data/hud/name_background.png",true)
local scale = 0.4
HUD.minimap = dgsCreateImage(0.025,0.575, scale/2, scale,"data/hud/map_background.png",true)