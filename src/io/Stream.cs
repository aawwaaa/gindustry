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
        return BitConverter.ToDouble(stream.Bytes(8), 0);
    }

    public static bool Bool(this ReadableStream stream)
    {
        return stream.Byte() != 0;
    }

    public static string String(this ReadableStream stream)
    {
        int length = stream.Int();
        byte[] buffer = stream.Bytes(length);
        return System.Text.Encoding.UTF8.GetString(buffer, 0, length);
    }
}

public interface WritableStream
{
    void Close();
    void Flush();
    void Seek(long offset);
    abstract ulong Position{get; }

    virtual WritableStream Write
    {
        get{ return this; }
    }

    void Bytes(byte[] value);

    // TODO void Object(object value);
}

public static class WritebleStreamEx
{
    public static WritableStream Write(this WritableStream stream)
    {
        return stream;
    }

    public static void Byte(this WritableStream stream, byte value)
    {
        stream.Bytes(new byte[]{value});
    }
    public static void ByteSigned(this WritableStream stream, sbyte value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Short(this WritableStream stream, short value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void ShortUnsigned(this WritableStream stream, ushort value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Int(this WritableStream stream, int value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void IntUnsigned(this WritableStream stream, uint value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Long(this WritableStream stream, long value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void LongUnsigned(this WritableStream stream, ulong value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }

    public static void Float(this WritableStream stream, float value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }
    public static void Double(this WritableStream stream, double value)
    {
        stream.Bytes(BitConverter.GetBytes(value));
    }

    public static void String(this WritableStream stream, string value)
    {
        stream.Int(value.Length);
        byte[] buffer = System.Text.Encoding.UTF8.GetBytes(value);
        stream.Bytes(buffer);
    }
    public static void Bool(this WritableStream stream, bool value)
    {
        stream.Byte(value? (byte)1: (byte)0);
    }
}
