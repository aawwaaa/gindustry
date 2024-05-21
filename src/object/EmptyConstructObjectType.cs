using Godot;
using System;

public partial class EmptyConstructObjectType<T> : RefObjectType<T> where T : IRefObject, new()
{
    public EmptyConstructObjectType(string typeID) : base(typeID) { }

    public override T _Create()
    {
        return new T();
    }
}
