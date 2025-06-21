using Godot;
using System.Collections.Generic;
using Gindustry.Attributes;

namespace Gindustry.Test
{
    [GDScriptAdapterTarget("GA_TestRun")]
    [GlobalClass]
    public partial class TestRun: RefCounted
    {
        public Test test;
        public virtual void _Inspect() {}
        public void Inspect() {
            _Inspect();
        }
        public virtual void _Reset() {}
        public void Reset() {
            _Reset();
        }
    }

    public class TestResult
    {
        public TestRun run;
        public bool failed;
    }
} 