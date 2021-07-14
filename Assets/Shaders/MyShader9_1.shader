
Shader "Unlit/MyShader9_1"
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
            //必须使用编译指令
            #pragma multi_compile_fwdbase
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
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

                //Blinn-Phong模型
                float3 halfDir = normalize(worldLight + viewDir);
                specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                //衰减参数
                fixed atten = 1.0;

                fixed3 col = ambient + (diffuse + specular) * atten;
                return fixed4(col, 1.0);
            }
            ENDCG
        }


        //第二个Pass，用来计算更多的逐像素光照
        Pass
        {
            Tags { "LightMode" = "ForwardAdd"}

            //必须开启混合模式
            Blend One One

            //将上面的代码复制过来，然后做修改，去掉环境光，自发光，逐顶点光照，SH光照等
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            //必须使用编译指令
            #pragma multi_compile_fwdadd
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            //Unity升级过后引入了这个库才会有unity_WorldToLight变换矩阵
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = i.worldNormal;
                
                //需要根据光源的不同类型，取得光照的方向
                //平行光的情况, 可以根据是否定义了下面这个来得到
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                #endif

                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));
                fixed3 viewDir = normalize(_WorldSpaceLightPos0.xyz - mul(unity_ObjectToWorld, i.pos).xyz);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( saturate(dot(reflectDir, viewDir)), _Gloss);

                //Blinn-Phong模型
                float3 halfDir = normalize(worldLight + viewDir);
                specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                //衰减参数
                //需要根据光源处理不同的衰减
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    #if defined(POINT)
                    //将顶点位置转移到光源空间下
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    //通过对用在光源空间下距离光源长度来对lightTexture0进行采样，UNITY_ATTEN_CHANNEL表示代表衰减值的那个分量
                    //因为用数学表达式来计算衰减会涉及到开根号除法等运算量大的操作，因为Unity采用了一张纹理作为衰减值的查找表，我们只需注意他的对角线上的值。
                    fixed atten = tex2D(_LightTexture0, float2(dot(lightCoord, lightCoord).rr)).UNITY_ATTEN_CHANNEL;
                        //聚光灯的情况,需要判断是否在有效光照区域内
                    #elif defined(SPOT)
                        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
                        fixed atten = 1.0;
                    #endif
                #endif

                fixed3 col = (diffuse + specular) * atten;
                return fixed4(col * atten, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
