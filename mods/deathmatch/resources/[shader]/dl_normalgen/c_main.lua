--
-- c_main.lua
--

local textureListTable = {}

local scx, scy = guiGetScreenSize()
isFXSupported = (tonumber(dxGetStatus().VideoCardNumRenderTargets) > 1 and tonumber(dxGetStatus().VideoCardPSVersion) > 2 
	and tostring(dxGetStatus().DepthBufferFormat) ~= "unknown")

local renderTarget = {RTColor = nil, RTNormal = nil, isOn = false}
					
local tbEffectEnabled = false

---------------------------------------------------------------------------------------------------
-- material primitive functions
---------------------------------------------------------------------------------------------------
trianglelist = {}
trianglelist.plane = {
	{ -0.5, 0.5, 0, 0, 1 },{ -0.5, -0.5, 0, 0, 0 },{ 0.5, 0.5, 0, 1, 1 },
	{ 0.5, -0.5, 0, 1, 0 },{ 0.5, 0.5, 0, 1, 1 },{ -0.5, -0.5, 0, 0, 0 }
}

---------------------------------------------------------------------------------------------------
-- manage after effect zBuffer recovery
---------------------------------------------------------------------------------------------------
CPrmNrmGen = { }
function CPrmNrmGen.create()
	if CPrmNrmGen.shader then return true end
	CPrmNrmGen.shader = dxCreateShader( "fx/primitive2d_prepNormals.fx" )
	if CPrmNrmGen.shader then
		dxSetShaderValue( CPrmNrmGen.shader, "fViewportSize", guiGetScreenSize() )
		dxSetShaderValue( CPrmNrmGen.shader, "ColorRT", renderTarget.RTColor )
		dxSetShaderValue( CPrmNrmGen.shader, "NormalRT", renderTarget.RTNormal )
		dxSetShaderValue( CPrmNrmGen.shader, "fViewportSize", scx, scy )
		dxSetShaderValue( CPrmNrmGen.shader, "sPixelSize", 1 / scx, 1 / scy )
		dxSetShaderValue( CPrmNrmGen.shader, "sHalfPixel", 1 / (scx * 2), 1 / (scy * 2) )
		dxSetShaderValue( CPrmNrmGen.shader, "SSR_RELIEF_AMOUNT", 0.60)
		dxSetShaderValue( CPrmNrmGen.shader, "SSR_RELIEF_SCALE", 0.35)
		return true
	end
	return false
end

function CPrmNrmGen.draw()
	if CPrmNrmGen.shader then
		-- draw the outcome
		dxDrawMaterialPrimitive3D( "trianglelist", CPrmNrmGen.shader, false, unpack( trianglelist.plane ) )
	end
end

function CPrmNrmGen.destroy()
	if CPrmNrmGen.shader then
		destroyElement( CPrmNrmGen.shader )
		CPrmNrmGen.shader = nil
		return true
	end
	return false
end

addEventHandler( "onClientPreRender", root,
    function()
		if not tbEffectEnabled then return end
		CPrmNrmGen.draw()
    end
, true, "high+9" )

----------------------------------------------------------------------------------------------------------------------------
-- onClientResourceStart/Stop
----------------------------------------------------------------------------------------------------------------------------
addEventHandler( "onClientResourceStart", resourceRoot, function()
	if not isFXSupported then return end
	renderTarget.isOn = getElementData ( localPlayer, "dl_core.on", false )
	if renderTarget.isOn then
		renderTarget.RTColor, renderTarget.RTNormal = exports.dl_core:getRenderTargets()
		if not tbEffectEnabled and renderTarget.RTColor and renderTarget.RTNormal then
			tbEffectEnabled = CPrmNrmGen.create()
		end 
	end
end
)

function switchNormalGenEffect(resName, isStarted)
	if not isFXSupported then return end
	if isStarted then
		if resName == "dl_core" then
			if tbEffectEnabled then return end
			renderTarget.isOn = getElementData ( localPlayer, "dl_core.on", false )
			if renderTarget.isOn then
				renderTarget.RTColor, renderTarget.RTNormal = exports.dl_core:getRenderTargets()
				if not tbEffectEnabled and renderTarget.RTColor and renderTarget.RTNormal then
					tbEffectEnabled = CPrmNrmGen.create()
				end
				return 
			end
		end	
	else
		if resName == "dl_core" then
			if tbEffectEnabled then
				renderTarget.isOn = false
				tbEffectEnabled = not CPrmNrmGen.destroy()
			end
		end	
	end
end

addEventHandler ( "onClientResourceStop", root, function(stoppedRes)
	switchNormalGenEffect(getResourceName(stoppedRes), false)
end
)

addEventHandler ( "onClientResourceStart", root, function(startedRes)
	switchNormalGenEffect(getResourceName(startedRes), true)
end
)	

addEvent( "switchdl_core", true )
addEventHandler( "switchdl_core", root, function(isOn) switchNormalGenEffect("dl_core", isOn) end)