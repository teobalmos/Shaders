// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(SHADOWS_INCLUDED)
#define SHADOWS_INCLUDED

#include "UnityCG.cginc"

struct VertexData {
	float4 position : POSITION;
	float3 normal : NORMAL;
};

// solving point light cube maps issue - not necessary
#if defined(SHADOWS_CUBE)
    struct Interpolators{
        float4 position : SV_POSITION;
        float3 lightVec : TEXCOORD0;
    };
    
    Interpolators shadowVert (VertexData v){
        Interpolators i;
        i.position = UnityObjectToClipPos(v.position);
        i.lightVec = mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
        
        return i;
    }
    
    float4 shadowFrag (Interpolators i) : SV_TARGET{
        float depth = length(i.lightVec) + unity_LightShadowBias.x;
        depth *= _LightPositionRange.w;
        return UnityEncodeCubeShadowDepth(depth);
    }
    
#else
    float4 shadowVert (VertexData v) : SV_POSITION {
        float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
        return UnityApplyLinearShadowBias(position);
    }
    
    half4 shadowFrag () : SV_TARGET {
        return 0;
    }
#endif
#endif
