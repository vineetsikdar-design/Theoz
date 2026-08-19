<?php
// api_core.php
error_reporting(0); // Production mode: Hide PHP errors from hackers

// 🔐 SAME KEYS AS ZentraxNetworkManager.m
define('SECRET_KEY', 'ZENTRAX_32_CHAR_SECRET_KEY_12345'); 
define('SECRET_IV', 'ZENTRAX_16_IV_89');

// 🗄️ DATABASE CONNECTION
$host = 'localhost';
$db   = 'zentrax_db'; // Tumhara database name
$user = 'zentrax_user'; // Tumhara database user
$pass = 'your_db_password';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    sendResponse('error', 'Database connection failed.');
}

// 🛡️ DECRYPTION FUNCTION
function decryptPayload($encryptedText) {
    $cipherData = base64_decode($encryptedText);
    $decrypted = openssl_decrypt($cipherData, 'AES-256-CBC', SECRET_KEY, OPENSSL_RAW_DATA, SECRET_IV);
    return json_decode($decrypted, true);
}

// 🛡️ ENCRYPTION FUNCTION
function encryptPayload($payloadArray) {
    $jsonString = json_encode($payloadArray);
    $encrypted = openssl_encrypt($jsonString, 'AES-256-CBC', SECRET_KEY, OPENSSL_RAW_DATA, SECRET_IV);
    return base64_encode($encrypted);
}

// 📤 SEND ENCRYPTED RESPONSE
function sendResponse($status, $message, $extraData = []) {
    $response = ['status' => $status, 'message' => $message];
    if (!empty($extraData)) {
        $response = array_merge($response, $extraData);
    }
    echo encryptPayload($response);
    exit;
}

// ⏳ REPLAY ATTACK PREVENTION
function verifyTimestamp($clientTime) {
    $serverTime = time();
    // Agar request 60 seconds se zyada purani hai, toh block kar do
    if (abs($serverTime - (int)$clientTime) > 60) {
        sendResponse('error', 'Request Timeout or Replay Attack Detected.');
    }
}
?>
