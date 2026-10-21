#!/bin/bash
# 1.0.2: команда «ym» в pfctl (меню усилителя → SOURCE → YANDEX MUSIC)
set -e
P=/usr/bin/pfctl
if ! grep -q 'pfctl-ym' "$P"; then
    cp -p "$P" "$P.pre-1.0.2"
    T=$(mktemp /usr/bin/.pfctl.XXXXXX)
    awk '/^        rate\)  echo "@RATE/ && !d {
        print "        ym) /usr/local/bin/pfctl-ym \"$arg\" \"$3\" \"$4\" ;;"; d=1 }
        { print }' "$P" > "$T"
    chmod --reference="$P" "$T"
    if grep -q 'pfctl-ym' "$T" && sh -n "$T"; then
        mv "$T" "$P"
    else
        rm -f "$T"; echo "не удалось встроить команду ym в pfctl"; exit 1
    fi
fi
systemctl restart --no-block pfctl.service 2>/dev/null || true
