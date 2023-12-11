Shader "Thesis/ToonShader"
{
    Properties
    {
        [Header(Base Toon Settings)]
        _BaseMap("Base Map", 2D) = "white" {}
        _BaseColor("Color", Color) = (0.5,0,0.5,1)

        [Header(Shadow Settings)]
        _ShadowStep("ShadowStep", Range(0,1)) =0.5
        _ShadowStepSmooth("ShadowStepSmooth", Range(0,1)) = 0.1

        [Header(Ambient Light)]
        [HDR]
        _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)

        [Header(Specular light)]
        [HDR]
        _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _SpecularStep ("SpecularStep", Range(0, 1)) = 0.5
        _SpecularStepSmooth ("SpecularStepSmooth", Range(0, 1)) = 0.01

        [Header(Rim Light)]
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
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


            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;

            //shadow
            float _ShadowStep;
            float _ShadowStepSmooth;

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
                OUT.positionCS = TransformObjectToHClip(IN.position.xyz); //transforms position to clip space
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
                float toonLight
                = smoothstep(_ShadowStep - _ShadowStepSmooth, _ShadowStep + _ShadowStepSmooth, NdotL);

                //float recieveShadow =(toonlight >= 0) ? mainLight.shadowAttenuation : 1;

                float4 light = toonLight * _MainLightColor; //* recieveShadow;
                //specular
                float specularValue = smoothstep((1 - _SpecularStep * 0.05) - _SpecularStepSmooth * 0.05,
                                              (1 - _SpecularStep * 0.05) + _SpecularStepSmooth * 0.05, NdotH);
                float4 specular = specularValue * _SpecularColor;
                //rim 
                float4 rimDot = 1 - NdotV; 
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity); 
                float4 rim = rimIntensity * _RimColor;

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
                //todo: ana understand this lmao 
                Varyings OUT;

                OUT.positionCS = TransformObjectToHClip(IN.position);
                // always have to do-> set the postiiton in the clip space
                //returns the normal in the worls coordinates
                float3 norm = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, IN.normal)); //transform normal into eye space
                // projection: from world -> view, which is our clipping space, so we get a flat outline
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