using Godot;
using System;
using Gindustry.Attributes;
using Gindustry.Mod;

namespace Gindustry.Object;

[GDScriptAdapterTarget("GA_ObjectType")]
[GlobalClass]
public partial class ObjectType : Resource
{
    public static ObjectType For<T>() where T : RefObject, new()
    {
        System.Type t = typeof(T);
        CSharpObjectTypeNameAttribute attr = t.GetCustomAttributes(typeof(CSharpObjectTypeNameAttribute), false)[0]
            as CSharpObjectTypeNameAttribute;
        if (attr == null) return null;
        return attr.GetObjectType<T>();
    }

    public static StringName IdFor<T>() where T : RefObject, new()
    {
        return For<T>()?.FullId;
    }

    public ObjectType() {}
    public ObjectType(string id) { this.id = id; }

    [Export] public string id;
    private string __fullId = null;
    public string FullId
    {
        get { return __fullId ?? (__fullId = _GetFullId()); }
        set { __fullId = value; }
    }

    public uint index = 0;

    public Mod.Mod Source { get; set; } = null;

    public string GetModId()
    {
        if (Source == null) return "builtin";
        return Source.Info.Id;
    }

    public string GetFullIdDefault(string insert = "")
    {
        return GetModId() + ":" +
            (insert.Length > 0? insert + ":": "") + id;
    }

    protected virtual string _GetFullId()
    {
        return GetFullIdDefault();
    }

    protected virtual RefObject _Create()
    {
        throw new NotImplementedException();
    }

    public RefObject Create(bool callCreate = true)
    {
        RefObject obj = _Create();
        obj.objectType = this;
        if (callCreate) obj.ObjectCreate();
        return obj;
    }

    public virtual bool _Visible() { return true; }
}

[AttributeUsage(AttributeTargets.Class, AllowMultiple = false)]
public class CSharpObjectTypeNameAttribute : Attribute
{
    public string id;
    private ObjectType type;

    public CSharpObjectTypeNameAttribute(string id)
    {
        this.id = id;
    }

    public ObjectType GetObjectType<T>() where T : RefObject, new()
    {
        if (type == null) type = new CSharpObjectType<T>(id);
        return type;
    }
}
