using System;
using System.Text;
using System.Linq;
using Microsoft.CodeAnalysis;

namespace Gen.Converters
{
    public class SignalConverter
    {
        private readonly TypeConverter _typeConverter;
        private readonly NameConverter _nameConverter;

        public SignalConverter(TypeConverter typeConverter, NameConverter nameConverter)
        {
            _typeConverter = typeConverter;
            _nameConverter = nameConverter;
        }

        public string ConvertSignal(INamedTypeSymbol signal)
        {
            var name = signal.Name.Replace("EventHandler", "");
            var method = signal.DelegateInvokeMethod!;
            var signalName = _nameConverter.ToGDScriptName(name);
            var parameters = string.Join(", ", method.Parameters.Select(p => 
                _nameConverter.ToGDScriptName(p.Name) + ": " + _typeConverter.ToGDScriptType(p.Type)));

            return $@"
signal {signalName}({parameters});

func _signal_{name}({string.Join(", ", method.Parameters.Select(p => 
    p.Name + ": " + _typeConverter.ToGDScriptType(p.Type)))}):
    {signalName}.emit({string.Join(", ", method.Parameters.Select(p => p.Name))});
";
        }
    }
} 