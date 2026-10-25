// Tiny SVG drawing helper shared by the architecture diagrams. Boxes, dashed
// boundaries and orthogonal arrows with labels; no layout engine, callers
// place everything by coordinate so the result stays predictable.

export const FONT = "Inter, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"

export const KIND_LABELS = {
  person: 'Person',
  app: 'Web app / static site',
  service: 'Service',
  data: 'Data store',
  aws: 'AWS managed service',
  delivery: 'Delivery & operations',
}

// Two palettes, same geometry. The dark one matches the site's dark card
// background (#141312) so the slide does not sit in a white rectangle.
export const PALETTES = {
  light: {
    bg: '#FFFFFF', ink: '#0F172A', muted: '#475569', body: '#1E293B', line: '#334155', ops: '#64748B',
    boundaryFill: '#F8FAFC', boundaryStroke: '#94A3B8', noteFill: '#FFFFFF', noteStroke: '#94A3B8',
    legendFill: '#FFFFFF', legendStroke: '#CBD5E1', footer: '#94A3B8', pillOpacity: 0.12,
    kinds: {
      person: { fill: '#F1F5F9', stroke: '#475569' },
      app: { fill: '#EEF2FF', stroke: '#4F46E5' },
      service: { fill: '#DBEAFE', stroke: '#2563EB' },
      data: { fill: '#FEF3C7', stroke: '#D97706' },
      aws: { fill: '#FFEDD5', stroke: '#EA580C' },
      delivery: { fill: '#DCFCE7', stroke: '#16A34A' },
    },
  },
  dark: {
    bg: '#141312', ink: '#F5F5F4', muted: '#A8A29E', body: '#D6D3D1', line: '#D6D3D1', ops: '#A8A29E',
    boundaryFill: '#1C1B1A', boundaryStroke: '#57534E', noteFill: '#1C1B1A', noteStroke: '#78716C',
    legendFill: '#1C1B1A', legendStroke: '#44403C', footer: '#78716C', pillOpacity: 0.22,
    kinds: {
      person: { fill: '#292524', stroke: '#A8A29E' },
      app: { fill: '#1E1B4B', stroke: '#818CF8' },
      service: { fill: '#172554', stroke: '#60A5FA' },
      data: { fill: '#3F2A06', stroke: '#F59E0B' },
      aws: { fill: '#431407', stroke: '#FB923C' },
      delivery: { fill: '#052E16', stroke: '#4ADE80' },
    },
  },
}

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

// Rough Inter metrics: average advance ≈ 0.55 em regular, 0.6 em bold.
// Conservative on purpose so lines wrap early rather than overflow.
export const textWidth = (s, size, weight = 400) => s.length * size * (weight >= 600 ? 0.6 : 0.55)

export function wrap(text, size, weight, maxWidth) {
  const lines = []
  let line = ''
  for (const word of text.split(/\s+/)) {
    const candidate = line ? `${line} ${word}` : word
    if (textWidth(candidate, size, weight) <= maxWidth || !line) line = candidate
    else {
      lines.push(line)
      line = word
    }
  }
  if (line) lines.push(line)
  return lines
}

