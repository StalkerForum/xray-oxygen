#include "common.h"
#include "oxy_config.h"

struct   vf
{
	float2	tbase	: TEXCOORD0;	// base
	float2	tnorm0	: TEXCOORD1;	// nm0
	float2	tnorm1	: TEXCOORD2;	// nm1
	float3	M1		: TEXCOORD3;
	float3	M2		: TEXCOORD4;
	float3	M3		: TEXCOORD5;
	float3	v2point	: TEXCOORD6;
#ifdef	USE_SOFT_WATER
#ifdef	NEED_SOFT_WATER
	float4	tctexgen: TEXCOORD7;
#endif	//	USE_SOFT_WATER
#endif	//	NEED_SOFT_WATER	
	float4	c0		: COLOR0;
	float	fog		: FOG;
	float4	hpos	: SV_Position;
};

Texture2D	s_nmap;
TextureCube	s_env0;
TextureCube	s_env1;

Texture2D	s_jitter;
Texture2D	s_leaves;

#if defined(USE_SOFT_WATER) && defined(NEED_SOFT_WATER)
float3	water_intensity;
#endif	//	defined(USE_SOFT_WATER) && defined(NEED_SOFT_WATER)

float3 calc_moon_road(float3 color, float3 vreflect, float2 tc, float depth, float Nz)
{
	float r = 0.0015*s_jitter.Sample(smp_base, tc).x;											// randomize borders of road
	float f = dot(normalize(vreflect.xz), -normalize(L_sun_dir_w.xz));
	f = step(lerp(0.998 + r, 1, depth*0.01), f);		// road appearance factor
	f *= step(10, depth);															// cut road in near 10 m
	f *= saturate((depth - 10)*0.5);													// fade in road in 2 m
	f *= step(Nz, 0);																// remove road from pixels with normals with positive z for better look
	f *= 1 - saturate(abs(L_sun_dir_w.y * 2));										// road fading out with sun height
	//f *= ogse_c_various.x;															// weather control
	return lerp(color, L_sun_color * MOON_ROAD_INTENSITY, f);
}

float4 main( vf I, float4 pos2d : SV_Position ) : SV_Target
{
	float4	base = s_base.Sample(smp_base, I.tbase);
	float3	n0 = s_nmap.Sample(smp_base, I.tnorm0);
	float3	n1 = s_nmap.Sample(smp_base, I.tnorm1);
	float3	Navg = n0 + n1 - 1;

	float3	Nw = mul(float3x3(I.M1, I.M2, I.M3), Navg);
			Nw = normalize(Nw);
	float3	v2point = normalize(I.v2point);
	float3	vreflect = reflect(v2point, Nw);
			vreflect.y = vreflect.y * 2 - 1;     // fake remapping

	base.rgb *= I.c0.xyz;
	
	float3	env0 = s_env0.Sample(smp_rtlinear, vreflect);
	float3	env1 = s_env1.Sample(smp_rtlinear, vreflect);
	float3	env = lerp(env0,env1,L_ambient.w);
			env *= env * 2;

	float	fresnel = saturate(dot(vreflect,v2point));
	float	power = pow(fresnel,9);
	float	amount = 0.15h + 0.25h*power;	// 1=full env, 0=no env

	float3	c_reflection = env * amount;
	float3	final = lerp(c_reflection,base.rgb,base.a);

			final *= I.c0 * 2;

#ifdef	NEED_SOFT_WATER

	float	alpha = 0.75h + 0.25h * power; // 1=full env, 0=no env

#ifdef	USE_SOFT_WATER

	//	ForserX: additional depth
	float2 PosTc = I.tctexgen.xy / I.tctexgen.z;
	gbuffer_data gbd = gbuffer_load_data(PosTc, pos2d);

	float4 _P = float4(gbd.P, gbd.mtl);
	float waterDepth = _P.z - I.tctexgen.z;
	
	// Water fog
	float  fog_exp_intens = -4.0h;
	float fog = 1 - exp(fog_exp_intens*waterDepth);
	float3 Fc = float3(0.1h, 0.1h, 0.1h) * water_intensity.r;
	final = lerp(Fc, final, alpha);

	alpha = min(alpha, saturate(waterDepth));

	alpha = max(fog, alpha);

	//	Leaves
	float4	leaves = s_leaves.Sample(smp_base, I.tbase);
			leaves.rgb *= water_intensity.r;
	float	calc_cos = -dot(float3(I.M1.z, I.M2.z, I.M3.z),  normalize(v2point));
	float	calc_depth = saturate(waterDepth*calc_cos);
	float	fLeavesFactor = smoothstep(0.025, 0.05, calc_depth);
			fLeavesFactor *= smoothstep(0.1, 0.075, calc_depth);
	final = lerp(final, leaves, leaves.a*fLeavesFactor);
	alpha = lerp(alpha, leaves.a, leaves.a*fLeavesFactor);
	
	// Moon road
	final = calc_moon_road(final, vreflect, I.tbase.xy, waterDepth, Nw.z);
#endif	//	USE_SOFT_WATER

	//	Fogging
	final = lerp(fog_color, final, I.fog);
	alpha *= I.fog*I.fog;

	return  float4   (final, alpha);

#else	//	NEED_SOFT_WATER
			//	Fogging
			final = lerp(fog_color, final, I.fog);
			return  float4   (final, I.fog*I.fog);
#endif
}