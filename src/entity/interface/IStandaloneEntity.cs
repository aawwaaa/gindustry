using Godot;
using System;
using System.Collections.Generic;

public interface IStandaloneEntity
{
    public World World{get; set;}
    public Vector3 Position{get; set;}

    protected HashSet<Vector3I> IStandaloneEntity_HistoryChunks {get; set;}
    protected HashSet<Vector3I> IStandaloneEntity_RemovedChunks {get; set;}
    public HashSet<Vector3I> IStandaloneEntity_AddedChunks {get; set;}
    public HashSet<Vector3I> IStandaloneEntity_CurrentChunks {get; set;}
    public bool IStandaloneEntity_ChunksUpdated {get; set;}

    protected abstract void UpdateChunks();

    public void ChunkUpdateBegin() {
        IStandaloneEntity_CurrentChunks.Clear();
        IStandaloneEntity_RemovedChunks.Clear();
        IStandaloneEntity_RemovedChunks.UnionWith(IStandaloneEntity_HistoryChunks);
        IStandaloneEntity_AddedChunks.Clear();
    }
    public void ChunkUpdateEnd() {
        IStandaloneEntity_HistoryChunks.Clear();
        IStandaloneEntity_HistoryChunks.UnionWith(IStandaloneEntity_CurrentChunks);
        IStandaloneEntity_ChunksUpdated = true;
    }
    public void ChunkUpdateSet(Vector3I chunk) {
        if (IStandaloneEntity_CurrentChunks.Contains(chunk))
            return;
        IStandaloneEntity_CurrentChunks.Add(chunk);
        if (IStandaloneEntity_RemovedChunks.Contains(chunk))
            IStandaloneEntity_RemovedChunks.Remove(chunk);
        if (!IStandaloneEntity_HistoryChunks.Contains(chunk))
            IStandaloneEntity_AddedChunks.Add(chunk);
    }
    public void ChunkUpdateClear(Vector3I chunk) {
        if (!IStandaloneEntity_CurrentChunks.Contains(chunk))
            return;
        IStandaloneEntity_CurrentChunks.Remove(chunk);
        IStandaloneEntity_AddedChunks.Remove(chunk);
    }
    public void ChunkUpdateInit() {
        IStandaloneEntity_HistoryChunks = new();
        IStandaloneEntity_RemovedChunks = new();
        IStandaloneEntity_AddedChunks = new();
        IStandaloneEntity_CurrentChunks = new();
        IStandaloneEntity_ChunksUpdated = false;
    }

    public void IStandaloneEntity_ApplyChunkUpdates() {
        UpdateChunks();
        if (!IStandaloneEntity_ChunksUpdated) return;
        foreach (var chunkPos in IStandaloneEntity_RemovedChunks)
        {
            var chunk = World.GetChunk(chunkPos);
            if (chunk != null)
                chunk.RemoveEntity(this as Entity);
            // maybe it's buggy
        }
        foreach (var chunkPos in IStandaloneEntity_AddedChunks)
        {
            var chunk = World.GetChunk(chunkPos);
            if (chunk != null)
                chunk.AddEntity(this as Entity);
            else
                IStandaloneEntity_HistoryChunks.Remove(chunkPos);
        }
        IStandaloneEntity_ChunksUpdated = false;
    }
}
