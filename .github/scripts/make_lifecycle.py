"""Generate .github/assets/lifecycle-{light,dark}.svg: the animated spec lifecycle in docs/first-feature.md.

Run from anywhere: python3 .github/scripts/make_lifecycle.py
Colours are the JoDi-27 design system tokens, matching the banners and the README demo.

The full graph is always drawn faintly. The animation walks the happy path first, then each
thing /jsdd:verify can do to a spec, one at a time, lighting up the path it takes.
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

W, H = 1000, 430
MONO = "ui-monospace, SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace"
SANS = "Inter, system-ui, -apple-system, 'Segoe UI', sans-serif"

# Nodes: id -> (label, cx, cy)
NODES = {
    "draft": ("draft", 150, 112),
    "planned": ("planned", 400, 112),
    "inprog": ("in-progress", 650, 112),
    "done": ("done", 900, 112),
    "approved": ("approved", 525, 232),
    "blocked": ("blocked", 775, 232),
    "dropped": ("dropped", 920, 232),
}
NH = 30


def nw(label):
    return 26 + len(label) * 8.2


# Edges: id -> dict(d=path, label=(command, outcome), lx, ly, anchor)
EDGES = {
    "specify": dict(d="M 40 112 L {draft_l} 112", label=("specify", ""), lx=72, ly=98, anchor="start"),
    "plan": dict(d="M {draft_r} 112 L {planned_l} 112", label=("plan", ""), lx=275, ly=98, anchor="middle"),
    "implement": dict(d="M {planned_r} 112 L {inprog_l} 112", label=("implement", ""), lx=525, ly=98, anchor="middle"),
    "verify_done": dict(d="M {inprog_r} 112 L {done_l} 112", label=("verify", "converged"), lx=775, ly=98, anchor="middle"),
    "gaps_ok": dict(d="M 640 128 L 548 216", label=("", "gaps approved"), lx=578, ly=170, anchor="end"),
    "amend": dict(d="M 502 216 L 412 128", label=("plan", "amendment"), lx=444, ly=182, anchor="end"),
    "gaps_no": dict(d="M 662 128 L 752 216", label=("", "gaps declined"), lx=722, ly=182, anchor="start"),
    "resume": dict(d="M 775 248 C 775 318 700 318 600 318 L 420 318 C 390 318 380 300 380 280 L 380 128",
                   label=("plan", "fix the gaps after all"), lx=590, ly=340, anchor="middle"),
    "drop": dict(d="M {blocked_r} 232 L {dropped_l} 232", label=("", "dropped by hand"), lx=848, ly=256, anchor="middle"),
    "spec_change": dict(d="M 650 96 C 650 26 150 26 150 96", label=("", "spec change approved"), lx=400, ly=36, anchor="middle"),
    "respec": dict(d="M {draft_r} 118 L {planned_l} 118", label=("specify, then plan", "amendment"), lx=250, ly=142, anchor="middle"),
}

# Phases: caption, start node, steps of (edge, node reached)
PHASES = [
    ("Happy path", "Each command is your approval of the step before it.", None,
     [("specify", "draft"), ("plan", "planned"), ("implement", "inprog"), ("verify_done", "done")]),
    ("Verify finds gaps, you approve the fixes", "Plan adds them as an amendment, and the loop runs again.", "inprog",
     [("gaps_ok", "approved"), ("amend", "planned"), ("implement", "inprog"), ("verify_done", "done")]),
    ("Verify finds gaps, you decline the fixes", "The spec is blocked until you plan them after all, or drop it by hand.", "inprog",
     [("gaps_no", "blocked"), ("drop", "dropped"), ("resume", "planned"), ("implement", "inprog"), ("verify_done", "done")]),
    ("A fix changes the spec itself", "Back to draft: revise it with specify, then plan the rest.", "inprog",
     [("spec_change", "draft"), ("respec", "planned"), ("implement", "inprog"), ("verify_done", "done")]),
]

EDGE_T = 0.8       # edge draw time
NODE_HOLD = 2.0    # time a node stays active before the next edge draws
PHASE_IN = 1.4     # caption and start node appear before the first edge
PHASE_HOLD = 4.0   # read the finished phase
FADE = 0.4

t = 0.0
for title, cap, start, steps in PHASES:
    ph = dict(start=t)
    t += PHASE_IN
    ph["steps"] = []
    for e, n in steps:
        ph["steps"].append((e, n, t))
        t += EDGE_T + NODE_HOLD
    t += PHASE_HOLD
    ph["end"] = t
    t += FADE
    ph["title"], ph["cap"], ph["from"] = title, cap, start
    PHASES[PHASES.index((title, cap, start, steps))] = ph
CYCLE = round(t, 2)

rules = []
n = 0


def pct(t):
    return f"{max(0.0, min(100.0, t / CYCLE * 100)):.3f}%"


def anim(frames, extra=""):
    global n
    n += 1
    name = f"a{n}"
    body = []
    for f in frames:
        tt, css = f[0], f[1]
        timing = f" animation-timing-function: {f[2]};" if len(f) > 2 else ""
        body.append(f"{pct(tt)} {{ {css};{timing} }}")
    rules.append(f"@keyframes {name} {{ {' '.join(body)} }}")
    rules.append(f".{name} {{ animation: {name} {CYCLE}s infinite linear; {extra}}}")
    return name


def windows(wins, fade=0.12):
    """Opacity 1 inside each (a, b) window, 0 elsewhere."""
    frames = [(0, "opacity: 0")]
    for a, b in sorted(wins):
        frames += [(a, "opacity: 0"), (a + fade, "opacity: 1"), (b, "opacity: 1"), (b + fade, "opacity: 0")]
    frames.append((CYCLE, "opacity: 0"))
    return anim(frames)


def geom():
    g = {}
    for k, (label, cx, cy) in NODES.items():
        w = nw(label)
        g[f"{k}_l"] = f"{cx - w / 2 - 2:.0f}"
        g[f"{k}_r"] = f"{cx + w / 2 + 2:.0f}"
    return g


def node(k, c, state):
    label, cx, cy = NODES[k]
    w = nw(label)
    x, y = cx - w / 2, cy - NH / 2
    if state == "idle":
        return (f'<rect x="{x:.0f}" y="{y:.0f}" width="{w:.0f}" height="{NH}" rx="15" fill="{c["paper"]}" stroke="{c["stone"]}" stroke-width="1.5"/>'
                f'<text x="{cx}" y="{cy + 5}" text-anchor="middle" class="lbl o">{label}</text>')
    if state == "active":
        return (f'<rect x="{x:.0f}" y="{y:.0f}" width="{w:.0f}" height="{NH}" rx="15" fill="{c["teal"]}"/>'
                f'<text x="{cx}" y="{cy + 5}" text-anchor="middle" class="lbl" fill="{c["on_teal"]}" font-weight="600">{label}</text>')
    return (f'<rect x="{x:.0f}" y="{y:.0f}" width="{w:.0f}" height="{NH}" rx="15" fill="{c["paper"]}" stroke="{c["teal"]}" stroke-width="1.5"/>'
            f'<text x="{cx}" y="{cy + 5}" text-anchor="middle" class="lbl i">{label}</text>')


def chevron(d, size=7.0, spread=0.5):
    """An open arrowhead at the end of path d, as path commands: from one wing to the tip to the other wing."""
    import math, re
    nums = [float(v) for v in re.findall(r"-?\d+(?:\.\d+)?", d)]
    cmds = re.findall(r"[MLC]", d)
    tip = (nums[-2], nums[-1])
    # the end tangent: from the last control point (C) or the previous point (L) to the tip
    prev = (nums[-4], nums[-3])
    ang = math.atan2(tip[1] - prev[1], tip[0] - prev[0])
    w1 = (tip[0] - size * math.cos(ang - spread), tip[1] - size * math.sin(ang - spread))
    w2 = (tip[0] - size * math.cos(ang + spread), tip[1] - size * math.sin(ang + spread))
    return f" M {w1[0]:.1f} {w1[1]:.1f} L {tip[0]:.1f} {tip[1]:.1f} L {w2[0]:.1f} {w2[1]:.1f}"


def edge_path(k, c, colour, width=1.5):
    """An edge with the same chevron the lit copy draws, so the lit copy covers it exactly."""
    d = EDGES[k]["d"].format(**geom())
    return f'<path d="{d + chevron(d)}" fill="none" stroke="{colour}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'


def edge_label(k, cls_cmd, cls_out):
    e = EDGES[k]
    cmd, out = e["label"]
    runs = []
    if cmd:
        runs.append(f'<tspan class="{cls_cmd}">{escape(cmd)}</tspan>')
    if cmd and out:
        runs.append(f'<tspan class="{cls_out}"> · </tspan>')
    if out:
        runs.append(f'<tspan class="{cls_out} it">{escape(out)}</tspan>')
    return f'<text x="{e["lx"]}" y="{e["ly"]}" text-anchor="{e["anchor"]}" class="el">{"".join(runs)}</text>'


def build(theme):
    global rules, n
    rules, n = [], 0
    c = THEMES[theme]
    out = []

    # Base layer: the whole graph, faint
    base = []
    for k in EDGES:
        base.append(edge_path(k, c, c["stone"]))
        base.append(edge_label(k, "o", "o"))
    for k in NODES:
        base.append(node(k, c, "idle"))
    out.append(f'<g class="base">{"".join(base)}</g>')

    # Per-phase highlight layers
    for ph in PHASES:
        a, b = ph["start"], ph["end"]
        parts = []
        # caption
        parts.append(f'<line x1="{W / 2 - 14}" y1="{H - 64}" x2="{W / 2 + 14}" y2="{H - 64}" stroke="{c["teal"]}" stroke-width="2"/>')
        parts.append(f'<text x="{W / 2}" y="{H - 44}" text-anchor="middle" class="ttl">{escape(ph["title"].upper())}</text>')
        parts.append(f'<text x="{W / 2}" y="{H - 20}" text-anchor="middle" class="cap">{escape(ph["cap"])}</text>')
        # start node active until the first edge reaches its node
        node_wins = {}  # node -> list of (state, a, b)
        if ph["from"]:
            node_wins.setdefault(ph["from"], []).append(("active", a, ph["steps"][0][2] + EDGE_T))
        for i, (e, nd, ts) in enumerate(ph["steps"]):
            # edge draws from ts to ts+EDGE_T, stays lit till phase end
            d = EDGES[e]["d"].format(**geom())
            length = 1200
            draw = anim([(0, f"stroke-dashoffset: {length}; opacity: 0"), (ts, f"stroke-dashoffset: {length}; opacity: 1"),
                         (ts + EDGE_T, "stroke-dashoffset: 0; opacity: 1"), (b, "stroke-dashoffset: 0; opacity: 1"),
                         (b + FADE, "stroke-dashoffset: 0; opacity: 0"), (CYCLE, f"stroke-dashoffset: {length}; opacity: 0")])
            # the arrowhead is the path's last segment, a chevron, so the dash reveal draws it right after the line arrives
            parts.append(f'<g class="{draw}" style="stroke-dasharray: {length}"><path d="{d + chevron(d)}" fill="none" stroke="{c["teal"]}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></g>')
            lbl = windows([(ts + EDGE_T * 0.6, b)])
            parts.append(f'<g class="{lbl}"><rect x="0" y="0" width="0" height="0"/>{edge_label(e, "t", "i")}</g>')
            reached = ts + EDGE_T
            nxt = ph["steps"][i + 1][2] + EDGE_T if i + 1 < len(ph["steps"]) else b
            # the node stays active until the next node is reached; then visited till phase end
            # "dropped" is a side branch: it goes straight to visited when the next edge leaves blocked
            node_wins.setdefault(nd, []).append(("active", reached, nxt))
            node_wins.setdefault(nd, []).append(("visited", nxt, b))
            # when a node is left (next edge starts from it), the previous active goes visited; handled by nxt
        for nd, wins in node_wins.items():
            for state in ("visited", "active"):
                ws = [(x, y) for s, x, y in wins if s == state and y > x]
                if not ws:
                    continue
                # a node can be active in several windows (e.g. planned and in-progress twice); merge
                frames = [(0, "opacity: 0")]
                for x, y in sorted(ws):
                    frames += [(x, "opacity: 0"), (x + 0.1, "opacity: 1"), (y, "opacity: 1"), (y + 0.1, "opacity: 0")]
                frames.append((CYCLE, "opacity: 0"))
                cls = anim(frames)
                parts.append(f'<g class="{cls}">{node(nd, c, state)}</g>')
        cap_cls = windows([(a, b)], fade=0.25)
        out.append(f'<g class="{cap_cls} ph">{"".join(parts)}</g>')

    waves = (
        f'<g mask="url(#fade)"><g transform="translate(0 {H - 78}) scale(0.8333 0.65)">'
        f'<path fill="{c["stone"]}" fill-opacity=".6" d="M0 80 C 180 30, 330 20, 470 55 S 760 110, 930 50 S 1120 0, 1200 15 L1200 120 L0 120 Z"/>'
        f'<path fill="{c["sage"]}" fill-opacity=".75" d="M0 95 C 160 65, 300 50, 450 78 S 720 120, 900 72 S 1110 32, 1200 48 L1200 120 L0 120 Z"/>'
        f'<path fill="{c["sage"]}" d="M0 112 C 220 90, 380 84, 560 102 S 880 118, 1040 94 S 1160 82, 1200 86 L1200 120 L0 120 Z"/>'
        f'</g></g>'
    )

    style = f"""
