using Godot;
using System;

public partial class RefObjectType<T> : Resource, IRefObjectType<T> where T : IRefObject
{
    // TODO: Mod name + typeID = TypeID

    public string TypeID { get; protected set; }

    public uint TypeIndex { get; set; }

    public RefObjectType(string typeID)
    {
        string modPrefix = Vars.mods.currentLoadingMod != null
            ? (Vars.mods.currentLoadingMod.id + "_")
            : "";
        TypeID = modPrefix + typeID;
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

