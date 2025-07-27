const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');

const app = express();
const server = http.createServer(app);

// 配置CORS
app.use(cors({
  origin: "*",
  methods: ["GET", "POST"]
}));

const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// 存储房间信息
const rooms = new Map();

// 存储用户信息
const users = new Map();

// 消息类型枚举
const MessageType = {
  CHAT: 'chat',
  GIFT: 'gift',
  LIKE: 'like',
  USER_JOIN: 'user_join',
  USER_LEAVE: 'user_leave',
  VIEWER_COUNT: 'viewer_count',
  SYSTEM: 'system'
};

// 礼物类型
const GiftTypes = {
  HEART: 'heart',
  FLOWER: 'flower',
  DIAMOND: 'diamond',
  CROWN: 'crown'
};

app.get('/', (req, res) => {
  res.json({
    message: 'GuiFei Live WebSocket Server is running!',
    timestamp: new Date().toISOString(),
    activeRooms: rooms.size,
    connectedUsers: users.size
  });
});

app.get('/rooms', (req, res) => {
  const roomList = Array.from(rooms.entries()).map(([roomId, room]) => ({
    roomId,
    viewerCount: room.viewers.size,
    createdAt: room.createdAt
  }));
  res.json(roomList);
});

io.on('connection', (socket) => {
  console.log(`用户连接: ${socket.id}`);

  // 用户加入房间
  socket.on('join_room', (data) => {
    const { roomId, userInfo } = data;
    
    // 离开之前的房间
    if (socket.currentRoom) {
      socket.leave(socket.currentRoom);
      leaveRoom(socket.id, socket.currentRoom);
    }

    // 加入新房间
    socket.join(roomId);
    socket.currentRoom = roomId;
    
    // 存储用户信息
    users.set(socket.id, {
      ...userInfo,
      socketId: socket.id,
      roomId: roomId,
      joinedAt: new Date().toISOString()
    });

    // 初始化房间（如果不存在）
    if (!rooms.has(roomId)) {
      rooms.set(roomId, {
        viewers: new Set(),
        createdAt: new Date().toISOString(),
        messageCount: 0,
        likeCount: 0
      });
    }

    const room = rooms.get(roomId);
    room.viewers.add(socket.id);

    console.log(`用户 ${userInfo.nickname} 加入房间 ${roomId}`);

    // 广播用户加入消息
    const joinMessage = {
      type: MessageType.USER_JOIN,
      senderId: socket.id,
      roomId: roomId,
      data: {
        userInfo: userInfo,
        message: `${userInfo.nickname} 加入了直播间`
      },
      timestamp: new Date().toISOString()
    };

    socket.to(roomId).emit('message', joinMessage);

    // 发送当前观众数
    broadcastViewerCount(roomId);

    // 发送加入成功确认
    socket.emit('join_success', {
      roomId: roomId,
      viewerCount: room.viewers.size
    });
  });

  // 处理聊天消息
  socket.on('chat_message', (data) => {
    const { roomId, message } = data;
    const user = users.get(socket.id);
    
    if (!user || !roomId) return;

    const room = rooms.get(roomId);
    if (room) {
      room.messageCount++;
    }

    const chatMessage = {
      type: MessageType.CHAT,
      senderId: socket.id,
      roomId: roomId,
      data: {
        message: message,
        senderName: user.nickname,
        senderAvatar: user.avatar
      },
      timestamp: new Date().toISOString()
    };

    // 广播给房间内所有用户（包括发送者）
    io.to(roomId).emit('message', chatMessage);
    console.log(`聊天消息 [${roomId}] ${user.nickname}: ${message}`);
  });

  // 处理礼物消息
  socket.on('send_gift', (data) => {
    const { roomId, giftType, giftCount = 1 } = data;
    const user = users.get(socket.id);
    
    if (!user || !roomId) return;

    const giftMessage = {
      type: MessageType.GIFT,
      senderId: socket.id,
      roomId: roomId,
      data: {
        giftType: giftType,
        giftCount: giftCount,
        senderName: user.nickname,
        senderAvatar: user.avatar
      },
      timestamp: new Date().toISOString()
    };

    // 广播给房间内所有用户
    io.to(roomId).emit('message', giftMessage);
    console.log(`礼物消息 [${roomId}] ${user.nickname} 送出 ${giftCount} 个 ${giftType}`);
  });

  // 处理点赞消息
  socket.on('send_like', (data) => {
    const { roomId } = data;
    const user = users.get(socket.id);
    
    if (!user || !roomId) return;

    const room = rooms.get(roomId);
    if (room) {
      room.likeCount++;
    }

    const likeMessage = {
      type: MessageType.LIKE,
      senderId: socket.id,
      roomId: roomId,
      data: {
        senderName: user.nickname,
        totalLikes: room ? room.likeCount : 1
      },
      timestamp: new Date().toISOString()
    };

    // 广播给房间内所有用户
    io.to(roomId).emit('message', likeMessage);
  });

  // 处理心跳
  socket.on('heartbeat', () => {
    socket.emit('heartbeat_ack', {
      timestamp: new Date().toISOString()
    });
  });

  // 用户断开连接
  socket.on('disconnect', () => {
    console.log(`用户断开连接: ${socket.id}`);
    
    if (socket.currentRoom) {
      leaveRoom(socket.id, socket.currentRoom);
    }
    
    users.delete(socket.id);
  });

  // 手动离开房间
  socket.on('leave_room', () => {
    if (socket.currentRoom) {
      leaveRoom(socket.id, socket.currentRoom);
      socket.leave(socket.currentRoom);
      socket.currentRoom = null;
    }
  });
});

