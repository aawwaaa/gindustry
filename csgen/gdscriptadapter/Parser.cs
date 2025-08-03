using Microsoft.CodeAnalysis;
using System.Reflection.Metadata;
using System.Text;

namespace Gindustry.Generator.GDScriptAdapter;

internal class ParserResult
{
    public Dictionary<string, Parser.FileContent> FileContents = [];
    public ParserResult() { }
}

internal class Parser
{
    public static List<string> IgnoredMethods = [
        "HasGodotClassSignal",
        "InvokeGodotClassMethod",
        "HasGodotClassMethod",
        "GetGodotClassPropertyValue",
        "SetGodotClassPropertyValue",
    ];
    public static List<string> IgnoredProperties = [];
    public static List<string> IgnoredSignals = [];
    public static Dictionary<string, string> RenamedTypes = new() {
        ["GodotObject"] = "Object",
        ["Rid"] = "RID",
        ["MultiplayerApi"] = "MultiplayerAPI",
        ["Vector2I"] = "Vector2i",
        ["Vector3I"] = "Vector3i",
        ["Vector4I"] = "Vector4i",
    };

    public struct FileContent
    {
        public string ClassName = "";
        public string FullName = "";
        public string TargetName = "";
        public string BaseClassTargetName = "";
        public string BaseClassFullName = "";
        public List<Method> Methods = [];
        internal HashSet<string> ExistedMemberSet = [];
        public List<Method> VirtualMethods = [];
        public List<Property> Properties = [];
        public List<Method> Constructors = [];
        public List<Signal> Signals = [];
        public List<string> Comments = [];
        public FileContent() {}

        public struct Type {
            public Dictionary<string, string> Data;
            public Type() {
                Data = [];
            }
            public readonly string For(string key) {
                if (Data.TryGetValue(key, out var value))
                    return value;
                return Data.FirstOrDefault().Value;
            }
        }
        public struct Property {
            public string Name = "";
            public Type Type = new();
            public bool Assignable = false;
            public Property() { }
        }
        public struct Method {
            public string Name = "";
            public string Accessibility = "";
            public Type ReturnType = new();
            public Property[] Parameters = [];
            public bool Owned = true;
            public Method() { }
        }
        public struct Signal {
            public string Name = "";
            public bool Owned = true;
            public Property[] Parameters = [];
            public Signal() { }
        }
    }

    public static GeneratorExecutionContext Context {get; set; }

    public static void Init(GeneratorExecutionContext context, FileStream? logFile)
    {
        Context = context;
        LogFile = logFile;
        Log(" --- Parser.Init --- ");
        AnaylsisResult = default;
    }

    public static void Reset()
    {
        Log(" --- Parser.Reset --- ");
        LogFile = null;
        AnaylsisResult = default;
    }

    static FileStream? LogFile;
    public static void Log(params object[] messages)
    {
        LogFile?.Write(Encoding.UTF8.GetBytes(string.Join(" ", messages) + "\n"));
        LogFile?.Flush();
    }

    private static AnaylsisResult AnaylsisResult;
    private static Dictionary<string, FileContent> ParsedResults = new();

    /// <summary>
    /// 获取基于继承依赖的解析顺序，确保基类先于派生类被解析
    /// </summary>
    private static List<string> GetSortedParsingOrder(AnaylsisResult anaylsisResult)
    {
        var visited = new HashSet<string>();
        var result = new List<string>();
        
        void Visit(string className)
        {
            if (visited.Contains(className))
                return;
                
            visited.Add(className);
            
            // 先访问基类
            if (anaylsisResult.Infos.TryGetValue(className, out var info))
            {
                if (!string.IsNullOrEmpty(info.BaseInfo) && anaylsisResult.Infos.ContainsKey(info.BaseInfo))
                {
                    Visit(info.BaseInfo);
                }
            }
            
            result.Add(className);
        }
        
        // 访问所有类，确保基类先于派生类
        foreach (var className in anaylsisResult.Infos.Keys)
        {
            Visit(className);
        }
        
        return result;
    }

