#include "UnityCG.cginc"


float _OutlineWidth;
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
	UNITY_VERTEX_INPUT_INSTANCE_ID
};


UNITY_INSTANCING_BUFFER_START(Props)
	UNITY_DEFINE_INSTANCED_PROP(float4, _OutlineColor)
	UNITY_DEFINE_INSTANCED_PROP(sampler2D, _MainTex)
UNITY_INSTANCING_BUFFER_END(Props)

VertexOutput vertOutline(VertexInput v)
 {
	VertexOutput o;

	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);

	o.pos = UnityObjectToClipPos(v.vertex * _TextureSpaceMultiplier);
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
	fixed4 tex = tex2D(UNITY_ACCESS_INSTANCED_PROP(Props, _MainTex), uv);

	tex.a *= step(0, uv.y) * step(uv.y, 1) * step(0, uv.x) * step(uv.x, 1);

	return tex;
}

bool Smooth(float2 uv, bool ifZero)
{
	bool smoothResult = false;
	
	float width = _OutlineWidth;
	width = AnimatedWidth();

	float thicknessX = width / _MainTex_TexelSize.z;
	float thicknessY = width / _MainTex_TexelSize.w;

	float alphaThreshold = _Threshold / 10;

	int steps = 50;
	float angle_step = 360.0 / steps;

	for (int i = 0; i < steps && !smoothResult && !ifZero; i++)
	{
		float angle = i * angle_step * 2 * 3.14 / 360;

		smoothResult = SampleSpriteTexture(uv + fixed2(thicknessX * cos(angle), thicknessY * sin(angle))).a > alphaThreshold;
	}

	return smoothResult;
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

	outline =   SampleSpriteTexture(uv + fixed2(0, +thicknessY)).a > alphaThreshold ||
				SampleSpriteTexture(uv + fixed2(0, -thicknessY)).a > alphaThreshold ||
				SampleSpriteTexture(uv + fixed2(+thicknessX, 0)).a > alphaThreshold ||
				SampleSpriteTexture(uv + fixed2(-thicknessX, 0)).a > alphaThreshold ||
				SampleSpriteTexture(uv + fixed2(+thicknessX * cos(3.14 / 4), -thicknessY * sin(3.14 / 4))).a > alphaThreshold ||
				SampleSpriteTexture(uv + fixed2(-thicknessX * cos(3.14 / 4), +thicknessY * sin(3.14 / 4))).a > alphaThreshold ||
				SampleSpriteTexture(uv + fixed2(-thicknessX * cos(3.14 / 4), -thicknessY * sin(3.14 / 4))).a > alphaThreshold ||
				SampleSpriteTexture(uv + fixed2(+thicknessX * cos(3.14 / 4), +thicknessY * sin(3.14 / 4))).a > alphaThreshold;
	
	return outline;
}

bool CheckOriginalSpriteTextureLoop(float2 uv)
{
	bool outline = false;

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
		outline = outline || SampleSpriteTexture(uv + offsets[index] * thickness * diagonalOffset).a > alphaThreshold;
	}

	return outline;
}

float4 fragOutline(VertexOutput i) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(i); 
	float4 outlineColor = UNITY_ACCESS_INSTANCED_PROP(Props, _OutlineColor);

	float delta = 0.01;

	float2 tiling = float2(_TextureSpaceMultiplier, _TextureSpaceMultiplier);

	float uvOffsetValue = _TextureSpaceMultiplier * -0.5 + 0.5;
	float2 uvOffset = float2(uvOffsetValue, uvOffsetValue);
	float2 uv = i.uv * tiling + uvOffset;
 
	float4 pixelCurrent = SampleSpriteTexture(uv);

	bool isZeroAlpha = pixelCurrent.a > delta;

	float4 outline = float4(outlineColor.rgb, CheckOriginalSpriteTextureLoop(uv));
	outline.a = Smooth(uv, isZeroAlpha);
	//outline.a = lerp(outline.a, 0, isZeroAlpha);

	float4 texColor = outline;

	clip(texColor.a - delta);

	return texColor;
}


