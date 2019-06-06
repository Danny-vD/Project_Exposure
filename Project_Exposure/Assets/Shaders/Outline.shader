﻿Shader "Custom/Outline"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)

		[Header(PBR maps)]
		_MainTex("Albedo (RGB), Alpha (A)", 2D) = "white" {}
		_BumpMap("NormalMap", 2D) = "bump" {}
		_MetallicMap("MetallicMap (RGB), Smoothness (A)", 2D) = "white" {}
		_HeightMap("HeightMap", 2D) = "black" {}
		_OcclusionMap("OcclusionMap", 2D) = "white" {}

		[Header(PBR settings)]
		_MaxHeight("MaxHeight", float) = 0.01
		_OcclusionStrength("Occlusion Strength", float) = 1

		[space]
		[Header(Outline)]
		[MaterialToggle] _ExtendVertices("ExtendAlongNormal", float) = 0
		_OutlineColor("OutlineColor", color) = (0, 0, 0, 1)
		_Thickness("Outline thickness (pixels)", float) = 25

		[space]
		[Header(Stencil buffer)]
		[IntRange] _StencilRef("Stencil Reference Value", Range(1,255)) = 1

		[space]
		[Header(Texture movement)]
		[MaterialToggle] _OnlyMoveAlbedo("Only move Albedo", float) = 0
		_Speed("Speed (XY)", vector) = (1, 0, 0, 0)

		[HideinInspector]_TimeElapsed("TimeOffset", float) = 0
	}


	SubShader
	{
		Tags 
		{
			"Queue" = "Transparent" "IgnoreProjector" = "true"
		}

		ZWrite off
		ZTest less
		blendop add
		blend srcAlpha OneMinusSrcAlpha

		CGINCLUDE

		struct VertexInput
		{
			float4 vertex : POSITION;
			float4 normal : NORMAL;
			float4 color : COLOR;
		};

		struct FragmentInput
		{
			float4 position : SV_POSITION;
			float4 color : COLOR;
		};

		ENDCG


		Pass //Stencil Buffer
		{
			Name "STENCIL"
			ZWrite Off
			ZTest Always
			ColorMask 0

			Stencil 
			{
				Ref [_StencilRef]
				Comp always
				Pass replace
				ZFail decrWrap
			}

			CGPROGRAM

			#pragma vertex vert2
			#pragma fragment frag

			FragmentInput vert2(VertexInput vert)
			{
				FragmentInput frag;
				frag.position = UnityObjectToClipPos(vert.vertex);
				frag.color = vert.color;

				return frag;
			}

			half4 frag(FragmentInput frag) : COLOR
			{
				return frag.color;
			}

			ENDCG
		}

		Pass //Outline
		{
			Name "OUTLINE"
			cull front

			Stencil 
			{
				Ref [_StencilRef]
				Comp NotEqual
				Pass replace
				ZFail decrWrap
			}

			CGPROGRAM
			#pragma vertex vertexShader alpha
			#pragma fragment fragmentShader alpha

			float4 _OutlineColor;
			float _Thickness;
			float _ExtendVertices;

			FragmentInput vertexShader(VertexInput vert)
			{
				FragmentInput frag;
				frag.color = vert.color;

				if (_ExtendVertices)
				{
					frag.position = UnityObjectToClipPos(vert.vertex);
					float3 clipNormal = mul((float3x3) UNITY_MATRIX_VP, mul((float3x3) UNITY_MATRIX_M, vert.normal));
					float2 offset = (normalize(clipNormal.xy) / _ScreenParams.xy) * _Thickness * frag.position.w * 2;

					frag.position.xy += offset;
					return frag;
				}
				else
				{
					float Width = _Thickness * 0.01;
					half3 vertex = vert.vertex.xyz;
					vertex.x *= Width + 1;
					vertex.y *= Width + 1;
					vertex.z *= Width + 1;

					frag.position = UnityObjectToClipPos(half4(vertex, vert.vertex.w));
					return frag;
				}
			}

			float4 fragmentShader(FragmentInput frag) : SV_TARGET
			{
				return _OutlineColor;
			}
			ENDCG
		}

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows alpha

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _MetallicMap;
		sampler2D _HeightMap;
		sampler2D _OcclusionMap;

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_MetallicMap;
			float2 uv_HeightMap;
			float2 uv_OcclusionMap;
			float3 viewDir;
		};

		float _Alpha;
		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		float _OcclusionStrength;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
		// put more per-instance properties here

		UNITY_INSTANCING_BUFFER_END(Props)

		float _MaxHeight;

		float _OnlyMoveAlbedo;
		float4 _Speed;
		float _TimeElapsed;

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			float timeX = _TimeElapsed * _Speed.x;
			float timeY = _TimeElapsed * _Speed.y;
			float2 timeOffset = float2(timeX, timeY);

			//Height map gives an offset to the uvs
			float value = tex2D(_HeightMap, IN.uv_HeightMap + timeOffset).rgb;
			float2 heightOffset = ParallaxOffset(value, _MaxHeight, IN.viewDir);

			//Albedo comes from a texture tinted by color
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex + heightOffset + timeOffset) * _Color;
			o.Albedo = c.rgb;

			if (_OnlyMoveAlbedo)
			{
				timeOffset = float2(0, 0);
				value = tex2D(_HeightMap, IN.uv_HeightMap + timeOffset).rgb;
				heightOffset = ParallaxOffset(value, _MaxHeight, IN.viewDir);
			}

			//Normal comes from a NormalMap
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap + heightOffset + timeOffset));

			//Metallic and smoothness come from the MetallicMap
			float4 metallicData = tex2D(_MetallicMap, IN.uv_MetallicMap + heightOffset + timeOffset);
			o.Metallic = metallicData.rgb;
			o.Smoothness = metallicData.a;

			//Ambient Occulusion comes from the occulusionMap
			o.Occlusion = tex2D(_OcclusionMap, IN.uv_OcclusionMap + heightOffset + timeOffset) * _OcclusionStrength;

			//Alpha comes from the Albedo
			o.Alpha = c.a;
		}
		ENDCG
	}
}