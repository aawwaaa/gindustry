using Godot;

[GDScriptAdapterTarget("GA_ResourceType")]
[GlobalClass]
public partial class ResourceType: Resource
{
    [Export]
    public string Id { get; set; }
    public Mod Mod{ get; set; } = null;

    public string FullId { get; protected set; }
    public ResourceTypeType Type { get => _GetType(); }

    public virtual void _InitFullId()
    {
        var mod_id = Mod != null? (Mod.ModInfo.Id + ":"): "";
        if (this is ResourceTypeType)
            FullId = mod_id + Id;
        else
            FullId = mod_id + Type.Id + ":" + Id;
    }
    public void InitFullId() => _InitFullId();

    public virtual ResourceTypeType _GetType() { return null; }

    public virtual void _Data() { }
    public virtual void _TypeRegisted() { }
    public virtual void _Assign() { }

    public virtual void _Load(CoroutineBridge c) { c.Finish(); }
    public virtual void _LoadAssets(CoroutineBridge c) { c.Finish(); }
    public virtual void _LoadHeadless(CoroutineBridge c) { c.Finish(); }
}
