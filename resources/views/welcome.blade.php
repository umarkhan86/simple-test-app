<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Simple Laravel Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            text-align: center;
            background: white;
            padding: 50px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }
        h1 { color: #667eea; margin: 0 0 20px 0; }
        .info { 
            background: #f5f5f5; 
            padding: 20px; 
            border-radius: 5px; 
            margin: 20px 0;
        }
        .version { color: #666; font-size: 14px; }
        .success { color: #10b981; font-size: 24px; margin: 20px 0; }
        a { 
            display: inline-block;
            margin: 10px;
            padding: 10px 20px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Laravel Deployment Test</h1>
        <div class="success">✅ Deployment Successful!2mddd</div>
        <div class="info">
            <p><strong>Laravel Version:</strong> {{ app()->version() }}</p>
            <p><strong>Environment:</strong> {{ app()->environment() }}</p>
            <p><strong>Server Time:</strong> {{ now()->toDateTimeString() }}</p>
            <p><strong>Deployment #:</strong> {{ config('app.deployment_id', '1') }}</p>
        </div>
        <div>
            <a href="/test">JSON Test</a>
            <a href="/health">Health Check</a>
        </div>
    </div>
</body>
</html>
