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

    public List<ulong> Entities {get; set; } = new();

    public virtual void _LoadData(Reader r)
    {
        r.A(r => {
            var len = r.U32();
            for (int i = 0; i < len; i++)
            {
                Entities.Add(r.U64());
            }
        });
    }
    public virtual void _SaveData(Writer w)
    {
        w.A(w => {
            w.U32((uint)Entities.Count);
            foreach (var id in Entities)
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
}
