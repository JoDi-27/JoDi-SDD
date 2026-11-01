"""Generate .github/assets/demo-{light,dark}.svg: the animated walk through the JoDi-SDD loop in the README.

Run from anywhere: python3 .github/scripts/make_demo.py
Colours are the JoDi-27 design system tokens, matching the banners.
"""
from html import escape
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets"

THEMES = {
    "light": dict(paper="#f9f7f3", stone="#d9d3c9", sage="#b8c1ba", teal="#0b8677",
                  teal_text="#0a7a6c", on_teal="#f9f7f3", ink="#1b201f", muted="#5a625e"),
    "dark": dict(paper="#161b1a", stone="#343b38", sage="#3d4a44", teal="#3fb8a6",
                 teal_text="#3fb8a6", on_teal="#161b1a", ink="#eeeae3", muted="#9ba39f"),
}

W, H = 1000, 380
FS = 15
CH = FS * 0.602          # monospace advance
LH = 27
X0, Y0 = 40, 128
MONO = "ui-monospace, SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace"
SANS = "Inter, system-ui, -apple-system, 'Segoe UI', sans-serif"

# Each output line is a list of (text, class) runs. Classes: o = muted, i = ink, t = teal, b = bold ink.
SCENES = [
    dict(step=0, cmd="/jsdd:specify Password reset by email", lines=[
        [("wrote ", "o"), ("specs/001-password-reset.md", "i")],
        [("AC-1  ", "t"), ("A reset link is emailed to a registered address", "o")],
        [("AC-2  ", "t"), ("The link expires after 30 minutes", "o")],
        [("1 question blocks this spec: which email provider?  ", "o"), ("→ spike 003", "i")],
    ]),
    dict(step=1, cmd="/jsdd:plan 001", lines=[
        [("approved ", "o"), ("001", "i")],
        [("reviewer, fresh context: plan checked against specs/constitution.md", "o")],
        [("T1  ", "t"), ("reset token model     ", "i"), ("check: npm test -- token", "o")],
        [("T2  ", "t"), ("reset email           ", "i"), ("check: npm test -- mail", "o")],
        [("T3  ", "t"), ("reset form            ", "i"), ("check: npm test -- form", "o")],
    ]),
    dict(step=2, cmd="/jsdd:implement 001", lines=[
        [("check: npm test -- token", "o")],
        [("check passed; ticked 001 T1", "t")],
        [("check: npm test -- mail", "o")],
        [("check failed (exit 1); 001 T2 not ticked", "b")],
        [("check: npm test -- mail", "o"), ("   after the fix", "i")],
        [("check passed; ticked 001 T2", "t")],
    ]),
    dict(step=3, cmd="/jsdd:verify 001", lines=[
        [("reviewer, fresh context: one verdict per acceptance criterion", "o")],
        [("AC-1  ", "t"), ("pass  ", "i"), ("evidence: reset.test.ts \"emails a reset link\"", "o")],
        [("AC-2  ", "t"), ("pass  ", "i"), ("evidence: reset.test.ts \"expires after 30 min\"", "o")],
        [("closed 001: ", "o"), ("done", "t")],
    ]),
    dict(step=4, cmd="/jsdd:status", lines=[
        [("Next up:", "i")],
        [("  003  ", "t"), ("draft       ", "o"), ("Which email provider      ", "i"), ("/jsdd:spike 003", "o")],
        [("  002  ", "t"), ("draft       ", "o"), ("Account lockout           ", "i"), ("/jsdd:specify 002", "o")],
        [("Requirement coverage:", "i")],
        [("  Must                  2   with a spec   2   done   1", "o")],
    ]),
]
STEPS = ["specify", "plan", "implement", "verify"]

TYPE_START = 0.6       # after scene start
TYPE_CPS = 14          # characters per second
FIRST_LINE = 1.0       # pause after typing
LINE_GAP = 1.5
HOLD = 2.6             # time to read a scene after its last line
FINAL_HOLD = 5.0       # the board stays up longer before the loop restarts
FADE = 0.25            # scene fade-out before its end

# Each scene lasts as long as its command takes to type and its lines take to appear, plus time to read.
t = 0.0
for s_ in SCENES:
    s_["start"] = t
    t += TYPE_START + len(s_["cmd"]) / TYPE_CPS + FIRST_LINE + (len(s_["lines"]) - 1) * LINE_GAP
    t += FINAL_HOLD if s_ is SCENES[-1] else HOLD + FADE
    s_["end"] = t
