using Gindustry.Attributes;
using Gindustry.CSharpUtils;
using Godot;

namespace Gindustry.Net
{
    [GlobalClass]
    [GDScriptAdapterTarget("GA_ServerManager")]
    public partial class ServerManager : Node
    {
        public enum PermissionResult {
            Allow, Deny, Ignore
        }
        public virtual int _Priority => 0;
        public virtual void _ServerCreated() {}
        public virtual void _ServerReset() {}

        public virtual void _PeerData(PeerData peer, string type, byte[] data) {}
        public virtual bool _DataReceived(PeerData peer) { return true; }
        public virtual void _PeerConnect(PeerData peer, CoroutineBridge c) {} // NOTE: Do not include *ANY* interact for local player
        public virtual void _PlayerJoin(PeerData peer) {}
        public virtual void _PlayerLeave(PeerData peer) {}
        public virtual void _PeerDisconnect(PeerData peer) {}

        public virtual PermissionResult _HasPermission(PeerData peer, string permission) {
            return PermissionResult.Ignore;
        }

        public virtual bool _HandleMessage(PeerData peer, string message) {
            return false;
        }
    }
}