// 离开房间的辅助函数
function leaveRoom(socketId, roomId) {
  const room = rooms.get(roomId);
  const user = users.get(socketId);
  
  if (room && user) {
    room.viewers.delete(socketId);
    
    // 广播用户离开消息
    const leaveMessage = {
      type: MessageType.USER_LEAVE,
      senderId: socketId,
      roomId: roomId,
      data: {
        userInfo: user,
        message: `${user.nickname} 离开了直播间`
      },
      timestamp: new Date().toISOString()
    };

    io.to(roomId).emit('message', leaveMessage);
    
    // 更新观众数
    broadcastViewerCount(roomId);
    
    // 如果房间没有观众了，删除房间
    if (room.viewers.size === 0) {
      rooms.delete(roomId);
      console.log(`房间 ${roomId} 已删除（无观众）`);
    }
    
    console.log(`用户 ${user.nickname} 离开房间 ${roomId}`);
  }
}

// 广播观众数的辅助函数
function broadcastViewerCount(roomId) {
  const room = rooms.get(roomId);
  if (room) {
    const viewerCountMessage = {
      type: MessageType.VIEWER_COUNT,
      roomId: roomId,
      data: {
        count: room.viewers.size
      },
      timestamp: new Date().toISOString()
    };
    
    io.to(roomId).emit('message', viewerCountMessage);
  }
}

// 定期清理空房间
setInterval(() => {
  for (const [roomId, room] of rooms.entries()) {
    if (room.viewers.size === 0) {
      const roomAge = Date.now() - new Date(room.createdAt).getTime();
      // 删除超过5分钟的空房间
      if (roomAge > 5 * 60 * 1000) {
        rooms.delete(roomId);
        console.log(`清理空房间: ${roomId}`);
      }
    }
  }
}, 60000); // 每分钟检查一次

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`🚀 GuiFei Live WebSocket服务器运行在端口 ${PORT}`);
  console.log(`📱 服务器地址: http://localhost:${PORT}`);
  console.log(`🔗 WebSocket地址: ws://localhost:${PORT}`);
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('收到SIGTERM信号，正在关闭服务器...');
  server.close(() => {
    console.log('服务器已关闭');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('收到SIGINT信号，正在关闭服务器...');
  server.close(() => {
    console.log('服务器已关闭');
    process.exit(0);
  });
});