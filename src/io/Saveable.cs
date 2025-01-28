using System.IO;


/*
    数据保存/加载需求：
    1 保存/加载至文件（存档/读档） - 可流式处理
    2 网络数据传输（分块） - 部分流式处理
    3 网络数据同步（只更新部分） - 无法流式处理
*/

public interface Saveable
{
    void SaveData(StreamWriter writer);
    void LoadData(StreamReader reader);
}
