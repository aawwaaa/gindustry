using Godot;
using System;

[CSharpObjectTypeName("ref_object")]
[GDScriptAdapterTarget("GA_RefObject")]
[GlobalClass]
public partial class RefObject : GodotObject, Saveable
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
        ObjectInit();
    }

    public void ObjectInit()
    {
        _ObjectInit();
        if (Vars.objects.AutoReady)
            ObjectReady();
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
    
    public void ObjectReady()
    {
        if (objectReady) return;
        objectReady = true;
        _ObjectReady();
    }

    public void _LoadData(Reader r) { }
    public void _SaveData(Writer w) { }

    public void _LoadSyncData(Reader r) { }
    public void _SaveSyncData(Writer w) { }

    public void LoadData(Reader r)
    {
        r.A((r) => {
            objectId = r.U64();
        });
        _LoadData(r);
        ObjectInit();
    }

    public void SaveData(Writer w)
    {
        w.A((w) => {
            w.U64(objectId);
        });
        _SaveData(w);
    }
}

