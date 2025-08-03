using Godot;
using System;
using System.Linq;
using Gindustry.Test;
using Gindustry.Game;
using Gindustry.Net;
using System.Threading.Tasks;

namespace Gindustry.Test
{
    [GlobalClass]
    public partial class NetTest : RefCounted
    {
        private const int TEST_PORT = 1234;
        private const int CLIENT_CONNECTION_TEST_PORT = 1235;
        private const int FULL_NETWORK_FLOW_TEST_PORT = 1236;
        private const string TEST_PLAYER_NAME = "TestPlayer";
        private const string TEST_PLAYER_TOKEN = "TestToken123";
        private const int CONNECTION_TIMEOUT_MS = 10000;
        private const int SERVER_WAIT_TIMEOUT_MS = 15000;

        // 辅助方法：加载NetTest预设
        private async Task LoadNetTestPreset()
        {
            var preset = Preset.Type.Get<Preset>("builtin:preset:NetTest");
            if (preset == null)
                throw new Exception("NetTest preset not found");
            
            await Vars.Presets.LoadPreset(preset);
        }

        // 辅助方法：重置游戏状态
        private void ResetGameState()
        {
            Vars.Game.ResetGame();
            Vars.Game.ResetToMenu();
        }

        // 辅助方法：等待网络条件
        private async Task WaitForNetworkCondition(Func<bool> condition, int timeoutMs = CONNECTION_TIMEOUT_MS)
        {
            var startTime = DateTime.Now;
            while (!condition() && (DateTime.Now - startTime).TotalMilliseconds < timeoutMs)
            {
                await Vars.Tree.ToSignal(Vars.Tree.CreateTimer(0.1f), "timeout");
            }
            if (!condition())
            {
                throw new TimeoutException($"Network condition not met within {timeoutMs}ms");
            }
        }

        [Test("Network", "ServerCreation")]
        public async void TestServerCreation(TestReporter r)
        {
            try
            {
                r.Log("开始测试服务器创建");
                
                // 首先重置游戏状态
                ResetGameState();
                
                // 加载NetTest预设
                await LoadNetTestPreset();
                
                // 验证服务器初始状态
                r.Assert(Vars.Server.state == Vars.Vars_Server.ServerState.Idle, "服务器初始状态应为Idle");
                
                // 创建服务器
                Vars.Server.CreateServer(TEST_PORT);
                
                // 验证服务器状态
                r.Equal(Vars.Server.state, Vars.Vars_Server.ServerState.Running, "服务器状态应为Running");
                
                // 验证多人游戏对等体已设置
                r.Assert(Vars.Tree.GetMultiplayer().MultiplayerPeer != null, "多人游戏对等体应已设置");
                
                // 验证服务器可以接受连接
                var peer = Vars.Tree.GetMultiplayer().MultiplayerPeer as ENetMultiplayerPeer;
                r.Assert(peer != null, "对等体应为ENetMultiplayerPeer类型");
                
                r.Success("服务器创建测试完成");
                
            }
            catch (Exception e)
            {
                r.Failed($"服务器创建测试失败: {e.Message}");
            }
            finally
            {
                // 清理：重置游戏状态
                ResetGameState();
            }
        }

        [Test("Network", "LocalJoin")]
        public async void TestLocalJoin(TestReporter r)
        {
            try
            {
                r.Log("开始测试本地玩家加入");
                
                // 重置游戏状态
                ResetGameState();
                
                // 加载NetTest预设
                await LoadNetTestPreset();
                
                // 创建服务器
                Vars.Server.CreateServer(TEST_PORT);
                r.Assert(Vars.Server.state == Vars.Vars_Server.ServerState.Running, "服务器应正在运行");
                
                // 配置客户端信息
                Vars.Client.ConfigPlayerName.V = TEST_PLAYER_NAME;
                Vars.Client.ConfigPlayerToken.V = TEST_PLAYER_TOKEN;
                
                // 本地加入
                Vars.Client.JoinLocal();
                
                // 等待连接建立
                await WaitForNetworkCondition(() => Vars.Client.State == Vars.Vars_Client.ClientState.Conntected);
                
                // 验证客户端状态
                r.Equal(Vars.Client.State, Vars.Vars_Client.ClientState.Conntected, "客户端应已连接");
                r.Assert(Vars.Client.localJoin, "应为本地加入");
                
                // 验证服务器端有对等体数据
                var peerData = Vars.Server.PeerDataFor(0L); // 本地玩家ID为0
                r.Assert(peerData != null, "服务器应有本地玩家的对等体数据");
                r.Equal(peerData.name, TEST_PLAYER_NAME, "玩家名称应匹配");
                r.Equal(peerData.token, TEST_PLAYER_TOKEN, "玩家令牌应匹配");
                
                r.Success("本地玩家加入测试完成");
                
            }
            catch (Exception e)
            {
                r.Failed($"本地玩家加入测试失败: {e.Message}");
            }
            finally
            {
                // 清理：重置游戏状态
                ResetGameState();
            }
        }

