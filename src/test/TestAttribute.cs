using System;

namespace Gindustry.Test
{
    [AttributeUsage(AttributeTargets.Method)]
    public class TestAttribute : Attribute
    {
        public string Group { get; }
        public string Name { get; }
        public bool ExcludeBatch { get; }

        public TestAttribute(string group, string name)
        {
            Group = group;
            Name = name;
            ExcludeBatch = false;
        }

        public TestAttribute(string group, string name, bool excludeBatch)
        {
            Group = group;
            Name = name;
            ExcludeBatch = excludeBatch;
        }
    }
} 