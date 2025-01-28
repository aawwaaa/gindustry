using Godot;
using System;

[CSharpObjectTypeName("ref_object")]
[GDScriptAdapterTarget("GA_RefObject")]
[GlobalClass]
public partial class RefObject : GodotObject
{
    public ulong objectId = 0;
    public ObjectType objectType = null;
    public bool objectReady = false;

    public virtual void _ObjectInit() {
        Vars.objects.AddObject(this, objectId);
    }
    public virtual void _ObjectCreate() { }
    public virtual void _ObjectReady() { }
    public virtual void _ObjectUpdate(float duration) { }
    public virtual void _ObjectFree() { }

    public void ObjectCreate()
    {
        _ObjectCreate();
        _ObjectInit();
        if (Vars.objects.autoReady)
            _ObjectReady();
    }

    public void ObjectUpdate(float duration)
    {
        if (!objectReady) return;
        _ObjectUpdate(duration);
    }

    public void ObjectFree()
    {
        _ObjectFree();
        Vars.objects.ObjectFreed(objectId);
        CallDeferred("free");
    }
    

}

