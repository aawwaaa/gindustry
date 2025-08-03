using Godot;
using System;
using Gindustry.Utils;
using System.Collections.Generic;

namespace Gindustry.IO;

public interface WriterImplement
{
    public void Write(int size, Span<byte> buffer);
}

[GlobalClass]
public partial class Writer: GodotObject
{
    protected WriterImplement implement;
    protected byte[] buffer = new byte[128];

    public Writer() {}
    public Writer(WriterImplement implement)
    {
        this.implement = implement;
    }

    public void SetImplement(WriterImplement implement)
    {
        this.implement = implement;
    }

    public void Write(int size, Span<byte> buffer)
    {
        implement.Write(size, buffer);
    }

    public void Buffer(int size, Span<byte> buffer) => implement.Write(size, buffer);
    public void MB(Span<byte> buffer)
    {
        I32(buffer.Length);
        implement.Write(buffer.Length, buffer);
    }
    
    public void B(byte value) {buffer[0] = value; implement.Write(1, buffer); }
    public void SB(sbyte value) {buffer[0] = (byte)value; implement.Write(1, buffer); }
    public void I8(sbyte value) {buffer[0] = (byte)value; implement.Write(1, buffer); }
    public void U8(byte value) {buffer[0] = value; implement.Write(1, buffer); }

    public void I16(short value) => implement.Write(2, BitConverter.GetBytes(value));
    public void U16(ushort value) => implement.Write(2, BitConverter.GetBytes(value));
    public void I32(int value) => implement.Write(4, BitConverter.GetBytes(value));
    public void U32(uint value) => implement.Write(4, BitConverter.GetBytes(value));
    public void I64(long value) => implement.Write(8, BitConverter.GetBytes(value));
    public void U64(ulong value) => implement.Write(8, BitConverter.GetBytes(value));

    public void F(float value) => implement.Write(4, BitConverter.GetBytes(value));
    public void D(double value) => implement.Write(8, BitConverter.GetBytes(value));
    public void F32(float value) => implement.Write(4, BitConverter.GetBytes(value));
    public void F64(double value) => implement.Write(8, BitConverter.GetBytes(value));

    public void Z(bool value){buffer[0] = value? (byte)1 : (byte)0; implement.Write(1, buffer); }
    public void S(string value) => MB(System.Text.Encoding.UTF8.GetBytes(value));

    public void V(Variant value) => MB(GD.VarToBytes(value));
    public void SV(object value) => Util.Serialization.Serialize(this, value);

    public delegate void WriteDelegate(Writer writer);

    public void A(params WriteDelegate[] delegates)
    {
        U8((byte)delegates.Length);
        foreach (var d in delegates)
        {
            d(this);
        }
    }
    
    public void Iter<T>(ICollection<T> collection, Action<Writer, T> func)
    {
        U32((uint)collection.Count);
        foreach (var item in collection)
        {
            func(this, item);
        }
    }
    public void Iter<K, V>(IDictionary<K, V> dictionary, Action<Writer, K, V> func)
    {
        U32((uint)dictionary.Count);
        foreach (var item in dictionary)
        {
            func(this, item.Key, item.Value);
        }
    }
}

