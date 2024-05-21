using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

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

    public void ModuleGameReset()
    {
        if (ObjectAdded != null) ObjectAdded(null);
        ResetObjectTypes();
        ResetObjects();
        autoReady = false;
    }

    public void ModuleGameInit()
    {
        InitObjectTypeMapping();
    }

    public void ModuleGameReady()
    {
        foreach (IRefObject obj in objects.Values)
        {
            obj.ObjectReady();
        }
        autoReady = true;
    }

    public void ModuleGameLoad(IReadableStream stream)
    {
        Utils.LoadWithVersion(stream, new Utils.LoadCallback[]{() => {
            LoadObjectTypeMapping(stream);
            LoadObjects(stream);
        }});
    }

    public void ModuleGameSave(IWritableStream stream)
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
