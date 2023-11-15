Shader "Thesis/Crosshatching"
{
    Properties
    {
        [Header(Common)]
        [MainTexture] _BaseMap("Base Texture", 2D) = "white" {}
        [MainColor] _Color("Base Color", Color) = (1, 1, 1, 1)
        _CrossHatchingTexture1("CrossHatching Texture 1", 2D) = "white" {}
        _CrossHatchingTexture2("CrossHatching Texture 2", 2D) = "white" {}
        _CrossHatchingTexture3("CrossHatching Texture 3", 2D) = "white" {}

        _CrossHatchingTexNum("CrossHatching Textures Number", int) = 6
        _Repeat ("Repeat", Vector) = (1, 1, 1, 1)


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

            TEXTURE2D(_CrossHatchingTexture1);
            SAMPLER(sampler_CrossHatchingTexture1);
            TEXTURE2D(_CrossHatchingTexture2);
            SAMPLER(sampler_CrossHatchingTexture2);
            TEXTURE2D(_CrossHatchingTexture3);
            SAMPLER(sampler_CrossHatchingTexture3);

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _BaseMap_ST;
            float4 _CrossHatchingTexture1_ST, _CrossHatchingTexture2_ST, _CrossHatchingTexture3_ST;
            int _CrossHatchingTexNum;
            float4 _Repeat;

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
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap) *_Repeat;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 mainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;
                float3 normal = normalize(IN.normalWS);
                float4 lightPos = normalize(_MainLightPosition);
                float NDotL = saturate(dot(lightPos, normal));

                float3 light = NDotL * _MainLightColor;
                mainTex.rgb = mainTex.rgb * light;
                float brightness = 1 - dot(mainTex.rgb, half3(0.3f, 0.59f, 0.11f));
                // Calculate the index of the texture based on shading
                float step = 1.0 / _CrossHatchingTexNum;

                float2 crosshatchUV = float2(brightness, IN.uv.y); // Corrected y-coordinate
                // half4 tonalMapValue = SAMPLE_TEXTURE2D(_CrossHatchingTexture1, sampler_CrossHatchingTexture1,
                //                                        crosshatchUV);
                half4 hatchValue;
                 if (brightness <= step) {
                   hatchValue =  SAMPLE_TEXTURE2D(_CrossHatchingTexture3, sampler_CrossHatchingTexture3,IN.uv);
                } else if (brightness > step && brightness <= 2.0 * step) {
                   hatchValue =  SAMPLE_TEXTURE2D(_CrossHatchingTexture2, sampler_CrossHatchingTexture2,IN.uv);
                } else  {
                   hatchValue =  SAMPLE_TEXTURE2D(_CrossHatchingTexture1, sampler_CrossHatchingTexture1,IN.uv);
                }
                
                return half4( hatchValue.rgb, 1);

                // half4 mainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;
                // float3 normal = normalize(IN.normalWS);
                // float4 lightPos = normalize(_MainLightPosition);
                // float NDotL = saturate(dot(lightPos, normal));
                //
                // float3 light = NDotL * _MainLightColor;
                // mainTex.rgb = mainTex.rgb * light;
                //
                //
                // float brightness = 1 - (dot(mainTex.rgb, half3(0.3f, 0.59f, 0.11f)));
                // // Calculate the index of the texture based on shading
                // float step = 1.0 / _CrossHatchingTexNum;
                //
                // float2 crosshatchUV = float2(brightness, IN.uv.y); // Corrected y-coordinate
                // half4 tonalMapValue = SAMPLE_TEXTURE2D(_CrossHatchingTexture, sampler_CrossHatchingTexture,
                //                                        crosshatchUV);
                // return half4(mainTex.rgb * tonalMapValue.rgb, 1);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}