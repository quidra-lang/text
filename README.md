# Quidra Text

## Joining printable values

```quidra
import text

values := [-12, 0, 34]
println(text.join(values, " "))
```

`text.join<T>(T[] values, string separator) -> string` renders each element with ordinary `{value}` interpolation and inserts the separator only between elements. Strings remain unquoted; tuples use their usual tuple representation. Empty input returns `""`, one element has no separator, and an empty separator concatenates the rendered values. The function does not append a newline or mutate its input. Types that do not support ordinary interpolation are rejected by the compiler. Use native `string[].join(separator)` when the elements are already strings.

First-party text parsing and structured text formats for Quidra 0.6.x.

Use [Core `0d0150b`](https://github.com/quidra-lang/quidra/commit/0d0150b6aeaeecf26f471cbbc0fce35f2876782e) or later for `.len()` and checked conversion calls such as `int(text)`. The compatibility workflow pins that baseline.

## Installation

```sh
quidra install quidra-text
```

## ASCII normalization and splitting

```quidra
import text
greeting := text.lower_ascii("HELLO")
parts := "name=value=more".split_once("=")
```

`lower_ascii` and `upper_ascii` are non-mutating string methods in current Core, also exposed as capture-free extension functions by this package; ASCII `A-Z` / `a-z` are mapped while every other Unicode scalar is left unchanged. `split_once(separator)` returns `(string, string) | none`, splitting at only the first occurrence; an empty separator fails with `TEXT_SPLIT`. `split_once` is currently a `text` extension method rather than a Core built-in.

## Word extraction

```quidra
import text
words := text.ascii_words("Apple, banana APPLE", ignore_case = true)
```

`ascii_words` selects maximal consecutive ASCII `A-Z`/`a-z` runs, returning words in source order. `ignore_case` converts ASCII uppercase to lowercase; all other characters delimit words. It does not implement Unicode segmentation or language-specific tokenization.

## CSV

```quidra
import text
rows := text.csv.parse("name,note{NL}Aki,{DQ}hello, world{DQ}{NL}")
```

`csv.parse(string) -> string[][] | error` supports quoted fields, doubled quotes, empty cells, embedded CR/LF, CRLF line endings and a final line without a newline. It rejects bare quotes, characters after a closing quote, and unterminated quotes. All fields remain strings; it performs no implicit numeric conversion. Empty input yields zero rows.

## Form-style URL query strings

```quidra
import text
params := text.url.query.parse("tag=C%2B%2B&tag=AI+ML")
```

`text.url.query.parse` accepts raw query text (optionally beginning with `?`) and returns `map<string, string[]> | error`. Map values retain duplicate-key values in occurrence order, and `keys()` lists keys in first-seen order. Use `get(key)` to read `string[] | none`. `+` is decoded as a space, `%HH` is decoded as a byte, and UTF-8 validity is checked only after all percent decoding; malformed escapes are errors. Values missing `=` become empty strings; empty `&` segments are skipped. This is application/x-www-form-urlencoded style parsing, not a general URI parser.

## Testing

Run `bash tests/integration.sh /path/to/quidra` against the matching Core compiler.

## Identifier segmentation and naming

```quidra
import text
words := text.identifier.words("HTTPServer_name")
formatted := text.identifier.snake("getLastLoginTime")
```

`identifier.words(string) -> string[] | error` recognizes ASCII letters/digits, `_` and `-`. It splits on separators, lower-to-upper boundaries, digit-to-upper boundaries, and acronym-to-word boundaries (e.g. HTTPServer becomes http, server). Output words are lowercase. Empty separators are ignored; invalid characters return `TEXT_IDENTIFIER`. `snake`, `kebab`, `camel` and `pascal` use the same segmentation.

## Reading character sequences

```quidra
import text

input := text.Cursor("12W")
count := .input.take_nat()
character := .input.take_char()
```

`text.Cursor(source)` reads from an immutable string. `offset()` counts consumed Unicode code points and `done()` tests for end of input. `.take_nat()` consumes the maximal consecutive ASCII digit prefix at the current offset and parses it as `nat`. `.take_char()` consumes one Unicode code point as a string. Both return `error` on failure and leave the offset unchanged. Missing input reports `TEXT_CURSOR`, while numeric parsing errors retain the underlying diagnostic.

`text.characters(source) -> string[]` returns one string per Unicode code point, in source order. Empty input yields an empty array. The function is also available as `source.characters()` after importing `text`.

## Padding text to a minimum width

```quidra
import text

field := "-12".pad_start(5)
label := "cat".pad_end(5, ".")
```

`pad_start(extend string source, nat width, string fill := " ") -> string | error` and `pad_end` add the fill character before or after the source until it contains at least `width` Unicode code points. Existing text is never truncated, and a sign counts as part of the source width: `"-12".pad_start(5)` is `"  -12"`. The fill must contain exactly one Unicode code point, even when no padding is required; otherwise the functions return `TEXT_PADDING`. Width zero and empty source are valid. The functions preserve the source value. This is code-point width, not grapheme or terminal display-cell width.

## Translating character alphabets

```quidra
import text

normalized := "Hello, 猫!".translate("H猫", "h犬")
```

`translate(extend string source, string original, string replacement) -> string | error` maps each code point in `original` to the code point at the same position in `replacement`, leaving unmatched characters unchanged. Both alphabets must have the same code-point length, including when the source is empty; unequal lengths return `TEXT_TRANSLATE`. An empty alphabet leaves the source unchanged. Repeated characters in `original` use their last mapping. Translation is simultaneous: a replacement is not translated again. The source remains unchanged. This operation maps individual Unicode code points; it performs no case folding, normalization, deletion or expansion.

## Consecutive text runs

`text.runs(source) -> (string,nat)[]` returns maximal adjacent runs of equal Unicode code points. It preserves run order and distinguishes repeated groups separated by other characters; empty input yields an empty array.

## Gregorian civil dates

```quidra
today := text.calendar.Date(2024, 2, 28)
later := text.calendar.add_days(today, 2)
println(text.calendar.iso(later))
```

`calendar.Date` is validated on construction and contains `year`, `month`, `day`. The module uses the proleptic Gregorian calendar, years 1..9999, no time zones. `leap_year`, `days_in_month`, `ordinal` (0-based from 0001-01-01), `from_ordinal`, `add_days`, `days_between`, `weekday` (Monday=0), `iso`, `parse(YYYY-MM-DD)`, and `month_grid(year,month)` are available. Invalid calendar values and out-of-range day arithmetic return `TEXT_DATE`. `month_grid` produces a Sunday-first display with a header row. Civil dates are not monotonic `time.Instant` or elapsed durations.

The three Date fields are immutable after construction, so later field writes cannot bypass validation. Create a new Date or use `add_days` to obtain another date.

## ASCII word wrapping and justification

`text.layout.wrap(source,width) -> string[] | error` word-wraps space-separated printable ASCII text without losing punctuation, collapsing repeated spaces. `text.layout.justify` distributes spaces across non-final lines and pads final/single-word lines to the requested width. `justify(string source, int width, bool extra_right := false)` assigns remainder spaces to the leftmost gaps by default; `extra_right = true` assigns them to the rightmost gaps on nonfinal, multiword lines only. Final and single-word lines remain right-padded. Both functions require a positive width and reject unsupported controls, non-ASCII text and overlong words with `TEXT_LAYOUT`. Rendering width is ASCII character width, not Unicode display-cell width.

## Lexer and cursor primitives

```quidra
tokens := text.lex.tokenize("x12<=5 + 3")
cursor := text.lex.Cursor(tokens)
.cursor.expect("x12")
```

`lex.tokenize` recognizes ASCII identifiers, integer digits, whitespace, quoted tokens (without escape support), punctuation, and the pairs `== != <= >= && ||`. It preserves token spellings and returns `TEXT_LEX` on invalid characters or unterminated quotes. `lex.Cursor` provides `peek()`, mutating `.take()`, `.accept(token)`, `.expect(token)`, `offset()` and `done()` for recursive-descent parsers. Unexpected expected tokens return `TEXT_PARSE`. `Cursor` additionally supports mutating `.accept_any(options)`, `.accept_sequence(sequence)`, and `.take_while(predicate)` for token-level choice, sequence and repetition. The first two are transactional: when nothing matches, the cursor position is unchanged. `take_while` accepts a capture-free pure `func<bool>(string)` and consumes the maximal matching prefix. This is a token-level parser-combinator substrate, not a complete typed grammar framework.

`Cursor.tokens` is an immutable value snapshot; consuming tokens changes only the private position. Replacing or editing that array through the cursor is rejected, preserving the relationship between `done`, `offset`, `peek` and `take`.

## Integer radix formatting

`text.base_string(extend int value, int base := 10, bool uppercase := false) -> string | error` converts arbitrary-precision signed integers in bases 2..36. It is also usable as `value.base_string(base=16)` when Text is imported. Negative integers have a leading minus sign, zero is `0`, and `uppercase=true` uses A-Z for digits 10..35. Invalid bases return `TEXT_BASE`. Core provides `value.b16` for lowercase hexadecimal and `value.B16` for uppercase hexadecimal. For any fixed base from 2 to 36, use `.bN` or `.BN`. Text's `base_string` instead accepts a run-time integer `base` (2..36) and an `int` receiver, returning a checked `TEXT_BASE` error for invalid bases. Other integer widths convert to `int` when bound to `base_string`'s receiver, following Core's numeric argument-conversion rules. Neither API adds prefixes.

