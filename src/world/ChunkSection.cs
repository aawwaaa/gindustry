using System.Collections.Generic;
using Godot;

namespace Gindustry.World;

public struct ChunkSection
{
    public Vector3I Position;
    public Vector3I Size;
    public ChunkSection(Vector3I position, Vector3I size)
    {
        Position = position;
        Size = size;
    }
    public static ChunkSection CenterSize(Vector3I center, Vector3I size)
    {
        center -= size / 2;
        return new ChunkSection(center, size);
    }

    public readonly Vector3I Center => Position + Size / 2;

    public readonly HashSet<Vector3I> Chunks {
        get {
            HashSet<Vector3I> chunks = new();
            for(int x = Position.X; x < Position.X + Size.X; x++)
            {
                for(int y = Position.Y; y < Position.Y + Size.Y; y++)
                {
                    for(int z = Position.Z; z < Position.Z + Size.Z; z++)
                    {
                        chunks.Add(new Vector3I(x, y, z));
                    }
                }
            }
            return chunks;
        }
    }
}