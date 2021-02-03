#!/bin/bash
input=$(</dev/stdin)
echo lunamark
echo '<<<'
echo "$input"
echo '>>>'
echo "$input" | pandoc -f markdown -t html
