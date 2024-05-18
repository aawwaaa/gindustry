using Godot;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;

public partial class ObjectsManager: Node
{
    public readonly Dictionary<ulong, RefObject> objects = new Dictionary<ulong, RefObject>();
    public readonly Dictionary<string, IRefObjectType<RefObject>> objectTypes = new Dictionary<string, IRefObjectType<RefObject>>();
    public readonly Dictionary<uint, IRefObjectType<RefObject>> objectTypeIndexed = new Dictionary<uint, IRefObjectType<RefObject>>();
    
    public uint objectTypeIncID = 1;
    public ulong objectIncID = 1;

    public delegate void ObjectAddedEventHandler (RefObject obj);
    public event ObjectAddedEventHandler ObjectAdded;

    public void AddObject(RefObject obj)
    {
        if (obj.objectID == 0){
            obj.objectID = objectIncID;
            objectIncID++;
        }
        objects.Add(obj.objectID, obj);
        if (ObjectAdded != null) ObjectAdded(obj);
    }

    public void RemoveObject(RefObject obj)
    {
        objects.Remove(obj.objectID);
    }

    public void Reset()
    {
        if(ObjectAdded != null) ObjectAdded(null);
        ResetObjectTypes();
        ResetObjects();
    }

    public void Init()
    {
        InitObjectTypeMapping();
    }

    public void Load(ReadableStream stream)
    {
        Utils.LoadWithVersion(stream, new Utils.LoadCallback[]{() => {
            LoadObjectTypeMapping(stream);
            LoadObjects(stream);
        }});
    }

    public void Write(WritableStream stream)
    {
        Utils.SaveWithVersion(stream, new Utils.SaveCallback[]{() => {
            SaveObjectTypeMapping(stream);
            SaveObjects(stream);
        }});
    }

    public void ResetObjects()
    {
        objectIncID = 1;
        foreach (RefObject obj in objects.Values)
        {
            obj.Free();
        }
        objects.Clear();
    }

    public void ResetObjectTypes()
    {
        objectTypeIncID = 1;
        objectTypeIndexed.Clear();
        foreach (RefObjectType<RefObject> objType in objectTypes.Values)
        {
            objType.TypeIndex = 0;
            if (objType is PlaceholderObjectType<RefObject>)
            {
                objectTypes.Remove(objType.TypeID);
                objType.Free();
            }
        }
    }

    public T GetObjectOrNull<T>(ulong objectID) where T: RefObject
    {
        if (objects.ContainsKey(objectID))
        {
            return objects[objectID] as T;
        }
        return null;
    }

    public async Task<T> GetObjectAsync<T>(ulong objectID) where T: RefObject
    {
        if (objects.ContainsKey(objectID))
        {
            return objects[objectID] as T;
        }
        TaskCompletionSource<T> tcs = new TaskCompletionSource<T>();
        ObjectAddedEventHandler handler = null;
        handler = (obj) => 
        {
            if (obj == null)
            {
                ObjectAdded -= handler;
                tcs.SetResult(null);
                return;
            }
            if (obj.objectID == objectID)
            {
                ObjectAdded -= handler;
                tcs.SetResult(obj as T);
                return;
            }
        };
        ObjectAdded += handler;
        return await tcs.Task;
    }

    public void GetObjectCallback<T>(ulong objectID, Action<T> callback) where T: RefObject
    {
        GetObjectAsync<T>(objectID).ContinueWith(x => callback(x.Result));
    }

    public void InitObjectTypeMapping(bool reset = true)
    {
        if (reset) ResetObjectTypes();
        foreach (IRefObjectType<RefObject> objType in objectTypes.Values)
        {
            if (objType.TypeIndex != 0) continue;
            objType.TypeIndex = objectTypeIncID;
            objectTypeIndexed.Add(objectTypeIncID, objType);
            objectTypeIncID++;
        }
    }

    public void SaveObjectTypeMapping(WritableStream stream)
    {
        stream.IntUnsigned(objectTypeIncID);

        foreach (IRefObjectType<RefObject> objType in objectTypes.Values)
        {
            stream.String(objType.TypeID);
        }
    }

