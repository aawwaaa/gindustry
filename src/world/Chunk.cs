using Godot;
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

    public virtual void _LoadData(Reader r)
    {

    }
    public virtual void _SaveData(Writer w)
    {

    }
    public void SaveData(Writer w)
    {
        _SaveData(w);
    }

    public void ChainLoad(SaveDataLayer layer)
    {

    }
}
