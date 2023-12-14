Shader "Thesis/SnowShader"
{
    Properties
    {
        [Header(Common)]
        [MainTexture] _BaseMap("Base Texture", 2D) = "white" {}
        [MainColor] _Color("Base Color", Color) = (1, 1, 1, 1)
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _RimThreshold("Rim Threshold", Float)=1
        _Shininess("Shininess", Float)=1

        [Header(Snow Base)]
        _Snow_Texture("Snow texture", 2D) = "white" {}
        _Snow_Direction("Snow Direction", Vector) = (0, 1, 0, 0)
        _Snow_Amount("Snow Amount", Range(0, 1)) = 0.7
        _Snow_Blend_Distance("Snow Blend Distance", Range(0, 1)) = 0.41
        
        _Snow_BuildUp_Noise_Size("BuildUp Noise Size", Float) = 100
        _Snow_Height("Snow Height", Range(0, 0.5)) = 0

        [Header(Snow Color)]
        [HDR]_Snow_Primary_Color("Snow Primary Color", Color) = (1, 1, 1, 0)
        [HDR]_Snow_Secondary_Color("Snow Primary Color", Color) = (1, 1, 1, 0)
        _Snow_Color_Noise_Size("Snow Color Noise Size", Float) = 63.8
        _Snow_Color_Noise_Strength("Snow Color Noise Strength", Range(0, 1)) = 0.38
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
            #include "Assets/Shaders/Utilities.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _BaseMap_ST;
            float4 _SpecularColor;
            float _RimThreshold;
            float _Shininess;
            float4 _Snow_Texture_ST;
            float3 _Snow_Direction;
            float _Snow_Amount;
            float _Snow_Blend_Distance;
            float _Snow_BuildUp_Noise_Size;
            float _Snow_Color_Noise_Size;
            float _Snow_Color_Noise_Strength;
            float4 _Snow_Primary_Color;
            float4 _Snow_Secondary_Color;
            float _Snow_Height;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_Snow_Texture);
            SAMPLER(sampler_Snow_Texture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS: NORMAL;
                float3 viewDirWS : TEXCOORD2;
                float snowNoise :TEXCOORD3;
            };

            float SnowNoise(float2 uv)
            {
                float simpleNoiseOne;
                Unity_SimpleNoise_float(uv, _Snow_BuildUp_Noise_Size, simpleNoiseOne);
                float simpleNoiseGolderRatio;
                Unity_SimpleNoise_float(uv, _Constant_PHI * _Snow_BuildUp_Noise_Size, simpleNoiseGolderRatio);
                float combinedNoise = lerp(simpleNoiseOne, simpleNoiseGolderRatio, 0.5f);
                float noiseValue = smoothstep(1 - _Snow_Amount, 1 - _Snow_Amount + _Snow_Blend_Distance, combinedNoise);
                return noiseValue;
            };

            //combines two defined colors of the snow with a noise 
            float4 SnowColor(float2 uv, float NdotSnowDirection)
            {
                float4 primaryColor = NdotSnowDirection * _Snow_Primary_Color;
                float4 secondaryColor = NdotSnowDirection * _Snow_Secondary_Color;

                //noise for the color distrubution
                float colorNoise;
                Unity_SimpleNoise_float(uv, _Snow_Color_Noise_Size, colorNoise);
                //todo : ana skipped remap
                Unity_Remap_float(colorNoise, float2(0, 1), float2(1 - _Snow_Color_Noise_Strength, 0), colorNoise);

                primaryColor *= colorNoise;
                secondaryColor *= colorNoise;
                float4 finalColor = lerp(primaryColor, secondaryColor, colorNoise);

                return finalColor;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                //Snow calculations
                float snowPattern = saturate(SnowNoise(OUT.uv));
                float3 snowDirection = normalize(_Snow_Direction);
                float NdotSnowDir = saturate(dot(normalize(TransformObjectToWorldNormal(IN.normal)), snowDirection));
                snowPattern *= NdotSnowDir;
                IN.positionOS.y += snowPattern * _Snow_Height;
                OUT.snowNoise = snowPattern;

                //other transformations
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz); //transforms position to clip space
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //variables
                float3 normal = normalize(IN.normalWS);
                float4 lightPos = normalize(_MainLightPosition);
                float3 viewDir = normalize(IN.viewDirWS);
                float3 snowDirection = normalize(_Snow_Direction);
                float3 halfwayDir = normalize(lightPos + viewDir);


                //general calculations
                float NdotL = dot(normal, lightPos);
                float NdotV = dot(normal, viewDir);
                float4 base_texture = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;
                float4 snow_texture = SAMPLE_TEXTURE2D(_Snow_Texture, sampler_Snow_Texture, IN.uv) *
                    _Snow_Primary_Color; // todo : ana change the multiplication with legit snow color

                //lighting calculations
                float diffuse = max(0, NdotL);
                float rim = pow(1.0 - max(0, NdotV), _RimThreshold);
                float specular = pow(max(0, dot(normal, halfwayDir)), _Shininess);

                //snow 
                float NdotSnowDir = saturate(dot(normal, snowDirection));
                float4 snowColor =  SnowColor(IN.uv, NdotSnowDir);
                snow_texture *= snowColor;

                float snowPattern = (SnowNoise(IN.uv) * NdotSnowDir);
                float4 lerpedTextures = lerp(base_texture, snow_texture, snowPattern);

                half4 output = lerpedTextures * (diffuse + rim + specular) * _SpecularColor ;

                return output;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"


    }
}