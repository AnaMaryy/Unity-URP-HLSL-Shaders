Shader "Thesis/HalftroneEffect"
{
    Properties
    {
        [Header(Common)]
        _BaseColor("Base Color", Color) = (1, 1, 1, 0)
        [NoScaleOffset]_BaseMap("Base Texture", 2D) = "white" {}
        
        [Header(Halftone Settings)]
        _ShadingMultiplier("Shading Multiplier", Float) = 0.1 //how dark is the shadow
        _CircleDensity("Circle Density", Float) = 5 // circle size
        _CircleColor("Circle Color", Color) = (0,0,0, 1) 
        _Softness("Softness", Range(0, 1)) = 0 // how much blending there is for each dot
        _Rotation("Rotation", Float) = 0 //rotate dots
        _LitTreshold("Lit Treshold", Float) = 1 // where the shadow line is
        _FalloffThreshold("Falloff Threshold", Float) = 2.5 // how large the dot region is
        [Toggle(_USE_SCREEN_SPACE)]_USE_SCREEN_SPACE("Use Screen Space", Float) = 1 //if false the dots are alligned to the object geometry, else they are not
        _VoronoiAngleOffset("Voronoi Angle Offset", Float) = 0
        _VoronoiCellDensity("Voronoi Cell Density", Float) = 5
        [Toggle(_USE_VORONOI_PATTERN)]_USE_VORONOI_PATTERN("Use Voronoi Pattern", Float) = 0
        [NoScaleOffset]_PatternTexture("Pattern Texture", 2D) = "white" {} 
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Blend Off
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _USE_SCREEN_SPACE
            #pragma shader_feature_local _USE_VORONOI_PATTERN


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Utilities.hlsl"


            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float _ShadingMultiplier;
            float _CircleDensity;
            float _Softness;
            float _Rotation;
            float _LitTreshold;
            float _FalloffThreshold;
            float4 _CircleColor;
            float _VoronoiAngleOffset;
            float _VoronoiCellDensity;
            CBUFFER_END


            TEXTURE2D(_BaseMap);
            float4 _BaseMap_ST;
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_PatternTexture);
            float4 _PatternTexture_ST;
            SAMPLER(sampler_PatternTexture);


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 normalWS: NORMAL;
                float4 screenPos : TEXCOORD3;
            };


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);

                float4 positionCS = ObjectToClipPos(IN.positionOS);
                OUT.screenPos = ComputeScreenPos(positionCS);
                OUT.screenPos = OUT.screenPos / OUT.screenPos.w;

                return OUT;
            }


            half4 frag(Varyings IN) : SV_Target
            {
                //variables
                float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                float3 mainLightDir = normalize(mainLight.direction);
                float shadowAttenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                float3 normal = normalize(IN.normalWS);
                float NDotL = dot(normal, mainLightDir);

                //sample texture 
                float4 mainTexture = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;


                //unlit color -> convert between color spaces and soften shadow 
                float3 hsv;
                Unity_ColorspaceConversion_RGB_HSV_float(mainTexture.rgb, hsv);
                hsv.b *= _ShadingMultiplier;
                float3 rgb;
                Unity_ColorspaceConversion_HSV_RGB_float(hsv, rgb);

                //diffuse light + color of circles
                float diffuseLight = NDotL * shadowAttenuation;
                float4 diffuseLightAndCircleColor = diffuseLight + _CircleColor;
                diffuseLightAndCircleColor *= -1; // negate

                rgb *= diffuseLight * _MainLightColor;

                //remap values -> set shadow treshold 
                float2 outMinMax = float2(_LitTreshold - _FalloffThreshold, _LitTreshold);
                float2 inMinMax = float2(-1, 1);
                float4 remap;
                Unity_Remap_float4(diffuseLightAndCircleColor, inMinMax, outMinMax, remap);

                //todo : check if theres a better way
                float4 remapShadow = remap + _Softness;


                //adjust texture of dots to screen ratio; so it is not streched
                float screenRatio = _ScreenParams.x / _ScreenParams.y;
                float newY = IN.screenPos.y / screenRatio;
                float2 adjustedScreenRatio = float2(IN.screenPos.x, newY);

                //generate halfthrone grid
                float2 input;
                #ifdef _USE_SCREEN_SPACE
                input = adjustedScreenRatio;
                #else
                    input = IN.uv;
                #endif
                float2 circleDensity = input * _CircleDensity;
                Unity_Rotate_Radians_float(circleDensity, half2(0.5f, 0.5f), _Rotation, circleDensity);

                //voronoi
                float pattern;
                float cells;

                #ifdef _USE_VORONOI_PATTERN
                Unity_Voronoi_float(circleDensity, _VoronoiAngleOffset, _VoronoiCellDensity, pattern, cells);
                #else
                //noise texture
                pattern = SAMPLE_TEXTURE2D(_PatternTexture, sampler_PatternTexture, circleDensity);
                #endif


                // final steps
                float4 patternsSmooth;
                Unity_Smoothstep_float4(remap, remapShadow, pattern, patternsSmooth); 
                float3 finalColor = lerp(rgb, mainTexture, patternsSmooth);

                return half4(finalColor.r, finalColor.g, finalColor.b, 1);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}