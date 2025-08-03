using Godot;
using Gindustry.Attributes;
using Gindustry.World;
using Gindustry.Object;

namespace Gindustry.Entities.Type.Base;

[GDScriptAdapterTarget("GA_SubEntity")]
[GlobalClass]
public partial class SubEntity : Entity
{
    protected RefObjectRefGeneric<Entity> _parent = new();
    
    public virtual Entity Parent 
    { 
        get => _parent; 
        set => this.ReplaceParent(value);
    }

    public override Dimension Dim 
    { 
        get => Parent?.Dim; 
        set { if (Parent != null) Parent.Dim = value; }
    }

    public override Vector3 Position 
    { 
        get => Parent?.Position ?? Vector3.Zero; 
        set { if (Parent != null) Parent.Position = value; }
    }

    private void ReplaceParent(Entity value)
    {
        _parent.V?.RemoveChild(this);
        _parent.V = value;
        _parent.V?.AddChild(this);
    }

    public override void _LoadData(Gindustry.IO.Reader r)
    {
        base._LoadData(r);
        _parent.LoadData(r);
        _parent.V?.AddChild(this);
    }

    public override void _SaveData(Gindustry.IO.Writer w)
    {
        base._SaveData(w);
        _parent.SaveData(w);
    }
}