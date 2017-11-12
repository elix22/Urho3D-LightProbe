# Urho3D LightProbe
  
---
### Description
SH coefficients generated from cubemap texture and applied at run time via shader program to achieve interreflected transfer. Based on: An Efficient Representation for Irradiance Environment Maps.  
ref: http://graphics.stanford.edu/papers/envmap/  

In this example, there are four lightprobes in the scene placed near objects that reflect some color to validate testing - look for red boxes and green sphere.  
  
---  
### How the coffecients are generated, stored and applied:
1) CubeCapture class generates cubemap textures.
2) LightProbe class maps the texture onto a unit box and generates SH coefficients onto a spherical space.
3) LightProbeCreator class gathers SH coefficients from all the LightProbe class and packs the information into a single ShprobeData.png file.
4) shader program reads the ShprobeData.png data and applies eqn. 13 mentioned in the ref above.
  
Coefficient generation takes about **200 msec.** for the scene. Your results may vary. The example does not generate the coefficients automatically, as it's already generated.  
To enable coeff generation, set **generateLightProbes_=true** in the CharacterDemo.  

#### Some useful debugging info:
* dump cubemap textures by setting **dumpOutputFiles_=true** in CubeCapture class.
* dump sh coeffs by setting **dumpShCoeff_=true** in LightProbe class.  
**Note:** enabling the above dump will obviously impact the build time.  
  
---  
### Improvements:
For test purposes, querying for light probe's position each frame is constant but not ideal as the number of light probes increase.  Eventually, the character class should peform queries of the closest light probes and pass the index via the shader material.
  
---  
### Further optimization:
LightProbe::CalculateSH() fn - instead of re-calcuating the xy pixels, normals and cube face, this could be saved and reused as they're same for all lightprobes.
  
  
---
### Screenshots

![alt tag](https://github.com/Lumak/Urho3D-LightProbe/blob/master/screenshot/lightprobescreen1.png)
![alt tag](https://github.com/Lumak/Urho3D-LightProbe/blob/master/screenshot/lightprobescreen2.png)

---
### To Build
To build it, unzip/drop the repository into your Urho3D/ folder and build it the same way as you'd build the default Samples that come with Urho3D.
  
---  
### License
The MIT License (MIT)







