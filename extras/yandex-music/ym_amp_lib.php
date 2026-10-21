<?php
// ym_amp_lib.php — имена и страницы для меню усилителя (из radio_lib.php DigiFox, без плеера APlayer)
const RADIO_PAGE = 6;
const NAME_MAX   = 24;

// UTF-8 -> short ASCII for the amp menu font
function amp_name($s) {
    static $tr = null;
    if ($tr === null) {
        $tr = [];
        $cyr = ['А'=>'A','Б'=>'B','В'=>'V','Г'=>'G','Д'=>'D','Е'=>'E','Ё'=>'E','Ж'=>'Zh','З'=>'Z','И'=>'I',
                'Й'=>'Y','К'=>'K','Л'=>'L','М'=>'M','Н'=>'N','О'=>'O','П'=>'P','Р'=>'R','С'=>'S','Т'=>'T',
                'У'=>'U','Ф'=>'F','Х'=>'Kh','Ц'=>'Ts','Ч'=>'Ch','Ш'=>'Sh','Щ'=>'Sch','Ъ'=>'','Ы'=>'Y','Ь'=>'',
                'Э'=>'E','Ю'=>'Yu','Я'=>'Ya','І'=>'I','Ї'=>'Yi','Є'=>'Ye','Ґ'=>'G','Ў'=>'U'];
        foreach ($cyr as $k => $v) {
            $tr[$k] = $v;
            $lk = mb_lc($k);
            $tr[$lk] = strtolower($v);
        }
        $tr += ['—'=>'-','–'=>'-','«'=>'"','»'=>'"','“'=>'"','”'=>'"','’'=>"'",'…'=>'...',
                'ä'=>'a','ö'=>'o','ü'=>'u','Ä'=>'A','Ö'=>'O','Ü'=>'U','ß'=>'ss','é'=>'e','è'=>'e',
                'ê'=>'e','à'=>'a','â'=>'a','ç'=>'c','ô'=>'o','î'=>'i','ñ'=>'n','ă'=>'a','â'=>'a',
                'ș'=>'s','ş'=>'s','ț'=>'t','ţ'=>'t','Ș'=>'S','Ț'=>'T','å'=>'a','Å'=>'A','ø'=>'o','æ'=>'ae'];
    }
    $s = strtr($s, $tr);
    $s = preg_replace('/[^\x20-\x7E]/', '', $s);
    // bitrate/format notes are noise on a small screen: "(128kbps)", "(320 kbps AAC)", "- AAC HD 256k"
    $s = preg_replace('/\s*\((?=[^)]*(kbps|aac|flac|mp3|ogg|\d+k\b))[^)]*\)/i', '', $s);
    $s = preg_replace('/\s*-\s*(aac|mp3|flac|ogg)\b.*$/i', '', $s);
    $s = trim(preg_replace('/\s+/', ' ', $s));
    if ($s === '') $s = '?';
    return strlen($s) > NAME_MAX ? rtrim(substr($s, 0, NAME_MAX - 1)) . '.' : $s;
}

// lowercase of one Cyrillic capital (no mbstring in this PHP)
function mb_lc($ch) {
    static $u = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯІЇЄҐЎ';
    static $l = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюяіїєґў';
    $U = preg_split('//u', $u, -1, PREG_SPLIT_NO_EMPTY);
    $L = preg_split('//u', $l, -1, PREG_SPLIT_NO_EMPTY);
    $i = array_search($ch, $U, true);
    return $i === false ? $ch : $L[$i];
}

// &lines=N: N lines of RADIO_PAGE names each (the amp keeps a window of 12)
function page($kind, $names, $from) {
    $total = count($names);
    $from  = max(0, min($from, $total));
    $lines = max(1, min(4, (int)($_GET['lines'] ?? 1)));
    $out   = [];
    for ($l = 0; $l < $lines; $l++) {
        $f = $from + $l * RADIO_PAGE;
        if ($l > 0 && $f >= $total) break;
        $o = "$kind $total $f";
        foreach (array_slice($names, $f, RADIO_PAGE) as $n) $o .= "\t" . amp_name($n);
        $out[] = $o;
    }
    echo implode("\n", $out);
}

