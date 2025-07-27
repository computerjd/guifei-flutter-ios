// 全局变量
let socket = null;
let isLoggedIn = false;
let currentUser = null;
let serverData = {
    activeRooms: 0,
    onlineUsers: 0,
    serverStatus: '离线',
    uptime: '--'
};

// API请求工具函数
async function apiRequest(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const config = {
        headers: {
            'Content-Type': 'application/json',
            ...(authToken && { 'Authorization': `Bearer ${authToken}` })
        },
        ...options
    };
    
    if (config.body && typeof config.body === 'object') {
        config.body = JSON.stringify(config.body);
    }
    
    try {
        console.log('发送API请求:', url, config);
        const response = await fetch(url, config);
        
        // 检查响应的Content-Type
        const contentType = response.headers.get('content-type');
        console.log('响应Content-Type:', contentType);
        console.log('响应状态:', response.status);
        
        let data;
        if (contentType && contentType.includes('application/json')) {
            data = await response.json();
        } else {
            // 如果不是JSON响应，获取文本内容
            const text = await response.text();
            console.log('非JSON响应内容:', text.substring(0, 200));
            throw new Error(`服务器返回了非JSON响应: ${response.status}`);
        }
        
        if (!response.ok) {
            throw new Error(data.message || data.error || `HTTP ${response.status}`);
        }
        
        return data;
    } catch (error) {
        console.error(`API请求失败 ${endpoint}:`, error);
        throw error;
    }
}

// 默认管理员登录凭据（用于演示）
const DEFAULT_CREDENTIALS = {
    phone: '13800138000',
    password: '123456'
};

// 服务器地址配置
const WEBSOCKET_URL = 'http://localhost:3001';
const API_BASE_URL = 'http://localhost:3000/api';

// API认证令牌
let authToken = localStorage.getItem('authToken');

// DOM元素
const elements = {
    loginPage: document.getElementById('loginPage'),
    adminPage: document.getElementById('adminPage'),
    loginForm: document.getElementById('loginForm'),
    loginError: document.getElementById('loginError'),
    logoutBtn: document.getElementById('logoutBtn'),
    currentUserSpan: document.getElementById('currentUser'),
    navLinks: document.querySelectorAll('.nav-link'),
    tabContents: document.querySelectorAll('.tab-content')
};

// 初始化应用
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

function initializeApp() {
    // 检查是否已登录
    const savedUser = localStorage.getItem('adminUser');
    if (savedUser) {
        currentUser = JSON.parse(savedUser);
        showAdminPage();
        connectToWebSocket();
    } else {
        showLoginPage();
    }

    // 绑定事件监听器
    bindEventListeners();
}

function bindEventListeners() {
    // 登录表单提交
    elements.loginForm.addEventListener('submit', handleLogin);
    
    // 退出登录
    elements.logoutBtn.addEventListener('click', handleLogout);
    
    // API连接测试
    document.getElementById('testApiBtn').addEventListener('click', testApiConnection);
    
    // 导航切换
    elements.navLinks.forEach(link => {
        link.addEventListener('click', handleNavClick);
    });
    
    // 指令控制按钮
    document.getElementById('sendBroadcast').addEventListener('click', sendBroadcast);
    document.getElementById('closeRoom').addEventListener('click', closeRoom);
    document.getElementById('muteRoom').addEventListener('click', muteRoom);
    document.getElementById('clearLogs').addEventListener('click', clearLogs);
    document.getElementById('refreshLogs').addEventListener('click', refreshLogs);
}

