using Gindustry.Attributes;
using Godot;
using System;
using System.Collections.Generic;

namespace Gindustry.Entities.Type.Base;

[GDScriptAdapterTarget("GA_StandaloneEntity")]
[GlobalClass]
public partial class StandaloneEntity : Entity
{
    private HashSet<Vector3I> historyChunks = [];
    private HashSet<Vector3I> removedChunks = [];
    private HashSet<Vector3I> addedChunks = [];
    private HashSet<Vector3I> currentChunks = [];
    private bool chunksUpdated = false;

    protected virtual void UpdateChunks() {
        throw new NotImplementedException();
    }

    protected void ChunkUpdateBegin()
    {
        currentChunks.Clear();
        removedChunks.Clear();
        removedChunks.UnionWith(historyChunks);
        addedChunks.Clear();
    }

    protected void ChunkUpdateEnd()
    {
        historyChunks.Clear();
        historyChunks.UnionWith(currentChunks);
        chunksUpdated = true;
    }

    protected void ChunkUpdateSet(Vector3I chunk)
    {
        if (currentChunks.Contains(chunk))
            return;
        currentChunks.Add(chunk);
        if (removedChunks.Contains(chunk))
            removedChunks.Remove(chunk);
        if (!historyChunks.Contains(chunk))
            addedChunks.Add(chunk);
    }

    protected void ChunkUpdateClear(Vector3I chunk)
    {
        if (!currentChunks.Contains(chunk))
            return;
        currentChunks.Remove(chunk);
        addedChunks.Remove(chunk);
    }

    public void ChunkUpdateInit()
    {
        historyChunks = [];
        removedChunks = [];
        addedChunks = [];
        currentChunks = [];
        chunksUpdated = false;
    }

    public void ApplyChunkUpdates()
    {
        UpdateChunks();
        if (!chunksUpdated) return;
        foreach (var chunkPos in removedChunks)
        {
            var chunk = Dim?.GetChunk(chunkPos);
            if (chunk != null)
                chunk.RemoveEntity(this);
            // maybe it's buggy
        }
        foreach (var chunkPos in addedChunks)
        {
            var chunk = Dim?.GetChunk(chunkPos);
            if (chunk != null)
                chunk.AddEntity(this);
            else
                historyChunks.Remove(chunkPos);
        }
        chunksUpdated = false;
    }
}