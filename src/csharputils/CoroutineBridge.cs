using Godot;
using System;
using System.Threading.Tasks;

[GlobalClass]
public partial class CoroutineBridge: GodotObject
{
    private TaskCompletionSource source;

    public Task Task => source.Task;

    public CoroutineBridge(out Task task)
    {
        source = new TaskCompletionSource();
        task = source.Task;
    }

    public void Finish()
    {
        source.SetResult();
        Free();
    }

    public void finish() => Finish();

    public void Throw(Variant e)
    {
        source.SetException(new Exception(e.ToString()));
        Free();
    }

    public void @throw(Variant e) => Throw(e);
}

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
