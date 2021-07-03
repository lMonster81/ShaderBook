Shader "Unlit/MyShader7_2"
{
Properties
    {
        _Color ("Color Tint", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
        //bump 内置法线纹理，作为默认值
        _BumpMap ("Normal Map", 2D) = "bump" {}
        //控制凹凸程度，如果为0表示法线纹理不会对光照产生任何结果
        _BumpScale ("Bump Scale", Float) = 1.0
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                //TANGENT语义用来秒速tangent变量，表示顶点的切线，tangent.w用来决定切线空间下的第三个坐标轴，副切线的方向性
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                //之前是float2，现在因为要用zw分量存额外的法线贴图，因此定义成float4,用成一个变量存可以节约性能，减少寄存器的使用
                float4 uv : TEXCOORD0;
                //因为是在切线空间下计算
                //切线空间下的光照方向
                float3 lightDir : TEXCOORD1;
                //切线空间下的视角方向
                float3 viewDir : TEXCOORD2;
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            fixed4 _Color;
            float _Gloss;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                //宏开始
                //计算副法向量
                float3 binormal = cross( normalize (v.normal), normalize(v.tangent.xyz));
                //构建从模型空间到切线空间的矩阵
                float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

                //或者直接使用下面这个, 这个宏在 UnityCG.cginc中被定义，可以直接得到rotation矩阵，代码实现和上面的一样
                //TANGENT_SPACE_ROTATION

                //将光照方向从模型空间到切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                //将视角方向从模型空间到法线空间
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                //对法线贴图进行采样
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal;

                //如果该贴图在unity内没有设置成法线贴图
                tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                //如果设置了
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);

            }
            ENDCG
        }
    }
    FallBack "Specular"
}
