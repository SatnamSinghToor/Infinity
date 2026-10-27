// generate-product-description — the seller's AI writer, now in git.
//
// The "Generate with AI" button on Add Product has called this function by
// name since it was written (`lib/screens/seller/add_product_screen.dart`,
// through `lib/services/product_description_service.dart`), and its source was
// never in this repository — `supabase/README.md` listed it under "Missing
// here, present only in the dashboard". So the button answered "Could not
// generate description" and nobody could see why: a function that lives only in
// one project's dashboard cannot be reviewed, cannot be fixed, and goes away
// with the project. This file is that function, plus the length rule the whole
// feature is now built around.
//
// The rule: 700 words at the shortest, 1500 at the longest — the same pair the
// app asks with (`ProductDescriptionAi.minWords` / `.maxWords`) and shows under
// the description box. A two-line description sells nothing, and a description
// the buyer never reaches the end of is worse. A floor like that cannot be left
// to good manners, so the length is *verified* here: the writer is given a word
// budget per section, what comes back is counted, a text short of the floor is
// continued (up to AI_MAX_PASSES times), and a text over the ceiling is cut at
// the last sentence that fits.
//
// Secrets (Supabase dashboard → Edge Functions → Secrets):
//   AI_API_KEY       the provider key. Without it the function still answers —
//                    see "Writing without a key" below. OPENAI_API_KEY works.
//                    GROQ_API_KEY works too, and then the address and model
//                    default to Groq's (see GROQ below).
//   AI_MODEL         default gpt-4o-mini; OPENAI_MODEL works too
//   AI_BASE_URL      any OpenAI-compatible endpoint. Default:
//                    https://api.openai.com/v1
//                    Groq        https://api.groq.com/openai/v1
//                    OpenRouter  https://openrouter.ai/api/v1
//                    DeepSeek    https://api.deepseek.com/v1
//                    Together    https://api.together.xyz/v1
//   AI_TEMPERATURE       0..2, default 0.7
//   AI_REQUEST_TIMEOUT_MS  one call to the provider, default 90000
//   AI_BUDGET_MS         the whole request, passes included, default 120000 —
//                        what runs out of it is answered with what was written
//   AI_MAX_TOKENS        overrides the token budget the word target sets
//   AI_MAX_PASSES        writing passes per request, default 3
//   AI_RATE_MAX          descriptions one account may ask for in ten minutes,
//                        default 8 — raise it while testing ten products
//
// Writing without a key: a request that cannot be answered by the model is
// still answered. `composeFallback` builds the page out of what the seller
// typed, in the same shape and within the same length rule, and says so in the
// reply (`model: "duggu-composed"`, `fallback: true`). That is the difference
// between a seller who can publish and a seller who saw a red banner.
//
// The reply then says *which* reason it was, in `fallback_reason`: `no_key`,
// `bad_key`, `bad_address`, `bad_request`, `timeout`, `provider_limit`,
// `upstream`, `not_json`, `crashed`. It is one word, and it is the difference
// between "the provider is slow, tap again in a minute" and "the key on the
// server was refused, tapping is a waste of your evening" — which used to be
// the same sentence in this app, and the wrong one for both.
//
// Every call is checked against the seller's own login token, because this is
// the one endpoint in the app that costs money per call.
//
// Deploy:
//   supabase functions deploy generate-product-description
//
// Deployed *with* JWT verification, unlike `send-push`: the caller is always a
// signed-in person, and the Supabase SDK sends that person's token on
// `functions.invoke` without being asked.

type RequestBody = {
  name?: unknown;
  category?: unknown;
  unit?: unknown;
  description?: unknown;
  store?: unknown;
  minWords?: unknown;
  maxWords?: unknown;
};

// ——————————————————————————————————————————————————————————————————————————————
// The pure half: no network, no `Deno`, no environment. Deliberately kept that
// way — the block can be sliced out of this file and run anywhere, which is how
// the length rule below was tested without a Supabase project or an API key.
// ——————————————————————————————————————————————————————————————————————————————

/** The length rule for a Infinity product description, in words. */
const MIN_WORDS = 700;
const MAX_WORDS = 1500;

/** What a caller may ask for, however odd the request is. The app asks with the
 *  rule above; these bounds only stop a hand-made request from turning one
 *  button tap into a 50,000-word bill. */
const MIN_ALLOWED = 150;
const MAX_ALLOWED = 2500;

/** Shortest stub of a line still worth keeping when a text is cut to size. */
const MIN_STUB_WORDS = 12;

/** How many words at the join are compared when two texts meet. */
const MAX_OVERLAP_WORDS = 40;

/** Shortest continuation worth appending; less is the model saying it has no
 *  more to give, and keeping it would only start another pass. */
const MIN_PASS_WORDS = 15;

/** A bullet, as the plain-text field shows it. */
const BULLET = '\u2022 ';

const clamp = (value: number, low: number, high: number): number =>
  value < low ? low : (value > high ? high : value);

/** The words of a text. */
function wordList(text: string): string[] {
  const trimmed = text.trim();
  return trimmed ? trimmed.split(/\s+/) : [];
}

/**
 * Words, counted the way `ProductDescriptionAi.countWords` counts them in the
 * app — the number the seller sees under the box and the number checked here
 * are the same number, on purpose.
 */
function countWords(text: string): number {
  return wordList(text).length;
}

/** Text reduced to what it says: no markdown, no case, no punctuation noise, so
 *  two texts can be compared with each other. */
