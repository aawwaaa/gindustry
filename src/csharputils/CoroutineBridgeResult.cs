using Godot;
using System;
using System.Threading.Tasks;

namespace Gindustry.CSharpUtils;

[GlobalClass]
public partial class CoroutineBridgeResult: GodotObject
{
    private TaskCompletionSource<Variant> source;

    public Task<Variant> Task => source.Task;

    public CoroutineBridgeResult(out Task<Variant> task)
    {
        source = new();
        task = source.Task;
    }

    public void Finish(Variant result)
    {
        source.SetResult(result);
        Free();
    }

    public void finish(Variant t) => Finish(t);

    public void Throw(Variant e)
    {
        source.SetException(new Exception(e.ToString()));
        Free();
    }

    public void @throw(Variant e) => Throw(e);
} 