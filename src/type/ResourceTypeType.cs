using Godot;
using System.Collections.Generic;

namespace Gindustry.Type;

[GlobalClass]
public sealed partial class ResourceTypeType: ResourceType
{
    public override ResourceTypeType _GetType() { return this; }

    public Dictionary<string, ResourceType> Types { get; private set; } = new ();
    public Godot.Collections.Array<ResourceType> TypesList { get; private set; } = new ();

    public ResourceType get_type(string typeId) => Types[typeId];
    public Godot.Collections.Array<ResourceType> get_types() => TypesList;

    public void AddType(ResourceType type)
    {
        Types[type.FullId] = type;
        TypesList.Add(type);
    }

    public T Get<T>(string typeId) where T : ResourceType
    {
        return (T)Types[typeId];
    }
    public bool Contains(string typeId)
    {
        return Types.ContainsKey(typeId);
    }
}
