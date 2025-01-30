using Godot;
using System;

[GDScriptAdapterTarget("GA_ObjectType")]
[GlobalClass]
public partial class ObjectType : Resource
{
    public static ObjectType For<T>() where T : RefObject, new()
    {
        Type t = typeof(T);
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
    public ObjectType(String id) { this.id = id; }

    [Export] public String id;
    private String __fullId = null;
    public String FullId
    {
        get { return __fullId ?? (__fullId = _GetFullId()); }
        set { __fullId = value; }
    }

    public uint index = 0;

    public GodotObject mod = null;

    public String GetModId()
    {
        if (mod == null) return "builtin";
        return (String)mod.GetChained(StringNames.mod_info, StringNames.id);
    }

    public String GetFullIdDefault(String insert = "")
    {
        return GetModId() + ":" +
            (insert.Length > 0? insert + ":": "") + id;
    }

    protected virtual String _GetFullId()
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
}

[AttributeUsage(AttributeTargets.Class, AllowMultiple = false)]
public class CSharpObjectTypeNameAttribute : Attribute
{
    public String id;
    private ObjectType type;

    public CSharpObjectTypeNameAttribute(String id)
    {
        this.id = id;
    }

    public ObjectType GetObjectType<T>() where T : RefObject, new()
    {
        if (type == null) type = new CSharpObjectType<T>(id);
        return type;
    }
}
