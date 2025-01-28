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
    private static readonly string[] methodBlacklist = new string[] {
        "GetType",
        "_Get",
        "_Set",
        "_GetPropertyList",
        "_PropertyCanRevert",
        "_PropertyGetRevert",
        "_ValidateProperty",
    };

    private static readonly string[] propertyBlacklist = new string[] {
        "_ImportPath"
    };

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
            .Replace("__S_GDScriptAdapter__", (string)dict["sourceNameOnly"])
            .Replace("__GDScriptAdapter__", (string)dict["targetName"])
            .Replace("__GDScriptAdapter_N__", "GDScriptAdapter_" + (string)dict["targetName"]);
    }

    private static string ToGDScriptName(String name)
    {
        // return name;
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

    private static bool NeedCompatibility(String name)
    {
        return name.ToLower() != name;
    }

    private static string ToGDScriptType(ITypeSymbol type, Dictionary<string, Object> dict)
    {
        if (type.SpecialType != SpecialType.None) switch(type.SpecialType)
        {
            case SpecialType.System_String:
                return "String";
            case SpecialType.System_Boolean:
                return "bool";
            case SpecialType.System_Single:
            case SpecialType.System_Double:
                return "float";
            case SpecialType.System_Byte:
            case SpecialType.System_SByte:
            case SpecialType.System_Int16:
            case SpecialType.System_Int32:
            case SpecialType.System_Int64:
            case SpecialType.System_UInt16:
            case SpecialType.System_UInt32:
            case SpecialType.System_UInt64:
            case SpecialType.System_Decimal:
                return "int";
            case SpecialType.System_Object:
                return "Variant";
            case SpecialType.System_Void:
                return "void";
            default:
                return $"GenerateError_{type}";
        }

        if (type.TypeKind == TypeKind.Array)
        {
            var arrayType = (IArrayTypeSymbol)type;
            return $"Array[{ToGDScriptType(arrayType.ElementType, dict)}]";
        }

        if (type is INamedTypeSymbol namedType)
        {
            ((Dictionary<string, string>)dict["type2target"]).TryGetValue(namedType.Name, out var targetName);
            if (targetName != null) return "Object";
            if (namedType.ContainingNamespace.ToDisplayString().StartsWith("Godot"))
                targetName = namedType.Name;
            if (targetName == null) return $"GenerateError_{namedType.Name}";
            if (namedType.Name.EndsWith("Enum")) return "int";
            if (namedType.Name == "MultiplayerApi") return "MultiplayerAPI";
            if (namedType.Name == "Rid") return "RID";
            if (namedType.Name == "GodotObject") return "Object";
            if (namedType.IsGenericType)
            {
                var genericType = (INamedTypeSymbol)namedType.TypeArguments[0];
                return $"{targetName}[{ToGDScriptType(genericType, dict)}]";
            }
            else
            {
                return targetName;
            }
        }
        return $"GenerateError_{type}";
    }

    private static string TOGDScriptDefaultValue(string type)
    {
        if (type.StartsWith("Array")) return "[]";
        switch (type)
        {
            case "bool":
                return "false";
            case "int":
                return "0";
            case "float":
                return "0.0";
            case "String":
                return "\"\"";
            case "void":
                return "pass";
            case "StringName":
                return "&\"\"";
            case "RID":
                return "RID()";
            default:
                return "null";
        }
    }

    private static string ReplaceCSharp(string template, Dictionary<string, Object> dict)
    {
        var signal_insert = new StringBuilder();
        foreach(var signal in (List<INamedTypeSymbol>)dict["signals"])
        {
            var name = signal.Name.Replace("EventHandler", "");
            signal_insert.Append($"Connect(_GetStringName(\"{name}\"), new Callable(adapter, _GetStringName(\"_signal_{name}\")));\n");
        }
        var virtual_method_insert = new StringBuilder();
        /*
        foreach(var method in (List<IMethodSymbol>)dict["virtualMethods"])
        {
            var returns = method.ReturnsVoid? "": "return (" + method.ReturnType + ")";
            var args = method.Parameters.Count() == 0? "": ", " + string.Join(", ", method.Parameters.Select(p => p.Name + "_"));
            virtual_method_insert.Append($@"
public bool _HaventOverriden{method.Name} = false;
{method.DeclaredAccessibility.ToString().ToLower()} override {method.ReturnType} {method.Name}({string.Join(", ",
    method.Parameters.Select(p => $"{p.Type} {p.Name}_"))})
{{
    if (_HaventOverriden{method.Name}) {{{returns}base.{method.Name}({string.Join(", ",
        method.Parameters.Select(p => p.Name + "_"))}); {(returns == ""? "return;": "")}}}
    {returns}_Adapter.Call(_GetStringName({"\"" + ToGDScriptName(method.Name) + "\""}){args});
}}
");
        }
        */
        var override_method_insert = new StringBuilder();
        foreach(var method in (List<IMethodSymbol>)dict["overrideMethods"])
        {
            var assign = method.ReturnsVoid? "": "var ret = (" + method.ReturnType + ")";
            var returns = method.ReturnsVoid? "": "return ret;";
            var args = method.Parameters.Count() == 0? "": ", " + string.Join(", ", method.Parameters.Select(p => p.Name + "_"));
            override_method_insert.Append($@"
public bool _HaventOverriden{method.Name} = false;
{method.DeclaredAccessibility.ToString().ToLower()} override {method.ReturnType} {method.Name}({string.Join(", ", 
    method.Parameters.Select(p => $"{p.Type} {p.Name}_"))})
{{
    IsOverriden = true;
    {assign}_Adapter.Call(_GetStringName({"\"" + ToGDScriptName(method.Name) + "\""}){args});
    if (!IsOverriden) {{{returns}base.{method.Name}({string.Join(", ",
        method.Parameters.Select(p => p.Name + "_"))}); {(returns == ""? "return;": "")}}}
    {returns}
}}
");
        }
        return Replace(template, dict)
            .Replace("// __CSHARP_SIGNAL_CONNECT_INSERT__", signal_insert.ToString())
            .Replace("// __CSHARP_VIRTUAL_METHODS_INSERT__", virtual_method_insert.ToString())
            .Replace("// __CSHARP_OVERRIDE_METHODS_INSERT__", override_method_insert.ToString());
    }

    private static string ReplaceCSharpCompatibility(string template, Dictionary<string, Object> dict)
    {
        var property_insert = new StringBuilder();
        /*
        foreach(var signal in (List<INamedTypeSymbol>)dict["signals"])
        {
            var name = signal.Name.Replace("EventHandler", "");
            if (!NeedCompatibility(name)) continue;
            property_insert.Append($"{signal.DeclaredAccessibility.ToString().ToLower()} Signal {ToGDScriptName(name)}" + 
                $" {{ get {{ return {name}; }} }}\n");
        }
        // I have no idea how to do this, the only override method is used by Godot.
        */
        foreach(var field in (List<IFieldSymbol>)dict["fields"])
        {
            if (!NeedCompatibility(field.Name)) continue;
            property_insert.Append($"{field.DeclaredAccessibility.ToString().ToLower()} {field.Type}" + 
                $" {ToGDScriptName(field.Name)} {{ get {{ return {field.Name}; }} set {{ {field.Name} = value; }} }}\n");
        }
        foreach(var property in (List<IPropertySymbol>)dict["properties"])
        {
            if (!NeedCompatibility(property.Name)) continue;
            var getAccess = property.GetMethod!.DeclaredAccessibility;
            var setAccess = property.SetMethod is not null? property.SetMethod!.DeclaredAccessibility: getAccess;
            var get = property.GetMethod is not null? @$" {(IsStricter(getAccess, setAccess)?
                getAccess.ToString().ToLower(): "")} get {{ return {property.Name}; }}": "";
            var set = property.SetMethod is not null? @$" {(IsStricter(setAccess, getAccess)? 
                setAccess.ToString().ToLower(): "")} set {{ {property.Name} = value; }}": "";
            property_insert.Append($"{property.DeclaredAccessibility.ToString().ToLower()} {property.Type}" + 
                $" {ToGDScriptName(property.Name)} {{ {get} {set} }}\n");
        }
        var method_insert = new StringBuilder();
        foreach(var method in (List<IMethodSymbol>)dict["methods"])
        {
            if (!NeedCompatibility(method.Name)) continue;
            var returns = method.ReturnsVoid? "": "return ";
            var args = string.Join(", ", method.Parameters.Select(p => ToGDScriptName(p.Name)));
            method_insert.Append($@"
{method.DeclaredAccessibility.ToString().ToLower()} {method.ReturnType} {ToGDScriptName(method.Name)}({
    string.Join(", ", method.Parameters.Select(p => $"{p.Type} {ToGDScriptName(p.Name)}"))})
{{
    {returns}{method.Name}({args});
}}
");
        }
        return Replace(template, dict)
            .Replace("// __CSHARP_PROPERTY_INSERT__", property_insert.ToString())
            .Replace("// __CSHARP_METHODS_INSERT__", method_insert.ToString());
    }

    // 判断 access1 是否比 access2 更严格
    private static bool IsStricter(Accessibility access1, Accessibility access2)
    {
        // 定义访问修饰符的严格程度顺序
        var accessibilityOrder = new[]
        {
            Accessibility.Private,
            Accessibility.ProtectedAndInternal,
            Accessibility.Protected,
            Accessibility.Internal,
            Accessibility.ProtectedOrInternal,
            Accessibility.Public
        };

        // 获取 access1 和 access2 在顺序中的索引
        int index1 = Array.IndexOf(accessibilityOrder, access1);
        int index2 = Array.IndexOf(accessibilityOrder, access2);

        // 如果 index1 小于 index2，则 access1 更严格
        return index1 < index2;
    }

    private static string ReplaceGDScript(string template, Dictionary<string, Object> dict)
    {
        var signal_insert = new StringBuilder();
        foreach(var signal in (List<INamedTypeSymbol>)dict["signals"])
        {
            var name = signal.Name.Replace("EventHandler", "");
            var method = signal.DelegateInvokeMethod!;
            signal_insert.Append($@"
signal {ToGDScriptName(name)}({string.Join(", ", method.Parameters.Select(p => ToGDScriptName(p.Name) + ": " + ToGDScriptType(p.Type, dict)))});

func _signal_{name}({string.Join(", ", method.Parameters.Select(p => p.Name + ": " + ToGDScriptType(p.Type, dict)))}):
    {ToGDScriptName(name)}.emit({string.Join(", ", method.Parameters.Select(p => p.Name))});
");
        }
        var field_insert = new StringBuilder();
        foreach(var field in (List<IFieldSymbol>)dict["fields"])
        {
            field_insert.Append($@"
var {ToGDScriptName(field.Name)}: {ToGDScriptType(field.Type, dict)}:
    get: return _instance.{field.Name};
    set(value): _instance.{field.Name} = value;
");
        }
        foreach(var field in (List<IPropertySymbol>)dict["properties"])
        {
            field_insert.Append($@"
var {ToGDScriptName(field.Name)}: {ToGDScriptType(field.Type, dict)}:
    get: return _instance.{field.Name};
");
            if (field.SetMethod != null && field.SetMethod.DeclaredAccessibility == Accessibility.Public)
                field_insert.Append($"    set(value): _instance.{field.Name} = value;\n");
        }
        var virtual_method_insert = new StringBuilder();
        /*
        foreach(var method in (List<IMethodSymbol>)dict["virtualMethods"])
        {
            var returns = method.ReturnsVoid? "": "return ";
            var defaultValue = TOGDScriptDefaultValue(ToGDScriptType(method.ReturnType, dict));
            virtual_method_insert.Append($@"
func {ToGDScriptName(method.Name)}({string.Join(", ", method.Parameters.Select(p => "_" + 
        ToGDScriptName(p.Name) + ": " + ToGDScriptType(p.Type, dict)))}) -> {ToGDScriptType(method.ReturnType, dict)}:
    _instance._HaventOverriden{method.Name} = true;
    {returns}{defaultValue};
");
        }
        */
        var override_method_insert = new StringBuilder();
        foreach(var method in (List<IMethodSymbol>)dict["overrideMethods"])
        {
            var returns = method.ReturnsVoid? "": "return ";
            var args = method.Parameters.Count() == 0? "": string.Join(", ", method.Parameters.Select(p => ToGDScriptName(p.Name) + "_"));
            var defaultValue = TOGDScriptDefaultValue(ToGDScriptType(method.ReturnType, dict));
            override_method_insert.Append($@"
func {ToGDScriptName(method.Name)}({string.Join(", ", method.Parameters.Select(p => 
        ToGDScriptName(p.Name) + "_: " + ToGDScriptType(p.Type, dict)))}) -> {ToGDScriptType(method.ReturnType, dict)}:
    GA.HaventOverriden(_instance);
    {returns}{defaultValue};
");
        }
        var method_insert = new StringBuilder();
        foreach(var method in (List<IMethodSymbol>)dict["methods"])
        {
            var returns = method.ReturnsVoid? "": "return ";
            var args = method.Parameters.Count() == 0? "": string.Join(", ", method.Parameters.Select(p => ToGDScriptName(p.Name) + "_"));
            method_insert.Append($@"
func {ToGDScriptName(method.Name)}({string.Join(", ", method.Parameters.Select(p => 
        ToGDScriptName(p.Name) + "_: " + ToGDScriptType(p.Type, dict)))}) -> {ToGDScriptType(method.ReturnType, dict)}:
    {returns}_instance.{method.Name}({args});
");
        }
        if (dict.ContainsKey("extends"))
            template = template.Replace("var _instance: __S_GDScriptAdapter__", "")
                .Replace("Object", (string)dict["extends"]);
        return Replace(template, dict)
            .Replace("# __GDSCRIPT_SIGNALS_INSERT__", signal_insert.ToString())
            .Replace("# __GDSCRIPT_FIELDS_INSERT__", field_insert.ToString())
            .Replace("# __GDSCRIPT_VIRTUAL_METHODS_INSERT__", virtual_method_insert.ToString())
            .Replace("# __GDSCRIPT_OVERRIDE_METHODS_INSERT__", override_method_insert.ToString())
            .Replace("# __GDSCRIPT_METHODS_INSERT__", method_insert.ToString());
    }

    public void Initialize(GeneratorInitializationContext context)
    {
        // 注册一个语法接收器，用于查找带有特定属性的类
        context.RegisterForSyntaxNotifications(() => new SyntaxReceiver());
    }

    private string csharpTemplate = "";
    private string csharpCompatibilityTemplate = "";
    private string gdscriptTemplate = "";

    private Dictionary<string, string> type2target = new Dictionary<string, string>();
    private HashSet<INamedTypeSymbol> toProcess = new HashSet<INamedTypeSymbol>();
    private HashSet<INamedTypeSymbol> processed = new HashSet<INamedTypeSymbol>();

    private void UpdateDict(Dictionary<string, object> dict, INamedTypeSymbol symbol, INamedTypeSymbol? endSymbol)
    {
        var methodsSet = new HashSet<string>();
        var methods = new List<IMethodSymbol>();
        var virtualMethods = new List<IMethodSymbol>();
        var overrideMethods = new List<IMethodSymbol>();
        var fields = new List<IFieldSymbol>();
        var properties = new List<IPropertySymbol>();
        var signals = new List<INamedTypeSymbol>();
        var current = symbol;
        INamedTypeSymbol? last = null;
        while (current is not null && !SymbolEqualityComparer.Default.Equals(current, endSymbol))
        {
            foreach(var method in current.GetMembers().OfType<IMethodSymbol>())
            {
                if (last is not null && last.FindImplementationForInterfaceMember(method) is not null)
                    continue;
                if (method.Name == ".ctor") continue;
                if (method.IsGenericMethod) continue;
                if (method.IsStatic) continue;
                if (methodBlacklist.Contains(method.Name)) continue;
                if (method.Name.StartsWith("set_") || method.Name.StartsWith("get_")
                        || method.Name.StartsWith("add_") || method.Name.StartsWith("remove_")) continue;
                if (methodsSet.Contains(method.Name)) continue;
                methodsSet.Add(method.Name);
                if (method.IsVirtual && method.Name.StartsWith("_")) 
                    overrideMethods.Add(method);
                else if (method.DeclaredAccessibility == Accessibility.Public && current.ContainingNamespace.Name != "Godot") methods.Add(method);
                if (method.IsOverride && method.Name.StartsWith("_")) overrideMethods.Add(method);
            }

            foreach(var field in current.GetMembers().OfType<IFieldSymbol>())
            {
                if (last is not null && last.FindImplementationForInterfaceMember(field) is not null)
                    continue;
                if (field.IsConst) continue;
                if (propertyBlacklist.Contains(field.Name)) continue;
                fields.Add(field);
            }

            foreach(var property in current.GetMembers().OfType<IPropertySymbol>())
            {
                if (last is not null && last.FindImplementationForInterfaceMember(property) is not null)
                    continue;
                if (property.Name == "NativeInstance") continue;
                if (propertyBlacklist.Contains(property.Name)) continue;
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
    }

    private void Process(GeneratorExecutionContext context, INamedTypeSymbol symbol, string targetName, out string classRef)
    {
        var current = symbol;
        while (current is not null)
        {
            current = current.BaseType;
            if (current is not null && toProcess.Contains(current))
            {
                Process(context, current, type2target[current.Name], out var a);
                break;
            }
        }
        var ns = symbol.ContainingNamespace.IsGlobalNamespace? "": symbol.ContainingNamespace.ToDisplayString()+".";
        classRef = "GDScriptAdapter_" + targetName;
        if (processed.Contains(symbol)) return;
        var dict = new Dictionary<String, Object>();
        dict["class"] = symbol;
        dict["targetName"] = targetName;
        dict["sourceNameOnly"] = symbol.Name;
        dict["sourceName"] = ns + symbol.Name;
        dict["type2target"] = type2target;

        UpdateDict(dict, symbol, context.Compilation.GetTypeByMetadataName("Godot.Object"));
        var generatedCode = ReplaceCSharp(csharpTemplate, dict);
        context.AddSource($"{symbol.Name}_GDScriptAdapter_{targetName}.g.cs", SourceText.From(generatedCode, Encoding.UTF8));
        
        /*
        var compatibilityTop = symbol;
        while (compatibilityTop is not null)
        {
            compatibilityTop = compatibilityTop.BaseType;
            if (compatibilityTop is not null && (toProcess.Contains(compatibilityTop) ||
                    compatibilityTop.ContainingNamespace.ToDisplayString() == "Godot"))
                break;
        }
        UpdateDict(dict, symbol, compatibilityTop);
        generatedCode = ReplaceCSharpCompatibility(csharpCompatibilityTemplate, dict);
        context.AddSource($"{symbol.Name}_GDScriptCompatibility_{targetName}.g.cs", SourceText.From(generatedCode, Encoding.UTF8));
        */

        UpdateDict(dict, symbol, current);
        if (current != null) dict["extends"] = type2target[current.Name];
        generatedCode = ReplaceGDScript(gdscriptTemplate, dict);
        GenerateFile(context, $"gdscript/{targetName}.gd", generatedCode);

        processed.Add(symbol);
    }

    public void Execute(GeneratorExecutionContext context)
    {
        if (context.SyntaxReceiver is not SyntaxReceiver receiver)
            return;

        foreach (var file in context.AdditionalFiles)
        {
            if (file.Path.EndsWith("gindustry.csproj"))
               projectBase = Path.GetDirectoryName(file.Path)!;
            if (file.Path.EndsWith("GDScriptAdapterTemplate.t.cs"))
                csharpTemplate = file.GetText(context.CancellationToken)!.ToString();
            if (file.Path.EndsWith("GDScriptCompatibilityTemplate.t.cs"))
                csharpCompatibilityTemplate = file.GetText(context.CancellationToken)!.ToString();
            if (file.Path.EndsWith("gdscript_adapter_template.t.gd"))
                gdscriptTemplate = file.GetText(context.CancellationToken)!.ToString();
        }

        csharpTemplate = csharpTemplate.Replace("# if NEVER", "").Replace("# endif", "");
        csharpCompatibilityTemplate = csharpCompatibilityTemplate.Replace("# if NEVER", "").Replace("# endif", "");
        
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
            type2target[ns + symbol.Name] = targetName;
            toProcess.Add(symbol);
        }

        var refs = new List<string>();

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
            Process(context, symbol, targetName, out var classRef);
            refs.Add(classRef);
        }

        var implement = string.Join("\n", refs.Select(x => $"        Gen.{x}._StaticInit();"));

        var sourceCode = $@"
public partial class GA
{{
    public partial void LoadStatics()
    {{
{implement}
    }}
}}
";
        context.AddSource("GDScriptAdapterImplement.cs", SourceText.From(sourceCode, Encoding.UTF8));
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

