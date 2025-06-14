using Godot;
using System;
using System.Collections.Generic;

public partial class Utils
{
    public partial class Serialization : GodotObject
    {
        public interface ISerializer {
            string GetName();
            int GetNameHash();

            bool Matched(object obj);
        }

        public class Serializer<T>: ISerializer
        {
            public virtual string GetName() => "builtin_none";
            public virtual int GetNameHash() => GetName().GetHashCode();

            public virtual bool Matched(object obj) => false;

            public virtual void Serialize(Writer w, T obj) => w.V(obj as GodotObject);

            public virtual T Unserialize(Reader r) => (T)(object)r.V();
        }

        public class VariantSerializer : Serializer<Variant>
        {
            public override string GetName() => "builtin_variant";
            public override bool Matched(object obj) => obj is Variant;

            public override void Serialize(Writer w, Variant obj) => w.V(obj);
            public override Variant Unserialize(Reader r) => r.V();
        }

        public class ArraySerializer : Serializer<Godot.Collections.Array>
        {
            public override string GetName() => "builtin_array";
            public override bool Matched(object obj) => obj is Variant v && v.VariantType == Variant.Type.Array;

            public override void Serialize(Writer w, Godot.Collections.Array array)
            {
                w.I32(array.Count);
                foreach (var item in array)
                    Serialization.Serialize(w, item);
            }
            public override Godot.Collections.Array Unserialize(Reader r)
            {
                var size = r.I32();
                var array = new Godot.Collections.Array();
                for (int i = 0; i < size; i++)
                    array.Add(Serialization.Unserialize<Variant>(r));
                return array;
            }
        }

        public class DictionarySerializer : Serializer<Godot.Collections.Dictionary>
        {
            public override string GetName() => "builtin_dictionary";
            public override bool Matched(object obj) => obj is Godot.Collections.Dictionary;

            public override void Serialize(Writer w, Godot.Collections.Dictionary dict)
            {
                w.I32(dict.Count);
                foreach (var key in dict.Keys)
                {
                    Serialization.Serialize(w, key);
                    Serialization.Serialize(w, dict[key]);
                }
            }
            public override Godot.Collections.Dictionary Unserialize(Reader r)
            {
                var size = r.I32();
                var dict = new Godot.Collections.Dictionary();
                for (int i = 0; i < size; i++)
                {
                    var key = Serialization.Unserialize<Variant>(r);
                    var value = Serialization.Unserialize<Variant>(r);
                    dict[key] = value;
                }
                return dict;
            }
        }

        public class NodeSerializer : Serializer<Node>
        {
            public override string GetName() => "builtin_node";
            public override bool Matched(object obj) => obj is Node;

            public override void Serialize(Writer w, Node node) => w.S(node.GetPath());
            public override Node Unserialize(Reader r) => Vars.Tree.Root.GetNodeOrNull(r.S());
        }

        /*
        public class ContentSerializer : Serializer<Content>
        {
            public override string GetName() => "builtin_content";
            public override bool Matched(object obj) => obj is Content;

            public override void Serialize(Writer w, Content content) => w.I64(content.Index);

            public override Content Unserialize(Reader r) => Vars.Contents.GetContentByIndex(r.I64());
        }

        public class ResourceTypeSerializer : Serializer<ResourceType>
        {
            public override string GetName() => "builtin_resource_type";
            public override bool Matched(object obj) => obj is ResourceType;

            public override void Serialize(Writer w, ResourceType resourceType)
            {
                w.S(resourceType.GetType().FullId);
                w.S(resourceType.FullId);
            }
            public override ResourceType Unserialize(Reader r)
            {
                var type = r.S();
                var id = r.S();
                var typeObj = Vars.Types.GetTypeType(type);
                return typeObj == null ? default : Vars.Types.GetType(typeObj, id);
            }
        }
        */

        public class ObjectTypeSerializer : Serializer<ObjectType>
        {
            public override string GetName() => "builtin_object_type";
            public override bool Matched(object obj) => obj is ObjectType;

            public override void Serialize(Writer w, ObjectType objectType) => w.U32(objectType.index);
            public override ObjectType Unserialize(Reader r)
            {
                var index = r.U32();
                return Vars.Vars_Objects.Registry.ObjectTypesMapped.ContainsKey(index) ?
                    Vars.Vars_Objects.Registry.ObjectTypesMapped[index] : default;
            }
        }

        public class RefObjectSerializer : Serializer<RefObject>
        {
            public override string GetName() => "builtin_ref_object";
            public override bool Matched(object obj) => obj is RefObject;

