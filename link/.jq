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
def fromhms($x): $x | fromhms ;

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
def tohms($x): $x | tohms ;

def toepoch($t):
    # make sure . is a number, otherwise convert it as an iso8601 string
    if ($t|type) == "number" then $t else (
        # remove timezone at end, we will put it back on
        $t | sub("(Z|[\\+\\-]\\d\\d:?\\d\\d)$"; "") |

        # add "T" if needed
        sub("(?<a>\\d\\d) (?<b>\\d\\d)"; "\(.a)T\(.b)") |

        # get the bits on both sides of the period, if it exists
        capture("^(?<n>([^\\.]+))(\\.(?<d>\\d+))?") as $m |

        # convert from iso8601
        "\($m.n)Z" | fromdateiso8601 as $ts |

        # if $t had a decimal part, put that back on
        if $m.d then ("\($ts).\($m.d)" | tonumber) else $ts end
    ) end
;
def toepoch: toepoch(.) ;

def dur($a; $b):
    # get number of seconds between $a and $b
    ( ($a|toepoch|fabs) - ($b|toepoch|fabs) ) | fabs
;
def dur($t): dur($t; now) ;
def dur:     dur(.; now) ;

def within($x; $a; $b):
    # check if $a and $b are within $x of each other
    dur($a;$b) < (if ($x|type) == "number" then $x else ($x|fromhms) end)
;
def within($x; $b): ($b|toepoch) as $c | within($x; $c; .) ;
def within($x): within($x; .) ;

# chunk stream into $n-long arrays
# https://stackoverflow.com/a/51413843
def nwise(stream; $n):
  foreach (stream, nan) as $x ([];
    if length == $n then [$x] else . + [$x] end;
    if (.[-1] | isnan) and length>1 then .[:-1]
    elif length == $n then .
    else empty
    end);

# https://users.aalto.fi/~tontti/posts/jq-and-human-readable-bytes/
def bytes:
  def _bytes(v; u):
    if (u | length) == 1 or (u[0] == "" and v < 10000) or v < 1000 then
      "\(v *100 | round /100) \(u[0])B"
    else
      _bytes(v/1000; u[1:])
    end;
  _bytes(.; ":k:M:G:T:P:E:Z:Y" / ":");
