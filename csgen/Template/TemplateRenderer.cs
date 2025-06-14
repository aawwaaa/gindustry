using System;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using Microsoft.CodeAnalysis;
using Gen.Converters;

namespace Gen.Template
{
    public class TemplateRenderer
    {
        private readonly TypeConverter _typeConverter;
        private readonly NameConverter _nameConverter;
        private readonly MethodConverter _methodConverter;
        private readonly PropertyConverter _propertyConverter;
        private readonly SignalConverter _signalConverter;

        public TemplateRenderer(
            TypeConverter typeConverter,
            NameConverter nameConverter,
            MethodConverter methodConverter,
            PropertyConverter propertyConverter,
            SignalConverter signalConverter)
        {
            _typeConverter = typeConverter;
            _nameConverter = nameConverter;
            _methodConverter = methodConverter;
            _propertyConverter = propertyConverter;
            _signalConverter = signalConverter;
        }

        public string RenderCSharpTemplate(string template, Dictionary<string, object> dict)
        {
            var signalInsert = new StringBuilder();
            foreach(var signal in (List<INamedTypeSymbol>)dict["signals"])
            {
                var name = signal.Name.Replace("EventHandler", "");
                signalInsert.Append($"Connect(_GetStringName(\"{name}\"), new Callable(adapter, _GetStringName(\"_signal_{name}\")));\n");
            }

            var overrideMethodInsert = new StringBuilder();
            foreach(var method in (List<IMethodSymbol>)dict["overrideMethods"])
            {
                var assign = method.ReturnsVoid ? "" : "var ret = (" + method.ReturnType + ")";
                var returns = method.ReturnsVoid ? "" : "return ";
                var returnsRet = method.ReturnsVoid ? "" : "return ret;";
                var args = method.Parameters.Count() == 0 ? "" : 
                    ", " + string.Join(", ", method.Parameters.Select(p => p.Name + "_"));

                overrideMethodInsert.Append($@"
public bool _HaventOverriden{method.Name} = false;
{method.DeclaredAccessibility.ToString().ToLower()} override {method.ReturnType} {method.Name}({string.Join(", ", 
    method.Parameters.Select(p => $"{p.Type} {p.Name}_"))})
{{
    IsOverriden = true;
    {assign}_Adapter.Call(_GetStringName({"\"" + _nameConverter.ToGDScriptName(method.Name) + "\""}){args});
    if (!IsOverriden) {{{returns}base.{method.Name}({string.Join(", ",
        method.Parameters.Select(p => p.Name + "_"))}); {(returns == "" ? "return;" : "")}}}
    {returnsRet}
}}
");
            }

            return Replace(template, dict)
                .Replace("// __CSHARP_SIGNAL_CONNECT_INSERT__", signalInsert.ToString())
                .Replace("// __CSHARP_OVERRIDE_METHODS_INSERT__", overrideMethodInsert.ToString());
        }

        public string RenderGDScriptTemplate(string template, Dictionary<string, object> dict)
        {
            var signalInsert = new StringBuilder();
            foreach(var signal in (List<INamedTypeSymbol>)dict["signals"])
            {
                signalInsert.Append(_signalConverter.ConvertSignal(signal));
            }

            var fieldInsert = new StringBuilder();
            foreach(var field in (List<IFieldSymbol>)dict["fields"])
            {
                fieldInsert.Append(_propertyConverter.ConvertField(field));
            }

            foreach(var property in (List<IPropertySymbol>)dict["properties"])
            {
                fieldInsert.Append(_propertyConverter.ConvertProperty(property));
            }

            var overrideMethodInsert = new StringBuilder();
            foreach(var method in (List<IMethodSymbol>)dict["overrideMethods"])
            {
                overrideMethodInsert.Append(_methodConverter.ConvertMethod(method, true));
            }

            var methodInsert = new StringBuilder();
            foreach(var method in (List<IMethodSymbol>)dict["methods"])
            {
                methodInsert.Append(_methodConverter.ConvertMethod(method));
            }

            if (dict.ContainsKey("extends"))
            {
                template = template.Replace("var _instance: __S_GDScriptAdapter__", "")
                    .Replace("Object", (string)dict["extends"]);
            }

            return Replace(template, dict)
                .Replace("# __GDSCRIPT_SIGNALS_INSERT__", signalInsert.ToString())
                .Replace("# __GDSCRIPT_FIELDS_INSERT__", fieldInsert.ToString())
                .Replace("# __GDSCRIPT_OVERRIDE_METHODS_INSERT__", overrideMethodInsert.ToString())
                .Replace("# __GDSCRIPT_METHODS_INSERT__", methodInsert.ToString());
        }

        private string Replace(string template, Dictionary<string, object> dict)
        {
            return template
                .Replace("__NS_GDScriptAdapter__", (string)dict["sourceName"])
                .Replace("__S_GDScriptAdapter__", (string)dict["sourceNameOnly"])
                .Replace("__GDScriptAdapter__", (string)dict["targetName"])
                .Replace("__GDScriptAdapter_N__", "GDScriptAdapter_" + (string)dict["targetName"]);
        }
    }
} 