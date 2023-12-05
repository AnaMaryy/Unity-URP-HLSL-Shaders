Shader "Thesis/Pixel"
{
    Properties
    {
        [Header(Common)]
        [MainTexture] _BaseMap("Base Texture", 2D) = "white" {}
        [MainColor] _Color("Base Color", Color) = (1, 1, 1, 1)

        _Width("Width", Float) = 8
        _Height("Height", Float)= 8

    }


    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Blend Off
            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float _Width;
            float _Height;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            float4 _BaseMap_ST;
            SAMPLER(sampler_BaseMap);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                return OUT;
            }

            float4 PixelShaderFunction(float2 coords: TEXCOORD0) : COLOR0
            {
                float dx = coords.x - 0.5f;
                float dy = coords.y - 0.5f;
                if (dx * dx + dy * dy <= 0.25f)
                    return float4(1.0f, 0.0f, 0.0f, 1.0f);
                return float4(0.0f, 0.0f, 0.0f, 0.0f);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                //create pixel cells
                float2 position = IN.uv;
                position *= float2(_Width, _Height);
                position = floor(position);
                position /= float2(_Width, _Height);

                position -= IN.uv;
                position *= float2(_Width, _Height);
                position = float2(1, 1) - position;;


                //circle
                float2 circlePosition = float2(0.5, 0.5);
                position-= circlePosition;
                float len = length(position);
                //
                // IN.uv -= float2(0.5f, 0.5f);
                // float len = length(IN.uv);
                // clip(0.5 - len);


                // half4 output = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _Color;
                half4 output = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, position) * _Color;

                return output ;//* step(len, 0.5); //return 0 or 1
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}