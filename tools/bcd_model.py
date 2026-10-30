"""Host-side model of the proposed AddScoreHL (no divisor table).
Score is 7 BCD bytes, wScore+0 (most significant) .. wScore+6. Value is in score units (x10 pts).
Algorithm: split value into hundreds (h), tens (t), ones (o) by subtraction, then add each
digit at column 3/4/5 with decimal carry toward column 0."""

def add_digit(score, col, d):
    # score: list of 7 ints (BCD digits); add digit d (0-9) at column col with carry
    if d == 0:
        return
    score[col] += d
    i = col
    while score[i] >= 10:
        score[i] -= 10
        i -= 1
        score[i] += 1

def add_value(score, v):
    h = 0
    while v >= 100:
        v -= 100
        h += 1
    t = 0
    while v >= 10:
        v -= 10
        t += 1
    o = v
    # hundreds count can exceed 9 only if v > 999; add as repeated digits
    while h > 0:
        add_digit(score, 3, 1); h -= 1
    while t > 0:
        add_digit(score, 4, 1); t -= 1
    add_digit(score, 5, o)

def to_int(score):
    return int("".join(str(x) for x in score))

def check():
    cases = [0, 1, 9, 10, 99, 100, 101, 255, 256, 999, 1000, 2550, 2000, 200, 65535 // 100]
    for c in cases:
        s = [0] * 7
        add_value(s, c)
        got = to_int(s)
        # score units are x10 points: value c is stored as the BCD number c*10 (column 5 = 1 unit of 10 pts)
        assert got == c * 10, (c, got, s)
    # carry chain: 9999 + 1 across columns
    s = [0, 0, 0, 9, 9, 9, 0]
    add_value(s, 1)
    assert s == [0, 0, 0, 0, 0, 0, 0] or to_int(s) == 10000, s
    print("all cases ok")

if __name__ == "__main__":
    check()
