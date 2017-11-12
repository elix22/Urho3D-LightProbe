#ifdef COMPILEPS
//=============================================================================
//=============================================================================
uniform int2 cProbeIndex;
uniform float cMinProbeDistance;
uniform float cTextSize;
uniform float cSHIntensity;

#line 1000
//=============================================================================
//=============================================================================
float3 irradcoeffs(float3 L00, float3 L1_1, float3 L10, float3 L11, 
                   float3 L2_2, float3 L2_1, float3 L20, float3 L21, float3 L22,
                   float3 n) 
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
	float3 col ;
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

float3 GetSH(float width, int i, int j)
{
    float2 tex2 = float2(i*10 + j + 1, 0)/width;
    float3 sh = Sample2D(EnvMap, tex2).xyz;
    sh = (sh - float3(0.5, 0.5, 0.5)) * 10.0f;
    return sh;
}

#line 2000
float3 SHDiffuse(int probeIdx, float3 normal, float3 worldPos)
{
    // probe cnt
    float width = cTextSize;
    float3 sh[9];

    // world pos
    float2 tex2 = float2(probeIdx*10, 0)/width;
    float3 wpos = Sample2D(EnvMap, tex2).xyz;

    wpos = (wpos * 2.0 - float3(1,1,1)) * 100.0;
    float3 seg = wpos - worldPos;
    float dist = length(seg);

    if (dist > cMinProbeDistance)
    {
        return float3(0,0,0);
    }
    dist = clamp(dist, 0.75, cMinProbeDistance);

    [unroll(9)]
    for (int j = 0; j < 9; ++j)
    {
        sh[j] = GetSH(width, probeIdx, j);
    }

    return irradcoeffs(sh[0], sh[1], sh[2], sh[3], sh[4], sh[5], sh[6], sh[7], sh[8], normal) * 1.0/dist;
}

float3 GatherDiffLightProbes(int2 probeIndex, float3 normal, float3 worldPos)
{
    float3 shdiff = float3(0,0,0);
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
        float3 shdiff2 = SHDiffuse(probeIndex.y, normal, worldPos);
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

