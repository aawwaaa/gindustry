using Godot;
using System;
using System.Threading.Tasks;

public partial class Utils : Node
{
    public static readonly StringName SINGLETON_NAME = "Utils";

    public delegate void SaveCallback();
    public static void SaveWithVersion(WritableStream stream, params SaveCallback[] callbacks)
    {
        stream.ShortUnsigned((ushort)callbacks.Length);

        foreach (SaveCallback callback in callbacks)
        {
            callback();
        }
    }

    public delegate void LoadCallback();
    public static void LoadWithVersion(ReadableStream stream, params LoadCallback[] callbacks)
    {
        ushort count = stream.ShortUnsigned();
        for (int i = 0; i < count; i++)
        {
            callbacks[i]();
        }
    }
}
