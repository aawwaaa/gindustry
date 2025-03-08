using Godot;
using System;

[GlobalClass]
public partial class SaveDataLayer: RefCounted
{
    public virtual void Close() {}

    public virtual void RequestLoadGameMeta() { }
  
    public virtual void RequestLoadWorld(uint world) {}
    // if return false: generate new one;
    public virtual bool RequestLoadChunk(uint world, Vector3I chunk) { return false; }
    public virtual void RequestLoadMesh(ulong mesh) { }
    public virtual void RequestLoadMeshChunk(ulong mesh, Vector3I chunk) { }

    public virtual void RequestSaveGameMeta() { }
    
    public virtual bool RequestSaveWorld(World world) { return false; }
    // if return false: do not dispose
    public virtual bool RequestSaveChunk(Chunk chunk) { return false; }
    public virtual bool RequestSaveMesh(ulong mesh) { return false; }
    public virtual bool RequestSaveMeshChunk(ulong mesh, Vector3I chunk) { return false; }

    public virtual void SaveAll(){}

    protected static string PS (Vector3I pos) => $"{pos.X}_{pos.Y}_{pos.Z}";
}

public partial class MemorySaveDataLayer: SaveDataLayer
{ }

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

    public override void RequestLoadWorld(uint world)
    { }

    public override bool RequestLoadChunk(uint world, Vector3I chunk)
    {
        if (!FileAccess.FileExists($"{Path}/world/{world}/chunk/{PS(chunk)}")) return false;
        
        var access = new GodotFileIO($"{Path}/world/{world}/chunk/{PS(chunk)}", FileAccess.ModeFlags.Read);
        var reader = access.Reader();
        Vars.Worlds.worlds[world].LoadChunk(chunk, reader).ChainLoad(this);
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
        MakeDir($"{Path}/world/");

        var access = new GodotFileIO($"{Path}/save.bin", FileAccess.ModeFlags.Write);
        var writer = access.Writer();
        Vars.Game.SaveGameMeta(writer);
        access.Close();
    }

    public override bool RequestSaveWorld(World world)
    {
        RequestSaveGameMeta();
        
        MakeDir($"{Path}/world/{world.Id}");
        MakeDir($"{Path}/world/{world.Id}/chunk/");
        return true;
    }

    public override bool RequestSaveChunk(Chunk chunk)
    {
        if (!FileAccess.FileExists($"{Path}/world/{chunk.World}"))
            if (!RequestSaveWorld(chunk.World)) return false;
        var access = new GodotFileIO($"{Path}/world/{chunk.World.Id}/chunk/{PS(chunk.Position)}", FileAccess.ModeFlags.Write);
        var writer = access.Writer();
        chunk.SaveData(writer);
        access.Close();
        return true;
    }

    public override void SaveAll()
    {
        RequestSaveGameMeta();

        foreach (var world in Vars.Worlds.worlds.Values)
        {
            RequestSaveWorld(world);
            foreach (var chunk in world.chunks.Values)
            {
                RequestSaveChunk(chunk);
            }
        }
    }
}

public partial class RemoteSaveDataLayer: SaveDataLayer
{ }
