ef// This shader draws a texture on the mesh.
Shader "Thesis/ToonInk"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
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



        [Header(Outline)]
        _OutlineWidth ("OutlineWidth", Range(0.0, 1)) = 0.15
        _OutlineColor ("OutlineColor", Color) = (0.0, 0.0, 0.0, 1)


    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
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

            // Universal Render Pipeline keywords
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _SHADOWS_SOFT


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
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS: NORMAL;
                float3 viewDirWS : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap); // declare _BaseTexture as a Texture2D object
            SAMPLER(sampler_BaseMap); // declare sampler for _BaseTexture


            // make variabled SRP Batcher compatible -> SRP Batcher is a draw call optimization
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST; //ST -> necessary for tilling to work
            half4 _BaseColor;
            //shadow
            float _ShadowStep;
            float _ShadowStepSmooth;


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
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //variables
                float3 normal = normalize(IN.normalWS);
                float lightPos = normalize(_MainLightPosition);
                float3 viewDir = normalize(IN.viewDirWS);
                float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);


                //general calculations
                float NdotL = dot(normal, lightPos);
                float3 halfVector = normalize(lightPos + viewDir);
                float NdotH = dot(normal, halfVector);
                float NdotV = dot(viewDir, normal);


                //blinn phong lighting toonified

                float toonlight = smoothstep(_ShadowStep - _ShadowStepSmooth, _ShadowStep + _ShadowStepSmooth, NdotL);
                //float recieveShadow =(toonlight >= 0) ? mainLight.shadowAttenuation : 1;
                


                //float4 base_texture = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv) * _BaseColor; 
                _BaseColor.a = 0;
                float4 base_texture = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                base_texture.a = toonlight <= 0 ? 0:1;

                float4 final_color = base_texture ;

                return final_color;
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