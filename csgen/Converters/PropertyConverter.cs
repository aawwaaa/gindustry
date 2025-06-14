using System;
using System.Text;
using Microsoft.CodeAnalysis;

namespace Gen.Converters
{
    public class PropertyConverter
    {
        private readonly TypeConverter _typeConverter;
        private readonly NameConverter _nameConverter;

        public PropertyConverter(TypeConverter typeConverter, NameConverter nameConverter)
        {
            _typeConverter = typeConverter;
            _nameConverter = nameConverter;
        }

        public string ConvertProperty(IPropertySymbol property)
        {
            var type = _typeConverter.ToGDScriptType(property.Type);
            var name = _nameConverter.ToGDScriptName(property.Name);
            var getter = property.GetMethod != null ? "get: return _instance." + property.Name + ";" : "";
            var setter = property.SetMethod != null && property.SetMethod.DeclaredAccessibility == Accessibility.Public ? 
                "set(value): _instance." + property.Name + " = value;" : "";

            return $@"
var {name}: {type}:
    {getter}
    {setter}
";
        }

        public string ConvertField(IFieldSymbol field)
        {
            var type = _typeConverter.ToGDScriptType(field.Type);
            var name = _nameConverter.ToGDScriptName(field.Name);

            return $@"
var {name}: {type}:
    get: return _instance.{field.Name};
    set(value): _instance.{field.Name} = value;
";
        }
    }
} 