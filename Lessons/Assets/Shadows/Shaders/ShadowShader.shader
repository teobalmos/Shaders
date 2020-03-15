// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/ShadowShader"
{
	Properties {
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}
		// _SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
		[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0,1)) = 0.5
	}
	SubShader {
		Pass {
			Tags {
				"LightMode" = "ForwardBase"
			}
			CGPROGRAM

			#pragma target 3.0
            
            #pragma multi_compile _ SHADOW_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON

			#pragma vertex vert
			#pragma fragment frag

			#define FORWARD_BASE_PASS

			#include "My Lighting.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}
			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_fwdadd_fullshadows

			#pragma vertex vert
			#pragma fragment frag

			#include "My Lighting.cginc"

			ENDCG
		}
		
		Pass{
		    Tags{
		        "LightMode" = "ShadowCaster"
		    }
		    
		    CGPROGRAM
		    
		    #pragma target 3.0
		    
		    // solving point light cube maps issue - not necessary
		    #pragma multi_compile_shadowcaster
		    
		    #pragma vertex shadowVert
		    #pragma fragment shadowFrag
		    
		    #include "Shadows.cginc"
		    
		    ENDCG
		}
	}
}
