using Godot;
using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;

namespace Gindustry.Test
{
    public partial class TestReporter: RefCounted
    {
        public Log.Logger logger;
        public bool failed;

        public void Success()
        {
            logger.Info("Test passed");
        }

        public void Failed()
        {
            failed = true;
            logger.Error("Test failed");
        }

        public void Success(string message)
        {
            logger.Info(message);
        }

        public void Failed(string message)
        {
            failed = true;
            logger.Error(message);
        }

        public void Equal<T>(T a, T b, 
            [CallerArgumentExpression(nameof(a))] string aExpr = null,
            [CallerArgumentExpression(nameof(b))] string bExpr = null,
            [CallerMemberName] string memberName = null,
            [CallerFilePath] string filePath = null)
        {
            if (!EqualityComparer<T>.Default.Equals(a, b))
            {
                logger.Error($"Assertion failed in {memberName} at {filePath}: {aExpr} ({a}) != {bExpr} ({b})");
                Failed();
            }
        }

        public void NotEqual<T>(T a, T b,
            [CallerArgumentExpression(nameof(a))] string aExpr = null,
            [CallerArgumentExpression(nameof(b))] string bExpr = null,
            [CallerMemberName] string memberName = null,
            [CallerFilePath] string filePath = null)
        {
            if (EqualityComparer<T>.Default.Equals(a, b))
            {
                logger.Error($"Assertion failed in {memberName} at {filePath}: {aExpr} ({a}) == {bExpr} ({b})");
                Failed();
            }
        }

        public void Assert(bool condition,
            [CallerArgumentExpression(nameof(condition))] string conditionExpr = null,
            [CallerMemberName] string memberName = null,
            [CallerFilePath] string filePath = null)
        {
            if (!condition)
            {
                logger.Error($"Assertion failed in {memberName} at {filePath}: {conditionExpr}");
                Failed();
            }
        }
    }
} 