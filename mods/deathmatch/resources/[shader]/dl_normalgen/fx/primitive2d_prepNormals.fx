// 
// file: primitive2D_prepNormals.fx
// version: v1.6
// author: Ren712
//

//--------------------------------------------------------------------------------------
// Settings
//--------------------------------------------------------------------------------------
float2 fViewportSize = float2(800, 600);
float2 fViewportScale = float2(1, 1);
float2 fViewportPos = float2(0, 0);

float2 sPixelSize = float2(0.00125,0.00166);
float2 sHalfPixel = float2(0.000625,0.00083);

float2 gDistFade = float2(300,250);

float SSR_RELIEF_AMOUNT = 0.7;
float SSR_RELIEF_SCALE = 0.4;

//--------------------------------------------------------------------------------------
// Settings
//--------------------------------------------------------------------------------------
texture colorRT < string renderTarget = "yes"; >;
texture normalRT < string renderTarget = "yes"; >;

//--------------------------------------------------------------------------------------
// Variables set by MTA
//--------------------------------------------------------------------------------------
texture gDepthBuffer : DEPTHBUFFER;
float4x4 gProjection : PROJECTION;
float4x4 gView : VIEW;
float4x4 gViewInverse : VIEWINVERSE;
float4x4 gWorld : WORLD;
float3 gCameraPosition : CAMERAPOSITION;
float3 gCameraDirection : CAMERADIRECTION;
int gFogEnable < string renderState="FOGENABLE"; >;
float4 gFogColor < string renderState="FOGCOLOR"; >;
float gFogStart < string renderState="FOGSTART"; >;
float gFogEnd < string renderState="FOGEND"; >;
int CUSTOMFLAGS < string skipUnusedParameters = "yes"; >;

//--------------------------------------------------------------------------------------
// Sampler 
//--------------------------------------------------------------------------------------
sampler SamplerColor = sampler_state
{
    Texture = (colorRT);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler SamplerNormal = sampler_state
{
    Texture = (normalRT);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    SRGBTexture = false;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

sampler SamplerDepth = sampler_state
{
    Texture = (gDepthBuffer);
    AddressU = Clamp;
    AddressV = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    SRGBTexture = false;
    MaxMipLevel = 0;
    MipMapLodBias = 0;
};

//--------------------------------------------------------------------------------------
// Structures
//--------------------------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse : COLOR0;
};

struct PSInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float4 UvToView : TEXCOORD1;
    float3 TexProj : TEXCOORD2;
    float4 Diffuse : COLOR0;
};

//--------------------------------------------------------------------------------------
// Returns a translation matrix
//--------------------------------------------------------------------------------------
float4x4 makeTranslation( float3 trans) 
{
  return float4x4(
     1,  0,  0,  0,
     0,  1,  0,  0,
     0,  0,  1,  0,
     trans.x, trans.y, trans.z, 1
  );
}

//--------------------------------------------------------------------------------------
// Creates projection matrix of a shadered dxDrawImage
//--------------------------------------------------------------------------------------
float4x4 createImageProjectionMatrix(float2 viewportPos, float2 viewportSize, float2 viewportScale, float adjustZFactor, float nearPlane, float farPlane)
{
    float Q = farPlane / ( farPlane - nearPlane );
    float rcpSizeX = 2.0f / viewportSize.x;
    float rcpSizeY = -2.0f / viewportSize.y;
    rcpSizeX *= adjustZFactor;
    rcpSizeY *= adjustZFactor;
    float viewportPosX = 2 * viewportPos.x;
    float viewportPosY = 2 * viewportPos.y;
	
    float4x4 sProjection = {
        float4(rcpSizeX * viewportScale.x, 0, 0,  0), float4(0, rcpSizeY * viewportScale.y, 0, 0), float4(viewportPosX, -viewportPosY, Q, 1),
        float4(( -viewportSize.x / 2.0f - 0.5f ) * rcpSizeX,( -viewportSize.y / 2.0f - 0.5f ) * rcpSizeY, -Q * nearPlane , 0)
    };

    return sProjection;
}

