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

    public void Reset()
    {
        if (ObjectAdded != null) ObjectAdded(null);
        ResetObjectTypes();
        ResetObjects();
    }

    public void Init()
    {
        InitObjectTypeMapping();
    }

    public void Load(IReadableStream stream)
    {
        Utils.LoadWithVersion(stream, new Utils.LoadCallback[]{() => {
            LoadObjectTypeMapping(stream);
            LoadObjects(stream);
        }});
    }

    public void Write(IWritableStream stream)
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
        foreach (RefObjectType<IRefObject> objType in objectTypes.Values)
        {
            objType.TypeIndex = 0;
            if (objType is PlaceholderObjectType<IRefObject>)
            {
                objectTypes.Remove(objType.TypeID);
                objType.Free();
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
        stream.IntUnsigned(objectTypeIncID);

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
        IRefObject obj = objType.LoadFrom(stream);
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

    RefObjectType<IRefObject> _GetType();
    void _ObjectInit();
    void _ObjectReady();
    void _ObjectFree();
    void _LoadData(IReadableStream stream);
    void _SaveData(IWritableStream stream);
}

public static class IRefObjectEx
{
    public static RefObjectType<T> GetObjectType<T>(this T obj) where T : IRefObject
    {
        return obj._GetType() as RefObjectType<T>;
    }

    public static void ObjectInit(this IRefObject obj)
    {
        if (obj is Node node){
            node.Name = obj.GetObjectType().TypeID + "_" + obj.ObjectID;
            node.AddToGroup(IRefObject.GROUP_NAME);
        }
        obj._ObjectInit();
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
        if (obj is GodotObject godotObject)
            godotObject.Free();
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
    T Create(bool init = true);
    T LoadFrom(IReadableStream stream);
}

public partial class RefObjectType<T> : Resource, IRefObjectType<T> where T : IRefObject
{
    // TODO: Mod name + typeID = TypeID

    public virtual string TypeID
    {
        get { return TypeID; }
        protected set { TypeID = value; }
    }

    public virtual uint TypeIndex { get; set; }

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

    public virtual void InitObject(T obj)
    {
        Vars.objects.AddObject(obj);
        obj._ObjectInit();
    }

    public virtual T Create(bool init = true)
    {
        T obj = _Create();
        if (init) InitObject(obj);
        return obj;
    }

    public virtual T LoadFrom(IReadableStream stream)
    {
        T obj = _Create();
        obj.LoadData(stream);
        InitObject(obj);
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
