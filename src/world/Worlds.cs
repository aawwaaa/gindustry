using Godot;
using System;
using System.Collections.Generic;
using Gindustry.IO;
using Gindustry.IO.Save;
using Gindustry.World;

namespace Gindustry;

public partial class Vars
{
    [GlobalClass]
    public partial class Vars_Dimensions: SaveDataComponent
    {
        public Dictionary<uint, Dimension> dimensions = new();
        public uint dimensionIncId = 1;

        public override void InitData()
        {
        }

        public override void LoadData(Reader r)
        {
            r.A(r => {
                dimensionIncId = r.U32();

                dimensions.Clear();
                var size = r.I32();
                for (int i = 0; i < size; i++)
                {
                    var dimension = new Dimension();
                    dimension._LoadData(r);
                    dimensions.Add(dimension.Id, dimension);
                }
            });
        }

        public override void SaveData(Writer w)
        {
            w.A(w => {
                w.U32(dimensionIncId);
                w.I32(dimensions.Count);
                foreach(var pair in dimensions)
                {
                    w.U32(pair.Key);
                    pair.Value._SaveData(w);
                }
            });
        }

        public override void DisposeData()
        {
            foreach(var dimension in dimensions.Values)
            {
                dimension.ObjectFree();
                dimension.Free();
            }
        }

        public Dimension Create()
        {
            var dimension = new Dimension();
            dimension.Id = dimensionIncId++;
            dimensions.Add(dimension.Id, dimension);
            return dimension;
        }
    }
}
