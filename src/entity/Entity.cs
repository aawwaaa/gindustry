using Godot;
using System;

[GDScriptAdapterTarget("GA_Entity")]
[GlobalClass]
public partial class Entity: RefObject
{
    public override void _LoadData(Reader r) 
    {
        base._LoadData(r);
    }
    public override void _SaveData(Writer w) 
    {
        base._SaveData(w);
    }
}
