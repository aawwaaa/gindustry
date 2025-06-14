# if NEVER

using Godot;
using System.Collections.Generic;

namespace Gen
{

public sealed partial class __GDScriptAdapter_N__: __NS_GDScriptAdapter__, GDScriptAdapter
{
    private static readonly Dictionary<string, StringName> _stringNameCache = new();
    private static StringName _GetStringName(string name)
    {
        if (!_stringNameCache.TryGetValue(name, out var stringName))
        {
            stringName = new StringName(name);
            _stringNameCache.Add(name, stringName);
        }
        return stringName;
    }

    public GodotObject _Adapter;
    public static void _StaticInit()
    {
        GA.AdapterSpawners.Add(new StringName("__GDScriptAdapter__"), () => {
            var instance = new __GDScriptAdapter_N__();
            return instance;
        });
    }

    public void _SetAdapter(GodotObject adapter)
    {
        _Adapter = adapter;
        // __CSHARP_SIGNAL_CONNECT_INSERT__
    }

    public bool IsOverriden {get; set; } = false;

// __CSHARP_VIRTUAL_METHODS_INSERT__
    /*
        public bool _HaventOverriden_Name = false;
        public override void _Name()
        {
            if (_HaventOverriden_Name) return default;
            return _Adapter.Call(_GetStringName("_Name"));
        }
    */

// __CSHARP_OVERRIDE_METHODS_INSERT__
    /*
        public bool _HaventOverriden_Name = false;
        public override void _Name()
        {
            if (_HaventOverriden_Name) return base._Name();
            return _Adapter.Call(_GetStringName("_Name"));
        }
        public override void _DefaultImplement_Name()
        {
            return base._Name();
        }
    */
}

}
# endif
