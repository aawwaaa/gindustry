using Godot;
using System;
using Gindustry.Attributes;
using Gindustry.World;
using Gindustry.IO;
using Gindustry.Object;

namespace Gindustry.Entity;

[GDScriptAdapterTarget("GA_Entity")]
[GlobalClass]
public partial class Entity: RefObject
{
    protected Dimension _dimension;
    protected Vector3 _position;

    public virtual Dimension Dim { get => _dimension; set => _dimension = value; }
    public virtual Vector3 Position { get => _position; set => _position = value; }

    public override void _LoadData(Reader r) 
    {
        base._LoadData(r);
    }
    public override void _SaveData(Writer w) 
    {
        base._SaveData(w);
    }
}
