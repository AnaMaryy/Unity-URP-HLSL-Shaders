// This shader draws a texture on the mesh.
Shader "Thesis/ToonTry"
{
    // The _BaseMap variable is visible in the Material's Inspector, as a field
    // called Base Map.
    Properties
    {
        [Header(Base Settings)]
        _BaseTexture("Base Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (0.5,0,0.5,1)

        [Header(Diffuse Lighting)]
        _RampNumber("Number of lighting ramps", int) = 2
        _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)

        [Header(Specular Lighting)]
        [Toggle(ENABLE_SPECULAR)] _SpecEnabled ("Enabled", Float) = 0
        [HDR]_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1) //color of reflection
        _Shininess("_Shininess", Float) = 32 //control the size of reflection
        //todo specular texture
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
            "PassFlags" = "OnlyDirectional" //restrict lighting data only to the directional light
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature ENABLE_SPECULAR

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

                float3 worldNormal : NORMAL;
                float3 viewDir : TEXCOORD1;
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


            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.position = TransformObjectToHClip(IN.position.xyz); //transforms position to clip space
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseTexture); // TRANSFORM_TEX macro performs the tiling and offset
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normal);
                OUT.viewDir = GetWorldSpaceNormalizeViewDir(IN.position);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // ----------- DIFFUSE LIGHT -------------------------------
                //blinn phong lighting calculation
                 float NdotL = dot(_MainLightPosition, IN.worldNormal);
                 //seprate light value into ramps;
                 float rampValue = 1.0 / (_RampNumber - 1);
                 float lightIntensity = (ceil(NdotL / rampValue) * rampValue);
                
                
                // // ----- SPECULAR LIGHT -----------------------------------
                half3 halfVector = normalize(reflect(-_MainLightPosition, IN.worldNormal));
               
                half RdotV =  dot(halfVector,IN.viewDir);
                // Make large values really large and small values really small.
                half specPow = pow(RdotV , _Shininess * _Shininess);
                specPow = smoothstep(0.005, 0.01, specPow);
                float4 specular = _SpecularColor *  specPow;
                

                //-------------- FINAL COLOR -------------------------------
                float4 light = lightIntensity * _MainLightColor + _AmbientColor + specular;
                // get the color of the directional light

                float4 color = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv) * _BaseColor * light;
                return color;
            }
            ENDHLSL
        }
    }
}