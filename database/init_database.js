const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// 数据库配置
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true
};

async function initDatabase() {
    let connection;
    
    try {
        console.log('正在连接MySQL服务器...');
        
        // 连接到MySQL服务器（不指定数据库）
        connection = await mysql.createConnection(dbConfig);
        
        console.log('MySQL连接成功！');
        
        // 读取schema.sql文件
        const schemaPath = path.join(__dirname, 'schema.sql');
        const schemaSql = fs.readFileSync(schemaPath, 'utf8');
        
        console.log('正在执行数据库初始化脚本...');
        
        // 首先创建数据库
        await connection.query('CREATE DATABASE IF NOT EXISTS guifei_live CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
        await connection.query('USE guifei_live');
        
        // 分割SQL语句并逐个执行（跳过数据库创建和USE语句）
        const sqlStatements = schemaSql
            .split(';')
            .map(stmt => stmt.trim())
            .filter(stmt => 
                stmt.length > 0 && 
                !stmt.startsWith('--') && 
                !stmt.startsWith('CREATE DATABASE') &&
                !stmt.startsWith('USE guifei_live')
            );
        
        for (const statement of sqlStatements) {
            if (statement.trim()) {
                try {
                    await connection.query(statement);
                } catch (error) {
                    console.log(`执行语句失败: ${statement.substring(0, 50)}...`);
                    console.error('错误:', error.message);
                    // 继续执行其他语句
                }
            }
        }
        
        console.log('数据库初始化完成！');
        console.log('已创建数据库：guifei_live');
        console.log('已创建所有表结构');
        console.log('已插入初始数据');
        
        // 验证数据插入
        const [users] = await connection.query('SELECT username, nickname, user_type FROM users');
        console.log('\n初始用户数据：');
        users.forEach(user => {
            const userTypeMap = {1: '普通用户', 2: '主播', 3: '客服', 4: '管理员'};
            console.log(`- ${user.username} (${user.nickname}) - ${userTypeMap[user.user_type]}`);
        });
        
        const [games] = await connection.query('SELECT name, description FROM games');
        console.log('\n游戏数据：');
        games.forEach(game => {
            console.log(`- ${game.name}: ${game.description}`);
        });
        
        const [gifts] = await connection.query('SELECT name, price FROM gift_types');
        console.log('\n礼物数据：');
        gifts.forEach(gift => {
            console.log(`- ${gift.name}: ${gift.price}元`);
        });
        
    } catch (error) {
        console.error('数据库初始化失败：', error.message);
        process.exit(1);
    } finally {
        if (connection) {
            await connection.end();
            console.log('\n数据库连接已关闭');
        }
    }
}

// 运行初始化
if (require.main === module) {
    initDatabase();
}

module.exports = { initDatabase };