using Godot;
using System;

[CSharpObjectTypeName("ref_object")]
[GDScriptAdapterTarget("GA_RefObject")]
[GlobalClass]
public partial class RefObject : GodotObject, Saveable
{
    public ulong objectId = 0;
    public ObjectType objectType = null;
    public bool objectReadyFlag = false;

    public virtual void _ObjectInit() {
        Vars.Objects.AddObject(this, objectId);
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
        if (Vars.Objects.AutoReady)
            ObjectReady();
    }
    
    public void ObjectUpdate(float duration)
    {
        if (!objectReadyFlag) return;
        _ObjectUpdate(duration);
    }

    public void ObjectFree()
    {
        _ObjectFree();
        Vars.Objects.ObjectFreed(objectId);
        CallDeferred("free");
    }
    
    public void ObjectReady()
    {
        if (objectReadyFlag) return;
        objectReadyFlag = true;
        _ObjectReady();
    }

    public virtual void _LoadData(Reader r) { }
    public virtual void _SaveData(Writer w) { }

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

    public RefObjectRef Ref()
    {
        return new RefObjectRef() { Id = objectId };
    }
}

