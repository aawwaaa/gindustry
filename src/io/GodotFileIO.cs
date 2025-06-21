using Godot;
using System;

namespace Gindustry.IO;

[GlobalClass]
public partial class GodotFileIO: GodotObject
{
    public class FileAccessReaderImplement: ReaderImplement
    {
        public FileAccess access;
        public FileAccessReaderImplement(FileAccess access)
        {
            this.access = access;
        }
        public void Skip(int size)
        {
            if (size < 0) throw new Exception("Cannot skip " + size + " bytes");
            access.Seek((ulong)size);
        }

        public void Read(int size, ref byte[] buffer)
        {
            access.GetBuffer(size).CopyTo(buffer, 0);
        }
    }

    public class FileAccessWriterImplement: WriterImplement
    {
        public FileAccess access;
        public FileAccessWriterImplement(FileAccess access)
        {
            this.access = access;
        }
        public void Write(int size, Span<byte> buffer)
        {
            access.StoreBuffer(buffer.Slice(0, size).ToArray());
        }
    }

    public FileAccess access;

    public GodotFileIO(string path, Godot.FileAccess.ModeFlags mode)
    {
        access = FileAccess.Open(path, mode);
        if (access == null)
            throw new Exception("Cannot open file " + path + " :" + FileAccess.GetOpenError());
    }

    public Reader Reader()
    {
        return new Reader(new FileAccessReaderImplement(access));
    }

    public Writer Writer()
    {
        return new Writer(new FileAccessWriterImplement(access));
    }

    public void Close()
    {
        access.Close();
    }
}


