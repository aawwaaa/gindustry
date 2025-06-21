using Godot;
using System.Collections.Generic;
using Gindustry.Attributes;
using Gindustry.Content;

namespace Gindustry.Type;

[GDScriptAdapterTarget("GA_ContentCategory")]
[GlobalClass]
public partial class ContentCategory : ResourceType
{
    public static new readonly ResourceTypeType Type = new() { Id = "content-category" };

    public static readonly ContentCategory Resource = new() { Id = "resource" };
    public static readonly ContentCategory Transportation = new() { Id = "transportation" };
    public static readonly ContentCategory Production = new() { Id = "production" };
    public static readonly ContentCategory Military = new() { Id = "military" };
    public static readonly ContentCategory Mesh = new() { Id = "mesh" };
    public static readonly ContentCategory Misc = new() { Id = "misc" };

    public static void __Resource__StaticInit()
    {
        Vars.Types.RegisterType(Type);

        Vars.Types.RegisterType(Resource);
        Vars.Types.RegisterType(Transportation);
        Vars.Types.RegisterType(Production);
        Vars.Types.RegisterType(Military);
        Vars.Types.RegisterType(Mesh);
        Vars.Types.RegisterType(Misc);
    }

    public override ResourceTypeType _GetType() { return ContentCategory.Type; }

    [Export]
    public int order = 0;
    [Export]
    public Texture2D icon = GD.Load<Texture2D>("res://assets/asset-not-found.png");

    public List<Content.Content> Contents { get; private set; } = new List<Content.Content>();
    public Godot.Collections.Array<Content.Content> contents() => new Godot.Collections.Array<Content.Content>(Contents);

    public virtual void _AddContent(Content.Content content) { }
    public void AddContent(Content.Content content)
    {
        _AddContent(content);
        Contents.Add(content);
    }
}
