using Godot;
using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;

namespace Gindustry.Test
{
    public partial class TestReporter: RefCounted
    {
        public Log.Logger logger;
        public TestRun run;
        public bool failed;
        public bool reported = false;

        private bool MarkReported() {
            if (!reported) return false;
            reported = true;
            return true;
        }

        public void Success()
        {
            if (MarkReported()) return;
            logger.Info("Test passed");
        }

        public void Failed()
        {
            if (MarkReported()) return;
            failed = true;
            logger.Error("Test failed");
        }

        public void Log(params object[] args)
        {
            logger.Info(string.Join(" ", args));
        }

        public void Success(string message)
        {
            if (MarkReported()) return;
            logger.Info(message);
        }

        public void Failed(string message)
        {
            if (MarkReported()) return;
            failed = true;
            logger.Error(message);
        }

        public void Equal<T>(T a, T b, 
            [CallerArgumentExpression(nameof(a))] string aExpr = null,
            [CallerArgumentExpression(nameof(b))] string bExpr = null,
            [CallerLineNumber] int lineNumber = 0,
            [CallerFilePath] string filePath = null)
        {
            if (MarkReported()) return;
            if (!EqualityComparer<T>.Default.Equals(a, b))
            {
                logger.Error($"Assertion failed in {filePath}:{lineNumber}: {aExpr} ({a}) != {bExpr} ({b})");
                Failed();
            }
        }

        public void NotEqual<T>(T a, T b,
            [CallerArgumentExpression(nameof(a))] string aExpr = null,
            [CallerArgumentExpression(nameof(b))] string bExpr = null,
            [CallerLineNumber] int lineNumber = 0,
            [CallerFilePath] string filePath = null)
        {
            if (MarkReported()) return;
            if (EqualityComparer<T>.Default.Equals(a, b))
            {
                logger.Error($"Assertion failed in {filePath}:{lineNumber}: {aExpr} ({a}) == {bExpr} ({b})");
                Failed();
            }
        }

        public void Assert(bool condition,
            [CallerArgumentExpression(nameof(condition))] string conditionExpr = null,
            [CallerLineNumber] int lineNumber = 0,
            [CallerFilePath] string filePath = null)
        {
            if (MarkReported()) return;
            if (!condition)
            {
                logger.Error($"Assertion failed in {filePath}:{lineNumber}: {conditionExpr}");
                Failed();
            }
        }

        public void Inspect(TestRun.InspectDelegate action)
        {
            run.InspectAction = action;
        }

        public void Reset(TestRun.ResetDelegate action)
        {
            run.ResetAction = action;
        }
    }
} 