//--------------------------------------------------------------------------------------
// Vertex Shader 
//--------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;

    // set proper position of the quad
    VS.Position.xyz = float3(VS.TexCoord, 0);
	
    // resize
    VS.Position.xy *= fViewportSize;

    // create projection matrix (as done for shadered dxDrawImage)
    float4x4 sProjection = createImageProjectionMatrix(fViewportPos, fViewportSize, fViewportScale, 1000, 100, 10000);
	
    // calculate screen position of the vertex
    float4 viewPos = mul(float4(VS.Position.xyz, 1), makeTranslation(float3(0,0, 1000)));
    PS.Position = mul(viewPos, sProjection);

    // pass texCoords and vertex color to PS
    PS.TexCoord = VS.TexCoord;
    PS.Diffuse = VS.Diffuse;
	
    // Set texCoords for projective texture
    float projectedX = (0.5 * (PS.Position.w + PS.Position.x));
    float projectedY = (0.5 * (PS.Position.w - PS.Position.y));
    PS.TexProj.xyz = float3(projectedX, projectedY, PS.Position.w); 
	
    // calculations for perspective-correct position recontruction
    float2 uvToViewADD = - 1 / float2(gProjection[0][0], gProjection[1][1]);	
    float2 uvToViewMUL = -2.0 * uvToViewADD.xy;
    PS.UvToView = float4(uvToViewMUL, uvToViewADD);
	
    return PS;
}

//--------------------------------------------------------------------------------------
//-- Get value from the depth buffer
//-- Uses define set at compile time to handle RAWZ special case (which will use up a few more slots)
//--------------------------------------------------------------------------------------
float FetchDepthBufferValue( float2 uv )
{
    float4 texel = tex2D(SamplerDepth, uv);
#if IS_DEPTHBUFFER_RAWZ
    float3 rawval = floor(255.0 * texel.arg + 0.5);
    float3 valueScaler = float3(0.996093809371817670572857294849, 0.0038909914428586627756752238080039, 1.5199185323666651467481343000015e-5);
    return dot(rawval, valueScaler / 255.0);
#else
    return texel.r;
#endif
}

//--------------------------------------------------------------------------------------
//-- Use the last scene projecion matrix to linearize the depth value a bit more
//--------------------------------------------------------------------------------------
float Linearize(float posZ)
{
    return gProjection[3][2] / (posZ - gProjection[2][2]);
}

//--------------------------------------------------------------------------------------
//-- Use the last scene projecion matrix to linearize the depth (0-1)
//--------------------------------------------------------------------------------------
float LinearizeToFloat(float posZ)
{
    return (1 - gProjection[2][2])/ (posZ - gProjection[2][2]);
}

//--------------------------------------------------------------------------------------
// GetPositionFromDepth
//--------------------------------------------------------------------------------------
float3 GetPositionFromDepth(float2 coords, float4 uvToView)
{
    return float3(coords.x * uvToView.x + uvToView.z, (1 - coords.y) * uvToView.y + uvToView.w, 1.0) 
        * Linearize(FetchDepthBufferValue(coords.xy));
}

//--------------------------------------------------------------------------------------
// Normal generation (by MartyMcFly)
//--------------------------------------------------------------------------------------
float3 GetNormalFromColor(sampler2D sample, float2 uv, float2 offset, float scale, float sharpness)
{
    float3 offset_swiz = float3(offset.xy, 0);
	
    float hpx = dot(tex2D(sample, float2(uv + offset_swiz.xz)).xyz, 0.333) * scale;
    float hmx = dot(tex2D(sample, float2(uv - offset_swiz.xz)).xyz, 0.333) * scale;
    float hpy = dot(tex2D(sample, float2(uv + offset_swiz.zy)).xyz, 0.333) * scale;
    float hmy = dot(tex2D(sample, float2(uv - offset_swiz.zy)).xyz, 0.333) * scale;
	
    float dpx = LinearizeToFloat(FetchDepthBufferValue(uv + offset_swiz.xz));
    float dmx = LinearizeToFloat(FetchDepthBufferValue(uv - offset_swiz.xz));
    float dpy = LinearizeToFloat(FetchDepthBufferValue(uv + offset_swiz.zy));
    float dmy = LinearizeToFloat(FetchDepthBufferValue(uv - offset_swiz.zy));

    float2 xymult = float2(abs(dmx - dpx), abs(dmy - dpy)) * sharpness;
    xymult.xy = saturate(1.0 - xymult);
	
    float3 normal;
    //normal.xy = float2(hmx - hpx, hmy - hpy) * xymult / offset.xy * 0.5;
    normal.xy = float2(hpx - hmx, hmy - hpy) * xymult / offset.xy * 0.5;

    normal.z = 1.0;

    return normalize(normal);       
}

