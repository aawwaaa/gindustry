using Godot;
using System;
using System.Collections.Generic;

public partial class Vars : Node
{
    public static Vars Instance { get; private set; }

    public List<GodotObject> varsObjects = new();

    // 静态变量
    public static Log.Logger Logger = Log.RegisterLogger("Vars");

    // 实例属性
    public Log.Logger logger => Logger;

    // 其他静态变量
    public static Node Main;
    public static SceneTree Tree;
    public static Vars_Core Core;
    public static Vars_Objects Objects;
    public static Vars_Configs Configs;
    public static Vars_Mods Mods;
    public static Vars_Types Types;
    public static GodotObject Contents;
    public static GodotObject Game;
    public static GodotObject Players;
    public static GodotObject Worlds;
    public static GodotObject Presets;
    public static GodotObject Saves;
    public static GodotObject Client;
    public static GodotObject Server;
    public static Vars_Headless Headless;
    public static GodotObject Input;
    public static GodotObject UI;

    // 实例属性
    public Node main => Main;
    public SceneTree tree => Tree;
    public Vars_Core core => Core;
    public Vars_Objects objects => Objects;
    public Vars_Configs configs => Configs;
    public Vars_Mods mods => Mods;
    public Vars_Types types => Types;
    public GodotObject contents => Contents;
    public GodotObject game => Game;
    public GodotObject players => Players;
    public GodotObject worlds => Worlds;
    public GodotObject presets => Presets;
    public GodotObject saves => Saves;
    public GodotObject client => Client;
    public GodotObject server => Server;
    public Vars_Headless headless => Headless;
    public GodotObject input => Input;
    public GodotObject ui => UI;

    public Vars()
    {
        Instance = this;
    }

    public override void _Ready()
    {
        Tree = GetTree();
    }
    
    private T Add<T>(T obj, string name) where T : GodotObject
    {
        if (obj is Node n)
        {
            n.Name = name;
            AddChild(n);
        }

        varsObjects.Add(obj);
        return obj;
    }

    private T LoadAdd<T>(string path, string name) where T : GodotObject
    {
        return Add((T)((GDScript)GD.Load(path)).New(), name);
    }

    public void Init()
    {
        Core = Add(new Vars_Core(), "Core");
        
        Objects = Add(new Vars_Objects(), "Objects");
        
        Configs = Add(new Vars_Configs(), "Configs");
        Mods = Add(new Vars_Mods(), "Mods");
        
        Types = Add(new Vars_Types(), "Types");
        Contents = LoadAdd<GodotObject>("res://src/content/contents.gd", "Contents");

        Game = LoadAdd<GodotObject>("res://src/game/game.gd", "Game");
        Players = LoadAdd<GodotObject>("res://src/game/player/players.gd", "Players");
        Worlds = LoadAdd<GodotObject>("res://src/world/worlds.gd", "Worlds");

        Presets = LoadAdd<GodotObject>("res://src/game/presets.gd", "Presets");
        Saves = LoadAdd<GodotObject>("res://src/game/saves.gd", "Saves");

        Client = LoadAdd<GodotObject>("res://src/net/client.gd", "Client");
        Server = LoadAdd<GodotObject>("res://src/net/server.gd", "Server");
        
        Headless = Add(new Vars_Headless(), "Headless");
        Input = LoadAdd<GodotObject>("res://src/input/input.gd", "Input");
        UI = LoadAdd<GodotObject>("res://ui/ui.gd", "UI");
    }
}
