<?php
// module.php (Clean Version)
require 'api_core.php';

if (!isset($_POST['data'])) { sendResponse('error', 'Invalid'); }
$request = decryptPayload($_POST['data']);

verifyTimestamp($request['timestamp']);
$hwid = $request['hwid'];
$moduleName = $request['module'];
$state = $request['state']; // 'ON' or 'OFF'

// 1. Verify Session & Hardware ID
$stmt = $pdo->prepare("SELECT b.expired_date, k.status FROM zentrax_binds b JOIN zentrax_keys k ON b.license_key = k.license_key WHERE b.ip_address = ?");
$stmt->execute([$hwid]);
$session = $stmt->fetch();

if (!$session || $session['status'] == 0 || strtotime($session['expired_date']) < time()) {
    sendResponse('error', 'Unauthorized or Expired Session.');
}

// 2. Fetch Module Paths from Database
// Admin panel se jo save kiya tha wo data layenge
$stmt = $pdo->prepare("SELECT bundle_id, relative_path, file_name, on_file_path, off_file_path FROM zentrax_features WHERE name = ?");
$stmt->execute([$moduleName]);
$feature = $stmt->fetch();

if (!$feature) { sendResponse('error', 'Module not found in database.'); }

// 3. Select Target File Based on State
$serverFilePath = ($state === 'ON') ? $feature['on_file_path'] : $feature['off_file_path'];

if (!file_exists($serverFilePath)) {
    sendResponse('error', 'Payload file missing on server.');
}

// 4. Read File & Encode
$fileContent = file_get_contents($serverFilePath);
$base64File = base64_encode($fileContent);

// 5. Send Full Execution Data to iOS
sendResponse('success', 'Payload Fetched', [
    'bundle_id'     => $feature['bundle_id'],
    'relative_path' => $feature['relative_path'],
    'file_name'     => $feature['file_name'],
    'file_data'     => $base64File
]);
?>
