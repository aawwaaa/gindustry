using Godot;
using System;

[CSharpObjectTypeName("ref_object")]
[GDScriptAdapterTarget("RefObject")]
public partial class RefObject : Node
{
    public static readonly StringName OBJECT_TYPE_META = new StringName("objectType");

    public long objectId = 0;
    public ObjectType objectType = null;
    public bool objectReady = false;

    public virtual void _ObjectInit() { }
    public virtual void _ObjectCreate() { }
    public virtual void _ObjectReady() { }
    public virtual void _ObjectUpdate(float duration) { }
    public virtual void _ObjectFree() { }

    public void ObjectCreate()
    {
    }

    public void ObjectUpdate(float duration)
    {
        if (!objectReady) return;
        _ObjectUpdate(duration);
    }

}

