loadstring(exports.dgs:dgsImportFunction())() 

browser = dgsCreateMediaBrowser(1280,720)
dgsMediaLoadMedia(browser,"start.webm","VIDEO") 
video = dgsCreateMask(browser,"backgroundFilter",{
	filterRGB={0.925,0.925,0.925},
	filterRange=0.35,
	isPixelated=false,
})
bk = dgsCreateImage(0,0,1,1,tocolor(255,255,255,255),true)


setTimer(function() 
    dgsAlphaTo(bk,0,false,"Linear",1000)
end,18*1000,1)
render = dgsCreateImage(0,0,1,1,video,true)
dgsMediaPlay(browser)