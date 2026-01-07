const http = require('http');
const os = require('os');

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
    const timestamp = new Date().toISOString();
    const hostname = os.hostname();
    
    // Log request
    console.log(`[${timestamp}] ${req.method} ${req.url} from ${req.socket.remoteAddress}`);
    
    if (req.url === '/' || req.url === '/index.html') {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(`
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DevOps CI/CD Demo - CSC11004</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0f3443 0%, #34e89e 50%, #43cea2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 40px;
            max-width: 800px;
            width: 100%;
        }
        h1 {
            color: #34e89e;
            text-align: center;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .subtitle {
            color: #666;
            text-align: center;
            margin-bottom: 30px;
            font-size: 1.2em;
        }
        .info-card {
            background: #f0fff4;
            border-radius: 10px;
            padding: 20px;
            margin: 15px 0;
            border-left: 4px solid #34e89e;
        }
        .info-card h3 {
            color: #333;
            margin-bottom: 10px;
        }
        .info-card p {
            color: #666;
            line-height: 1.6;
        }
        .pipeline {
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
            margin: 30px 0;
            gap: 10px;
        }
        .pipeline-step {
            background: linear-gradient(135deg, #34e89e 0%, #0f3443 100%);
            color: white;
            padding: 15px 25px;
            border-radius: 25px;
            font-weight: bold;
            position: relative;
        }
        .pipeline-step:not(:last-child)::after {
            content: '→';
            position: absolute;
            right: -20px;
            top: 50%;
            transform: translateY(-50%);
            color: #34e89e;
            font-size: 1.5em;
        }
        .server-info {
            background: #e8f5e9;
            border-radius: 10px;
            padding: 20px;
            margin-top: 20px;
        }
        .server-info h3 {
            color: #2e7d32;
            margin-bottom: 15px;
        }
        .server-info code {
            background: #c8e6c9;
            padding: 5px 10px;
            border-radius: 5px;
            display: block;
            margin: 5px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #999;
            font-size: 0.9em;
        }
        .version {
            background: linear-gradient(135deg, #34e89e 0%, #0f3443 100%);
            color: white;
            padding: 5px 15px;
            border-radius: 15px;
            display: inline-block;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 DevOps CI/CD Demo</h1>
        <p class="subtitle">Đồ án môn Mạng máy tính nâng cao (CSC11004)</p>
        
        <div class="info-card">
            <h3>📋 Mô tả dự án</h3>
            <p>Triển khai CI/CD sử dụng Git, Jenkins và Docker. 
            Quy trình tự động hóa từ khâu code đến triển khai container.</p>
        </div>

        <div class="pipeline">
            <span class="pipeline-step">📝 Code</span>
            <span class="pipeline-step">📤 Git Push</span>
            <span class="pipeline-step">🔧 Jenkins Build</span>
            <span class="pipeline-step">🐳 Docker Push</span>
            <span class="pipeline-step">🚀 Deploy</span>
        </div>

        <div class="info-card">
            <h3>🛠️ Công nghệ sử dụng</h3>
            <p>
                <strong>• Git/GitHub:</strong> Quản lý source code<br>
                <strong>• Jenkins:</strong> CI/CD automation server<br>
                <strong>• Docker:</strong> Container platform<br>
                <strong>• Docker Hub:</strong> Container registry<br>
                <strong>• Node.js:</strong> Runtime environment
            </p>
        </div>

        <div class="server-info">
            <h3>📊 Thông tin Server</h3>
            <code><strong>Hostname:</strong> ${hostname}</code>
            <code><strong>Timestamp:</strong> ${timestamp}</code>
            <code><strong>Node Version:</strong> ${process.version}</code>
            <code><strong>Platform:</strong> ${os.platform()} ${os.arch()}</code>
        </div>

        <div class="footer">
            <p>© 2026 - Đồ án CI/CD Pipeline</p>
            <span class="version">Version 1.0.0</span>
        </div>
    </div>
</body>
</html>
        `);
    } else if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'healthy',
            timestamp: timestamp,
            hostname: hostname,
            uptime: process.uptime()
        }));
    } else if (req.url === '/api/info') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            app: 'DevOps CI/CD Demo',
            course: 'CSC11004 - Mạng máy tính nâng cao',
            version: '1.0.0',
            hostname: hostname,
            timestamp: timestamp,
            nodejs: process.version,
            platform: os.platform(),
            arch: os.arch(),
            memory: {
                total: Math.round(os.totalmem() / 1024 / 1024) + ' MB',
                free: Math.round(os.freemem() / 1024 / 1024) + ' MB'
            }
        }));
    } else {
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('<h1>404 - Page Not Found</h1>');
    }
});

server.listen(PORT, () => {
    console.log(`
    ╔═══════════════════════════════════════════════╗
    ║     DevOps CI/CD Demo Application Started     ║
    ║              CSC11004 Project                 ║
    ╠═══════════════════════════════════════════════╣
    ║  Server running at http://localhost:${PORT}       ║
    ║  Health check: http://localhost:${PORT}/health    ║
    ║  API Info: http://localhost:${PORT}/api/info      ║
    ╚═══════════════════════════════════════════════╝
    `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});
