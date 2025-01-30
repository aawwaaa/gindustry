using Godot;
using System;
using System.IO;
using System.Collections.Generic;

[GlobalClass]
public partial class ByteArrayIO: GodotObject
{
    const int MAX_BUFFER_SIZE = 64 * 1024;

    public class BufferBlock
    {
        public byte[] buffer = new byte[MAX_BUFFER_SIZE];
        public int used = 0;
    }

    public class ByteArrayReaderImplement: ReaderImplement
    {
        public ByteArrayIO io;
        public ByteArrayReaderImplement(ByteArrayIO io)
        {
            this.io = io;
        }
        public void Skip(int size)
        {
            io.readIndex += size;
        }

        public void Read(int size, ref byte[] buffer)
        {
            Array.Copy(io.readBuffer, io.readIndex, buffer, 0, size);
            io.readIndex += size;
        }
    }

    public class ByteArrayWriterImplement: WriterImplement
    {
        public ByteArrayIO io;
        public ByteArrayWriterImplement(ByteArrayIO io)
        {
            this.io = io;
        }
        public void Write(int size, Span<byte> buffer)
        {
            if(io.writeBuffers.Count == 0 || io.writeBuffers[io.writeBuffers.Count - 1].used + size > MAX_BUFFER_SIZE)
            {
                io.writeBuffers.Add(new BufferBlock());
            }
            var block = io.writeBuffers[io.writeBuffers.Count - 1];
            Array.Copy(buffer.ToArray(), 0, block.buffer, block.used, size);
            block.used += size;
            io.writeIndex += size;
        }
    }

    public List<BufferBlock> writeBuffers = new List<BufferBlock>();
    public int writeIndex = 0;
    public byte[] readBuffer = new byte[0];
    public int readIndex = 0;

    public ByteArrayIO()
    {
    }

    public void Clear()
    {
        readBuffer = new byte[0];
        readIndex = 0;
        writeBuffers = new List<BufferBlock>();
        writeIndex = 0;
    }

    public byte[] DumpData()
    {
        var buffer = new byte[writeIndex];
        var index = 0;
        foreach(var block in writeBuffers)
        {
            Array.Copy(block.buffer, 0, buffer, index, block.used);
            index += block.used;
        }
        Clear();
        return buffer;
    }

    public void SetData(byte[] buffer)
    {
        Clear();
        readBuffer = buffer;
        readIndex = 0;
    }

    public Reader Reader()
    {
        return new Reader(new ByteArrayReaderImplement(this));
    }

    public Writer Writer()
    {
        return new Writer(new ByteArrayWriterImplement(this));
    }
}


