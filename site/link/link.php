<?php
// Waaiya's "try a link" on o2switch: the first server the landing page asks (site/link/README.md).
// Same answers as server.py: 200 audio/mp4 + X-Waaiya-Meta, or JSON {"error"} with 400 (stop) / 503 (next server).
// Runs ~/waaiya-link/waaiya_link.py. yt-dlp updates itself here at most once a day, after an answer has been sent
// (no cron: this account's crontab is managed elsewhere). Shared hosting
// cannot sandbox it, so: one fetch at a time, hard time limit, per-address and daily caps, link sent by POST
// (never in a log), temporary file always deleted.
define('HOME', dirname(__DIR__, 2));            // link.php sits in ~/<docroot>/api/
const HOME_DIR = HOME . '/waaiya-link';
const STOP = ['invalid_url', 'unsupported_site', 'playlist', 'live', 'no_format'];
const PER_IP = 6, PER_IP_WINDOW = 600, PER_DAY = 400;

header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');

function fail($code) {
    http_response_code(in_array($code, STOP, true) ? 400 : 503);
    header('Content-Type: application/json');
    echo json_encode(['error' => $code]);
    exit;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') { http_response_code(405); exit; }
$url = $_POST['url'] ?? '';
if (!is_string($url) || $url === '' || strlen($url) > 2000) fail('invalid_url');

// caps: addresses kept only as a salted daily hash
$state = HOME_DIR . '/state';
@mkdir($state, 0700, true);
$fh = fopen("$state/caps.json", 'c+');
if (!$fh || !flock($fh, LOCK_EX)) fail('failed');
$caps = json_decode(stream_get_contents($fh) ?: '{}', true) ?: [];
$today = gmdate('Y-m-d'); $now = time();
if (($caps['day'] ?? '') !== $today) $caps = ['day' => $today, 'n' => 0, 'ip' => [], 'salt' => bin2hex(random_bytes(16))];
$ip = hash('sha256', $caps['salt'] . ($_SERVER['REMOTE_ADDR'] ?? ''));
$recent = array_values(array_filter($caps['ip'][$ip] ?? [], fn($t) => $t > $now - PER_IP_WINDOW));
$ok = $caps['n'] < PER_DAY && count($recent) < PER_IP;
if ($ok) { $recent[] = $now; $caps['ip'][$ip] = $recent; $caps['n']++; }
foreach ($caps['ip'] as $k => $ts) if (max($ts) < $now - PER_IP_WINDOW) unset($caps['ip'][$k]);
ftruncate($fh, 0); rewind($fh); fwrite($fh, json_encode($caps)); flock($fh, LOCK_UN); fclose($fh);
if (!$ok) fail('quota');

// one at a time
$busy = fopen("$state/busy.lock", 'c');
if (!$busy || !flock($busy, LOCK_EX | LOCK_NB)) fail('busy');

// Keep yt-dlp current: at most once a day, after the visitor has the answer (also after a failure, which may be
// the very reason to update), still holding the busy lock so no fetch runs meanwhile.
register_shutdown_function(function () use ($state) {
    $stamp = "$state/updated";
    if (is_file($stamp) && filemtime($stamp) > time() - 86400) return;
    if (function_exists('fastcgi_finish_request')) fastcgi_finish_request();
    touch($stamp);
    $u = proc_open(['/usr/bin/timeout', '300', HOME_DIR . '/venv/bin/pip', 'install', '-q', '-U', 'yt-dlp', 'yt-dlp-ejs'],
                   [0 => ['file', '/dev/null', 'r'], 1 => ['file', "$state/update.log", 'w'], 2 => ['file', "$state/update.log", 'a']],
                   $pipes, HOME_DIR, ['PATH' => '/usr/bin:/bin', 'HOME' => HOME_DIR]);
    if (is_resource($u)) proc_close($u);
});

$out = "$state/" . bin2hex(random_bytes(8)) . '.m4a';
register_shutdown_function(function () use ($out) { if (is_file($out)) unlink($out); });
$cmd = ['/usr/bin/timeout', '-k', '5', '55', HOME_DIR . '/venv/bin/python', HOME_DIR . '/waaiya_link.py', $url, $out];
$env = ['PATH' => '/usr/bin:/bin', 'HOME' => HOME_DIR, 'WAAIYA_QJS' => HOME_DIR . '/qjs',
        'WAAIYA_FFMPEG' => HOME . '/bin/ffmpeg', 'TMPDIR' => $state];
$p = proc_open($cmd, [0 => ['file', '/dev/null', 'r'], 1 => ['pipe', 'w'], 2 => ['file', '/dev/null', 'w']], $pipes, HOME_DIR, $env);
if (!is_resource($p)) fail('failed');
$stdout = stream_get_contents($pipes[1]); fclose($pipes[1]);
$rc = proc_close($p);
$lines = array_filter(explode("\n", trim($stdout)));
$res = $lines ? json_decode(end($lines), true) : null;
if ($rc === 124 || $rc === 137) fail('timeout');
if (!is_array($res) || empty($res['ok']) || !is_file($out)) fail(is_array($res) ? ($res['error'] ?? 'failed') : 'failed');
unset($res['ok']);
header('Content-Type: audio/mp4');
header('Content-Length: ' . filesize($out));
header('X-Waaiya-Meta: ' . json_encode($res));  // json_encode escapes non-ASCII: a safe header
readfile($out);
unlink($out);

