using System;
using System.Text;
using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.Text;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Gen {};

[Generator]
public class GDScriptAdapterGenerator : ISourceGenerator
{
    private static string projectBase = "";

    private static void Cleanup(GeneratorExecutionContext context, string path)
    {
        path = Path.Combine(projectBase, "gen", path);

        if (File.Exists(path))
        {
            File.Delete(path);
        }
    }

    private static void GenerateFile(GeneratorExecutionContext context, string path, string data)
    {
        var fullPath = Path.Combine(projectBase, "gen", path);
        var dir = Path.GetDirectoryName(fullPath)!;
        if (!Directory.Exists(dir))
        {
            Directory.CreateDirectory(dir);
        }
        File.WriteAllText(fullPath, data);
    }

    private static string Replace(string template, Dictionary<string, Object> dict)
    {
        return template
            .Replace("__NS_GDScriptAdapter__", (string)dict["sourceName"])
            .Replace("__GDScriptAdapter__", (string)dict["targetName"])
            .Replace("__GDScriptAdapter_N__", "GDScriptAdapter_" + (string)dict["targetName"]);
    }

    private static string ToGDScriptName(String name)
    {
        var builder = new StringBuilder();
        bool first = true;
        foreach(var c in name)
        {
            if (char.IsUpper(c) && !first)
            {
                builder.Append('_');
            }
            builder.Append(char.ToLower(c));
            first = c == '_';
        }
        return builder.ToString();
    }

