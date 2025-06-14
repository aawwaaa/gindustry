using System;

namespace Gindustry.Test
{
    [AttributeUsage(AttributeTargets.Method)]
    public class TestAttribute : Attribute
    {
        public string Group { get; }
        public string Name { get; }

        public TestAttribute(string group, string name)
        {
            Group = group;
            Name = name;
        }
    }
} 