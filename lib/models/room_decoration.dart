// Shared room-decoration data used by both customize_screen and home_screen.

// Coordinates are in the visible 400×440 space (top 60 px of original canvas cropped).
const kRoomSlots = [
  // ── Back wall (posters & frames only) ─────────────────────────
  (id: 'wall_left',    label: 'Left',   category: 'wall',  x: 65.0,  y: 90.0,  big: false),
  (id: 'wall_center',  label: 'Center', category: 'wall',  x: 200.0, y: 190.0, big: false),
  (id: 'wall_right',   label: 'Right',  category: 'wall',  x: 340.0, y: 90.0,  big: false),
  // ── Floor (carpets & plants only) ─────────────────────────────
  (id: 'floor_left',   label: 'Left',   category: 'floor', x: 60.0,  y: 340.0, big: false),
  (id: 'floor_center', label: 'Center', category: 'floor', x: 195.0, y: 360.0, big: true),
  (id: 'floor_right',  label: 'Right',  category: 'floor', x: 300.0, y: 340.0, big: false),
];

const kRoomCatalog = <String, ({String glyph, String name, bool big, String category})>{
  // ── Wall items (posters & frames) ─────────────────────────────
  'print':       (glyph: '🖼️', name: 'Pixel Print',    big: false, category: 'wall'),
  'map':         (glyph: '🗺️', name: 'World Map',      big: false, category: 'wall'),
  'mirror':      (glyph: '🪞', name: 'Vanity Mirror',  big: false, category: 'wall'),
  'clock':       (glyph: '🕰️', name: 'Antique Clock',  big: false, category: 'wall'),
  'poster_sun':  (glyph: '🌅', name: 'Sunrise Poster', big: false, category: 'wall'),
  'poster_star': (glyph: '⭐', name: 'Star Chart',     big: false, category: 'wall'),
  // ── Floor items (carpets & plants) ────────────────────────────
  'rug':     (glyph: '🌌', name: 'Starlight Rug',  big: true,  category: 'floor'),
  'plant':   (glyph: '🪴', name: 'Cozy Plant',     big: false, category: 'floor'),
  'cactus':  (glyph: '🌵', name: 'Desert Cactus',  big: false, category: 'floor'),
  'bamboo':  (glyph: '🎋', name: 'Lucky Bamboo',   big: false, category: 'floor'),
  'fern':    (glyph: '🌿', name: 'Wild Fern',      big: false, category: 'floor'),
  'blossom': (glyph: '🌸', name: 'Blossom Tree',   big: false, category: 'floor'),
};
