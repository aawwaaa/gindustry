using Godot;
using System;
using System.IO;

/*
    数据保存/加载需求：
    1 保存/加载至文件（存档/读档） - 可流式处理
    2 网络数据传输（分块） - 部分流式处理
    3 网络数据同步（只更新部分） - 无法流式处理
*/

public interface Saveable
{
    public void _SaveData(Writer w);
    public void _LoadData(Reader r);

    public virtual void _SaveSyncData(Writer w) {}
    public virtual void _LoadSyncData(Reader r) {}
}

/*

public interface Reader
{
    void Skip(int size); void Buffer(int size, ref byte[] buffer); byte[] Buffer(int size);
    byte[] MB();
    byte B(); sbyte SB(); sbyte I8(); byte U8(); short I16(); ushort U16(); int I32(); uint U32(); long I64(); ulong U64();
    float F(); double D(); float F32(); double F64();
    bool Z(); string S(); Variant V(); Variant SV();
    void A(params ReadDelegate[] delegates);
}

public delegate void ReadDelegate(Reader reader);
public interface Writer
{
    void Write(int size, Span<byte> buffer); void Buffer(int size, Span<byte> buffer); void MB(Span<byte> buffer);
    void B(byte value); void SB(sbyte value); void I8(sbyte value); void U8(byte value); void I16(short value); void U16(ushort value); void I32(int value); void U32(uint value); void I64(long value); void U64(ulong value);
    void F(float value); void D(double value); void F32(float value); void F64(double value);
    void Z(bool value); void S(string value); void V(Variant value); void SV(Variant value);
    void A(params WriteDelegate[] delegates);
}

public delegate void WriteDelegate(Writer writer);
*/
