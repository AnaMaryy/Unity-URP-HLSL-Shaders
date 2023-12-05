Shader "Thesis/WaterColor"
{
    Properties
    {
        [Header(Common)]
        [MainColor] _Color("Base Color", Color) = (1, 1, 1, 1)

        [Header(WaterColor)]
        _ShadowColor("Shadow Color", Color) = (1, 1, 1, 1)
        _DiffuseBrightness("Diffuse Brightness", Range(0,1)) = 0.6
        _WaterColorNoiseTexture("Water Color Noise Texture", 2D)= "white" {}
        _WaterColorNoiseStrength("Water Color Noise Strength",Range(0,3)) = 1
        _WaterColorNoiseBrightness("Water Color Noise Brightness",Range(0,1)) = 1

        [Header(Fresnel)]
        _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _FresnelIntensity("Fresnel Intensity", Range(0,10)) = 0
        _FresnelRamp("Fresnel Ramp", Range(0,10))= 0
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Utilities.hlsl"

            //texture samplers
            TEXTURE2D(_WaterColorNoiseTexture);
            SAMPLER(sampler_WaterColorNoiseTexture);

            CBUFFER_START(UnityPerMaterial)
            half4 _Color, _ShadowColor;
            float _DiffuseBrightness;
            float _WaterColorNoiseStrength, _WaterColorNoiseBrightness;

            //fresnel
            float4 _FresnelColor;
            float _FresnelIntensity;
            float _FresnelRamp;

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

            void MainLight_float(float3 WorldPos, out float3 Direction, out float3 Color,
                                 out float DistanceAtten, out float ShadowAtten)
            {
                Light mainLight = GetMainLight();
                Direction = mainLight.direction;
                Color = mainLight.color;
                DistanceAtten = mainLight.distanceAttenuation;

                float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
                ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                float shadowStrength = GetMainLightShadowStrength();
                ShadowAtten = SampleShadowmap(shadowCoord,
                                              TEXTURE2D_ARGS(_MainLightShadowmapTexture,
                                                             sampler_MainLightShadowmapTexture), shadowSamplingData,
                                              shadowStrength, false);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 ShadowOffset(float3 worldPos)
            {
                float shadowNoiseOne;
                float shadowNoiseTwo;
                Unity_SimpleNoise_float(float2(worldPos.x, worldPos.z), 20, shadowNoiseOne);
                Unity_SimpleNoise_float(float2(worldPos.x, worldPos.z), 80, shadowNoiseTwo);
                shadowNoiseTwo *= 0.5f;

                float noise = (shadowNoiseOne + shadowNoiseTwo) * 0.3f;


                float3 offsetShadowCoord = float3(noise - 0.2f, 0, noise);
                return float4(worldPos - offsetShadowCoord, 0);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.normalWS);
                //main light

                float4 shadowCoord = ShadowOffset(IN.positionWS);
                half3 lightDir;
                half3 lightColor;
                float distanceAttenuation;
                half shadowAttenuation;
                // light calculation
                MainLight_float(shadowCoord, lightDir, lightColor, distanceAttenuation, shadowAttenuation);

                //watercolor final Shadow
                float waterColorShadowX = (1 - shadowAttenuation) * 0.5f;
                float waterColorShadowZ = step(shadowAttenuation, 0.95f);
                float shadow = lerp(1, waterColorShadowX, waterColorShadowZ);


                //brighter diffuse
                float NDotL = saturate(dot(normal, lightDir));
                float brighterDiffuse = saturate(NDotL + _DiffuseBrightness);


                //noise texturing; watercolor noise
                float4 triplanarNoise = SAMPLE_TEXTURE2D(_WaterColorNoiseTexture, sampler_WaterColorNoiseTexture, IN.uv);

                //combine watercolor texture noise and shadow; REGULAR NOISE
                float shadowNoise = saturate(triplanarNoise.r+0.8f);
                shadowNoise *= brighterDiffuse;
                float finalWaterColorShadow = shadow+ shadowNoise;
                
                //waterColor noise 
                float waterColorNoise = abs(triplanarNoise.r * _WaterColorNoiseStrength- 0.3f);
                waterColorNoise = saturate(waterColorNoise + _WaterColorNoiseBrightness);

                //x watercolour Noise
                finalWaterColorShadow *= waterColorNoise;


                //fresnel
                float fresnelAmount = 1 - max(0, dot(normal, IN.viewDirWS));
                fresnelAmount = pow(fresnelAmount, _FresnelRamp) * _FresnelIntensity;

                //FINAL COLOR
                float4 finalColor = lerp(_ShadowColor,finalWaterColorShadow* _Color, finalWaterColorShadow*fresnelAmount );
                return finalColor;
                
            }
            ENDHLSL
        }
        
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}