Shader "Hidden/Outline Blit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_OutlineWidth("Outline Width", Range(0,100)) = 10.0
		_OutlineColor("Outline Color", Color) = (1,1,0,1)
		_Threshold("Outline Threshold", Range(0,1)) = 0.25
		_TextureSpaceMultiplier("Texture Space Multiplier", float) = 2.0
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

		Pass
		{ 
			Name "MTR"

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float4 _OutlineTempColor;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			void frag(v2f i, out fixed4 out_gbuffer0 : SV_Target0, out fixed4 out_gbuffer1 : SV_Target1)
			{
				out_gbuffer0 = float4(1, 1, 1, 1);
				out_gbuffer1 = _OutlineTempColor;
			}
			ENDCG
		}


        Pass
        {
			Name "Outline"
            CGPROGRAM
			#include "UnityCG.cginc"
			#pragma vertex vertOutline
			#pragma fragment fragOutline

			sampler2D _MainTex;
			sampler2D _ColorTex;

			float _OutlineWidth;
			float4 _OutlineColor;
			float _Threshold;
			float4 _MainTex_TexelSize;
			float _TextureSpaceMultiplier;
			bool _IsAnimated;
			bool _IsMultiColor;

			struct VertexInput
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 vertexColor : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			 {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float vertexColorAlpha : COLOR;
			};


			VertexOutput vertOutline(VertexInput v)
			 {
				VertexOutput o;

				UNITY_SETUP_INSTANCE_ID(v);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				o.vertexColorAlpha = v.vertexColor.a;
				return o;
			}

			float AnimatedWidth()
			{
				float min = _OutlineWidth - _OutlineWidth / 2;
				float max = _OutlineWidth + _OutlineWidth / 2;

				float speed = 100;

				float animated = lerp(min, max, pow(sin(_Time.x * speed), 2));

				return lerp(_OutlineWidth, animated, _IsAnimated);
			}

			fixed4 SampleSpriteTexture(float2 uv)
			{
				fixed4 tex = tex2D(_MainTex, uv);
				return tex;
			}

			void Smooth(float2 uv, bool ifZero, out float4 outline)
			{
				bool smoothResult = false;

				float width = _OutlineWidth;
				width = AnimatedWidth();

				float thicknessX = width / _MainTex_TexelSize.z;
				float thicknessY = width / _MainTex_TexelSize.w;

				float alphaThreshold = _Threshold / 10;

				int steps = 100;
				float angle_step = 360.0 / steps;

				for (int i = 0; i < steps && !smoothResult && !ifZero; i++)
				{
					float angle = i * angle_step * 2 * 3.14 / 360;

					float2 newUv = uv + fixed2(thicknessX * cos(angle), thicknessY * sin(angle));

					smoothResult = SampleSpriteTexture(newUv).a > alphaThreshold;

					outline = float4(tex2D(_ColorTex, newUv).rgb, smoothResult);
				}
			}

			bool CheckOriginalSpriteTexture(float2 uv)
			{
				bool outline = false;

				bool smoothResult = false;

				float width = _OutlineWidth;
				width = AnimatedWidth();

				float thicknessX = width / _MainTex_TexelSize.z;
				float thicknessY = width / _MainTex_TexelSize.w;

				float alphaThreshold = _Threshold / 10;

				outline = SampleSpriteTexture(uv + fixed2(0, +thicknessY)).a > alphaThreshold ||
							SampleSpriteTexture(uv + fixed2(0, -thicknessY)).a > alphaThreshold ||
							SampleSpriteTexture(uv + fixed2(+thicknessX, 0)).a > alphaThreshold ||
							SampleSpriteTexture(uv + fixed2(-thicknessX, 0)).a > alphaThreshold ||
							SampleSpriteTexture(uv + fixed2(+thicknessX * cos(3.14 / 4), -thicknessY * sin(3.14 / 4))).a > alphaThreshold ||
							SampleSpriteTexture(uv + fixed2(-thicknessX * cos(3.14 / 4), +thicknessY * sin(3.14 / 4))).a > alphaThreshold ||
							SampleSpriteTexture(uv + fixed2(-thicknessX * cos(3.14 / 4), -thicknessY * sin(3.14 / 4))).a > alphaThreshold ||
							SampleSpriteTexture(uv + fixed2(+thicknessX * cos(3.14 / 4), +thicknessY * sin(3.14 / 4))).a > alphaThreshold;

				return outline;
			}

			float4 CheckOriginalSpriteTextureLoop(float2 uv)
			{
				float4 outline;

				float width = _OutlineWidth;
				width = AnimatedWidth();

				float thicknessX = width / _MainTex_TexelSize.z;
				float thicknessY = width / _MainTex_TexelSize.w;

				float alphaThreshold = _Threshold / 10;

				static const float2 offsets[] =
				{
					float2(0, 1),
					float2(0, -1),
					float2(-1, 0),
					float2(1, 0),
					float2(-1, 1),
					float2(1, 1),
					float2(-1, -1),
					float2(1, -1),
				};

				for (int index = 0; index < offsets.Length; index++)
				{
					float2 angleOffset = float2(cos(3.14 / 4), sin(3.14 / 4));
					float2 thickness = float2(thicknessX, thicknessY);
					float2 diagonalOffset = lerp(1, angleOffset, index > 3);

					float2 newUv = uv + offsets[index] * thickness * diagonalOffset;

					outline = lerp(tex2D(_ColorTex, newUv), outline, outline > 0);
					outline.a = outline.a || SampleSpriteTexture(newUv).a > alphaThreshold;
				}

				return outline;
			}

			float4 fragOutline(VertexOutput i) : SV_Target
			{
				float delta = 0.01;

				float2 uv = i.uv;

				float4 pixelCurrent = SampleSpriteTexture(uv);

				bool isZeroAlpha = pixelCurrent.a > delta;

				float4 outline;

				//outline = CheckOriginalSpriteTextureLoop(uv);
				Smooth(uv, isZeroAlpha, outline);

				outline.rgb = lerp(_OutlineColor.rgb, outline, _IsMultiColor);
				outline.a = lerp(outline.a, 0, isZeroAlpha);

				float4 texColor = outline;

				clip(texColor.a - delta);

				return texColor;
			}

            ENDCG
        }


    }
}
