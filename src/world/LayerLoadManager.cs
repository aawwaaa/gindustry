using Godot;
using System;
using System.Collections.Generic;

namespace Gindustry.World;

[GlobalClass]
public partial class LayerLoadManager: GodotObject
{
    public const ulong REPEAT_REQUEST_TIMEOUT = 3000;
    
    [Signal]
    public delegate void ChunkAddEventHandler(Vector3I chunk);
    [Signal]
    public delegate void ChunkRemoveEventHandler(Vector3I chunk);

    public int layer;
    public LoadManager loadManager;
    
    public HashSet<Vector3I> Chunks = new();
    public Dictionary<Vector3I, ulong> ChunkRequestTimeout = new();

    public LayerLoadManager(int layer, LoadManager loadManager)
    {
        this.layer = layer;
        this.loadManager = loadManager;
    }

    public void Update()
    {
        HashSet<Vector3I> chunksNext = new();
        foreach(var controller in loadManager.Controllers)
        {
            if(controller.Dimension != loadManager.Dimension)
                continue;
            var section = controller.SectionFor(layer);
            chunksNext.UnionWith(section.Chunks);
        }
        HashSet<Vector3I> chunksToAdd = new(chunksNext);
        chunksToAdd.ExceptWith(Chunks);
        HashSet<Vector3I> chunksToRemove = new(Chunks);
        chunksToRemove.ExceptWith(chunksNext);
        foreach(var chunk in chunksToAdd)
        {
            if (ChunkRequestTimeout.TryGetValue(chunk, out var timeout) && Time.GetTicksMsec() - timeout < REPEAT_REQUEST_TIMEOUT)
            {
                continue;
            }
            EmitSignal(SignalName.ChunkAdd, chunk);
            ChunkRequestTimeout[chunk] = Time.GetTicksMsec();
        }
        foreach(var chunk in chunksToRemove)
        {
            if (ChunkRequestTimeout.TryGetValue(chunk, out var timeout) && Time.GetTicksMsec() - timeout < REPEAT_REQUEST_TIMEOUT)
            {
                continue;
            }
            EmitSignal(SignalName.ChunkRemove, chunk);
            ChunkRequestTimeout[chunk] = Time.GetTicksMsec();
        }
    }

    public void AddChunk(Vector3I chunk)
    {
        Chunks.Add(chunk);
        ChunkRequestTimeout.Remove(chunk);
    }
    public void RemoveChunk(Vector3I chunk)
    {
        Chunks.Remove(chunk);
        ChunkRequestTimeout.Remove(chunk);
    }

    public void Destroy()
    {
        Free();
    }
}
