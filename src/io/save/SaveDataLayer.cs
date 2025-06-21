using Godot;
using System;
using Gindustry.World;
using Gindustry.IO;

namespace Gindustry.IO.Save;

[GlobalClass]
public partial class SaveDataLayer: Node
{
    public static class ChainLoadMask
    {
        public const int MeshParent = 1 << 0;
        public const int MeshChunks = 1 << 1;
        public const int EntitiesInMeshChunks = 1 << 2;

        public const int Default = MeshParent;
        public const int All = (1 << 30) - 1;
    }
    
    public virtual void Close() {}

    public virtual void RequestLoadGameMeta() { }
  
    public virtual void RequestLoadDimension(uint dimension) {}
    // if return false: generate new one;
    public virtual bool RequestLoadChunk(uint dimension, Vector3I chunk) { return false; }
    public virtual void RequestLoadMesh(ulong mesh) { }
    public virtual void RequestLoadMeshChunk(ulong mesh, Vector3I chunk) { }

    public virtual void RequestSaveGameMeta() { }
    
    public virtual bool RequestSaveDimension(Dimension dimension) { return false; }
    // if return false: do not dispose
    public virtual bool RequestSaveChunk(Chunk chunk) { return false; }
    public virtual bool RequestSaveMesh(ulong mesh) { return false; }
    public virtual bool RequestSaveMeshChunk(ulong mesh, Vector3I chunk) { return false; }

    public virtual int GetChainLoadMask() => ChainLoadMask.Default;

    public virtual void SaveAll(){}

    protected static string PS (Vector3I pos) => $"{pos.X}_{pos.Y}_{pos.Z}";
}

public partial class MemorySaveDataLayer: SaveDataLayer
{ }

/*
    | save.bin
    | dimension
      | <dimension_id>
        | chunk
          | <chunk_pos>
    | entity_map
      | <entity_id_suffix(last 5 dight)>
    | mesh
      | <mesh_id>
        | mesh.bin
        | chunk
          | <chunk_pos>
*/
public partial class SaveFileSaveDataLayer: SaveDataLayer
{
    public SaveMeta meta;
    public string Path => meta.FilePath;

    public SaveFileSaveDataLayer(SaveMeta meta)
    {
        this.meta = meta;
    }

    public override void Close()
    { }

    public override void RequestLoadGameMeta()
    {
        var access = new GodotFileIO($"{Path}/save.bin", FileAccess.ModeFlags.Read);
        var reader = access.Reader();
        Vars.Game.LoadGameMeta(reader);
        access.Close();
    }

    public override void RequestLoadDimension(uint dimension)
    { }

    public override bool RequestLoadChunk(uint dimension, Vector3I chunk)
    {
        if (!FileAccess.FileExists($"{Path}/dimension/{dimension}/chunk/{PS(chunk)}")) return false;
        
        var access = new GodotFileIO($"{Path}/dimension/{dimension}/chunk/{PS(chunk)}", FileAccess.ModeFlags.Read);
        var reader = access.Reader();
        Vars.Dimensions.dimensions[dimension].LoadChunk(chunk, reader).ChainLoad(this);
        access.Close();
        return true;
    }

    public void MakeDir(string path)
    {
        if (DirAccess.DirExistsAbsolute(path)) return;
        DirAccess.MakeDirAbsolute(path);
    }

    public override void RequestSaveGameMeta()
    {
        MakeDir($"{Path}/");
        MakeDir($"{Path}/dimension/");

        var access = new GodotFileIO($"{Path}/save.bin", FileAccess.ModeFlags.Write);
        var writer = access.Writer();
        Vars.Game.SaveGameMeta(writer);
        access.Close();
    }

    public override bool RequestSaveDimension(Dimension dimension)
    {
        RequestSaveGameMeta();
        
        MakeDir($"{Path}/dimension/{dimension.Id}");
        MakeDir($"{Path}/dimension/{dimension.Id}/chunk/");
        return true;
    }

    public override bool RequestSaveChunk(Chunk chunk)
    {
        if (!FileAccess.FileExists($"{Path}/dimension/{chunk.Dimension}"))
            if (!RequestSaveDimension(chunk.Dimension)) return false;
        var access = new GodotFileIO($"{Path}/dimension/{chunk.Dimension.Id}/chunk/{PS(chunk.Position)}", FileAccess.ModeFlags.Write);
        var writer = access.Writer();
        chunk.SaveData(writer);
        access.Close();
        return true;
    }

    public override void SaveAll()
    {
        RequestSaveGameMeta();

        foreach (var dimension in Vars.Dimensions.dimensions.Values)
        {
            RequestSaveDimension(dimension);
            foreach (var chunk in dimension.chunks.Values)
            {
                RequestSaveChunk(chunk);
            }
        }
    }

    // It means all the calculation should be done in the local machine
    public override int GetChainLoadMask() => ChainLoadMask.All;
}

public partial class RemoteSaveDataLayer: SaveDataLayer
{
    public void RemoteData(params object[] args) {}
}
