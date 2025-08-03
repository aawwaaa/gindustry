using Gindustry;
using Gindustry.CSharpUtils;
using Gindustry.Mod;
using Gindustry.Utils;
using Godot;
using System;
using System.Threading.Tasks;

namespace builtin;

[GlobalClass]
public partial class Main: Mod
{
    public Log.Logger logger = Log.RegisterLogger("Builtin");
    public override void _ModInit(CoroutineBridge b)
    {
        b.Finish();
    }

    public override async void _LoadContents(CoroutineBridge c)
    {
        await LoadResources("mod://content/");
        c.Finish();
    }
}
