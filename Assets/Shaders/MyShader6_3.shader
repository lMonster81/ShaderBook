Shader "Unlit/MyShader6_3"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
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
                fixed3 color : COLOR;
            };

            fixed4 _Diffuse;

            v2f vert (appdata v)
            {
                v2f o;
                //模型空间到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //世界坐标下的法线，逆矩阵+转置矩阵
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                //世界空间下指向光源的平行光方向
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //兰伯特经验模型
                //原本用saturate函数，将小于0的值都变成0，这样阴影部分的数值将没有变化，都为0  。
                //但是如果用半兰伯特模型，只要不是叉乘-1，都会有变化，原本无细节变化的阴影处也有细节变化了。相当于阴影处整体提亮
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * (dot(worldNormal, worldLight) * 0.5 + 0.5);

                o.color = ambient + diffuse;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = fixed4(i.color, 1.0);
                return col;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
