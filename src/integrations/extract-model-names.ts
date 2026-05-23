/** توحيد أشكال الاستجابة من FastAPI أو واجهات أخرى. */
export function extractModelNames(data: unknown): string[] {
  if (Array.isArray(data)) {
    return listFromPrimitives(data as unknown[]);
  }
  if (data !== null && typeof data === 'object') {
    const o = data as Record<string, unknown>;
    const direct = ['models', 'data', 'items', 'choices'];
    for (const k of direct) {
      const v = o[k];
      if (Array.isArray(v)) {
        const out = extractFromArrayEntries(v as unknown[]);
        if (out.length > 0) {
          return out;
        }
      }
    }
  }
  return [];
}

function listFromPrimitives(arr: unknown[]): string[] {
  const out: string[] = [];
  for (const x of arr) {
    if (typeof x === 'string') {
      const t = x.trim();
      if (t.length > 0) {
        out.push(t);
      }
    }
  }
  return uniq(out);
}

function extractFromArrayEntries(arr: unknown[]): string[] {
  const out: string[] = [];
  for (const x of arr) {
    if (typeof x === 'string') {
      const t = x.trim();
      if (t.length > 0) {
        out.push(t);
      }
      continue;
    }
    if (x !== null && typeof x === 'object') {
      const m = x as Record<string, unknown>;
      const name = m.name ?? m.model ?? m.id;
      if (typeof name === 'string' && name.trim().length > 0) {
        out.push(name.trim());
      }
    }
  }
  return uniq(out);
}

function uniq(items: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const s of items) {
    if (!seen.has(s)) {
      seen.add(s);
      out.push(s);
    }
  }
  return out;
}
