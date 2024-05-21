using Godot;
using System;
using System.Threading.Tasks;

public partial class Utils : Node
{
    public static readonly StringName SINGLETON_NAME = "Utils";

    public static Serialize serialize;

    public override void _Ready()
    {
        serialize = Attach(new Serialize());
    }

    public T Attach<T>(T obj) where T: Node
    {
        obj.Name = obj.GetType().Name;
        AddChild(obj);
        return obj;
    }

    public Serialize Serialize
    {
        get { return serialize; }
    }

    public delegate void SaveCallback();
    public static void SaveWithVersion(IWritableStream stream, params SaveCallback[] callbacks)
    {
        stream.ShortUnsigned((ushort)callbacks.Length);

        foreach (SaveCallback callback in callbacks)
        {
            callback();
        }
    }

    public delegate void LoadCallback();
    public static void LoadWithVersion(IReadableStream stream, params LoadCallback[] callbacks)
    {
        ushort count = stream.ShortUnsigned();
        for (int i = 0; i < count; i++)
        {
            callbacks[i]();
        }
    }
}
