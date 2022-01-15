loadstring(exports.dgs:dgsImportFunction())() 

browser = dgsCreateMediaBrowser(1280,720)
dgsMediaLoadMedia(browser,"countdown.webm","VIDEO") 
video = dgsCreateMask(browser,"backgroundFilter",{
	filterRGB={0,0,0},
	filterRange=0.3,
	isPixelated=false,
})

render = dgsCreateImage(0,0,1,1,video,true)
dgsMediaPlay(browser)