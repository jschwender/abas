#!/bin/bash
# Loginzahlen seit der letzten Abfrage
LOG=/var/log/local0
LAST=/var/log/local0lastline
OldLastLine=$(<"$LAST")
tail -1 "$LOG" >"$LAST"  2>/dev/null
/usr/bin/grep -A 100 "$OldLastLine" "$LOG"  |cut -d' ' -f4|sort -n |tail -1
