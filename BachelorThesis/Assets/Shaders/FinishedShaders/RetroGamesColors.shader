Shader "Thesis/GameboyColors"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Texture", 2D) = "white" {}
        _ColorRamp("Color Ramp", 2D) = "white" {}
        _GridSpacing("Grid Spacing", float) = 16
        _GridThickness("GridThickness", float) = 1
        _GridColor("GridColor", Color) = (93, 113, 9,1)
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

            TEXTURE2D(_ColorRamp);
            SAMPLER(sampler_ColorRamp);

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _ColorRamp_ST;
            float4 _GridColor;
            float _GridSpacing, _GridThickness;

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
                float3 normalWS: NORMAL;
                float4 screenPos : TEXCOORD3;
            };


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float normal = normalize(IN.normalWS);
                float4 lightPos = normalize(_MainLightPosition);
                float NDotL = saturate(dot(lightPos, normal));

                float3 light = NDotL * _MainLightColor;
                mainTex.rgb = mainTex.rgb * light;

                //greyscale
                float greyscale = dot(mainTex.rgb, float3(0.2126, 0.7152, 0.0722));
                float2 rampUv = float2(saturate(greyscale), 0.5f);
                half4 rampTex = SAMPLE_TEXTURE2D(_ColorRamp, sampler_ColorRamp, rampUv);

                // Calculate grid lines
                float2 gridLines = float2(fmod(IN.uv.x * _ScreenParams.x, _GridSpacing),
                                          fmod(IN.uv.y * _ScreenParams.y, _GridSpacing));
                // Add grid lines
                float grid = 1 - step(_GridThickness, gridLines.x) * step(_GridThickness, gridLines.y);

                return rampTex + _GridColor * grid;
            }
            ENDHLSL
        }

    }
}