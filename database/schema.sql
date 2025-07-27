-- 贵妃直播应用数据库设计
-- 创建数据库
CREATE DATABASE IF NOT EXISTS guifei_live CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE guifei_live;

-- 1. 核心用户表 (users)
CREATE TABLE users (
    id VARCHAR(12) PRIMARY KEY COMMENT '主键ID (UUID:长度固定为12位，由字母和数字组成)',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名/账号',
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
    password VARCHAR(255) NOT NULL COMMENT '密码',
    avatar VARCHAR(500) DEFAULT NULL COMMENT '头像',
    nickname VARCHAR(100) NOT NULL COMMENT '昵称',
    gender TINYINT(1) NOT NULL DEFAULT 1 COMMENT '性别 (1男 2女)',
    birthday DATE NOT NULL COMMENT '生日',
    status TINYINT(1) NOT NULL DEFAULT 0 COMMENT '状态 (0正常 1禁用 2冻结)',
    register_time DATE NOT NULL COMMENT '注册时间（年月日即可不需要时分秒）',
    user_type TINYINT(1) NOT NULL DEFAULT 1 COMMENT '用户类型 (1普通用户 2主播 3客服 4管理员)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='核心用户表';

-- 2. 消费者扩展表 (users_consumer)
CREATE TABLE users_consumer (
    user_id VARCHAR(12) PRIMARY KEY COMMENT '关联用户ID',
    vip_level INT NOT NULL DEFAULT 0 COMMENT 'VIP等级',
    vip_expire DATE DEFAULT NULL COMMENT 'VIP到期时间',
    consumption_level INT NOT NULL DEFAULT 1 COMMENT '消费等级',
    balance DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '账户余额',
    total_spent DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '累计消费金额',
    watch_history JSON DEFAULT NULL COMMENT '观看历史(关联或JSON)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='消费者扩展表';

-- 3. 主播扩展表 (users_live)
CREATE TABLE users_live (
    user_id VARCHAR(12) PRIMARY KEY COMMENT '关联用户ID',
    live_level INT NOT NULL DEFAULT 1 COMMENT '主播等级',
    fans_count INT NOT NULL DEFAULT 0 COMMENT '粉丝数',
    total_income DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '总收入',
    withdrawable DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '可提现金额',
    withdrawn DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '已提现金额',
    live_tags JSON DEFAULT NULL COMMENT '直播标签(JSON)',
    verify_status TINYINT(1) NOT NULL DEFAULT 0 COMMENT '认证状态',
    live_notice TEXT DEFAULT NULL COMMENT '直播公告',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='主播扩展表';

-- 4. 客服扩展表 (users_kefu)
CREATE TABLE users_kefu (
    user_id VARCHAR(12) PRIMARY KEY COMMENT '关联用户ID',
    kefu_tags JSON DEFAULT NULL COMMENT '客服标签(JSON)',
    kefu_avatar VARCHAR(500) DEFAULT NULL COMMENT '客服头像',
    kefu_nickname VARCHAR(100) DEFAULT NULL COMMENT '客服昵称',
    kefu_register_time DATE DEFAULT NULL COMMENT '客服注册时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='客服扩展表';

-- 5. 管理员扩展表(users_admin)
CREATE TABLE users_admin (
    user_id VARCHAR(12) PRIMARY KEY COMMENT '关联用户ID',
    admin_tags JSON DEFAULT NULL COMMENT '管理员标签(JSON)',
    admin_avatar VARCHAR(500) DEFAULT NULL COMMENT '管理员头像',
    admin_nickname VARCHAR(100) DEFAULT NULL COMMENT '管理员昵称',
    admin_register_time DATE DEFAULT NULL COMMENT '管理员注册时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员扩展表';

-- 6. 分类表 (categories)
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT '分类ID',
    name VARCHAR(100) NOT NULL COMMENT '分类名称',
    type TINYINT(1) NOT NULL COMMENT '分类类型(1视频 2直播 3游戏)',
    icon VARCHAR(500) DEFAULT NULL COMMENT '分类图标',
    sort INT NOT NULL DEFAULT 0 COMMENT '排序权重',
    status TINYINT(1) NOT NULL DEFAULT 1 COMMENT '状态',
    parent_id INT DEFAULT NULL COMMENT '父分类ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='分类表';

-- 7. 游戏表 (games)
CREATE TABLE games (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT '游戏ID',
    name VARCHAR(100) NOT NULL COMMENT '游戏名称',
    icon VARCHAR(500) DEFAULT NULL COMMENT '游戏图标',
    cover VARCHAR(500) DEFAULT NULL COMMENT '游戏封面',
    description TEXT DEFAULT NULL COMMENT '游戏描述',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='游戏表';

-- 8. 礼物类型表(gift_types)
CREATE TABLE gift_types (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT '礼物ID',
    name VARCHAR(100) NOT NULL COMMENT '礼物名称',
    icon VARCHAR(500) DEFAULT NULL COMMENT '礼物图标',
    price DECIMAL(10,2) NOT NULL COMMENT '礼物价格',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='礼物类型表';

-- 9. 视频内容表 (videos)
CREATE TABLE videos (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT '视频ID',
    title VARCHAR(200) NOT NULL COMMENT '视频标题',
    description TEXT DEFAULT NULL COMMENT '视频描述',
    cover VARCHAR(500) DEFAULT NULL COMMENT '封面图',
    video VARCHAR(500) NOT NULL COMMENT '视频文件',
    duration INT NOT NULL DEFAULT 0 COMMENT '视频时长(秒)',
    width INT DEFAULT NULL COMMENT '视频宽度',
    height INT DEFAULT NULL COMMENT '视频高度',
    format VARCHAR(20) DEFAULT NULL COMMENT '视频格式',
    size DECIMAL(10,2) DEFAULT NULL COMMENT '视频大小(MB)',
    user_id VARCHAR(12) NOT NULL COMMENT '上传用户ID',
    category_id INT DEFAULT NULL COMMENT '分类ID',
    tags JSON DEFAULT NULL COMMENT '标签(JSON)',
    view_count INT NOT NULL DEFAULT 0 COMMENT '观看次数',
    like_count INT NOT NULL DEFAULT 0 COMMENT '点赞数',
    share_count INT NOT NULL DEFAULT 0 COMMENT '分享数',
    collect_count INT NOT NULL DEFAULT 0 COMMENT '收藏数',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    resolution JSON DEFAULT NULL COMMENT '分辨率信息(JSON)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='视频内容表';

-- 10. 直播间表 (live_rooms)
CREATE TABLE live_rooms (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT '直播间ID',
    user_id VARCHAR(12) NOT NULL COMMENT '主播ID',
    title VARCHAR(200) NOT NULL COMMENT '直播标题',
    cover_url VARCHAR(500) DEFAULT NULL COMMENT '封面图URL',
    live_url VARCHAR(500) DEFAULT NULL COMMENT '直播流地址',
    category_id INT DEFAULT NULL COMMENT '分类ID',
    tags JSON DEFAULT NULL COMMENT '标签(JSON)',
    online_count INT NOT NULL DEFAULT 0 COMMENT '当前在线人数',
    like_count INT NOT NULL DEFAULT 0 COMMENT '点赞数',
    gift_income DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '礼物收入',
    status TINYINT(1) NOT NULL DEFAULT 0 COMMENT '状态(0未开播 1直播中 2已结束)',
    start_time TIMESTAMP NULL DEFAULT NULL COMMENT '开始时间',
    end_time TIMESTAMP NULL DEFAULT NULL COMMENT '结束时间',
    duration DECIMAL(5,2) DEFAULT NULL COMMENT '直播时长(小时)',
    game_id INT DEFAULT NULL COMMENT '关联游戏ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='直播间表';

-- 11. 消息/聊天表 (messages)
CREATE TABLE messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '消息ID',
    sender_id VARCHAR(12) NOT NULL COMMENT '发送者ID',
    receiver_id VARCHAR(12) DEFAULT NULL COMMENT '接收者ID/群ID',
    content TEXT NOT NULL COMMENT '消息内容',
    type TINYINT(1) NOT NULL DEFAULT 1 COMMENT '消息类型(1文本 2图片 3视频 4语音)',
    status TINYINT(1) NOT NULL DEFAULT 0 COMMENT '状态(0未读 1已读 2撤回)',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    read_time TIMESTAMP NULL DEFAULT NULL COMMENT '阅读时间',
    chat_type TINYINT(1) NOT NULL DEFAULT 1 COMMENT '聊天类型(1私聊 2群聊 3直播间)',
    relation_id VARCHAR(50) DEFAULT NULL COMMENT '关联ID(直播间ID等)',
    extra JSON DEFAULT NULL COMMENT '附加信息(JSON)',
    is_deleted TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否删除',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='消息/聊天表';

-- 12. 配置表 (configs)
CREATE TABLE configs (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT '配置ID',
    `key` VARCHAR(100) NOT NULL UNIQUE COMMENT '配置键',
    `value` TEXT DEFAULT NULL COMMENT '配置值',
    description VARCHAR(500) DEFAULT NULL COMMENT '配置描述',
    `group` VARCHAR(50) DEFAULT NULL COMMENT '配置分组',
    type VARCHAR(20) NOT NULL DEFAULT 'string' COMMENT '值类型(string,number,boolean,json)',
    is_system TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否系统配置',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='配置表';

-- 13. 文件表 (files)
CREATE TABLE files (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT '文件ID',
    name VARCHAR(255) NOT NULL COMMENT '原始文件名',
    path VARCHAR(500) NOT NULL COMMENT '存储路径',
    url VARCHAR(500) NOT NULL COMMENT '访问URL',
    size BIGINT NOT NULL COMMENT '文件大小',
    type VARCHAR(100) DEFAULT NULL COMMENT '文件类型',
    extension VARCHAR(20) DEFAULT NULL COMMENT '文件扩展名',
    md5 VARCHAR(32) DEFAULT NULL COMMENT '文件MD5',
    user_id VARCHAR(12) DEFAULT NULL COMMENT '上传用户',
    status TINYINT(1) NOT NULL DEFAULT 1 COMMENT '状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文件表';

-- 插入初始数据

-- 插入管理员账号
INSERT INTO users (id, username, phone, password, avatar, nickname, gender, birthday, status, register_time, user_type) VALUES
('ADM001234567', 'admin01', '13800000000', '123456', 'assets\\images\\管理员默认头像.png', '管理员', 1, '2000-01-01', 0, '2023-01-01', 4);

-- 插入用户账号
INSERT INTO users (id, username, phone, password, avatar, nickname, gender, birthday, status, register_time, user_type) VALUES
('USR001234567', 'user01', '13800000001', '123456', 'assets\\images\\用户默认头像.png', '用户', 1, '2000-01-01', 0, '2023-01-01', 1);

-- 插入主播账号
INSERT INTO users (id, username, phone, password, avatar, nickname, gender, birthday, status, register_time, user_type) VALUES
('LIV001234567', 'live01', '13800000002', '123456', 'assets\\images\\主播默认头像.png', '主播', 1, '2000-01-01', 0, '2023-01-01', 2);

-- 插入客服账号
INSERT INTO users (id, username, phone, password, avatar, nickname, gender, birthday, status, register_time, user_type) VALUES
('KEF001234567', 'kefu01', '13800000003', '123456', 'assets\\images\\客服默认头像.png', '客服', 1, '2000-01-01', 0, '2023-01-01', 3);

-- 插入对应的扩展表数据
INSERT INTO users_consumer (user_id) VALUES ('USR001234567');
INSERT INTO users_live (user_id) VALUES ('LIV001234567');
INSERT INTO users_kefu (user_id, kefu_register_time) VALUES ('KEF001234567', '2023-01-01');
INSERT INTO users_admin (user_id, admin_register_time) VALUES ('ADM001234567', '2023-01-01');

-- 插入游戏数据
INSERT INTO games (name, icon, cover, description) VALUES
('一分快三', 'assets\\images\\一分快三.png', 'assets\\images\\一分快三.png', '这是一个简单的游戏，玩家在游戏中需要在规定时间内完成选择并下注。'),
('时时彩', 'assets\\images\\时时彩.png', 'assets\\images\\时时彩.png', '这是一个简单的游戏，玩家在游戏中需要在规定时间内完成选择并下注。');

-- 插入礼物数据
INSERT INTO gift_types (name, icon, price) VALUES
('小心心', 'assets\\images\\小心心.png', 1.00),
('墨镜', 'assets\\images\\墨镜.png', 10.00),
('豪华游轮', 'assets\\images\\豪华游轮.png', 400.00),
('Kitty城堡', 'assets\\images\\Kitty城堡.png', 1000.00);

-- 创建索引
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_type ON users(user_type);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_chat_type ON messages(chat_type);
CREATE INDEX idx_live_rooms_user ON live_rooms(user_id);
CREATE INDEX idx_live_rooms_status ON live_rooms(status);
CREATE INDEX idx_videos_user ON videos(user_id);
CREATE INDEX idx_videos_category ON videos(category_id);