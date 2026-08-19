<?php
// heartbeat.php
require 'api_core.php';

if (!isset($_POST['data'])) { sendResponse('error', 'Invalid'); }
$request = decryptPayload($_POST['data']);

$hwid = $request['hwid'] ?? '';
verifyTimestamp($request['timestamp']);

$stmt = $pdo->prepare("SELECT k.status, b.expired_date FROM zentrax_binds b JOIN zentrax_keys k ON b.license_key = k.license_key WHERE b.ip_address = ?");
$stmt->execute([$hwid]);
$session = $stmt->fetch();

if (!$session) { sendResponse('error', 'Session destroyed.'); }
if ($session['status'] == 0) { sendResponse('error', 'Key has been banned.'); }
if (strtotime($session['expired_date']) < time()) { sendResponse('error', 'Subscription expired.'); }

// Update online status
$pdo->prepare("UPDATE zentrax_binds SET last_access = NOW() WHERE ip_address = ?")->execute([$hwid]);

sendResponse('success', 'Active');
?>
