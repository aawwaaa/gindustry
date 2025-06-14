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

    public virtual bool Post(Node rpcBase, string name, params Variant[] args)
    {
        return true;
    }

    public virtual void Sync(Node rpcBase, string name, params Variant[] args)
    {
        rpcBase.Call(name, args);
    }
    
    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
    public void RpcNode(NodePath node, string name, byte[] data)
    {
        if (!name.StartsWith("rpc")) return;
        var args = Utils.Serialization.UnserializeFromBuffer<Variant[]>(data);
        Vars.Tree.Root.GetNodeOrNull(node)?.Call(name, args);
    }
    [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
    public void RpcRefObject(ulong objectId, string name, byte[] data)
    {
        if (!name.StartsWith("rpc")) return;
        var args = Utils.Serialization.UnserializeFromBuffer<Variant[]>(data);
        Vars.Objects.GetObjectOrNull(objectId)?.Call(name, args);
    }
}

public partial class DefaultNetLayer: NetLayer
{}

public partial class ClientNetLayer: NetLayer
{
    public override void Sync(Node rpcBase, string name, params Variant[] args) { }
}

public static class NetLayerFuncs
{
    public static void RpcS(this Node node, string name, params Variant[] args)
        => Vars.Net.Rpc("RpcNode", node, name, Utils.Serialization.SerializeAsBuffer(args));
    public static void RpcIdS(this Node node, long id, string name, params Variant[] args)
        => Vars.Net.RpcId(id, "RpcNode", node, name, Utils.Serialization.SerializeAsBuffer(args));
    public static void RpcS(this RefObject obj, string name, params Variant[] args)
        => Vars.Net.Rpc("RpcRefObject", obj.objectId, name, Utils.Serialization.SerializeAsBuffer(args));
    public static void RpcIdS(this RefObject obj, long id, string name, params Variant[] args)
        => Vars.Net.RpcId(id, "RpcRefObject", obj.objectId, name, Utils.Serialization.SerializeAsBuffer(args));
    public static long RpcCaller(this Node node) => node.Multiplayer.GetRemoteSenderId();
    public static long RpcCaller(this RefObject obj) => Vars.Net.Multiplayer.GetRemoteSenderId();

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
