# User-defined variables
global w = 853
global h = 480
global fps = 30
global b0 = $000000
global b1 = $001100
global b2 = $002200
global b3 = $003300
global b4 = $004400
global b5 = $005500
global b6 = $006600
global b7 = $007700
global b8 = $008800
global b9 = $009900
global ba = $00AA00
global bb = $00BB00
global bc = $00CC00
global bd = $00DD00
global be = $00EE00
global bf = $00FF00

function add_fade_from_to(clip c, int num_frames, int from_color, int fade_color)
{
	new_clip = c + BlankClip(length=num_frames, width=w, height=h, fps=fps, color=from_color)
	new_clip = FadeOut(new_clip, num_frames, color=fade_color, fps=fps)
	return new_clip
}

clip = BlankClip(length=300, width=w, height=h, fps=fps, color=b7)
clip = add_fade_from_to(clip, 300, b7, b4)
clip = add_fade_from_to(clip, 100, b4, b4)
clip = add_fade_from_to(clip, 100, b4, bd)
clip = add_fade_from_to(clip, 200, bd, bd)
clip = add_fade_from_to(clip, 100, bd, b4)
clip = add_fade_from_to(clip, 250, b4, b7)
clip = add_fade_from_to(clip, 100, b7, b7)
two_hump = clip

clip = BlankClip(length=1600, width=w, height=h, fps=fps, color=b7)
clip = add_fade_from_to(clip, 100, b7, b0)
clip = add_fade_from_to(clip, 300, b0, b7)
surprise = clip

clip = BlankClip(length=100, width=w, height=h, fps=fps, color=b7)
clip = add_fade_from_to(clip, 300, b7, b2)
clip = add_fade_from_to(clip, 100, b2, b6)
clip = add_fade_from_to(clip, 100, b6, bb)
clip = add_fade_from_to(clip, 200, bb, b5)
clip = add_fade_from_to(clip, 100, b5, b4)
clip = add_fade_from_to(clip, 250, b4, b3)
clip = add_fade_from_to(clip, 100, b3, b7)
natural = clip

clip = BlankClip(length=60, width=w, height=h, fps=fps, color=b7)
clip = add_fade_from_to(clip, 80, b7, be)
clip = add_fade_from_to(clip, 50, be, b6)
clip = add_fade_from_to(clip, 30, b6, b4)
clip = add_fade_from_to(clip, 100, b4, b8)
clip = add_fade_from_to(clip, 70, b8, b9)
clip = add_fade_from_to(clip, 150, b9, b3)
clip = add_fade_from_to(clip, 50, b3, b7)
high_energy = clip

trial1_clip = two_hump + natural + surprise + natural + high_energy + two_hump
trial1_clip
#Info
