using Godot;
using System;
using System.Collections.Generic;

namespace Gindustry.Test
{
    public class TestGroup
    {
        public string name;
        public Dictionary<string, Test> tests = new();

        public void Add(Test test)
        {
            test.group = this;
            tests[test.name] = test;
        }

        public Dictionary<string, TestRun> RunAll(Action<Dictionary<string, TestResult>> callback)
        {
            var results = new Dictionary<string, TestResult>();
            var runs = new Dictionary<string, TestRun>();

            foreach (var test in tests.Values)
            {
                if (test.excludeBatch) continue;
                var run = test.Run(result => results[test.name] = result);
                runs[test.name] = run;
            }

            callback?.Invoke(results);
            return runs;
        }
    }
} 