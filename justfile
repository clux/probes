open := if os() == "macos" { "open" } else { "xdg-open" }

[private]
default:
  @just --list --unsorted

serve:
  (sleep 2 && {{open}} http://127.0.0.1:8080/) &
  zola serve -p 8080

build:
  echo TODO

update:
  git submodule update --remote themes/abridge
  rsync themes/abridge/COPY-TO-ROOT-SASS/* sass/
  rsync themes/abridge/package_abridge.js package_abridge.js
  rsync themes/abridge/package.json package.json
  rsync themes/abridge/static/fonts/Roboto* static/fonts/

# convert static resources to webp
convert folder:
  #!/bin/sh -x
  fd . {{folder}} -e gif -x gif2webp {} -q 50 -lossy -o '{.}.webp'
  rm -f -- {{folder}}/*.gif
  fd . {{folder}} -e jpg -x cwebp -q 50 {} -o '{.}.webp'
  rm -f -- {{folder}}/*.jpg
  fd . {{folder}} -e png -x img2webp -q 30 {} -lossy -o '{.}.webp'
  rm -f -- {{folder}}/*.png

# compress static resources in a folder in-place (can be better than webp conversion)
compress folder:
  #!/bin/sh -x
  pngquant --skip-if-larger --strip --quality=93-93 --speed 4 -- {{folder}}/*.png || true
  fd -p '.*-fs8.png' {{folder}} -x echo "{.}" | choose 0..-4 -c | xargs -I '{}' mv {}-fs8.png {}.png
  oxipng -o5 --strip all -a -t20 -- {{folder}}/*.png
