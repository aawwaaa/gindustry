using Godot;
using Godot.Collections;
using System;

public partial class ModsManager: Node
{
    [Signal]
    public delegate void ModInfoRegistedEventHandler(ModInfo info);

    public Dictionary<string, ModInfo> mods = new Dictionary<string, ModInfo>();
    public ModInfo currentLoadingMod;
}
