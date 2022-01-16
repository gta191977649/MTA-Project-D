local scx, scy = guiGetScreenSize()
scx=scx/2
scy=scy/2
-----------------------------------------------------------------------------------
-- Le settings
-----------------------------------------------------------------------------------
Settings = {}
Settings.var = {}

Settings.var.bloom = 1.176
Settings.var.xzoom = 1
Settings.var.yzoom = 0.78
Settings.var.bFac = 0.5
Settings.var.xval = 0.00
Settings.var.yval = -0.02
Settings.var.efInte = 0.6 -- 0.56
Settings.var.brFac = 0.5 -- 0.32

-- List of world textures to exclude from this effect

local removeList = {
						"",							-- unnamed
						"basketball2","skybox_tex",	   				    -- other
						"muzzle_texture*",								-- guns
						"font*","radar*",								-- hud
						"fireba*",
						"vehicle*", "?emap*", "?hite*",					-- vehicles
						"*92*", "*wheel*", "*interior*",				-- vehicles
						"*handle*", "*body*", "*decal*",				-- vehicles
						"*8bit*", "*logos*", "*badge*",					-- vehicles
						"*plate*", "*sign*", "*headlight*",				-- vehicles
						"vehiclegeneric256","vehicleshatter128", 		-- vehicles
						"*shad*",										-- shadows
						"coronastar","coronamoon","coronaringa",
						"coronaheadlightline",							-- coronas
						"lunar",										-- moon
						"tx*",											-- grass effect
						--"lod*",										-- lod models
						"cj_w_grad",									-- checkpoint texture
						"*cloud*",										-- clouds
						"*smoke*",										-- smoke
						"sphere_cj",									-- nitro heat haze mask
						"particle*",									-- particle skid and maybe others
						"water*","newaterfal1_256",
						--"sw_sand", "coral",							-- sea
						"boatwake*","splash_up","carsplash_*",			-- splash
						"gensplash","wjet4","bubbles","blood*",			-- splash
						--"sm_des_bush*", "*tree*", "*ivy*", "*pine*",	-- trees and shrubs
						--"veg_*", "*largefur*", "hazelbr*", "weeelm",
						--"*branch*", "cypress*", "plant*", "sm_josh_leaf",
						--"trunk3", "*bark*", "gen_log", "trunk5","veg_bush2", 
						"fist","*icon","headlight*",
						"unnamed",
					}				
									
function applyBumpToTexture(fakeBumpMapShader)

	engineApplyShaderToWorldTexture ( fakeBumpMapShader, "*" )
	-- Apply settings
	dxSetShaderValue( fakeBumpMapShader, "xzoom", Settings.var.xzoom )
	dxSetShaderValue( fakeBumpMapShader, "yzoom", Settings.var.yzoom )
	dxSetShaderValue( fakeBumpMapShader, "bFac", Settings.var.bFac )	
	dxSetShaderValue( fakeBumpMapShader, "xval", Settings.var.xval )
	dxSetShaderValue( fakeBumpMapShader, "yval", Settings.var.yval )	
    dxSetShaderValue( fakeBumpMapShader, "efInte", Settings.var.efInte )	
    dxSetShaderValue( fakeBumpMapShader, "brFac", Settings.var.brFac )
	-- Process remove list
	for _,removeMatch in ipairs(removeList) do
		engineRemoveShaderFromWorldTexture ( fakeBumpMapShader, removeMatch )
	end
end

----------------------------------------------------------------
-- onClientResourceStart
----------------------------------------------------------------
addEventHandler( "onClientResourceStart", resourceRoot,
	function()

		-- Version check
		if getVersion ().sortable < "1.1.3" then
			outputChatBox( "Resource is not compatible with this client." )
			return
		end

		-- Create things
        myScreenSource = dxCreateScreenSource( scx, scy )
		
        blurHShader,tecName = dxCreateShader( "blurH.fx" )
		outputDebugString( "blurHShader is using technique " .. tostring(tecName) )

        blurVShader,tecName = dxCreateShader( "blurV.fx" )
		outputDebugString( "blurVShader is using technique " .. tostring(tecName) )
		fakeBumpMapShader,tecName = dxCreateShader ( "shader_bump.fx",1,400,false,"world,object" )
		outputDebugString( "fakeBumpShader is using technique " .. tostring(tecName) )
		if not fakeBumpMapShader then return end
		applyBumpToTexture(fakeBumpMapShader)
		-- Check everything is ok
		bAllValid = myScreenSource and blurHShader and blurVShader and fakeBumpMapShader

		if not bAllValid then
			outputChatBox( "Could not create some things. Please use debugscript 3" )
		else
		outputChatBox( "Started: Shader reflective bump - test 2" )
		end
	
	end
)


-----------------------------------------------------------------------------------
-- onClientHUDRender
-----------------------------------------------------------------------------------
addEventHandler( "onClientHUDRender", root,
    function()
		if not Settings.var then
			return
		end
        if bAllValid then
			-- Reset render target pool
			RTPool.frameStart()
			-- Update screen
			dxUpdateScreenSource( myScreenSource )
			-- Start with screen
			current = myScreenSource
			-- Apply all the effects, bouncing from one render target to another
			current = applyGBlurH( current, Settings.var.bloom )
			current = applyGBlurV( current, Settings.var.bloom )
			-- When we're done, turn the render target back to default
			dxSetRenderTarget()
			dxSetShaderValue ( fakeBumpMapShader, "sReflectionTexture", current );
        end
    end
)


-----------------------------------------------------------------------------------
-- Apply the different stages
-----------------------------------------------------------------------------------

function applyGBlurH( Src, bloom )
	if not Src then return nil end
	local mx,my = dxGetMaterialSize( Src )
	local newRT = RTPool.GetUnused(mx,my)
	if not newRT then return nil end
	dxSetRenderTarget( newRT, true ) 
	dxSetShaderValue( blurHShader, "TEX0", Src )
	dxSetShaderValue( blurHShader, "TEX0SIZE", mx,my )
	dxSetShaderValue( blurHShader, "BLOOM", bloom )
	dxDrawImage( 0, 0, mx, my, blurHShader )
	return newRT
end

function applyGBlurV( Src, bloom )
	if not Src then return nil end
	local mx,my = dxGetMaterialSize( Src )
	local newRT = RTPool.GetUnused(mx,my)
	if not newRT then return nil end
	dxSetRenderTarget( newRT, true ) 
	dxSetShaderValue( blurVShader, "TEX0", Src )
	dxSetShaderValue( blurVShader, "TEX0SIZE", mx,my )
	dxSetShaderValue( blurVShader, "BLOOM", bloom )
	dxDrawImage( 0, 0, mx,my, blurVShader )
	return newRT
end

-----------------------------------------------------------------------------------
-- Pool of render targets
-----------------------------------------------------------------------------------
RTPool = {}
RTPool.list = {}

function RTPool.frameStart()
	for rt,info in pairs(RTPool.list) do
		info.bInUse = false
	end
end

function RTPool.GetUnused( mx, my )
	-- Find unused existing
	for rt,info in pairs(RTPool.list) do
		if not info.bInUse and info.mx == mx and info.my == my then
			info.bInUse = true
			return rt
		end
	end
	-- Add new
	local rt = dxCreateRenderTarget( mx, my )
	if rt then
		outputDebugString( "creating new RT " .. tostring(mx) .. " x " .. tostring(mx) )
		RTPool.list[rt] = { bInUse = true, mx = mx, my = my }
	end
	return rt
end