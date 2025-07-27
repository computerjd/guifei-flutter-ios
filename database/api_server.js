const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bcrypt = require('bcrypt');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors({
    origin: ['http://localhost:8080', 'http://127.0.0.1:8080', 'http://localhost:3000', 'http://localhost:7594', 'http://127.0.0.1:7594', 'http://localhost:9533', 'http://127.0.0.1:9533', 'http://localhost:9534', 'http://127.0.0.1:9534'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 添加请求日志中间件
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    console.log('Headers:', req.headers);
    if (req.body && Object.keys(req.body).length > 0) {
        console.log('Body:', req.body);
    }
    next();
});

// 更新直播间状态
app.put('/api/live-rooms/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        
        if (status === undefined) {
            return res.status(400).json({ success: false, message: '状态参数不能为空' });
        }
        
        // 更新直播间状态
        const [result] = await pool.execute(
            'UPDATE live_rooms SET status = ?, updated_at = NOW() WHERE id = ?',
            [status, id]
        );
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ success: false, message: '直播间不存在' });
        }
        
        // 获取更新后的直播间信息
        const [rooms] = await pool.execute(
            `SELECT lr.*, u.nickname as anchor_name, u.avatar as anchor_avatar, g.name as game_name
             FROM live_rooms lr
             LEFT JOIN users u ON lr.user_id = u.id
             LEFT JOIN games g ON lr.game_id = g.id
             WHERE lr.id = ?`,
            [id]
        );
        
        res.json({ success: true, message: '直播间状态更新成功', data: rooms[0] });
    } catch (error) {
        console.error('更新直播间状态错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 数据库配置
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: 'guifei_live',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
};

// 创建数据库连接池
const pool = mysql.createPool(dbConfig);

// 生成12位UUID（字母和数字组合）
function generateUserId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < 12; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

// 管理员登录
app.post('/api/auth/login', async (req, res) => {
    try {
        const { phone, password } = req.body;
        
        if (!phone || !password) {
            return res.status(400).json({ success: false, message: '手机号和密码不能为空' });
        }
        
        // 查找管理员用户
        const [users] = await pool.execute(
            'SELECT * FROM users WHERE phone = ? AND user_type = 4',
            [phone]
        );
        
        if (users.length === 0) {
            return res.status(401).json({ success: false, message: '管理员账户不存在' });
        }
        
        const user = users[0];
        
        // 简单密码验证
        if (user.password !== password) {
            return res.status(401).json({ success: false, message: '密码错误' });
        }
        
        if (user.status !== 0) {
            return res.status(403).json({ success: false, message: '账户已被禁用' });
        }
        
        // 生成简单的token（实际项目中应该使用JWT）
        const token = 'admin_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        
        // 移除密码字段
        delete user.password;
        
        res.json({ success: true, message: '登录成功', token, user });
    } catch (error) {
        console.error('管理员登录错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 用户登录
app.post('/api/login', async (req, res) => {
    try {
        const { phone, password, user_type } = req.body;
        
        if (!phone || !password) {
            return res.status(400).json({ success: false, message: '手机号和密码不能为空' });
        }
        
        const [users] = await pool.execute(
            'SELECT * FROM users WHERE phone = ? AND user_type = ?',
            [phone, user_type || 1]
        );
        
        if (users.length === 0) {
            return res.status(401).json({ success: false, message: '用户不存在或用户类型不匹配' });
        }
        
        const user = users[0];
        
        // 简单密码验证（实际项目中应该使用bcrypt）
        if (user.password !== password) {
            return res.status(401).json({ success: false, message: '密码错误' });
        }
        
        if (user.status !== 0) {
            return res.status(403).json({ success: false, message: '账户已被禁用或冻结' });
        }
        
        // 移除密码字段
        delete user.password;
        
        res.json({ success: true, message: '登录成功', data: user });
    } catch (error) {
        console.error('登录错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 用户注册
app.post('/api/register', async (req, res) => {
    try {
        const { username, phone, password, nickname, gender, birthday, user_type } = req.body;
        
        if (!username || !phone || !password || !nickname) {
            return res.status(400).json({ success: false, message: '必填字段不能为空' });
        }
        
        // 检查用户名是否已存在
        const [existingUsers] = await pool.execute(
            'SELECT id FROM users WHERE username = ? OR phone = ?',
            [username, phone]
        );
        
        if (existingUsers.length > 0) {
            return res.status(409).json({ success: false, message: '用户名或手机号已存在' });
        }
        
        const userId = generateUserId();
        const userTypeValue = user_type || 1;
        
        // 插入用户数据
        await pool.execute(
            'INSERT INTO users (id, username, phone, password, nickname, gender, birthday, register_time, user_type) VALUES (?, ?, ?, ?, ?, ?, ?, CURDATE(), ?)',
            [userId, username, phone, password, nickname, gender || 1, birthday || '2000-01-01', userTypeValue]
        );
        
        // 根据用户类型插入扩展表数据
        if (userTypeValue === 1) {
            await pool.execute('INSERT INTO users_consumer (user_id) VALUES (?)', [userId]);
        } else if (userTypeValue === 2) {
            await pool.execute('INSERT INTO users_live (user_id) VALUES (?)', [userId]);
        } else if (userTypeValue === 3) {
            await pool.execute('INSERT INTO users_kefu (user_id, kefu_register_time) VALUES (?, CURDATE())', [userId]);
        } else if (userTypeValue === 4) {
            await pool.execute('INSERT INTO users_admin (user_id, admin_register_time) VALUES (?, CURDATE())', [userId]);
        }
        
        res.json({ success: true, message: '注册成功', data: { user_id: userId } });
    } catch (error) {
        console.error('注册错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取用户信息
app.get('/api/user/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const [users] = await pool.execute(
            'SELECT id, username, phone, avatar, nickname, gender, birthday, status, register_time, user_type FROM users WHERE id = ?',
            [id]
        );
        
        if (users.length === 0) {
            return res.status(404).json({ success: false, message: '用户不存在' });
        }
        
        const user = users[0];
        
        // 根据用户类型获取扩展信息
        if (user.user_type === 1) {
            const [consumer] = await pool.execute('SELECT * FROM users_consumer WHERE user_id = ?', [id]);
            user.consumer_info = consumer[0] || null;
        } else if (user.user_type === 2) {
            const [live] = await pool.execute('SELECT * FROM users_live WHERE user_id = ?', [id]);
            user.live_info = live[0] || null;
        } else if (user.user_type === 3) {
            const [kefu] = await pool.execute('SELECT * FROM users_kefu WHERE user_id = ?', [id]);
            user.kefu_info = kefu[0] || null;
        } else if (user.user_type === 4) {
            const [admin] = await pool.execute('SELECT * FROM users_admin WHERE user_id = ?', [id]);
            user.admin_info = admin[0] || null;
        }
        
        res.json({ success: true, data: user });
    } catch (error) {
        console.error('获取用户信息错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取游戏列表
app.get('/api/games', async (req, res) => {
    try {
        const [games] = await pool.execute('SELECT * FROM games ORDER BY id');
        res.json({ success: true, data: games });
    } catch (error) {
        console.error('获取游戏列表错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取礼物列表
app.get('/api/gifts', async (req, res) => {
    try {
        const [gifts] = await pool.execute('SELECT * FROM gift_types ORDER BY price');
        res.json({ success: true, data: gifts });
    } catch (error) {
        console.error('获取礼物列表错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取用户列表
app.get('/api/users', async (req, res) => {
    try {
        const sql = `
            SELECT id, username, phone, avatar, nickname, gender, birthday, status, created_at
            FROM users
            ORDER BY created_at DESC
            LIMIT 50
        `;
        
        const [users] = await pool.execute(sql);
        
        res.json({ 
            success: true, 
            users: users
        });
    } catch (error) {
        console.error('获取用户列表错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取活跃用户会话
app.get('/api/user-sessions/active', async (req, res) => {
    try {
        // 模拟活跃用户会话数据（实际项目中应该从会话表获取）
        const [users] = await pool.execute(
            'SELECT id as user_id, NULL as room_id FROM users WHERE status = 0 LIMIT 20'
        );
        
        res.json({ 
            success: true, 
            sessions: users
        });
    } catch (error) {
        console.error('获取活跃用户会话错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 创建直播间
app.post('/api/live-rooms', async (req, res) => {
    try {
        const { title, user_id, game_id } = req.body;
        
        if (!title || !user_id) {
            return res.status(400).json({ success: false, message: '标题和用户ID不能为空' });
        }
        
        // 插入直播间数据
        const [result] = await pool.execute(
            'INSERT INTO live_rooms (title, user_id, game_id, status, created_at) VALUES (?, ?, ?, 1, NOW())',
            [title, user_id, game_id || null]
        );
        
        const roomId = result.insertId;
        
        // 获取创建的直播间信息
        const [rooms] = await pool.execute(
            `SELECT lr.*, u.nickname as anchor_name, u.avatar as anchor_avatar, g.name as game_name
             FROM live_rooms lr
             LEFT JOIN users u ON lr.user_id = u.id
             LEFT JOIN games g ON lr.game_id = g.id
             WHERE lr.id = ?`,
            [roomId]
        );
        
        res.json({ success: true, message: '直播间创建成功', data: rooms[0] });
    } catch (error) {
        console.error('创建直播间错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取直播间列表
app.get('/api/live-rooms', async (req, res) => {
    try {
        const { status } = req.query;
        let sql = `
            SELECT lr.*, u.nickname as anchor_name, u.avatar as anchor_avatar, g.name as game_name
            FROM live_rooms lr
            LEFT JOIN users u ON lr.user_id = u.id
            LEFT JOIN games g ON lr.game_id = g.id
        `;
        const params = [];
        
        if (status !== undefined) {
            sql += ' WHERE lr.status = ?';
            params.push(status);
        }
        
        sql += ' ORDER BY lr.created_at DESC';
        
        const [rooms] = await pool.execute(sql, params);
        res.json({ success: true, data: rooms });
    } catch (error) {
        console.error('获取直播间列表错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取活跃直播间
app.get('/api/live-rooms/active', async (req, res) => {
    try {
        const sql = `
            SELECT lr.id, lr.title, lr.user_id, lr.created_at,
                   u.nickname as streamer_nickname, u.avatar as streamer_avatar
            FROM live_rooms lr
            LEFT JOIN users u ON lr.user_id = u.id
            WHERE lr.status = 1
            ORDER BY lr.created_at DESC
        `;
        
        const [rooms] = await pool.execute(sql);
        res.json({ 
            success: true, 
            rooms: rooms
        });
    } catch (error) {
        console.error('获取活跃直播间错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 更新直播间状态
app.put('/api/live-rooms/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        
        if (status === undefined) {
            return res.status(400).json({ success: false, message: '状态参数不能为空' });
        }
        
        // 更新直播间状态
        const [result] = await pool.execute(
            'UPDATE live_rooms SET status = ?, updated_at = NOW() WHERE id = ?',
            [status, id]
        );
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ success: false, message: '直播间不存在' });
        }
        
        // 获取更新后的直播间信息
        const [rooms] = await pool.execute(
            `SELECT lr.*, u.nickname as anchor_name, u.avatar as anchor_avatar, g.name as game_name
             FROM live_rooms lr
             LEFT JOIN users u ON lr.user_id = u.id
             LEFT JOIN games g ON lr.game_id = g.id
             WHERE lr.id = ?`,
            [id]
        );
        
        res.json({ success: true, message: '直播间状态更新成功', data: rooms[0] });
    } catch (error) {
        console.error('更新直播间状态错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取单个直播间信息
app.get('/api/live-rooms/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const [rooms] = await pool.execute(
            `SELECT lr.*, u.nickname as anchor_name, u.avatar as anchor_avatar, g.name as game_name
             FROM live_rooms lr
             LEFT JOIN users u ON lr.user_id = u.id
             LEFT JOIN games g ON lr.game_id = g.id
             WHERE lr.id = ?`,
            [id]
        );
        
        if (rooms.length === 0) {
            return res.status(404).json({ success: false, message: '直播间不存在' });
        }
        
        res.json({ success: true, data: rooms[0] });
    } catch (error) {
        console.error('获取直播间信息错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取服务器状态
app.get('/api/server/status', async (req, res) => {
    try {
        // 获取基本统计信息
        const [userCount] = await pool.execute('SELECT COUNT(*) as total FROM users');
        const [onlineUsers] = await pool.execute('SELECT COUNT(*) as online FROM users WHERE status = 0');
        const [activeRooms] = await pool.execute('SELECT COUNT(*) as active FROM live_rooms WHERE status = 1');
        
        res.json({
            success: true,
            status: {
                server_status: '在线',
                total_users: userCount[0].total,
                online_users: onlineUsers[0].online,
                active_rooms: activeRooms[0].active,
                uptime: process.uptime(),
                memory_usage: process.memoryUsage(),
                timestamp: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('获取服务器状态错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取仪表板统计数据
app.get('/api/stats/dashboard', async (req, res) => {
    try {
        // 获取基本统计信息
        const [userCount] = await pool.execute('SELECT COUNT(*) as total FROM users');
        const [onlineUsers] = await pool.execute('SELECT COUNT(*) as online FROM users WHERE status = 0');
        const [activeRooms] = await pool.execute('SELECT COUNT(*) as active FROM live_rooms WHERE status = 1');
        const [totalRooms] = await pool.execute('SELECT COUNT(*) as total FROM live_rooms');
        
        // 获取今日新增用户
        const [todayUsers] = await pool.execute('SELECT COUNT(*) as today FROM users WHERE DATE(created_at) = CURDATE()');
        
        // 获取今日新增直播间
        const [todayRooms] = await pool.execute('SELECT COUNT(*) as today FROM live_rooms WHERE DATE(created_at) = CURDATE()');
        
        res.json({
            success: true,
            data: {
                users: {
                    total: userCount[0].total,
                    online: onlineUsers[0].online,
                    today: todayUsers[0].today
                },
                rooms: {
                    total: totalRooms[0].total,
                    active: activeRooms[0].active,
                    today: todayRooms[0].today
                },
                server: {
                    status: '在线',
                    uptime: process.uptime(),
                    memory_usage: process.memoryUsage()
                }
            }
        });
    } catch (error) {
        console.error('获取仪表板统计数据错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 健康检查
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// 客服相关API

// 创建客服会话
app.post('/api/customer-service/sessions', async (req, res) => {
    try {
        const { user_id, subject } = req.body;
        
        if (!user_id) {
            return res.status(400).json({ success: false, message: '用户ID不能为空' });
        }
        
        // 检查是否已有活跃会话
        const [existingSessions] = await pool.execute(
            'SELECT * FROM messages WHERE sender_id = ? AND chat_type = "customer_service" AND created_at > DATE_SUB(NOW(), INTERVAL 1 DAY) ORDER BY created_at DESC LIMIT 1',
            [user_id]
        );
        
        let sessionId;
        if (existingSessions.length > 0) {
            sessionId = existingSessions[0].receiver_id || 'cs_001';
        } else {
            sessionId = 'cs_001'; // 默认客服ID
        }
        
        res.json({ 
            success: true, 
            data: {
                session_id: `${user_id}_${sessionId}`,
                agent_id: sessionId,
                user_id: user_id,
                status: 'active',
                created_at: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('创建客服会话错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取客服会话消息
app.get('/api/customer-service/sessions/:sessionId/messages', async (req, res) => {
    try {
        const { sessionId } = req.params;
        const { page = 1, limit = 50 } = req.query;
        
        const offset = (page - 1) * limit;
        
        // 从sessionId中提取user_id
        const userId = sessionId.split('_')[0];
        
        const [messages] = await pool.execute(
            `SELECT m.*, u.nickname as sender_name, u.avatar as sender_avatar
             FROM messages m
             LEFT JOIN users u ON m.sender_id = u.id
             WHERE (m.sender_id = ? OR m.receiver_id = ?) AND m.chat_type = 'customer_service'
             ORDER BY m.created_at DESC
             LIMIT ? OFFSET ?`,
            [userId, userId, parseInt(limit), offset]
        );
        
        res.json({ success: true, data: messages.reverse() });
    } catch (error) {
        console.error('获取客服消息错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 发送客服消息
app.post('/api/customer-service/messages', async (req, res) => {
    try {
        const { session_id, sender_id, content, message_type = 'text' } = req.body;
        
        if (!session_id || !sender_id || !content) {
            return res.status(400).json({ success: false, message: '参数不完整' });
        }
        
        // 确定接收者ID
        const userId = session_id.split('_')[0];
        const receiverId = sender_id === userId ? 'cs_001' : userId;
        
        const [result] = await pool.execute(
            'INSERT INTO messages (sender_id, receiver_id, content, message_type, chat_type, created_at) VALUES (?, ?, ?, ?, "customer_service", NOW())',
            [sender_id, receiverId, content, message_type]
        );
        
        // 获取刚插入的消息
        const [newMessage] = await pool.execute(
            `SELECT m.*, u.nickname as sender_name, u.avatar as sender_avatar
             FROM messages m
             LEFT JOIN users u ON m.sender_id = u.id
             WHERE m.id = ?`,
            [result.insertId]
        );
        
        res.json({ success: true, data: newMessage[0] });
    } catch (error) {
        console.error('发送客服消息错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取在线客服列表
app.get('/api/customer-service/agents', async (req, res) => {
    try {
        const [agents] = await pool.execute(
            `SELECT u.id, u.nickname, u.avatar, uk.kefu_nickname, uk.kefu_tags
             FROM users u
             LEFT JOIN users_kefu uk ON u.id = uk.user_id
             WHERE u.user_type = 3 AND u.status = 0
             ORDER BY u.created_at ASC`
        );
        
        res.json({ success: true, data: agents });
    } catch (error) {
        console.error('获取客服列表错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// 获取快捷回复模板
app.get('/api/customer-service/quick-replies', async (req, res) => {
    try {
        // 模拟快捷回复数据
        const quickReplies = [
            { id: '1', title: '问候语', content: '您好！我是客服小助手，有什么可以帮助您的吗？' },
            { id: '2', title: '账户问题', content: '关于账户问题，请提供您的用户ID，我来为您查询。' },
            { id: '3', title: '充值问题', content: '充值遇到问题了吗？请告诉我具体情况，我来帮您处理。' },
            { id: '4', title: '直播问题', content: '直播功能有问题吗？请详细描述一下遇到的情况。' },
            { id: '5', title: '结束语', content: '问题已为您解决，如还有其他疑问请随时联系我们！' }
        ];
        
        res.json({ success: true, data: quickReplies });
    } catch (error) {
        console.error('获取快捷回复错误：', error);
        res.status(500).json({ success: false, message: '服务器内部错误' });
    }
});

// API测试端点
app.get('/api/test', (req, res) => {
    res.json({ 
        success: true, 
        message: 'API服务器连接正常', 
        timestamp: new Date().toISOString(),
        server: 'guifei-live-api'
    });
});

// 错误处理中间件
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ success: false, message: '服务器内部错误' });
});

// 404处理
app.use((req, res) => {
    res.status(404).json({ success: false, message: '接口不存在' });
});

// 启动服务器
app.listen(PORT, () => {
    console.log(`API服务器运行在端口 ${PORT}`);
    console.log(`健康检查: http://localhost:${PORT}/health`);
});

module.exports = app;