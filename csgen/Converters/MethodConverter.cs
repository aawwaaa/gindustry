using System;
using System.Text;
using System.Linq;
using Microsoft.CodeAnalysis;

namespace Gen.Converters
{
    public class MethodConverter
    {
        private readonly TypeConverter _typeConverter;
        private readonly NameConverter _nameConverter;

        public MethodConverter(TypeConverter typeConverter, NameConverter nameConverter)
        {
            _typeConverter = typeConverter;
            _nameConverter = nameConverter;
        }

        public string ConvertMethod(IMethodSymbol method, bool isOverride = false)
        {
            var returns = method.ReturnsVoid ? "" : "return ";
            var defaultValue = _typeConverter.GetDefaultValue(_typeConverter.ToGDScriptType(method.ReturnType));
            var args = method.Parameters.Count() == 0 ? "" : 
                string.Join(", ", method.Parameters.Select(p => "_" + _nameConverter.ToGDScriptName(p.Name) + "_: " + 
                    _typeConverter.ToGDScriptType(p.Type)));

            if (isOverride)
            {
                return $@"
func {_nameConverter.ToGDScriptName(method.Name)}({args}) -> {_typeConverter.ToGDScriptType(method.ReturnType)}:
    GA.HaventOverriden(_instance);
    {returns}{defaultValue};
";
            }

            return $@"
func {_nameConverter.ToGDScriptName(method.Name)}({args}) -> {_typeConverter.ToGDScriptType(method.ReturnType)}:
    {returns}_instance.{method.Name}({string.Join(", ", method.Parameters.Select(p => "_" + _nameConverter.ToGDScriptName(p.Name) + "_"))});
";
        }

        public string ConvertVirtualMethod(IMethodSymbol method)
        {
            var returns = method.ReturnsVoid ? "" : "return ";
            var defaultValue = _typeConverter.GetDefaultValue(_typeConverter.ToGDScriptType(method.ReturnType));
            var args = string.Join(", ", method.Parameters.Select(p => "_" + 
                _nameConverter.ToGDScriptName(p.Name) + ": " + _typeConverter.ToGDScriptType(p.Type)));

            return $@"
func {_nameConverter.ToGDScriptName(method.Name)}({args}) -> {_typeConverter.ToGDScriptType(method.ReturnType)}:
    _instance._HaventOverriden{method.Name} = true;
    {returns}{defaultValue};
";
        }
    }
} 