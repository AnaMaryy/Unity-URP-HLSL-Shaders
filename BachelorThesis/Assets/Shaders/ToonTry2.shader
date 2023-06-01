// This shader draws a texture on the mesh.
Shader "Thesis/ToonShaderTry2"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
    Properties
    {
        [Header(Base Toon Settings)]
        _BaseTexture("Base Texture", 2D) = "white" {}
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
        _Glossiness("Glossiness", Float) = 32



    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
            //"PassFlags" = "OnlyDirectional" //restrict lighting data only to the directional light
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
                //position of the vertex after being transformed into projection space || system value
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 normalWS: NORMAL;
                float3 viewDirWS : TEXCOORD2;
            };

            TEXTURE2D(_BaseTexture); // declare _BaseTexture as a Texture2D object
            SAMPLER(sampler_BaseTexture); // declare sampler for _BaseTexture


            // make variabled SRP Batcher compatible -> SRP Batcher is a draw call optimization
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseTexture_ST; //ST -> necessary for tilling to work
            half4 _BaseColor;
            //shadow
            float _ShadowStep;
            float _ShadowStepSmooth;

            //specular
            float _Glossiness;
            float4 _SpecularColor;

            //ambient
            float4 _AmbientColor;


            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.position.xyz); //transforms position to clip space
                OUT.positionWS = TransformObjectToWorld(IN.position.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                //OUT.viewDirWS = GetCameraPositionWS() - OUT.positionWS;

                // OUT.normalWS = float4( OUT.normalWS, OUT.viewDirWS.x);
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //variables
                float3 normal = normalize(IN.normalWS);
                float lightPos = normalize(_MainLightPosition);
                float3 viewDir = normalize(IN.viewDirWS);

                float NdotL = dot(normal, lightPos);
                float3 halfVector = normalize(lightPos + viewDir);
                float NdotH = dot(normal, halfVector);


                //blinn phong lighting toonified
                float toonlight = smoothstep(_ShadowStep - _ShadowStepSmooth, _ShadowStep + _ShadowStepSmooth, NdotL);
                float4 light = toonlight * _MainLightColor;
                //specular
                float specularIntensity = pow(NdotH * light, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float4 specular = specularIntensitySmooth * _SpecularColor;


                float4 base_texture = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv) * _BaseColor;

                float4 final_color = base_texture * (_AmbientColor + light + specular);
                final_color.a = 1;

                return final_color;
            }
            ENDHLSL
        }
    }
}