        [Test("Network", "ClientConnectionServer", true)]
        public async void TestClientConnectionServer(TestReporter r)
        {
            try
            {
                r.Log("开始测试客户端连接服务器端");
                
                // 重置游戏状态
                ResetGameState();
                
                // 加载NetTest预设
                await LoadNetTestPreset();
                
                // 创建服务器
                Vars.Server.CreateServer(CLIENT_CONNECTION_TEST_PORT);
                r.Assert(Vars.Server.state == Vars.Vars_Server.ServerState.Running, "服务器应正在运行");
                
                // 验证服务器状态
                r.Assert(Vars.Tree.GetMultiplayer().MultiplayerPeer != null, "多人游戏对等体应已设置");
                var peer = Vars.Tree.GetMultiplayer().MultiplayerPeer as ENetMultiplayerPeer;
                r.Assert(peer != null, "对等体应为ENetMultiplayerPeer类型");
                
                r.Log($"服务器已在端口 {CLIENT_CONNECTION_TEST_PORT} 上运行，等待客户端连接");
                
                // 等待客户端连接
                var initialPeerIds = Vars.Tree.GetMultiplayer().GetPeers();
                await WaitForNetworkCondition(() => Vars.Tree.GetMultiplayer().GetPeers().Length > initialPeerIds.Length, SERVER_WAIT_TIMEOUT_MS);
                
                // 验证客户端连接
                r.Assert(Vars.Tree.GetMultiplayer().GetPeers().Length > initialPeerIds.Length, "应有新的客户端连接");
                
                // 等待客户端数据接收
                PeerData clientPeerData = null;
                await WaitForNetworkCondition(() => {
                    var peerIds = Vars.Tree.GetMultiplayer().GetPeers();
                    foreach (var peerId in peerIds)
                    {
                        var peerData = Vars.Server.PeerDataFor(peerId);
                        if (peerData != null && !string.IsNullOrEmpty(peerData.name))
                        {
                            clientPeerData = peerData;
                            return true;
                        }
                    }
                    return false;
                }, SERVER_WAIT_TIMEOUT_MS);
                
                // 验证客户端数据
                r.Assert(clientPeerData != null, "应有客户端对等体数据");
                r.Assert(!string.IsNullOrEmpty(clientPeerData.name), "客户端名称应已设置");
                r.Assert(!string.IsNullOrEmpty(clientPeerData.token), "客户端令牌应已设置");

                await Vars.Tree.ToSignal(Vars.Tree.CreateTimer(3f), "timeout");
                
                r.Success("客户端连接服务器端测试完成");
                
            }
            catch (Exception e)
            {
                r.Failed($"客户端连接服务器端测试失败: {e.Message}");
            }
            finally
            {
                // 清理：重置游戏状态
                ResetGameState();
            }
        }

