using Godot;
using System;
using System.Collections.Generic;
using Gindustry.IO;

namespace Gindustry.Utils;

public class ConfigKey<T>
{
    public string Name { get; private set; }
    public T DefaultValue { get; private set; }

    public ConfigKey(string name, T defaultValue)
    {
        Name = name;
        DefaultValue = defaultValue;
    }
    
    // I don't know why C# doesn't support generic indexer
    public T this[ConfigsGroup group]
    {
        get => group.Get(this);
        set => group.Set(this, value);
    }

    public T V // [V]ars.Configs.configs
    {
        get => Vars.Configs.Get(this);
        set => Vars.Configs.Set(this, value);
    }

    public static implicit operator T(ConfigKey<T> key)
    {
        return key.V;
    }
}

[GlobalClass]
public partial class ConfigsGroup : Resource, Saveable
{

    private Dictionary<string, object> _dict = new ();
    private Dictionary<string, object> _defaults = new ();

    public void LoadFrom(Reader stream)
    {
        InitConfigs();
        LoadConfigs(stream);
    }

    public void _SaveData(Writer w) => SaveConfigs(w);
    public void _LoadData(Reader r) => LoadConfigs(r);

    public void LoadConfigs(Reader stream)
    {
        stream.Iter(_dict, reader => new KeyValuePair<string, object>(reader.S(), reader.SV<object>()));
    }

    public void SaveConfigs(Writer stream)
    {
        stream.I32(_dict.Count);
        foreach (var key in _dict.Keys)
        {
            stream.S(key);
            stream.SV(_dict[key]);
        }
    }

    public void InitConfigs()
    {
        _dict = new();
    }

    public ConfigsGroup Copy()
    {
        var newInst = new ConfigsGroup();
        newInst._dict = new (_dict);
        return newInst;
    }

    public T Get<T>(string key)
    {
        if (!_dict.ContainsKey(key) && _defaults.ContainsKey(key))
            return (T)_defaults[key];
        return (T)_dict[key];
    }
    public Variant g(string key) => Get(key);

    public T Get<T>(string key, T defaultValue)
    {
        if (defaultValue == null && _defaults.ContainsKey(key))
            defaultValue = (T)_defaults[key];
        if (!_dict.ContainsKey(key) && defaultValue != null)
            _dict[key] = defaultValue;
        return (T)_dict[key];
    }
    public Variant g(string key, Variant defaultValue) => Get(key, defaultValue);

    public T Get<T>(ConfigKey<T> key)
    {
        return Get(key.Name, key.DefaultValue);
    }

    public void Set(string key, object value)
    {
        _dict[key] = value;
    }
    public void s(string key, object value) => Set(key, value);

    public void Set<T>(ConfigKey<T> key, T value)
    {
        Set(key.Name, value);
    }

    public bool Contains(string key) => _dict.ContainsKey(key);
    public bool Contains<T>(ConfigKey<T> key) => Contains(key.Name);

    public void SetDefaults(Dictionary<string, object> defs)
    {
        foreach (var kvp in defs)
            _defaults[kvp.Key] = kvp.Value;
    }
    public void set_defaults(Godot.Collections.Dictionary defs)
    {
        foreach (var kvp in defs)
            _defaults[(string)kvp.Key] = kvp.Value;
    }

    public object this[string key]
    {
        get => Get(key);
        set => Set(key, value);
    }
}
