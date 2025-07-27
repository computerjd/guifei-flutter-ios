const { pool, generateUserId, USER_TYPES, DatabaseHelper } = require('./config');
const readline = require('readline');

// 创建命令行接口
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// 提示用户输入
function question(prompt) {
    return new Promise((resolve) => {
        rl.question(prompt, resolve);
    });
}

// 创建用户
async function createUser(userData) {
    const connection = await pool.getConnection();
    try {
        await connection.beginTransaction();
        
        const userId = generateUserId();
        
        // 插入用户基本信息
        await connection.execute(
            'INSERT INTO users (id, username, phone, password, avatar, nickname, gender, birthday, register_time, user_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURDATE(), ?)',
            [
                userId,
                userData.username,
                userData.phone,
                userData.password,
                userData.avatar || null,
                userData.nickname,
                userData.gender || 1,
                userData.birthday || '2000-01-01',
                userData.user_type
            ]
        );
        
        // 根据用户类型插入扩展表数据
        switch (userData.user_type) {
            case USER_TYPES.CONSUMER:
                await connection.execute(
                    'INSERT INTO users_consumer (user_id) VALUES (?)',
                    [userId]
                );
                break;
            case USER_TYPES.ANCHOR:
                await connection.execute(
                    'INSERT INTO users_live (user_id) VALUES (?)',
                    [userId]
                );
                break;
            case USER_TYPES.SERVICE:
                await connection.execute(
                    'INSERT INTO users_kefu (user_id, kefu_register_time) VALUES (?, CURDATE())',
                    [userId]
                );
                break;
            case USER_TYPES.ADMIN:
                await connection.execute(
                    'INSERT INTO users_admin (user_id, admin_register_time) VALUES (?, CURDATE())',
                    [userId]
                );
                break;
        }
        
        await connection.commit();
        console.log(`用户创建成功！用户ID: ${userId}`);
        return userId;
        
    } catch (error) {
        await connection.rollback();
        console.error('创建用户失败:', error.message);
        throw error;
    } finally {
        connection.release();
    }
}

// 列出所有用户
async function listUsers(userType = null) {
    try {
        let sql = `
            SELECT u.id, u.username, u.phone, u.nickname, u.user_type, u.status, u.register_time,
                   CASE u.user_type
                       WHEN 1 THEN '普通用户'
                       WHEN 2 THEN '主播'
                       WHEN 3 THEN '客服'
                       WHEN 4 THEN '管理员'
                       ELSE '未知'
                   END as user_type_name
            FROM users u
        `;
        
        const params = [];
        if (userType) {
            sql += ' WHERE u.user_type = ?';
            params.push(userType);
        }
        
        sql += ' ORDER BY u.register_time DESC';
        
        const users = await DatabaseHelper.executeQuery(sql, params);
        
        console.log('\n用户列表:');
        console.log('ID\t\t用户名\t\t昵称\t\t类型\t\t状态\t注册时间');
        console.log('-'.repeat(80));
        
        users.forEach(user => {
            const status = user.status === 0 ? '正常' : user.status === 1 ? '禁用' : '冻结';
            console.log(`${user.id}\t${user.username}\t\t${user.nickname}\t\t${user.user_type_name}\t\t${status}\t${user.register_time}`);
        });
        
        return users;
    } catch (error) {
        console.error('获取用户列表失败:', error.message);
        throw error;
    }
}

// 更新用户状态
async function updateUserStatus(userId, status) {
    try {
        await DatabaseHelper.executeQuery(
            'UPDATE users SET status = ? WHERE id = ?',
            [status, userId]
        );
        
        const statusText = status === 0 ? '正常' : status === 1 ? '禁用' : '冻结';
        console.log(`用户 ${userId} 状态已更新为: ${statusText}`);
    } catch (error) {
        console.error('更新用户状态失败:', error.message);
        throw error;
    }
}

