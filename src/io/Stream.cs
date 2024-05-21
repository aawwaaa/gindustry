using Godot;
using System;

public interface IReadableStream
{
    void Close();
    void Seek(long offset);
    ulong Position{get; }


    byte[] Bytes(long length);

    // TODO object Object();
}

public static class IReadableStreamEx
{
    public static IReadableStream Read(this IReadableStream stream)
    {
        return stream;
    }
    public static byte Byte(this IReadableStream stream)
    {
        return stream.Bytes(1)[0];
    }
    public static sbyte ByteSigned(this IReadableStream stream)
    {
        byte value = stream.Byte();
        if ((value & 0x80) != 0) return (sbyte)(value - 0x100);
        else return (sbyte)value;
    }
    public static short Short(this IReadableStream stream)
    {
        return BitConverter.ToInt16(stream.Bytes(2), 0);
    }
    public static ushort ShortUnsigned(this IReadableStream stream)
    {
        return BitConverter.ToUInt16(stream.Bytes(2), 0);
    }
    public static int Int(this IReadableStream stream)
    {
        return BitConverter.ToInt32(stream.Bytes(4), 0);
    }
    public static uint IntUnsigned(this IReadableStream stream)
    {
        return BitConverter.ToUInt32(stream.Bytes(4), 0);
    }
    public static long Long(this IReadableStream stream)
    {
        return BitConverter.ToInt64(stream.Bytes(8), 0);
    }
    public static ulong LongUnsigned(this IReadableStream stream)
    {
        return BitConverter.ToUInt64(stream.Bytes(8), 0);
    }

    public static float Float(this IReadableStream stream)
    {
        return BitConverter.ToSingle(stream.Bytes(4), 0);
    }
    public static double Double(this IReadableStream stream)
    {
        return BitConverter.ToDouble(stream.Bytes(8), 0);
    }

    public static bool Bool(this IReadableStream stream)
    {
        return stream.Byte() != 0;
    }

    public static string String(this IReadableStream stream)
    {
        int length = stream.Int();
        byte[] buffer = stream.Bytes(length);
        return System.Text.Encoding.UTF8.GetString(buffer, 0, length);
    }
}

public interface IWritableStream
{
    void Close();
    void Flush();
    void Seek(long offset);
    ulong Position{get; }

    virtual IWritableStream Write
    {
        get{ return this; }
    }

    void Bytes(byte[] value);

    // TODO void Object(object value);
}

public static class IWritableStreamEx
{
    public static IWritableStream Write(this IWritableStream stream)
    {
        return stream;
    }

    public static void Byte(this IWritableStream stream, byte value)
    {
        stream.Bytes(new byte[]{value});
    }
    public static void ByteSigned(this IWritableStream stream, sbyte value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Short(this IWritableStream stream, short value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void ShortUnsigned(this IWritableStream stream, ushort value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Int(this IWritableStream stream, int value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void IntUnsigned(this IWritableStream stream, uint value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Long(this IWritableStream stream, long value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void LongUnsigned(this IWritableStream stream, ulong value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }

    public static void Float(this IWritableStream stream, float value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Double(this IWritableStream stream, double value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }

    public static void String(this IWritableStream stream, string value)
    {
        stream.Int(value.Length);
        byte[] buffer = System.Text.Encoding.UTF8.GetBytes(value);
        stream.Bytes(buffer);
    }
    public static void Bool(this IWritableStream stream, bool value)
    {
        stream.Byte(value? (byte)1: (byte)0);
    }
}
