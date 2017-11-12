#ifdef COMPILEPS
//=============================================================================
//=============================================================================
uniform vec2 cProbeIndex;
uniform float cMinProbeDistance;
uniform float cTextSize;
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

vec3 GetSH(float width, int i, int j)
{
    #ifdef USE_TEXTURE2D
    vec3 sh = texture2D(sEnvMap, vec2(float(i*10 + j + 1), 0)/width).xyz;
    #else
    vec3 sh = texelFetch(sEnvMap, ivec2(i*10 + j + 1, 0), 0).xyz;
    #endif
    sh = (sh - vec3(0.5, 0.5, 0.5)) * 10.0f;
    return sh;
}

#line 2000
vec3 SHDiffuse(int probeIdx, vec3 normal, vec3 worldPos)
{
    // probe cnt
    float width = cTextSize;
    vec3 sh[9];

    // world pos
    #ifdef USE_TEXTURE2D
    vec3 wpos = texture2D(sEnvMap, vec2(float(probeIdx*10), 0)/width).xyz;
    #else
    vec3 wpos = texelFetch(sEnvMap, ivec2(probeIdx*10, 0), 0).xyz;
    #endif

    wpos = (wpos * 2.0 - vec3(1,1,1)) * 100.0;
    vec3 seg = wpos - worldPos;
    float dist = length(seg);
    if (dist > cMinProbeDistance)
    {
        return vec3(0,0,0);
    }
    dist = clamp(dist, 0.75, cMinProbeDistance);

    for (int j = 0; j < 9; ++j)
    {
        sh[j] = GetSH(width, probeIdx, j);
    }

    return irradcoeffs(sh[0], sh[1], sh[2], sh[3], sh[4], sh[5], sh[6], sh[7], sh[8], normal) * 1.0/dist;
}

vec3 GatherDiffLightProbes(ivec2 probeIndex, vec3 normal, vec3 worldPos)
{
    vec3 shdiff = vec3(0,0,0);
    bool foundOne = false;

    if (probeIndex.x > -1)
    {
        shdiff = SHDiffuse(probeIndex.x, normal, worldPos);
        if (shdiff.x + shdiff.y + shdiff.z > 0.1)
        {
            foundOne = true;
        }
    }

    if (probeIndex.y > -1)
    {
        vec3 shdiff2 = SHDiffuse(probeIndex.y, normal, worldPos);
        if (shdiff2.x + shdiff2.y + shdiff2.z > 0.1)
        {
            if (foundOne)
            {
                shdiff = (shdiff + shdiff2) * 0.5;
            }
            else
            {
                shdiff = shdiff2;
            }
        }
    }

    return shdiff * cSHIntensity;
}
#endif //COMPILEPS

