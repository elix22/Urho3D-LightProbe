//
// Copyright (c) 2008-2017 the Urho3D project.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#include <Urho3D/Core/Context.h>
#include <Urho3D/Scene/Scene.h>
#include <Urho3D/Scene/SceneEvents.h>
#include <Urho3D/Resource/ResourceCache.h>
#include <Urho3D/Resource/Image.h>
#include <Urho3D/Graphics/Material.h>
#include <Urho3D/Graphics/Model.h>
#include <Urho3D/IO/FileSystem.h>

#include "LightProbeCreator.h"
#include "LightProbe.h"
#include "CubeCapture.h"

#include <Urho3D/DebugNew.h>
//=============================================================================
//=============================================================================
LightProbeCreator::LightProbeCreator(Context* context)
    : Object(context)
    , initialCnt_(0)
    , numProcessed_(0)
    , maxThreads_(8)
{
    LightProbe::RegisterObject(context);
    CubeCapture::RegisterObject(context);
}

LightProbeCreator::~LightProbeCreator()
{
}

void LightProbeCreator::Init(Scene *scene, const String& basepath)
{
    ResourceCache* cache = GetSubsystem<ResourceCache>();

    // all lightprobes use the default unit box - parse it
    LightProbe::SetupUnitBoxGeom(cache->GetResource<Model>("Models/Box.mdl"));

    scene_ = scene;
    programPath_ = GetSubsystem<FileSystem>()->GetProgramDir();
    basepath_ = basepath;

    SubscribeToEvent(E_SHBUILDDONE, URHO3D_HANDLER(LightProbeCreator, HandleBuildEvent));
}

void LightProbeCreator::GenerateLightProbes()
{
    ParseLightProbesInScene();
    QueueNodeProcess();
}

unsigned LightProbeCreator::ParseLightProbesInScene()
{
    PODVector<Node*> result;
    scene_->GetChildrenWithComponent(result, "LightProbe", true);

    for ( unsigned i = 0; i < result.Size(); ++i )
    {
        buildRequiredNodeList_.Push(result[i]);
        maintainedNodeList_.Push(result[i]);
    }
    initialCnt_ = buildRequiredNodeList_.Size();

    return initialCnt_;
}

void LightProbeCreator::QueueNodeProcess()
{
    while (buildRequiredNodeList_.Size() && processingNodeList_.Size() < maxThreads_)
    {
        Node* node = buildRequiredNodeList_[0];

        StartSHBuild(node);

        processingNodeList_.Push(node);
        buildRequiredNodeList_.Erase(0);
    }
}

void LightProbeCreator::StartSHBuild(Node *node)
{
    LightProbe *lightProbe = node->GetComponent<LightProbe>();
    lightProbe->GenerateSH(basepath_, programPath_);
}

void LightProbeCreator::WriteSHTableImage()
{
    SharedPtr<Image> image(new Image(context_));

    // set default size to 64x1 for testing
    // **consider this: NextPowerOfTwo(initialCnt_ * 10), 10 pixels per light probe
    image->SetSize(64, 1, 4);

    for ( int i = 0; i < (int)initialCnt_; ++i )
    {
        LightProbe *lightProbe = maintainedNodeList_[i]->GetComponent<LightProbe>();
        PODVector<Vector3> &coeffVec = lightProbe->GetCoeffVec();

        // write probe's node pos: scaled wpos -> normalized to [0, 1]
        Vector3 swpos = maintainedNodeList_[i]->GetWorldPosition() * 1.0f/100.0f;
        Vector3 npos = (swpos + Vector3::ONE) * 0.5f;
        // reverse in shader: swpos = (npos * 2.0f - Vector3::ONE) * 100.0f;

        image->SetPixel((i * 10), 0, Color(npos.x_, npos.y_, npos.z_));

        // write coeffs - normalized to [0, 1]
        for ( int j = 0; j < 9; ++j )
        {
            float c0 = coeffVec[j].x_ * 0.1f + 0.5f;
            float c1 = coeffVec[j].y_ * 0.1f + 0.5f;
            float c2 = coeffVec[j].z_ * 0.1f + 0.5f;
            // reverse in shader: coeff = (c - Vector3(0.5,0.5,0.5)) * 10.0f;
            image->SetPixel((i * 10) + j + 1, 0, Color(c0, c1, c2));
        }
    }
    image->SavePNG(programPath_ + basepath_ + "/Textures/SHprobeData.png");
}

void LightProbeCreator::MarkNodeComplete(Node *node)
{
    if (processingNodeList_.Remove(node))
    {
        ++numProcessed_;
    }

    // send event
    SendEventMsg();

    if (initialCnt_ != numProcessed_)
    {
        QueueNodeProcess();
    }
    else
    {
        WriteSHTableImage();
    }
}

void LightProbeCreator::SendEventMsg()
{
    using namespace LightProbeStatus;

    VariantMap& eventData = GetEventDataMap();
    eventData[P_INITIAL] = initialCnt_;
    eventData[P_COMPLETED] = numProcessed_;

    SendEvent(E_LIGHTPROBESTATUS, eventData);
}

void LightProbeCreator::HandleBuildEvent(StringHash eventType, VariantMap& eventData)
{
    using namespace SHBuildDone;
    Node *node = (Node*)eventData[P_NODE].GetVoidPtr();

    MarkNodeComplete(node);
}