    public static ParserResult Execute(AnaylsisResult anaylsisResult){
        var result = new ParserResult();
        AnaylsisResult = anaylsisResult;
        ParsedResults.Clear();
        
        // 使用基于继承依赖的排序顺序解析
        var sortedOrder = GetSortedParsingOrder(anaylsisResult);
        foreach (var className in sortedOrder) {
            Log("Parse:", className);
            var fileContent = Parse(anaylsisResult.Infos[className]);
            ParsedResults[className] = fileContent;
        }
        result.FileContents = ParsedResults;
        
        return result;
    }

    private static FileContent Parse(Anaylsis.AnaylsisInfo info)
    {
        var fileContent = new FileContent();
        Basic(info, ref fileContent);
        Methods(info, ref fileContent);
        Properties(info, ref fileContent);
        Signals(info, ref fileContent);
        return fileContent;
    }

    private static void Basic(Anaylsis.AnaylsisInfo info, ref FileContent fileContent)
    {
        fileContent.ClassName = info.Symbol.Name;
        fileContent.FullName = info.FullName;
        fileContent.TargetName = info.TargetName;
        Anaylsis.AnaylsisInfo? baseInfo = info.BaseInfo != "" ? AnaylsisResult.Infos[info.BaseInfo] : null;
        fileContent.BaseClassTargetName = baseInfo?.TargetName ?? "";
        fileContent.BaseClassFullName = baseInfo?.FullName ?? "";
    }

    private static string TypeString(ITypeSymbol type)
    {
        if (type == null)
        {
            return string.Empty;
        }

        var specialType = type.SpecialType switch
        {
            SpecialType.System_Void | SpecialType.None => "void",
            SpecialType.System_String => "string",
            SpecialType.System_Int32 => "int",
            SpecialType.System_Int64 => "long",
            SpecialType.System_Single => "float",
            SpecialType.System_Double => "double",
            SpecialType.System_Boolean => "bool",
            SpecialType.System_Object => "object",
            SpecialType.System_Char => "char",
            SpecialType.System_Byte => "byte",
            SpecialType.System_UInt32 => "uint",
            SpecialType.System_UInt64 => "ulong",
            SpecialType.System_Decimal => "decimal",
            SpecialType.System_Int16 => "short",
            SpecialType.System_UInt16 => "ushort",
            SpecialType.System_SByte => "sbyte",
            _ => null
        };
        if (specialType != null) return specialType;

        if (type is IArrayTypeSymbol arrayType)
            return $"{TypeString(arrayType.ElementType)}[]";

        var containingNamespace = type.ContainingNamespace;
        var name = type.Name;

        if (type is INamedTypeSymbol namedType && namedType.TypeArguments.Length > 0)
        {
            var typeArgs = string.Join(", ", namedType.TypeArguments.Select(TypeString));
            name += $"<{typeArgs}>";
        }

        if (containingNamespace == null || containingNamespace.IsGlobalNamespace)
        {
            return $"global::{name}";
        }

        return $"{containingNamespace.ToDisplayString()}.{name}";
    }
    private static string TypeStringGD(ITypeSymbol type)
    {
        if (type == null)
        {
            return string.Empty;
        }
        var specialType = type.SpecialType switch
        {
            SpecialType.System_Void | SpecialType.None => "void",
            SpecialType.System_String => "String",
            SpecialType.System_Int32 => "int",
            SpecialType.System_Int64 => "int",
            SpecialType.System_Single => "float",
            SpecialType.System_Double => "float",
            SpecialType.System_Boolean => "bool",
            SpecialType.System_Object => "Variant", // Godot Variant type
            SpecialType.System_Char => "String",
            SpecialType.System_Byte => "int",
            SpecialType.System_UInt32 => "int",
            SpecialType.System_UInt64 => "int",
            SpecialType.System_Decimal => "float",
            SpecialType.System_Int16 => "int",
            SpecialType.System_UInt16 => "int",
            SpecialType.System_SByte => "int",
            _ => string.Empty
        };
        if (specialType != string.Empty) return specialType;
        if (type is IArrayTypeSymbol arrayType)
            return $"Array[{TypeStringGD(arrayType.ElementType)}]";
        if (type.TypeKind == TypeKind.Enum)
            return "int";
        if (RenamedTypes.TryGetValue(type.Name, out var renamedType))
            return renamedType;
        if (type is ITypeParameterSymbol typeParameter){
            // 使用类型参数的约束（下界）作为返回类型，如果有约束则返回第一个约束，否则返回 "Variant"
            if (typeParameter.ConstraintTypes.Length > 0)
                return TypeStringGD(typeParameter.ConstraintTypes[0]);
            return "Variant";
        }
        return type.Name;
    }

