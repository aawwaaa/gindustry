using System;
using Gindustry.Attributes;
using Gindustry.Entities;
using Gindustry.Entities.Type.Base;
using Gindustry.IO;
using Godot;
using static Gindustry.World.LoadController;

namespace Gindustry.World.Mesh;

[GlobalClass]
public partial class MeshChunk : SubEntity
{
    public const uint ChunkMeshSize = 64;
    public const float MeshUnitSize = 0.5f;
    public const uint PlaceholderShapeMeshSize = 16;
    public const float PlaceholderShapeSize = PlaceholderShapeMeshSize * MeshUnitSize;
    public const float ChunkSize = ChunkMeshSize * MeshUnitSize;

    public ChunkLoadLevel LoadLevel { get; set; } = ChunkLoadLevel.None;

    public PlaceholderData? placeholderData = null;
    public ChunkData? chunkData = null;

    /// <summary>
    /// 占位符数据结构，使用一维数组存储4x4x4的数据
    /// 使用z*size^2+y*size+x索引计算，提升内存访问效率和缓存性能
    /// </summary>
    public class PlaceholderData {
        private const int PLACEHOLDER_ARRAY_SIZE = (int)(ChunkMeshSize / PlaceholderShapeMeshSize);
        private const int TOTAL_ELEMENTS = PLACEHOLDER_ARRAY_SIZE * PLACEHOLDER_ARRAY_SIZE * PLACEHOLDER_ARRAY_SIZE;
        private const int BUFFER_SIZE = TOTAL_ELEMENTS * sizeof(ushort); // 64 * 2 = 128字节
        
        public ushort[] shapeColor; // flags(___, enabled), red, green, blue

        public PlaceholderData() {
            shapeColor = new ushort[TOTAL_ELEMENTS];
        }

        /// <summary>
        /// 计算三维坐标到一维数组的索引
        /// 使用公式：z*size^2 + y*size + x
        /// </summary>
        private static int GetIndex(int x, int y, int z) {
            if (x < 0 || x >= PLACEHOLDER_ARRAY_SIZE || 
                y < 0 || y >= PLACEHOLDER_ARRAY_SIZE || 
                z < 0 || z >= PLACEHOLDER_ARRAY_SIZE) {
                throw new ArgumentOutOfRangeException($"坐标超出范围：({x}, {y}, {z})，有效范围：[0, {PLACEHOLDER_ARRAY_SIZE})");
            }
            return z * PLACEHOLDER_ARRAY_SIZE * PLACEHOLDER_ARRAY_SIZE + y * PLACEHOLDER_ARRAY_SIZE + x;
        }

        /// <summary>
        /// 获取或设置指定坐标的shapeColor值（索引器重载）
        /// </summary>
        public ushort this[int x, int y, int z]
        {
            get => GetShapeColor(x, y, z);
            set => SetShapeColor(x, y, z, value);
        }

        /// <summary>
        /// 获取指定坐标的shapeColor值
        /// </summary>
        public ushort GetShapeColor(int x, int y, int z) {
            return shapeColor[GetIndex(x, y, z)];
        }

        /// <summary>
        /// 设置指定坐标的shapeColor值
        /// </summary>
        public void SetShapeColor(int x, int y, int z, ushort value) {
            shapeColor[GetIndex(x, y, z)] = value;
        }

