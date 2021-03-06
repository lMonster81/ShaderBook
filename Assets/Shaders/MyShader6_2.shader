// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
//逐顶点光照
///
Shader "Unlit/MyShader6_2"
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
            // sample the texture
            fixed4 col = fixed4(color, 1.0);
            return col;
        }
        ENDCG
    }
}
Fallback "Diffuse"
}
