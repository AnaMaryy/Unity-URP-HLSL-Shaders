Shader "Thesis/BaseLit"
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
        _NormalIntensity("Normal Intensity", Range(0,1))=1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalRenderPipeline"
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


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
            CBUFFER_END

            v2f vert(appdata v)
            {
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
                // sample the texture
                half4 mainTex = tex2D(_MainTex, i.uv);

                InputData inputData = (InputData)0; //create a 0 and cast is
                //normal map
                inputData.positionWS = i.positionWS;
                float3 normals = UnpackNormalScale(tex2D(_NormalMap, i.uv), _NormalIntensity);

                if (length(normals) == 0.0) //if normals texture not set
                {
                    inputData.normalWS = normalize(i.normalWS);
                }
                else
                {
                    float3 finalNormals = normals.r * i.tangent + normals.g * i.bitangent + normals.b * i.normalWS;
                    inputData.normalWS = normalize(finalNormals); //normalize(i.normalWS);
                }
                inputData.viewDirectionWS = i.viewDirWS;
                inputData.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, inputData.normalWS);;
                //baked global illumination; unity functions light mapping light probes

                SurfaceData surfacedata;
                surfacedata.albedo = mainTex * _BaseColor;
                surfacedata.specular = _Specular;
                surfacedata.metallic = _Metallic;
                surfacedata.smoothness = _Smoothness;
                surfacedata.normalTS = 0;
                surfacedata.emission = 0;
                surfacedata.occlusion = 1;
                surfacedata.alpha = 0;
                surfacedata.clearCoatMask = 0;
                surfacedata.clearCoatSmoothness = 0;

                return UniversalFragmentPBR(inputData, surfacedata);
            }
            ENDHLSL

        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}