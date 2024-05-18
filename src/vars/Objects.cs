using Godot;
using System;

public partial class Vars
{
    public partial class Objects: Node
    {
    }
}

public partial class RefObject: GodotObject
{
    public static readonly RefObjectType<RefObject> TYPE = new RefObjectType<RefObject>();

    public virtual void _ObjectInit()
    {

    }

    public virtual void _ObjectReady()
    {

    }

    public virtual void _ObjectFree()
    {

    }

    public virtual void _LoadData(ReadableStream stream)
    {
    }

    public virtual void _SaveData(WritableStream stream)
    {
    }
}

public partial class RefObjectType<T>: Resource where T: RefObject
{
    public virtual string TypeUUID
    {
        get { return "RefObjectType"; }
    }

    public virtual T _Create()
    {
        return (T)new RefObject();
    }

    public virtual void InitObject(T obj)
    {

    }

    public virtual T Create(bool init = true)
    {
        T obj = _Create();
        if (init) InitObject(obj);
        return obj;
    }

    public virtual T LoadFrom(ReadableStream stream)
    {
        T obj = _Create();
        obj._LoadData(stream);
        InitObject(obj);
        return obj;
    }

    public virtual void SaveTo(WritableStream stream, T obj)
    {
        obj._SaveData(stream);
    }
}
