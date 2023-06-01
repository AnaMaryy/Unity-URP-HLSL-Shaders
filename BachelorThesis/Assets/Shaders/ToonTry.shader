// This shader draws a texture on the mesh.
Shader "Thesis/ToonShader"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
    Properties
    {
        [Header(Base Settings)]
        _BaseTexture("Base Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (0.5,0,0.5,1)

        [Space]
        [Header(Diffuse Lighting)]
        _RampNumber("Number of lighting ramps", int) = 2 //todo : rename this?
        _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)

        [Space]
        [Header(Specular Lighting)]
        [Toggle(ENABLE_SPECULAR)] _SpecEnabled ("Enabled", Float) = 0
        [HDR]_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1) //color of reflection
        _Shininess("_Shininess", Float) = 32 //control the size of reflection

        [Space]
        [Header(Rim Lighting)]
        _RimIntensity("Rim Intensity", Range(0, 1)) = 0.716
        //        _RimPower("Rim power", Range(0,5)) =1
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
        _RimStep ("RimStep", Range(0, 1)) = 0.65
        _RimStepSmooth ("RimStepSmooth",Range(0,1)) = 0.4
        _RimColor ("RimColor", Color) = (1,1,1,1)


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
            Name "Toon"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature ENABLE_SPECULAR

            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include  "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
          


            struct Attributes
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : NORMAL;
            };

            struct Varyings
            {
                //position of the vertex after being transformed into projection space || system value
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;

                float3 worldNormal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3; // shadow receive 
            };

            TEXTURE2D(_BaseTexture); // declare _BaseTexture as a Texture2D object
            SAMPLER(sampler_BaseTexture); // declare sampler for _BaseTexture

            // make variabled SRP Batcher compatible -> SRP Batcher is a draw call optimization
            CBUFFER_START(UnityPerMaterial)

            float4 _BaseTexture_ST; //ST -> necessary for tilling to work
            half4 _BaseColor;
            int _RampNumber;
            float4 _AmbientColor;
            //specular
            float4 _SpecularColor;
            float _Shininess;
            //rim liging
            // float4 _RimColor;
            float _RimIntensity;
            // float _RimPower;
            float _RimThreshold;

            float _RimStepSmooth;
            float _RimStep;
            float4 _RimColor;


            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.position.xyz);

                OUT.position = TransformObjectToHClip(IN.position.xyz); //transforms position to clip space
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseTexture); // TRANSFORM_TEX macro performs the tiling and offset
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normal);
                // OUT.viewDir = GetWorldSpaceNormalizeViewDir(IN.position.xyz);
                OUT.viewDir = GetCameraPositionWS() - vertexInput.positionWS;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // ----------- DIFFUSE LIGHT -------------------------------
                //blinn phong lighting calculation
                float NdotL = dot(normalize(_MainLightPosition), IN.worldNormal);
                //seprate light value into ramps;
                float rampValue = 1.0 / (_RampNumber - 1);
                float lightIntensity = (ceil(NdotL / rampValue) * rampValue);


                // // ----- SPECULAR LIGHT -----------------------------------
                half3 halfVector = normalize(reflect(-_MainLightPosition, IN.worldNormal));

                half RdotV = dot(halfVector, IN.viewDir);
                // Make large values really large and small values really small.
                half specPow = pow(RdotV, _Shininess * _Shininess);
                specPow = smoothstep(0.005, 0.01, specPow);
                float4 specular = _SpecularColor * specPow;

                //--------- RIM LIGHTING -----------------------
                // float NV = dot(IN.worldNormal, IN.viewDir);
                // float rimDot = smoothstep((1 - _RimStep) - _RimStepSmooth * 0.5, (1 - _RimStep) + _RimStepSmooth * 0.5,1 - NV);
                // float rimIntensity = rimDot * pow(NdotL, 1 -_RimThreshold); //create a cutoff, how does it work? no idea
                // float4 rim = rimIntensity * _RimColor;
                //
                // // ___________ AMBIENT LIGHTING ----------------
                // float3 ambient = 


                // float4 myTexture = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv);
                // float3 finalColor = myTexture * _BaseColor + rim * _RimColor;
                // return float4(finalColor, 1.0);

                float rimDot = 1 - dot(IN.viewDir, IN.worldNormal).r;
                float rimIntensity = smoothstep(_RimIntensity - 0.01, _RimIntensity + 0.01, rimDot);
                float4 rim = rimIntensity * _RimColor;

                // float NdotV = 1 - dot(IN.worldNormal, IN.viewDir);
                // NdotV = pow(NdotV, _RimPower);
                // NdotV *= _RimIntensity;
                // float4 rim = float4(NdotV.rrr, 1) * _RimColor;


                // float rimIntensity = rimDot  * pow(NdotL, _RimThreshold);
                //------------------ SHADOW --------------
                //IN.shadowCoord = TransformWorldToShadowCoord(IN.position);
                //float shadow = MainLightRealtimeShadow(IN.shadowCoord);


                //-------------- FINAL COLOR -------------------------------
                float4 light = lightIntensity * _MainLightColor + specular + rim;

                float4 color = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv) * _BaseColor * light +
                    _AmbientColor;
                return color;
            }
            ENDHLSL
        }
    }
}