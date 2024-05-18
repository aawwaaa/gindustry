using Godot;
using System;

public partial class FileStream : GodotObject, IReadableStream, IWritableStream
{
    private FileAccess access;

    public FileStream(FileAccess access) {
        this.access = access;
    }

    public void Close() {
        access.Close();
    }

    public void Flush() {
        access.Flush();
    }

    public void Seek(long offset){
        access.Seek((ulong)((long)Position + offset));
    }

    public ulong Position
    {
        get{ return access.GetPosition(); }
    }

    public byte[] Bytes(long length)
    {
        return access.GetBuffer(length);
    }
    public byte Byte()
    {
        return access.Get8();
    }
    public ushort ShortUnsigned()
    {
        return access.Get16();
    }
    public uint IntUnsigned()
    {
        return access.Get32();
    }
    public ulong LongUnsigned()
    {
        return access.Get64();
    }

    public float Float()
    {
        return access.GetFloat();
    }
    public double Double()
    {
        return access.GetDouble();
    }

    public void Bytes(byte[] value)
    {
        access.StoreBuffer(value);
    }
    public void Byte(byte value)
    {
        access.Store8(value);
    }
    public void ShortUnsigned(ushort value)
    {
        access.Store16(value);
    }
    public void IntUnsigned(uint value)
    {
        access.Store32(value);
    }
    public void LongUnsigned(ulong value)
    {
        access.Store64(value);
    }

    public void Float(float value)
    {
        access.StoreFloat(value);
    }
    public void Double(double value)
    {
        access.StoreDouble(value);
    }

}
