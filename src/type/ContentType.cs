using Godot;
using System.Collections.Generic;

[GDScriptAdapterTarget("GA_ContentType")]
[GlobalClass]
public partial class ContentType: ResourceType
{
    public static new readonly ResourceTypeType Type = new() { Id = "content-type" };

    public static readonly ContentType Content = new() { Id = "content" };
    public static readonly ContentType Entity = new() { Id = "entity" };
    public static readonly ContentType Block = new() { Id = "block" };
    public static readonly ContentType Item = new() { Id = "item" };
    public static readonly ContentType Fluid = new() { Id = "fluid" };
    public static readonly ContentType Recipe = new() { Id = "recipe" };
    public static readonly ContentType Energy = new() { Id = "energy" };
    public static readonly ContentType MeshBlock = new() { Id = "mesh-block" };

    public static void __Resource__StaticInit()
    {
        Vars.Types.RegisterType(Type);

        Vars.Types.RegisterType(Content);
        Vars.Types.RegisterType(Entity);
        Vars.Types.RegisterType(Block);
        Vars.Types.RegisterType(Item);
        Vars.Types.RegisterType(Fluid);
        Vars.Types.RegisterType(Recipe);
        Vars.Types.RegisterType(Energy);
        Vars.Types.RegisterType(MeshBlock);
    }

    public override ResourceTypeType _GetType() { return ContentType.Type; }

    [Export]
    public int order = 0;
    [Export]
    public Texture2D icon = GD.Load<Texture2D>("res://assets/asset-not-found.png");

    [Export]
    public PackedScene selector_panel = null;

    public List<Content> Contents { get; private set; } = new List<Content>();
    public Godot.Collections.Array<Content> contents() => new Godot.Collections.Array<Content>(Contents);

    public virtual void _AddContent(Content content) { }
    public void AddContent(Content content)
    {
        _AddContent(content);
        Contents.Add(content);
    }
}
