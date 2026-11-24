<?php
// The Google Play test sign-up (the /test/ page, TEST in site/build.py), served as /api/test-signup.php on o2switch (the
// preview's copy: /preview/api/test-signup.php). Both write the same list.
//   POST email, name (optional), lang (ar|en|fr), mode (join|remove), website (a trap: people never see it).
//   Answers {"ok":true} or {"error":"invalid_email"|"rate"|"failed"} as JSON when asked for JSON; a plain form post
//   (no JavaScript) is sent back to the page, to #done, #removed or #oops.
// Kept outside the docroot, files mode 600: ~/waaiya-testers/signups.csv (time_utc,email,name,lang; one line per
// address), ~/waaiya-testers/state/ (caps.json: per-address counts as a salted hash that changes every day;
// notify.log: the time and whether Telegram took each message). The owner hears of each new or removed address
// through the Telegram bot: only sendMessage, as the bot's own server long-polls for updates. Its token and the
// owner's chat id are in ~/.config/waaiya-test/tg.env (TG_TOKEN=..., TG_CHAT=...), never in the repository.
const PER_IP = 8, PER_IP_WINDOW = 3600, PER_DAY = 300;
const LANGS = ['ar' => '../test/', 'en' => '../en/test/', 'fr' => '../fr/test/'];

umask(077);
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
header('X-Robots-Tag: noindex');

