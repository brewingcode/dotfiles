def pad_left($len; $chr):
    # adapted from https://stackoverflow.com/a/64958532 for numbers specifically
    (tostring | capture("^(?<prefix>\\+|-)?(?<n>\\d+)(?<d>\\..*)?")) as $r |
    "\($r.prefix // "")\($chr * ([$len - ($r.n|length), 0] | max) // "")\($r.n)\($r.d // "")"
;

def fromhms:
    # regex out the optional prefix and the optional decimal numbers. need to
    # remove the decimal numbers because multiplying with them instantly adds
    # floating point imprecision because of Javascript (ie, `.1 * 2 = 0.2`, BUT
    # `.1 * 3 = 0.30000000000000004`)
    capture("^(?<prefix>\\+|-)?(?<n>[\\d:]+)(?<d>\\..*)?") as $r |

    # split on colons, and convert to three numbers while handling missing values
    $r.n | split(":") | [ .[-1, -2, -3] ] | map(. // "0" | tonumber) as [$s, $m, $h] |

    # sum them all up, and stick the decimal numberes back on
    [ $h * 3600, $m * 60, $s ] | add | . + (($r.d // "0") | tonumber) |

    # negate the final number if the original string had a negative sign
    if ($r.prefix == "-") then -. else . end
;

def tohms:
    # convert to string to handle numbers and strings, then regex
    ( tostring | capture("^(?<prefix>-|\\+)?(?<n>\\d+)(?<d>.*)") ) as $r |

    # standard breakdown of number of seconds into hours, minutes, seconds
    ( $r.n | tonumber ) as $t |
    ( ( $t / 3600 ) | floor ) as $h |
    ( ( $t - ($h * 3600) ) / 60 | floor ) as $m |
    ( $t - ($h * 3600) - ($m * 60) ) as $s |

    # print out final string while padding the numbers with zeroes and
    # re-adding the decimal numbers
    "\($r.prefix // "")\([$h,$m,$s] | map(pad_left(2; "0")) | join(":"))\($r.d // "")"
;

def toepoch($t):
    # make sure . is a number, otherwise convert it as an iso8601 string
    if ($t|type) == "number" then $t else (
        # remove timezone at end, we will put it back on
        $t | sub("(Z|[\\+\\-]\\d\\d:?\\d\\d)$"; "") |

        # get the bits on both sides of the period, if it exists
        capture("^(?<n>([^\\.]+))(\\.(?<d>\\d+))?") as $m |

        # convert from iso8601
        "\($m.n)Z" | fromdateiso8601 as $ts |

        # if $t had a decimal part, put that back on
        if $m.d then ("\($ts).\($m.d)" | tonumber) else $ts end
    ) end
;
def toepoch: toepoch(.) ;

def dur($t; $ref):
    # get number of seconds between $t and $ref ($ref is `now` by default)
    toepoch($t) - toepoch(if $ref then $ref else now end) | fabs
;
def dur($t): dur($t; now) ;
def dur:     dur(.; now) ;

def within($a; $b; $x):
    # check if $a and $b are within $x of each other
    dur($a;$b) < ($x|fromhms)
;
def within($b; $x): within(.; $b; $x) ;
def within($x):     within(.; now; $x) ;
