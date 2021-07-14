Shader "Unlit/MyShader9_2"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
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
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                //用这个宏来声明阴影贴图纹理坐标变量,_ShadowCoord
                SHADOW_COORDS(2)
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (a2f v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //根据平台不同来计算阴影贴图纹理坐标变量，把顶点坐标从模型空间变换到光源空间后存到_ShadowCoord
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = i.worldNormal;
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 color = ambient + diffuse;

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
    FallBack "Specular"
}
