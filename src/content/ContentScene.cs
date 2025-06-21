using Godot;
using Godot.Collections;

namespace Gindustry.Content;

[Tool]
[GlobalClass]
public partial class ContentScene : Node
{
    [Export]
    public Script ContentType
    {
        get => _contentType;
        set
        {
            _contentType = value;
            _defaults.Clear();
            Init();
        }
    }
    private Script _contentType;

    private GodotObject _instance;
    private Array<Dictionary> _propertyList = new Array<Dictionary>();

    private Dictionary _defaults = new Dictionary();
    private Dictionary _storaged = new Dictionary();

    public override void _Ready()
    {
        Init();
    }

    private void Init()
    {
        if (_storaged == null)
            _storaged = new Dictionary();
        if (_instance != null)
            _instance = null;
        if (_contentType == null)
        {
            _propertyList.Clear();
            NotifyPropertyListChanged();
            return;
        }

        if (_contentType.HasMethod("__ContentScene__Type"))
            _instance = _contentType.Call("__ContentScene__Type").As<GodotObject>();
        else if (_contentType.HasMethod("__content_scene__type"))
            _instance = _contentType.Call("__content_scene__type").As<GodotObject>();
        else if (_contentType is GDScript gds)
            _instance = gds.New().As<GodotObject>();
        else if (_contentType is CSharpScript cs)
            _instance = cs.New().As<GodotObject>();
        else
            _instance = null;

        _propertyList.Clear();
        bool ignoring = false;
        StringName ignoredCategory = new StringName();

        foreach (var prop in _instance.GetPropertyList())
        {
            if (prop["name"].AsStringName() == "Resource" && (prop["usage"].As<int>() & (int)PropertyUsageFlags.Category) != 0)
            {
                ignoring = true;
                ignoredCategory = prop["name"].AsStringName();
                continue;
            }
            if (prop["name"].AsStringName() != ignoredCategory && (prop["usage"].As<int>() & (int)PropertyUsageFlags.Category) != 0)
                ignoring = false;
            if (ignoring) continue;

            if ((prop["usage"].As<int>() & (int)PropertyUsageFlags.Category) != 0)
                prop["name"] = "Content / " + prop["name"].AsString();
            if ((prop["usage"].As<int>() & (int)PropertyUsageFlags.Storage) != 0)
            {
                _defaults[prop["name"].AsStringName()] = _instance.Get(prop["name"].AsStringName());
                if (!_storaged.ContainsKey(prop["name"].AsStringName()))
                {
                    _storaged[prop["name"].AsStringName()] = _instance.Get(prop["name"].AsStringName());
                }
            }
            prop["usage"] = prop["usage"].As<int>() & ~(int)PropertyUsageFlags.Storage;
            _propertyList.Add(prop);
        }

        _propertyList.Add(new Dictionary
        {
            { "name", "storaged" },
            { "type", (int)Variant.Type.Dictionary },
            { "usage", (int)PropertyUsageFlags.Storage | (int)PropertyUsageFlags.Internal }
        });

        CallDeferred("NotifyPropertyListChanged");
    }

    public override void _Notification(int what)
    {
        if (what == NotificationPredelete)
        {
            if (_instance != null)
            {
                _instance = null;
            }
        }
    }

    public override Godot.Collections.Array<Dictionary> _GetPropertyList()
    {
        return new Godot.Collections.Array<Dictionary>(_propertyList);
    }

    public override Variant _Get(StringName property)
    {
        if (property == "content_type")
            return _contentType;
        if (property == "storaged")
            return _storaged;
        return _storaged.ContainsKey(property) ? _storaged[property] : default;
    }

    public override bool _Set(StringName property, Variant value)
    {
        if (property == "content_type")
        {
            ContentType = value.As<GDScript>();
            return true;
        }
        if (property == "storaged")
        {
            _storaged = value.As<Dictionary>();
            return true;
        }
        _storaged[property] = value;
        return false;
    }

    public override Variant _PropertyGetRevert(StringName property)
    {
        if (_instance == null) return default;
        return _defaults.ContainsKey(property) ? _defaults[property] : default;
    }

    public override bool _PropertyCanRevert(StringName property)
    {
        if (_instance == null) return false;
        return _defaults.ContainsKey(property);
    }

    public virtual bool __PackedScene__Init(Mod.Mod mod)
    {
        Init();
        foreach (var key in _storaged.Keys)
            _instance.Set(key.As<StringName>(), _storaged[key]);
        if (_instance.HasMethod("_InitFromScene"))
            _instance.Call("_InitFromScene", this);
        else
            _instance.Call("_init_from_scene", this);
        return true;
    }

    public virtual Resource __PackedScene__GetResource()
    {
        return _instance as Resource;
    }
}