$home = function_exists('posix_getpwuid') ? (posix_getpwuid(posix_geteuid())['dir'] ?? '') : '';
if ($home === '' || !is_dir($home)) $home = preg_match('#^/home\d*/[^/]+#', __DIR__, $m) ? $m[0] : '';
$dir = "$home/waaiya-testers";
$state = "$dir/state";
$lang = array_key_exists($_POST['lang'] ?? '', LANGS) ? $_POST['lang'] : 'ar';
$wantsJson = str_contains($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json');

function answer(string $code): never {
    global $wantsJson, $lang;
    $ok = $code === 'ok' || $code === 'removed';
    if ($wantsJson) {
        // not 429: o2switch's front end holds a POST answered 429 until the client gives up
        http_response_code($ok ? 200 : ['invalid_email' => 400, 'rate' => 503][$code] ?? 500);
        header('Content-Type: application/json');
        echo json_encode($ok ? ['ok' => true] : ['error' => $code]);
    } else {
        header('Location: ' . LANGS[$lang] . '#' . ($code === 'ok' ? 'done' : ($ok ? 'removed' : 'oops')), true, 303);
    }
    exit;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') { http_response_code(405); header('Allow: POST'); exit; }
if ($home === '' || (!is_dir($state) && !mkdir($state, 0700, true))) answer('failed');

// the trap: filled in only by robots, which are thanked and forgotten
if (trim((string)($_POST['website'] ?? '')) !== '') answer('ok');

// caps: every post counts, valid or not
$fh = fopen("$state/caps.json", 'c+');
if (!$fh || !flock($fh, LOCK_EX)) answer('failed');
$caps = json_decode(stream_get_contents($fh) ?: '{}', true) ?: [];
$today = gmdate('Y-m-d'); $now = time();
if (($caps['day'] ?? '') !== $today) $caps = ['day' => $today, 'n' => 0, 'ip' => [], 'salt' => bin2hex(random_bytes(16))];
$ip = hash('sha256', $caps['salt'] . ($_SERVER['REMOTE_ADDR'] ?? ''));
$recent = array_values(array_filter($caps['ip'][$ip] ?? [], fn($t) => $t > $now - PER_IP_WINDOW));
$allowed = $caps['n'] < PER_DAY && count($recent) < PER_IP;
if ($allowed) { $recent[] = $now; $caps['ip'][$ip] = $recent; $caps['n']++; }
foreach ($caps['ip'] as $k => $ts) if (!$ts || max($ts) < $now - PER_IP_WINDOW) unset($caps['ip'][$k]);
ftruncate($fh, 0); rewind($fh); fwrite($fh, json_encode($caps)); flock($fh, LOCK_UN); fclose($fh);
if (!$allowed) answer('rate');

$email = strtolower(trim((string)($_POST['email'] ?? '')));
if (strlen($email) > 254 || !filter_var($email, FILTER_VALIDATE_EMAIL)) answer('invalid_email');
$name = trim(preg_replace('/[\p{C}]+/u', ' ', (string)($_POST['name'] ?? '')) ?? '');
$name = mb_substr($name, 0, 80);
if ($name !== '' && strpbrk($name[0], '=+-@') !== false) $name = "'" . $name;   // not a formula in a spreadsheet
$remove = ($_POST['mode'] ?? 'join') === 'remove';

// the list, under a lock: one line per address
$csv = "$dir/signups.csv";
$fh = fopen($csv, 'c+');
if (!$fh || !flock($fh, LOCK_EX)) answer('failed');
chmod($csv, 0600);
$rows = [];
while (($r = fgetcsv($fh, 0, ',', '"', '')) !== false) if ($r !== [null]) $rows[] = $r;
$header = ['time_utc', 'email', 'name', 'lang'];
if (!$rows) $rows[] = $header;
$known = false;
foreach (array_slice($rows, 1) as $r) if (($r[1] ?? '') === $email) { $known = true; break; }
$changed = false;
if ($remove && $known) {
    $rows = array_values(array_filter($rows, fn($r) => ($r[1] ?? '') !== $email));
    ftruncate($fh, 0); rewind($fh);
    foreach ($rows as $r) fputcsv($fh, $r, ',', '"', '');
    $changed = true;
} elseif (!$remove && !$known) {
    if (count($rows) === 1) { ftruncate($fh, 0); rewind($fh); fputcsv($fh, $header, ',', '"', ''); }
    fseek($fh, 0, SEEK_END);
    $rows[] = $line = [gmdate('Y-m-d H:i:s'), $email, $name, $lang];
    fputcsv($fh, $line, ',', '"', '');
    $changed = true;
}
fflush($fh); flock($fh, LOCK_UN); fclose($fh);

// tell the owner (only when the list changed: a second sign-up of the same address says nothing)
if ($changed) {
    $e = fn($s) => htmlspecialchars($s, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    $where = str_contains(__DIR__, '/preview/') ? ' · from the preview' : '';
    $n = count($rows) - 1;
    $text = $remove
        ? "Waaiya Play test: remove this tester (asked on the site)\n<code>{$e($email)}</code>\n\n"
          . "Remove it from the testers list in Play Console. {$n} on the list now$where."
        : "Waaiya Play test: new tester, n° {$n}\n<code>{$e($email)}</code>\n\n"
          . ($name !== '' ? "Name: {$e($name)} · " : '') . "Page: $lang$where\n"
          . "Add it to the testers list in Play Console (Test and release › Testing).";
    notify($text);
}
answer($remove ? 'removed' : 'ok');

function notify(string $text): void {
    global $home, $state;
    $conf = [];
    foreach (@file("$home/.config/waaiya-test/tg.env", FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $l)
        if (preg_match('/^\s*(\w+)\s*=\s*(.*?)\s*$/', $l, $m)) $conf[$m[1]] = $m[2];
    $result = 'error no config';
    if (($conf['TG_TOKEN'] ?? '') !== '' && ($conf['TG_CHAT'] ?? '') !== '') {
        $ch = curl_init('https://api.telegram.org/bot' . $conf['TG_TOKEN'] . '/sendMessage');
        curl_setopt_array($ch, [
            CURLOPT_POST => true, CURLOPT_RETURNTRANSFER => true, CURLOPT_CONNECTTIMEOUT => 5, CURLOPT_TIMEOUT => 10,
            CURLOPT_POSTFIELDS => http_build_query(['chat_id' => $conf['TG_CHAT'], 'text' => $text,
                                                   'parse_mode' => 'HTML', 'disable_web_page_preview' => 'true']),
        ]);
        $body = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_errno($ch);
        curl_close($ch);
        $res = is_string($body) ? json_decode($body, true) : null;
        // only Telegram's verdict is logged: never the address, the URL (it holds the token) or the answer's body
        $result = is_array($res) && !empty($res['ok']) ? 'ok' : "error http $code curl $err";
    }
    file_put_contents("$state/notify.log", gmdate('Y-m-d H:i:s') . " $result\n", FILE_APPEND | LOCK_EX);
}
