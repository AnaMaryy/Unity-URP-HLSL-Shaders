Shader "Thesis/Bending"
{
    Properties
    {
        [Header(Common)]
        [MainTexture] _BaseMap("Base Texture", 2D) = "white" {}
        [MainColor] _Color("Base Color", Color) = (1, 1, 1, 1)
        _CurvatureY("Curvature Y", Range(-0.01,0.1))= 0
        _CurvatureX("Curvature X", Range(-0.01,0.1))= 0
        _CurvatureZ("Curvature Z", Range(-0.01,0.1))= 0
    }


    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Blend Off
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //texture samplers
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _BaseMap_ST;
            float _CurvatureY, _CurvatureX, _CurvatureZ;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            Varyings vert(Attributes IN)
            {
                float3 posWorldSpace = TransformObjectToWorld(IN.positionOS);
                float3 cameraDistance = posWorldSpace - _WorldSpaceCameraPos;
                float cameraDistanceZSquared = pow(cameraDistance.z, 2);
                float3 offset = float3(cameraDistanceZSquared * -_CurvatureX, cameraDistanceZSquared * -_CurvatureY, cameraDistanceZSquared * -_CurvatureZ);
                posWorldSpace += offset;
                IN.positionOS.xyz = TransformWorldToObject(posWorldSpace);

                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 output = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;
                return output;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}