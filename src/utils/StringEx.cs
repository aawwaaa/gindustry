using System;

public static class StringEx
{
    public static string Fmt(this string str, string key, string value)
    {
        return str.Replace($"{{{key}}}", value);
    }
}