        [Test("Network", "ClientConnectionClient", true)]
        public async void TestClientConnectionClient(TestReporter r)
        {
            try
            {
                r.Log("开始测试客户端连接客户端端");
                
                // 重置游戏状态
                ResetGameState();
                
                // 配置客户端信息
                Vars.Client.ConfigPlayerName.V = TEST_PLAYER_NAME;
                Vars.Client.ConfigPlayerToken.V = TEST_PLAYER_TOKEN;
                
                // 验证初始状态
                r.Equal(Vars.Client.State, Vars.Vars_Client.ClientState.Idle, "客户端初始状态应为Idle");
                
                // 连接到服务器
                Vars.Client.ConnectTo("localhost", CLIENT_CONNECTION_TEST_PORT);
                
                // 等待连接建立
                await WaitForNetworkCondition(() => 
                    Vars.Client.State == Vars.Vars_Client.ClientState.Conntected || 
                    Vars.Client.State == Vars.Vars_Client.ClientState.WaitingServer ||
                    Vars.Client.State == Vars.Vars_Client.ClientState.ServerInteract);
                
                // 验证客户端状态
                r.Assert(Vars.Client.ClientActive, "客户端应处于活动状态");
                r.Assert(!Vars.Client.localJoin, "应为远程连接");
                r.Assert(Vars.Client.State != Vars.Vars_Client.ClientState.Idle, "客户端状态应已改变");
                
                // 验证网络连接
                r.Assert(Vars.Tree.GetMultiplayer().MultiplayerPeer != null, "多人游戏对等体应已设置");

                await Vars.Tree.ToSignal(Vars.Tree.CreateTimer(2f), "timeout");
                
                r.Success("客户端连接客户端端测试完成");
                
            }
            catch (Exception e)
            {
                r.Failed($"客户端连接客户端端测试失败: {e.Message}");
            }
            finally
            {
                // 清理：重置游戏状态
                ResetGameState();
            }
        }

        [Test("Network", "FullNetworkFlowServer", true)]
        public async void TestFullNetworkFlowServer(TestReporter r)
        {
            try
            {
                r.Log("开始测试完整网络流程服务器端");
                
                // 步骤1：重置游戏状态
                ResetGameState();
                r.Log("步骤1完成：游戏状态重置");
                
                // 步骤2：加载NetTest预设
                await LoadNetTestPreset();
                r.Log("步骤2完成：NetTest预设加载");
                
                // 步骤3：创建服务器
                Vars.Server.CreateServer(FULL_NETWORK_FLOW_TEST_PORT);
                r.Equal(Vars.Server.state, Vars.Vars_Server.ServerState.Running, "服务器应正在运行");
                r.Log("步骤3完成：服务器创建");
                
                // 步骤4：验证服务器基本状态
                r.Assert(Vars.Tree.GetMultiplayer().MultiplayerPeer != null, "多人游戏对等体应已设置");
                var peer = Vars.Tree.GetMultiplayer().MultiplayerPeer as ENetMultiplayerPeer;
                r.Assert(peer != null, "对等体应为ENetMultiplayerPeer类型");
                r.Log("步骤4完成：服务器基本状态验证");
                
                // 步骤5：等待客户端连接
                var initialPeerIds = Vars.Tree.GetMultiplayer().GetPeers();
                await WaitForNetworkCondition(() => Vars.Tree.GetMultiplayer().GetPeers().Length > initialPeerIds.Length, SERVER_WAIT_TIMEOUT_MS);
                r.Assert(Vars.Tree.GetMultiplayer().GetPeers().Length > initialPeerIds.Length, "应有新的客户端连接");
                r.Log("步骤5完成：客户端连接到服务器");
                
                // 步骤6：等待并验证客户端数据
                PeerData clientPeerData = null;
                await WaitForNetworkCondition(() => {
                    var peerIds = Vars.Tree.GetMultiplayer().GetPeers();
                    foreach (var peerId in peerIds)
                    {
                        var peerData = Vars.Server.PeerDataFor(peerId);
                        if (peerData != null && !string.IsNullOrEmpty(peerData.name) && !string.IsNullOrEmpty(peerData.token))
                        {
                            clientPeerData = peerData;
                            return true;
                        }
                    }
                    return false;
                }, SERVER_WAIT_TIMEOUT_MS);
                
                r.Assert(clientPeerData != null, "应有客户端对等体数据");
                r.Assert(!string.IsNullOrEmpty(clientPeerData.name), "客户端名称应已设置");
                r.Assert(!string.IsNullOrEmpty(clientPeerData.token), "客户端令牌应已设置");
                r.Log("步骤6完成：客户端数据验证");
                
                // 步骤7：等待客户端状态达到连接状态
                await WaitForNetworkCondition(() => {
                    return clientPeerData != null && (clientPeerData.state == PeerState.Connected || clientPeerData.state == PeerState.Connecting);
                }, SERVER_WAIT_TIMEOUT_MS);

                await Vars.Tree.ToSignal(Vars.Tree.CreateTimer(3f), "timeout");
                
                r.Assert(clientPeerData.state != PeerState.Idle, "客户端状态应已改变");
                r.Log("步骤7完成：客户端状态验证");
                
                // 步骤8：验证游戏状态
                r.Assert(Vars.Game.SavePreset != null, "游戏预设应已加载");
                r.Log("步骤8完成：游戏状态验证");
                
                r.Success("完整网络流程服务器端测试完成");
                
            }
            catch (Exception e)
            {
                r.Failed($"完整网络流程服务器端测试失败: {e.Message}");
            }
            finally
            {
                // 清理：重置游戏状态
                ResetGameState();
                r.Log("服务器端测试清理完成：游戏状态已重置");
            }
        }

