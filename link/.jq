def pad_left($len; $chr):
    (tostring | length) as $l
    | "\($chr * ([$len - $l, 0] | max) // "")\(.)"
;

def pad_left($len):
    pad_left($len; "0")
;

def fromhms:
    capture(" (?<h>\\d+) : (?<m>\\d+) : (?<s>\\d+) "; "x") as $t |
    ($t.h | tonumber | . * 3600) + ($t.m | tonumber | . * 60) + ($t.s | tonumber)
;

def pad: if . < 0 then "00" else .|pad_left(2; "0") end;

def tohms:
    . | tonumber as $t |
    ( ( $t / 3600 ) | floor ) as $h |
    ( ( $t - ($h * 3600) ) / 60 | floor ) as $m |
    ( $t - ($h * 3600) - ($m * 60) ) as $s |
    [$h,$m,$s] | map(pad) | join(":")
;