CYCLE = round(t, 2)

rules = []
n = 0


def pct(t):
    return f"{max(0.0, min(100.0, t / CYCLE * 100)):.3f}%"


def anim(frames, extra=""):
    """Register a keyframes animation, return its class name. frames: list of (t, css[, timing])."""
    global n
    n += 1
    name = f"a{n}"
    body = []
    for f in frames:
        t, css = f[0], f[1]
        timing = f" animation-timing-function: {f[2]};" if len(f) > 2 else ""
        body.append(f"{pct(t)} {{ {css};{timing} }}")
    rules.append(f"@keyframes {name} {{ {' '.join(body)} }}")
    rules.append(f".{name} {{ animation: {name} {CYCLE}s infinite linear; {extra}}}")
    return name


def visible_between(a, b):
    frames = [(0, "opacity: 0")]
    if a > 0:
        frames.append((a, "opacity: 0"))
    frames += [(a + 0.12, "opacity: 1"), (b, "opacity: 1"), (b + 0.12, "opacity: 0"), (CYCLE, "opacity: 0")]
    if b >= CYCLE:
        frames = frames[:-2] + [(CYCLE, "opacity: 1")]
    return anim(frames)


def text_runs(runs, x, y):
    spans = "".join(f'<tspan class="{c}">{escape(s)}</tspan>' for s, c in runs)
    return f'<text x="{x}" y="{y}" xml:space="preserve">{spans}</text>'


