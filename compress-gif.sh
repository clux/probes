#!/bin/bash
set -euo pipefail

fd . -e gif -x gif2webp {} -q 50 -lossy -o '{.}.webp'
rm -- *.gif
