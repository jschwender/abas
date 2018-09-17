#!/bin/bash
# alte ABAS-Benutzerprozesse in allen Mandanten killen
# Aufruf durch crontab (root)
# die Prozesskontendatei liefert diese Zeilen:
#3839	3839	GUI:wts02:107	abas-2015	63	0	NA	ferrotec	WTS02 ???	14.03.2018 12:14
#21207	21207	GUI:wts02:141	abas-2015	64	0	JW	ferrotec	WTS02 ???	14.03.2018 11:52
#  ^[PID]                                                                  ^[Benutzer]                      ^[Prozessbeginn]
#                                                                ^[Benutzer]
#
MaxAlter=$((3600*36))  # Maximales Alter eines Prozesses
# diese Prozesskontendatei wird von ABAS permanent aktualisiert
# direkt darauf zu zugreifen geht schneller als über su + lizinfo.sh
# Die Gesamtlaufzeit geht von 1,8 s auf 0,7 s zurück
Aproz=/data/prod/abas/...mandant../pa.dat          # PFAD unbedingt für den Mandanten anpassen !!!
AprozTemp=/tmp/abas-prozesse
# Die Datei erst mal nur kopieren
cp -f "$Aproz" "$AprozTemp"
Jetzt=$(date +%s)
#
while read -r LINE
do
    AZEIT=$(echo "$LINE"|awk '{print $3}') # Datum in ISO umgeformt
    ALTER=$(( Jetzt - $(date +%s -d"${AZEIT}:00") ))   # Alter des Prozesses in s ermitteln (minutengenau)
#    echo "Alter: $ALTER s"
    if [[ "$ALTER" -gt "$MaxAlter" ]]
    then
        PID=$(echo "$LINE"|awk '{print $1}')
        USR=$(echo "$LINE"|awk '{print $2}') # Der (ABAS) Benutzer
	echo "Kill:$PID Alter:$ALTER s - Benutzer:$USR"
	kill -9 "$PID"
	logger -t licence -p user.info "terminate user process $USR,$PID,$ALTER s ($?)"  # Dokumentation von Eingriffen in den Prozess
#    else
#	logger -t licence -p user.info "user process ok: $USR,$PID,$ALTER s"  # Dokumentation von Eingriffen in den Prozess
    fi
done < <(grep "GUI:" $AprozTemp|awk '{ printf"%s %s %s-%s-%sT%s\n", $1,$7,substr($11,7,4),substr($11,4,2),substr($11,1,2),$12 }')
# grep auf GUI filtert die EDP Prozesse raus, die dürfen nicht gekillt werden!
# Die Ausgabe erfolgt im FOrmat:   PID  USER  ZEITSTEMPEL
rm -f "$AprozTemp"
