using Gindustry.Attributes;
using Gindustry.Test;
using Godot;

namespace Gindustry.Test.GA;

[GDScriptAdapterTarget("GA_CSharpClass")]
[GlobalClass]
public partial class CSharpClass : GodotObject {

    public CSharpClass() {
        A = 100;
    }

    public int A { get; set; }

    public virtual void Test() {
        A = 1000;
    }
    public void Test2() {
        A = 2000;
    }
}

