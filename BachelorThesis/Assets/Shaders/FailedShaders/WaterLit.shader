Shader "Thesis/WaterLit"
{
    Properties
    {
        _NormalMap("Normal Map", 2D) = "white" {}
        _SecondNormalMap("Second Normal Map", 2D) = "white" {}
        _NormalIntensity("Normal Intensity", Range(0,1)) = 1
        _NormalMapsScale("Normal Maps Scale",Range(0,4)) =100
        _Smoothness("Smoothness", Range(0,1)) = 0

        _WaterDepth("Water Depth", Range(0,10))=1
        _WaterIntersectPower("Water Intersect Power", Range(0,10))=1

        _WaterSurfaceColor("Water Surface Color", Color) = (1,1,1,1)
        _WaterDepthColor("Water Depth Color", Color) = (1,1,1,1)

        _WaterTimeSpeed("Water Time Speed", Range(0,100)) = 30

        [Header(Foam)]
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FoamAmount("Foam Amount", Range(0,10))= 1
        _FoamCutOff("Foam Cut Off", Range(0,10))= 1
        _FoamTime("Foam Time", Range(0,100))= 10
        _FoamScale("Foam Scale", Range(0,500))= 10


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
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
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
                float4 positionHCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
                //3 -> which texcoord is used //SH -> spherical harmonics
                float4 tangent : TEXCOORD4;
                float3 bitangent : TEXCOORD5;
                float4 screenPos : TEXCOORD6;
            };

            sampler2D _NormalMap;
            sampler2D _SecondNormalMap;


            CBUFFER_START(UnityPerMaterial)
            float _Smoothness;
            float4 _NormalMap_ST;
            float4 _SecondNormalMap_ST;
            float _NormalMapsScale;
            float _NormalIntensity;
            float _WaterDepth, _WaterIntersectPower;
            half4 _WaterSurfaceColor, _WaterDepthColor;
            float _WaterTimeSpeed;
            float _FoamAmount, _FoamCutOff, _FoamTime, _FoamScale;
            half4 _FoamColor;

            CBUFFER_END

            v2f vert(appdata v)
            {
                v2f o;
                o.positionHCS = TransformObjectToHClip(v.positionOS);
                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS = normalize(_WorldSpaceCameraPos - o.positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _NormalMap);
                o.screenPos = ComputeScreenPos(o.positionHCS);
                o.tangent.xyz = TransformObjectToWorldDir(v.tangent.xyz);
                o.tangent.w = v.tangent.w;
                o.bitangent = cross(o.normalWS, o.tangent.xyz) * o.tangent.w;


                OUTPUT_LIGHTMAP_UV(v.texcoord1, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalWS.xyz, o.vertexSH);
                return o;
            }

            float DepthIntersection(float4 screenPos, float depth, float IntersectPower)
            {
                float2 screenUVs = screenPos.xy / screenPos.w;
                float rawDepth = SampleSceneDepth(screenUVs);
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float intersectAmount = sceneEyeDepth - screenPos.w;
                intersectAmount = saturate(intersectAmount / depth);
                intersectAmount = pow(intersectAmount, intersectAmount);
                return intersectAmount;
            }

            float2 MovementUV(float2 uv, float time, float2 tiling)
            {
                float2 newUv = Unity_TilingAndOffset_float(uv, tiling, time / 50);
                return newUv;
            }

            half4 frag(v2f i) : SV_Target
            {
                //water depth and intersection
                float waterIntersection = DepthIntersection(i.screenPos, _WaterDepth, _WaterIntersectPower);

                //water color
                float4 waterDepthColor = lerp(_WaterSurfaceColor, _WaterDepthColor, waterIntersection);

                // //water foam
                // float foamIntersection = DepthIntersection(i.screenPos, _FoamAmount, _WaterIntersectPower);
                // foamIntersection = foamIntersection * _FoamCutOff;
                // float2 foamUv = MovementUV(i.uv, _Time * _FoamTime, (1,1)* _FoamScale);
                // float foamNoise;
                // Unity_SimpleNoise_float(foamUv,1, foamNoise);
                // float foamStep =step(foamIntersection, foamNoise);
                // foamStep = foamStep * _FoamColor.a; //transparency of the foam
                //
                // float3 finalColor = lerp(waterDepthColor,_FoamColor,foamStep);
                

                //refraction (normal maps)
                float uvOne = MovementUV(i.uv, _Time * _WaterTimeSpeed / 50, (1, 1) * _NormalMapsScale);
                float3 normalMap = UnpackNormalScale(tex2D(_NormalMap, uvOne), _NormalIntensity);
                normalMap = normalMap.r * i.tangent + normalMap.g * i.bitangent + normalMap.b * i.normalWS;

                float uvTwo = MovementUV(i.uv, _Time * _WaterTimeSpeed / -25, (1, 1) * _NormalMapsScale);
                float3 secondNormalMap = UnpackNormalScale(tex2D(_SecondNormalMap, uvTwo), _NormalIntensity);
                secondNormalMap = secondNormalMap.r * i.tangent + secondNormalMap.g * i.bitangent + secondNormalMap.b *
                    i.normalWS;

                float3 normalsCombined = normalMap + secondNormalMap;

                //
                //
                // float3 finalNormals = normals.r * i.tangent + normals.g * i.bitangent + normals.b * i.normalWS;
                // inputData.normalWS = normalize(finalNormals); //normalize(i.normalWS);
                //
                InputData inputData = (InputData)0; //create a 0 and cast is
                inputData.positionWS = i.positionWS;
                inputData.normalWS = normalsCombined;
                inputData.viewDirectionWS = i.viewDirWS;
                inputData.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH, inputData.normalWS);;
                //baked global illumination; unity functions light mapping light probes
                SurfaceData surfacedata;
                surfacedata.albedo = waterDepthColor;
                surfacedata.specular = 0;
                surfacedata.metallic = 0;
                surfacedata.smoothness = _Smoothness;
                surfacedata.normalTS = 0;
                surfacedata.emission = 0;
                surfacedata.occlusion = 0;
                surfacedata.alpha = waterDepthColor.w;
                surfacedata.clearCoatMask = 0;
                surfacedata.clearCoatSmoothness = 0;

                return UniversalFragmentPBR(inputData, surfacedata);
            }
            ENDHLSL

        }
    }
}