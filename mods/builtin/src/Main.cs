using Godot;
using System;

namespace builtin;

[GlobalClass]
public partial class Main: Mod
{
    public override void _ModInit(CoroutineBridge b)
    {
        GD.Print("Hello world!");
        b.Finish();
    }
}
