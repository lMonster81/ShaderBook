Shader "Unlit/MyShader9_3"
{
    Properties
    {
        //因为VertexLit中使用了这个变量，所以必须声明
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
        _MainTex ("Main Tex", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        //需要更换渲染队列
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
			
			Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "Lighting.cginc"
            //必须引入这个库才有下面使用的宏定义
            #include "AutoLight.cginc"

            //特别需要注意的是，因为在预处理的时候相当于替换原来的代码
            //所以当变量名字声明不正确的时候可能会报空
            //所以必须要保证以下几点：
            //1.a2f中顶点坐标变量必须为vertex
            //2.a2f的变量必须命名为v，v2f中的顶点位置变量必须为pos
            //如果不确定可以查源码，宏的定义是怎么写的
            struct a2f
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                //用这个宏来声明阴影贴图纹理坐标变量,_ShadowCoord
                //填入3因为前面0,1,2个已经被占用，用第4个寄存器存
                SHADOW_COORDS(3)
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            v2f vert (a2f v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //根据平台不同来计算阴影贴图纹理坐标变量，把顶点坐标从模型空间变换到光源空间后存到_ShadowCoord
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = i.worldNormal;
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                clip (texColor.a - _Cutoff);
				
				fixed3 albedo = texColor.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));
                fixed3 viewDir = normalize(_WorldSpaceLightPos0.xyz - mul(unity_ObjectToWorld, i.pos).xyz);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( saturate(dot(reflectDir, viewDir)), _Gloss);

                float3 halfDir = normalize(worldLight + viewDir);
                specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);


                //这个宏用_ShadowCoord对相对应的贴图纹理进行采样
                //fixed atten = 1.0;
                //fixed shadow = SHADOW_ATTENUATION(i);

                //这个宏将阴影和衰减相乘的结果赋值到第一个变量中
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 col = ambient + (diffuse + specular) * atten ;
                return fixed4(col, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
