Shader "Thesis/Crosshatching"
{
    Properties
    {
        [Header(Outline)]
        _OutlineWidth ("OutlineWidth", Range(0.0, 5)) = 0.15
        _OutlineColor ("OutlineColor", Color) = (0.0, 0.0, 0.0, 1)

        [Header(Lighting)]
        _DiffuseIntensity("Diffuse Intensity", Range(0,10))=1
        _Ambient("Ambient", Range(0,1)) = 1
        _AmbientIntensity("Ambient Intensity", Range(0,1))=1

        _RimIntensity("Rim Intensity", Range(0,10))=1
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _Shininess("Shininess (Specular)", Range(0,0.1))=1

        [Header(Hatching)]
        _HatchColor("Hatch Color", Color) = (1,1,1,1)
        _Tilling ("Tilling", Vector) = (1, 1, 1, 1)

        _CrossHatchingTexture1("CrossHatching Texture 1", 2D) = "white" {}
        _CrossHatchingTexture2("CrossHatching Texture 2", 2D) = "white" {}
        _CrossHatchingTexture3("CrossHatching Texture 3", 2D) = "white" {}
        _CrossHatchingTexture4("CrossHatching Texture 4", 2D) = "white" {}
        _CrossHatchingTexture5("CrossHatching Texture 5", 2D) = "white" {}
        _CrossHatchingTexture6("CrossHatching Texture 6", 2D) = "white" {}
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
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //texture samplers
            TEXTURE2D(_CrossHatchingTexture1);
            SAMPLER(sampler_CrossHatchingTexture1);
            TEXTURE2D(_CrossHatchingTexture2);
            SAMPLER(sampler_CrossHatchingTexture2);
            TEXTURE2D(_CrossHatchingTexture3);
            SAMPLER(sampler_CrossHatchingTexture3);
            TEXTURE2D(_CrossHatchingTexture4);
            SAMPLER(sampler_CrossHatchingTexture4);
            TEXTURE2D(_CrossHatchingTexture5);
            SAMPLER(sampler_CrossHatchingTexture5);
            TEXTURE2D(_CrossHatchingTexture6);
            SAMPLER(sampler_CrossHatchingTexture6);

            CBUFFER_START(UnityPerMaterial)
            half4 _HatchColor, _RimColor;
            float4 _CrossHatchingTexture1_ST, _CrossHatchingTexture2_ST, _CrossHatchingTexture3_ST;
            float4 _CrossHatchingTexture4_ST, _CrossHatchingTexture5_ST, _CrossHatchingTexture6_ST;
            float4 _Tilling;
            float _DiffuseIntensity, _AmbientIntensity, _RimIntensity, _Shininess;
            float _Ambient;

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
                OUT.uv = IN.uv * _Tilling;
                return OUT;
            }


            half4 frag(Varyings IN) : SV_Target
            {
                //variables
                half4 lightPosition = normalize(_MainLightPosition);
                float3 normal = normalize(IN.normalWS);
                float3 viewDir = normalize(IN.viewDirWS);
                float3 halfVec = normalize(viewDir + normal);
                float NumOfTextures = 6;
                
                //lighiting calculations
                float diffuse = dot(normal, lightPosition);

                float rim = 1 - saturate(dot(viewDir, normal));
                rim = pow(rim, _RimIntensity);
                float4 rimColor = _RimColor * rim;

                float ambient = _Ambient * _AmbientIntensity;

                float specular = saturate(dot(normal, halfVec));
                specular = dot(specular, _Shininess);

                //final light calculation
                float brightness = diffuse * _DiffuseIntensity + rim + ambient + specular;
                brightness = 1 - brightness;
                float step = 1.0 / NumOfTextures;
                float normalizedBrightness = brightness / step;
                //hatching processing
                
                half4 hatchValue;
                if (brightness <= step)
                {
                    half4 texture1 = SAMPLE_TEXTURE2D(_CrossHatchingTexture1, sampler_CrossHatchingTexture1, IN.uv);
                    half4 texture2 = SAMPLE_TEXTURE2D(_CrossHatchingTexture2, sampler_CrossHatchingTexture2, IN.uv);
                    hatchValue = lerp(texture1, texture2, normalizedBrightness);
                }
                else if (brightness > step && brightness <= 2. * step)
                {
                    half4 texture2 = SAMPLE_TEXTURE2D(_CrossHatchingTexture2, sampler_CrossHatchingTexture2, IN.uv);
                    half4 texture3 = SAMPLE_TEXTURE2D(_CrossHatchingTexture3, sampler_CrossHatchingTexture3, IN.uv);
                    hatchValue = lerp(texture2, texture3, normalizedBrightness - 1);
                }
                else if (brightness > step * 2 && brightness <= 3. * step)
                {
                    half4 texture3 = SAMPLE_TEXTURE2D(_CrossHatchingTexture3, sampler_CrossHatchingTexture3, IN.uv);
                    half4 texture4 = SAMPLE_TEXTURE2D(_CrossHatchingTexture4, sampler_CrossHatchingTexture4, IN.uv);
                    hatchValue = lerp(texture3, texture4, normalizedBrightness - 2);
                }
                else if (brightness > step * 3 && brightness <= 4. * step)
                {
                    half4 texture4 = SAMPLE_TEXTURE2D(_CrossHatchingTexture4, sampler_CrossHatchingTexture4, IN.uv);
                    half4 texture5 = SAMPLE_TEXTURE2D(_CrossHatchingTexture5, sampler_CrossHatchingTexture5, IN.uv);
                    hatchValue = lerp(texture4, texture5, normalizedBrightness - 3);
                }
                else if (brightness > step * 4 && brightness <= 5. * step)
                {
                    half4 texture5 = SAMPLE_TEXTURE2D(_CrossHatchingTexture5, sampler_CrossHatchingTexture5, IN.uv);
                    half4 texture6 = SAMPLE_TEXTURE2D(_CrossHatchingTexture6, sampler_CrossHatchingTexture6, IN.uv);
                    hatchValue = lerp(texture5, texture6, normalizedBrightness - 4);
                }
                else if (brightness > 5 * step)
                {
                    half4 texture6 = SAMPLE_TEXTURE2D(_CrossHatchingTexture6, sampler_CrossHatchingTexture6, IN.uv);
                    hatchValue = texture6;
                }
               // return lerp( lerp( _HatchColor, float4(1,1,1,1), hatchValue.r ), hatchValue, .5 );

                return half4(rimColor.rgb + (hatchValue.rgba + _HatchColor.rgba* brightness), 1);
            }
            ENDHLSL
        }
        Pass
        {
            Name "Outline"
            Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 position : POSITION;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)

            float _OutlineWidth;
            float4 _OutlineColor;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.position);
                float3 norm = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, IN.normal)); 
                float2 offset = TransformWViewToHClip(norm.xyz);
                OUT.positionCS.xy += offset * OUT.positionCS.z * _OutlineWidth;
                OUT.color = _OutlineColor;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                return IN.color;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}