using Godot;
using System;

public interface ReaderImplement
{
    public void Skip(int size);
    public void Read(int size, ref byte[] buffer);
}

[GlobalClass]
public partial class Reader: GodotObject
{
    protected ReaderImplement implement;
    protected byte[] buffer = new byte[128];

    public Reader() {}
    public Reader(ReaderImplement implement)
    {
        this.implement = implement;
    }

    public void SetImplement(ReaderImplement implement)
    {
        this.implement = implement;
    }

    protected byte[] Read(int size)
    {
        implement.Read(size, ref buffer);
        return buffer;
    }

    public void Skip(int size) => implement.Skip(size);
    public void Buffer(int size, ref byte[] buffer) => implement.Read(size, ref buffer);
    public byte[] Buffer(int size)
    {
        var buffer = new byte[size];
        implement.Read(size, ref buffer);
        return buffer;
    }
    
    public byte[] MB()
    {
        var size = I32();
        var buffer = new byte[size];
        implement.Read(size, ref buffer);
        return buffer;
    }

    public byte B() => Read(1)[0];
    public sbyte SB() => (sbyte)Read(1)[0];
    public sbyte I8() => (sbyte)Read(1)[0];
    public byte U8() => Read(1)[0];

    public short I16() => BitConverter.ToInt16(Read(2), 0);
    public ushort U16() => BitConverter.ToUInt16(Read(2), 0);
    public int I32() => BitConverter.ToInt32(Read(4), 0);
    public uint U32() => BitConverter.ToUInt32(Read(4), 0);
    public long I64() => BitConverter.ToInt64(Read(8), 0);
    public ulong U64() => BitConverter.ToUInt64(Read(8), 0);

    public float F() => BitConverter.ToSingle(Read(4), 0);
    public double D() => BitConverter.ToDouble(Read(8), 0);
    public float F32() => BitConverter.ToSingle(Read(4), 0);
    public double F64() => BitConverter.ToDouble(Read(8), 0);

    public bool Z() => Read(1)[0] != 0;
    
    public string S() => System.Text.Encoding.UTF8.GetString(MB());

    public Variant V() => GD.BytesToVarWithObjects(MB());
    public T SV<T>() => Utils.Serialization.Unserialize<T>(this);

    public delegate void ReadDelegate(Reader reader);

    public void A(params ReadDelegate[] delegates)
    {
        var count = U8();
        if (count > delegates.Length) throw new Exception("Version too large! " + count + " > " + delegates.Length);
        for (int i = 0; i < count; i++)
        {
            delegates[i](this);
        }
    }
}

