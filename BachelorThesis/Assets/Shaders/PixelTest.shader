Shader "Thesis/PixelTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white"
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        HLSLINCLUDE
        #pragma vertex vert
        #pragma fragment frag

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionHCS : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        TEXTURE2D(_MainTex);
        float4 _MainTex_TexelSize;
        float4 _MainTex_ST;


        SamplerState sampler_point_clamp;

        uniform float2 _BlockCount;
        uniform float2 _BlockSize;
        uniform float2 _HalfBlockSize;
        uniform float _Width = 512;
        uniform float _Height = 512;


        Varyings vert(Attributes IN)
        {
            Varyings OUT;
            OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
            OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
            return OUT;
        }
        ENDHLSL

        Pass
        {
            Name "Pixelation"

            HLSLPROGRAM
            half4 frag(Varyings IN) : SV_TARGET
            {
                // float2 blockPos = floor(IN.uv * _BlockCount);
                // float2 blockCenter = blockPos * _BlockSize + _HalfBlockSize;
                //
                // float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, blockCenter);
                //return float4(IN.uv,1,1);

                //this works, but lets try to keep the original? UNCOMMENT THIS AFTER CIRCLE
                float2 position = IN.uv;
                position *= _BlockCount;
                position = ceil(position);
                position = position * _BlockSize + _HalfBlockSize;
                // position /= _BlockCount;
                // float2 cellPosition = position;
                //
                // position -= IN.uv;
                // position *= _BlockCount;
                // position = float2(1,1) - position;
                //circle
                // float2 circlePosition = float2(0.5, 0.5);
                // circlePosition -= position;
                // float distance = length(circlePosition);
                // float2 circlePosition = float2(0.5, 0.5);
                // circlePosition -= position;
                // float distance = length(circlePosition);
                //clip(0.5-distance); // diameter of the circle is 0.5; so here if a distance is greater then that it is clipped


                // //create pixel cells
                // float2 position = IN.uv;
                // position *= float2(_Width, _Height);
                // position = floor(position);
                // position /= float2(_Width, _Height);

                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_point_clamp, position);//* step(0.5 - distance, 0);
                return tex;
            }
            ENDHLSL
        }


    }
}