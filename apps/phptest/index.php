<?php
// Jednoduchá PHP aplikace pro testování K3s deploymentu
?>
<!DOCTYPE html>
<html lang="cs">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Test App - K3s</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        .info-box {
            background: rgba(255, 255, 255, 0.2);
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
        }
        h1 { color: #fff; text-align: center; }
        .status { color: #4CAF50; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 PHP Test Application</h1>
        <p class="status">✅ K3s deployment úspěšný!</p>
        
        <div class="info-box">
            <h3>Server Info:</h3>
            <p><strong>Hostname:</strong> <?php echo gethostname(); ?></p>
            <p><strong>Server IP:</strong> <?php echo $_SERVER['SERVER_ADDR'] ?? 'N/A'; ?></p>
            <p><strong>Client IP:</strong> <?php echo $_SERVER['REMOTE_ADDR'] ?? 'N/A'; ?></p>
            <p><strong>User Agent:</strong> <?php echo $_SERVER['HTTP_USER_AGENT'] ?? 'N/A'; ?></p>
        </div>

        <div class="info-box">
            <h3>PHP Info:</h3>
            <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
            <p><strong>Current Time:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
            <p><strong>Timezone:</strong> <?php echo date_default_timezone_get(); ?></p>
        </div>

        <div class="info-box">
            <h3>Environment:</h3>
            <p><strong>Pod Name:</strong> <?php echo getenv('HOSTNAME') ?: 'N/A'; ?></p>
            <p><strong>Namespace:</strong> <?php echo getenv('POD_NAMESPACE') ?: 'default'; ?></p>
            <p><strong>Service Account:</strong> <?php echo getenv('POD_SERVICE_ACCOUNT') ?: 'default'; ?></p>
        </div>

        <div class="info-box">
            <h3>Request Headers:</h3>
            <?php
            foreach (getallheaders() as $name => $value) {
                echo "<p><strong>$name:</strong> $value</p>";
            }
            ?>
        </div>

        <div class="info-box">
            <h3>Test Database Connection:</h3>
            <?php
            // Simulace databázového připojení
            $db_host = getenv('DB_HOST') ?: 'localhost';
            $db_status = "Připojení k $db_host - " . (rand(0, 1) ? '✅ OK' : '❌ Failed');
            echo "<p>$db_status</p>";
            ?>
        </div>
    </div>
</body>
</html>
