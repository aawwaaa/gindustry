using Godot;
using Godot.Collections;
using System;

public partial class ModInfo: GodotObject
{
    public static readonly string ModInfoFileName = "info.json";

    public bool modLoaded = false;
    public Mod mod = null;

    public bool enabled = true;
    public string filePath;

    public string id;
    public string name;
    public string description = "none";
    public string author = "none";
    public Version version = new Version(1, 0, 0);
    public string repository = "none";
    public string iconPath = "";
    public Texture2D icon = null;
    public string main;
    public Script mainScript = null;
    public Dictionary metaData;

    public Godot.Collections.Array<ModDepend> depends = new Godot.Collections.Array<ModDepend>();
    public Godot.Collections.Array<ModReference> excepts = new Godot.Collections.Array<ModReference>();

    public Error LoadFromString(string text)
    {
        Json json = new Json();
        Error error = json.Parse(text);
        if(error != Error.Ok)
            return error;
        Dictionary data = (Dictionary)json.Data;
        if (!data.ContainsKey("id"))
            return Error.InvalidData;
        if (!data.ContainsKey("name"))
            return Error.InvalidData;
        if (!data.ContainsKey("main"))
            return Error.InvalidData;
        id = (string)data["id"];
        name = (string)data["name"];
        main = (string)data["main"];
        if (data.ContainsKey("description"))
            description = (string)data["description"];
        if (data.ContainsKey("author"))
            author = (string)data["author"];
        if (data.ContainsKey("version"))
            version = new Version((string)data["version"]);
        if (data.ContainsKey("repository"))
            repository = (string)data["repository"];
        if (data.ContainsKey("icon"))
            iconPath = (string)data["icon"];
        if (data.ContainsKey("metaData"))
            metaData = (Dictionary)data["metaData"];
        if (data.ContainsKey("depends"))
        {
            foreach (string depend in (Godot.Collections.Array)data["depends"])
            {
                depends.Add(new ModDepend(depend, (string)((Dictionary)data["depends"])[depend]));
            }
        }
        if (data.ContainsKey("excepts"))
        {
            foreach (string except in (Godot.Collections.Array)data["excepts"])
            {
                excepts.Add(new ModReference(except));
            }
        }
        return Error.Ok;
    }

    public Error ParseFromPckOrZip(string path)
    {
        ZipReader zip = new ZipReader();
        Error error = zip.Open(path);
        if(error != Error.Ok)
            return error;
        byte[] data = zip.ReadFile(ModInfoFileName);
        error = LoadFromString(data.GetStringFromUtf8());
        if(error != Error.Ok)
            return error;
        if (iconPath != "")
        {
            data = zip.ReadFile(iconPath);
            Image image = new Image();
            error = image.LoadPngFromBuffer(data);
            if (error != Error.Ok)
                return error;
            icon = ImageTexture.CreateFromImage(image);
        }
        zip.Close();
        return error;
    }
}

public partial class ModReference: GodotObject
{
    public string id;
    public ModInfo info = null;
    public ModReference(string id) {
        this.id = id;
        if (Vars.mods.mods.ContainsKey(id))
        {
            info = Vars.mods.mods[id];
        }else
        {
            ModsManager.ModInfoRegistedEventHandler handler = null;
            handler = (info) => 
            {
                if (info == null)
                {
                    Vars.mods.ModInfoRegisted -= handler;
                    return;
                }
                if (info.id != id)
                    return;
                this.info = info;
                Vars.mods.ModInfoRegisted -= handler;
            };
            Vars.mods.ModInfoRegisted += handler;
        }
    }
}

public partial class ModDepend: ModReference
{
    public ModDepend(string id, string version) : base(id) {
         string[] splited = version.Split('~');
         minVersion = new Version(splited[0]);
         if(splited.Length > 1)
             maxVersion = new Version(splited[1]);
         if(!version.EndsWith("+") && !version.Contains("~"))
             maxVersion = minVersion;
    }

    public Version minVersion = new Version(1, 0, 0);
    public Version maxVersion = null;
}
