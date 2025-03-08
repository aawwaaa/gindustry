using Godot;
using System.Collections.Generic;

[GlobalClass]
public partial class ModInfo : Resource
{
    public struct ModRef
    {
        public string Id = "";
        public string Min = "";
        public string Max = "none";
        public ModRef(){ }

        public string RefString => $"{Id} [{Min}{(Max != "none"? " ~ " + Max: "+")}]";

        public static explicit operator ModRef(ModInfo info) => new ModRef
        {
            Id = info.Id,
            Min = info.Version
        };
    }

    public string RefString => $"{Id} ({Name}) [{Version}]({DisplayVersion})";

    [Export]
    public string Id { get; set; }
    [Export]
    public string Name { get; set; } = "unnamed";
    [Export]
    public string Description { get; set; } = "no_description";
    [Export]
    public string Author { get; set; } = "unknown";
    [Export]
    public string Repo { get; set; } = "no_repo";
    [Export]
    public string Version { get; set; } = "1.0.0";
    [Export]
    public string DisplayVersion { get; set; } = "unmarked";
    /// <summary>
    /// Dictionary of dependencies in the format {"id": [min, max?]}
    /// </summary>
    [Export]
    public Dictionary<string, ModRef> Depends { get; set; } = new ();

    [Export]
    public Dictionary<string, ModRef> Excepts { get; set; } = new ();

    [Export]
    public Texture2D Icon { get; set; } = ResourceLoader.Load<Texture2D>("res://assets/asset-not-found.png");

    [Export]
    public string Main { get; set; } = "/scripts/main.gd";

    public bool Enabled { get; set; } = false;
    public string FilePath { get; set; } = "";
    public string Root { get; set; } = "";
    public bool Folder { get; set; } = false;

    /// <summary>
    /// Loads a ModInfo from a .zip file.
    /// </summary>
    /// <param name="path">Path to the .zip file.</param>
    /// <returns>ModInfo instance or null if loading fails.</returns>
    public static ModInfo LoadFromFile(string path)
    {
        var reader = new ZipReader();
        if (reader.Open(path) != Error.Ok)
        {
            reader.Close();
            return null;
        }

        if (!reader.FileExists("info.json"))
        {
            reader.Close();
            return null;
        }

        var infoData = System.Text.Encoding.UTF8.GetString(reader.ReadFile("info.json"));
        var infoDict = (Godot.Collections.Dictionary)Json.ParseString(infoData);
        var info = ParseInfoDict(infoDict);

        if (info != null && infoDict.ContainsKey("icon") && infoDict.ContainsKey("iconType"))
        {
            var iconData = reader.ReadFile((string)infoDict["icon"]);
            info.Icon = Utils.ParseImageData(iconData, (string)infoDict["iconType"]);
        }

        reader.Close();
        info.FilePath = path;
        info.Root = "res://mods/" + info.Id;
        return info;
    }

    /// <summary>
    /// Loads a ModInfo from a folder.
    /// </summary>
    /// <param name="path">Path to the folder.</param>
    /// <returns>ModInfo instance or null if loading fails.</returns>
    public static ModInfo LoadFromFolder(string path)
    {
        if (!FileAccess.FileExists(path + "/info.json"))
        {
            return null;
        }

        using var infoAccess = FileAccess.Open(path + "/info.json", FileAccess.ModeFlags.Read);
        var infoData = infoAccess.GetAsText();
        var infoDict = (Godot.Collections.Dictionary)Json.ParseString(infoData);
        var info = ParseInfoDict(infoDict);

        if (info != null && infoDict.ContainsKey("icon") && infoDict.ContainsKey("iconType"))
        {
            var fullPath = path + "/" + (string)infoDict["icon"];
            if (path.StartsWith("res://"))
            {
                info.Icon = ResourceLoader.Load<Texture2D>(fullPath);
            }
            else
            {
                var image = Image.LoadFromFile(fullPath);
                info.Icon = ImageTexture.CreateFromImage(image);
            }
        }

        info.Root = path;
        info.Folder = true;
        return info;
    }

    /// <summary>
    /// Parses a dictionary into a ModInfo instance.
    /// </summary>
    /// <param name="dict">Dictionary containing mod info.</param>
    /// <returns>ModInfo instance or null if parsing fails.</returns>
    public static ModInfo ParseInfoDict(Godot.Collections.Dictionary dict)
    {
        if (!dict.ContainsKey("id"))
            return null;

        var info = new ModInfo
        {
            Id = (string)dict["id"]
        };

        if (dict.ContainsKey("name"))
            info.Name = (string)dict["name"];
        else
            info.Name = info.Id;

        if (dict.ContainsKey("description"))
            info.Description = (string)dict["description"];
        if (dict.ContainsKey("author"))
            info.Author = (string)dict["author"];
        if (dict.ContainsKey("repo"))
            info.Repo = (string)dict["repo"];

        if (dict.ContainsKey("version"))
            info.Version = (string)dict["version"];
        if (dict.ContainsKey("displayVersion"))
            info.DisplayVersion = (string)dict["displayVersion"];

        if (dict.ContainsKey("depends"))
        {
            var dependsDict = (Godot.Collections.Dictionary)dict["depends"];
            foreach (var key in dependsDict.Keys)
            {
                var depId = (string)key;
                var depValue = (string)dependsDict[key];
                if (depValue.EndsWith("+"))
                    info.Depends[depId] = new ModRef
                    {
                        Id = depId, Min = depValue.TrimEnd('+')
                    };
                else
                {
                    var split = depValue.Split('~');
                    info.Depends[depId] = new ModRef
                    {
                        Id = depId, Min = split[0], Max = split[1]
                    };
                }
            }
        }

        if (dict.ContainsKey("excepts"))
            foreach(var id in (string[])dict["excepts"])
                info.Excepts[id] = new ModRef
                {
                    Id = id,
                    Min = "0.0.0"
                };

        if (dict.ContainsKey("main"))
            info.Main = (string)dict["main"];

        return info;
    }
}
