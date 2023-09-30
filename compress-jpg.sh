#!/bin/bash
set -euo pipefail

fd . -e jpg -x cwebp -q 50 {} -o '{.}.webp'
rm -- *.jpg
