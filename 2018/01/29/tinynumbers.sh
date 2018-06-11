#!/bin/bash
# ⁰¹²³⁴⁵⁶⁷⁸⁹
# ₀₁₂₃₄₅₆₇₈₉

TEMP=$(mktemp)
NUMBERS=("⁰" "¹" "²" "³" "⁴" "⁵" "⁶" "⁷" "⁸" "⁹" "₀" "₁" "₂" "₃" "₄" "₅" "₆" "₇" "₈" "₉")
for i in $(seq 0 6); do
bc <<< "ibase=10; obase=20; $RANDOM * $RANDOM * $RANDOM + $RANDOM * $RANDOM" >> $TEMP
done
sed -i -e 's/\b00\b/⁰/g' \
    -e 's/\b01\b/¹/g' \
    -e 's/\b02\b/²/g' \
    -e 's/\b03\b/³/g' \
    -e 's/\b04\b/⁴/g' \
    -e 's/\b05\b/⁵/g' \
    -e 's/\b06\b/⁶/g' \
    -e 's/\b07\b/⁷/g' \
    -e 's/\b08\b/⁸/g' \
    -e 's/\b09\b/⁹/g' \
    -e 's/\b10\b/₀/g' \
    -e 's/\b11\b/₁/g' \
    -e 's/\b12\b/₂/g' \
    -e 's/\b13\b/₃/g' \
    -e 's/\b14\b/₄/g' \
    -e 's/\b15\b/₅/g' \
    -e 's/\b16\b/₆/g' \
    -e 's/\b17\b/₇/g' \
    -e 's/\b18\b/₈/g' \
    -e 's/\b19\b/₉/g' \
$TEMP
TWEET=()
while read line; do
    TWEET+=("$line")
done < $TEMP

t update -P ~/.trc.tinynumbers "
${TWEET[0]}
${TWEET[1]}
${TWEET[2]}
${TWEET[3]}
${TWEET[4]}
${TWEET[5]}"

