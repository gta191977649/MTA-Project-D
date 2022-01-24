--
-- c_uv_scroll.lua
--


addEventHandler( "onClientResourceStart", resourceRoot,
	function()

		-- Version check
		if getVersion ().sortable < "1.1.0" then
			outputChatBox( "Resource is not compatible with this client." )
			return
		end

		-- Create shader
		local shader, tec = dxCreateShader ( "firework.fx" )

		if not shader then
			outputChatBox( "Could not create shader. Please use debugscript 3" )
		else
			outputChatBox( "Using technique " .. tec )

			-- Apply to world texture
			engineApplyShaderToWorldTexture ( shader, "FUK_TEXTURENAME_16_0_33_133" )
		end
	end
)
