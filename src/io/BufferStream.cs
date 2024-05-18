using Godot;
using System;

public partial class BufferStream : GodotObject, IReadableStream, IWritableStream
{
    public long expandSize;

    private byte[] buffer;
    private long length;

    public BufferStream()
    {

    }
    public BufferStream(byte[] buffer)
    {
        this.buffer = buffer;
    }

    public byte[] Get()
    {
        Array.Resize(ref buffer, (int)length);
        return buffer;
    }

    public void Close() { }

    public void Flush() { }

    public void Seek(long offset)
    {
        Position = (ulong)((long)Position + offset);
    }

    public ulong Position
    {
        get; private set;
    }

    public byte[] Bytes(long length)
    {
        byte[] slice = new byte[length];
        Buffer.BlockCopy(buffer, (int)Position, slice, 0, (int)length);
        Seek(length);
        return slice;
    }

    public void Bytes(byte[] value)
    {
        if (Position + (ulong)value.Length > (ulong)buffer.Length)
        {
            Array.Resize(ref buffer, (int)(buffer.Length + expandSize));
        }
        value.CopyTo(buffer, (int)Position);
        Seek(value.Length);
        length += value.Length;
    }
}

public class PacketOutputStream : IWritableStream
{
    public ulong packetSize;

    public delegate void SendPacketCallback(byte[] packet, ulong validSize);
    public SendPacketCallback sendPacketCallback;

    public delegate void CloseStreamCallback();
    public CloseStreamCallback closeStreamCallback;

    public byte[] buffer;

    public ulong Position
    {
        get; private set;
    }

    public void Close()
    {
        Flush();
        if (closeStreamCallback != null) closeStreamCallback();
    }

    public void Flush()
    {
        if (Position == 0) return;
        sendPacketCallback(buffer, Position);
        Position = 0;
        buffer = new byte[packetSize];
    }

    public void Seek(long offset)
    {
        throw new NotImplementedException();
    }

    public void Bytes(byte[] value)
    {
        long current = 0;
        while (current < value.Length){
            long overflow = Math.Max(value.Length - (long)(packetSize - Position), 0);
            long validSize = value.Length - overflow;
            Array.Copy(value, current, buffer, (int)Position, (int)validSize);
            Position += (ulong)validSize;
            if (Position >= packetSize) Flush();
            current += validSize;
        }

    }
}
