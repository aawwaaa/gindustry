using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.Text;
using Gen.Converters;
using Gen.Template;
using Gen.Utils;

namespace Gen.Analysis
{
    public class SymbolAnalyzer
    {
        private readonly Dictionary<string, string> _type2target = new();
        private readonly HashSet<INamedTypeSymbol> _toProcess = new();
        private readonly HashSet<INamedTypeSymbol> _processed = new();
        private readonly TypeConverter _typeConverter;
        private readonly NameConverter _nameConverter;
        private readonly MethodConverter _methodConverter;
        private readonly PropertyConverter _propertyConverter;
        private readonly SignalConverter _signalConverter;
        private readonly TemplateRenderer _templateRenderer;
        private readonly FileManager _fileManager;
        private readonly TemplateManager _templateManager;

        public SymbolAnalyzer(
            TypeConverter typeConverter,
            NameConverter nameConverter,
            MethodConverter methodConverter,
            PropertyConverter propertyConverter,
            SignalConverter signalConverter,
            TemplateRenderer templateRenderer,
            FileManager fileManager,
            TemplateManager templateManager)
        {
            _typeConverter = typeConverter;
            _nameConverter = nameConverter;
            _methodConverter = methodConverter;
            _propertyConverter = propertyConverter;
            _signalConverter = signalConverter;
            _templateRenderer = templateRenderer;
            _fileManager = fileManager;
            _templateManager = templateManager;
        }

        public void ProcessSymbol(INamedTypeSymbol symbol, string targetName, GeneratorExecutionContext context)
        {
            var current = symbol;
            while (current is not null)
            {
                current = current.BaseType;
                if (current is not null && _toProcess.Contains(current))
                {
                    ProcessSymbol(current, _type2target[current.Name], context);
                    break;
                }
            }

            var ns = symbol.ContainingNamespace.IsGlobalNamespace ? "" : symbol.ContainingNamespace.ToDisplayString() + ".";
            var classRef = "GDScriptAdapter_" + targetName;
            if (_processed.Contains(symbol)) return;

            var dict = new Dictionary<string, object>();
            dict["class"] = symbol;
            dict["targetName"] = targetName;
            dict["sourceNameOnly"] = symbol.Name;
            dict["sourceName"] = ns + symbol.Name;
            dict["type2target"] = _type2target;

            UpdateDict(dict, symbol, context.Compilation.GetTypeByMetadataName("Godot.Object"));
            var generatedCode = _templateRenderer.RenderCSharpTemplate(_templateManager.GetCSharpTemplate(), dict);
            context.AddSource($"{symbol.Name}_GDScriptAdapter_{targetName}.g.cs", SourceText.From(generatedCode, Encoding.UTF8));

            UpdateDict(dict, symbol, current);
            if (current != null) dict["extends"] = _type2target[current.Name];
            generatedCode = _templateRenderer.RenderGDScriptTemplate(_templateManager.GetGDScriptTemplate(), dict);
            _fileManager.GenerateFile($"gdscript/{targetName}.gd", generatedCode);

            _processed.Add(symbol);
        }

        private void UpdateDict(Dictionary<string, object> dict, INamedTypeSymbol symbol, INamedTypeSymbol? endSymbol)
        {
            var methodsSet = new HashSet<string>();
            var methods = new List<IMethodSymbol>();
            var virtualMethods = new List<IMethodSymbol>();
            var overrideMethods = new List<IMethodSymbol>();
            var fields = new List<IFieldSymbol>();
            var properties = new List<IPropertySymbol>();
            var signals = new List<INamedTypeSymbol>();
            IMethodSymbol? constructor = null;
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
                    if (GeneratorConfig.MethodBlacklist.Contains(method.Name)) continue;
                    if (method.Name.StartsWith("set_") || method.Name.StartsWith("get_")
                            || method.Name.StartsWith("add_") || method.Name.StartsWith("remove_")) continue;
                    if (methodsSet.Contains(method.Name)) continue;
                    methodsSet.Add(method.Name);
                    if (method.IsVirtual && method.Name.StartsWith("_")) 
                        overrideMethods.Add(method);
                    else if (method.IsOverride && method.Name.StartsWith("_")) 
                        overrideMethods.Add(method);
                    else if (method.DeclaredAccessibility == Accessibility.Public && current.ContainingNamespace.Name != "Godot") 
                        methods.Add(method);
                }

                foreach(var field in current.GetMembers().OfType<IFieldSymbol>())
                {
                    if (last is not null && last.FindImplementationForInterfaceMember(field) is not null)
                        continue;
                    if (field.IsConst) continue;
                    if (field.Name.EndsWith("__BackingField")) continue;
                    if (GeneratorConfig.PropertyBlacklist.Contains(field.Name)) continue;
                    fields.Add(field);
                }

                foreach(var property in current.GetMembers().OfType<IPropertySymbol>())
                {
                    if (last is not null && last.FindImplementationForInterfaceMember(property) is not null)
                        continue;
                    if (property.Name == "NativeInstance") continue;
                    if (property.Name.EndsWith("__BackingField")) continue;
                    if (GeneratorConfig.PropertyBlacklist.Contains(property.Name)) continue;
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
            if (constructor is not null)
                dict["constructor"] = constructor;
        }
    }
} 