    private static string ReplaceCSharp(string template, Dictionary<string, Object> dict)
    {
        var signal_insert = new StringBuilder();
        foreach(var signal in (List<INamedTypeSymbol>)dict["signals"])
        {
            var name = signal.Name.Replace("EventHandler", "");
            signal_insert.Append($"Connect(_GetStringName(\"{name}\"), Callable(adapter, _GetStringName(\"_signal_{name}\")));\n");
        }
        var virtual_method_insert = new StringBuilder();
        foreach(var method in (List<IMethodSymbol>)dict["virtualMethods"])
        {
            var returns = method.ReturnsVoid? "": "return (" + method.ReturnType + ")";
            var args = method.Parameters.Count() == 0? "": ", " + string.Join(", ", method.Parameters.Select(p => p.Name + "_"));
            virtual_method_insert.Append($@"
public override {method.ReturnType} {method.Name}({string.Join(", ", method.Parameters.Select(p => $"{p.Type} {p.Name}_"))})
{{
    {returns}_Adapter.Call(_GetStringName({"\"" + ToGDScriptName(method.Name) + "\""}){args});
}}
");
        }

        var override_method_insert = new StringBuilder();
        foreach(var method in (List<IMethodSymbol>)dict["overrideMethods"])
        {
            var returns = method.ReturnsVoid? "": "return (" + method.ReturnType + ")";
            var args = method.Parameters.Count() == 0? "": ", " + string.Join(", ", method.Parameters.Select(p => p.Name + "_"));
            override_method_insert.Append($@"
public {method.ReturnType} _DefaultImplement{method.Name}({string.Join(", ", method.Parameters.Select(p => $"{p.Type} {p.Name}_"))})
{{
    {returns}base.{method.Name}({args});
}}
");
        }
        return Replace(template, dict)
            .Replace("// __CSHARP_SIGNAL_CONNECT_INSERT__", signal_insert.ToString())
            .Replace("// __CSHARP_VIRTUAL_METHODS_INSERT__", virtual_method_insert.ToString())
            .Replace("// __CSHARP_OVERRIDE_METHODS_INSERT__", override_method_insert.ToString());
    }

    private static string ReplaceGDScript(string template, Dictionary<string, Object> dict)
    {
        return Replace(template, dict);
    }

    public void Initialize(GeneratorInitializationContext context)
    {
        // 注册一个语法接收器，用于查找带有特定属性的类
        context.RegisterForSyntaxNotifications(() => new SyntaxReceiver());
    }

    public void Execute(GeneratorExecutionContext context)
    {
        if (context.SyntaxReceiver is not SyntaxReceiver receiver)
            return;
        
        string csharpTemplate = "";
        string gdscriptTemplate = "";

        foreach (var file in context.AdditionalFiles)
        {
            if (file.Path.EndsWith("gindustry.csproj"))
               projectBase = Path.GetDirectoryName(file.Path)!;
            if (file.Path.EndsWith("GDScriptAdapterTemplate.t.cs"))
                csharpTemplate = file.GetText(context.CancellationToken)!.ToString();
            if (file.Path.EndsWith("gdscript_adapter_template.t.gd"))
                gdscriptTemplate = file.GetText(context.CancellationToken)!.ToString();
        }

        csharpTemplate = csharpTemplate.Replace("# if NEVER", "").Replace("# endif", "");
        
        // Cleanup(context, "gdscript/");

        foreach (var pair in receiver.Targets)
        {
            var classDeclaration = pair.Key;
            var attributeData = pair.Value;
            var model = context.Compilation.GetSemanticModel(classDeclaration.SyntaxTree);
            var symbol = model.GetDeclaredSymbol(classDeclaration);
            if (symbol is null)
                continue;
            if (attributeData is null)
                continue;
            
            var targetName = attributeData.ArgumentList?.Arguments.FirstOrDefault()?.GetText().ToString().Replace("\"", "");
            if (targetName is null) 
                continue;
            var ns = symbol.ContainingNamespace.IsGlobalNamespace? "": symbol.ContainingNamespace.ToDisplayString()+".";
            var dict = new Dictionary<String, Object>();
            dict["class"] = symbol;
            dict["targetName"] = targetName;
            dict["sourceName"] = ns + symbol.Name;

            var methods = new List<IMethodSymbol>();
            var virtualMethods = new List<IMethodSymbol>();
            var overrideMethods = new List<IMethodSymbol>();
            var fields = new List<IFieldSymbol>();
            var properties = new List<IPropertySymbol>();
            var signals = new List<INamedTypeSymbol>();
            var current = symbol;
            INamedTypeSymbol? last = null;
            while (current is not null)
            {
                foreach(var method in current.GetMembers().OfType<IMethodSymbol>())
                {
                    if (last is not null && last.FindImplementationForInterfaceMember(method) is not null)
                        continue;
                    if (!method.Name.StartsWith("_")) continue;
                    if ((method.IsVirtual || method.IsOverride)) virtualMethods.Add(method);
                    else if (method.DeclaredAccessibility == Accessibility.Public) methods.Add(method);
                    if (method.IsOverride) overrideMethods.Add(method);
                }

                foreach(var field in current.GetMembers().OfType<IFieldSymbol>())
                {
                    if (last is not null && last.FindImplementationForInterfaceMember(field) is not null)
                        continue;
                    fields.Add(field);
                }

                foreach(var property in current.GetMembers().OfType<IPropertySymbol>())
                {
                    if (last is not null && last.FindImplementationForInterfaceMember(property) is not null)
                        continue;
                    properties.Add(property);
                }

                foreach(var signal in current.GetMembers().OfType<INamedTypeSymbol>())
                {
                    if (last is not null && last.FindImplementationForInterfaceMember(signal) is not null)
                        continue;
                    if (signal.TypeKind != TypeKind.Delegate) continue;
                    if (!signal.GetAttributes().Any(attr => attr.AttributeClass?.Name == "SignalAttribute")) continue;
                    signals.Add(signal);
                }
                last = current;
                current = current.BaseType;
            }

            dict["methods"] = methods;
            dict["virtualMethods"] = virtualMethods;
            dict["overrideMethods"] = overrideMethods;
            dict["fields"] = fields;
            dict["properties"] = properties;
            dict["signals"] = signals;

            var generatedCode = ReplaceCSharp(csharpTemplate, dict);
            context.AddSource($"{symbol.Name}_GDScriptAdapter_{targetName}.g.cs", SourceText.From(generatedCode, Encoding.UTF8));

            generatedCode = ReplaceGDScript(gdscriptTemplate, dict);
            GenerateFile(context, $"gdscript/{targetName}.gd", generatedCode);
        }
    }

    class SyntaxReceiver : ISyntaxReceiver
    {
        public Dictionary<ClassDeclarationSyntax, AttributeSyntax> Targets { get; } = new();

        public void OnVisitSyntaxNode(SyntaxNode syntaxNode)
        {
            if (syntaxNode is not ClassDeclarationSyntax classDeclaration) return;
            if (classDeclaration.AttributeLists.Count == 0) return;
            foreach (var attributes in classDeclaration.AttributeLists)
            {
                foreach (var attribute in attributes.Attributes)
                {
                    if (attribute.Name.ToString() == "GDScriptAdapterTarget")
                        Targets.Add(classDeclaration, attribute);
                }
            }
        }
    }

}


[AttributeUsage(AttributeTargets.Class)]
public class GDScriptAdapterTargetAttribute : Attribute
{
    public String TargetName { get; }

    public GDScriptAdapterTargetAttribute(String targetName)
    {
        TargetName = targetName;
    }
}

