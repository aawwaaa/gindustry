using Godot;
using System;
using System.Collections.Generic;

[GlobalClass]
public class SaveMeta : RefCounted
{
    public String SaveName = "save";
    public string FilePath { get; set; }

    public int SaveMetaVersion { get; set; } = 1;
    public Dictionary<string, ModInfo.ModRef> Mods { get; set; } = new();

    public void ApplyCurrentMods()
    {
        foreach (var mod in Vars.Mods.ModInstList.Values)
            Mods[mod.ModInfo.Id] = (ModInfo.ModRef)mod.ModInfo;
    }

    public void LoadFrom(Reader reader)
    {
        SaveMetaVersion = reader.U16();

        // Version 0
        if (SaveMetaVersion < 0) return;

        int size = reader.I32();

        for (int i = 0; i < size; i++)
        {
            string modId = reader.S();

            string modVersion = reader.S();

            Mods[modId] = new ModInfo.ModRef {
                Id = modId,
                Min = modVersion
            };
        }
    }

    public void SaveTo(Writer writer)
    {
        writer.U16(0);

        // Version 0
        var values = Vars.Mods.ModInstList.Values;
        writer.I32(values.Count);
        foreach (var mod in values)
        {
            writer.S(mod.ModInfo.Id);
            writer.S(mod.ModInfo.Version);
        }
    }
}
