using Gindustry.Controllers;
using Gindustry.IO;
using Gindustry.Net;
using Gindustry.World;
using Godot;
using System;
using System.Collections.Generic;

namespace Gindustry.Game.Player;

[GlobalClass]
public partial class Player: Node
{
    public string PlayerName { get; set; }
    public int PlayerId { get; set; }
    public int PeerId { get; set; }
    public PeerData? Peer { get; set; } // server only
    public bool Online { get; set; }

    public LoadController LoadController { get; set; }

    public Dictionary<string, PlayerDataComponent>? DataComponents { get; set; } // server only

    public Player(int playerId)
    {
        PlayerId = playerId;
        Name = "Player#" + playerId;
        LoadController = new LoadController
        {
            Name = "LoadController"
        };
        AddChild(LoadController);
        SetMultiplayerAuthority(playerId);
    }

    public void ServerInitData(PeerData peer)
    {
        Peer = peer;
        DataComponents = new Dictionary<string, PlayerDataComponent>();
        foreach (var component in PlayerDataComponent.PlayerDataComponentInitList)
        {
            var dataComponent = component.Value();
            DataComponents[component.Key] = dataComponent;
            dataComponent.Name = component.Key;
            AddChild(dataComponent);
            dataComponent.InitData();
        }
    }
    public void ServerLoadData(PeerData peer, Reader r)
    {
        Peer = peer;
        LoadData(r);
    }
    public void LoadData(Reader r)
    {
        DataComponents = new Dictionary<string, PlayerDataComponent>();
        r.Iter(DataComponents, r => {
            var name = r.S();
            var dataComponent = PlayerDataComponent.PlayerDataComponentInitList[name]();
            DataComponents[name] = dataComponent;
            dataComponent.Name = name;
            AddChild(dataComponent);
            dataComponent.LoadData(r);
            return new KeyValuePair<string, PlayerDataComponent>(name, dataComponent);
        });
        foreach (var component in PlayerDataComponent.PlayerDataComponentInitList)
        {
            if (DataComponents.ContainsKey(component.Key))
                continue;
            var dataComponent = component.Value();
            DataComponents[component.Key] = dataComponent;
            dataComponent.Name = component.Key;
            AddChild(dataComponent);
            dataComponent.InitData();
        }
    }
    public void ServerSaveData(Writer w)
    {
        w.Iter(DataComponents, (w, kvp) => {
            w.S(kvp.Key);
            kvp.Value.SaveData(w);
        });
    }
    public void ClientSaveData(Writer w)
    {
        w.Iter(DataComponents, (w, kvp) => {
            w.S(kvp.Key);
            kvp.Value.SaveDataClient(w);
        });
    }
    public void DisposeData()
    {
        foreach (var component in DataComponents)
        {
            component.Value.DisposeData();
        }
    }
}
