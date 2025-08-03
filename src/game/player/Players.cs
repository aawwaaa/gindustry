using System.Collections.Generic;
using Gindustry.Game.Player;
using Gindustry.IO;
using Gindustry.IO.Save;
using Gindustry.Net;
using Godot;

namespace Gindustry;
public partial class Vars {
    public partial class Vars_Players: SaveDataComponent {
        public int PlayerIncId = 1;
        public Dictionary<int, Player> Players { get; set; } = new();
        public HashSet<Player> OnlinePlayers { get; set; } = new();
        public Dictionary<string, int> TokenToPlayerId { get; set; } = new();

        [Rpc(MultiplayerApi.RpcMode.Authority, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable, CallLocal = true)]
        public void PlayerOnline(int id, string name, int peerId)
        {
            if (!this.Post([id, name, peerId]))
                return;
            if (Players.TryGetValue(id, out Player player)) 
            {
                player.Online = true;
                player.PeerId = peerId;
                player.PlayerName = name;
            }
            player = new Player(id) {
                Online = true,
                PeerId = peerId,
                PlayerName = name
            };
            AddChild(player);
            Players[id] = player;
            OnlinePlayers.Add(player);
        }
        [Rpc(MultiplayerApi.RpcMode.Authority, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable, CallLocal = true)]
        public void PlayerOffline(int id)
        {
            if (!this.Post([id]))
                return;
            if (Players.TryGetValue(id, out Player player))
            {
                player.Online = false;
                OnlinePlayers.Remove(player);
            }
        }

        public Player GetPlayer(int id)
        {
            if (Players.TryGetValue(id, out Player player))
                return player;
            return null;
        }
        public Godot.Collections.Array<Player> GetPlayers()
        {
            return [.. Players.Values];
        }

        public Player GetPlayerServer(string token)
        {
            if (!TokenToPlayerId.TryGetValue(token, out int id))
                id = PlayerIncId++;
            if (Players.TryGetValue(id, out Player player))
                return player;
            player = new Player(id);
            AddChild(player);
            Players[id] = player;
            TokenToPlayerId[token] = id;
            return player;
        }

        public override void InitData()
        {
            PlayerIncId = 1;
            Players = new Dictionary<int, Player>();
            TokenToPlayerId = new Dictionary<string, int>();
        }
        public override void LoadData(Reader r)
        {
            PlayerIncId = r.I32();
            Players.Clear();
            TokenToPlayerId.Clear();
            OnlinePlayers.Clear();
            r.Iter(Players, r => {
                var id = r.I32();
                var name = r.S();
                var player = new Player(id);
                player.LoadData(r);
                AddChild(player);
                return new KeyValuePair<int, Player>(id, player);
            });
            r.Iter(TokenToPlayerId, r => {
                var uuid = r.S();
                var id = r.I32();
                return new KeyValuePair<string, int>(uuid, id);
            });
        }
        public override void SaveData(Writer w)
        {
            w.I32(PlayerIncId);
            w.Iter(Players, (w, kvp) => {
                w.I32(kvp.Key);
                w.S(kvp.Value.PlayerName);
                kvp.Value.ServerSaveData(w);
            });
            w.Iter(TokenToPlayerId, (w, kvp) => {
                w.S(kvp.Key);
                w.I32(kvp.Value);
            });
        }
        public override void SaveDataClient(Writer w)
        {
            w.Iter(Players, (w, kvp) => {
                w.I32(kvp.Key);
                w.S(kvp.Value.PlayerName);
                kvp.Value.ClientSaveData(w);
            });
            // keep it blank
            w.Iter(new Dictionary<int, int>(), (w, t) => {});
        }
        public override void DisposeData()
        {
            foreach (var player in Players.Values)
            {
                player.DisposeData();
                player.QueueFree();
                Players.Remove(player.PlayerId);
            }
        }
    }
}