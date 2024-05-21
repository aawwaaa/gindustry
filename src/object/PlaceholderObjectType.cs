using Godot;
using System;

public partial class PlaceholderObjectType<T> : RefObjectType<T> where T : IRefObject
{
    public PlaceholderObjectType(string typeID) : base(typeID) { }
}
