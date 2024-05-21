using Godot;
using System;

public interface IRefObject
{
    public static readonly StringName GROUP_NAME = "objects";

    ulong ObjectID { get; set; }

    IRefObjectType<IRefObject> _GetType();
    void _ObjectInit();
    void _ObjectReady();
    void _ObjectFree();
    void _LoadData(IReadableStream stream);
    void _SaveData(IWritableStream stream);
}

public static class IRefObjectEx
{
    public static IRefObjectType<T> GetObjectType<T>(this T obj) where T : IRefObject
    {
        return obj._GetType() as IRefObjectType<T>;
    }

    public static void ObjectInit(this IRefObject obj)
    {
        Vars.objects.AddObject(obj);
        if (obj is Node node){
            node.Name = obj.GetObjectType().TypeID + "#" + obj.ObjectID;
            node.AddToGroup(IRefObject.GROUP_NAME);
            node.ProcessMode = Node.ProcessModeEnum.Pausable;
        }
        obj._ObjectInit();
        if (Vars.objects.autoReady)
        {
            obj.ObjectReady();
        }
    }

    public static void ObjectReady(this IRefObject obj)
    {
        if (obj is Node node){
            if (!node.IsInsideTree())
                Vars.objects.AddChild(node);
        }
        obj._ObjectReady();
    }

    public static void ObjectFree(this IRefObject obj)
    {
        obj._ObjectFree();
        Vars.objects.RemoveObject(obj);
        if (obj is GodotObject gobj)
        {
            if (gobj is Node node) node.QueueFree();
            else gobj.Free();
        }
    }

    public static void LoadData(this IRefObject obj, IReadableStream stream)
    {
        Utils.LoadWithVersion(stream, new Utils.LoadCallback[]{() => {
            obj.ObjectID = stream.LongUnsigned();
        }});
        obj._LoadData(stream);
    }

    public static void SaveData(this IRefObject obj, IWritableStream stream)
    {
        Utils.SaveWithVersion(stream, new Utils.SaveCallback[]{() => {
            stream.LongUnsigned(obj.ObjectID);
        }});
        obj._SaveData(stream);
    }
}