    public void LoadObjectTypeMapping(ReadableStream stream)
    {
        uint count = stream.IntUnsigned();
        for (int i = 0; i < count; i++)
        {
            string typeID = stream.String();
            IRefObjectType<RefObject> objType = objectTypes.ContainsKey(typeID)
                ? objectTypes[typeID]
                : new PlaceholderObjectType<RefObject>(typeID);
            objType.TypeIndex = objectTypeIncID;
            objectTypeIndexed.Add(objectTypeIncID, objType);
            objectTypeIncID++;
        }
        InitObjectTypeMapping(false);
    }

    public void SaveObject(WritableStream stream, RefObject obj)
    {
        stream.IntUnsigned(obj.GetObjectType().TypeIndex);
        obj.SaveData(stream);
    }

    public RefObject LoadObject(ReadableStream stream)
    {
        uint index = stream.IntUnsigned();
        IRefObjectType<RefObject> objType = objectTypeIndexed[index];
        RefObject obj = objType.LoadFrom(stream);
        return obj;
    }

    public void SaveObjects(WritableStream stream)
    {
        stream.IntUnsigned((uint)objects.Count);
        foreach (RefObject obj in objects.Values)
        {
            SaveObject(stream, obj);
        }
    }

    public void LoadObjects(ReadableStream stream)
    {
        uint count = stream.IntUnsigned();
        for (int i = 0; i < count; i++)
        {
            RefObject obj = LoadObject(stream);
        }
    }
}

public partial class RefObject: Node
{
    public static readonly RefObjectType<RefObject> TYPE = new EmptyConstructObjectType<RefObject>("RefObject");
    public static readonly StringName GROUP_NAME = "objects";

    public ulong objectID = 0;

    public virtual RefObjectType<RefObject> _GetType()
    {
        return TYPE;
    }

    public RefObjectType<RefObject> GetObjectType()
    {
        return _GetType();
    }

    public virtual void _ObjectInit()
    {
        Name = GetObjectType().TypeID + "_" + objectID;
        AddToGroup(GROUP_NAME);
    }

    public virtual void _ObjectReady()
    {
        if (!IsInsideTree())
        {
            Vars.objects.AddChild(this);
        }
    }

    public virtual void _ObjectFree()
    {
        Vars.objects.RemoveObject(this);
    }

    public new void Free()
    {
        _ObjectFree();
        base.Free();
    }

    public virtual void _LoadData(ReadableStream stream)
    {
    }

    public virtual void _SaveData(WritableStream stream)
    {
    }

    public void LoadData(ReadableStream stream)
    {
        Utils.LoadWithVersion(stream, new Utils.LoadCallback[]{() => {
            objectID = stream.LongUnsigned();
        }});
        _LoadData(stream);
    }

    public void SaveData(WritableStream stream)
    {
        Utils.SaveWithVersion(stream, new Utils.SaveCallback[]{() => {
            stream.LongUnsigned(objectID);
        }});
        _SaveData(stream);
    }
}

public interface IRefObjectType<out T> where T: RefObject
{
    abstract string TypeID{ get; }
    abstract uint TypeIndex{ get; set; }
    T Create(bool init = true);
    T LoadFrom(ReadableStream stream);
}

public partial class RefObjectType<T>: Resource, IRefObjectType<T> where T: RefObject
{
    // TODO: Mod name + typeID = TypeID

    public virtual string TypeID
    {
        get { return TypeID; }
        protected set { TypeID = value; }
    }

    public virtual uint TypeIndex{ get; set; }

    public RefObjectType(string typeID)
    {
        TypeID = typeID;
        TypeIndex = 0;
        Vars.objects.objectTypes.Add(TypeID, this);
    }

    public virtual T _Create()
    {
        return null;
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

    public virtual T LoadFrom(ReadableStream stream)
    {
        T obj = _Create();
        obj.LoadData(stream);
        InitObject(obj);
        return obj;
    }
}

public partial class EmptyConstructObjectType<T>: RefObjectType<T> where T: RefObject, new()
{
    public EmptyConstructObjectType(string typeID): base(typeID) { }

    public override T _Create()
    {
        return new T();
    }
}

public partial class PlaceholderObjectType<T>: RefObjectType<T> where T: RefObject
{
    public PlaceholderObjectType(string typeID): base(typeID) { }
}
