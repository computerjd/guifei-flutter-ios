## app进一步规划

# 数据库重新设计，原有数据无需保存，但是依然必须使用MySQL（原来的数据库我已经删除）

## 1. 核心用户表 (users)

```
- id: 主键ID (UUID:长度固定为12位，由字母和数字组成)
- username: 用户名/账号
- phone: 手机号 
- password: 密码 
- avatar: 头像
- nickname: 昵称
- gender: 性别 (1男 2女)
- birthday: 生日
- status: 状态 (0正常 1禁用 2冻结)
- register_time: 注册时间（年月日即可不需要时分秒）
- user_type: 用户类型 (1普通用户 2主播 3客服 4管理员)
```

## 2. 消费者扩展表 (users_consumer)

```
- user_id: 关联用户ID
- vip_level: VIP等级
- vip_expire: VIP到期时间
- consumption_level: 消费等级
- balance: 账户余额
- total_spent: 累计消费金额
- watch_history: 观看历史(关联或JSON)

```

## 3. 主播扩展表 (users_live)

```
- user_id: 关联用户ID
- live_level: 主播等级
- fans_count: 粉丝数
- total_income: 总收入
- withdrawable: 可提现金额
- withdrawn: 已提现金额
- live_tags: 直播标签(JSON)
- verify_status: 认证状态
- live_notice: 直播公告
```

## 4. 视频内容表 (videos)

```
- id: 视频ID
- title: 视频标题
- description: 视频描述
- cover: 封面图
- video: 视频文件
- duration: 视频时长(秒)
- width: 视频宽度
- height: 视频高度
- format: 视频格式
- size: 视频大小(MB)
- user_id: 上传用户ID
- category_id: 分类ID
- tags: 标签(JSON)
- view_count: 观看次数
- like_count: 点赞数
- share_count: 分享数
- collect_count: 收藏数
- create_time: 创建时间
- resolution: 分辨率信息(JSON)
```

## 5. 直播间表 (live_rooms)

```
- id: 直播间ID
- user_id: 主播ID
- title: 直播标题
- cover_url: 封面图URL
- live_url: 直播流地址
- category_id: 分类ID
- tags: 标签(JSON)
- online_count: 当前在线人数
- like_count: 点赞数
- gift_income: 礼物收入
- status: 状态(0未开播 1直播中 2已结束)
- start_time: 开始时间
- end_time: 结束时间
- duration: 直播时长(小时)

```

## 6. 游戏表 (games)

```
- id: 游戏ID
- name: 游戏名称
- icon: 游戏图标
- cover: 游戏封面
- description: 游戏描述

```

## 7. 客服扩展表 (users_kefu)

```
- user_id: 关联用户ID
- kefu_tags: 客服标签(JSON)
- kefu_avatar: 客服头像
- kefu_nickname: 客服昵称
- kefu_register_time: 客服注册时间
```

## 8. 消息/聊天表 (messages)

```
- id: 消息ID
- sender_id: 发送者ID
- receiver_id: 接收者ID/群ID
- content: 消息内容
- type: 消息类型(1文本 2图片 3视频 4语音)
- status: 状态(0未读 1已读 2撤回)
- create_time: 发送时间
- read_time: 阅读时间
- chat_type: 聊天类型(1私聊 2群聊 3直播间)
- relation_id: 关联ID(直播间ID等)
- extra: 附加信息(JSON)
- is_deleted: 是否删除
```

## 9. 系统通用表设计

### 分类表 (categories)
```
- id: 分类ID
- name: 分类名称
- type: 分类类型(1视频 2直播 3游戏)
- icon: 分类图标
- sort: 排序权重
- status: 状态
- parent_id: 父分类ID
```

### 配置表 (configs)
```
- id: 配置ID
- key: 配置键
- value: 配置值
- description: 配置描述
- group: 配置分组
- type: 值类型(string,number,boolean,json)
- is_system: 是否系统配置
```

