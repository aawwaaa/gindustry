using Godot;
using System;
using Gindustry.Attributes;
using System.Collections.Generic;
using Gindustry.CSharpUtils;

namespace Gindustry.IO.Save;

[GDScriptAdapterTarget("GA_SaveDataComponent")]
[GlobalClass]
public partial class SaveDataComponent: Node
{
    public static readonly Dictionary<string, Func<SaveDataComponent>> SaveDataComponentInitList = new();
    public static void RegisterSaveDataComponentInitList<T>(Func<T> func) where T: SaveDataComponent
    {
        SaveDataComponentInitList.Add(typeof(T).Name, func);
    }
    public static void RegisterGDScriptComponentInitList(GDScript script)
    {
        SaveDataComponentInitList.Add(script.GetGlobalName(), () => (SaveDataComponent)script.New());
    }

    public static T GetSaveDataComponent<T>() where T: SaveDataComponent => Vars.Game.saveDataComponents[typeof(T).Name] as T;

    public virtual void InitData()
    {
    }

    public virtual void LoadData(Reader r)
    {
    }

    public virtual void SaveData(Writer w)
    {
    }

    public virtual void SaveDataClient(Writer w) => SaveData(w);

    public virtual void DisposeData()
    {
    }
}
