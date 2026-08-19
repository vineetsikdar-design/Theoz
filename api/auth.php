<?php
// auth.php
require 'api_core.php';

if (!isset($_POST['data'])) { sendResponse('error', 'Invalid Request'); }

$request = decryptPayload($_POST['data']);
if (!$request || !isset($request['action'], $request['key'], $request['hwid'], $request['timestamp'])) {
    sendResponse('error', 'Malformed Payload');
}

verifyTimestamp($request['timestamp']);

$key = trim($request['key']);
$hwid = trim($request['hwid']);

// 1. Check if Key Exists and is Active
$stmt = $pdo->prepare("SELECT * FROM zentrax_keys WHERE license_key = ?");
$stmt->execute([$key]);
$keyData = $stmt->fetch();

if (!$keyData) { sendResponse('error', 'Access Key not found.'); }
if ($keyData['status'] == 0) { sendResponse('error', 'This Key has been banned by Admin.'); }

// 2. Check existing binds for this key
$stmt = $pdo->prepare("SELECT * FROM zentrax_binds WHERE license_key = ?");
$stmt->execute([$key]);
$binds = $stmt->fetchAll();

$isBoundToMe = false;
$expiredDate = null;

foreach ($binds as $b) {
    if ($b['ip_address'] === $hwid) { // NOTE: Using ip_address column to store HWID
        $isBoundToMe = true;
        $expiredDate = $b['expired_date'];
        break;
    }
}

// 3. Bind new HWID if limit not reached
if (!$isBoundToMe) {
    if (count($binds) >= $keyData['max_ips']) {
        sendResponse('error', 'Maximum device limit reached for this key.');
    }
    
    // Calculate Expiry
    $duration = (int)$keyData['duration_val'];
    $unit = strtoupper($keyData['duration_unit']) === 'DAYS' ? 'DAY' : 'HOUR';
    
    $stmt = $pdo->prepare("INSERT INTO zentrax_binds (license_key, ip_address, expired_date) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? $unit))");
    $stmt->execute([$key, $hwid, $duration]);
    
    $stmt = $pdo->prepare("SELECT expired_date FROM zentrax_binds WHERE license_key = ? AND ip_address = ?");
    $stmt->execute([$key, $hwid]);
    $expiredDate = $stmt->fetchColumn();
}

// 4. Check if Expired
if (strtotime($expiredDate) < time()) {
    sendResponse('error', 'Your subscription has expired.');
}

// 5. Update Last Access (Online Status)
$pdo->prepare("UPDATE zentrax_binds SET last_access = NOW() WHERE license_key = ? AND ip_address = ?")->execute([$key, $hwid]);

// Success! Send available modules
sendResponse('success', 'Authentication Successful.', [
    'expiry' => $expiredDate,
    'module' => $keyData['feature_name']
]);
?>
