//最基础的shader

Shader "MyShader/MyShader5_1"
{
    //属性
    Properties
    {
    //声明一个Color类型的属性（可在inspector面板看到）
    //结构： 内部变量名，(inspector显示名字, 类型) = 默认值
    _Color ("Color Tint", Color) = (1.0,1.0,1.0,1.0)
    }


    //第一个subshader，只会执行一个，根据硬件的高低配置来
    SubShader
    {
        //第一个通道，有多个可执行多个
        Pass
        {
            //CGPROGRAM 表示可编程渲染管线代码开始
            CGPROGRAM

            //UnityCG.cginc包含了最常用的函数等等，一般都需要引用上
            #include "UnityCG.cginc"

            //顶点着色器的函数名为vert
            #pragma vertex vert
            //片元着色器的函数名为frag
            #pragma fragment frag

            //要用到属性，需要声明一个类型匹配的变量，名字必须与内部变量名相同
            fixed4 _Color;

            //2是to的意思(two的谐音)，application to vertex
            struct a2v
            {
                //POSITION表示应用阶段输入的模型空间顶点坐标
                float4 vertex : POSITION;
                //表示顶点模型空间的法线
                float3 normal : NORMAL;
                //表示改顶点的纹理坐标
                float4 texcoord : TEXCOORD0;
                //更多类型的语义 TANGENT 切线 COLOR 顶点颜色
            };

            //vertex to fragment
            struct v2f
            {
                //pos表示裁剪空间的坐标
                //看到网上说SV_position的声明如果不是第一个在手机上会有问题
                float4 pos : SV_POSITION;
                //COLOR0用来存颜色信息
                fixed3 color : COLOR0;
            };

            //SV表示system value的意思
            //SV_POSITION 是表示输出值为顶点着色器的输出值  语义
            //顶点着色器一般需要把顶点从模型空间转到齐次裁剪空间，还未进行 裁剪 和 透视除法
            float4 vert(a2v v) :SV_POSITION
            {
                // Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
                return UnityObjectToClipPos(v.vertex);
            }

            //CPU
            //准备好各个顶点的数据 传递给GPU

            //GPU
            // ↑ 顶点着色器
            //裁剪
            //透视除法
            //屏幕映射（把未裁剪的顶点映射到屏幕上）
            //三角形设置，生成三角形，三角形遍历
            // ↓ 片元着色器
            //逐片元操作


            //SV_Target 表示片元着色器的输出值
            fixed4 frag():SV_Target
            {
                return fixed4(1.0,1.0,1.0,1.0);
            }

            //结束
            ENDCG
        }
    }
}