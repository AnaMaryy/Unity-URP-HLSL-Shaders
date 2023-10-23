Shader "Thesis/HolographicFirst"
{
    Properties
    {
        [Header(Common)]
        [MainTexture] _BaseMap("Hologram Texture", 2D) = "white" {}
        [MainColor] _Color("Base Color", Color) = (1, 1, 1, 1)
        _FresnelPower("Fresnel Power", float) = 4
        _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _ScrollSpeed("Scroll Speed", float) = 0.06

    }


    SubShader
    {
        Tags
        {
            "Queue" = "AlphaTest"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"

        }
        Pass
        {
//            Cull Off
//            Tags
//			{
//				"LightMode" = "UniversalForward"
//			}

       Blend SrcAlpha OneMinusSrcAlpha //made it work in the first place



            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ UNITY_UI_ALPHACLIP


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float _FresnelPower;
            float4 _FresnelColor;
            float _ScrollSpeed;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal: NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD2;
                float3 normalWS: NORMAL;
                float3 positionWS : TEXCOORD1;

                float3 viewDirWS : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            float4 _BaseMap_ST;
            SAMPLER(sampler_BaseMap);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //variables
                float3 normal = normalize(IN.normalWS);
                float4 lightPos = normalize(_MainLightPosition);
                float3 viewDir = normalize(IN.viewDirWS);
                float3 halfwayDir = normalize(lightPos + viewDir);

                //general calculations
                float NdotV = dot(normal, viewDir);

                //fresnel effect
                float fresnel_effect = pow(1.0 - saturate(NdotV), _FresnelPower);
                _FresnelColor *= fresnel_effect;

                //scroll texture effect
                float speedY = IN.positionWS.y + (_ScrollSpeed * _Time);

                half4 output = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, float2(IN.uv.x, speedY)) * _Color;

                float4 final_effect = output + _FresnelColor;
                return final_effect;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}