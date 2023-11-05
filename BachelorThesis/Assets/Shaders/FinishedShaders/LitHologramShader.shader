Shader "Thesis/LitHologramShader"
{
    Properties
    {
        [Header(Base Lit Settings)]
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "white" {}
        _BaseColor("Base Color", color) = (1,1,1,1)
        _Specular("Specular",Range(0,1)) = 0
        _Smoothness("Smoothness", Range(0,1)) = 0
        _Metallic("Metallic", Range(0,1)) = 0
        _NormalIntensity("Normal Intensity", Range(0,1))=0

        [Header(Hologram Settings)]
        _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _FresnelIntensity("Fresnel Intensity", Range(0,10)) = 0
        _FresnelRamp("Fresnel Ramp", Range(0,10))= 0
        _ScrollSpeed("Scroll Speed", Range(0,10)) = 0.06

        _GlitchStrength("Glith Strength", Range(0,10)) = 0.5
        
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline"
        }
        LOD 100

        Pass
        {
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Shaders/Utilities.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normalOS: NORMAL;
                float4 texcoord1: TEXCOORD1; //unity puts stuff for lighting here
            };

            struct v2f
            {
                // float4 positionOS :SV_POSITION;
                float4 positionHCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
                //3 -> which texcoord is used //SH -> spherical harmonics
                float4 tangent : TEXCOORD4;
                float3 bitangent : TEXCOORD5;
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;


            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NormalMap_ST;
            float _NormalIntensity;
            float4 _BaseColor;
            float _Smoothness, _Metallic, _Specular;

            //hologram
            float4 _FresnelColor;
            float _FresnelIntensity;
            float _FresnelRamp;
            float _ScrollSpeed;
            float _GlitchStrength;

            CBUFFER_END

            v2f vert(appdata v)
            {
                //glitching y pos
                float noise = 0;
                Unity_SimpleNoise_float(v.positionOS.y, 500, noise);
                float3 positionVS = TransformWorldToView(TransformObjectToWorld(v.positionOS));
                noise *= _GlitchStrength;
                float3 newPosVS = positionVS + float3(noise, 0, 0);
                float3 newPosOS = TransformViewToObject(newPosVS);
                v.positionOS = float4(newPosOS, 0);


                v2f o;
                o.positionHCS = TransformObjectToHClip(v.positionOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS = normalize(_WorldSpaceCameraPos - o.positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.tangent.xyz = TransformObjectToWorldDir(v.tangent.xyz);
                o.tangent.w = v.tangent.w;
                o.bitangent = cross(o.normalWS, o.tangent.xyz) * o.tangent.w;


                OUTPUT_LIGHTMAP_UV(v.texcoord1, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalWS.xyz, o.vertexSH);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                //normals
                //normal map
                float3 normals = UnpackNormalScale(tex2D(_NormalMap, i.uv), _NormalIntensity);
                float3 finalNormals;
                if (length(normals) == 0.0) //if normals texture not set
                {
                    finalNormals = normalize(i.normalWS);
                }
                else
                {
                    finalNormals = normalize(normals.r * i.tangent + normals.g * i.bitangent + normals.b * i.normalWS);
                }

                //fresnel
                float fresnelAmount = 1 - max(0, dot(finalNormals, i.viewDirWS));
                fresnelAmount = pow(fresnelAmount, _FresnelRamp) * _FresnelIntensity;
                float4 fresnelColor = fresnelAmount * _FresnelColor;

                // scrolling texture
                float speedY = i.positionWS.y + (_ScrollSpeed * _Time);
                half4 mainTex = tex2D(_MainTex, float2(i.uv.x, speedY));
                half4 finalColor = mainTex + fresnelColor;


                InputData inputData = (InputData)0; //create a 0 and cast is
                inputData.positionWS = i.positionWS;
                inputData.normalWS = finalNormals;
                inputData.viewDirectionWS = i.viewDirWS;
                inputData.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, inputData.normalWS);;
                //baked global illumination; unity functions light mapping light probes

                SurfaceData surfacedata;
                surfacedata.albedo = _BaseColor;
                surfacedata.specular = _Specular;
                surfacedata.metallic = _Metallic;
                surfacedata.smoothness = _Smoothness;
                surfacedata.normalTS = 0;
                surfacedata.emission = finalColor;
                surfacedata.occlusion = 1;
                surfacedata.alpha = finalColor;
                surfacedata.clearCoatMask = 0;
                surfacedata.clearCoatSmoothness = 0;

                return UniversalFragmentPBR(inputData, surfacedata);
            }
            ENDHLSL

        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}