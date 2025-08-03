using Godot;
using System;
using Gindustry.Attributes;
using System.Collections.Generic;
using Gindustry.CSharpUtils;

namespace Gindustry.Game.Player;

[GDScriptAdapterTarget("GA_PlayerDataComponent")]
[GlobalClass]
public partial class PlayerDataComponent: Node
{
    public static readonly Dictionary<string, Func<PlayerDataComponent>> PlayerDataComponentInitList = new();
    public static void RegisterPlayerDataComponentInitList<T>(Func<T> func) where T: PlayerDataComponent
    {
        PlayerDataComponentInitList.Add(typeof(T).Name, func);
    }
    public static void RegisterGDScriptComponentInitList(GDScript script)
    {
        PlayerDataComponentInitList.Add(script.GetGlobalName(), () => (PlayerDataComponent)script.New());
    }

    public static T GetPlayerDataComponent<T>(Player player) where T: PlayerDataComponent => player.DataComponents[typeof(T).Name] as T;

    public virtual void InitData()
    {
    }

    public virtual void LoadData(Gindustry.IO.Reader r)
    {
    }

    public virtual void SaveData(Gindustry.IO.Writer w)
    {
    }

    public virtual void SaveDataClient(Gindustry.IO.Writer w) => SaveData(w);

    public virtual void DisposeData()
    {
    }
}
