using Godot;
using System;

[GDScriptAdapterTargetAttribute("GA_Entity")]
[GlobalClass]
public partial class Entity: RefObject
{
    private World _world;
    public World World {
        get { return _world; }
        set { _world = value; }
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
