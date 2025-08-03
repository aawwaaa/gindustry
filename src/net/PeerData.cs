using System.Threading.Tasks;
using Gindustry.CSharpUtils;
using Gindustry.Game.Player;
using Godot;
using Godot.Collections;

namespace Gindustry.Net;
public enum PeerState
{
    Idle,
    Connecting,
    Interact,
    Connected,
    Refused
}
[GlobalClass]
public partial class PeerData: RefCounted
{
    public string name;
    public string token;

    public long peerId; // 0 means local player
    public PeerState state;

    public Player player;
    public Dictionary<string, Variant> data = new();

    public PeerData(string name, string token, long peerId)
    {
        this.name = name;
        this.token = token;
        this.peerId = peerId;
        state = PeerState.Idle;
    }

    public void SetState(PeerState state)
    {
        this.state = state;
    }

    public void CallRemote(string name, params Variant[] args)
    {
        if (peerId == 0) Vars.Client.Call(name, args);
        else Vars.Client.RpcId(peerId, name, args);
    }

    public void AddMessage(string message)
    {
        CallRemote("AddMessage", message);
    }

    public void Refuse(string reason)
    {
        SetState(PeerState.Refused);
        CallRemote("ConnectionRefused", reason);
    }

    public void RequestInteract()
    {
        SetState(PeerState.Interact);
        CallRemote("RequestInteract");
    }

    public void AcceptConnection(int playerId)
    {
        SetState(PeerState.Connected);
        CallRemote("AcceptConnection", playerId);
    }

    public TaskCompletionSource<string>? requestInputSource;
    public Task<string> RequestInput(string prompt = "")
    {
        CallRemote("SetPrompt", prompt);
        CallRemote("RequestInput");
        requestInputSource = new TaskCompletionSource<string>();
        return requestInputSource.Task;
    }
}