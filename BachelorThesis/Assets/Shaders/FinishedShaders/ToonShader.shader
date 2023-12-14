Shader "Thesis/ToonShader"
{
    Properties
    {
        [Header(Base Toon Settings)]
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Color", Color) = (0.5,0,0.5,1)

        [Header(Shadow Settings)]
        _ToonRamp("Toon Ramp", 2D) = "white" {}

        [Header(Ambient Light)]
        _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)

        [Header(Specular light)]
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _SpecularStep ("SpecularStep", Range(0, 1)) = 0.25
        _SpecularStepSmooth ("SpecularStepSmooth", Range(0, 1)) = 0.1

        [Header(Rim Light)]
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1

        [Header(Outline)]
        _OutlineWidth ("OutlineWidth", Range(0.0, 1)) = 0.15
        _OutlineColor ("OutlineColor", Color) = (0.0, 0.0, 0.0, 1)

    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        Pass
        {
            Name "ToonForward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 position : POSITION;
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
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_ToonRamp);
            SAMPLER(sampler_ToonRamp);


            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _ToonRamp_ST;
            half4 _BaseColor;
            
            //specular
            float4 _SpecularColor;
            float _SpecularStep;
            float _SpecularStepSmooth;

            //ambient
            float4 _AmbientColor;

            //rim
            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.position.xyz); 
                OUT.positionWS = TransformObjectToWorld(IN.position.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //variables
                float3 normal = normalize(IN.normalWS);
                float4 lightPos = normalize(_MainLightPosition);
                float3 viewDir = normalize(IN.viewDirWS);

                float NdotL = dot(normal, lightPos);
                float3 halfVector = normalize(lightPos + viewDir);
                float NdotH = dot(normal, halfVector);
                float NdotV = dot(viewDir, normal);


                //blinn phong lighting toonified
                float toonLight = 1 - SAMPLE_TEXTURE2D(_ToonRamp, sampler_ToonRamp, float2(NdotL, IN.uv.y));
                float4 light = toonLight * _MainLightColor;
                
                //specular
                float specularValue = smoothstep((1 - _SpecularStep * 0.05) - _SpecularStepSmooth * 0.05,
                                                 (1 - _SpecularStep * 0.05) + _SpecularStepSmooth * 0.05, NdotH);
                float4 specular = specularValue * _SpecularColor;
                
                //rim
                float rimLighting = saturate(1 - NdotV);
                float rimCutOff = pow(NdotL, _RimThreshold) * rimLighting;
                float rimToonified = smoothstep(_RimAmount - 0.03, _RimAmount + 0.03, rimCutOff);
                float4 rim = rimToonified * _RimColor;

                //calculation of final color
                float4 baseTexture = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

                float4 finalColor = baseTexture * (_AmbientColor + light + specular + rim);
                finalColor.a = 1;

                return finalColor;
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
                float2 uv : TEXCOORD0;
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
                float3 normalWorld = TransformObjectToWorld(IN.normal);
                float3 normalview = normalize(TransformWorldToView(normalWorld));
                float2 offset = TransformWViewToHClip(normalview.xyz);

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