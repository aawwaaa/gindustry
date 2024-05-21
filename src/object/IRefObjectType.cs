using Godot;
using System;

public interface IRefObjectType<out T> where T : IRefObject
{
    abstract string TypeID { get; }
    abstract uint TypeIndex { get; set; }
    T Create();
    T LoadFrom(IReadableStream stream);
}

public static class IRefObjectTypeEx
{
    public static T CreateAndInit<T>(this IRefObjectType<T> objType) where T : IRefObject
    {
        T obj = objType.Create();
        obj.ObjectInit();
        return obj;
    }

    public static T LoadFromAndInit<T>(this IRefObjectType<T> objType, IReadableStream stream) where T : IRefObject
    {
        T obj = objType.LoadFrom(stream);
        obj.ObjectInit();
        return obj;
    }
}
