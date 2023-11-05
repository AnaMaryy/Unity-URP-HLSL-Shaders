Shader "Thesis/StylizedWater"
{
    Properties
    {
        _WaterDepth("Water Depth", Range(0,10))=1
        _WaterIntersectPower("Water Intersect Power", Range(0,10))=1

        _WaterSurfaceColor("Water Surface Color", Color) = (1,1,1,1)
        _WaterDepthColor("Water Depth Color", Color) = (1,1,1,1)

        _WaterRefractionSpeed("Water Refraction Speed", Range(0,10))=1
        _WaterRefractionScale("Water Refraction Scale", Range(0,10))=1
        
        _MainNormal("Main Normal", 2D) = "white" {}
        _SecondNormal("Second Normal", 2D) = "white" {}
    }


    SubShader
    {
        Tags
        {
 "Queue" = "Transparent"
            "RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline"        }
        Pass
        {
               ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Assets/Shaders/Utilities.hlsl"


            //texture samplers
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;

            float _WaterDepth, _WaterIntersectPower;
            half4 _WaterSurfaceColor, _WaterDepthColor;
            float _WaterRefractionSpeed, _WaterRefractionScale, _WaterRefractionNoiseScale, _WaterRefractionStrength;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS: NORMAL;
                float3 viewDirWS : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float4 tangent : TEXCOORD4;
                float3 bitangent : TEXCOORD5;
            };


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                OUT.tangent.xyz = TransformObjectToWorldDir(IN.tangent.xyz);
                OUT.tangent.w = IN.tangent.w;
                OUT.bitangent = cross(OUT.normalWS, OUT.tangent.xyz) * OUT.tangent.w;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //WATER REFRACTION
                //Speed of refraction
                float time = _Time * _WaterRefractionSpeed;
                float2 uvSpeed = Unity_TilingAndOffset_float(IN.uv, _WaterRefractionScale, time);

                //todo : ana to change this you could instead provide a normal texture... 
                // float noise;
                // Unity_SimpleNoise_float(uvSpeed, _WaterRefractionNoiseScale, noise);
                // float3 noiseNormalMap;
                // float3x3 tangentMatrix = float3x3(normalize(IN.tangent.xyz), normalize(IN.bitangent),
                //                                   normalize(IN.normalWS));
                // Unity_NormalFromHeight_Tangent_float(noise, 1, IN.positionWS, tangentMatrix, noiseNormalMap);
                // noiseNormalMap = noiseNormalMap * _WaterRefractionStrength;
                // float3 finalNoise = noiseNormalMap + IN.screenPos;
                
                //water depth and intersection
                float2 screenUVs = IN.screenPos.xy / IN.screenPos.w;
                float rawDepth = SampleSceneDepth(screenUVs);
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float intersectAmount = sceneEyeDepth - IN.screenPos.w;
                intersectAmount = saturate(intersectAmount / _WaterDepth);
                intersectAmount = pow(intersectAmount, _WaterIntersectPower);

                //water color
                float4 waterDepthColor = lerp(_WaterSurfaceColor, _WaterDepthColor, intersectAmount);
                //float3 finalColor = lerp(finalNoise, waterDepthColor, waterDepthColor.w);

                // half4 output = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;
                return half4(waterDepthColor);
            }
            ENDHLSL
        }

    }
}