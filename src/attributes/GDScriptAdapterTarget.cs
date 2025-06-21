using System;

namespace Gindustry.Attributes;

[AttributeUsage(AttributeTargets.Class, AllowMultiple = false)]
public class GDScriptAdapterTargetAttribute(string targetName) : Attribute
{
    public string TargetName { get; } = targetName;
}