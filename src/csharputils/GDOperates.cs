using Godot;
using System;

public static class GDOperates
{
    public static Nullable<Variant> GetChained(this GodotObject obj, params StringName[] names)
    {
        for (int i = 0; i < names.Length; i++)
        {
            if (i == names.Length - 1)
                return obj.Get(names[i]);
            obj = (GodotObject)obj.Get(names[i]);
            if (obj == null) break;
        }
        return null;
    }
}
