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
        public delegate void InspectDelegate();
        public InspectDelegate InspectAction = delegate { };
        public void Inspect() {
            InspectAction();
        }

        public delegate void ResetDelegate();
        public ResetDelegate ResetAction = delegate { };
        public void Reset() {
            ResetAction();
        }
    }

    public class TestResult
    {
        public TestRun run;
        public bool failed;
    }
} 