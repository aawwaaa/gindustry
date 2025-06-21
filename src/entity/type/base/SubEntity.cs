using Godot;
using Gindustry.Attributes;
using Gindustry.World;

namespace Gindustry.Entity.Type.Base;

[GDScriptAdapterTarget("GA_SubEntity")]
[GlobalClass]
public partial class SubEntity : Entity
{
    protected Entity _parent;
    
    public virtual Entity Parent 
    { 
        get => _parent; 
        set => _parent = value; 
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
} 