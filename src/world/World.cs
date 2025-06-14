using Godot;
using System;
using System.Collections.Generic;

[GlobalClass]
public partial class World: GodotObject, Saveable
{
    public Dictionary<Vector3I, Chunk> chunks = new();

    public uint Id { get; set; }

    public Rid Scenario { get; private set; }
    public Rid Space { get; private set; }

    public World()
    {
        Scenario = RenderingServer.ScenarioCreate();
        Space = PhysicsServer3D.SpaceCreate();
    }

    public void _LoadData(Reader r) {
        r.A(r => {
            Id = r.U32();
        });
    }
    public void _SaveData(Writer w) {
        w.A(w => {
            w.U32(Id);
        });
    }

    public void ObjectFree()
    {
        foreach (var chunk in chunks.Values)
        {
            chunk.ObjectFree();
        }

        RenderingServer.FreeRid(Scenario);
        PhysicsServer3D.FreeRid(Space);
    }

    public Chunk LoadChunk(Vector3I position, Reader r)
    {
        var chunk = Chunk.LoadFrom(this, position, r);
        chunks.Add(chunk.Position, chunk);
        return chunk;
    }
    
    public Chunk GetChunk(Vector3I position) {
        if (chunks.TryGetValue(position, out var chunk))
            return chunk;
        return null;
    }
}
