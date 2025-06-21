using Godot;
using System;

namespace Gindustry;

public partial class Vars
{
    [GlobalClass]
    public partial class Vars_Server: Node
    {
        public partial class PeerData: RefCounted
        {

        }

        public bool IsCallerHasPermission(MultiplayerApi api, string permission)
        {
            return true;
        }

        public void CreateServer(int port)
        {}
        public void Reset()
        {}
    }
}