function signature(text: string): string {
  return wordList(text)
    .join(' ')
    .toLowerCase()
    .replace(/\bhttps?:\/\/\S+/g, ' url ')
    .replace(/[^a-z0-9\u0900-\u097F ]+/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * How many of the first words of `after` are already the last words of
 * `before`. A model asked to continue very often repeats the sentence it
 * stopped on, and a paragraph that says a thing twice is what the seller would
 * then have to delete by hand.
 */
function repeatedHead(before: string, after: string): number {
  const old = wordList(before);
  const fresh = wordList(after);
  const room = Math.min(old.length, fresh.length, MAX_OVERLAP_WORDS);
  for (let size = room; size >= 6; size--) {
    if (
      signature(old.slice(old.length - size).join(' ')) ===
        signature(fresh.slice(0, size).join(' '))
    ) {
      return size;
    }
  }
  return 0;
}

/** Drop `count` words from the front, whole lines first — so the shape of what
 *  is left survives the cut. */
function dropWords(text: string, count: number): string {
  let left = count;
  const out: string[] = [];
  for (const line of text.split('\n')) {
    if (left <= 0) {
      out.push(line);
      continue;
    }
    const words = wordList(line);
    if (words.length <= left) {
      left -= words.length;
      continue;
    }
    out.push(words.slice(left).join(' '));
    left = 0;
  }
  return out.join('\n').trim();
}

/** What a continuation pass adds to what is already written, repeat taken out
 *  — or nothing at all, when the pass turned out to repeat the page. */
function appendPass(before: string, after: string): string {
  const skip = repeatedHead(before, after);
  const kept = skip > 0 ? dropWords(after, skip) : after.trim();
  return countWords(kept) >= MIN_PASS_WORDS ? kept : '';
}

/**
 * At most `maxWords` of `text`, cut where it hurts least: whole lines while
 * they fit, a line's worth of words when they do not, and then back up to the
 * last sentence end — but never below `minWords`, because half a thought at the
 * end of a product page reads as a broken app.
 */
function capWords(text: string, maxWords: number, minWords: number): string {
  // Inside the rule already: the text is handed over as it was written, and
  // this function only ever re-shapes a page that is too long for the box.
  if (countWords(text) <= maxWords) return text.trim();
  const kept: string[] = [];
  let used = 0;
  for (const raw of text.trim().split(/\n+/)) {
    const line = raw.trim();
    if (!line) continue;
    const size = countWords(line);
    if (used + size <= maxWords) {
      kept.push(line);
      used += size;
      continue;
    }
    const room = maxWords - used;
    if (room >= MIN_STUB_WORDS) {
      kept.push(wordList(line).slice(0, room).join(' '));
    }
    break;
  }
  let out = kept.join('\n\n');
  const tail = out.slice(-600);
  const stops = [...tail.matchAll(/[.!?\u0964](?=["')\]]?\s|$)/g)];
  const last = stops.length > 0 ? stops[stops.length - 1] : null;
  if (last !== null && last.index !== undefined) {
    const cut = out.length - tail.length + last.index + 1;
    const shorter = out.slice(0, cut).trim();
    if (countWords(shorter) >= minWords) out = shorter;
  }
  return out;
}

/**
 * Models write markdown unless told otherwise, and this text lands in a plain
 * box: a `**bold**` would be printed with its asterisks on the product page. So
 * markdown is taken out here rather than trusted to the prompt — headings
 * become their own line, bullets become the app's bullet, and the "Sure! Here
 * is a description…" manners at either end are dropped.
 */
function toPlainText(text: string): string {
  let out = text
    .replace(/```[a-zA-Z]*\n?/g, '')
    // A link is kept as its words and loses the address: the box has no
    // links, and a URL in a product description is a way for a model to
    // send a buyer somewhere the seller never meant.
    .replace(/\[([^\]]+)\]\((?:https?:)?\/\/[^)\s]*\)/g, '$1')
    .replace(/\b(?:https?:\/\/|www\.)\S+/gi, '')
    .replace(/ {2,}/g, ' ')
    .replace(/^\s{0,3}#{1,6}\s*(.+?)\s*:?\s*$/gm, (_m, head: string) => {
      const h = head.replace(/[*_`]/g, '').trim();
      return h.endsWith(':') ? h : `${h}:`;
    })
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/__([^_]+)__/g, '$1')
    .replace(/(^|[\s(])\*([^*\n]+)\*/g, '$1$2')
    .replace(/(^|[\s(])_([^_\n]+)_/g, '$1$2')
    .replace(/`([^`\n]+)`/g, '$1')
    .replace(/^\s*[-*\u2013\u2022]\s+/gm, BULLET)
    .replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/gu, '')
    .replace(/[ \t]+$/gm, '');

  const lines = out.split('\n');
  // A preamble or a sign-off, if the model added one anyway.
  while (
    lines.length > 2 &&
    /^(sure|certainly|of course|here'?s|here is|below i?s)/i.test(lines[0].trim())
  ) {
    lines.shift();
  }
  while (
    lines.length > 2 &&
    /^(let me know|let us know|hope this|hope you|would you like|want me to|need anything)/i
      .test(lines[lines.length - 1].trim())
  ) {
    lines.pop();
  }
  out = lines
    .filter((line) => !/^\s*(===+|(---+|___+|=+)\s*)$/.test(line))
    .join('\n');
  return out.replace(/\n{3,}/g, '\n\n').trim();
}

/**
 * Take apart what the writer sent. The `===DESCRIPTION===` /
 * `===HIGHLIGHTS===` frame it is asked to keep is optional on the way in: an
 * answer from an older prompt, or one that forgot the frame halfway, still has
 * to come back as a description and not as a page with `===` in it.
 */
function parseDraft(text: string): { description: string; highlights: string[] } {
  const marks = /={2,}\s*DESCRIPTION\s*={2,}/i;
  const hl = /={2,}\s*(?:HIGHLIGHTS|FEATURES)\s*={2,}/i;
  let body = text;
  let tail = '';
  const at = body.search(hl);
  if (at >= 0) {
    tail = body.slice(at).replace(hl, '');
    body = body.slice(0, at);
  }
  body = body.replace(marks, '');
  if (tail === '') {
    // Unframed: the highlights, if any, stand under a line that only says so.
    const loose = /\n[ \t]*highlights?[ \t]*:?[ \t]*\n/i.exec(body);
    if (loose !== null && loose.index >= 0) {
      tail = body.slice(loose.index + loose[0].lastIndexOf('\n') + 1);
      body = body.slice(0, loose.index);
    }
  }
  const highlights = tail
    .split('\n')
    .map((line) => line.replace(/^\s*(?:[-*\u2022]|\d+[.)])\s*/, '').trim())
    .filter((line) => line.length > 2);
  return { description: toPlainText(body), highlights };
}

/** Six to eight short lines for the product page's Highlights, no more, no
 *  duplicate, none that is a whole sentence. */
function cleanHighlights(list: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const item of list) {
    const text = toPlainText(item)
      .replace(/^[•-]\s*/, '')
      .replace(/\s*\n\s*/g, ' ')
      .replace(/\s{2,}/g, ' ')
      .trim();
    if (text.length < 3) continue;
    const key = signature(text);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    out.push(text.length > 70 ? `${text.slice(0, 69).trimEnd()}\u2026` : text);
    if (out.length === 8) break;
  }
  return out;
}

/** What the seller typed, fitted to what one request can carry. */
function clip(value: unknown, max: number): string {
  const text = typeof value === 'string' ? value.trim() : '';
  return text.length > max ? text.slice(0, max) : text;
}

/** The word range to write for, inside what this file will write at all. */
function wordRange(min: number, max: number): { minWords: number; maxWords: number } {
  const minWords = clamp(min, MIN_ALLOWED, MAX_ALLOWED);
  const maxWords = clamp(Math.max(max, minWords), minWords, Math.max(MAX_ALLOWED, minWords));
  return { minWords, maxWords };
}

/** The token budget for one answer: the word target plus a fifth, because a
 *  model counting to 1500 needs room to overshoot before this file cuts it
 *  back. ~1.6 tokens per word of Indian-English prose, and the estimate is
 *  generous on purpose. */
function tokensFor(target: number): number {
  return Math.round(target * 1.6) + 300;
}

/** How much of the budget one continuation may use. */
function tokensLeft(target: number, written: number): number {
  return clamp(Math.round((target - written) * 1.8) + 120, 320, tokensFor(target));
}

type Config = {
  apiKey: string;
  baseUrl: string;
  model: string;
  temperature: number;
  requestTimeoutMs: number;
  budgetMs: number;
  maxPasses: number;
  maxTokens: number;
};

type Draft = {
  description: string;
  highlights: string[];
  wordCount: number;
  minWords: number;
  maxWords: number;
  inRange: boolean;
  shortBy: number;
  passes: number;
  outOfTime?: boolean;
  model: string;
};

/** The house style, so that every seller's page reads alike and no model
 *  decides for itself that a description is a poem or a sales letter. */
const SYSTEM_PROMPT = `You write product descriptions for Infinity, an Indian online
marketplace. The reader is a first-time buyer in a small city, on a phone, often on a slow
connection, and the seller's page has to carry the whole sale on its own words.

LENGTH IS THE RULE, not a suggestion: between {{MIN}} and {{MAX}} words. Count as you go and keep
writing until the target is there. An answer under {{MIN}} words is a failed answer.

SHAPE
- Plain text only. No markdown, no asterisks, no # signs, no tables, no links, no emoji.
- One section title per line, ending with a colon. Bullets as a dot and a space.
- One blank line between sections. No preamble and no sign-off: the first word is the first title.
- The sections, in this order, about this long:
  What this product is ({{S1}} words)
  Why you will like it ({{S2}} words, as bullets)
  Specifications and pack details ({{S3}} words, as bullets)
  How to use it ({{S4}} words)
  Storage and care ({{S5}} words)
  Good to know ({{S6}} words)
  Frequently asked questions ({{S7}} words: four questions, two sentences in each answer)
  About the seller ({{S8}} words, last)
- Then 6 to 8 highlights of 2 to 8 words each, for the Highlights strip.

HONESTY IS THE OTHER RULE
- Only what the seller gave you, plus what is simply true of this kind of product.
- Never invent a price, a discount, a warranty, an expiry date, a certification (FSSAI, BIS, ISI,
  AGMARK, organic), a percentage, a test result, a number sold, a review or a rating.
- No "100% genuine", no medical or cure claims, no promises about delivery, refund, COD or
  exchange.
- Where the seller gave nothing for a detail, write what is normal for the category and say that
  the pack and the label are the final word on it.
- Short words, complete sentences, no more than two or three superlatives in a page.
- Write in the language the seller wrote in, English if they wrote nothing. Indian English, metric
  units. Never a placeholder, never [your text here], never lorem ipsum.`;

function fill(template: string, values: Record<string, string>): string {
  let out = template;
  for (const key of Object.keys(values)) {
    out = out.split(`{{${key}}}`).join(values[key]);
  }
  return out;
}

/** The length of each section, scaled to the range asked for. "About 1100
 *  words" is nothing a model can feel; eight parts of 140 words can be written
 *  one after another, and that is how the floor gets reached in one pass. */
function sectionBudgets(minWords: number, maxWords: number): Record<string, string> {
  const mid = (minWords + maxWords) / 2;
  const share = (part: number): string => String(Math.round((mid * part) / 100));
  return {
    S1: share(14),
    S2: share(18),
    S3: share(15),
    S4: share(13),
    S5: share(10),
    S6: share(11),
    S7: share(13),
    S8: share(6),
  };
}

/** The brief for one page, built from the four boxes of the seller's form. */
function sellerBrief(input: Record<string, string>, minWords: number, maxWords: number): string {
  const notes = input.description;
  return [
    `Product name: ${input.name}`,
    input.category === '' ? '' : `Category: ${input.category}`,
    input.unit === '' ? '' : `Sold as: ${input.unit}`,
    input.store === '' ? '' : `Seller's store: ${input.store}`,
    notes === ''
      ? 'The seller has written nothing yet. Write the whole page from the name and the ' +
        'category, and keep every sentence true of any product of this kind.'
      : `The seller's own notes: use them, keep what is in them, build the page around them, ` +
        `and do not contradict a number they wrote.\n${notes}`,
    `Write between ${minWords} and ${maxWords} words. Aim for ${
      Math.round((minWords + maxWords) / 2)
    }.`,
    'Format exactly:\n===DESCRIPTION===\n<the description>\n===HIGHLIGHTS===\n<highlight per line>',
  ].filter((line) => line !== '').join('\n');
}

/** The brief for a pass that only follows on, from where the last one stopped. */
function continuationBrief(
  name: string,
  soFar: number,
  minWords: number,
  maxWords: number,
): string {
  const need = clamp(minWords - soFar + 120, 150, maxWords - soFar + 60);
  return [
    `Your description of "${name}" stopped at ${soFar} words. The floor is ${minWords}.`,
    `Continue it from exactly where it stopped, with about ${need} more words, in the same`,
    'voice and the same format.',
    'Do not repeat a sentence that is already there, do not open a section that is',
    `already written, and do not wrap up with a summary while ${
      Math.max(0, minWords - soFar)
    } words are still missing.`,
    'Answer with the new words only.',
    'Answer with the new words only.',
  ].join('\n');
}

// ——————————————————————————————————————————————————————————————————————————————
// The half that touches the outside world: the environment, the seller's login,
// the rate limit, the AI provider.
// ——————————————————————————————————————————————————————————————————————————————

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'content-type': 'application/json' },
  });
}

