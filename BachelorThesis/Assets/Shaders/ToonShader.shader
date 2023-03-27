Shader "Thesis/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.5,0.2,0.5,1)
        [HDR]_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1) // for ambient light; HDR -> high dynamic range: 
        [HDR] _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _Glossiness("Glossiness", Float) = 32

        [HDR]
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1


    }
    SubShader
    {
        Tags
        {
            "LightMode" = "ForwardBase" // we use our own lighting
            "PassFlags" = "OnlyDirectional" //use only the direction light
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           // #pragma multi_compile_fwdbase //unity compiles all variants necessary for forward base renderig


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            //#include "AutoLight.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldNormal : NORMAL;
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD1;
               // SHADOW_COORDS(2) //recieve shadows

            };

            sampler2D _MainTex;
            float4 _Color;
            float4 _MainTex_ST; //tilling and offset information
            float4 _AmbientColor;
            float4 _SpecularColor;
            float _Glossiness;
            float4 _RimColor;
            float _RimAmount;
            float _RimTreshold;

            v2f vert(appdata v)
            {
                v2f o;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //TRANSFER_SHADOW(o) // recieve shadows

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //blinn-Phong light calculation
                float3 normal = normalize(i.worldNormal);
                float NdotL = dot(normal, _WorldSpaceLightPos0);

                //float shadow = SHADOW_ATTENUATION(i); //sample shadow

                //divide the light into light and dark : todo : add more discrete bands of shading :D
                //float lightValue = NdotL < 0 ? 0 :1;
                float lightValue;
                if (NdotL < 0)
                {
                    lightValue = 0;
                }
                else if (NdotL <= 0.5)
                {
                    lightValue = 0.5;
                }
                else
                {
                    lightValue = 1;
                }
                //add shadow
                //lightValue *= shadow;
                //lightValue = smoothstep(0,0.1, NdotL);
                //final light -> takes the color of the direction light 
                float4 light = lightValue * _LightColor0;

                //specular and glossiness : todo watch blinn phong shading to understand exactly why this shit happens..
                float3 halfVector = normalize(normalize(i.viewDir) + _WorldSpaceLightPos0);
                // half vector is the sum of viewdir and light dir
                float HdotN = dot(halfVector, normal);
                //mutluply lightvalue and HdotN to add specular only where the surface is lit ; _glossines multiplied, so smaller walues have greater effect
                float specularValue = pow(HdotN * lightValue, _Glossiness * _Glossiness);

                //smooth the specular value to toonify
                float specularValueSmooth = smoothstep(0.005, 0.01, specularValue);
                float4 specular = specularValueSmooth * _SpecularColor;

                //rim lighting
                float4 rimDot = 1 - dot(normalize(i.viewDir), normal);
                //toonify with smoothstep -> adds an outline only on the edge
                float rimValue = rimDot *pow(NdotL, _RimTreshold);
                rimValue = smoothstep(_RimAmount -0.01, _RimAmount +0.01, rimValue);
                float4 rim = rimValue *_RimColor;

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                //add texture color, ambient color and light, and specular value
                return col * _Color * (_AmbientColor + light + specular + rim); //todo why multiply color and why add
            }
            ENDCG
        }
        //UsePass "Legacy Shaders/VertexLit/SHADOWCASTER" //add shadow pass that is defined by another shader, the unity defualt for shadows

    }
}