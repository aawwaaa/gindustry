using Godot;
using System;
using System.Collections.Generic;
using Gindustry.Type;

namespace Gindustry;

public partial class Vars
{
    public partial class Vars_Types: Node
    {
        private Log.Logger _logger = Log.RegisterLogger("Types");
        
        public Dictionary<string, ResourceTypeType> resourceTypeTypes = new();
        
        public T RegisterType<T>(T type) where T : ResourceType
        {
            type.Source = Vars.Mods.CurrentLoadingMod;
            type._Data();
            if (type.Source != null) type.Source.Types.Add(type);
            type.InitFullId();
            _logger.Debug("Registered type: " + type.FullId);
            if (type is ResourceTypeType typeType)
                resourceTypeTypes[type.FullId] = typeType;
            type.Type.AddType(type);
            type._TypeRegisted();
            type._Assign();
            return type;
        }
        public void RegisterType(ResourceType type1, ResourceType type2, params ResourceType[] types)
        {
            RegisterType(type1);
            RegisterType(type2);
            foreach (var type in types)
                RegisterType(type);
        }

        public ResourceType register_type(ResourceType type) => RegisterType(type);
        
        public ResourceTypeType GetTypeType(string typeId) => resourceTypeTypes[typeId];
        public ResourceTypeType get_type_type(string typeId) => GetTypeType(typeId);
    }
}
