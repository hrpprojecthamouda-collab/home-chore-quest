// Small catalog of mental-wellbeing facts about keeping a clean home.
// Pip surfaces one of these as a speech bubble on (a) the first quest
// completion of a brand-new game, and (b) the first quest completion at
// each new level. Facts rotate sequentially via factIndexProvider and
// wrap modulo this list's length.
//
// Tone: warm, short, evidence-aligned, light emoji — same voice as the
// chilling-sheet taglines and celebration screen.

class CleanHomeFact {
  final String text;
  const CleanHomeFact(this.text);
}

const kCleanHomeFacts = <CleanHomeFact>[
  CleanHomeFact('A tidy space clears a busy mind. 🧠✨'),
  CleanHomeFact('Making your bed sets a tiny win for the rest of the day. 🛏️'),
  CleanHomeFact('Less clutter, more calm — your brain stops scanning for chaos.'),
  CleanHomeFact('Clean kitchens nudge you toward home-cooked, kinder meals. 🍳'),
  CleanHomeFact('Tidying for 10 minutes can lift your mood like a short walk. 🌿'),
  CleanHomeFact('Fresh sheets = better sleep. Your future self thanks you. 💤'),
  CleanHomeFact('A clean bathroom feels like a tiny spa visit. 🛁'),
  CleanHomeFact('Putting things away beats searching for them later.'),
  CleanHomeFact('Open windows for 5 minutes — fresh air resets the room and you. 🌬️'),
  CleanHomeFact('Small daily chores prevent the big overwhelming pile.'),
  CleanHomeFact('A clear desk helps a clear thought. ✍️'),
  CleanHomeFact('Cleaning is movement — your body counts every minute. 💪'),
  CleanHomeFact('A neat space invites you to host, rest, or just breathe.'),
  CleanHomeFact('Done is better than perfect — Pip is proud either way. 💜'),
  CleanHomeFact('Caring for your space is a quiet form of self-care.'),
  CleanHomeFact('Sunlight + tidy surfaces = instant mood boost. ☀️'),
  CleanHomeFact('Even one drawer organized today is a real win.'),
  CleanHomeFact('A clean home is a soft landing after a long day. 🏡'),
];
