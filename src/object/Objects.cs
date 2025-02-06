using Godot;
using System;
using System.Threading.Tasks;
using System.Collections.Generic;

public partial class Vars
{
    public partial class Vars_Objects : Node
    {
        public partial class PlaceholderObjectType : ObjectType { }

        public class ObjectTypeRegistry
        {
            public uint ObjectTypeIncId = 1;
            public Dictionary<string, ObjectType> ObjectTypes = new();
            public Dictionary<uint, ObjectType> ObjectTypesMapped = new();
        }

        [Signal]
        public delegate void ObjectRegisteredEventHandler(RefObject obj, ulong id);

        public Dictionary<ulong, List<Action<RefObject>>> objectCallbacks = new();

        public static ObjectTypeRegistry Registry { get; } = new ObjectTypeRegistry();

        public bool AutoReady { get; set; } = true;

        private ulong objectIncId = 1;
        public Dictionary<ulong, RefObject> objects = new Dictionary<ulong, RefObject>();

        private Log.Logger logger = new Log.Logger("Objects");

        public ulong CreateId()
        {
            ulong id = objectIncId;
            do{
                objectIncId++;
            }while(objects.ContainsKey(id));
            return id;
        }

        public void AddObject(RefObject obj, ulong id = 0)
        {
            if (id == 0)
            {
                id = CreateId();
                obj.objectId = id;
            }
            objects[id] = obj;
            EmitSignal(SignalName.ObjectRegistered, obj, id);
            if (objectCallbacks.ContainsKey(id))
            {
                foreach (var callback in objectCallbacks[id])
                    callback(obj);
                objectCallbacks.Remove(id);
            }
        }

        public void MakeReady(RefObject obj)
        {
            obj.ObjectReady();
        }

        public void ObjectFreed(ulong id)
        {
            objects.Remove(id);
        }

        public bool HasObject(ulong id)
        {
            return objects.ContainsKey(id);
        }

        public RefObject GetObjectOrNull(ulong id)
        {
            if (id == 0) return null;
            return objects.ContainsKey(id) ? objects[id] : null;
        }

        public Task<RefObject> GetObject(ulong id)
        {
            TaskCompletionSource<RefObject> tcs = new();
            if (id == 0) {
                tcs.SetResult(null);
                return tcs.Task;
            }
            if (objects.ContainsKey(id))
            {
                tcs.SetResult(objects[id]);
                return tcs.Task;
            }
            GetObjectCallback(id, (obj) => {
                tcs.SetResult(obj);
            });
            return tcs.Task;
        }

        public void GetObjectCallback(ulong id, Action<RefObject> callback)
        {
            if (id == 0)
            {
                callback(null);
                return;
            }
            if (objects.ContainsKey(id))
            {
                callback(objects[id]);
                return;
            }
            if (!objectCallbacks.ContainsKey(id))
                objectCallbacks[id] = new();
            objectCallbacks[id].Add(callback);
        }

        public ulong GetObjectId(RefObject obj)
        {
            return obj?.objectId ?? 0;
        }

        public ObjectType GetObjectTypeByIndex(uint index)
        {
            return Registry.ObjectTypesMapped[index];
        }

        public ObjectType GetObjectTypeByFullId(string fullId)
        {
            return Registry.ObjectTypes[fullId];
        }

        public void ObjectReady()
        {
            foreach (var obj in objects.Values)
            {
                MakeReady(obj);
            }
            AutoReady = true;
        }

        public void Reset()
        {
            foreach (var obj in objects.Values)
                if (IsInstanceValid(obj))
                    obj.ObjectFree();
            foreach (var list in objectCallbacks.Values)
                foreach (var callback in list)
                    callback(null);
            objectCallbacks.Clear();
            EmitSignal(SignalName.ObjectRegistered, null);
            objectIncId = 1;
            AutoReady = false;
            CleanupObjectTypes();
        }

        public void CleanupObjectTypes()
        {
            foreach (var type in Registry.ObjectTypesMapped.Values)
                if (type is PlaceholderObjectType)
                    type.Free();
            Registry.ObjectTypeIncId = 1;
            Registry.ObjectTypesMapped.Clear();
        }

        public RefObject LoadObject(Reader r)
        {
            var typeId = r.U32();
            if (typeId == 0) return null;
            if (!Registry.ObjectTypesMapped.ContainsKey(typeId))
            {
                logger.Error($"Unknown object type: [{typeId}]");
                return null;
            }
            var type = Registry.ObjectTypesMapped[typeId];
            if (type is PlaceholderObjectType)
            {
                logger.Error($"Unknown object type: {type.FullId}");
                return null;
            }
            var obj = type.Create(false);
            obj.LoadData(r);
            return obj;
        }

        public void SaveObject(Writer w, RefObject obj)
        {
            if (obj == null)
            {
                w.U32(0);
                return;
            }
            w.U32(obj.objectType.index);
            obj.SaveData(w);
        }

        public void LoadData(Reader r)
        {
            r.A((r) => {
                LoadObjectTypesMapping(r);
                objectIncId = r.U64();
            });
        }

        public void SaveData(Writer w)
        {
            w.A((w) => {
                SaveObjectTypesMapping(w);
                w.U64(objectIncId);
            });
        }

        public static void AddObjectType(ObjectType type)
        {
            type.Mod = Vars.Mods.CurrentLoadingMod;
            Registry.ObjectTypes[type.FullId] = type;
        }

        public static void AddObjectType(ObjectType type1, ObjectType type2, params ObjectType[] types)
        {
            AddObjectType(type1);
            AddObjectType(type2);
            foreach (var type in types)
                AddObjectType(type);
        }

        public void InitObjectTypesMapping()
        {
            CleanupObjectTypes();
            
            foreach (var type in Registry.ObjectTypes.Values)
            {
                type.index = Registry.ObjectTypeIncId;
                Registry.ObjectTypesMapped[type.index] = type;
                Registry.ObjectTypeIncId++;
            }
        }

        public void LoadObjectTypesMapping(Reader r)
        {
            CleanupObjectTypes();

            foreach (var type in Registry.ObjectTypes.Values)
                type.index = 0;

            Registry.ObjectTypeIncId = 1;
            
            var size = r.U32();

            for (int i = 0; i < size; i++)
            {
                var uuid = r.S();

                ObjectType type;
                if (Registry.ObjectTypes.ContainsKey(uuid))
                    type = Registry.ObjectTypes[uuid];
                else
                {
                    type = new PlaceholderObjectType();
                    type.FullId = uuid;
                    logger.Warn($"Unknown object type: {uuid}");
                }

                type.index = Registry.ObjectTypeIncId;
                Registry.ObjectTypesMapped[type.index] = type;
                Registry.ObjectTypeIncId++;
            }

            foreach (var type in Registry.ObjectTypes.Values)
            {
                if (type.index != 0) continue;
                type.index = Registry.ObjectTypeIncId;
                Registry.ObjectTypesMapped[type.index] = type;
                Registry.ObjectTypeIncId++;
            }
        }

        public void SaveObjectTypesMapping(Writer w)
        {
            w.U32((uint)Registry.ObjectTypesMapped.Count);
            for (uint i = 0; i < Registry.ObjectTypesMapped.Count; i++)
            {
                var type = Registry.ObjectTypesMapped[i];
                w.S(type.FullId);
            }
        }
    }
}
