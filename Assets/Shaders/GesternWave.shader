Shader "Unlit/GesternWave"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        [HDR] _WaveColor ("Wave Color", Color) = (1,1,1,1)

		_Wavelength1 ("Wavelength Wave A", Float) = 10
		_Amplitude1 ("Amplitude Wave A", Float) = 1
		_Speed1 ("Speed Wave A", Float) = 1
		_Steepnes1 ("Steepnes Wave A", Range(0,1)) = 0.5
		_Direction1 ("Direction Wave A (2D)", Vector) = (1,0,0,0)

		_Wavelength2 ("Wavelength Wave B", Float) = 10
		_Amplitude2 ("Amplitude Wave B", Float) = 1
		_Speed2 ("Speed Wave B", Float) = 1
		_Steepnes2 ("Steepnes Wave B", Range(0,1)) = 0.5
		_Direction2 ("Direction Wave B (2D)", Vector) = (1,0,0,0)

		_NormalMapScrollSpeed ("Normal Map Scroll Speed", Vector) = (1,1,1,1)		
		
		_DistortionFactor("Distortion Factor", Range(0, 0.5)) =  0.15
        _WaterFog("Water Fog", Range(0, 1)) =  0.5

        _SunThreshold("Sun Glitter Threshold", Range(0, 100)) =  1        
        
        _SSPower("Subsurface Scatering Power", Float) =  2
        _SSScale("Subsurface Scatering Scale", Range(0, 1)) =  0.5

        [NoScaleOffset] _NormalMap1("Normal Map 1", 2D) = "white" {}
        [NoScaleOffset] _DuDvMap1("Normal Map 1 Distortion", 2D) = "white" {}
		
        [NoScaleOffset] _NormalMap2("Normal Map 2", 2D) = "white" {}
		[NoScaleOffset] _DuDvMap2("Normal Map 2 Distortion", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"      
            #include "UnityStandardBRDF.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;

                half3 normal : TEXCOORD0;
                half3 binormal : TEXCOORD1;
                half3 tangent : TEXCOORD2;

                half2 uv : TEXCOORD3;
                half4 uvGrab : TEXCOORD4;

                float3 worldPos : TEXCOORD5;
                half4 screenPos : TEXCOORD6;
            };

            struct WaveInfo
            {
                float wavelength; 	// (W)
                float amplitude; 	// (A)
                float speed; 		// (phi)
                float2 direction;	// (D)
                float steepnes; 	// (Q)
            };

		    struct TangentSpace
    		{
                half3 normal;
			    half3 binormal;
			    half3 tangent;			    
		    };

            //sampler2D _MainTex;
            //float4 _MainTex_ST;

            half4 _WaveColor;

            half _Wavelength1, _Amplitude1, _Speed1, _Steepnes1;
            half _Wavelength2, _Amplitude2, _Speed2, _Steepnes2;
            
            half _DistortionFactor, _WaterFog, _SunThreshold;

            float _Distortion, _SSPower, _SSScale;            
                
            half4 _Direction1, _Direction2;
            half4 _NormalMapScrollSpeed;
            
            sampler2D _NormalMap1, _NormalMap2;
            sampler2D _DuDvMap1, _DuDvMap2;
            sampler2D _CameraOpaqueTexture, _CameraDepthTexture;
            
            half4 _CameraDepthTexture_TexelSize;

            half3 GesternWave(WaveInfo wave, inout TangentSpace tangentSpace, float3 p, float t)
            {
                half w = sqrt( 9.81 * ( (2*UNITY_PI) / wave.wavelength ) );
                //float w = 2 * UNITY_PI / wave.wavelength;
                half PHI_t = wave.speed * w * t;
                half2 D = normalize(wave.direction.xy);
                half Q = wave.steepnes / (w * wave.amplitude * 2);			

                half f1 = w * dot ( D, p.xz ) + PHI_t;		
                half S = sin(f1);
                half C = cos(f1);

                half WA = w * wave.amplitude;
                half WAS = WA * S;
                half WAC = WA * C;						

                tangentSpace.binormal += half3
                (
                    Q * (D.x * D.x) * WAS,
                    D.x * WAC,
                    Q * (D.x * D.y) * WAS
                );

                tangentSpace.tangent += half3
                (
                    Q * (D.x * D.y) * WAS,
                    D.y * WAC,
                    Q * (D.y * D.y) * WAS
                );

                tangentSpace.normal += half3
                (
                    D.x * WAC,
                    Q * WAS,
                    D.y * WAC
                );			

                half f3 = cos(f1);
                half f4 =  Q * wave.amplitude * f3;

                return half3
                (
                    f4 * D.x,					// X
                    wave.amplitude * sin(f1),	// Y
                    f4 * D.y					// Z
                );
            }

            TangentSpace CalculateTangentSpace(TangentSpace tangentSpace)
            {
                tangentSpace.binormal = half3(
                    1 - tangentSpace.binormal.x,
                    tangentSpace.binormal.y,
                    -tangentSpace.binormal.z
                );
                tangentSpace.tangent = half3(
                    -tangentSpace.tangent.x,
                    tangentSpace.tangent.y,
                    1 - tangentSpace.tangent.z
                );
                tangentSpace.normal = half3(
                    -tangentSpace.normal.x,
                    1 - tangentSpace.normal.y,
                    -tangentSpace.normal.z
                );
                
                return tangentSpace;
            }	

            v2f vert (float4 vertex : POSITION, float3 normal : NORMAL, float4 tangent : TANGENT, float2 uv : TEXCOORD0)
            {               
                v2f o;

                float3 p = vertex.xyz;
			    float t = _Time.y;

                WaveInfo wave1 = {_Wavelength1, _Amplitude1, _Speed1, _Direction1.xy, _Steepnes1};
                WaveInfo wave2 = {_Wavelength2, _Amplitude2, _Speed2, _Direction2.xy, _Steepnes2};

			    TangentSpace tangentSpace = { half3(0,0,0), half3(0,0,0), half3(0,0,0) };

			    p += GesternWave(wave1, tangentSpace, p, t);
			    p += GesternWave(wave2, tangentSpace, p, t);

			    vertex.xyz = p;

                tangentSpace = CalculateTangentSpace(tangentSpace);	

                o.normal = tangentSpace.normal;
                o.binormal = tangentSpace.binormal;
                o.tangent = tangentSpace.tangent;                

                o.screenPos = ComputeScreenPos(UnityObjectToClipPos(vertex));
                o.pos = UnityObjectToClipPos(vertex); 
                o.worldPos = mul(unity_ObjectToWorld, vertex).xyz;

                o.uvGrab = ComputeGrabScreenPos(UnityObjectToClipPos(vertex));
                o.uv = uv;

                return o;
            }

            half2 AlignWithGrabTexel (half2 uv)
            {
	            #if UNITY_UV_STARTS_AT_TOP
		        if (_CameraDepthTexture_TexelSize.y < 0) 
                {
    			    uv.y = 1 - uv.y;
		        }
	            #endif

                return (floor(uv * _CameraDepthTexture_TexelSize.zw) + 0.5) * abs(_CameraDepthTexture_TexelSize.xy);
            }
                        
            half3 SkyReflection(float3 worldPos, half3x3 tangentSpaceMatrix, half4 normalMapCoords)//, half2 uv)
            {
                half3 normalMap1 = UnpackNormal(tex2D(_NormalMap1, normalMapCoords.xy));
			    half3 normalMap2 = UnpackNormal(tex2D(_NormalMap2, normalMapCoords.zw));
                half3 normal = normalMap1 + normalMap1;
			   
                half3 worldNormal = normalize(mul(tangentSpaceMatrix, normal));

                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                half3 worldRefl = reflect(-worldViewDir,  worldNormal );
                //worldRefl.y = clamp(worldRefl.y, 0.75, 1);
                half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
                half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);                

                half reflectionFactor = dot(worldViewDir, worldNormal);
                half3 relectedColor = lerp( _WaveColor.rgb, skyColor, reflectionFactor);
                
                //SUN GLITTER
                float4 lightColor = max(0, dot(_WorldSpaceLightPos0.xyz, reflect(-worldViewDir.xzy, worldNormal.xzy))) * _LightColor0;
                lightColor.a = (lightColor.a > 0.98 + _SunThreshold * 0.02);
                half3 glitter = lightColor * lightColor.a;

                //SUBSURFACE SCATERING
	            half3 subsurfaceHeight = normalize(_WorldSpaceLightPos0.xyz + half3(0, worldPos.y, 0));
	            half ViewDotH = pow( saturate( dot(worldViewDir, -subsurfaceHeight) ), _SSPower ) * _SSScale;
                half3 subsurfaceScatter = _LightColor0 * ViewDotH;
                
                return saturate(relectedColor + glitter + subsurfaceScatter);
            }

            half3 Distortion(half3x3 tangentSpaceMatrix, half4 normalMapCoords)
            {
                half3 duDvMap1 = UnpackNormal(tex2D(_DuDvMap1, normalMapCoords.xy));
                half3 duDvMap2 = UnpackNormal(tex2D(_DuDvMap2, normalMapCoords.zw));
                half3 duDVMapSum = duDvMap1 + duDvMap2; 

                half3 worldDuDvMap = normalize(mul(tangentSpaceMatrix, duDVMapSum));                
                
                return worldDuDvMap * _DistortionFactor;
            }
                    
            half3 SurfaceColor(half3 distortion, half3 skyColor, half4 screenPos)
            {
                distortion.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	            half2 uv = AlignWithGrabTexel((screenPos.xy + distortion) / screenPos.w);

                half backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	            half surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	            half depthDifference = backgroundDepth - surfaceDepth;

                distortion *= saturate(depthDifference);
                uv = AlignWithGrabTexel((screenPos.xy + distortion) / screenPos.w);
	            backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	            depthDifference = backgroundDepth - surfaceDepth;

                half3 underwaterColor = tex2D(_CameraOpaqueTexture, uv).rgb;
                
                half4 depthFactor = saturate(_WaterFog * depthDifference);          
                
                return lerp(underwaterColor, skyColor, depthFactor);
            }
            
            half4 frag (v2f i) : SV_Target
            {
                half4 normalMapCoords;
                normalMapCoords.xy = i.uv + (_Time.x * _NormalMapScrollSpeed.x) * _Direction1.xy;
    			normalMapCoords.zw = i.uv + (_Time.x * _NormalMapScrollSpeed.y) * _Direction2.xy;
            
                half3x3 tangentSpaceMatrix = { 
                    i.binormal.x, i.normal.x, i.tangent.x,
                    i.binormal.y, i.normal.y, i.tangent.y,
                    i.binormal.z, i.normal.z, i.tangent.z
                };

                half3 skyReflection = SkyReflection(i.worldPos, tangentSpaceMatrix, normalMapCoords);//, i.uv);
                
                half3 distortion = Distortion(tangentSpaceMatrix, normalMapCoords);
                
                half3 surfaceColor = SurfaceColor(distortion, skyReflection, i.screenPos);

                half4 c = 0;
                c.rgb = surfaceColor;                
                return c;                 
            }
            ENDCG
        }
    }
}