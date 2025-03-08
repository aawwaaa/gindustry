using Godot;
using System.Runtime.CompilerServices;
using System;

[GlobalClass]
public partial class NetLayer: Node
{
    public NetLayer()
    {
        if (Vars.Net != null) Vars.Net.QueueFree();
        Vars.Net = this;
        Vars.Instance.AddChild(this);
        this.Name = "NetLayer";
    }

    public virtual bool Post(Node RpcBase, string name, params Variant[] args)
    {
        return true;
    }

    public virtual void Sync(Node RpcBase, string name, params Variant[] args)
    {
        RpcBase.Call(name, args);
    }
    
    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
    public void RpcRefObject(ulong objectId, string name, Variant[] args)
    {
        Vars.Objects.GetObjectOrNull(objectId)?.Call(name, args);
    }
}

public static class NetLayerFuncs
{
    public static bool Post(this Node node, Variant[] args, [CallerMemberName] string name = "")
    {
        return Vars.Net.Post(node, name, args);
    }
    public static bool Post(this RefObject obj, Variant[] args, [CallerMemberName] string name = "")
    {
        var newArgs = new Variant[2 + args.Length];
        newArgs[0] = obj.objectId;
        newArgs[1] = name;
        Array.Copy(args, 0, newArgs, 2, args.Length);
        return Vars.Net.Post(Vars.Net, "RpcRefObject", newArgs);
    }

    public static void Sync(this Node node, string name, params Variant[] args)
    {
        Vars.Net.Sync(node, name, args);
    }

    public static void Sync(this RefObject obj, string name, params Variant[] args)
    {
        var newArgs = new Variant[2 + args.Length];
        newArgs[0] = obj.objectId;
        newArgs[1] = name;
        Array.Copy(args, 0, newArgs, 2, args.Length);
        Vars.Net.Sync(Vars.Net, "RpcRefObject", newArgs);
    }
}