export function canvas({ width, height, title, theme = 'light' }) {
  const P = PALETTES[theme]
  const { ink: INK, muted: MUTED, line: LINE, ops: OPS } = P
  const out = []
  const warnings = []

  const text = (x, y, s, { size = 14, weight = 400, fill = INK, anchor = 'start' } = {}) => {
    out.push(
      `<text x="${x}" y="${y}" font-family="${FONT}" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}">${esc(s)}</text>`,
    )
  }

  const raw = (s) => out.push(s)

  // name (bold) · optional pill · optional tag line · optional wrapped description
  const node = ({ x, y, w, h, kind, name, pill, tag, desc, nameSize = 19, descSize = 14, tagSize = 15 }) => {
    const k = P.kinds[kind]
    const pad = 14
    const inner = w - pad * 2
    raw(`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="12" fill="${k.fill}" stroke="${k.stroke}" stroke-width="2"/>`)
    let cy = y + pad + Math.round(nameSize * 0.8)
    for (const l of wrap(name, nameSize, 700, inner)) {
      text(x + pad, cy, l, { size: nameSize, weight: 700 })
      cy += Math.round(nameSize * 1.2)
    }
    if (pill) {
      const pw = Math.round(textWidth(pill, 12, 600)) + 16
      raw(`<rect x="${x + pad}" y="${cy - 9}" width="${pw}" height="20" rx="10" fill="${k.stroke}" opacity="${P.pillOpacity}"/>`)
      text(x + pad + 8, cy + 5, pill, { size: 12, weight: 600, fill: k.stroke })
      cy += 30
    }
    if (tag) {
      cy += Math.round(tagSize * 0.3)
      for (const l of wrap(tag, tagSize, 500, inner)) {
        text(x + pad, cy, l, { size: tagSize, weight: 500, fill: MUTED })
        cy += Math.round(tagSize * 1.3)
      }
    }
    if (desc) {
      cy += 2
      const lh = Math.round(descSize * 1.3)
      for (const l of wrap(desc, descSize, 400, inner)) {
        text(x + pad, cy, l, { size: descSize, fill: P.body })
        cy += lh
      }
    }
    const used = cy - y - 6
    if (used > h) warnings.push(`${name}: content ${used}px exceeds box height ${h}px`)
  }

  const note = ({ x, y, w, h, title: t, body }) => {
    raw(`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="8" fill="${P.noteFill}" stroke="${P.noteStroke}" stroke-width="1.5" stroke-dasharray="5 4"/>`)
    let cy = y + 20
    text(x + 12, cy, t, { size: 13, weight: 600 })
    for (const l of wrap(body, 12.5, 400, w - 24)) {
      cy += 17
      text(x + 12, cy, l, { size: 12.5, fill: MUTED })
    }
    if (cy + 6 > y + h) warnings.push(`${t}: note content exceeds box height ${h}px`)
  }

  const boundary = ({ x, y, w, h, title: t, sub, titleSize = 16 }) => {
    raw(`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="18" fill="${P.boundaryFill}" stroke="${P.boundaryStroke}" stroke-width="2" stroke-dasharray="10 7"/>`)
    text(x + 18, y + 10 + titleSize, t, { size: titleSize, weight: 700, fill: LINE })
    if (sub) text(x + 18, y + 29 + titleSize, sub, { size: 13, fill: MUTED })
  }

  // points: [[x,y],...] drawn as an orthogonal polyline with an arrowhead.
  // label: string or string[]; at: [x,y] baseline of the first line.
  const edge = (points, { label, at, anchor = 'middle', dashed = false, size = 13 } = {}) => {
    const color = dashed ? OPS : LINE
    const d = points.map(([px, py], i) => `${i ? 'L' : 'M'}${px},${py}`).join(' ')
    raw(`<path d="${d}" fill="none" stroke="${color}" stroke-width="2.2" ${dashed ? 'stroke-dasharray="8 6"' : ''} marker-end="url(#${dashed ? 'arrow-ops' : 'arrow'})"/>`)
    if (!label) return
    const lines = Array.isArray(label) ? label : [label]
    let [lx, ly] = at
    for (const l of lines) {
      const tw = textWidth(l, size, 500)
      const bx = anchor === 'middle' ? lx - tw / 2 : anchor === 'end' ? lx - tw : lx
      raw(`<rect x="${bx - 4}" y="${ly - size + 2}" width="${tw + 8}" height="${size + 4}" rx="4" fill="${P.bg}" opacity="0.92"/>`)
      text(lx, ly, l, { size, weight: 500, fill: color, anchor })
      ly += Math.round(size * 1.3)
    }
  }

  const legendSwatch = (x, y, kind, label, size = 13.5) => {
    const k = P.kinds[kind]
    raw(`<rect x="${x}" y="${y - 12}" width="28" height="18" rx="4" fill="${k.fill}" stroke="${k.stroke}" stroke-width="1.5"/>`)
    text(x + 38, y + 2, label, { size, fill: P.body })
  }

  const legendArrow = (x, y, label, { dashed = false, size = 13.5 } = {}) => {
    raw(`<path d="M${x},${y} L${x + 28},${y}" stroke="${dashed ? OPS : LINE}" stroke-width="2.2" ${dashed ? 'stroke-dasharray="8 6"' : ''} marker-end="url(#${dashed ? 'arrow-ops' : 'arrow'})"/>`)
    text(x + 38, y + 4, label, { size, fill: P.body })
  }

  // Boxed legend: every kind plus the two arrow styles.
  const legendBox = (x, y) => {
    raw(`<rect x="${x}" y="${y}" width="260" height="250" rx="12" fill="${P.legendFill}" stroke="${P.legendStroke}" stroke-width="1.5"/>`)
    text(x + 16, y + 28, 'Legend', { size: 15, weight: 700, fill: LINE })
    let ly = y + 54
    for (const kind of Object.keys(KIND_LABELS)) {
      legendSwatch(x + 16, ly, kind, KIND_LABELS[kind])
      ly += 25
    }
    legendArrow(x + 16, ly + 2, 'Runtime request / data flow')
    legendArrow(x + 16, ly + 27, 'Deploy & operations', { dashed: true })
  }

  const toString = () => `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="t">
<title id="t">${esc(title)}</title>
<defs>
  <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="${LINE}"/></marker>
  <marker id="arrow-ops" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="${OPS}"/></marker>
</defs>
<rect width="${width}" height="${height}" fill="${P.bg}"/>
${out.join('\n')}
</svg>
`

  return { text, raw, node, note, boundary, edge, legendSwatch, legendArrow, legendBox, palette: P, warnings, toString }
}
