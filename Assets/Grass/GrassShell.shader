Shader "Unlit/GrassShell"
{
    Properties
    {
        _NoiseScale("Noise scale", Float) = 10
        [Space(20)]
        _ColorBottom("Color bottom", Color) = (0,1,0,1)
        _ColorTop("Color top", Color) = (0,1,0,1)
        _TipColor("Tip color", Color) = (1,1,1,1)
        _SelfShadowCoef("Self shadow coef", Float) = 2
        _TopBottomColorsBlendCoef("top-bottom colors blend coef", Float) = 1
        _TipColorHeight("Tip color height", Range(0,1)) = 0.7
        [Space(20)]
        _DisplaceValue("Displace value", Float) = 1
        _SinDisplaceFreq("Sin displace frequency", Float) = 1
        _SinDisplaceSpeed("sin displace speed", Float) = 0
        _DisplaceDir("Displace direction", Range(0, 6.28)) = 0
        [Space(20)]
        _HeightMap("Grass height noise map", 2D) = "white" {}
        _HeightMultipler("Height multipler", Float) = 1.3
        _HeightMapScale("Height map scale", Float) = 1
        _LowerHeightValue("Lower height value", Range(0,1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="AlphaTest" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            TEXTURE2D(_HeightMap);
            SAMPLER(sampler_HeightMap);
            
            half _NoiseScale, _SelfShadowCoef, _TopBottomColorsBlendCoef, _TipColorHeight;
            half4 _ColorBottom, _ColorTop, _TipColor;
            half _DisplaceValue, _SinDisplaceFreq, _SinDisplaceSpeed, _DisplaceDir;
            half _HeightMultipler, _HeightMapScale, _LowerHeightValue;
            

            float _normCurHeights[1023];
            float _curHeights[1023];
            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(half, startOffset)
                UNITY_DEFINE_INSTANCED_PROP(half, grassThickness)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata v, uint instanceID: SV_InstanceID)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                v.vertex.xyz += v.normal * _curHeights[instanceID];
                half offset = UNITY_ACCESS_INSTANCED_PROP(Props, startOffset);
                v.vertex.xyz += v.normal * offset;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            float rand(float2 Seed, float Min, float Max)
            {
                float randomno =  frac(sin(dot(Seed, float2(12.9898, 78.233)))*43758.5453);
                return lerp(Min, Max, randomno);
            }

            half RemapVal(half value, half from1, half to1, half from2, half to2)
            {
                return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
            }

            half4 GetTippedColor(half4 defaultColor, half curHeight)
            {
                half r = 1-_TipColorHeight;
                
                half4 lerpedColor = lerp(defaultColor, _TipColor,
                        saturate(RemapVal(curHeight, _TipColorHeight-r, _TipColorHeight, 0, 1)));
                
                return lerpedColor;
            }

            half4 frag (v2f i, uint instanceID: SV_InstanceID) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half2 uv = i.uv * _NoiseScale;
                
                half instNormCurHeight = _normCurHeights[instanceID];
                half displaceValY = sin(i.uv.y*_SinDisplaceFreq + _Time.y*_SinDisplaceSpeed)*0.5+0.5;
                half displaceValX = sin(i.uv.x*_SinDisplaceFreq + _Time.y*_SinDisplaceSpeed)*0.5+0.5;
                half2 displace = half2(sin(_DisplaceDir) * displaceValX, cos(_DisplaceDir) * displaceValY);
                
                displace *= instNormCurHeight*instNormCurHeight;
                uv += displace*_DisplaceValue;
                
                half2 fracUvPart = frac(uv);
                fracUvPart = fracUvPart * 2 - 1;

                half2 seed = floor(uv);
                
                half dist = sqrt(fracUvPart.x*fracUvPart.x + fracUvPart.y*fracUvPart.y);
                half randNum = rand(seed,0,1);
                
                half2 heightUV = i.uv*_HeightMapScale;
                half texHeight = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, heightUV).r;
                half resHeight = randNum*texHeight*_HeightMultipler;
                resHeight = resHeight<_LowerHeightValue ? resHeight + _LowerHeightValue : resHeight;
                
                half colorsLerpCoef = pow(abs(instNormCurHeight), _TopBottomColorsBlendCoef);
                half4 col = lerp(_ColorBottom, _ColorTop, colorsLerpCoef);
                col = GetTippedColor(col, instNormCurHeight);
                half instGrassThickness = UNITY_ACCESS_INSTANCED_PROP(Props, grassThickness);

                clip(instGrassThickness*(resHeight-instNormCurHeight) - dist);
          
                half heightSelfShadow = pow(abs(instNormCurHeight),_SelfShadowCoef);
                col *=heightSelfShadow;
                
                return col;
            }
            ENDHLSL
        }
    }
}