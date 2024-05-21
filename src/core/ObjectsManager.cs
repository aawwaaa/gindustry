using Godot;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;

public partial class ObjectsManager : Node
{
    public readonly Dictionary<ulong, IRefObject> objects = new Dictionary<ulong, IRefObject>();
    public readonly Dictionary<string, IRefObjectType<IRefObject>> objectTypes = new Dictionary<string, IRefObjectType<IRefObject>>();
    public readonly Dictionary<uint, IRefObjectType<IRefObject>> objectTypeIndexed = new Dictionary<uint, IRefObjectType<IRefObject>>();

    public uint objectTypeIncID = 1;
    public ulong objectIncID = 1;

    public delegate void ObjectAddedEventHandler(IRefObject obj);
    public event ObjectAddedEventHandler ObjectAdded;

    public bool autoReady = false;

    public void AddObject(IRefObject obj)
    {
        if (obj.ObjectID == 0)
        {
            obj.ObjectID = objectIncID;
            objectIncID++;
        }
        objects.Add(obj.ObjectID, obj);
        if (ObjectAdded != null) ObjectAdded(obj);
    }

    public void RemoveObject(IRefObject obj)
    {
        objects.Remove(obj.ObjectID);
    }

    public void ModuleReset()
    {
        if (ObjectAdded != null) ObjectAdded(null);
        ResetObjectTypes();
        ResetObjects();
        autoReady = false;
    }

    public void ModuleInit()
    {
        InitObjectTypeMapping();
    }

    public void ModuleReady()
    {
        foreach (IRefObject obj in objects.Values)
        {
            obj.ObjectReady();
        }
        autoReady = true;
    }

    public void ModuleLoad(IReadableStream stream)
    {
        Utils.LoadWithVersion(stream, new Utils.LoadCallback[]{() => {
            LoadObjectTypeMapping(stream);
            LoadObjects(stream);
        }});
    }

    public void ModuleSave(IWritableStream stream)
    {
        Utils.SaveWithVersion(stream, new Utils.SaveCallback[]{() => {
            SaveObjectTypeMapping(stream);
            SaveObjects(stream);
        }});
    }

    public void ResetObjects()
    {
        objectIncID = 1;
        foreach (IRefObject obj in objects.Values)
        {
            obj.ObjectFree();
        }
        objects.Clear();
    }

    public void ResetObjectTypes()
    {
        objectTypeIncID = 1;
        objectTypeIndexed.Clear();
        foreach (IRefObjectType<IRefObject> objType in objectTypes.Values)
        {
            objType.TypeIndex = 0;
            if (objType is PlaceholderObjectType<IRefObject> placeholder)
            {
                objectTypes.Remove(objType.TypeID);
                placeholder.Free();
            }
        }
    }

    public T GetObjectOrThrow<T>(ulong objectID) where T : IRefObject
    {
        if (objects.ContainsKey(objectID))
        {
            return (T)objects[objectID];
        }
        throw new ObjectNotFoundException(objectID);
    }

    public async Task<T> GetObjectAsync<T>(ulong objectID) where T : IRefObject
    {
        if (objects.ContainsKey(objectID))
        {
            return (T)objects[objectID];
        }
        TaskCompletionSource<T> tcs = new TaskCompletionSource<T>();
        ObjectAddedEventHandler handler = null;
        handler = (obj) =>
        {
            if (obj == null)
            {
                ObjectAdded -= handler;
                tcs.SetException(new ObjectManagerResetedException());
                return;
            }
            if (obj.ObjectID == objectID)
            {
                ObjectAdded -= handler;
                tcs.SetResult((T)obj);
                return;
            }
        };
        ObjectAdded += handler;
        return await tcs.Task;
    }

    public void GetObjectCallback<T>(ulong objectID, Action<T> callback) where T : IRefObject
    {
        GetObjectAsync<T>(objectID).ContinueWith(x => callback(x.Result));
    }

    public void InitObjectTypeMapping(bool reset = true)
    {
        if (reset) ResetObjectTypes();
        foreach (IRefObjectType<IRefObject> objType in objectTypes.Values)
        {
            if (objType.TypeIndex != 0) continue;
            objType.TypeIndex = objectTypeIncID;
            objectTypeIndexed.Add(objectTypeIncID, objType);
            objectTypeIncID++;
        }
    }

