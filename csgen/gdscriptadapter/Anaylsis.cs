using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using System.Text;

namespace Gindustry.Generator.GDScriptAdapter;

internal struct AnaylsisResult
{
    public Dictionary<string, Anaylsis.AnaylsisInfo> Infos = [];

    public AnaylsisResult() { }
}

internal class Anaylsis
{
    public static List<string> StopBaseClasses = [
        "Godot.GodotObject",
    ];

    internal struct AnaylsisInfo
    {
        public string FullName = "";
        public ClassDeclarationSyntax Declaration = null!;
        public SemanticModel Model = null!;
        public INamedTypeSymbol Symbol = null!;
        public string BaseClass = "";
        public string TargetName = "";
        public bool IsTarget => TargetName != null && TargetName != "";
        public List<AnaylsisInfo> BaseClasses = [];
        public string BaseInfo = "";
        public AnaylsisInfo() {}
    }

    public static GeneratorExecutionContext Context {get; private set; }

    static Dictionary<string, AnaylsisInfo> Infos = new();
    public static void Init(GeneratorExecutionContext context, FileStream? logFile)
    {
        Context = context;
        Infos.Clear();
        LogFile = logFile;
        Log(" --- Anaylsis.Init --- ");
    }
    public static void Reset() {
        Log(" --- Anaylsis.Reset --- ");
        Infos.Clear();
        LogFile = null;
    }

    static FileStream? LogFile;
    public static void Log(params object[] messages)
    {
        LogFile?.Write(Encoding.UTF8.GetBytes(string.Join(" ", messages) + "\n"));
        LogFile?.Flush();
    }

    private static string GetSymbolFullName(ISymbol symbol)
    {
        if (symbol.ContainingNamespace.IsGlobalNamespace)
        {
            return "global::" + symbol.Name;
        }
        return symbol.ContainingNamespace.ToString() + "." + symbol.Name;
    }
    internal static AnaylsisInfo AddSource(ClassDeclarationSyntax declaration, string targetName)
    {
        var model = Context.Compilation.GetSemanticModel(declaration.SyntaxTree);
        var symbol = (INamedTypeSymbol)model.GetDeclaredSymbol(declaration)!;
        var info = new AnaylsisInfo()
        {
            FullName = GetSymbolFullName(symbol),
            Declaration = declaration,
            Model = model,
            TargetName = targetName,
            BaseClass = GetSymbolFullName(symbol.BaseType!),
            BaseClasses = new List<AnaylsisInfo>(),
            Symbol = symbol,
        };
        Infos[info.FullName] = info;
        Log("AddSource:", info.FullName);
        return info;
    }

    private static bool SolveBaseClass(AnaylsisInfo info)
    {
        if (StopBaseClasses.Contains(info.BaseClass)) {
            return false;
        }
        if (!Infos.ContainsKey(info.BaseClass)){
            var symbol = Context.Compilation.GetTypeByMetadataName(info.BaseClass);
            if (symbol == null)
            {
                Log("SolveBaseClass: not found", info.BaseClass);
                return false; // fail
            }
            var newInfo = new AnaylsisInfo() {
                FullName = GetSymbolFullName(symbol),
                Declaration = (ClassDeclarationSyntax)symbol.DeclaringSyntaxReferences.FirstOrDefault()?.GetSyntax()!,
                BaseClass = symbol.BaseType != null ? GetSymbolFullName(symbol.BaseType) : null!,
                BaseClasses = new List<AnaylsisInfo>(),
                Symbol = symbol,
            };
            Infos[newInfo.FullName] = newInfo;
            if (symbol.BaseType != null) {
                Log("SolveBaseClass:", newInfo.FullName);
                SolveBaseClass(newInfo); // prepare base class
            }
        }
        if (!info.IsTarget)
            return true;
        var baseInfo = Infos[info.BaseClass];
        Log("Bind:", info.FullName);
        while (!baseInfo.IsTarget) {
            Log(" <-", baseInfo.FullName);
            info.BaseClasses.Add(baseInfo);
            if (baseInfo.BaseClass == null)
                break;
            if (!Infos.ContainsKey(baseInfo.BaseClass) && !SolveBaseClass(baseInfo)) {
                break;
            }
            baseInfo = Infos[baseInfo.BaseClass];
        }
        if (baseInfo.IsTarget) {
            Log(" ->", baseInfo.FullName);
            info.BaseInfo = baseInfo.FullName;
        }
        Infos[info.FullName] = info;
        return true;
    }

    internal static void SolveBaseClasses()
    {
        foreach (var info in Infos.Values.ToList()) {
            SolveBaseClass(info);
        }
    }

    internal static AnaylsisResult Execute()
    {
        var result = new AnaylsisResult
        {
            Infos = Infos.Where(i => i.Value.IsTarget).ToDictionary()
        };
        return result;
    }
}