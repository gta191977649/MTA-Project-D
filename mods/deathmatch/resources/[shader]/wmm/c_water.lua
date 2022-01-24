--
-- c_water.lua
--

addEventHandler( "onClientResourceStart", resourceRoot,
	function()

		-- Version check
		if getVersion ().sortable < "1.1.0" then
			outputChatBox( "Resource is not compatible with this client." )
			return
		end

		-- Create shader
		local myShader, tec = dxCreateShader ( "water.fx" )

		if not myShader then
			outputChatBox( "Could not create shader. Please use debugscript 3" )
		else
			outputChatBox( "Using technique " .. tec )

			-- Set textures
			local textureVol = dxCreateTexture ( "images/smallnoise3d.dds" );
			local textureCube = dxCreateTexture ( "images/cube_env256.dds" );
			dxSetShaderValue ( myShader, "sRandomTexture", textureVol );
			dxSetShaderValue ( myShader, "sReflectionTexture", textureCube );

			-- Apply to global txd 13
			engineApplyShaderToWorldTexture ( myShader, "FUK_TEXTURENAME_16_0_32_117" )
			engineApplyShaderToWorldTexture ( myShader, "OSAK_TEXTURENAME_16_0_32_90" )

			-- Update water color incase it gets changed by persons unknown
			setTimer(	function()
							if myShader then
								local r,g,b,a = getWaterColor()
								dxSetShaderValue ( myShader, "sWaterColor", r/120, g/120, b/110, a/120 );
							end
						end
						,100,0 )
		end
	end
)
