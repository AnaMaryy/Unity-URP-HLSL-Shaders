Shader "Thesis/SketchyOutline"
{
    Properties
    {
        _OutlineNoiseScale("Outline Noise Scale", Range(0,100))= 10
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
        _ScissorValue ("Scissor Value", Range(0,1)) = 0.5
        _FalloffCurve ("Falloff Curve", 2D) = "white" {}
        _OutlineSize ("Outline Size", Range(0,1)) = 0.1
        _OffsetFres ("Offset Fres", Range(0,1)) = 0.3
    }


    SubShader
    {
        Tags
        {
            "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" //"RenderType" = "Opaque"
        }
        Pass
        {

            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Shaders/Utilities.hlsl"


            //texture samplers

            TEXTURE2D(_FalloffCurve);
            SAMPLER(sampler_FalloffCurve);

            CBUFFER_START(UnityPerMaterial)
            half4 _OutlineColor;
            float4 _FalloffCurve_ST;
            float _OutlineNoiseScale;
            float _ScissorValue;
            float2 _UVScale;
            float _OutlineSize;
            float _OffsetFres;
            float _FPS;


            CBUFFER_END


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS: NORMAL;
                float3 viewDirWS : TEXCOORD2;
            };


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float simpleNoise;
                Unity_SimpleNoise_float(IN.uv, _OutlineNoiseScale, simpleNoise);

                IN.positionOS.xyz += IN.normalOS * _OutlineSize * simpleNoise;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // float fres = abs(dot(normalize(-IN.viewDirWS), normalize(IN.worldRefl)));
                float3 normal = normalize(IN.normalWS);
                float angle = atan2(normal.y, normal.x) / 3.14;
                half alpha = SAMPLE_TEXTURE2D(_FalloffCurve, sampler_FalloffCurve,float2(angle * _UVScale.x + IN.positionHCS.x, normal.z * _UVScale.y )).r ;//* fres_remap

                alpha = round(alpha);
                clip(alpha);

                return half4(alpha,alpha,alpha, 1);
                // float fres_remap = tex2D(_FalloffCurve, float2(1.0 - fres, 0)).r + _OffsetFres;
                // o.Alpha = tex2D(_OutlineNoiseTex, float2(angle * _UVScale.x + IN.screenPos.x, nor.z * _UVScale.y + floor(_Time.y * _FPS) / _FPS)).r * fres_remap;
                // o.Albedo = _OutlineColor.rgb;
                // o.AlphaClip = _ScissorValue;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}