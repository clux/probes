#!/bin/bash
set -euo pipefail

pngquant --skip-if-larger --strip --quality=93-93 --speed 4 -- *.png
# write over old files
fd -p '.*-fs8.png' -x echo "{.}" | choose 0..-4 -c | xargs -I '{}' mv {}-fs8.png {}.png
# compress them
oxipng -o5 --strip all -a -t20 -- *.png
# crazy variant that takes a lot longer for 1% gains
#oxipng -o max --strip all -a -Z -t20 -- *.png
