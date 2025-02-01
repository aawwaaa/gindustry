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

