using System;
using System.Text;

namespace Gen.Converters
{
    public class NameConverter
    {
        public string ToGDScriptName(string name)
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

        public bool NeedCompatibility(string name)
        {
            return name.ToLower() != name;
        }
    }
} 