float3 GetNormalFromDepth(float2 coords, float4 uvToView)
{
	float3 single_pixel_offset = float3(sPixelSize.xy, 0);

	float3 position              =              GetPositionFromDepth(coords, uvToView);
	float3 position_delta_x1 	 = - position + GetPositionFromDepth(coords + single_pixel_offset.xz, uvToView);
	float3 position_delta_x2 	 =   position - GetPositionFromDepth(coords - single_pixel_offset.xz, uvToView);
	float3 position_delta_y1 	 = - position + GetPositionFromDepth(coords + single_pixel_offset.zy, uvToView);
	float3 position_delta_y2 	 =   position - GetPositionFromDepth(coords - single_pixel_offset.zy, uvToView);

	position_delta_x1 = lerp(position_delta_x1, position_delta_x2, abs(position_delta_x1.z) > abs(position_delta_x2.z));
	position_delta_y1 = lerp(position_delta_y1, position_delta_y2, abs(position_delta_y1.z) > abs(position_delta_y2.z));

	return normalize(cross(position_delta_y1, position_delta_x1));
}

float4 GetNormalAndEdgesFromDepth(float2 coords, float4 uvToView)
{
	float3 single_pixel_offset = float3(sPixelSize.xy, 0);

	float3 position              =              GetPositionFromDepth(coords, uvToView);
	float3 position_delta_x1 	 = - position + GetPositionFromDepth(coords + single_pixel_offset.xz, uvToView);
	float3 position_delta_x2 	 =   position - GetPositionFromDepth(coords - single_pixel_offset.xz, uvToView);
	float3 position_delta_y1 	 = - position + GetPositionFromDepth(coords + single_pixel_offset.zy, uvToView);
	float3 position_delta_y2 	 =   position - GetPositionFromDepth(coords - single_pixel_offset.zy, uvToView);

	position_delta_x1 = lerp(position_delta_x1, position_delta_x2, abs(position_delta_x1.z) > abs(position_delta_x2.z));
	position_delta_y1 = lerp(position_delta_y1, position_delta_y2, abs(position_delta_y1.z) > abs(position_delta_y2.z));

	float deltaz = abs(position_delta_x1.z * position_delta_x1.z - position_delta_x2.z * position_delta_x2.z)
				 + abs(position_delta_y1.z * position_delta_y1.z - position_delta_y2.z * position_delta_y2.z);

	return float4(normalize(cross(position_delta_y1, position_delta_x1)), deltaz);
}

float3 GetSmoothedNormals(float2 texcoord, float3 ScreenSpaceNormals, float3 ScreenSpacePosition, float4 uvToView)
{
    float depthFac = 1.0 - 0.5 * saturate(ScreenSpacePosition.z * 0.05);
	float4 blurnormal = 0.0;
	[loop]
	for(float x = -3; x <= 3; x++)
	{
		[loop]
		for(float y = -3; y <= 3; y++)
		{	
			float2 offsetcoord 	= texcoord.xy + 0.0001f + float2(x,y) * depthFac * sPixelSize * 3.4999;
			float3 samplenormal 	= GetNormalFromDepth(offsetcoord.xy, uvToView);
			float3 sampleposition	= GetPositionFromDepth(offsetcoord.xy, uvToView);
			float weight 		= saturate(1.0 - distance(ScreenSpacePosition.xyz,sampleposition.xyz)*1.2);
			weight 		       *= smoothstep(0.5,1.0,dot(samplenormal,ScreenSpaceNormals));
			blurnormal.xyz += samplenormal * weight;
			blurnormal.w += weight;
		}
	}

	return normalize(blurnormal.xyz / (blurnormal.w + 0.0001f) + ScreenSpaceNormals*0.05);
}