    public void SaveObjectTypeMapping(IWritableStream stream)
    {
        stream.IntUnsigned(objectTypeIncID - 1);

        foreach (IRefObjectType<IRefObject> objType in objectTypes.Values)
        {
            stream.String(objType.TypeID);
        }
    }

    public void LoadObjectTypeMapping(IReadableStream stream)
    {
        uint count = stream.IntUnsigned();
        for (int i = 0; i < count; i++)
        {
            string typeID = stream.String();
            IRefObjectType<IRefObject> objType = objectTypes.ContainsKey(typeID)
                ? objectTypes[typeID]
                : new PlaceholderObjectType<IRefObject>(typeID);
            objType.TypeIndex = objectTypeIncID;
            objectTypeIndexed.Add(objectTypeIncID, objType);
            objectTypeIncID++;
        }
        InitObjectTypeMapping(false);
    }

    public void SaveObject(IWritableStream stream, IRefObject obj)
    {
        stream.IntUnsigned(obj.GetObjectType().TypeIndex);
        obj.SaveData(stream);
    }

    public IRefObject LoadObject(IReadableStream stream)
    {
        uint index = stream.IntUnsigned();
        IRefObjectType<IRefObject> objType = objectTypeIndexed[index];
        IRefObject obj = objType.LoadFromAndInit(stream);
        return obj;
    }

    public void SaveObjects(IWritableStream stream)
    {
        stream.IntUnsigned((uint)objects.Count);
        foreach (IRefObject obj in objects.Values)
        {
            SaveObject(stream, obj);
        }
    }

    public void LoadObjects(IReadableStream stream)
    {
        uint count = stream.IntUnsigned();
        for (int i = 0; i < count; i++)
        {
            IRefObject obj = LoadObject(stream);
        }
    }

    public class ObjectNotFoundException: Exception
    {
        public ulong ObjectID;
        public ObjectNotFoundException(ulong objectID): base($"Object with ID {objectID} not found")
        {
            ObjectID = objectID;
        }
    }
    
    public class ObjectManagerResetedException: Exception
    {
        public ObjectManagerResetedException(): base("Object manager reseted")
        {
        }
    }
}

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

public interface IRefObjectType<out T> where T : IRefObject
{
    abstract string TypeID { get; }
    abstract uint TypeIndex { get; set; }
    T Create();
    T LoadFrom(IReadableStream stream);
}

public static class IRefObjectTypeEx
{
    public static T CreateAndInit<T>(this IRefObjectType<T> objType) where T : IRefObject
    {
        T obj = objType.Create();
        obj.ObjectInit();
        return obj;
    }

    public static T LoadFromAndInit<T>(this IRefObjectType<T> objType, IReadableStream stream) where T : IRefObject
    {
        T obj = objType.LoadFrom(stream);
        obj.ObjectInit();
        return obj;
    }
}

public partial class RefObjectType<T> : Resource, IRefObjectType<T> where T : IRefObject
{
    // TODO: Mod name + typeID = TypeID

    public string TypeID { get; protected set; }

    public uint TypeIndex { get; set; }

    public RefObjectType(string typeID)
    {
        TypeID = typeID;
        TypeIndex = 0;
        Vars.objects.objectTypes.Add(TypeID, (IRefObjectType<IRefObject>)this);
    }

    public virtual T _Create()
    {
        throw new NotImplementedException();
    }
    public virtual T Create()
    {
        T obj = _Create();
        return obj;
    }

    public virtual T LoadFrom(IReadableStream stream)
    {
        T obj = Create();
        obj.LoadData(stream);
        return obj;
    }
}

public partial class EmptyConstructObjectType<T> : RefObjectType<T> where T : IRefObject, new()
{
    public EmptyConstructObjectType(string typeID) : base(typeID) { }

    public override T _Create()
    {
        return new T();
    }
}

public partial class PlaceholderObjectType<T> : RefObjectType<T> where T : IRefObject
{
    public PlaceholderObjectType(string typeID) : base(typeID) { }
}
