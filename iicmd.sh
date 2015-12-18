#!/usr/bin/env bash

nick="$1"
mesg="$2"
netw="$3"
chan="$4"

read -r cmd extra <<< "$mesg"
if [[ "$mesg" =~ .*\>.+ ]]; then
    read -r nicks <<< "${extra#*>}"
    read -r extra <<< "${extra%>*}"
fi

if [[ "$nicks" == "@all" ]]; then
    printf -- "/names %s\n" "$chan"
    nicks=""
    while test -z "$nicks"; do # wait for the response
        nicks="$(tail -n2 "$ircdir/$netw/out" | grep "[[:digit:]-]\+ [[:digit:]:]\+ = $chan" | cut -d" " -f5-)"
        sleep .5
    done
fi

commands=(
    man
    bc
    qdb
    grep
    fortune
    ping
    url
    talkto
    whereami
)

qdb() {
    if [[ -n $2 ]]
    then
        ((first=$1+1))
        ((num=1+$2-$1))
    else
        ((first=1))
        ((num=$1))
    fi
    date=`date +%s`
    head -n-$first "$ircdir/$netw/$chan/out" | tail -n$num > $botdir/qdb/$date.qdb
    printf -- "Added the %s messages starting with:\n" "$num"
    head -n1 $botdir/qdb/$date.qdb
}

case "$cmd" in
    man)
        [[ -n "$nicks" ]] && printf -- "%s: %s\n" "$nicks" "${commands[*]}" || printf -- "%s: %s | " "$nick" "${commands[*]}"
        echo "See my source at https://github.com/lk86/iibot"
        ;;
    bc)
        [[ -n "$extra" ]] && printf -- "%f\n" "$(bc -l <<< "$extra")"
        ;;
    #echo)
    #    [[ -n "$nicks" ]] && printf -- "%s: %s\n" "$nicks" "${extra#/}" || printf "%s\n" "${extra#/}"
    #    ;;
    talkto)
        printf -- "@talk %s \n" "${extra#/}"
        ;;
    qdb)
        qdb ${extra#/}
        ;;
    grep)
        file="$(grep -rilh --include=[1-9]*.qdb "${extra#/}" $botdir/qdb/)"
        if [[ $? -eq 0 ]]; then
            tail "$file"
        else
            echo "QDB entry not found"
        fi
        ;;
    fortune)
        printf -- "%s\n" "$(fortune -osea)"
        ;;
    ping)
        [[ -n "$nicks" ]] && printf -- "%s: ping!\n" "$nicks" || printf -- "%s: pong!\n" "$nick"
        ;;
    die)
        if [[ "$nick" == \`lhk\` ]]
        then
            killall ii
        else
            printf -- "%s: Go Die\n" "$nick"
        fi
        ;;
    restart)
        if [[ "$nick" == \`lhk\` ]]
        then
            ./iibot.sh
        else
            printf -- "%s: Fuck Off\n" "$nick"
        fi
        ;;
    url)
        link="$(sed 's;.*\(http[^ ]*\).*;\1;' <<< "$extra")"
        #turl="$(curl -s "http://api.bitly.com/v3/shorten?login=pancakesbot&apiKey=R_ac2adceb07f01d8faca52bb77c67293b&longUrl=${link%#*}&format=txt")"
        #(( ${#link} > 80 )) && tiny=1 || tiny=0

        # handle youtube links
        link="$(sed 's;.*youtube\..*v=\([^&]\+\).*;http://youtube.com/embed/\1;' <<< "$link")"
        link="$(sed 's;.*youtu\.be/\(.\+\);http://youtube.com/embed/\1;' <<< "$link")"

        titl="$(curl -s "$link" | sed -n 's;.*<title>\([^<]*\)</title>.*;\1;p' | tail -n1)"
        (( tiny )) && printf -- "%s :: %s\n" "$turl" "$titl" || printf -- "%s\n" "$titl"
        ;;
    whereami)
        printf -- "%s: That's a damn good question. I'm gonna guess %s?\n" "$nick" "$chan"
        ;;
esac

