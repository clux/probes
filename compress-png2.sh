#!/bin/bash
set -euo pipefail

fd . -e png -x img2webp -q 30 {} -lossy -o '{.}.webp'
rm -- *.png
