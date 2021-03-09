Shader "Custom/Sprites Outline" {
	Properties {
		
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)
		[MaterialToggle] PixelSnap("Pixel snap", Float) = 0
		[HideInInspector] _RendererColor("RendererColor", Color) = (1,1,1,1)
		[HideInInspector] _Flip("Flip", Vector) = (1,1,1,1)
		[PerRendererData] _AlphaTex("External Alpha", 2D) = "white" {}
		[PerRendererData] _EnableExternalAlpha("Enable External Alpha", Float) = 0

		_OutlineWidth("Outline Width", Range(0,100)) = 10.0
		_OutlineColor("Outline Color", Color) = (1,1,0,1)
		_Threshold("Outline Threshold", Range(0,1)) = 0.25
		_TextureSpaceMultiplier("Texture Space Multiplier", float) = 2.0

		_StencilMask_1("Stencil mask", Int) = 2
		_StencilMask_2("Stencil mask 2", Int) = 0
	}

	SubShader {
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
			"DisableBatching" = "True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		Pass
		{	
			Name "Outline"
		
			Stencil
			{
				Ref[_StencilMask_1]
				Comp always
				Pass replace
			}

			CGPROGRAM
			#pragma vertex vertOutline
			#pragma fragment fragOutline
			#include "CGIncludes/Sprites-Outline-Pass.cginc"
			ENDCG
		}

		Pass
		{
			Name "Unity Sprite"

			Stencil
			{
				Ref[_StencilMask_2]
				Comp GEqual
				Pass replace
			}

			CGPROGRAM
			#pragma vertex SpriteVert
			#pragma fragment SpriteFrag
			#pragma target 2.0
			#pragma multi_compile_instancing
			#pragma multi_compile _ PIXELSNAP_ON
			#pragma multi_compile _ ETC1_EXTERNAL_ALPHA
			#include "UnitySprites.cginc"
			ENDCG
		}


	}

	FallBack "Sprites/Default"
}
