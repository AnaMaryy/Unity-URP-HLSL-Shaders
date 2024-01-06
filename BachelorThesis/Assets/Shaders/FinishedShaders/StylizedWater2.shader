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
        _UvScrollSpeed("Uv Scroll Speed", Vector) = (0.05, 0.05, 0, 0)
        _FoamDistance("Foam Distance", Range(0, 1)) = 0.4
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FoamSmoothStepBlend("Foam Smooth Step Blend" , float) = 0.001

        [Header(Animation water texture)]
        _VoronoiSpeed("Voronoi Speed", Range(0,10))=2
        _VoronoiCellDensitiy("Voronoi Cell Densitiy", int)= 50
        _RadialSheerStrength("Radial Sheer Strength" , float) = 1

        // Control to multiply the strength of the distortion.
        [Header(Animation vertex distortion)]
        _WaveFrequency("Wave Frequency", Range(0,20))=1
        _WaveSpeed("WaveSpeed", Range(0,10))=1

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
            #include "Assets/Shaders/Utilities.hlsl"


            //texture samplers
            TEXTURE2D(_SurfaceColorNoise);
            SAMPLER(sampler_SurfaceColorNoise);

            TEXTURE2D(_WavesDistortionTex);
            SAMPLER(sampler_WavesDistortionTex);


            CBUFFER_START(UnityPerMaterial)
            //water color
            float4 _ColorShallowWater, _ColorDeepWater;
            float _DepthMaxDistance, _WaterDepthIntersectPower;

            //foam
            float4 _SurfaceColorNoise_ST;
            float _FoamDistance;
            float4 _FoamColor;
            float _FoamSmoothStepBlend;

            //animation water texture
            float _VoronoiSpeed;
            int _VoronoiCellDensitiy;
            float _RadialSheerStrength;
            // animation
            float2 _UvScrollSpeed;

            //vertex animation
            float _WaveFrequency;
            float _WaveSpeed;


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

            float4 alphaBlend(float4 colorOne, float4 colorTwo)
            {
                float3 finalColor = (colorOne.rgb * colorOne.a) + (colorTwo.rgb * (1 - colorOne.a));
                float alpha = colorOne.a + colorTwo.a * (1 - colorOne.a);
                return float4(finalColor, alpha);
            }


            Varyings vert(Attributes IN)
            {
                float noiseOne;
                float2 distortedUv = IN.uv + _Time.y * _WaveSpeed * 0.05;
                Unity_SimpleNoise_float(distortedUv, _WaveFrequency, noiseOne);
                IN.positionOS.xyz += IN.normalOS * noiseOne;

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

                //uv scroll animation
                float2 uvWithNoise = float2((IN.uv.x + _Time.y * _UvScrollSpeed.x),
                                            (IN.uv.y + _Time.y * _UvScrollSpeed.y));
                // surface foam  color noise
                float surfaceNoiseSample = SAMPLE_TEXTURE2D(_SurfaceColorNoise, sampler_SurfaceColorNoise, uvWithNoise).r;

                float surfaceNoise = smoothstep(foamDepthDifference - _FoamSmoothStepBlend,
                                                foamDepthDifference + _FoamSmoothStepBlend, surfaceNoiseSample);

                float4 foamColor = _FoamColor * surfaceNoise;

                // voronoi water pattern
                float voronoi, cells;
                float2 radialSheerUv;
                Unity_RadialShear_float(IN.uv, float2(0.5f,0.5f),_RadialSheerStrength,float2(0,0), radialSheerUv);
                Unity_Voronoi_float(radialSheerUv, _Time * _VoronoiSpeed, _VoronoiCellDensitiy, voronoi, cells);
                float4 waterVoronoiColor = voronoi * _FoamColor;

                //final colors
                waterColor= alphaBlend(waterVoronoiColor, waterColor);
                return alphaBlend(foamColor,waterColor);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}