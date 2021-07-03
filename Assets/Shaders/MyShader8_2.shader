Shader "Unlit/MyShader8_2"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        //控制整体的透明度
        _AlphaScale ("AlphaScale", Range(0,1)) = 1
    }
    SubShader
    {
        //将渲染队列换成Transparent
        Tags { "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

        Pass
        {
            ZWrite On
            //ColorMask用于设置颜色通道的写掩码，当ColorMask为0时，表示该Pass不会输出任何颜色
            //这样下来该Pass就只需写入深度缓存
            ColorMask 0
        }
        
        Pass
        {
            ZWrite Off
        //将源颜色的因子设置成SrcAlpha将目标颜色的因子设置成OneMinusSrcAlpha
        //相当于 SrcColor * srcAlpha + DesColor * (1 - srcAlpha)其中SrcColor是改片元产生的颜色,des为颜色缓存上的颜色
        Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM   
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _AlphaScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed4 texColor = tex2D(_MainTex, i.uv);

                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rbg * albedo * max(0, dot(worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);

            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