### 文件表 (files)
```
- id: 文件ID
- name: 原始文件名
- path: 存储路径
- url: 访问URL
- size: 文件大小
- type: 文件类型
- extension: 文件扩展名
- md5: 文件MD5
- user_id: 上传用户
- create_time: 上传时间
- status: 状态
```
## 10. 管理员扩展表(users_admin)
```
- user_id: 关联用户ID
- admin_tags: 管理员标签(JSON)
- admin_avatar: 管理员头像
- admin_nickname: 管理员昵称
- admin_register_time: 管理员注册时间
```
## 11.礼物类型表(gift_types)
```
- id: 礼物ID
- name: 礼物名称
- icon: 礼物图标
- price: 礼物价格
```
插入的管理员账号
```
- username: admin01
- phone: 13800000000
- password: 123456
- avatar: assets\images\管理员默认头像.png
- nickname: 管理员
- gender: 1
- birthday: 2000-01-01
- status: 0
- register_time: 2023-01-01
- user_type: 4
```
插入的用户账号
```
- username: user01
- phone: 13800000001
- password: 123456
- avatar: assets\images\用户默认头像.png
- nickname: 用户
- gender: 1
- birthday: 2000-01-01
- status: 0
- register_time: 2023-01-01
- user_type: 1
```
插入的主播账号
```
- username: live01
- phone: 13800000002
- password: 123456
- avatar: assets\images\主播默认头像.png
- nickname: 主播
- gender: 1
- birthday: 2000-01-01
- status: 0
- register_time: 2023-01-01
- user_type: 2
```
插入的客服账号
```
- username: kefu01
- phone: 13800000003
- password: 123456
- avatar: assets\images\客服默认头像.png
- nickname: 客服
- gender: 1
- birthday: 2000-01-01
- status: 0
- register_time: 2023-01-01
- user_type: 3
```
插入的游戏名字
```
- name: 一分快三
- icon: assets\images\一分快三.png
- cover: assets\images\一分快三.png
- description: 这是一个简单的游戏，玩家在游戏中需要在规定时间内完成选择并下注。
```
```
- name: 时时彩
- icon: assets\images\时时彩.png
- cover: assets\images\时时彩.png
- description: 这是一个简单的游戏，玩家在游戏中需要在规定时间内完成选择并下注。
```

插入的礼物
```
- name: 小心心
- icon: assets\images\小心心.png
- price: 1元
```
```
- name: 墨镜
- icon: assets\images\墨镜.png
- price: 10元
```
```
- name: 豪华游轮
- icon: assets\images\豪华游轮.png
- price: 400元
```
```
- name: Kitty城堡
- icon: assets\images\Kitty城堡.png
- price: 1000元
```

特别注意：数据库创建时可以小改但不能大改，插入的数据不能改。


## 关于消费者表中的消费等级-按照充值金额计算，影响在直播间的等级显示

```
充值0元即默认等级：1级（不可在直播间评论）
充值满100元：2级（可在直播间评论）
充值满200元：3级（可在直播间评论）
充值满500元：4级（可在直播间评论）
充值满1000元：5级（可在直播间评论）
充值满1500元：6级（可在直播间评论）
充值满2000元：7级（可在直播间评论）
往后每充值500元，等级加1级。（可在直播间评论）
当用户达到20级及以后时，用户可以解锁在直播间连麦。

```
## 关于直播间需要展示游戏

```
主播在开启直播时，需要选择一款游戏表的游戏当作挂件。
用户在直播间玩这个游戏时，下注会有系统消息在直播间评论，如：用户****下注了10元。如果获利则会有系统消息在直播间评论，如：用户****获利了10元。没有获利则不会有系统消息在直播间评论。
```

## 关于游戏

```
游戏表的游戏有：一分快三、时时彩。
游戏表的游戏的规则：
1. 一分快三：玩家需要在规定时间内完成选择并下注。
2. 时时彩：玩家需要在规定时间内完成选择并下注。


---

## ✅ **简化玩法设计方案（共4种）**

| 玩法名称      | 说明                              | 投注选项示例                               | 赔率示例           |
| --------- | ------------------------------- | ------------------------------------ | -------------- |
| **大小单双**  | 投注“点数总和”的大小/单双，简单直观，用户认知低成本     | 大、小、单、双                              | 1.95倍          |
| **猜和值区间** | 将点数总和（3\~18）划分为4个区间，玩家选择一个区间即可  | 小（3~~6）、中（7~~10）、中（11~~14）、大（15~~18） | 3.5倍           |
| **猜豹子**   | 猜三个点数是否全相同（111、222等），极少数中，高赔率刺激 | “豹子”或“非豹子”                           | 豹子20倍 非豹子1.05倍 |
| **猜点数之和** | 玩家直接猜3个骰子的和（3\~18），属于高难高回报      | 任选一个和值，如10或17等                       | 9.5\~180倍浮动    |

> 注：数据可调整，支持动态赔率或固定赔率系统。

---

## ⏱ **开奖规则**

* **开奖频率**：每 **2分钟一期**
* **全天开放**：24小时 \* 30期/小时 = **720期/天**
* **期号命名**：`yyyyMMdd + 期数`，如：

  * 第1期：`20250726001`
  * 第69期：`20250728069`

> 系统可自动编号，每天从001开始递增，不跨天累加。

点数由管理员生成

```

## 关于登录注册

```
用户端app，主播端app，客服端app的登录注册界面都类似
管理员端是一个web后台管理系统，没有注册，只能登录
另外生成的UUID:长度固定为12位，由字母和数字组成时字母和数字可以交叉

```


！！！如果你对我的描述有需要更改的地方，请把更改的内容描述写在这个文件！！！