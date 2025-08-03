using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Gindustry.Net;
using Gindustry.Game.Player;
using Gindustry.CSharpUtils;
using Gindustry.Utils;

namespace Gindustry;

public static class MultiplayerApiExtensions
{
    public static PeerData PeerData(this MultiplayerApi api)
    {
        var peerId = api.GetRemoteSenderId();
        return Vars.Server.PeerDataFor(peerId);
    }

    public static bool IsCallerHasPermission(this MultiplayerApi api, string permission)
    {
        var peerData = api.PeerData();
        if (peerData == null) return true; // Local call or invalid peer

        return Vars.Server.AnyManager(manager =>
        {
            var permResult = manager._HasPermission(peerData, permission);
            return permResult;
        }, result => result != ServerManager.PermissionResult.Ignore)
            == ServerManager.PermissionResult.Allow;
    }
}

public partial class Vars
{
    [GlobalClass]
    public partial class Vars_Server: Node
    {
        public ServerState state;
        public enum ServerState
        {
            Idle,
            Creating,
            Running,
        }

        private const double PEER_WAIT_TIMEOUT = 30.0;
        public static ConfigKey<int> ConfigMaxClients = new("server/max_clients", 32);
        
        public List<ServerManager> managers = new();
        private Dictionary<long, PeerData> peerDataDict = new();
        private Log.Logger logger = Log.RegisterLogger("Server");

        public override void _Ready()
        {
            Multiplayer.PeerConnected += _OnPeerConnected;
            Multiplayer.PeerDisconnected += _OnPeerDisconnected;
        }

        public void RegisterServerManager(ServerManager manager)
        {
            AddChild(manager);
            managers.Add(manager);
            // Sort by priority (higher priority first)
            managers = managers.OrderByDescending(m => m._Priority).ToList();
        }

        private void EachManager(Action<ServerManager> action)
        {
            foreach (var manager in managers)
            {
                action(manager);
            }
        }

        private async Task EachManager(Func<ServerManager, Task> func)
        {
            foreach (var manager in managers)
            {
                await func(manager);
            }
        }

        private bool EveryManager(Func<ServerManager, bool> func)
        {
            foreach (var manager in managers)
            {
                if (!func(manager))
                    return false;
            }
            return true;
        }

        public T AnyManager<T>(Func<ServerManager, T?> func, Func<T?, bool> check = null)
        {
            foreach (var manager in managers)
            {
                var result = func(manager);
                if ((check == null && result != null) || (check != null && check(result)))
                    return result;
            }
            return default;
        }

        public PeerData PeerDataFor(Player player)
        {
            return peerDataDict.Values.FirstOrDefault(p => p.player == player);
        }

        public PeerData PeerDataFor(long peerId)
        {
            return peerDataDict.GetValueOrDefault(peerId);
        }

        public void _OnPeerConnected(long id)
        {
            var peerData = new PeerData("", "", id);
            peerDataDict[id] = peerData;
            
            // Set timeout for connection
            Vars.Tree.CreateTimer(PEER_WAIT_TIMEOUT, true, false, true).Timeout += () =>
            {
                var peer = PeerDataFor(id);
                if (peer != null && peer.state == PeerState.Idle)
                {
                    logger.Info($"Peer {id} connection timeout");
                    Multiplayer.MultiplayerPeer.DisconnectPeer((int)id);
                }
            };
        }
        public void CreatePeerForLocal()
        {
            var peerData = new PeerData("", "[LOCAL]", 0);
            peerDataDict[0] = peerData;
        }

        public void _OnPeerDisconnected(long id)
        {
            var peerData = PeerDataFor(id);
            if (peerData != null)
            {
                if (peerData.player != null)
                {
                    Vars.Players.Rpc(Vars_Players.MethodName.PlayerOffline, peerData.player.PlayerId);
                    logger.Info($"Player left: {peerData.name} [{peerData.token}]");
                    SendMessageToAll($"@Server_PlayerLeft\xA7{peerData.player.PlayerName}");
                }
                
                EachManager(m => m._PeerDisconnect(peerData));
                peerDataDict.Remove(id);
            }
        }

