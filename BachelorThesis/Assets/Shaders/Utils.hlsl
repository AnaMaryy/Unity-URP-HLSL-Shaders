#include <UnityShaderVariables.cginc>
///CUSTOM HLSL FILE WITH UTILS FUNCTIONS FOR SHADER
///
///used for translating shaders done in Built in Renderer pipeline to universal Render pipeline
///
// Transforms normal from object to world space
inline float3 UnityObjectToWorldNormal( in float3 norm )
{
    #ifdef UNITY_ASSUME_UNIFORM_SCALING
    return UnityObjectToWorldDir(norm);
    #else
    // mul(IT_M, norm) => mul(norm, I_M) => {dot(norm, I_M.col0), dot(norm, I_M.col1), dot(norm, I_M.col2)}
    return normalize(mul(norm, (float3x3)unity_WorldToObject));
    #endif
}


// Tranforms position from object to homogenous space
inline float4 UnityObjectToClipPos( in float3 pos )
{
    #if defined(UNITY_SINGLE_PASS_STEREO) || defined(UNITY_USE_CONCATENATED_MATRICES)
    // More efficient than computing M*VP matrix product
    return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(pos, 1.0)));
    #else
    return mul(UNITY_MATRIX_MVP, float4(pos, 1.0));
    #endif
}

// Computes world space view direction, from object space position
inline float3 UnityWorldSpaceViewDir( in float3 worldPos )
{
    return _WorldSpaceCameraPos.xyz - worldPos;
}

// Computes world space view direction, from object space position
// *Legacy* Please use UnityWorldSpaceViewDir instead
inline float3 WorldSpaceViewDir( in float4 localPos )
{
    float3 worldPos = mul(unity_ObjectToWorld, localPos).xyz;
    return UnityWorldSpaceViewDir(worldPos);
}