def build(theme):
    global rules, n
    rules, n = [], 0
    c = THEMES[theme]
    out = []

    # Step track
    track_y = 50
    cx = X0 + 9
    for i, label in enumerate(STEPS):
        if i:
            nxt = prev_end + 70
            out.append(f'<line x1="{prev_end:.0f}" y1="{track_y}" x2="{nxt - 22:.0f}" y2="{track_y}" stroke="{c["stone"]}"/>')
            cx = nxt
        prev_end = cx + 16 + len(label) * 8.6 + 14
        # state windows across scenes
        states = {"pending": [], "active": [], "done": []}
        for s in SCENES:
            st = "done" if s["step"] > i else "active" if s["step"] == i else "pending"
            states[st].append((s["start"], s["end"]))
        groups = {
            "pending": f'<circle cx="{cx}" cy="{track_y}" r="8" fill="none" stroke="{c["stone"]}" stroke-width="1.5"/>'
                       f'<text x="{cx + 16}" y="{track_y + 5}" class="lbl o">{label}</text>',
            "active": f'<circle cx="{cx}" cy="{track_y}" r="8" fill="{c["teal"]}"/>'
                      f'<circle cx="{cx}" cy="{track_y}" r="3" fill="{c["on_teal"]}"/>'
                      f'<text x="{cx + 16}" y="{track_y + 5}" class="lbl b">{label}</text>',
            "done": f'<circle cx="{cx}" cy="{track_y}" r="8" fill="none" stroke="{c["teal"]}" stroke-width="1.5"/>'
                    f'<polyline points="{cx - 3.5},{track_y} {cx - 1},{track_y + 2.8} {cx + 3.8},{track_y - 2.8}" fill="none" '
                    f'stroke="{c["teal"]}" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"/>'
                    f'<text x="{cx + 16}" y="{track_y + 5}" class="lbl o">{label}</text>',
        }
        for st, wins in states.items():
            if not wins:
                continue
            frames = [(0, "opacity: 0")]
            for a, b in wins:
                frames += [(a, "opacity: 1"), (b - 0.001, "opacity: 1"), (b, "opacity: 0")]
            frames.append((CYCLE, "opacity: 0"))
            frames.sort(key=lambda f: f[0])
            cls = anim(frames, "animation-timing-function: steps(1, end);")
            rm = " rm-show" if st == ("done") else " rm-hide"
            out.append(f'<g class="{cls}{rm}">{groups[st]}</g>')

    out.append(f'<line x1="0" y1="86" x2="{W}" y2="86" stroke="{c["stone"]}"/>')

    # Scenes
    for si, s in enumerate(SCENES):
        last = si == len(SCENES) - 1
        g_cls = visible_between(s["start"], s["end"] - FADE if not last else CYCLE)
        parts = []
        cmd_x = X0 + 2 * CH
        parts.append(f'<text x="{X0}" y="{Y0}" class="t">›</text>')
        parts.append(f'<text x="{cmd_x}" y="{Y0}" class="i">{escape(s["cmd"])}</text>')
        # typing: a paper-coloured cover with the cursor on its left edge slides right in steps
        n_ch = len(s["cmd"])
        t0 = s["start"] + TYPE_START
        t1 = t0 + n_ch / TYPE_CPS
        dist = n_ch * CH
        mv = anim([(0, "transform: translateX(0px)"), (t0, "transform: translateX(0px)", f"steps({n_ch}, end)"),
                   (t1, f"transform: translateX({dist:.1f}px)"), (CYCLE, f"transform: translateX({dist:.1f}px)")])
        parts.append(f'<g class="{mv} rm-hide"><rect x="{cmd_x + 8.5:.1f}" y="{Y0 - 17}" width="{dist + 40:.1f}" height="24" fill="{c["paper"]}"/>'
                     f'<rect x="{cmd_x:.1f}" y="{Y0 - 14}" width="8" height="18" fill="{c["teal"]}" fill-opacity=".85"/></g>')
        t = t1 + FIRST_LINE
        for li, runs in enumerate(s["lines"]):
            cls = anim([(0, "opacity: 0"), (t, "opacity: 0"), (t + 0.35, "opacity: 1"), (CYCLE, "opacity: 1")])
            parts.append(f'<g class="{cls} rm-line">{text_runs(runs, cmd_x, Y0 + (li + 1) * LH + 4)}</g>')
            t += LINE_GAP
        rm = "rm-show" if last else "rm-hide"
        out.append(f'<g class="{g_cls} {rm}">{"".join(parts)}</g>')

    waves = (
        f'<g mask="url(#fade)"><g transform="translate(0 {H - 78}) scale(0.8333 0.65)">'
        f'<path fill="{c["stone"]}" fill-opacity=".6" d="M0 80 C 180 30, 330 20, 470 55 S 760 110, 930 50 S 1120 0, 1200 15 L1200 120 L0 120 Z"/>'
        f'<path fill="{c["sage"]}" fill-opacity=".75" d="M0 95 C 160 65, 300 50, 450 78 S 720 120, 900 72 S 1110 32, 1200 48 L1200 120 L0 120 Z"/>'
        f'<path fill="{c["sage"]}" d="M0 112 C 220 90, 380 84, 560 102 S 880 118, 1040 94 S 1160 82, 1200 86 L1200 120 L0 120 Z"/>'
        f'</g></g>'
    )

    style = f"""
text {{ font-family: {MONO}; font-size: {FS}px; }}
.lbl {{ font-family: {SANS}; font-size: 14px; font-weight: 500; letter-spacing: .02em; }}
.o {{ fill: {c["muted"]}; }} .i {{ fill: {c["ink"]}; }} .t {{ fill: {c["teal_text"]}; }}
.b {{ fill: {c["ink"]}; font-weight: 600; }}
{chr(10).join(rules)}
@media (prefers-reduced-motion: reduce) {{
  g {{ animation: none !important; }}
  .rm-hide {{ opacity: 0; }} .rm-show, .rm-line {{ opacity: 1; }}
}}
"""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-labelledby="t d">
  <title id="t">JoDi-SDD walkthrough</title>
  <desc id="d">A spec for password reset goes through /jsdd:specify, /jsdd:plan, /jsdd:implement (one task check fails and is not ticked until it passes) and /jsdd:verify, then /jsdd:status shows what is next.</desc>
  <defs>
    <clipPath id="card"><rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="10"/></clipPath>
    <linearGradient id="g" x1="0" x2="1" y1="0" y2="0"><stop offset=".45" stop-color="#fff" stop-opacity="0"/><stop offset=".9" stop-color="#fff"/></linearGradient>
    <mask id="fade" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><rect width="{W}" height="{H}" fill="url(#g)"/></mask>
  </defs>
  <style>{style}</style>
  <rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="10" fill="{c["paper"]}"/>
  <g clip-path="url(#card)">{waves}</g>
  <rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="10" fill="none" stroke="{c["stone"]}"/>
  {chr(10).join(out)}
</svg>
"""


for theme in THEMES:
    with open(f"{OUT}/demo-{theme}.svg", "w") as f:
        f.write(build(theme))