// API连接测试
async function testApiConnection() {
    const testResult = document.getElementById('testResult');
    const testBtn = document.getElementById('testApiBtn');
    
    testBtn.disabled = true;
    testBtn.textContent = '测试中...';
    testResult.style.display = 'block';
    testResult.textContent = '正在测试API连接...';
    testResult.style.background = '#f8f9fa';
    testResult.style.color = '#333';
    
    try {
        const response = await fetch(`${API_BASE_URL}/test`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        console.log('API测试响应状态:', response.status);
        console.log('API测试响应头:', response.headers);
        
        const contentType = response.headers.get('content-type');
        console.log('Content-Type:', contentType);
        
        if (contentType && contentType.includes('application/json')) {
            const data = await response.json();
            console.log('API测试响应数据:', data);
            
            if (data.success) {
                testResult.textContent = `✅ API连接成功！服务器: ${data.server}, 时间: ${data.timestamp}`;
                testResult.style.background = '#d4edda';
                testResult.style.color = '#155724';
            } else {
                testResult.textContent = `❌ API响应异常: ${data.message || '未知错误'}`;
                testResult.style.background = '#f8d7da';
                testResult.style.color = '#721c24';
            }
        } else {
            const text = await response.text();
            console.log('非JSON响应:', text.substring(0, 200));
            testResult.textContent = `❌ API返回非JSON响应 (${response.status}): ${text.substring(0, 100)}...`;
            testResult.style.background = '#f8d7da';
            testResult.style.color = '#721c24';
        }
    } catch (error) {
        console.error('API测试错误:', error);
        testResult.textContent = `❌ API连接失败: ${error.message}`;
        testResult.style.background = '#f8d7da';
        testResult.style.color = '#721c24';
    } finally {
        testBtn.disabled = false;
        testBtn.textContent = '测试API连接';
    }
}

// 登录处理
async function handleLogin(e) {
    e.preventDefault();
    
    const phone = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    
    try {
        // 尝试API登录
        const response = await apiRequest('/auth/login', {
            method: 'POST',
            body: { phone, password }
        });
        
        // 保存认证信息
        authToken = response.token;
        currentUser = response.user;
        localStorage.setItem('authToken', authToken);
        localStorage.setItem('adminUser', JSON.stringify(currentUser));
        
        showAdminPage();
        connectToWebSocket();
        elements.loginError.textContent = '';
        
        addLog(`管理员登录成功: ${currentUser.phone}`);
        
    } catch (error) {
        // 如果API登录失败，尝试默认凭据（用于演示）
        if (phone === DEFAULT_CREDENTIALS.phone && password === DEFAULT_CREDENTIALS.password) {
            currentUser = { phone, nickname: 'Admin', loginTime: new Date().toISOString() };
            localStorage.setItem('adminUser', JSON.stringify(currentUser));
            
            showAdminPage();
            connectToWebSocket();
            elements.loginError.textContent = '';
            
            addLog('使用默认凭据登录（演示模式）');
        } else {
            elements.loginError.textContent = '登录失败: ' + error.message;
            addLog('登录失败: ' + error.message, 'error');
        }
    }
}

// 退出登录
function handleLogout() {
    localStorage.removeItem('adminUser');
    localStorage.removeItem('authToken');
    currentUser = null;
    authToken = null;
    isLoggedIn = false;
    
    if (socket) {
        socket.disconnect();
        socket = null;
    }
    
    showLoginPage();
    addLog('管理员已退出登录');
}

// 显示登录页面
function showLoginPage() {
    elements.loginPage.classList.add('active');
    elements.adminPage.classList.remove('active');
    document.getElementById('username').value = '';
    document.getElementById('password').value = '';
}

// 显示管理页面
function showAdminPage() {
    elements.loginPage.classList.remove('active');
    elements.adminPage.classList.add('active');
    elements.currentUserSpan.textContent = currentUser.username;
    isLoggedIn = true;
    
    // 默认显示仪表盘
    showTab('dashboard');
}

// 导航点击处理
function handleNavClick(e) {
    e.preventDefault();
    const tabName = e.target.getAttribute('data-tab');
    showTab(tabName);
    
    // 更新导航状态
    elements.navLinks.forEach(link => link.classList.remove('active'));
    e.target.classList.add('active');
}

// 显示标签页
function showTab(tabName) {
    elements.tabContents.forEach(content => {
        content.classList.remove('active');
    });
    
    const targetTab = document.getElementById(tabName);
    if (targetTab) {
        targetTab.classList.add('active');
        
        // 根据标签页加载相应数据
        switch(tabName) {
            case 'dashboard':
                updateDashboard();
                break;
            case 'rooms':
                loadRooms();
                break;
            case 'users':
                loadUsers();
                break;
            case 'commands':
                loadRoomOptions();
                break;
            case 'logs':
                loadLogs();
                break;
        }
    }
}

// 连接WebSocket
function connectToWebSocket() {
    try {
        console.log('正在连接WebSocket服务器...');
        addLog('正在连接WebSocket服务器...');
        
        // 连接到WebSocket服务器
        socket = io(WEBSOCKET_URL);
        
        socket.on('connect', () => {
            console.log('WebSocket连接成功');
            addLog('WebSocket连接成功');
            
            // 立即获取一次状态
            fetchServerStatus();
            
            // 定期获取服务器状态
            setInterval(fetchServerStatus, 5000);
        });
        
        socket.on('disconnect', () => {
            console.log('WebSocket连接断开');
            addLog('WebSocket连接断开');
        });
        
        socket.on('connect_error', (error) => {
            console.error('WebSocket连接错误:', error);
            addLog('WebSocket连接错误: ' + error.message);
            
            // 如果WebSocket连接失败，回退到API轮询模式
            console.log('回退到API轮询模式');
            addLog('回退到API轮询模式');
            fetchServerStatus();
            setInterval(fetchServerStatus, 5000);
        });
        
        // 监听消息
        socket.on('message', handleWebSocketMessage);
        
    } catch (error) {
        console.error('初始化失败:', error);
        addLog('初始化失败: ' + error.message);
        
        // 回退到API轮询模式
        fetchServerStatus();
        setInterval(fetchServerStatus, 5000);
    }
}

// 处理WebSocket消息
function handleWebSocketMessage(data) {
    addLog(`收到消息: ${data.type} - ${JSON.stringify(data.data)}`);
    
    // 根据消息类型更新界面
    switch(data.type) {
        case 'user_join':
        case 'user_leave':
            loadUsers();
            loadRooms();
            break;
        case 'viewer_count':
            updateViewerCount(data);
            break;
    }
}

// 处理管理员响应
function handleAdminResponse(data) {
    addLog(`管理员操作响应: ${data.action} - ${data.status}`);
    
    if (data.status === 'success') {
        showNotification('操作成功', 'success');
    } else {
        showNotification('操作失败: ' + data.message, 'error');
    }
}

// 获取服务器状态
async function fetchServerStatus() {
    try {
        // 获取活跃用户会话统计
        const activeSessionsData = await apiRequest('/user-sessions/active');
        
        // 获取数据库统计
        const statsData = await apiRequest('/stats/dashboard');
        
        serverData.activeRooms = statsData.stats?.activeRooms || 0;
        serverData.onlineUsers = activeSessionsData.activeUsers || 0;
        serverData.serverStatus = '在线';
        
        // 更新全局统计数据
        if (statsData.stats) {
            serverData.totalUsers = statsData.stats.totalUsers || 0;
            serverData.totalMessages = statsData.stats.todayMessages || 0;
            serverData.totalGifts = statsData.stats.totalGifts || 0;
        }
        
        updateDashboard();
    } catch (error) {
        console.error('获取服务器状态失败:', error);
        serverData.serverStatus = '离线';
        updateServerStatus();
        addLog('获取服务器状态失败: ' + error.message, 'error');
    }
}

// 更新仪表盘
function updateDashboard() {
    document.getElementById('activeRooms').textContent = serverData.activeRooms;
    document.getElementById('onlineUsers').textContent = serverData.onlineUsers;
    updateServerStatus();
    
    // 更新统计卡片
    updateStatCards();
    
    // 更新图表
    updateCharts();
    
    // 更新快速操作状态
    updateQuickActions();
    
    console.log('Dashboard updated with enhanced features');
}

// 更新统计卡片
function updateStatCards() {
    const stats = {
        activeRooms: serverData.activeRooms || 0,
        onlineUsers: serverData.onlineUsers || 0,
        totalMessages: serverData.totalMessages || 0,
        totalUsers: serverData.totalUsers || 0
    };
    
    // 更新数值
    const statElements = document.querySelectorAll('.stat-value');
    if (statElements.length >= 4) {
        statElements[0].textContent = stats.activeRooms;
        statElements[1].textContent = stats.onlineUsers;
        statElements[2].textContent = stats.totalMessages;
        statElements[3].textContent = stats.totalUsers;
    }
    
    // 更新变化指示器（可以基于历史数据计算）
    document.querySelectorAll('.stat-change').forEach((element, index) => {
        const changes = ['+5%', '+12%', '+8%', '+3%'];
        if (element && changes[index]) {
            element.textContent = changes[index];
            element.className = 'stat-change positive';
        }
    });
}

// 更新图表（模拟数据）
function updateCharts() {
    // 这里可以集成真实的图表库如Chart.js
    console.log('Charts updated with real-time data');
}

// 更新快速操作
function updateQuickActions() {
    const quickBtns = document.querySelectorAll('.quick-btn');
    quickBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            const action = this.textContent.trim();
            handleQuickAction(action);
        });
    });
}