// 删除用户
async function deleteUser(userId) {
    try {
        const user = await DatabaseHelper.findUserById(userId);
        if (!user) {
            console.log('用户不存在');
            return;
        }
        
        await DatabaseHelper.executeQuery('DELETE FROM users WHERE id = ?', [userId]);
        console.log(`用户 ${userId} (${user.username}) 已删除`);
    } catch (error) {
        console.error('删除用户失败:', error.message);
        throw error;
    }
}

// 重置用户密码
async function resetPassword(userId, newPassword) {
    try {
        await DatabaseHelper.executeQuery(
            'UPDATE users SET password = ? WHERE id = ?',
            [newPassword, userId]
        );
        console.log(`用户 ${userId} 密码已重置`);
    } catch (error) {
        console.error('重置密码失败:', error.message);
        throw error;
    }
}

// 交互式创建用户
async function interactiveCreateUser() {
    try {
        console.log('\n=== 创建新用户 ===');
        
        const username = await question('请输入用户名: ');
        const phone = await question('请输入手机号: ');
        const password = await question('请输入密码: ');
        const nickname = await question('请输入昵称: ');
        
        console.log('\n用户类型:');
        console.log('1. 普通用户');
        console.log('2. 主播');
        console.log('3. 客服');
        console.log('4. 管理员');
        
        const userTypeInput = await question('请选择用户类型 (1-4): ');
        const userType = parseInt(userTypeInput);
        
        if (userType < 1 || userType > 4) {
            console.log('无效的用户类型');
            return;
        }
        
        const gender = await question('请输入性别 (1男 2女, 默认1): ') || '1';
        const birthday = await question('请输入生日 (YYYY-MM-DD, 默认2000-01-01): ') || '2000-01-01';
        
        const userData = {
            username,
            phone,
            password,
            nickname,
            user_type: userType,
            gender: parseInt(gender),
            birthday
        };
        
        await createUser(userData);
        
    } catch (error) {
        console.error('创建用户失败:', error.message);
    }
}

// 主菜单
async function mainMenu() {
    while (true) {
        console.log('\n=== 用户管理系统 ===');
        console.log('1. 创建用户');
        console.log('2. 查看所有用户');
        console.log('3. 查看普通用户');
        console.log('4. 查看主播');
        console.log('5. 查看客服');
        console.log('6. 查看管理员');
        console.log('7. 更新用户状态');
        console.log('8. 重置用户密码');
        console.log('9. 删除用户');
        console.log('0. 退出');
        
        const choice = await question('请选择操作: ');
        
        try {
            switch (choice) {
                case '1':
                    await interactiveCreateUser();
                    break;
                case '2':
                    await listUsers();
                    break;
                case '3':
                    await listUsers(USER_TYPES.CONSUMER);
                    break;
                case '4':
                    await listUsers(USER_TYPES.ANCHOR);
                    break;
                case '5':
                    await listUsers(USER_TYPES.SERVICE);
                    break;
                case '6':
                    await listUsers(USER_TYPES.ADMIN);
                    break;
                case '7':
                    const userId1 = await question('请输入用户ID: ');
                    const status = await question('请输入新状态 (0正常 1禁用 2冻结): ');
                    await updateUserStatus(userId1, parseInt(status));
                    break;
                case '8':
                    const userId2 = await question('请输入用户ID: ');
                    const newPassword = await question('请输入新密码: ');
                    await resetPassword(userId2, newPassword);
                    break;
                case '9':
                    const userId3 = await question('请输入用户ID: ');
                    const confirm = await question('确认删除用户? (y/N): ');
                    if (confirm.toLowerCase() === 'y') {
                        await deleteUser(userId3);
                    }
                    break;
                case '0':
                    console.log('再见!');
                    rl.close();
                    process.exit(0);
                    break;
                default:
                    console.log('无效的选择');
            }
        } catch (error) {
            console.error('操作失败:', error.message);
        }
    }
}

// 如果直接运行此文件，启动交互式菜单
if (require.main === module) {
    console.log('正在连接数据库...');
    mainMenu().catch(console.error);
}

module.exports = {
    createUser,
    listUsers,
    updateUserStatus,
    deleteUser,
    resetPassword
};