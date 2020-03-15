#if !defined(MY_LIGHTING_INCLUDED)
	#define MY_LIGHTING_INCLUDED

	#include "UnityPBSLighting.cginc"
	#include "AutoLight.cginc"

	float4 _Tint;
	sampler2D _MainTex;
	float4 _MainTex_ST;
	// float4 _SpecularTint;
	float _Metallic;
	float _Smoothness;

	struct VertexData {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float2 uv : TEXCOORD0;
	};

	struct Interpolators {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : TEXCOORD1;
		float3 worldPos : TEXCOORD2;
		
		SHADOW_COORDS(5)

		#if defined(VERTEXLIGHT_ON)
			float3 vertexLightColor : TEXCOORD3;
		#endif
	};

	void ComputeVertexLightColor (inout Interpolators i) {
		#if defined(VERTEXLIGHT_ON)
		i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.worldPos, i.normal
		);
			// float3 lightPos = float3(
			// 	unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x
			// );
			// float3 lightVec = lightPos - i.worldPos;
			// float3 lightDir = normalize(lightVec);
			// float ndotl = DotClamped(i.normal, lightDir);
			// float attenuation = 1 / (1 + dot(lightVec, lightVec) * unity_4LightAtten0.x);
			// i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;
		#endif
	}

	Interpolators vert(VertexData v) 
	{
		Interpolators i;

		i.pos = UnityObjectToClipPos(v.vertex);
		i.worldPos = mul(unity_ObjectToWorld, v.vertex);
		i.normal = UnityObjectToWorldNormal(v.normal);
		i.uv = TRANSFORM_TEX(v.uv, _MainTex);
		
		TRANSFER_SHADOW(i);
		
		ComputeVertexLightColor(i);

		return i;
	}

	UnityLight CreateLight (Interpolators i) {
		UnityLight light;
		
		#if defined(POINT) || defined(POINT_COOKIE)  || defined(SPOT)
			light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
		#else
			light.dir = _WorldSpaceLightPos0.xyz;
		#endif
		
//		#if defined(SHADOWS_SCREEN)
//		    float attenuation = SHADOW_ATTENUATION(i);
//		#else
//		    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
//		#endif
        UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
				
		light.color = _LightColor0.rgb * attenuation;
		light.ndotl = DotClamped(i.normal, light.dir);
		return light;
	}

	UnityIndirect CreateInderictLight (Interpolators i) {
		UnityIndirect indirectLight;
		indirectLight.diffuse = 0;
		indirectLight.specular = 0;
		
		#if defined(VERTEXLIGHT_ON)
			indirectLight.diffuse = i.vertexLightColor;
		#endif

		#if defined(FORWARD_BASE_PASS)
			indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
		#endif
		
		return indirectLight;
	}

	float4 frag(Interpolators i) : SV_TARGET
	{
		i.normal = normalize(i.normal);

		float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

		float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

		float3 specularTint;
		float oneMinusReflectivity;
		albedo = DiffuseAndSpecularFromMetallic(
		albedo, _Metallic, specularTint, oneMinusReflectivity
		);

		// float t = i.normal.x;
		// // return t > 0 ? t : float4(1, 0, 0, 1) * -t;
		// float3 shColor = ShadeSH9(float4(i.normal, 1));
		// return float4(shColor, 1);

		return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		CreateLight(i), CreateInderictLight(i)
		);
	}
#endif