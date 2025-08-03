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
                r.Iter(dimensions, reader => {
                    var dimension = new Dimension();
                    dimension._LoadData(reader);
                    return new KeyValuePair<uint, Dimension>(dimension.Id, dimension);
                });
            });
        }

        public override void SaveData(Writer w)
        {
            w.A(w => {
                w.U32(dimensionIncId);
                w.Iter(dimensions, (w, key, value) => {
                    w.U32(key);
                    value._SaveData(w);
                });
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

        public void UpdateManagers()
        {
            foreach(var dimension in dimensions.Values)
            {
                dimension.UpdateManager();
            }
        }
    }
}
