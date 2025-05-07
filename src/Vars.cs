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
    public static Vars_Contents Contents;
    public static Vars_Game Game;
    // public static GodotObject Players;
    public static Vars_Worlds Worlds => SaveDataComponent.GetSaveDataComponent<Vars_Worlds>();
    public static Vars_Presets Presets;
    public static Vars_Saves Saves;
    public static NetLayer Net;
    public static Vars_Client Client;
    public static Vars_Server Server;
    public static Vars_Headless Headless;
    // public static GodotObject Input;
    // public static GodotObject UI;

    // 实例属性
    public Node main => Main;
    public SceneTree tree => Tree;
    public Vars_Core core => Core;
    public Vars_Objects objects => Objects;
    public Vars_Configs configs => Configs;
    public Vars_Mods mods => Mods;
    public Vars_Types types => Types;
    public Vars_Contents contents => Contents;
    public Vars_Game game => Game;
    // public GodotObject players => Players;
    public Vars_Worlds worlds => SaveDataComponent.GetSaveDataComponent<Vars_Worlds>();
    public Vars_Presets presets => Presets;
    public GodotObject saves => Saves;
    public NetLayer net => Net;
    public Vars_Client client => Client;
    public Vars_Server server => Server;
    public Vars_Headless headless => Headless;
    // public GodotObject input => Input;
    // public GodotObject ui => UI;

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
        Contents = Add(new Vars_Contents(), "Contents");
        
        Game = Add(new Vars_Game(), "Game");
        // Players = LoadAdd<GodotObject>("res://src/game/player/players.gd", "Players");
        SaveDataComponent.RegisterSaveDataComponentInitList(() => new Vars_Worlds());
        
        Presets = Add(new Vars_Presets(), "Presets");
        Saves = Add(new Vars_Saves(), "Saves");
        
        Client = Add(new Vars_Client(), "Client");
        Server = Add(new Vars_Server(), "Server");
        
        Headless = Add(new Vars_Headless(), "Headless");
        // Input = LoadAdd<GodotObject>("res://src/input/input.gd", "Input");
        // UI = LoadAdd<GodotObject>("res://ui/ui.gd", "UI");
    }
}