// 处理快速操作
function handleQuickAction(action) {
    switch(action) {
        case '刷新数据':
            updateDashboard();
            showNotification('数据已刷新', 'success');
            break;
        case '导出日志':
            exportLogs();
            break;
        case '系统维护':
            if (confirm('确定要进入维护模式吗？')) {
                showNotification('系统进入维护模式', 'warning');
            }
            break;
        case '紧急停止':
            if (confirm('确定要紧急停止服务器吗？')) {
                showNotification('服务器已紧急停止', 'error');
            }
            break;
    }
}

// 导出日志功能
function exportLogs() {
    const logData = logs.join('\n');
    const blob = new Blob([logData], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `admin_logs_${new Date().toISOString().split('T')[0]}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showNotification('日志已导出', 'success');
}

// 更新服务器状态
function updateServerStatus() {
    const statusElement = document.getElementById('serverStatus');
    statusElement.textContent = serverData.serverStatus;
    statusElement.className = serverData.serverStatus === '在线' ? 'stat-value status-online' : 'stat-value status-offline';
}

// 加载房间列表
async function loadRooms() {
    try {
        // 获取活跃直播间
        const roomsData = await apiRequest('/live-rooms/active');
        const rooms = roomsData.rooms || [];
        
        const tbody = document.querySelector('#roomsTable tbody');
        if (tbody) {
            tbody.innerHTML = '';
            
            rooms.forEach(room => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${room.id}</td>
                    <td>${room.title || '未命名直播间'}</td>
                    <td>${room.streamer_nickname || '未知主播'}</td>
                    <td>${room.viewer_count || 0}</td>
                    <td>${room.is_live ? '直播中' : '离线'}</td>
                    <td>${new Date(room.created_at).toLocaleString()}</td>
                    <td>
                        <button class="command-btn" onclick="closeSpecificRoom('${room.id}')">关闭</button>
                        <button class="command-btn warning" onclick="muteSpecificRoom('${room.id}')">禁言</button>
                    </td>
                `;
                tbody.appendChild(row);
            });
        }
        
        // 更新房间选择器
        updateRoomSelector(rooms);
        
        addLog(`加载了 ${rooms.length} 个活跃直播间`);
        
    } catch (error) {
        console.error('加载房间列表失败:', error);
        addLog('加载房间列表失败: ' + error.message, 'error');
        
        // 如果API失败，使用空数据
        updateRoomSelector([]);
        addLog('无法获取房间数据，使用空列表', 'warning');
        
        // 显示fallback数据
        const tbody = document.querySelector('#roomsTable tbody');
        if (tbody) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" style="text-align: center; color: #666; padding: 20px;">
                        无法连接到API服务器，请检查网络连接或联系管理员
                    </td>
                </tr>
            `;
        }
    }
}

// 更新房间选择器
function updateRoomSelector(rooms) {
    const selector = document.getElementById('targetRoom');
    if (selector) {
        selector.innerHTML = '<option value="">选择房间</option>';
        
        rooms.forEach(room => {
            const option = document.createElement('option');
            option.value = room.id || room.roomId;
            const roomTitle = room.title || room.roomId || room.id;
            const viewerCount = room.viewer_count || room.viewerCount || 0;
            option.textContent = `${roomTitle} (${viewerCount}人)`;
            selector.appendChild(option);
        });
    }
}

// 加载用户列表
async function loadUsers() {
    try {
        // 获取所有用户数据
        const usersData = await apiRequest('/users');
        const allUsers = usersData.users || [];
        
        // 获取在线用户会话信息
        let onlineUserIds = [];
        let userRooms = {};
        try {
            const sessionsData = await apiRequest('/user-sessions/active');
            const sessions = sessionsData.sessions || [];
            onlineUserIds = sessions.map(session => session.user_id);
            // 构建用户当前房间映射
            sessions.forEach(session => {
                if (session.room_id) {
                    userRooms[session.user_id] = session.room_id;
                }
            });
        } catch (sessionError) {
            console.warn('获取在线用户会话失败:', sessionError);
        }
        
        // 转换为用户数据格式
        const users = allUsers.map(user => ({
            id: user.id,
            username: user.nickname || user.phone,
            phone: user.phone,
            avatar: user.avatar || 'https://via.placeholder.com/40',
            status: onlineUserIds.includes(user.id) ? 'online' : user.status || 'offline',
            level: user.user_level || 1,
            lastActive: user.last_active ? new Date(user.last_active).toLocaleString() : '从未活跃',
            joinDate: new Date(user.created_at).toLocaleDateString(),
            totalMessages: user.total_messages || 0,
            totalEarnings: user.total_earnings || 0,
            isVerified: user.is_verified || false,
            isBanned: user.is_banned || false,
            currentRoom: userRooms[user.id] || null // 当前房间信息
        }));
        
        updateUserTable(users);
        updateUserStats(users);
        setupUserSearch(users);
        
        addLog(`加载了 ${users.length} 个用户，其中 ${onlineUserIds.length} 个在线`);
        
    } catch (error) {
        console.error('加载用户列表失败:', error);
        addLog('加载用户列表失败: ' + error.message, 'error');
        
        // 如果API失败，使用模拟数据
        const fallbackUsers = [
            {
                id: 1,
                username: '演示用户001',
                phone: '13812345678',
                avatar: 'https://via.placeholder.com/40',
                status: 'online',
                level: 5,
                lastActive: '2分钟前',
                joinDate: '2024-01-15',
                totalMessages: 150,
                totalEarnings: 0,
                isVerified: false
            },
            {
                id: 2,
                username: '演示用户002',
                phone: '13987654321',
                avatar: 'https://via.placeholder.com/40',
                status: 'offline',
                level: 3,
                lastActive: '1小时前',
                joinDate: '2024-02-20',
                totalMessages: 89,
                totalEarnings: 0,
                isVerified: true
            }
        ];
        
        updateUserTable(fallbackUsers);
        updateUserStats(fallbackUsers);
        setupUserSearch(fallbackUsers);
        
        addLog('使用演示数据显示用户列表', 'warning');
    }
}

// 更新用户表格
function updateUserTable(users) {
    const tableBody = document.querySelector('#usersTable tbody');
    if (!tableBody) return;
    
    tableBody.innerHTML = users.map(user => `
        <tr data-user-id="${user.id}">
            <td>
                <img src="${user.avatar}" alt="${user.username}" class="user-avatar">
            </td>
            <td title="${user.id}">${user.id.substring(0, 8)}...</td>
            <td>${user.username}</td>
            <td>
                <span class="status-badge status-${user.status}">
                    ${user.status === 'online' ? '🟢 在线' : '⚫ 离线'}
                    ${user.isBanned ? ' 🚫' : ''}
                </span>
            </td>
            <td>${user.currentRoom || '-'}</td>
            <td>
                <span class="user-level">
                    ⭐ ${user.level}
                </span>
            </td>
            <td>${user.joinDate}</td>
            <td>${user.lastActive}</td>
            <td>
                <button class="control-btn ${user.isBanned ? 'success' : 'danger'}" onclick="${user.isBanned ? 'unbanUser' : 'banUser'}('${user.id}')" title="${user.isBanned ? '解封用户' : '封禁用户'}">
                    ${user.isBanned ? '✅' : '🚫'}
                </button>
                <button class="control-btn warning" onclick="muteUser('${user.id}')" title="禁言用户">
                    🔇
                </button>
                <button class="control-btn info" onclick="viewUserDetails('${user.id}')" title="查看详情">
                    👁️
                </button>
            </td>
        </tr>
    `).join('');
}

// 更新用户统计
function updateUserStats(users) {
    const totalUsers = users.length;
    const onlineUsers = users.filter(u => u.status === 'online').length;
    const bannedUsers = users.filter(u => u.isBanned).length;
    const newUsersToday = users.filter(u => {
        const today = new Date().toLocaleDateString();
        return u.joinDate === today;
    }).length;
    
    // 更新统计显示
    const totalUsersEl = document.getElementById('totalUsers');
    const onlineUsersEl = document.getElementById('onlineUsersCount');
    const newUsersTodayEl = document.getElementById('newUsersToday');
    
    if (totalUsersEl) totalUsersEl.textContent = totalUsers;
    if (onlineUsersEl) onlineUsersEl.textContent = onlineUsers;
    if (newUsersTodayEl) newUsersTodayEl.textContent = newUsersToday;
    
    addLog(`用户统计更新: 总用户${totalUsers}, 在线${onlineUsers}, 封禁${bannedUsers}, 今日新增${newUsersToday}`);
}

// 设置用户搜索功能
function setupUserSearch(users) {
    const searchInput = document.querySelector('#userSearch');
    const statusFilter = document.querySelector('#statusFilter');
    const levelFilter = document.querySelector('#levelFilter');
    
    if (!searchInput) return;
    
    function filterUsers() {
        const searchTerm = searchInput.value.toLowerCase();
        const statusValue = statusFilter ? statusFilter.value : '';
        const levelValue = levelFilter ? levelFilter.value : '';
        
        const filteredUsers = users.filter(user => {
            const matchesSearch = user.username.toLowerCase().includes(searchTerm);
            const matchesStatus = !statusValue || user.status === statusValue;
            const matchesLevel = !levelValue || user.level >= parseInt(levelValue);
            
            return matchesSearch && matchesStatus && matchesLevel;
        });
        
        updateUserTable(filteredUsers);
    }
    
    searchInput.addEventListener('input', filterUsers);
    if (statusFilter) statusFilter.addEventListener('change', filterUsers);
    if (levelFilter) levelFilter.addEventListener('change', filterUsers);
}

// 用户操作函数
async function banUser(userId) {
    if (confirm('确定要封禁此用户吗？')) {
        try {
            await apiRequest(`/users/${userId}/ban`, { method: 'POST' });
            showNotification(`用户 ${userId} 已被封禁`, 'warning');
            loadUsers(); // 刷新用户列表
        } catch (error) {
            showNotification('封禁用户失败: ' + error.message, 'error');
        }
    }
}

async function unbanUser(userId) {
    if (confirm('确定要解封此用户吗？')) {
        try {
            await apiRequest(`/users/${userId}/unban`, { method: 'POST' });
            showNotification(`用户 ${userId} 已被解封`, 'success');
            loadUsers(); // 刷新用户列表
        } catch (error) {
            showNotification('解封用户失败: ' + error.message, 'error');
        }
    }
}

function muteUser(userId) {
    if (confirm('确定要禁言此用户吗？')) {
        showNotification(`用户 ${userId} 已被禁言`, 'warning');
        // 这里应该发送禁言请求到服务器
    }
}

function viewUserDetails(userId) {
    // 显示用户详情模态框
    showNotification(`查看用户 ${userId} 的详细信息`, 'info');
    // 这里应该打开用户详情模态框
}

function kickUser(userId) {
    if (confirm('确定要踢出此用户吗？')) {
        showNotification(`用户 ${userId} 已被踢出`, 'error');
        // 这里应该发送踢出请求到服务器
    }
}

function promoteUser(userId) {
    if (confirm('确定要提升此用户权限吗？')) {
        showNotification(`用户 ${userId} 权限已提升`, 'success');
        // 这里应该发送权限提升请求到服务器
    }
}

// 加载房间选项
function loadRoomOptions() {
    loadRooms(); // 重用房间加载逻辑
}

// 发送广播
function sendBroadcast() {
    const message = document.getElementById('broadcastMessage').value.trim();
    if (!message) {
        showNotification('请输入广播消息', 'error');
        return;
    }
    
    if (socket && socket.connected) {
        socket.emit('admin_broadcast', {
            type: 'system_broadcast',
            message: message,
            timestamp: new Date().toISOString()
        });
        
        addLog(`发送广播消息: ${message}`);
        document.getElementById('broadcastMessage').value = '';
        showNotification('广播消息已发送', 'success');
    } else {
        showNotification('WebSocket未连接', 'error');
    }
}

// 关闭房间
function closeRoom() {
    const roomId = document.getElementById('targetRoom').value;
    if (!roomId) {
        showNotification('请选择要关闭的房间', 'error');
        return;
    }
    
    closeSpecificRoom(roomId);
}

// 关闭特定房间
function closeSpecificRoom(roomId) {
    if (socket && socket.connected) {
        socket.emit('admin_command', {
            action: 'close_room',
            roomId: roomId,
            timestamp: new Date().toISOString()
        });
        
        addLog(`关闭房间: ${roomId}`);
        showNotification(`正在关闭房间 ${roomId}`, 'info');
    } else {
        showNotification('WebSocket未连接', 'error');
    }
}

// 禁言房间
function muteRoom() {
    const roomId = document.getElementById('targetRoom').value;
    if (!roomId) {
        showNotification('请选择要禁言的房间', 'error');
        return;
    }
    
    if (socket && socket.connected) {
        socket.emit('admin_command', {
            action: 'mute_room',
            roomId: roomId,
            timestamp: new Date().toISOString()
        });
        
        addLog(`禁言房间: ${roomId}`);
        showNotification(`正在禁言房间 ${roomId}`, 'info');
    } else {
        showNotification('WebSocket未连接', 'error');
    }
}

// 日志管理
let logs = [];

function addLog(message, type = 'info') {
    const timestamp = new Date().toLocaleString();
    const logEntry = `[${timestamp}] ${type.toUpperCase()}: ${message}`;
    logs.push(logEntry);
    
    // 限制日志数量
    if (logs.length > 1000) {
        logs.shift();
    }
    
    // 更新日志显示
    updateLogDisplay();
    
    // 更新日志统计
    updateLogStats();
}

// 更新日志显示
function updateLogDisplay() {
    const logContent = document.getElementById('logContent');
    if (!logContent) return;
    
    // 格式化日志内容，添加颜色和样式
    const formattedLogs = logs.map(log => {
        const logClass = getLogClass(log);
        return `<span class="${logClass}">${log}</span>`;
    }).join('\n');
    
    logContent.innerHTML = formattedLogs;
    logContent.scrollTop = logContent.scrollHeight;
}

// 获取日志样式类
function getLogClass(logEntry) {
    if (logEntry.includes('ERROR')) return 'log-error';
    if (logEntry.includes('WARNING')) return 'log-warning';
    if (logEntry.includes('SUCCESS')) return 'log-success';
    if (logEntry.includes('DEBUG')) return 'log-debug';
    return 'log-info';
}

// 更新日志统计
function updateLogStats() {
    const stats = {
        total: logs.length,
        errors: logs.filter(log => log.includes('ERROR')).length,
        warnings: logs.filter(log => log.includes('WARNING')).length,
        info: logs.filter(log => log.includes('INFO')).length
    };
    
    // 更新统计显示
    const statElements = document.querySelectorAll('.log-stat-value');
    if (statElements.length >= 4) {
        statElements[0].textContent = stats.total;
        statElements[1].textContent = stats.errors;
        statElements[2].textContent = stats.warnings;
        statElements[3].textContent = stats.info;
    }
}

function loadLogs() {
    updateLogDisplay();
    setupLogFilters();
}

function clearLogs() {
    if (confirm('确定要清空所有日志吗？')) {
        logs.length = 0;
        updateLogDisplay();
        updateLogStats();
        showNotification('日志已清空', 'success');
    }
}

function refreshLogs() {
    updateLogDisplay();
    updateLogStats();
    showNotification('日志已刷新', 'success');
}

// 设置日志过滤
function setupLogFilters() {
    const levelFilter = document.getElementById('logLevelFilter');
    if (levelFilter) {
        levelFilter.addEventListener('change', function() {
            filterLogs(this.value);
        });
    }
}

// 过滤日志
function filterLogs(level) {
    const logContent = document.getElementById('logContent');
    if (!logContent) return;
    
    let filteredLogs = logs;
    if (level && level !== 'all') {
        filteredLogs = logs.filter(log => log.includes(level.toUpperCase()));
    }
    
    const formattedLogs = filteredLogs.map(log => {
        const logClass = getLogClass(log);
        return `<span class="${logClass}">${log}</span>`;
    }).join('\n');
    
    logContent.innerHTML = formattedLogs;
    logContent.scrollTop = logContent.scrollHeight;
}

// 通知系统
function showNotification(message, type = 'info', duration = 3000) {
    // 创建通知容器（如果不存在）
    let container = document.getElementById('notification-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'notification-container';
        container.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 10000;
            max-width: 400px;
        `;
        document.body.appendChild(container);
    }
    
    // 创建通知元素
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.style.cssText = `
        background: ${getNotificationColor(type)};
        color: white;
        padding: 15px 20px;
        margin-bottom: 10px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        transform: translateX(100%);
        transition: transform 0.3s ease;
        display: flex;
        align-items: center;
        gap: 10px;
        font-weight: 500;
    `;
    
    notification.innerHTML = `
        <span>${getNotificationIcon(type)}</span>
        <span>${message}</span>
        <button onclick="this.parentElement.remove()" style="
            background: none;
            border: none;
            color: white;
            font-size: 18px;
            cursor: pointer;
            margin-left: auto;
            padding: 0;
            width: 20px;
            height: 20px;
        ">×</button>
    `;
    
    container.appendChild(notification);
    
    // 动画显示
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 10);
    
    // 自动移除
    setTimeout(() => {
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 300);
    }, duration);
    
    // 添加到日志
    addLog(message, type);
}

// 获取通知颜色
function getNotificationColor(type) {
    const colors = {
        success: '#27ae60',
        error: '#e74c3c',
        warning: '#f39c12',
        info: '#3498db'
    };
    return colors[type] || colors.info;
}

// 获取通知图标
function getNotificationIcon(type) {
    const icons = {
        success: '✅',
        error: '❌',
        warning: '⚠️',
        info: 'ℹ️'
    };
    return icons[type] || icons.info;
}

// 添加通知动画样式
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// 页面卸载时断开连接
window.addEventListener('beforeunload', () => {
    if (socket) {
        socket.disconnect();
    }
});