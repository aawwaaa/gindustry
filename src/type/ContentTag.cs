using Godot;
using System.Collections.Generic;

[GDScriptAdapterTarget("GA_ContentTag")]
[GlobalClass]
public partial class ContentTag : ResourceType
{
    public static new readonly ResourceTypeType Type = new() { Id = "content-tag" };

    public static ContentTag Get(string tag)
    {
        if (Type.Contains("#" + tag))
            return Type.Get<ContentTag>("#" + tag);

        var inst = new ContentTag { Id = tag };
        return (ContentTag)Vars.Types.RegisterType(inst);
    }

    public override void _InitFullId() { FullId = "#" + Id; }
    public override ResourceTypeType _GetType() { return Type; }

    public List<Content> Contents { get; private set; } = new List<Content>();
    public Godot.Collections.Array<Content> contents() => new Godot.Collections.Array<Content>(Contents);

    public virtual void _AddContent(Content content) { }
    public void AddContent(Content content)
    {
        _AddContent(content);
        Contents.Add(content);
    }
}
