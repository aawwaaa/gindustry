using Godot;

[CSharpObjectTypeName("ref_object_a")]
[GDScriptAdapterTarget("GA_RefObjectA")]
[CSharpScriptName("RefObjectA")]
[GlobalClass]
public partial class RefObjectA : RefObject
{
    public virtual void _Foo()
    {
        GD.Print("Foo!");
    }
    public virtual void _Bar()
    {
        GD.Print("Bar!");
    }

    public void FooBar()
    {
        _Foo();
        _Bar();
    }
}
