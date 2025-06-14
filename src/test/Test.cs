using Godot;
using System;

namespace Gindustry.Test
{
    public class Test
    {
        public delegate TestRun TestAction(TestReporter r);
        public TestAction action;
        public string name;
        public TestGroup group;

        public TestRun Run(Action<TestResult> callback)
        {
            var reporter = new TestReporter
            {
                logger = Log.RegisterLogger($"Test:{group?.name ?? "ungrouped"}.{name}")
            };

            var run = new TestRun { test = this };
            try
            {
                action(reporter);
                reporter.Success();
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