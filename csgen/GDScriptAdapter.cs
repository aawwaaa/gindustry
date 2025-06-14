using System;
using System.Text;
using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.Text;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Gen.Converters;
using Gen.Template;
using Gen.Utils;
using Gen.Analysis;

namespace Gen 
{
    #region Core Module
    
    [Generator]
    public class GDScriptAdapterGenerator : ISourceGenerator
    {
        private readonly TemplateManager _templateManager;
        private readonly FileManager _fileManager;
        private readonly Gen.Analysis.SymbolAnalyzer _symbolAnalyzer;
        private readonly TypeConverter _typeConverter;
        private readonly NameConverter _nameConverter;
        private readonly MethodConverter _methodConverter;
        private readonly PropertyConverter _propertyConverter;
        private readonly SignalConverter _signalConverter;
        private readonly TemplateRenderer _templateRenderer;
        
        public GDScriptAdapterGenerator()
        {
            _templateManager = new TemplateManager();
            _fileManager = new FileManager();
            _typeConverter = new TypeConverter(new Dictionary<string, string>());
            _nameConverter = new NameConverter();
            _methodConverter = new MethodConverter(_typeConverter, _nameConverter);
            _propertyConverter = new PropertyConverter(_typeConverter, _nameConverter);
            _signalConverter = new SignalConverter(_typeConverter, _nameConverter);
            _templateRenderer = new TemplateRenderer(
                _typeConverter,
                _nameConverter,
                _methodConverter,
                _propertyConverter,
                _signalConverter
            );
            _symbolAnalyzer = new Gen.Analysis.SymbolAnalyzer(
                _typeConverter,
                _nameConverter,
                _methodConverter,
                _propertyConverter,
                _signalConverter,
                _templateRenderer,
                _fileManager,
                _templateManager
            );
        }

        public void Initialize(GeneratorInitializationContext context)
        {
            context.RegisterForSyntaxNotifications(() => new SyntaxReceiver());
        }

        public void Execute(GeneratorExecutionContext context)
        {
            if (context.SyntaxReceiver is not SyntaxReceiver receiver)
                return;

            // Initialize templates
            _templateManager.Initialize(context);
            
            // Set project base
            foreach (var file in context.AdditionalFiles)
            {
                if (file.Path.EndsWith("gindustry.csproj"))
                {
                    _fileManager.SetProjectBase(Path.GetDirectoryName(file.Path)!);
                    break;
                }
            }
            
            // Process each target class
            foreach (var pair in receiver.Targets)
            {
                ProcessTarget(context, pair.Key, pair.Value);
            }
        }

        private void ProcessTarget(GeneratorExecutionContext context, ClassDeclarationSyntax classDeclaration, AttributeSyntax attribute)
        {
            var model = context.Compilation.GetSemanticModel(classDeclaration.SyntaxTree);
            var symbol = model.GetDeclaredSymbol(classDeclaration);
            if (symbol is null || attribute is null)
                return;

            var targetName = GetTargetName(attribute);
            if (targetName is null)
                return;

            // Process the target class
            _symbolAnalyzer.ProcessSymbol(symbol, targetName, context);
        }

        private string? GetTargetName(AttributeSyntax attribute)
        {
            return attribute.ArgumentList?.Arguments.FirstOrDefault()?.GetText().ToString().Replace("\"", "");
        }
    }

    public class SyntaxReceiver : ISyntaxReceiver
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

    #endregion

    #region Template Module

    public class TemplateManager
    {
        private string _csharpTemplate = "";
        private string _csharpCompatibilityTemplate = "";
        private string _gdscriptTemplate = "";

        public void Initialize(GeneratorExecutionContext context)
        {
            foreach (var file in context.AdditionalFiles)
            {
                if (file.Path.EndsWith("GDScriptAdapterTemplate.t.cs"))
                    _csharpTemplate = file.GetText(context.CancellationToken)!.ToString();
                if (file.Path.EndsWith("GDScriptCompatibilityTemplate.t.cs"))
                    _csharpCompatibilityTemplate = file.GetText(context.CancellationToken)!.ToString();
                if (file.Path.EndsWith("gdscript_adapter_template.t.gd"))
                    _gdscriptTemplate = file.GetText(context.CancellationToken)!.ToString();
            }

            _csharpTemplate = _csharpTemplate.Replace("# if NEVER", "").Replace("# endif", "");
            _csharpCompatibilityTemplate = _csharpCompatibilityTemplate.Replace("# if NEVER", "").Replace("# endif", "");
        }

        public string GetCSharpTemplate() => _csharpTemplate;
        public string GetCSharpCompatibilityTemplate() => _csharpCompatibilityTemplate;
        public string GetGDScriptTemplate() => _gdscriptTemplate;
    }

    #endregion

    #region File Management Module

    public class FileManager
    {
        private string _projectBase = "";

        public void SetProjectBase(string path)
        {
            _projectBase = path;
        }

        public void Cleanup(string path)
        {
            path = Path.Combine(_projectBase, "gen", path);
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }

        public void GenerateFile(string path, string data)
        {
            var fullPath = Path.Combine(_projectBase, "gen", path);
            var dir = Path.GetDirectoryName(fullPath)!;
            if (!Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
            }
            File.WriteAllText(fullPath, data);
        }
    }

    #endregion

    #region Symbol Analysis Module

    public class SymbolAnalyzer
    {
        private readonly Dictionary<string, string> _type2target = new();
        private readonly HashSet<INamedTypeSymbol> _toProcess = new();
        private readonly HashSet<INamedTypeSymbol> _processed = new();

        public void ProcessSymbol(INamedTypeSymbol symbol, string targetName, GeneratorExecutionContext context)
        {
            // Implementation will be added in next step
        }
    }

    #endregion

    #region Configuration Module

    public class GeneratorConfig
    {
        public static readonly string[] MethodBlacklist = new string[] {
            "GetType",
            "_Get",
            "_Set",
            "_GetPropertyList",
            "_PropertyCanRevert",
            "_PropertyGetRevert",
            "_ValidateProperty",
        };

        public static readonly string[] PropertyBlacklist = new string[] {
            "_ImportPath",
        };
    }

    #endregion
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