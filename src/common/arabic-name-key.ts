/**
 * Builds a stable comparison key for Arabic (and mixed) names so that:
 * - Hamza, ta marbuta, diacritics, etc. align
 * - "زكريا مهروسة" matches "زكريامهروسه" (spacing / one-piece spelling)
 * - "محمود شعار" matches "محمود ادلبي شعار" (optional middle names → first+last)
 * - "محمد ايمن نعال" matches "محمدأيمن نعال" / "محمدايمن نعال" (glued first+second name)
 * - Known spelling variants: ديما/ديمة، اسجميع/اسجيع
 */


const ARABIC_DIACRITICS =
  /[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D4-\u08FF]/g;

/** Same person, different spelling — keys already character-normalized (lowercase, ة→ه, …). */
const CANONICAL_TOKEN: Record<string, string> = {
  ديما: 'ديمه',
  اسجميع: 'اسجيع',
};

/**
 * If a token is written as two names without space (e.g. محمدايمن), split after these prefixes.
 * Longest first so عبدالرحمن wins over عبد.
 */
const GLUED_FIRST_NAME_PREFIXES: string[] = [
  'عبدالرحمن',
  'عبدالعزيز',
  'عبدالله',
  'محمود',
  'محمد',
  'احمد',
  'مهند',
  'حسين',
  'حسن',
  'يوسف',
  'ياسر',
  'خالد',
  'طارق',
  'عمر',
  'زينب',
  'علي',
].sort((a, b) => b.length - a.length);

function normalizeArabicCharacters(s: string): string {
  let t = s.normalize('NFKC').trim();
  t = t.replace(/\s+/g, ' ');
  t = t.replace(/\u0640/g, ''); // tatweel
  t = t.replace(ARABIC_DIACRITICS, '');
  t = t.replace(/لآ|لأ|لإ/g, 'لا');
  t = t.replace(/[\u0622\u0623\u0625\u0671\u0672\u0673]/g, 'ا');
  t = t.replace(/ء/g, '');
  t = t.replace(/ؤ/g, 'و');
  t = t.replace(/ئ/g, 'ي');
  t = t.replace(/ة/g, 'ه');
  t = t.replace(/ی/g, 'ي');
  t = t.replace(/ک/g, 'ك');
  t = t.replace(/ى/g, 'ي');
  return t.toLowerCase();
}

function canonicalizeToken(token: string): string {
  return CANONICAL_TOKEN[token] ?? token;
}

function splitGluedToken(token: string): string[] {
  for (const prefix of GLUED_FIRST_NAME_PREFIXES) {
    if (token.startsWith(prefix) && token.length > prefix.length) {
      const rest = token.slice(prefix.length);
      if (rest.length >= 2) {
        return [prefix, rest];
      }
    }
  }
  return [token];
}

function expandTokens(rawTokens: string[]): string[] {
  const out: string[] = [];
  for (const t of rawTokens) {
    if (!t) {
      continue;
    }
    const mapped = canonicalizeToken(t);
    out.push(...splitGluedToken(mapped));
  }
  return out;
}

function compoundKey(tokens: string[]): string {
  if (tokens.length === 0) {
    return '';
  }
  if (tokens.length === 1) {
    return tokens[0];
  }
  if (tokens.length === 2) {
    return tokens[0] + tokens[1];
  }
  return tokens[0] + tokens[tokens.length - 1];
}

export function normalizeArabicNameKey(input: string): string {
  const s = normalizeArabicCharacters(input);
  const rawTokens = s.split(' ').filter((x) => x.length > 0);
  const tokens = expandTokens(rawTokens);
  return compoundKey(tokens);
}
