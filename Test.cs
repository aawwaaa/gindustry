using Godot;
using System;

public partial class Test : Node
{
    public override void _Ready()
    {
        GD.Print(ObjectType.IdFor<RefObject>());
        GD.Print(ObjectType.IdFor<RefObjectA>());
    }
}

[CSharpObjectTypeName("ref_object_a")]
public partial class RefObjectA : RefObject
{

}
