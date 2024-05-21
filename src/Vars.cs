using Godot;
using System;

public partial class Vars: Node
{
    public static readonly StringName SINGLETON_NAME = "Vars";

    public static SceneTree tree;

    public static CoreClass core;

    public static ObjectsManager objects;
    public static GameManager game;

    public override void _Ready()
    {
        tree = GetTree();

        core = Attach(new CoreClass());

        objects = Attach(new ObjectsManager());
        game = Attach(new GameManager());
    }

    public T Attach<T>(T obj) where T: Node
    {
        obj.Name = obj.GetType().Name;
        AddChild(obj);
        return obj;
    }

    public ObjectsManager Objects
    {
        get { return objects; }
    }

    public CoreClass Core
    {
        get { return core; }
    }

    public GameManager Game
    {
        get { return game; }
    }
}