        [Test("Network", "FullNetworkFlowClient", true)]
        public async void TestFullNetworkFlowClient(TestReporter r)
        {
            try
            {
                r.Log("开始测试完整网络流程客户端");
                
                // 步骤1：重置游戏状态
                ResetGameState();
                r.Log("步骤1完成：游戏状态重置");
                
                // 步骤3：配置客户端信息
                Vars.Client.ConfigPlayerName.V = TEST_PLAYER_NAME;
                Vars.Client.ConfigPlayerToken.V = TEST_PLAYER_TOKEN;
                r.Log("步骤3完成：客户端配置");
                
                // 步骤4：验证初始状态
                r.Equal(Vars.Client.State, Vars.Vars_Client.ClientState.Idle, "客户端初始状态应为Idle");
                r.Log("步骤4完成：初始状态验证");
                
                // 步骤5：连接到服务器
                Vars.Client.ConnectTo("localhost", FULL_NETWORK_FLOW_TEST_PORT);
                r.Log("步骤5完成：开始连接服务器");
                
                // 步骤6：等待连接建立
                await WaitForNetworkCondition(() => 
                    Vars.Client.State == Vars.Vars_Client.ClientState.Conntected || 
                    Vars.Client.State == Vars.Vars_Client.ClientState.WaitingServer ||
                    Vars.Client.State == Vars.Vars_Client.ClientState.ServerInteract);
                
                r.Assert(Vars.Client.ClientActive, "客户端应处于活动状态");
                r.Assert(!Vars.Client.localJoin, "应为远程连接");
                r.Assert(Vars.Client.State != Vars.Vars_Client.ClientState.Idle, "客户端状态应已改变");
                r.Log("步骤6完成：网络连接建立");
                
                // 步骤7：验证网络连接
                r.Assert(Vars.Tree.GetMultiplayer().MultiplayerPeer != null, "多人游戏对等体应已设置");
                var peer = Vars.Tree.GetMultiplayer().MultiplayerPeer as ENetMultiplayerPeer;
                r.Assert(peer != null, "对等体应为ENetMultiplayerPeer类型");
                r.Log("步骤7完成：网络连接验证");
                
                // 步骤8：等待服务器响应（如果需要）
                if (Vars.Client.State == Vars.Vars_Client.ClientState.WaitingServer)
                {
                    await WaitForNetworkCondition(() => 
                        Vars.Client.State == Vars.Vars_Client.ClientState.Conntected ||
                        Vars.Client.State == Vars.Vars_Client.ClientState.ServerInteract, 
                        CONNECTION_TIMEOUT_MS);
                }
                r.Log("步骤8完成：服务器响应处理");
                
                // 步骤9：验证最终状态
                r.Assert(Vars.Client.ClientActive, "客户端应保持活动状态");
                if (Vars.Client.State == Vars.Vars_Client.ClientState.Conntected)
                {
                    r.Assert(Vars.Core.IsInGame(), "游戏应处于InGame状态");
                }
                r.Log("步骤9完成：最终状态验证");

                await Vars.Tree.ToSignal(Vars.Tree.CreateTimer(2f), "timeout");
                
                r.Success("完整网络流程客户端测试完成");
                
            }
            catch (Exception e)
            {
                r.Failed($"完整网络流程客户端测试失败: {e.Message}");
            }
            finally
            {
                // 清理：重置游戏状态
                ResetGameState();
                r.Log("客户端测试清理完成：游戏状态已重置");
            }
        }
    }
}
