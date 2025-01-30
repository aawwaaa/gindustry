using Godot;
using System;
using System.IO;

[GlobalClass]
public partial class FileIO: GodotObject
{
    public class FileStreamReaderImplement: ReaderImplement
    {
        public FileStream stream;
        public FileStreamReaderImplement(FileStream stream)
        {
            this.stream = stream;
        }
        public void Skip(int size)
        {
            stream.Seek(size, SeekOrigin.Current);
        }

        public void Read(int size, ref byte[] buffer)
        {
            stream.Read(buffer, 0, size);
            stream.Seek(size, SeekOrigin.Current);
        }
    }

    public class FileStreamWriterImplement: WriterImplement
    {
        public FileStream stream;
        public FileStreamWriterImplement(FileStream stream)
        {
            this.stream = stream;
        }
        public void Write(int size, Span<byte> buffer)
        {
            stream.Write(buffer.ToArray(), 0, size);
            stream.Seek(size, SeekOrigin.Current);
        }
    }

    public FileStream stream;

    public FileIO(string path, Godot.FileAccess.ModeFlags mode)
    {
        switch(mode)
        {
            case Godot.FileAccess.ModeFlags.Read:
                stream = File.Open(path, FileMode.Open, System.IO.FileAccess.Read);
                break;
            case Godot.FileAccess.ModeFlags.Write:
                stream = File.Open(path, FileMode.OpenOrCreate, System.IO.FileAccess.Write);
                break;
            case Godot.FileAccess.ModeFlags.ReadWrite:
                stream = File.Open(path, FileMode.OpenOrCreate, System.IO.FileAccess.ReadWrite);
                break;
        }
    }

    public Reader Reader()
    {
        return new Reader(new FileStreamReaderImplement(stream));
    }

    public Writer Writer()
    {
        return new Writer(new FileStreamWriterImplement(stream));
    }

    public void Close()
    {
        stream.Close();
    }
}


