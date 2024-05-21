using Godot;
using System;

public class FileStream: ReadableStream, WriteableStream
{
    private FileAccess access;

    public FileStream(FileAccess access) {
        this.access = access;
    }

    public virtual void Close() {
        access.Close();
    }

    public virtual void Flush() {
        access.Flush();
    }

    public virtual void Seek(long offset){
        access.Seek((ulong)((long)Position + offset));
    }

    public virtual ulong Position
    {
        get{ return access.GetPosition(); }
    }

    public virtual byte[] Bytes(long length)
    {
        return access.GetBuffer(length);
    }
    public virtual byte Byte()
    {
        return access.Get8();
    }
    public virtual ushort ShortUnsigned()
    {
        return access.Get16();
    }
    public virtual uint IntUnsigned()
    {
        return access.Get32();
    }
    public virtual ulong LongUnsigned()
    {
        return access.Get64();
    }

    public virtual float Float()
    {
        return access.GetFloat();
    }
    public virtual double Double()
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
