using Godot;
using System;
using System.Collections.Generic;

public partial class Vars
{
    [GlobalClass]
    public partial class Vars_Worlds: SaveDataComponent
    {
        public Dictionary<uint, World> worlds = new();
        public uint worldIncId = 1;

        public override void InitData()
        {
        }

        public override void LoadData(Reader r)
        {
            r.A(r => {
                worldIncId = r.U32();

                worlds.Clear();
                var size = r.I32();
                for (int i = 0; i < size; i++)
                {
                    var world = new World();
                    world._LoadData(r);
                    worlds.Add(world.Id, world);
                }
            });
        }

        public override void SaveData(Writer w)
        {
            w.A(w => {
                w.U32(worldIncId);
                w.I32(worlds.Count);
                foreach(var pair in worlds)
                {
                    w.U32(pair.Key);
                    pair.Value._SaveData(w);
                }
            });
        }

        public override void DisposeData()
        {
            foreach(var world in worlds.Values)
            {
                world.ObjectFree();
                world.Free();
            }
        }

        public World Create()
        {
            var world = new World();
            world.Id = worldIncId++;
            worlds.Add(world.Id, world);
            return world;
        }
    }
}