text {{ font-family: {SANS}; }}
.lbl {{ font-size: 14px; font-weight: 500; letter-spacing: .02em; }}
.el {{ font-family: {MONO}; font-size: 13px; }}
.it {{ font-family: {SANS}; font-style: italic; }}
.ttl {{ font-size: 13px; font-weight: 700; letter-spacing: .14em; fill: {c["teal_text"]}; }}
.cap {{ font-size: 17px; font-weight: 500; fill: {c["ink"]}; }}
.o {{ fill: {c["muted"]}; }} .i {{ fill: {c["ink"]}; }} .t {{ fill: {c["teal_text"]}; font-weight: 600; }}
.base {{ opacity: .55; }}
{chr(10).join(rules)}
@media (prefers-reduced-motion: reduce) {{
  g {{ animation: none !important; }}
  .ph {{ display: none; }}
  .base {{ opacity: 1; }}
  .base .o {{ fill: {c["ink"]}; }}
}}
"""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-labelledby="t d">
  <title id="t">Spec lifecycle</title>
  <desc id="d">A feature spec goes draft, planned, in-progress, done, one command per step. When verify finds gaps, approving the fixes sends the spec to approved and plan adds an amendment; declining blocks it until plan resumes it or it is dropped; a spec change sends it back to draft for specify, then plan.</desc>
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
    with open(f"{OUT}/lifecycle-{theme}.svg", "w") as f:
        f.write(build(theme))
