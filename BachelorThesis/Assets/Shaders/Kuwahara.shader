Shader "Thesis/Kuwahara"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Texture", 2D) = "white" {}
        [MainColor] _Color("Base Color", Color) = (1, 1, 1, 1)
        _QuadrantSizeX("Quadrant Size X", int) = 5
        _QuadrantSizeY("Quadrant Size Y", int) = 5

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
            float4 _BaseMap_TexelSize;
            int _QuadrantSizeX, _QuadrantSizeY;

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
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }


            float4 SampleQuadrant(float2 uv, int x1, int x2, int y1, int y2, int n)
            {
                float3 average_color;
                // get mean
                for (int x = x1; x <= x2; ++x)
                {
                    for (int y = y1; y <= y2; ++y)
                    {
                        float2 selectedUv = float2(uv.x + x / _BaseMap_TexelSize.x, uv.y + y * _BaseMap_TexelSize.y);
                        float3 pixelColor = (SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, selectedUv) * _Color).rgb;
                        average_color += pixelColor;
                       ;
                    }
                }
                average_color /= n;
                //get standard deviation
                float3 deviation;
                for (int x = x1; x <= x2; ++x)
                {
                    for (int y = y1; y <= y2; ++y)
                    {
                        float2 selectedUv = float2(uv.x + x / _BaseMap_TexelSize.x, uv.y + y * _BaseMap_TexelSize.y);
                        float3 pixelColor = (SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, selectedUv) * _Color).rgb;
                        deviation += pow(pixelColor - average_color, 2);
                    }
                }
                float std = sqrt(deviation / (n - 1));
                return float4(average_color, std);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                int numOfSamples = (_QuadrantSizeX + 1) * (_QuadrantSizeY + 1);

                float4 quadrant1 = SampleQuadrant(IN.uv, -_QuadrantSizeX, 0, -_QuadrantSizeY, 0, numOfSamples);
                float4 quadrant2 = SampleQuadrant(IN.uv, 0, _QuadrantSizeX, -_QuadrantSizeY, 0, numOfSamples);
                float4 quadrant3 = SampleQuadrant(IN.uv, -_QuadrantSizeX, 0, 0, _QuadrantSizeY, numOfSamples);
                float4 quadrant4 = SampleQuadrant(IN.uv, 0, _QuadrantSizeX, 0, _QuadrantSizeY, numOfSamples);

                float minStd = min(quadrant4.a, min(quadrant3.a, min(quadrant2.a, quadrant1.a)));

                if (minStd == quadrant1.a)
                {
                    return half4(quadrant1.rgb, 1);
                }
                if (minStd == quadrant2.a)
                {
                    return half4(quadrant2.rgb, 1);
                }
                if (minStd == quadrant3.a)
                {
                    return half4(quadrant3.rgb, 1);
                }

                return half4(quadrant4.rgb, 1);
                
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}