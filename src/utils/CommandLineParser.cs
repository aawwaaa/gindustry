using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class CommandLineParser: GodotObject
{
    // 定义接口 ArgType
    public interface IArgType
    {
        string Name { get; }
        string ShortName { get; }
        void DoAction(string[] args);
    }

    // PropertyArg 类
    public class PropertyArg : IArgType
    {
        public string Name { get; }
        public string ShortName { get; }
        private Action<string> Setter { get; }
        private Func<string, string> Validator { get; }

        public PropertyArg(string name, Action<string> setter, Func<string, string> validator = null, string shortName = null)
        {
            Name = name;
            ShortName = shortName;
            Setter = setter;
            Validator = validator;
        }

        public void DoAction(string[] args)
        {
            if (args.Length == 0)
                throw new ArgumentException($"Missing value for property: {Name}");

            string value = args[0];
            string validationResult = Validator?.Invoke(value);
            if (!string.IsNullOrEmpty(validationResult))
                throw new ArgumentException(validationResult);

            Setter(value);
        }
    }

    // ActionArg 类
    public class ActionArg : IArgType
    {
        public string Name { get; }
        public string ShortName { get; }
        private Action<string[]> Action { get; }
        private Func<string[], string> Validator { get; }

        public ActionArg(string name, Action<string[]> action, Func<string[], string> validator = null, string shortName = null)
        {
            Name = name;
            ShortName = shortName;
            Action = action;
            Validator = validator;
        }

        public void DoAction(string[] args)
        {
            string validationResult = Validator?.Invoke(args);
            if (!string.IsNullOrEmpty(validationResult))
                throw new ArgumentException(validationResult);

            Action(args);
        }
    }

    private readonly Dictionary<string, IArgType> _propertyArgs;
    private readonly Dictionary<string, IArgType> _actionArgs;

    public CommandLineParser(List<PropertyArg> propertyArgs, List<ActionArg> actionArgs)
    {
        _propertyArgs = propertyArgs.ToDictionary(arg => arg.Name, arg => (IArgType)arg);
        _actionArgs = actionArgs.ToDictionary(arg => arg.Name, arg => (IArgType)arg);

        // 添加短名称映射
        foreach (var arg in propertyArgs)
        {
            if (!string.IsNullOrEmpty(arg.ShortName))
            {
                if (_propertyArgs.ContainsKey(arg.ShortName) || _actionArgs.ContainsKey(arg.ShortName))
                    throw new ArgumentException($"Duplicate short name: {arg.ShortName}");

                _propertyArgs[arg.ShortName] = arg;
            }
        }
        foreach (var arg in actionArgs)
        {
            if (!string.IsNullOrEmpty(arg.ShortName))
            {
                if (_propertyArgs.ContainsKey(arg.ShortName) || _actionArgs.ContainsKey(arg.ShortName))
                    throw new ArgumentException($"Duplicate short name: {arg.ShortName}");

                _actionArgs[arg.ShortName] = arg;
            }
        }
    }

    public void Parse(string[] args)
    {
        for (int i = 0; i < args.Length; i++)
        {
            string arg = args[i];
            if (arg.StartsWith("--"))
            {
                // 处理长名称参数
                string[] parts = arg.Substring(2).Split(new[] { '=' }, 2);
                string name = parts[0];
                string[] values = parts.Length > 1 ? new[] { parts[1] } : new string[0];

                if (_propertyArgs.TryGetValue(name, out var propertyArg))
                    propertyArg.DoAction(values);
                else if (_actionArgs.TryGetValue(name, out var actionArg))
                    actionArg.DoAction(values);
                else
                    throw new ArgumentException($"Unknown argument: {name}");
            }
            else if (arg.StartsWith("-"))
            {
                // 处理短名称参数
                string shortName = arg.Substring(1);
                if (_propertyArgs.TryGetValue(shortName, out var propertyArg))
                    propertyArg.DoAction(new string[0]);
                else if (_actionArgs.TryGetValue(shortName, out var actionArg))
                    actionArg.DoAction(new string[0]);
                else
                    throw new ArgumentException($"Unknown short argument: {shortName}");
            }
            else
            {
                // 处理无前缀参数
                throw new ArgumentException($"Unexpected argument: {arg}");
            }
        }
    }
}
