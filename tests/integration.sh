#!/usr/bin/env bash
set -euo pipefail
QUIDRA="${1:?usage: integration.sh /path/to/quidra}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP"
export QUIDRA_CACHE_DIR="$TMP/cache"
"$QUIDRA" package validate "$ROOT"
"$QUIDRA" install "$ROOT"
printf 'Checking Text smoke tests\n' >&2
"$QUIDRA" run "$ROOT/tests/smoke.qui" > "$TMP/output"
printf 'hello, world!\nHELLO, WORLD!\nname:value=more\nno-match\napple|banana|apple\nAki:a,b\nC++|AI ML\nempty=0\ncsv-error\nurl-error\ntrue\n' > "$TMP/expected"
diff -u "$TMP/expected" "$TMP/output"

printf 'Checking Text feature tests\n' >&2
"$QUIDRA" run "$ROOT/tests/features.qui" > "$TMP/features-output"
cat > "$TMP/features-expected" <<'EXPECTED'
identifier=http|server|name
snake=get_last_login_time
camel=firstSecondValue
pascal=FirstSecond
kebab=last-login-date
runs=3
first-run=A:3
date=2024-03-01
weekday=4
between=2
grid-header=Su Mo Tu We Th Fr Sa
grid-last=25 26 27 28 29
date-error
wrapped=a bb|ccc
|a    bb|
|ccc    |
left=|a   b  c|
right=|a  b   c|
last=|xxx     |
width-error
tokens=x12|<=|5|+|3
accept=true
taken=5
position=3
lex-error
sequence-rejected=false
sequence-offset=0
repeated=+|-
choice=true
sequence-accepted=true
combinator-done=true
radix-bin=11111111
radix-oct=377
radix-hex=FF
radix-negative=-FF
base-error
prefix=12:W:3
unicode=0:猫:5
cursor-end=TEXT_CURSOR
cursor-invalid=TEXT_CURSOR:0
characters=a|猫:0
EXPECTED
diff -u "$TMP/features-expected" "$TMP/features-output"

printf 'Checking Text printable joins\n' >&2
"$QUIDRA" run "$ROOT/tests/join.qui" > "$TMP/join-output"
cat > "$TMP/join-expected" <<'EXPECTED'
integers=-12 0 34
no-separator=-12034
empty=||
singleton=5
naturals=0:18446744073709551615
bools=true|false|true
fractions=1.5;-2.25
strings=a::::b
tuples=(1, "x");(2, "y")
EXPECTED
diff -u "$TMP/join-expected" "$TMP/join-output"

printf 'Checking Text padding and translation\n' >&2
"$QUIDRA" run "$ROOT/tests/transform.qui"

cat > "$TMP/unprintable-join.qui" <<'QUI'
import text
class Record(int value)
Record[] records = [Record(1)]
string rendered = text.join(records, ",")
QUI
if "$QUIDRA" check "$TMP/unprintable-join.qui" > "$TMP/join-type-error" 2>&1; then
    echo "Text join unexpectedly accepted unprintable records" >&2
    exit 1
fi
grep -Eqi 'print|interpol|format' "$TMP/join-type-error"

cat > "$TMP/mutate-date.qui" <<'QUI'
import text
auto date = text.calendar.Date(2024, 2, 28)
date.month = 13
QUI
if "$QUIDRA" check "$TMP/mutate-date.qui" > "$TMP/date-error" 2>&1; then
    echo "Date fields unexpectedly writable" >&2
    exit 1
fi
grep -Eqi 'const|read.only|immutable' "$TMP/date-error"
cat > "$TMP/mutate-cursor.qui" <<'QUI'
import text
auto cursor = text.lex.Cursor(["x"])
.cursor.take()
cursor.tokens = []
QUI
if "$QUIDRA" check "$TMP/mutate-cursor.qui" > "$TMP/cursor-error" 2>&1; then
    echo "Cursor tokens unexpectedly writable" >&2
    exit 1
fi
grep -Eqi 'const|read.only|immutable' "$TMP/cursor-error"

