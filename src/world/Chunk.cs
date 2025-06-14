using Godot;
using System.Collections.Generic;
using System;

[GlobalClass]
public partial class Chunk: GodotObject, Saveable
{
    public static Chunk LoadFrom(World world, Vector3I position, Reader r)
    {
        var chunk = new Chunk();
        chunk.World = world;
        chunk.Position = position;
        chunk._LoadData(r);
        return chunk;
    }

    public World World{get; set;}
    public Vector3I Position {get; set; }

    public HashSet<ulong> EntityIds {get; set; } = new();
    public HashSet<Entity> Entities {get; set; } = new();

    public virtual void _LoadData(Reader r)
    {
        r.A(r => {
            var len = r.U32();
            for (int i = 0; i < len; i++)
            {
                var id = r.U64();
                EntityIds.Add(id);
            }
        });
    }
    public virtual void _SaveData(Writer w)
    {
        w.A(w => {
            w.U32((uint)EntityIds.Count);
            foreach (var id in EntityIds)
            {
                w.U64(id);
            }
        });
    }
    public void SaveData(Writer w)
    {
        _SaveData(w);
    }

    public void ChainLoad(SaveDataLayer layer)
    {
        int mask = layer.GetChainLoadMask();
        if ((mask & SaveDataLayer.ChainLoadMask.MeshParent) == 0)
            return;
    }

    public void ObjectFree()
    {

    }

    public void AddEntity(Entity entity)
    {
        EntityIds.Add(entity.objectId);
        Entities.Add(entity);
    }

    public void RemoveEntity(Entity entity)
    {
        EntityIds.Remove(entity.objectId);
        Entities.Remove(entity);
    }
}