    private static FileContent.Type Type(ITypeSymbol type) {
        return new() {
            Data = new() {
                ["cs"] = TypeString(type),
                ["gd"] = TypeStringGD(type),
            }
        };
    }

    private static ITypeSymbol? fail = null;

    private static bool Passable(params ITypeSymbol[] types) {
        foreach (var type in types) {
            fail = type;
            if (type.SpecialType is SpecialType.System_Void or SpecialType.System_String or SpecialType.System_Boolean
                or SpecialType.System_Int32 or SpecialType.System_Int64 or SpecialType.System_Single or SpecialType.System_Double
                or SpecialType.System_Char or SpecialType.System_Byte or SpecialType.System_UInt32 or SpecialType.System_UInt64
                or SpecialType.System_Decimal or SpecialType.System_Int16 or SpecialType.System_UInt16 or SpecialType.System_SByte) continue;
            if (type.ContainingNamespace?.ToString()?.StartsWith("Godot") ?? false) continue;
            if (type is INamedTypeSymbol namedType){
                var baseType = namedType;
                bool isAcceptable = false;
                while (baseType != null)
                {
                    if (baseType.Name == "Variant" || baseType.Name == "GodotObject")
                    {
                        isAcceptable = true;
                        break;
                    }
                    baseType = baseType.BaseType;
                }
                if (!isAcceptable)
                    return false;
            }
            if (type.TypeKind == TypeKind.TypeParameter)
                return false;
        }
        fail = null;
        return true;
    }
    
    private static void Methods(Anaylsis.AnaylsisInfo info, ref FileContent fileContent)
    {
        MethodsSymbol(info.Symbol, ref fileContent);
        foreach (var baseClass in info.BaseClasses) {
            MethodsSymbol(baseClass.Symbol, ref fileContent);
        }
        if (fileContent.Constructors.Count == 0) {
            fileContent.Constructors.Add(new FileContent.Method() {
                Name = "ctor",
                Accessibility = "public",
                ReturnType = Type(info.Symbol),
            });
        }
        // 如果有基类信息，则将基类的所有虚方法复制到当前类，owned=false
        if (!string.IsNullOrEmpty(info.BaseInfo) && ParsedResults.TryGetValue(info.BaseInfo, out var baseFileContent))
        {
            foreach (var baseVirtualMethod in baseFileContent.VirtualMethods)
            {
                // 检查当前类是否已存在同名虚方法，避免重复
                if (!fileContent.VirtualMethods.Any(m => m.Name == baseVirtualMethod.Name))
                {
                    var copiedMethod = baseVirtualMethod;
                    copiedMethod.Owned = false;
                    fileContent.VirtualMethods.Add(copiedMethod);
                }
            }
        }
    }

