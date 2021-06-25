// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/MyShader6_4"
{
    Properties
    {
        //漫反射的颜色,可以理解为材质，物体吸收了光，反射出什么颜色
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        //高光反射的颜色,可以理解为材质，物体吸收了光，反射出什么颜色
        _Specular("Diffuse", Color) = (1,1,1,1)
        //控制高光区域的大小，可以理解为Phong模型的一个系数
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        

        Pass
        {
            //逐顶点的前向渲染
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            //引入这个库才能正确使用内置的光照变量
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : COLOR;
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                //模型空间到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //世界坐标下的法线，逆矩阵+转置矩阵
                o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = i.worldNormal;
                //世界空间下指向光源的平行光方向
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //兰伯特经验模型
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 color = ambient + diffuse;

                //高光反射模型
                //反射方向
                fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));
                //视角方向
                fixed3 viewDir = normalize(_WorldSpaceLightPos0.xyz - mul(unity_ObjectToWorld, i.pos).xyz);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( saturate(dot(reflectDir, viewDir)), _Gloss);

                //Blinn-Phong模型
                float3 halfDir = normalize(worldLight + viewDir);
                specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // sample the texture
                fixed3 col = ambient + diffuse + specular;
                return fixed4(col, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