function firstText(...values: (string | undefined)[]): string {
  for (const value of values) {
    const trimmed = (value ?? '').trim();
    if (trimmed !== '') return trimmed;
  }
  return '';
}

function envInt(value: string | undefined, fallback: number): number {
  const n = Number.parseInt((value ?? '').trim(), 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

/** Where a GROQ_API_KEY points by default. The model has to be one the key
 *  can reach: this project's key lists openai/gpt-oss-120b and -20b and
 *  qwen/qwen3.8-27b, and no Llama (llama-3.3-70b-versatile answered 404 on
 *  every call). gpt-oss is a reasoning model, which is what left the old
 *  dashboard copy with empty answers — see [reasoningExtras]. */
const GROQ = {
  baseUrl: 'https://api.groq.com/openai/v1',
  model: 'openai/gpt-oss-120b',
};

/** Tokens a reasoning model may spend thinking before it writes. */
const REASONING_ALLOWANCE = 1200;

/** Whether [model] thinks before it answers. Its thinking counts against
 *  max_tokens, so a budget sized for the page alone runs out before the
 *  page is written and the answer comes back empty. */
function isReasoningModel(model: string): boolean {
  return /(^|\/)(gpt-oss|o\d|qwen3|deepseek-r1)/i.test(model);
}

/** For a reasoning model: think briefly, keep the thinking out of the
 *  answer, and leave room for it on top of the page's own budget. */
function reasoningExtras(model: string, maxTokens: number): Record<string, unknown> {
  if (!isReasoningModel(model)) return { max_tokens: maxTokens };
  const extras: Record<string, unknown> = {
    max_tokens: maxTokens + REASONING_ALLOWANCE,
  };
  if (/gpt-oss/i.test(model)) {
    extras.reasoning_effort = 'low';
    extras.include_reasoning = false;
  } else if (/qwen3/i.test(model)) {
    extras.reasoning_format = 'hidden';
  }
  return extras;
}

/** The provider, from the environment. `null` when there is no key, which is a
 *  normal state for a project that has not been set up — and is answered with
 *  the composed fallback, not with a failure the seller cannot act on. */
function config(): Config | null {
  const env = Deno.env;
  const get = (key: string): string => (env.get(key) ?? '').trim();
  const generic = firstText(get('AI_API_KEY'), get('OPENAI_API_KEY'));
  // The project already keeps a Groq key under its own name (the dashboard
  // copy of this function read it), so that key is enough on its own.
  const groq = generic === '' ? get('GROQ_API_KEY') : '';
  const apiKey = firstText(generic, groq);
  if (apiKey === '') return null;
  const temperature = Number.parseFloat(firstText(get('AI_TEMPERATURE'), '0.7'));
  const maxWords = wordRange(MIN_WORDS, MAX_WORDS).maxWords;
  return {
    apiKey,
    baseUrl: firstText(
      get('AI_BASE_URL'),
      get('OPENAI_BASE_URL'),
      groq !== '' ? GROQ.baseUrl : 'https://api.openai.com/v1',
    ).replace(/\/+$/, ''),
    model: firstText(
      get('AI_MODEL'),
      get('OPENAI_MODEL'),
      groq !== '' ? GROQ.model : 'gpt-4o-mini',
    ),
    temperature: Number.isFinite(temperature) ? clamp(temperature, 0, 2) : 0.7,
    requestTimeoutMs: clamp(envInt(get('AI_REQUEST_TIMEOUT_MS'), 90000), 5000, 180000),
    budgetMs: clamp(envInt(get('AI_BUDGET_MS'), 120000), 10000, 240000),
    maxPasses: clamp(envInt(get('AI_MAX_PASSES'), 3), 1, 5),
    maxTokens: envInt(get('AI_MAX_TOKENS'), tokensFor(maxWords)),
  };
}

type ChatMessage = { role: string; content: string };

class UpstreamError extends Error {
  code: string;
  status: number;
  /** One word for what went wrong out there, and the only thing the app needs
   *  to say it: the page composed without a model is labelled with this, so
   *  "no key", "your key was refused" and "the service is down" are three
   *  different sentences instead of one shrug. They are fixed by different
   *  people on different days, which is the whole reason it travels. */
  reason: string;

  constructor(
    message: string,
    code: string,
    status = 502,
    reason = 'upstream',
  ) {
    super(message);
    this.code = code;
    this.status = status;
    this.reason = reason;
  }
}

/** The four things a caller needs about a provider answer, before anything is
 *  thrown: what to log, what to map, what status to answer with, and the one
 *  word that goes to the app. */
type Refusal = {
  error: string;
  code: string;
  status: number;
  reason: string;
};

/** The host of `AI_BASE_URL`, for one readable line. A base url that is not an
 *  address at all comes back empty, and that is the answer, not a detail. */
function hostOf(url: string): string {
  try {
    return new URL(url).host;
  } catch {
    return '';
  }
}

/** The provider's own words about a failure, clipped, with anything shaped like
 *  a key taken out before it reaches a log line that more people can read than
 *  the one who set the secret. */
function providerDetail(raw: string): string {
  let text = '';
  try {
    const body = JSON.parse(raw) as {
      error?: { message?: string; type?: string };
      message?: string;
    };
    text = firstText(body?.error?.message, body?.message, body?.error?.type);
  } catch {
    // The body was not json at all, which some gateways do: its first words
    // are still better than nothing in the log.
  }
  if (text === '') text = raw;
  text = text.replace(/\s+/g, ' ').replace(/sk-[A-Za-z0-9_-]{6,}/g, 'sk-…');
  return clip(text, 110);
}

/** What an http answer from the provider means. The distinction is invisible
 *  from a phone and decides everything: a request that will be refused *every*
 *  time (wrong key, wrong address, a body the provider dislikes) is not the
 *  same emergency as a pause (429, 5xx, a slow call), and only the second one
 *  is worth the words "try again in a minute". A seller told to retry a refused
 *  key retries forever, and it is the server that is wrong. */
function upstreamRefusal(
  status: number,
  host: string,
  detail: string,
): Refusal {
  const where = host === '' ? '' : ` at ${host}`;
  const at = `${where}${detail === '' ? '' : `: ${detail}`}`;
  if (status === 401 || status === 403) {
    return {
      error: `the AI key was refused${at}`,
      code: 'AI_BAD_KEY',
      status: 500,
      reason: 'bad_key',
    };
  }
  if (status === 429) {
    return {
      error: `the AI provider is throttling this key${at}`,
      code: 'AI_PROVIDER_LIMIT',
      status: 429,
      reason: 'provider_limit',
    };
  }
  if (status === 404) {
    // The model name or the address is wrong, and both are one setting away.
    return {
      error: `the AI model was not found${at}` +
        ' — check AI_MODEL and AI_BASE_URL',
      code: 'AI_BAD_ADDRESS',
      status: 500,
      reason: 'bad_address',
    };
  }
  if (status >= 500) {
    return {
      error: `the AI provider is not answering${at}`,
      code: 'AI_UPSTREAM',
      status: 502,
      reason: 'upstream',
    };
  }
  return {
    error: `the AI provider refused the request${at}`,
    code: 'AI_BAD_REQUEST',
    status: 500,
    reason: 'bad_request',
  };
}

/**
 * One call to the provider. A 429 or a 5xx is tried once more after a moment;
 * a 401 or a 400 is not, because nothing this function could do the second
 * time would change the answer.
 */
async function complete(
  cfg: Config,
  messages: ChatMessage[],
  maxTokens: number,
  timeoutMs: number,
): Promise<string | null> {
  const url = `${cfg.baseUrl}/chat/completions`;
  const host = hostOf(cfg.baseUrl);
  if (host === '') {
    // Retried once like everything else, which is how a typo in a setting
    // comes back as "the service is slow". It is not slow, and it will not
    // change on the next tap: it is not an address.
    throw new UpstreamError(
      `AI_BASE_URL is not an address (${clip(cfg.baseUrl, 40)})`,
      'AI_BAD_ADDRESS',
      500,
      'bad_address',
    );
  }
  let stuck: Refusal | null = null;
  for (let attempt = 0; attempt < 2; attempt++) {
    if (attempt > 0) await new Promise((done) => setTimeout(done, 1200));
    let res: Response;
    try {
      res = await fetch(url, {
        method: 'POST',
        headers: {
          authorization: `Bearer ${cfg.apiKey}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          model: cfg.model,
          messages,
          temperature: cfg.temperature,
          ...reasoningExtras(cfg.model, maxTokens),
        }),
        signal: AbortSignal.timeout(Math.max(1000, timeoutMs)),
      });
    } catch (e) {
      // Nothing came back at all. A slow answer is worth one more try; a
      // connection that never opened is the address, and the address is not
      // going to have moved by the time the seller taps again.
      stuck = e instanceof Error && e.name === 'TimeoutError'
        ? {
          error: `the AI provider took too long to answer at ${host}`,
          code: 'AI_TIMEOUT',
          status: 504,
          reason: 'timeout',
        }
        : {
          error: `the AI provider could not be reached at ${host}`,
          code: 'AI_BAD_ADDRESS',
          status: 500,
          reason: 'bad_address',
        };
      continue;
    }
    const raw = await res.text();
    if (!res.ok) {
      const refusal = upstreamRefusal(res.status, host, providerDetail(raw));
      // Only a provider that is busy gets a second call, because that is the
      // one thing that can change between two calls. A refused key, a model
      // that does not exist, a body it dislikes: said now, not retried.
      const canWaitItOut = refusal.code === 'AI_PROVIDER_LIMIT' ||
        refusal.code === 'AI_UPSTREAM';
      if (!canWaitItOut) {
        throw new UpstreamError(
          refusal.error,
          refusal.code,
          refusal.status,
          refusal.reason,
        );
      }
      stuck = refusal;
      continue;
    }
    let content: unknown;
    try {
      content = JSON.parse(raw)?.choices?.[0]?.message?.content;
    } catch {
      throw new UpstreamError(
        `the AI provider at ${host} answered with something not JSON`,
        'AI_UPSTREAM',
        502,
        'not_json',
      );
    }
    const answer = typeof content === 'string'
      ? content
      : Array.isArray(content)
      ? content.map((part: { text?: string }) => part?.text ?? '').join('')
      : '';
    // An empty answer is worth one more try: a model that stopped before the
    // first word is usually the provider, not the request.
    return answer.trim() === '' ? null : answer.trim();
  }
  const last = stuck ?? {
    error: `the AI provider at ${host} answered without a body`,
    code: 'AI_UPSTREAM',
    status: 502,
    reason: 'upstream',
  };
  throw new UpstreamError(last.error, last.code, last.status, last.reason);
}

/**
 * The length rule, applied. Ask for the page; while it is short of the floor,
 * ask for the rest of it; cut it back when it is over the ceiling. The draft
 * says honestly how it ended (`in_range`, `short_by`) rather than failing a
 * 620-word page that is already worth reading: the seller's button then says
 * "tap again to extend", and the next request continues from what is in the
 * box, because the box's own text is the brief.
 */
async function writeWithinRange(
  cfg: Config,
  input: Record<string, string>,
  minWords: number,
  maxWords: number,
  startedAt: number,
): Promise<Draft> {
  const system = fill(SYSTEM_PROMPT, {
    MIN: String(minWords),
    MAX: String(maxWords),
    ...sectionBudgets(minWords, maxWords),
  });
  const messages: ChatMessage[] = [
    { role: 'system', content: system },
    { role: 'user', content: sellerBrief(input, minWords, maxWords) },
  ];

  let body = '';
  let highlights: string[] = [];
  let passes = 0;
  let timedOut = false;
  for (let pass = 0; pass < cfg.maxPasses; pass++) {
    const left = cfg.budgetMs - (Date.now() - startedAt);
    if (pass > 0 && left < 4000) {
      // Out of time, not out of words: what is written so far goes back, and
      // `in_range: false` tells the app the page wants one more tap.
      timedOut = true;
      break;
    }
    const written = countWords(body);
    const budget = pass === 0 ? cfg.maxTokens : tokensLeft(maxWords, written);
    let answer: string | null;
    try {
      answer = await complete(
        cfg,
        messages,
        budget,
        Math.min(cfg.requestTimeoutMs, left),
      );
    } catch (e) {
      // A first pass that failed has nothing to keep, and the caller then
      // composes the page. A later pass that failed leaves a real page half
      // written by the model, which is worth more than starting over — so it
      // goes back short, and `in_range: false` says so.
      if (pass === 0 || countWords(body) < MIN_ALLOWED) throw e;
      console.error(
        'generate-product-description: a pass failed, keeping what is written:',
        e,
      );
      break;
    }
    if (answer === null) break;
    passes += 1;
    const draft = parseDraft(answer);
    if (pass === 0) {
      body = draft.description;
      highlights = draft.highlights;
    } else {
      const added = appendPass(body, draft.description);
      if (added !== '') {
        body = `${body}\n\n${added}`;
        if (highlights.length === 0) highlights = draft.highlights;
      }
    }
    messages.push({ role: 'assistant', content: answer });
    if (countWords(body) >= minWords) break;
    if (pass + 1 < cfg.maxPasses) {
      messages.push({
        role: 'user',
        content: continuationBrief(
          input.name,
          countWords(body),
          minWords,
          maxWords,
        ),
      });
    }
  }

  const description = capWords(toPlainText(body), maxWords, minWords);
  const wordCount = countWords(description);
  return {
    description,
    highlights: cleanHighlights(highlights),
    wordCount,
    minWords,
    maxWords,
    inRange: wordCount >= minWords && wordCount <= maxWords,
    shortBy: Math.max(0, minWords - wordCount),
    passes,
    outOfTime: timedOut,
    model: cfg.model,
  };
}

/**
 * What the page looks like when no model answered — no key set, the provider
 * down, the request refused. The seller's own words are put in the same shape
 * as the AI's answer, in the same length rule, so the listing can still be
 * published and the seller is not sent to wait for somebody to fix a secret.
 * It writes nothing the seller did not say, and the reply is marked
 * `fallback: true` so the app can label it and the log can count it.
 */
function composeFallback(input: Record<string, string>, minWords: number): Draft {
  const notes = input.description
    .split(/[\n;]+/)
    .map((line) => line.replace(/^[•*\-]\s*/, '').replace(/^\d+[.)]\s*/, '').trim())
    .filter((line) => line.length > 2);
  const facts = notes.length > 0 ? notes : [input.name];
  const seller = input.store === '' ? 'The store' : input.store;
  const category = input.category === '' ? 'this category' : input.category;
  const unit = input.unit === '' ? 'as listed' : input.unit;

  const section = (title: string, lines: string[]): string =>
    `${title}:\n${
      lines.filter((line) => line !== '').map((line) => `${BULLET}${line}`).join('\n')
    }`;
  const prose = (title: string, ...parts: string[]): string =>
    `${title}:\n${parts.filter((p) => p !== '').join(' ')}`;

  const parts: string[] = [];

  parts.push(
    prose(
      'What this product is',
      `${input.name} is listed on Infinity` +
        `${input.category === '' ? '' : ` under ${input.category}`}` +
        `${input.unit === '' ? '' : ` and sold as ${input.unit}`}.`,
      ...(facts[0].toLowerCase() === input.name.toLowerCase() ? [] : [`${facts[0]}`]),
      'This page is written from what the store published about the item, so that a buyer can ' +
        'decide without having to ask first. Where a detail matters — the size on the pack, the ' +
        'grade, the date printed on the label — the pack and the label are the final word, and ' +
        'the store is happy to confirm either before the order is placed.',
    ),
  );

  parts.push(
    section('Why you will like it', [
      ...facts.slice(0, 5),
      input.unit === '' ? '' : `Sold as ${input.unit}`,
      'Listed by a store that answers its buyers on Infinity',
      'Packed for shipping once the order is accepted',
      'The photos and the details on this page are the store\'s own',
      'Ask the store about size, grade or fit before ordering, not after',
    ].filter((line) => line !== '').slice(0, 8)),
  );

  parts.push(
    section('Specifications and pack details', [
      `Item: ${input.name}`,
      `Category: ${category}`,
      `Sold as: ${unit}`,
      'Quantity or pack size: as shown on the product page',
      'Variant, size or grade: the one selected at checkout, where the listing offers any',
      'Net quantity, batch and date: as printed on the pack',
      'Model or article number: as printed on the pack or listed by the store',
      'Country of origin: as printed on the label',
    ]),
  );

  parts.push(
    prose(
      'How to use it',
      'Read the label and any card inside the pack before the item is first used, and use it for ' +
        'the purpose it is made for, in the quantity the pack suggests.',
      'Where a product of this kind has to be assembled, installed, cooked, measured or fitted, ' +
        'follow the instructions in the box and the store\'s other photos first — most returns on ' +
        'items like this one turn out to be a usage question rather than a fault.',
      'Anything the pack does not answer is worth asking the store before ordering, not after: ' +
        'the store page on Infinity lists its other products and how to reach it.',
    ),
  );

  parts.push(
    prose(
      'Storage and care',
      'Keep the item in its own pack, in a cool dry place, away from direct sun and damp, until it ' +
        'is needed.',
      'Wrappers, small parts and any silica gel should be kept out of reach of children and pets, ' +
        'and thrown away once the item is out of the box.',
      'Clean and maintain the product the way the card inside the pack says, and keep that card ' +
        'with the bill — a service centre asks for it first.',
      'Food and consumable items should be checked against the printed date the day they arrive, ' +
        'and sealed again after every use.',
    ),
  );

  parts.push(
    prose(
      'Good to know',
      'The photos on this page are of the item the store keeps in stock. A small difference in ' +
        'shade, print or finish between units of the same product is normal for goods made this ' +
        'way, and is not a fault.',
      'Where a product comes in sizes, grades or variants, the one that is sent is the one ' +
        'selected at checkout, so it is worth reading the name on the order once before paying.',
      'Stock on the page is the store\'s own count and can move during a busy day. An order is ' +
        'confirmed when the seller accepts it, and Infinity tells the buyer either way.',
      'This page was written from the store\'s listing. A buyer who needs certainty about a ' +
        'specific number — a weight, a size, a date — should ask the store rather than read past ' +
        'it.',
    ),
  );

  parts.push(
    prose(
      'Frequently asked questions',
      'Is this the exact item in the photo? The listing photo is of the product the store packs. ' +
        'What is in the box is listed above, and the label on the pack is the final word if the ' +
        'two ever differ.',
      'What if the item arrives damaged? Tell the store from the order, with a photo of the pack ' +
        'as it arrived, inside the return window Infinity allows. A damaged item is settled through ' +
        'the return flow.',
      'Can I return it if I change my mind? Return terms are the store\'s policy and Infinity\'s, as ' +
        'shown on the order page at the time of buying. Read that policy before ordering ' +
        'customised, perishable or sealed goods, where returns are narrower.',
      'When will it be dispatched? The store packs the order once it is accepted. The order page ' +
        'shows the status, and a notification arrives when the parcel leaves the store.',
    ),
  );

  parts.push(
    prose(
      'About the seller',
      `${seller} lists this product on Infinity and answers the questions buyers ask before ` +
        'ordering.',
      'The store\'s other products, its rating and how long it has been selling are on its Infinity ' +
        'store page.',
      'Asking about size, grade, compatibility or the date printed on the pack before buying is ' +
        'usually quicker than reading a long page, and the answer usually comes the same day.',
    ),
  );

  // The Highlights strip wants short lines, so the same facts are clipped
  // here rather than pasted in whole.
  const shortLines = [
    ...facts.slice(0, 4),
    input.unit,
    'Sold by a store that answers its buyers',
    'Packed once the order is accepted',
  ].filter((line) => line !== '');

  const description = capWords(toPlainText(parts.join('\n\n')), MAX_WORDS, minWords);
  const wordCount = countWords(description);
  return {
    description,
    highlights: cleanHighlights(shortLines),
    wordCount,
    minWords,
    maxWords: MAX_WORDS,
    inRange: wordCount >= minWords && wordCount <= MAX_WORDS,
    shortBy: Math.max(0, minWords - wordCount),
    passes: 0,
    model: 'duggu-composed',
  };
}

/** Per user, in the worker's own memory: a speed bump, not a wall. Edge
 *  Functions run in more than one place, so the real ceiling is the provider's
 *  quota; what this stops is a loop on one device, which is what burns a key. */
const RATE_WINDOW_MS = 10 * 60 * 1000;
const RATE_MAX = 8;
const hits = new Map<string, { count: number; resetAt: number }>();

/** Minutes to wait, or 0 when this user may ask again. The number goes back to
 *  the app with the refusal, because "try again in a minute" is a lie when the
 *  window closes in seven, and a person who is told how long to wait stops
 *  tapping and comes back instead. */
function rateWindow(userId: string, now: number, max: number): number {
  if (userId === 'anonymous') return 0;
  const slot = hits.get(userId);
  if (!slot || slot.resetAt <= now) {
    hits.set(userId, { count: 1, resetAt: now + RATE_WINDOW_MS });
    if (hits.size > 5000) hits.clear();
    return 0;
  }
  slot.count += 1;
  if (slot.count <= max) return 0;
  return Math.max(1, Math.ceil((slot.resetAt - now) / 60000));
}

/** A refusal, said twice: once to the app as json, once to the log with who
 *  asked and how long it took. The dashboard's log is where a "why is the AI
 *  not working" question gets answered, and it can only do that if the
 *  refusals are written down too, not just the successes. */
function refuse(
  user: string,
  startedAt: number,
  body: Record<string, string | number>,
  status: number,
): Response {
  console.log(JSON.stringify({
    event: 'ai_refused',
    user,
    status,
    code: body.code ?? '',
    ms: Date.now() - startedAt,
  }));
  return json(body, status);
}

/**
 * Who is asking. `functions.invoke` carries the signed-in user's own JWT, and
 * it is checked with GoTrue before anything is paid for: this is the only
 * endpoint in the app that costs money per call, and a writer open to the
 * internet is a writer somebody else will use.
 */
async function authUser(req: Request): Promise<string | null> {
  const bearer = req.headers.get('authorization') ?? '';
  const token = bearer.replace(/^Bearer\s+/i, '').trim();
  const url = (Deno.env.get('SUPABASE_URL') ?? '').trim();
  if (token === '' || url === '') return null;
  const key = firstText(
    Deno.env.get('SUPABASE_ANON_KEY'),
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
  );
  if (key === '') return null;
  try {
    const res = await fetch(`${url}/auth/v1/user`, {
      headers: { authorization: `Bearer ${token}`, apikey: key },
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return null;
    const id = (await res.json())?.id;
    return typeof id === 'string' && id !== '' ? id : null;
  } catch (e) {
    // The seller looks signed in from where they are standing, and this is the
    // one answer that tells them to sign in again, so the reason it says that
    // gets written down rather than left as a mystery.
    console.error('generate-product-description: the login check failed:', e);
    return null;
  }
}

function fields(body: RequestBody): Record<string, string> {
  return {
    name: clip(body.name, 200),
    category: clip(body.category, 120),
    unit: clip(body.unit, 60),
    description: clip(body.description, 6000),
    store: clip(body.store, 120),
  };
}

async function respond(req: Request): Promise<Response> {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') {
    return json({ error: 'POST only', code: 'BAD_METHOD' }, 405);
  }

  const startedAt = Date.now();
  const size = Number.parseInt(req.headers.get('content-length') ?? '0', 10);
  if (size > 40000) {
    return json({ error: 'this request is too large', code: 'TOO_LARGE' }, 413);
  }

  const user = await authUser(req);
  if (user === null) {
    return refuse('none', startedAt, {
      error: 'sign in first: the AI writer answers a signed-in seller only',
      code: 'AI_AUTH',
    }, 401);
  }
  const rateMax = clamp(envInt(Deno.env.get('AI_RATE_MAX'), RATE_MAX), 1, 100);
  const waitMinutes = rateWindow(user, Date.now(), rateMax);
  if (waitMinutes > 0) {
    return refuse(user, startedAt, {
      error: `the writer allows ${rateMax} descriptions in ten minutes — ` +
        `try again in about ${waitMinutes} ` +
        `${waitMinutes === 1 ? 'minute' : 'minutes'}`,
      code: 'AI_RATE_LIMIT',
      retry_after_minutes: waitMinutes,
    }, 429);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'send a json body', code: 'BAD_JSON' }, 400);
  }
  const input = fields(body);
  if (input.name === '') {
    return json(
      { error: 'a product name is needed to write from', code: 'AI_NO_NAME' },
      400,
    );
  }
  const range = wordRange(
    envInt(String(body.minWords ?? ''), MIN_WORDS),
    envInt(String(body.maxWords ?? ''), MAX_WORDS),
  );

  const cfg = config();
  let draft: Draft;
  let fallback = false;
  let why = 'no_key';
  if (cfg === null) {
    fallback = true;
    draft = composeFallback(input, range.minWords);
  } else {
    try {
      draft = await writeWithinRange(cfg, input, range.minWords, range.maxWords, startedAt);
      why = '';
    } catch (e) {
      // The seller keeps a page either way — that policy is what the whole
      // feature is built on, and it is why a bad provider day is a labelled
      // fallback and not a red banner. What changed is that the reply now says
      // *which* day it was: the page the seller reads is the same shape, and
      // the app can tell them whether another tap can help (down, paused, out
      // of time) or whether the server has to be fixed first (key, address).
      why = e instanceof UpstreamError ? e.reason : 'crashed';
      console.error('generate-product-description: the AI failed, composing instead:', e);
      fallback = true;
      draft = composeFallback(input, range.minWords);
    }
  }

  if (draft.description === '' || draft.wordCount < MIN_ALLOWED) {
    // Nothing to hand over. The app keeps the seller's own text in the box
    // rather than writing this failure into it.
    return refuse(user, startedAt, {
      error: 'the AI writer came back with nothing. Try again.',
      code: 'AI_EMPTY',
      // Which nothing: the model answered with no text at all, or the
      // composing had too little of the seller's to stretch. `why` is empty on
      // the success path, so a bare hand-over of it would blame the missing
      // key for a model that simply had nothing to say.
      fallback_reason: fallback ? why : 'empty_answer',
    }, 502);
  }

  console.log(
    JSON.stringify({
      event: 'ai_description',
      user,
      words: draft.wordCount,
      min_words: range.minWords,
      max_words: range.maxWords,
      in_range: draft.inRange,
      passes: draft.passes,
      fallback,
      reason: why,
      model: draft.model,
      ms: Date.now() - startedAt,
    }),
  );

  return json({
    description: draft.description,
    highlights: draft.highlights,
    word_count: draft.wordCount,
    min_words: range.minWords,
    max_words: range.maxWords,
    in_range: draft.inRange,
    short_by: draft.shortBy,
    passes: draft.passes,
    out_of_time: draft.outOfTime === true,
    model: draft.model,
    fallback,
    fallback_reason: fallback ? why : '',
  });
}

// `respond` is wrapped rather than handed to the runtime directly, because a
// throw that escapes becomes an html error page: the app then sees a status
// with no code and no words, which is precisely how this feature used to say
// "the writer is busy" about problems it could have named. Anything that can
// still break comes back as json with a code, and the reason is in the log.
Deno.serve((req) =>
  respond(req).catch((e) => {
    const why = e instanceof Error ? `${e.name}: ${e.message}` : String(e);
    console.error('generate-product-description: the writer broke:', why);
    return json(
      {
        error: `the AI writer broke while answering (${clip(why, 80)})`,
        code: 'AI_INTERNAL',
      },
      500,
    );
  }));

// No `@supabase/supabase-js` here on purpose: this function writes nothing and
// reads only the caller's login, so it is handed no service role key at all.