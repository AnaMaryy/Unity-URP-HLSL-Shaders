Shader "Thesis/StylizedWater2"
{
    Properties
    {
        _ColorShallowWater("Color Shallow Water", Color) = (0.325, 0.807, 0.971, 0.725)
        _ColorDeepWater("Color Deep Water", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Range(0,10)) = 1
        _WaterDepthIntersectPower("Water Depth Intersect Power", Range(0,10)) = 1

        [Header(Foam)]
        _SurfaceColorNoise("Surface Color Noise", 2D) = "white" {}
        _SurfaceColorNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777 // to toonify
        _FoamDistance("Foam Distance", Range(0, 1)) = 0.4
        _FoamColor("Foam Color", Color) = (1,1,1,1)

        [Header(Animation)]
        _UvScrollSpeed("Uv Scroll Speed", Vector) = (0.05, 0.05, 0, 0)
        _WavesDistortionTex("Waves Distortion Texture", 2D) = "white" {}
        // Control to multiply the strength of the distortion.
        _WaveDistortionAmount("Wave Distortion Amount", Range(0, 1)) = 0.5

    }

    // you had to enable depth write on camera
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            HLSLPROGRAM
            // #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //texture samplers
            TEXTURE2D(_SurfaceColorNoise);
            SAMPLER(sampler_SurfaceColorNoise);

            TEXTURE2D(_WavesDistortionTex);
            SAMPLER(sampler_WavesDistortionTex);


            CBUFFER_START(UnityPerMaterial)
            float4 _ColorShallowWater, _ColorDeepWater;
            float _DepthMaxDistance, _WaterDepthIntersectPower;
            float4 _SurfaceColorNoise_ST;
            float _SurfaceColorNoiseCutoff;
            float _FoamDistance;
            float4 _FoamColor;

            // animation
            float2 _UvScrollSpeed;
            float4 _WavesDistortionTex_ST;
            float _WavesDistortionAmount;


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
                float4 screenPosition : TEXCOORD3;
            };


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                OUT.screenPosition = ComputeScreenPos(OUT.positionHCS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _SurfaceColorNoise);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //water color based on camera depth
                float2 screenUVs = IN.screenPosition.xy / IN.screenPosition.w;
                // transform from ortographic to perspective projection
                float rawDepth = SampleSceneDepth(screenUVs);

                float existingDepthLinear = LinearEyeDepth(rawDepth, _ZBufferParams);

                float depthDifference = existingDepthLinear - IN.screenPosition.w;

                float waterDepthDifferencePercentage = saturate(depthDifference / _DepthMaxDistance);
                float intersectAmount = pow(waterDepthDifferencePercentage, _WaterDepthIntersectPower);

                float4 waterColor = lerp(_ColorShallowWater, _ColorDeepWater, intersectAmount);

                //foam on the edges
                float foamDepthDifference = saturate(depthDifference / _FoamDistance);
                float surfaceNoiseCutoff = foamDepthDifference * _SurfaceColorNoiseCutoff;

                //animation -> noise texture
                float2 wavesDistortion = (SAMPLE_TEXTURE2D(_WavesDistortionTex, sampler_WavesDistortionTex, IN.uv).xy *
                    2 - 1) * _WavesDistortionAmount;

                //uv scroll animation
                float2 uvWithNoise = float2((IN.uv.x + _Time.y * _UvScrollSpeed.x) + wavesDistortion.x,
                                            (IN.uv.y + _Time.y * _UvScrollSpeed.y) + wavesDistortion.y);
                // surface color noise
                float surfaceNoiseSample = SAMPLE_TEXTURE2D(_SurfaceColorNoise, sampler_SurfaceColorNoise, uvWithNoise).
                    r;
                float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutoff ? surfaceNoiseSample : 0;
                float4 foamColor = surfaceNoise * _FoamColor;

                return waterColor + foamColor;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}