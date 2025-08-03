using Godot;
using System;
using System.Collections.Generic;

namespace Gindustry.IO;

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
    public T SV<T>() => Util.Serialization.Unserialize<T>(this);

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

    public I Iter<I, T>(Func<Reader, T> func) where I : ICollection<T>, new()
    {
        var count = U32();
        var list = new I();
        for (int i = 0; i < count; i++)
        {
            list.Add(func(this));
        }
        return list;
    }
    public void Iter<T>(ICollection<T> collection, Func<Reader, T> func)
    {
        var count = U32();
        for (int i = 0; i < count; i++)
        {
            collection.Add(func(this));
        }
    }
    public I Iter<I, K, V>(Func<Reader, KeyValuePair<K, V>> func) where I : IDictionary<K, V>, new()
    {
        var count = U32();
        var dict = new I();
        for (int i = 0; i < count; i++)
        {
            var pair = func(this);
            dict.Add(pair);
        }
        return dict;
    }
    public void Iter<K, V>(IDictionary<K, V> dictionary, Func<Reader, KeyValuePair<K, V>> func)
    {
        var count = U32();
        for (int i = 0; i < count; i++)
        {
            var pair = func(this);
            dictionary.Add(pair);
        }
    }
}

