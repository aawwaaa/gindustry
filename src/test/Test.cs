using Godot;
using System;

namespace Gindustry.Test
{
    public class Test
    {
        public delegate void TestAction(TestReporter r);
        public TestAction action;
        public string name;
        public TestGroup group;
        public bool excludeBatch;

        public TestRun Run(Action<TestResult> callback)
        {
            var reporter = new TestReporter
            {
                logger = Log.RegisterLogger($"Test:{group?.name ?? "ungrouped"}.{name}")
            };

            var run = new TestRun { test = this };
            reporter.run = run;
            try
            {
                action(reporter);
            }
            catch (Exception e)
            {
                reporter.logger.Error($"Test failed: {e}");
                reporter.Failed();
            }

            callback?.Invoke(new TestResult { run = run, failed = reporter.failed });
            return run;
        }
    }
} 