Shader "Test/kva"
{
    Properties
    {
        [Header(Common)]
        [MainTexture] _BaseMap("Base Texture", 2D) = "white" {}

        [Header(Foil)]
        _FoilTexture("Foil Texture", 2D) = "white" {}
        _FoilIntensity("Foil Intensity", Range(0,10)) = 1

        [Header(Plasma)]
        _PlasmaNoise("Plasma noise Size",Range(0,500)) = 10
        _PlasmaScale("Plasma Scale", float) = 1
        _PlasmaXScale("Plasma X Scale", float) = 1
        _PlasmaYScale("Plasma Y Scale", float) = 0.5
        _WaveColor1("Wave Color 1", Color) = (1,1,1,1)
        _WaveColor2("Wave Color 2", Color) = (1,1,1,1)
        _WaveColor3("Wave Color 3", Color) = (1,1,1,1)


    }


    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Blend Off
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Shaders/Utilities.hlsl"


            //texture samplers
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_FoilTexture);
            SAMPLER(sampler_FoilTexture);

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _FoilTexture_ST;
            float _PlasmaNoise,_PlasmaScale, _TimeSpeed, _PlasmaXScale, _PlasmaYScale;
            half4 _WaveColor1, _WaveColor2, _WaveColor3;
            float _FoilIntensity;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS: NORMAL;
                float3 viewDirWS : TEXCOORD2;
            };

            float3 Plasma(float2 uv, float t)
            {
                float time = t;
               //float time = _Time * _TimeSpeed;
                uv = uv * _PlasmaScale - _PlasmaScale / 2; //set the center of uv to _PlasmaScale/2

                float x = sin(uv.x + time);
                float y = sin(uv.y + time);
                float diagonal = sin(uv.x + uv.y + time);
                float elipsoid = sin(sqrt(
                    (_PlasmaXScale * uv.x) * (_PlasmaXScale * uv.x) + (_PlasmaYScale * uv.y) * (_PlasmaYScale * uv.
                        y)) + time);

                float finalEffect = x + y + diagonal + elipsoid;

                //offset the waves so that you can see all of the effects on different axis
                float3 wave1 = sin(finalEffect * M_PI) * _WaveColor1;
                float3 wave2 = cos(finalEffect * M_PI) * _WaveColor2;
                float3 wave3 = cos(finalEffect) * _WaveColor3;


                return wave1 + wave2 + wave3;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(OUT.positionWS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 mainTexture = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                half4 foilTexture = SAMPLE_TEXTURE2D(_FoilTexture, sampler_FoilTexture, IN.uv);

                float2 changedUV = IN.viewDirWS.xy + foilTexture.rg;
                float noise;
                Unity_SimpleNoise_float(changedUV,_PlasmaNoise,noise); 
                float3 plasma = Plasma(changedUV+ noise, IN.viewDirWS.z) * _FoilIntensity;
                
                return half4(mainTexture + mainTexture * plasma, 1);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}