            public override void Serialize(Writer w, RefObject refObject) => w.U64(refObject.objectId);
            public override RefObject Unserialize(Reader r) => Vars.Objects.GetObjectOrNull(r.U64());
        }

        public class RefObjectRefSerializer : Serializer<RefObjectRef>
        {
            public override string GetName() => "builtin_ref_object_ref";
            public override bool Matched(object obj) => obj is RefObjectRef;

            public override void Serialize(Writer w, RefObjectRef refObjectRef) => w.U64(refObjectRef.Id);
            public override RefObjectRef Unserialize(Reader r) => new RefObjectRef() { Id = r.U64() };
        }

        /*
        public class RefObjectPackedSerializer : Serializer<RefObjectPacked>
        {
            public override string GetName() => "builtin_ref_object_packed";
            public override bool Matched(object obj) => obj is RefObjectPacked;

            public override void Serialize(Writer w, RefObjectPacked refObjectPacked) => Vars.Objects.SaveObject(w, refObjectPacked);

            public override RefObjectPacked Unserialize(Reader r) => Vars.Objects.LoadObject(r);
        }

        public class PlayerSerializer : Serializer<Player>
        {
            public override string GetName() => "builtin_player";
            public override bool Matched(object obj) => obj is Player;

            public override void Serialize(Writer w, Player player) => w.I64(player.PlayerId);
            public override Player Unserialize(Reader r) => Vars.Players.GetPlayerOrNull(r.I64());
        }

        public class EntityComponentSerializer : Serializer
        {
            public override string GetName() => "builtin_entity_component";
            public override bool Matched(object obj) => obj.Obj is EntityComponent;

            public override void Serialize(Writer w, object obj)
            {
                w.V((obj.Obj as EntityComponent).Entity);
                w.I32((obj.Obj as EntityComponent).ComponentId);
            }

            public override object Unserialize(Reader r)
            {
                var entity = r.V();
                var componentId = r.I32();
                return (entity.Obj as Entity).ComponentsId[componentId];
            }
        }

        */

        public static List<ISerializer> Serializers { get; } = new();
        public static Dictionary<int, ISerializer> Map { get; } = new();

        public static void AddSerializer(ISerializer serializer)
        {
            Serializers.Insert(0, serializer);
            Map[serializer.GetNameHash()] = serializer;
        }

        public static void Serialize<T>(Writer w, T obj)
        {
            foreach (var serializer in Serializers)
            {
                if (!serializer.Matched(obj)) continue;
                var hash = serializer.GetNameHash();
                w.I32(hash);
                ((Serializer<T>)serializer).Serialize(w, obj);
                return;
            }
        }

        public static T Unserialize<T>(Reader r)
        {
            var hash = r.I32();
            if (!Map.ContainsKey(hash)) return default;
            return ((Serializer<T>)Map[hash]).Unserialize(r);
        }

        public static byte[] SerializeAsBuffer(object obj)
        {
            ByteArrayIO.Temp.Clear();
            Serialize(ByteArrayIO.Temp.Writer(), obj);
            return ByteArrayIO.Temp.DumpData();
        }

        public static T UnserializeFromBuffer<T>(byte[] buffer)
        {
            ByteArrayIO.Temp.SetData(buffer);
            return Unserialize<T>(ByteArrayIO.Temp.Reader());
        }

        public static void AddDefaults()
        {
            AddSerializer(new VariantSerializer());
            AddSerializer(new ArraySerializer());
            AddSerializer(new DictionarySerializer());
            AddSerializer(new NodeSerializer());

            // AddSerializer(new ContentSerializer());
            // AddSerializer(new ResourceTypeSerializer());
            AddSerializer(new ObjectTypeSerializer());
            AddSerializer(new RefObjectSerializer());
            AddSerializer(new RefObjectRefSerializer());
            // AddSerializer(new RefObjectPackedSerializer());

            // AddSerializer(new PlayerSerializer());
            // AddSerializer(new EntitySerializer());
        }

        // 添加 snake_case 的实例方法
        public void add_serializer(ISerializer serializer) => AddSerializer(serializer);
        public void serialize(Writer w, object obj) => Serialize(w, obj);
        public Variant unserialize(Reader r) => Unserialize<Variant>(r);
        public byte[] serialize_as_buffer(object obj) => SerializeAsBuffer(obj);
        public Variant unserialize_from_buffer(byte[] buffer) => UnserializeFromBuffer<Variant>(buffer);
        public void add_defaults() => AddDefaults();
    }
}
