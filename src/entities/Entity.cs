using Godot;
using System;
using Gindustry.Attributes;
using Gindustry.World;
using Gindustry.IO;
using Gindustry.Object;
using System.Collections.Generic;

namespace Gindustry.Entities;

[GDScriptAdapterTarget("GA_Entity")]
[GlobalClass]
public partial class Entity: RefObject
{
    protected Dimension _dimension;
    protected Vector3 _position;

    public virtual Dimension Dim { get => _dimension; set => _dimension = value; }
    public virtual Vector3 Position { get => _position; set => _position = value; }

    public List<Entity> Children { get; set; } = new();

    public void AddChild(Entity child)
    {
        Children.Add(child);
    }
    public void RemoveChild(Entity child)
    {
        Children.Remove(child);
    }

    public override void _LoadData(Reader r) 
    {
        base._LoadData(r);
    }
    public override void _SaveData(Writer w) 
    {
        base._SaveData(w);
    }
}
