using Godot;
using System;

namespace Gindustry.Object;

public partial class CSharpObjectType<T> : ObjectType where T : RefObject, new()
{
    public CSharpObjectType() {}
    public CSharpObjectType(String id) : base(id) {}

    protected override RefObject _Create()
    {
        return new T();
    }
}
