using Godot;
using System;

public interface ReadableStream
{
    void Close();
    void Seek(long offset);
    abstract ulong Position{get; }


    byte[] Bytes(long length);

    // TODO object Object();
}

public static class ReadableStreamEx
{
    public static ReadableStream Read(this ReadableStream stream)
    {
        return stream;
    }
    public static byte Byte(this ReadableStream stream)
    {
        return stream.Bytes(1)[0];
    }
    public static sbyte ByteSigned(this ReadableStream stream)
    {
        byte value = stream.Byte();
        if ((value & 0x80) != 0) return (sbyte)(value - 0x100);
        else return (sbyte)value;
    }
    public static short Short(this ReadableStream stream)
    {
        return BitConverter.ToInt16(stream.Bytes(2), 0);
    }
    public static ushort ShortUnsigned(this ReadableStream stream)
    {
        return BitConverter.ToUInt16(stream.Bytes(2), 0);
    }
    public static int Int(this ReadableStream stream)
    {
        return BitConverter.ToInt32(stream.Bytes(4), 0);
    }
    public static uint IntUnsigned(this ReadableStream stream)
    {
        return BitConverter.ToUInt32(stream.Bytes(4), 0);
    }
    public static long Long(this ReadableStream stream)
    {
        return BitConverter.ToInt64(stream.Bytes(8), 0);
    }
    public static ulong LongUnsigned(this ReadableStream stream)
    {
        return BitConverter.ToUInt64(stream.Bytes(8), 0);
    }

    public static float Float(this ReadableStream stream)
    {
        return BitConverter.ToSingle(stream.Bytes(4), 0);
    }
    public static double Double(this ReadableStream stream)
    {
        return BitConverter.ToSingle(stream.Bytes(8), 0);
    }

    public static bool Bool(this ReadableStream stream)
    {
        return stream.Byte() != 0;
    }

    public static string String(this ReadableStream stream)
    {
        long length = stream.Long();
        byte[] buffer = stream.Bytes(length);
        return System.Text.Encoding.UTF8.GetString(buffer, 0, (int)length);
    }
}

public interface WriteableStream
{
    void Close();
    void Flush();
    void Seek(long offset);
    abstract ulong Position{get; }

    virtual WriteableStream Write
    {
        get{ return this; }
    }

    void Bytes(byte[] value);

    // TODO void Object(object value);
}

public static class WriteableStreamEx
{
    public static WriteableStream Write(this WriteableStream stream)
    {
        return stream;
    }

    public static void Byte(this WriteableStream stream, byte value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void ByteSigned(this WriteableStream stream, sbyte value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Short(this WriteableStream stream, short value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void ShortUnsigned(this WriteableStream stream, ushort value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Int(this WriteableStream stream, int value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void IntUnsigned(this WriteableStream stream, uint value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Long(this WriteableStream stream, long value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void LongUnsigned(this WriteableStream stream, ulong value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }

    public static void Float(this WriteableStream stream, float value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Double(this WriteableStream stream, double value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }

    public static void String(this WriteableStream stream, string value)
    {
        stream.Long(value.Length);
        byte[] buffer = System.Text.Encoding.UTF8.GetBytes(value);
        stream.Bytes(buffer);
    }
    public static void Bool(this WriteableStream stream, bool value)
    {
        stream.Byte(value? (byte)1: (byte)0);
    }
}
