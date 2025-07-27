const mysql = require('mysql2/promise');
require('dotenv').config();

// 数据库配置
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'guifei_live',
    waitForConnections: true,
    connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT) || 10,
    queueLimit: 0,
    acquireTimeout: parseInt(process.env.DB_ACQUIRE_TIMEOUT) || 60000,
    timeout: parseInt(process.env.DB_TIMEOUT) || 60000,
    reconnect: true,
    charset: 'utf8mb4'
};

// 创建连接池
const pool = mysql.createPool(dbConfig);

// 测试数据库连接
async function testConnection() {
    try {
        const connection = await pool.getConnection();
        console.log('数据库连接成功');
        connection.release();
        return true;
    } catch (error) {
        console.error('数据库连接失败:', error.message);
        return false;
    }
}

// 生成12位UUID（字母和数字组合）
function generateUserId(prefix = '') {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = prefix;
    const remainingLength = 12 - prefix.length;
    
    for (let i = 0; i < remainingLength; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

// 用户类型常量
const USER_TYPES = {
    CONSUMER: 1,    // 普通用户
    ANCHOR: 2,      // 主播
    SERVICE: 3,     // 客服
    ADMIN: 4        // 管理员
};

// 用户状态常量
const USER_STATUS = {
    NORMAL: 0,      // 正常
    DISABLED: 1,    // 禁用
    FROZEN: 2       // 冻结
};

// 消息类型常量
const MESSAGE_TYPES = {
    TEXT: 1,        // 文本
    IMAGE: 2,       // 图片
    VIDEO: 3,       // 视频
    VOICE: 4        // 语音
};

// 聊天类型常量
const CHAT_TYPES = {
    PRIVATE: 1,     // 私聊
    GROUP: 2,       // 群聊
    LIVE_ROOM: 3    // 直播间
};

// 直播间状态常量
const LIVE_ROOM_STATUS = {
    NOT_STARTED: 0, // 未开播
    LIVE: 1,        // 直播中
    ENDED: 2        // 已结束
};

// 分类类型常量
const CATEGORY_TYPES = {
    VIDEO: 1,       // 视频
    LIVE: 2,        // 直播
    GAME: 3         // 游戏
};

// 消费等级计算函数
function calculateConsumptionLevel(totalSpent) {
    if (totalSpent < 100) return 1;
    if (totalSpent < 200) return 2;
    if (totalSpent < 500) return 3;
    if (totalSpent < 1000) return 4;
    if (totalSpent < 1500) return 5;
    if (totalSpent < 2000) return 6;
    
    // 2000元以上，每500元增加1级
    const additionalLevels = Math.floor((totalSpent - 2000) / 500);
    return 7 + additionalLevels;
}

// 检查用户是否可以评论
function canComment(consumptionLevel) {
    return consumptionLevel >= 2;
}

// 检查用户是否可以连麦
function canConnectMic(consumptionLevel) {
    return consumptionLevel >= 20;
}

// 数据库查询辅助函数
class DatabaseHelper {
    static async executeQuery(sql, params = []) {
        try {
            const [results] = await pool.execute(sql, params);
            return results;
        } catch (error) {
            console.error('数据库查询错误:', error);
            throw error;
        }
    }
    
    static async findUserById(userId) {
        const sql = 'SELECT * FROM users WHERE id = ?';
        const results = await this.executeQuery(sql, [userId]);
        return results[0] || null;
    }
    
    static async findUserByUsername(username) {
        const sql = 'SELECT * FROM users WHERE username = ?';
        const results = await this.executeQuery(sql, [username]);
        return results[0] || null;
    }
    
    static async updateUserConsumption(userId, amount) {
        const connection = await pool.getConnection();
        try {
            await connection.beginTransaction();
            
            // 更新消费金额
            await connection.execute(
                'UPDATE users_consumer SET total_spent = total_spent + ?, balance = balance - ? WHERE user_id = ?',
                [amount, amount, userId]
            );
            
            // 获取新的消费总额
            const [results] = await connection.execute(
                'SELECT total_spent FROM users_consumer WHERE user_id = ?',
                [userId]
            );
            
            if (results.length > 0) {
                const newLevel = calculateConsumptionLevel(results[0].total_spent);
                await connection.execute(
                    'UPDATE users_consumer SET consumption_level = ? WHERE user_id = ?',
                    [newLevel, userId]
                );
            }
            
            await connection.commit();
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }
}

module.exports = {
    pool,
    dbConfig,
    testConnection,
    generateUserId,
    USER_TYPES,
    USER_STATUS,
    MESSAGE_TYPES,
    CHAT_TYPES,
    LIVE_ROOM_STATUS,
    CATEGORY_TYPES,
    calculateConsumptionLevel,
    canComment,
    canConnectMic,
    DatabaseHelper
};