using System;
using System.Collections.Generic;
using Gindustry.Entities;
using Gindustry.Net;
using Godot;

namespace Gindustry.World;

[GlobalClass]
public partial class LoadController: Node
{
    public enum ChunkLoadLevelClient {
        None = 0,
        Placeholder = 20,
        Full = 70,
    }
    public enum ChunkLoadLevelServer {
        None = 0,
        ServerEmpty = 5,
        Placeholder = 15,
        Full = 60,
    }
    public const int LoadDistance = 100;

    public ulong AnchorEntityId { get; set; }
    public Entity AnchorEntity => Vars.Objects.GetObjectOrNull(AnchorEntityId) as Entity;
    public Vector3 Offset { get; set; }
    public Dimension Dimension => AnchorEntity.Dim;
    public bool WorldMetaSent { get; set; }

    [Rpc(MultiplayerApi.RpcMode.Authority, TransferMode = MultiplayerPeer.TransferModeEnum.UnreliableOrdered, CallLocal = true)]
    public void Sync(ulong anchorEntityId, Vector3 offset, Vector3I range)
    {
        if (!this.Post([anchorEntityId, offset, range]))
            return;
        AnchorEntityId = anchorEntityId;
        Offset = offset;
    }

    public Vector3I CenterChunk => Chunk.ChunkPosition(AnchorEntity.Position + Offset);
    
    public ChunkSection SectionFor(int level)
    {
        int distance = LoadDistance - level;
        return ChunkSection.CenterSize(CenterChunk, Vector3I.One * distance);
    }
}