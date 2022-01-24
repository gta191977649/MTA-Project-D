loadstring(exports.dgs:dgsImportFunction())() 

--render = dgsCreateImage(0,0,1,1,"ref.png",true)
setPlayerHudComponentVisible("all", false )
PADDING = 0.01
HUD = {}

HUD.laptime = dgsCreateImage(0 + PADDING,0.07  + PADDING, 0.28, 0.23/2,"data/hud/time_background_extended.png",true)
HUD.record = dgsCreateImage(0.742- PADDING,0.07+ PADDING, 0.258, 0.2,"data/hud/record_background_extended.png",true)
HUD.player = dgsCreateImage(0.742- PADDING,0.28+ PADDING, 0.258, 0.07,"data/hud/name_background.png",true)
local scale = 0.4
HUD.minimap = dgsCreateImage(0.025+ PADDING,0.575+ PADDING, scale/2, scale,"data/hud/map_background.png",true)
scale = 0.14
HUD.event = dgsCreateImage(0.035+ PADDING,0.046+ PADDING,scale,scale/3,"data/session/koudou.png",true)


HUD.timeleft = dgsCreateImage(0.7+ PADDING,0.09+ PADDING,0.25,0.25/2,"data/mfd/time_left.png",true,HUD.laptime)

HUD.timeleft_digit = {
    dgsCreateImage(0.65+ PADDING,0.2+ PADDING,0.75/5,0.75,"data/digits/digits_9.png",true,HUD.laptime),
    dgsCreateImage(0.8+ PADDING,0.2+ PADDING,0.75/5,0.75,"data/digits/digits_9.png",true,HUD.laptime),
}

FONT = {}
FONT.ui = dgsCreateFont( "data/font/Cairo-SemiBold.ttf", 32 ) 
LABEL = {}

LABEL.laptime = dgsCreateLabel(0,0.48,0.85,0.3,"0'00.000",true,HUD.laptime )
dgsSetFont( LABEL.laptime, FONT.ui ) 
dgsSetProperty(LABEL.laptime,"alignment",{"center","center"})
dgsSetProperty(LABEL.laptime,"shadow",{1,1,tocolor(0,0,0,255),true})

exports.dl_core:setWorldObjectLighting(0.3)