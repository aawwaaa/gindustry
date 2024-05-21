using Godot;
using System;

public partial class Vars: Node
{
    public static SceneTree tree;

    public static Objects objects;

    public override void _Ready()
    {
        tree = GetTree();

        objects = new Objects();
    }
}