    private static void MethodsSymbol(INamedTypeSymbol symbol, ref FileContent fileContent)
    {
        foreach (var method in symbol.GetMembers().OfType<IMethodSymbol>()) {
            if (IgnoredMethods.Contains(method.Name)) continue;
            if (method.MethodKind != MethodKind.Ordinary && method.MethodKind != MethodKind.Constructor) continue;
            if (fileContent.ExistedMemberSet.Contains(method.Name)) continue;
            fileContent.ExistedMemberSet.Add(method.Name);
            if (!Passable(method.Parameters.Select(p => p.Type).ToArray())) {
                fileContent.Comments.Add($"IM {method} -> {method.ReturnType}");
                fileContent.Comments.Add($"    {fail}");
                continue;
            }
            if (!Passable(method.ReturnType)) {
                fileContent.Comments.Add($"IM {method} -> {method.ReturnType}");
                fileContent.Comments.Add($"    {fail}");
                continue;
            }
            var methodContent = new FileContent.Method
            {
                Name = method.Name,
                Accessibility = method.DeclaredAccessibility.ToString().ToLower(),
                ReturnType = Type(method.ReturnType),
                Parameters = [.. method.Parameters.Select(p => new FileContent.Property() {
                    Name = p.Name,
                    Type = Type(p.Type),
                })]
            };
            if (method.IsVirtual)
                fileContent.VirtualMethods.Add(methodContent);
            else if (method.MethodKind == MethodKind.Constructor)
                fileContent.Constructors.Add(methodContent);
            else if (method.IsOverride) {}
            else fileContent.Methods.Add(methodContent);
        }
    }

    private static void Properties(Anaylsis.AnaylsisInfo info, ref FileContent fileContent)
    {
        PropertiesSymbol(info.Symbol, ref fileContent);
        foreach (var baseClass in info.BaseClasses) {
            PropertiesSymbol(baseClass.Symbol, ref fileContent);
        }
        
        // 移除与基类重复的属性
        if (!string.IsNullOrEmpty(info.BaseInfo) && ParsedResults.TryGetValue(info.BaseInfo, out var baseFileContent))
        {
            var basePropertyNames = new HashSet<string>(baseFileContent.Properties.Select(p => p.Name));
            fileContent.Properties = fileContent.Properties
                .Where(p => !basePropertyNames.Contains(p.Name))
                .ToList();
        }
    }
    private static void PropertiesSymbol(INamedTypeSymbol symbol, ref FileContent fileContent)
    {
        foreach (var property in symbol.GetMembers().OfType<IPropertySymbol>()) {
            if (IgnoredProperties.Contains(property.Name)) continue;
            if (fileContent.ExistedMemberSet.Contains(property.Name)) continue;
            fileContent.ExistedMemberSet.Add(property.Name);
            if (!Passable(property.Type)) {
                fileContent.Comments.Add($"IP {property} -> {property.Type}");
                fileContent.Comments.Add($"    {fail}");
                continue;
            }
            var propertyContent = new FileContent.Property
            {
                Name = property.Name,
                Type = Type(property.Type),
                Assignable = property.DeclaredAccessibility == Accessibility.Public
            };
            fileContent.Properties.Add(propertyContent);
        }
    }

    private static void Signals(Anaylsis.AnaylsisInfo info, ref FileContent fileContent)
    {
        SignalsSymbol(info.Symbol, ref fileContent, true);
        foreach (var baseClass in info.BaseClasses) {
            SignalsSymbol(baseClass.Symbol, ref fileContent, true);
        }
        var current = info;
        while (current.BaseInfo != null && current.BaseInfo != "") {
            SignalsSymbol(current.Symbol, ref fileContent, false);
            foreach (var baseClass in current.BaseClasses) {
                SignalsSymbol(baseClass.Symbol, ref fileContent, false);
            }
            current = AnaylsisResult.Infos[current.BaseInfo];
        }
    }
    private static void SignalsSymbol(INamedTypeSymbol symbol, ref FileContent fileContent, bool owned)
    {
        foreach (var signal in symbol.GetMembers().OfType<IEventSymbol>()) {
            if (IgnoredSignals.Contains(signal.Name)) continue;
            if (fileContent.ExistedMemberSet.Contains(signal.Name)) continue;
            fileContent.ExistedMemberSet.Add(signal.Name);
            var signalContent = new FileContent.Signal
            {
                Name = signal.Name,
                Owned = owned
            };
            if (signal.Type is INamedTypeSymbol eventType && eventType.DelegateInvokeMethod != null)
            {
                signalContent.Parameters = eventType.DelegateInvokeMethod.Parameters
                    .Select(p => new FileContent.Property
                    {
                        Name = p.Name,
                        Type = Type(p.Type),
                    })
                    .ToArray();
            }
            fileContent.Signals.Add(signalContent);
        }
    }
}