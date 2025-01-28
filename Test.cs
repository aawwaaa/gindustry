using Godot;
using System;

public partial class Test : Node
{
    public override void _Ready()
    {
        // GD.Print(ObjectType.IdFor<RefObject>());
        // GD.Print(ObjectType.IdFor<RefObjectA>());
        Resource res = GD.Load("res://test2.gd");
        if (res is GDScript script)
        {
            GodotObject instance = (GodotObject)script.New();
            instance.Call("init");
            instance.Free();
        }
    }
}