        /// <summary>
        /// 批量读取数据，一次性读取所有ushort值
        /// </summary>
        private void LoadDataBatch(Reader r, ushort[] array) {
            try {
                var buffer = r.Buffer(BUFFER_SIZE);
                if (buffer == null || buffer.Length != BUFFER_SIZE) {
                    throw new InvalidOperationException($"Data integrity error: expected {BUFFER_SIZE} bytes, but got {buffer?.Length ?? 0} bytes");
                }
                
                var span = new Span<byte>(buffer);
                
                // 直接复制到一维数组，最大化内存访问效率
                for (int i = 0; i < TOTAL_ELEMENTS; i++) {
                    array[i] = BitConverter.ToUInt16(span.Slice(i * sizeof(ushort), sizeof(ushort)));
                }
            }
            catch (Exception ex) {
                throw new InvalidOperationException($"Failed to batch read data: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// 批量写入数据，一次性写入所有ushort值
        /// </summary>
        private void SaveDataBatch(Writer w, ushort[] array) {
            var buffer = new byte[BUFFER_SIZE];
            var span = new Span<byte>(buffer);
            
            // 直接从一维数组复制，最大化内存访问效率
            for (int i = 0; i < TOTAL_ELEMENTS; i++) {
                BitConverter.TryWriteBytes(span.Slice(i * sizeof(ushort), sizeof(ushort)), array[i]);
            }
            
            w.Buffer(BUFFER_SIZE, span);
        }

        public void LoadData(Reader r) {
            // 复用现有数组，避免重复分配内存
            if (shapeColor == null) {
                shapeColor = new ushort[TOTAL_ELEMENTS];
            }
            
            // 使用批量读取优化，从64次IO调用减少到1次
            LoadDataBatch(r, shapeColor);
        }

        public void SaveData(Writer w) {
            // 使用批量写入优化，从64次IO调用减少到1次
            SaveDataBatch(w, shapeColor);
        }
    }

    public struct MeshBlockProxy(ChunkData chunk, int x, int y, int z) {
        public ulong MeshBlock {
            get => chunk.GetMeshBlock(x, y, z);
            set => chunk.SetMeshBlock(x, y, z, value);
        }

        public bool IsInvalid => chunk == null;
        public bool IsEmpty => MeshBlock == 0;
        public bool IsEntity => MeshBlock >> 63 == 1;
        public ulong EntityId => MeshBlock & ((1UL << 63) - 1);
        public bool IsStatic => MeshBlock >> 63 == 0;
        public uint ObjectTypeIndex => (uint)(MeshBlock >> 31);
        public uint CustomData => (uint)(MeshBlock & 0x7FFFFFFF);
        public Entity Entity => Vars.Objects.GetObjectOrNull(EntityId) as Entity;
    }

    /// <summary>
    /// 块数据结构，使用一维数组存储4x4x4的数据
    /// 使用z*size^2+y*size+x索引计算，提升内存访问效率和缓存性能
    /// </summary>
    public class ChunkData {
        private const int CHUNK_ARRAY_SIZE = (int)(ChunkMeshSize / PlaceholderShapeMeshSize);
        private const int CHUNK_TOTAL_ELEMENTS = CHUNK_ARRAY_SIZE * CHUNK_ARRAY_SIZE * CHUNK_ARRAY_SIZE;
        
        public ulong[] meshBlock; // 63(flag), [flag=true] entity id, [flag=false] static block data

        /// <summary>
        /// 计算三维坐标到一维数组的索引
        /// 使用公式：z*size^2 + y*size + x
        /// </summary>
        private static int GetChunkIndex(int x, int y, int z) {
            if (x < 0 || x >= CHUNK_ARRAY_SIZE || 
                y < 0 || y >= CHUNK_ARRAY_SIZE ||
                z < 0 || z >= CHUNK_ARRAY_SIZE)
                {
                    throw new ArgumentOutOfRangeException(
                        $"Coordinates out of range: ({x}, {y}, {z}), valid range: [0, {CHUNK_ARRAY_SIZE})"
                    );
            }
            return z * CHUNK_ARRAY_SIZE * CHUNK_ARRAY_SIZE + y * CHUNK_ARRAY_SIZE + x;
        }

        /// <summary>
        /// 获取指定坐标的meshBlock值
        /// </summary>
        public ulong GetMeshBlock(int x, int y, int z) {
            return meshBlock[GetChunkIndex(x, y, z)];
        }

        /// <summary>
        /// 设置指定坐标的meshBlock值
        /// </summary>
        public void SetMeshBlock(int x, int y, int z, ulong value) {
            meshBlock[GetChunkIndex(x, y, z)] = value;
        }

        /// <summary>
        /// 提供meshBlock的三维索引代理
        /// </summary>
        public MeshBlockProxy this[int x, int y, int z]
        {
            get => new(this, x, y, z);
        }

        public ChunkData() {
            meshBlock = new ulong[CHUNK_TOTAL_ELEMENTS];
        }
    }
}
