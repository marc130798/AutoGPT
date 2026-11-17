#!/bin/bash
# $1 figure (lion|lioness) $2 garment $3 pose ('' or .wave etc)
fig=$1; g=$2; pose=$3
out=design/gemini/kleider/avatar.$fig.$g$pose.png
[ -f "$out" ] && exit 0
case $g in
  sailor) C="a cosy sailor sweater (knitted jumper) in a strong medium BLUE colour with white details (white sailor collar with stripes, white anchor on the chest) and plain BLUE trousers";;
  vest) C="a plain white shirt with short sleeves and over it an open BLUE trader's waistcoat (vest) with two small golden buttons and a pocket, and plain BLUE trousers";;
  hoodie) C="a cosy BLUE hooded sweatshirt (hoodie, hood down) with one big white star on the chest, and BLUE jogging trousers";;
  raincoat) C="a BLUE sailor's raincoat (oilskin jacket) with white toggle buttons and a white collar edge, and matching BLUE rain trousers, no hat";;
esac
if [ $fig = lion ]; then who="young lion"; pr="he"; else who="young lioness"; pr="she"; fi
P="Recreate EXACTLY this character from the reference image: same $who, same face, same hair, same fur colour, same proportions, EXACTLY the same pose and arm position, same facial expression, same white sneakers, same camera angle and size. Only change the clothes: instead of the striped shirt and shorts $pr wears $C. Keep all clothing only blue and white (tiny golden buttons allowed). 3D animated movie style. Plain flat solid magenta background (#FF00FF), no shadow, no text."
timeout 240 python3 tool/gemini_bild.py "$out" "$P" assets/images/avatar.$fig$pose.png --format 3:4 >/dev/null 2>&1 && echo "ok $out" || echo "FEHLER $out"