float3 BlendNormals2(float3 n1, float3 n2)
{
    n1 -= float3( 0, 0, -1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}

float3 BlendNormals(float3 n1, float3 n2)
{
    //return normalize(float3(n1.xy*n2.z + n2.xy*n1.z, n1.z*n2.z));
    n1 += float3( 0, 0, 1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}

//------------------------------------------------------------------------------------------
// Structure of color data sent to the renderer ( from the pixel shader  )
//------------------------------------------------------------------------------------------
struct Pixel
{
    float4 World : COLOR0;      // Render target #0
    float4 Color : COLOR1;      // Render target #1
    float4 Normal : COLOR2;     // Render target #2
};

//--------------------------------------------------------------------------------------
// Pixel shaders 
//--------------------------------------------------------------------------------------
Pixel PixelShaderFunction(PSInput PS)
{
    Pixel output;

    float depth = FetchDepthBufferValue(PS.TexCoord.xy);
    if (depth > 0.99999f) discard;
    float linearDepth = Linearize(depth);

    float4 texel = tex2D(SamplerColor, PS.TexCoord);

    float3 viewPos = GetPositionFromDepth(PS.TexCoord, PS.UvToView);
	
    float3 viewNormal = 0;
    float4 viewNormalEdges = 0;
		
    // get world normal from normalRT
    float3 texNormal = tex2D(SamplerNormal, PS.TexCoord).xyz;
	
    if (texNormal.z > 0.3999f)
    {
        float3 worldNormalTex = float3((texNormal.xy - 0.5) * 2, 0);
        worldNormalTex.z =  1 - length(worldNormalTex.xy);
        worldNormalTex.z = fmod(texNormal.z, 0.2) > 0.1 ? worldNormalTex.z : -worldNormalTex.z;
        worldNormalTex = normalize(worldNormalTex);
        viewNormal = -mul(worldNormalTex, (float3x3)gView);
    }
    else
    {	
        viewNormalEdges = GetNormalAndEdgesFromDepth(PS.TexCoord, PS.UvToView);	
        viewNormal = viewNormalEdges.xyz; 
        viewNormal = GetSmoothedNormals(PS.TexCoord.xy + 0.0001f, viewNormal, viewPos, PS.UvToView);
    }
    float3 worldNormal = 0;

    if (texNormal.z < 0.6)
    {
        float3 normalFromTex = GetNormalFromColor(SamplerColor, PS.TexCoord.xy + sHalfPixel + 0.0001f, sPixelSize * SSR_RELIEF_SCALE, 0.005 * SSR_RELIEF_AMOUNT, 1000);	
        float3 combineNormal = BlendNormals(viewNormal, normalFromTex);
        combineNormal = lerp(combineNormal, viewNormal, pow(viewNormalEdges.w, 0.125));
        worldNormal = mul(-combineNormal, (float3x3)gViewInverse);
    }
    else
	{
        worldNormal = mul(-viewNormal, (float3x3)gViewInverse);
	}

    worldNormal = normalize(worldNormal);

    output.World = 0;
    output.Color = float4(texel.rgb, 1);
    output.Normal = float4((worldNormal.xy * 0.5) + 0.5, worldNormal.z <0 ? 0.611 : 0.789, 1);
	
    return output;
}

float4 PixelShaderFunctionNoDB(PSInput PS) : COLOR0
{
    return 0;
}

//--------------------------------------------------------------------------------------
// Techniques
//--------------------------------------------------------------------------------------
technique primitive3D_prepRTs_nor
{
  pass P0
  {
    ZEnable = false;
    ZFunc = GreaterEqual;
    ZWriteEnable = false;
    CullMode = 1;
    ShadeMode = Gouraud;
    AlphaBlendEnable = true;
    SrcBlend = SrcAlpha;
    DestBlend = InvSrcAlpha;
    AlphaTestEnable = false;
    AlphaRef = 1;
    AlphaFunc = GreaterEqual;
    Lighting = false;
    FogEnable = false;
    SRGBWriteEnable = false;
    VertexShader = compile vs_3_0 VertexShaderFunction();
    PixelShader  = compile ps_3_0 PixelShaderFunction();
  }
}

technique primitive3D_prepRTs_nor_noDB
{
  pass P0
  {
    ZEnable = false;
    ZFunc = GreaterEqual;
    ZWriteEnable = false;
    CullMode = 1;
    ShadeMode = Gouraud;
    AlphaBlendEnable = true;
    SrcBlend = SrcAlpha;
    DestBlend = InvSrcAlpha;
    AlphaTestEnable = false;
    AlphaRef = 1;
    AlphaFunc = GreaterEqual;
    Lighting = false;
    FogEnable = false;
    SRGBWriteEnable = false;
    VertexShader = compile vs_2_0 VertexShaderFunction();
    PixelShader  = compile ps_2_0 PixelShaderFunctionNoDB();
  }
}

// Fallback
technique fallback
{
  pass P0
  {
    // Just draw normally
  }
}