        [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false)]
        public void PeerConnected(string name, string token)
        {
            var peerData = Multiplayer.PeerData();
            peerData.name = name;
            peerData.token = token;
            
            // Check if all data received
            if (AllDataReceived(peerData))
            {
                ProcessConnection(peerData);
            }
        }

        [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false)]
        public void PeerData(string type, byte[] data)
        {
            var peerData = Multiplayer.PeerData();
            peerData.data[type] = data;
            
            // Send to all managers
            EachManager(m => m._PeerData(peerData, type, data));
            
            // Check if all data received
            if (AllDataReceived(peerData))
            {
                ProcessConnection(peerData);
            }
        }

        private bool AllDataReceived(PeerData peer)
        {
            return EveryManager(m => m._DataReceived(peer));
        }

        private async void ProcessConnection(PeerData peer)
        {
            if (peer.state != PeerState.Idle)
                return;

            peer.SetState(PeerState.Connecting);
            logger.Info($"Connecting: {peer.name} [{peer.token}]", "Connecting");

            try
            {
                await EachManager(async m =>
                {
                    var bridge = new CoroutineBridge(out var task);
                    m._PeerConnect(peer, bridge);
                    await task;
                    
                    if (peer.state == PeerState.Refused)
                        return; // Connection refused, stop processing
                });

                if (peer.state == PeerState.Refused)
                    return;

                var player = Vars.Players.GetPlayerServer(peer.token);
                peer.player = player;
                Vars.Players.Rpc(Vars_Players.MethodName.PlayerOnline, player.PlayerId, player.PlayerName, peer.peerId);
                peer.AcceptConnection(player.PlayerId);
            }
            catch (Exception e)
            {
                logger.Error($"Error processing connection for {peer.name}: {e.Message}");
                peer.Refuse($"Server error: {e.Message}");
            }
        }

        [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false)]
        public void ReadyToJoin()
        {
            var peerData = Multiplayer.PeerData();
            logger.Info($"Player joined: {peerData.name} [{peerData.token}]");
            EachManager(m => m._PlayerJoin(peerData));
            SendMessageToAll($"@Server_PlayerJoined\xA7{peerData.player.PlayerName}");
        }

        public void SendMessageToAll(string message)
        {
            foreach(var peer in peerDataDict.Values){
                if (peer.state == PeerState.Connected)
                    peer.AddMessage(message);
            }
        }

        [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false)]
        public void MessageSubmit(string message)
        {
            var peerData = Multiplayer.PeerData();
            
            // Handle input request
            if (peerData.requestInputSource != null)
            {
                peerData.requestInputSource.SetResult(message);
                peerData.requestInputSource = null;
                return;
            }

            // Try any manager to handle message
            if (AnyManager(manager => manager._HandleMessage(peerData, message), result => result))
                return;

            SendMessageToAll($"@Server_Chat\xA7{peerData.player.PlayerName}\xA7{message}");
            logger.Info($"[CHAT] {peerData.player.PlayerName}: {message}");
        }

        public void CreateServer(int port)
        {
            state = ServerState.Creating;
            EachManager(m => m._ServerCreated());
            var peer = new ENetMultiplayerPeer();
            var error = peer.CreateServer(port, ConfigMaxClients);
            if (error != Error.Ok)
            {
                throw new Exception($"Failed to create server: {error}");
            }
            Multiplayer.MultiplayerPeer = peer;
            state = ServerState.Running;
        }

        public void Reset()
        {
            state = ServerState.Idle;
            EachManager(m => m._ServerReset());
            
            // Clear all peer data
            foreach (var peerData in peerDataDict.Values)
            {
                EachManager(m => m._PlayerLeave(peerData));
            }
            peerDataDict.Clear();
            
            // Clean up multiplayer peer to prevent port conflicts
            if (Multiplayer.MultiplayerPeer != null)
            {
                Multiplayer.MultiplayerPeer.Close();
                Multiplayer.MultiplayerPeer = null;
            }
        }
    }
}
