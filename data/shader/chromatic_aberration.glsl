extern number aberration_x; // 0.5
extern number aberration_y;
extern number screen_width;
extern number screen_height;

vec4 effect(vec4 color, Image tx, vec2 tc, vec2 pc)
{
  // fake chromatic aberration
  float sx = aberration_x/screen_width;
  float sy = aberration_y/screen_height;
  vec4 r = Texel(tx, vec2(tc.x + sx, tc.y - sy));
  vec4 g = Texel(tx, vec2(tc.x, tc.y + sy));
  vec4 b = Texel(tx, vec2(tc.x - sx, tc.y - sy));
  number a = (r.a + g.a + b.a)/3.0;

  return vec4(r.r, g.g, b.b, a);
}