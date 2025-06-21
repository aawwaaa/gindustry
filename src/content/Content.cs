using Godot;
using System;
using Gindustry.Attributes;
using System.Collections.Generic;
using Gindustry.Object;
using Gindustry.Type;
using Gindustry.CSharpUtils;

namespace Gindustry.Content;

[GDScriptAdapterTarget("GA_Content")]
[GlobalClass]
public partial class Content: ObjectType
{
    public ContentType Type { get; set; }
    public ContentCategory Category { get; set; }
    public List<ContentTag> Tags { get; set; } = new();

    protected override string _GetFullId()
    {
        return GetFullIdDefault(Type.Id);
    }

    public virtual string _GetTrName()
    {
        return Tr(FullId);
    }
    public string Name => _GetTrName();

    public virtual void _ContentRegisted() { }
    public void ContentRegisted()
    {
        Type.AddContent(this);
        Category.AddContent(this);
        foreach(var tag in Tags) {
            tag.AddContent(this);
        }

        _ContentRegisted();
    }

    public void Tag(params string[] tags)
    {
        foreach(var tag in tags)
            Tags.Add(ContentTag.Get(tag));
    }
    // Overriden in C#
    public virtual void _DataDefault()
    {
        Type = ContentType.Content;
        Category = ContentCategory.Misc;
    }

    public virtual void _Data() => _DataDefault();

    public virtual void _Assign() {}

    public virtual void _Load(CoroutineBridge c) { c.Finish(); }
    public virtual void _LoadAssets(CoroutineBridge c) { c.Finish(); }
    public virtual void _LoadHeadless(CoroutineBridge c) { c.Finish(); }

    public virtual void _InitFromSceneDefault(ContentScene node) { }
    public virtual void _InitFromScene(ContentScene node) => _InitFromSceneDefault(node);

    public static Transform3D GetAbsoluteTransform(Node3D node)
    {
        var current = node.Transform;
        var parent = node.GetParent();
        while (parent != null)
        {
            if (parent is Node3D n3)
            {
                current = n3.Transform * current;
            }
            parent = parent.GetParent();
        }
        return current;
    }
}
