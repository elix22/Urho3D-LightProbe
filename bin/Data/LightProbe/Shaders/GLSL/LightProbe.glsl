#ifdef COMPILEPS
//=============================================================================
//=============================================================================
uniform int cProbeIndex;
uniform vec3 cProbePosition;
uniform float cMinProbeDistance;
uniform float cTextureSize;
uniform float cSHIntensity;

#ifdef GL_ES
#define USE_TEXTURE2D
#endif

#line 1000
//=============================================================================
//=============================================================================
vec3 irradcoeffs(vec3 L00, vec3 L1_1, vec3 L10, vec3 L11, 
                 vec3 L2_2, vec3 L2_1, vec3 L20, vec3 L21, vec3 L22,
                 vec3 n) 
{
  //------------------------------------------------------------------
  // These are variables to hold x,y,z and squares and products

	float x2 ;
	float  y2 ;
	float z2 ;
	float xy ;
	float  yz ;
	float  xz ;
	float x ;
	float y ;
	float z ;
	vec3 col ;
  //------------------------------------------------------------------       
  // We now define the constants and assign values to x,y, and z 
	
	const float c1 = 0.429043 ;
	const float c2 = 0.511664 ;
	const float c3 = 0.743125 ;
	const float c4 = 0.886227 ;
	const float c5 = 0.247708 ;
	x = n.x ; y = n.y ; z = n.z ;
  //------------------------------------------------------------------ 
  // We now compute the squares and products needed 

	x2 = x*x ; y2 = y*y ; z2 = z*z ;
	xy = x*y ; yz = y*z ; xz = x*z ;
  //------------------------------------------------------------------ 
  // Finally, we compute equation 13

	col = c1*L22*(x2-y2) + c3*L20*z2 + c4*L00 - c5*L20 
            + 2*c1*(L2_2*xy + L21*xz + L2_1*yz) 
            + 2*c2*(L11*x+L1_1*y+L10*z) ;

	return col;
}

vec3 GetSH(int i)
{
    #ifdef USE_TEXTURE2D
    vec3 sh = texture2D(sEnvMap, vec2(float(cProbeIndex*9 + i), 0)/cTextureSize).xyz;
    #else
    vec3 sh = texelFetch(sEnvMap, ivec2(cProbeIndex*9 + i, 0), 0).xyz;
    #endif
    sh = (sh - vec3(0.5, 0.5, 0.5)) * 10.0f;
    return sh;
}

#line 2000
vec3 SHDiffuse(vec3 normal, vec3 worldPos)
{
    // world pos
    vec3 seg = cProbePosition - worldPos;
    float dist = length(seg);
    if (dist > cMinProbeDistance)
    {
        return vec3(0,0,0);
    }

    dist = clamp(dist, 0.75, cMinProbeDistance);

    // read sh
    vec3 sh[9];
    for (int i = 0; i < 9; ++i)
    {
        sh[i] = GetSH(i);
    }

    return irradcoeffs(sh[0], sh[1], sh[2], sh[3], sh[4], sh[5], sh[6], sh[7], sh[8], normal) * 1.0/dist;
}

vec3 GatherDiffLightProbes(vec3 normal, vec3 worldPos)
{
    if (cProbeIndex == -1)
    {
        return vec3(0,0,0);
    }

    return SHDiffuse(normal, worldPos) * cSHIntensity;
}
#endif //COMPILEPS

