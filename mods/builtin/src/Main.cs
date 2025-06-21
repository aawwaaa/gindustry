using Gindustry.CSharpUtils;
using Gindustry.Mod;
using Godot;
using System;
using System.Threading.Tasks;

namespace builtin;

[GlobalClass]
public partial class Main: Mod
{
    public override void _ModInit(CoroutineBridge b)
    {
        b.Finish();
    }
}
