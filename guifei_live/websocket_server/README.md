# GuiFei Live WebSocket Server

这是GuiFei Live直播应用的WebSocket服务器，提供实时通信功能，支持聊天、礼物、点赞等交互。

## 功能特性

- ✅ **实时聊天** - 支持房间内实时文字聊天
- ✅ **礼物系统** - 支持多种礼物类型的发送和接收
- ✅ **点赞功能** - 实时点赞统计和广播
- ✅ **观众统计** - 实时观众数量统计
- ✅ **房间管理** - 自动房间创建和清理
- ✅ **心跳检测** - 连接状态监控
- ✅ **用户管理** - 用户加入/离开通知

## 技术栈

- **Node.js** - 服务器运行环境
- **Socket.IO** - WebSocket通信库
- **Express** - HTTP服务器框架
- **CORS** - 跨域资源共享支持

## 快速开始

### 1. 安装依赖

```bash
cd websocket_server
npm install
```

### 2. 启动服务器

```bash
# 生产环境
npm start

# 开发环境（自动重启）
npm run dev
```

### 3. 验证服务器

打开浏览器访问 `http://localhost:3000`，应该看到服务器状态信息。

## API 接口

### HTTP 接口

#### GET /
获取服务器状态信息

```json
{
  "message": "GuiFei Live WebSocket Server is running!",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "activeRooms": 5,
  "connectedUsers": 23
}
```

#### GET /rooms
获取活跃房间列表

```json
[
  {
    "roomId": "room_1704067200000",
    "viewerCount": 15,
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
]
```

### WebSocket 事件

#### 客户端发送事件

| 事件名 | 参数 | 描述 |
|--------|------|------|
| `join_room` | `{roomId, userInfo}` | 加入房间 |
| `chat_message` | `{roomId, message}` | 发送聊天消息 |
| `send_gift` | `{roomId, giftType, giftCount}` | 发送礼物 |
| `send_like` | `{roomId}` | 发送点赞 |
| `heartbeat` | - | 心跳检测 |
| `leave_room` | - | 离开房间 |

#### 服务器发送事件

| 事件名 | 参数 | 描述 |
|--------|------|------|
| `message` | `WebSocketMessage` | 各类消息（聊天、礼物、系统等） |
| `join_success` | `{roomId, viewerCount}` | 加入房间成功 |
| `heartbeat_ack` | `{timestamp}` | 心跳响应 |

## 消息格式

### WebSocket消息结构

```typescript
interface WebSocketMessage {
  type: MessageType;
  senderId?: string;
  roomId: string;
  data: any;
  timestamp: string;
}
```

### 消息类型

- `chat` - 聊天消息
- `gift` - 礼物消息
- `like` - 点赞消息
- `user_join` - 用户加入
- `user_leave` - 用户离开
- `viewer_count` - 观众数量更新
- `system` - 系统消息

### 礼物类型

- `heart` - 爱心
- `flower` - 鲜花
- `diamond` - 钻石
- `crown` - 皇冠

## 配置选项

### 环境变量

- `PORT` - 服务器端口（默认：3000）

### 服务器配置

- **房间清理间隔**：60秒
- **空房间保留时间**：5分钟
- **CORS策略**：允许所有来源

## 部署说明

### 本地部署

1. 确保已安装 Node.js (版本 >= 14)
2. 克隆项目并安装依赖
3. 运行 `npm start` 启动服务器

### 生产部署

推荐使用 PM2 进行进程管理：

```bash
# 安装 PM2
npm install -g pm2

# 启动服务
pm2 start server.js --name "guifei-websocket"

# 查看状态
pm2 status

# 查看日志
pm2 logs guifei-websocket
```

## 监控和日志

服务器会输出以下日志信息：

- 用户连接/断开
- 房间加入/离开
- 消息发送统计
- 房间清理操作

## 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 查找占用端口的进程
   netstat -ano | findstr :3000
   # 杀死进程
   taskkill /PID <进程ID> /F
   ```

2. **连接失败**
   - 检查防火墙设置
   - 确认服务器正在运行
   - 验证客户端连接地址

3. **消息丢失**
   - 检查网络连接稳定性
   - 确认心跳机制正常工作
   - 查看服务器日志

## 性能优化

- 使用 Redis 存储房间和用户信息（大规模部署）
- 实现负载均衡（多服务器实例）
- 添加消息队列（处理高并发）
- 实现数据持久化（聊天记录）

## 安全考虑

- 实现用户认证和授权
- 添加消息内容过滤
- 限制连接频率和消息发送频率
- 使用 HTTPS/WSS 加密传输

## 开发计划

- [ ] 用户认证系统
- [ ] 消息持久化
- [ ] 管理员功能
- [ ] 房间密码保护
- [ ] 私聊功能
- [ ] 文件传输支持