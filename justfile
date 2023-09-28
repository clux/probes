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
