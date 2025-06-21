using Gindustry.IO.Save;
using Gindustry.Net;
using Gindustry.Utils;
using Godot;
using System;

namespace Gindustry;

public partial class Vars
{
    [GlobalClass]
    public partial class Vars_Client: Node
    {
        public readonly ConfigKey<string> ConfigPlayerToken = new("client/player_token", "");
        public readonly ConfigKey<string> ConfigPlayerName = new("client/player_name", "player");

        [Signal]
        public delegate void SendJoinDataEventHandler();

        public Log.Logger logger = Log.RegisterLogger("Client");
        public Log.Logger messageLogger = Log.RegisterLogger("CM");
        public RemoteSaveDataLayer RemoteSaveDataLayer { get; set; }

        public enum ClientState
        {
            Idle,
            NetworkConnecting,
            WaitingServer,
            // login, hub, redirect, maintain info display, blacklisted display, etc.
            ServerInteract,
            Conntected
        }

        public StateMachineGeneric<ClientState> state = new(ClientState.Idle);
        public ClientState State
        {
            get => state.GetState();
            set => state.SetState(value);
        }

        public override void _Ready()
        {
            Multiplayer.ConnectedToServer += _OnConnectToServer;
            Multiplayer.ConnectionFailed += _OnConnectionFailed;
            Multiplayer.ServerDisconnected += _OnServerDisconnected;

            Reset();
        }

        public void Reset()
        {
            Vars.Net = new Net.DefaultNetLayer();
            if (GodotObject.IsInstanceValid(RemoteSaveDataLayer))
                RemoteSaveDataLayer.QueueFree();
            RemoteSaveDataLayer = new RemoteSaveDataLayer();
            RemoteSaveDataLayer.Name = "RemoteSaveDataLayer";
            AddChild(RemoteSaveDataLayer);
        }
        
        [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
        public void AddMessage(string message)
        {
            if (Vars.Headless.HeadlessClient)
                messageLogger.Info(message);
        }
        [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
        public void RequestInput()
        { }
        [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
        public void SetPromot(string promot)
        { }
        public void _OnMessageSubmit(string message)
        {
        }
        public void _OnMessageRequestAutoComplete(string message)
        {
        }

        public bool ClientActive => State != ClientState.Idle;

        public void RaiseError(string message)
        {
            logger.Error(message);
            AddMessage(message);
            Vars.Game.ResetToMenu();
        }

        public void ConnectTo(string host, int port)
        {
            Vars.Core.SetState(Vars.State.LoadingGame);
            State = ClientState.NetworkConnecting;
            var peer = new ENetMultiplayerPeer();
            var err = peer.CreateClient(host, port);
            if (err != Error.Ok)
            {
                RaiseError($"Failed to connect to {host}:{port} with error {err}");
                return;
            }
            Multiplayer.MultiplayerPeer = peer;
            logger.Info($"Connecting to {host}:{port}");
            Vars.Tree.CreateTimer(5.0, true, false, true).Timeout += () => 
            {
                if (State != ClientState.NetworkConnecting)
                    return;
                ConnectionRefused("Timeout");
            };
        }

        public void CallRemote(string name, params Variant[] args)
        {
            RpcId(1, name, args);
        }

        public void _OnConnectToServer()
        {
            State = ClientState.WaitingServer;
            CallRemote("PeerConnected",
                ConfigPlayerToken.V,
                ConfigPlayerName.V);
            EmitSignal(SignalName.SendJoinData);
        }
        public void _OnConnectionFailed()
        {
            RaiseError($"Connection failed");
        }
        public void _OnServerDisconnected()
        {
            RaiseError($"Server disconnected");
        }
        
        [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
        public void ConnectionRefused(string reason)
        {
            RaiseError($"Connection refused: {reason}");
        }
        [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
        public void RequestInteract()
        {
            State = ClientState.ServerInteract;
            logger.Info("Server required interact");
        }
        [Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = false)]
        public void AcceptConnection()
        {
            State = ClientState.Conntected;
            Vars.Game.SaveDataLayer = RemoteSaveDataLayer;
            Vars.Game.SaveDataLayer.RequestLoadGameMeta();
        }

        public void JoinLocal()
        {
        }
        public bool PostToServer(GodotObject obj, string name, params object[] args)
        {
            return true;
        }
    }
}
