#!/bin/bash
# Snaketrix v5.3 - Snake game with B walls

SCOREFILE="/userdata/system/configs/snakescores.txt"

cleanup() {
    stty sane
    tput cnorm
    clear
}
trap "cleanup; exit" INT EXIT

tput civis

# --- Utility ---
draw_char() {
    tput cup "$1" "$2"
    echo -ne "$3"
}
pause() {
    tput cup $(($(tput lines)/2)) $(($(tput cols)/2-10))
    read -n1 -s -r -p "Press any key..."
}

# --- Matrix Rain ---
matrix_rain() {
    duration=${1:-4}
    stty -echo -icanon time 0 min 0
    clear
    rows=$(tput lines)
    cols=$(tput cols)
    chars=({A..Z} {a..z} {0..9} "@" "#" "$" "%" "&" "*" "+" "-" "=")
    declare -a col_y col_speed
    for ((c=0;c<cols;c++)); do
        col_y[$c]=$((RANDOM % rows))
        col_speed[$c]=$((RANDOM % 4 +1))
    done
    end_time=$(( $(date +%s)+duration ))
    while (( $(date +%s) < end_time )); do
        batch=$((cols/6+1))
        for ((i=0;i<batch;i++)); do
            c=$((RANDOM % cols))
            y=${col_y[$c]}
            ch=${chars[RANDOM % ${#chars[@]}]}
            if ((RANDOM % 15==0)); then
                echo -ne "\033[${y};${c}H$(tput bold)$(tput setaf 2)$ch$(tput sgr0)"
            else
                echo -ne "\033[${y};${c}H$(tput setaf 2)$ch$(tput sgr0)"
            fi
            ((y+=col_speed[$c]))
            ((y>=rows)) && y=0
            col_y[$c]=$y
        done
        sleep 0.02
    done
    clear
}

# --- Game Over ---
game_over_sequence() {
    matrix_rain 4
    clear
    rows=$(tput lines)
    cols=$(tput cols)
    text=" GAME OVER!!! "
    textlen=${#text}
    cy=$((rows/2))
    cx=$(( (cols-textlen)/2 ))
    for i in {1..3}; do
        tput cup $cy $cx
        echo -ne "$(tput bold)$(tput setaf 1)$text$(tput sgr0)"
        sleep 0.4
        tput cup $cy $cx
        echo -n "$(printf '%*s' "$textlen")"
        sleep 0.2
    done
    clear
}

# --- High Score ---
save_score() {
    [ ! -f "$SCOREFILE" ] && touch "$SCOREFILE"
    rows=$(tput lines)
    cols=$(tput cols)
    tput cup $((rows/2)) $((cols/2-20))
    echo -n "Save your score ($score)? (y/n): "
    read -n1 save_choice
    echo
    if [[ "$save_choice" =~ [Yy] ]]; then
        tput cup $((rows/2+1)) $((cols/2-20))
        echo -n "Enter your name: "
        read name
        [ -z "$name" ] && name="Anonymous"
        echo "$score|$name" >> "$SCOREFILE"
        sort -t'|' -k1,1nr "$SCOREFILE" -o "$SCOREFILE"
        top=$(awk -F'|' 'NR==1{print $1}' "$SCOREFILE")
        if (( top == score )); then
            tput cup $((rows/2+3)) $((cols/2-20))
            echo "🎉 NEW TOP SCORE! 🎉"
            sleep 1.5
        fi
    fi
}

show_scores() {
    clear
    echo "=== High Scores ==="
    if [ -f "$SCOREFILE" ] && [ -s "$SCOREFILE" ]; then
        printf "%-5s %-10s %s\n" "Rank" "Score" "Name"
        echo "----------------------------"
        rank=1
        while IFS="|" read -r s n; do
            printf "%-5s %-10s %s\n" "$rank" "$s" "$n"
            ((rank++))
            [ $rank -gt 10 ] && break
        done < <(sort -t'|' -k1,1nr "$SCOREFILE")
    else
        echo "No scores yet!"
    fi
    pause
}

# --- Options ---
options_menu() {
    while true; do
        clear
        echo "=== Options ==="
        echo "1) Snake Colour"
        echo "2) Snake Character"
        echo "3) B Block Frequency (current: $b_frequency)"
        echo "4) Back"
        read -n1 -s choice
        case $choice in
            1) snake_colour_menu ;;
            2) snake_char_menu ;;
            3) b_frequency_menu ;;
            4) return ;;
        esac
    done
}

snake_colour_menu() {
    clear
    echo "Choose snake colour:"
    echo "1) Red"; echo "2) Green"; echo "3) Yellow"; echo "4) Blue"; echo "5) Multi-coloured"
    read -n1 -s c
    case $c in 1) snake_colour=1;; 2) snake_colour=2;; 3) snake_colour=3;; 4) snake_colour=4;; 5) snake_colour="multi";; esac
}

snake_char_menu() {
    clear
    echo "Enter single character for snake (default O):"
    read -n1 s
    snake_char=${s:-O}
}

b_frequency_menu() {
    clear
    echo "Set number of B blocks spawned per item eaten (0–50):"
    echo -n "Enter value: "
    read value
    if [[ "$value" =~ ^[0-9]+$ ]] && ((value >= 0 && value <= 50)); then
        b_frequency=$value
    else
        echo "Invalid input. Must be between 0 and 50."
        sleep 1.5
    fi
}

# --- Menus ---
main_menu() {
    while true; do
        clear
        echo "==========================="
        echo " Welcome to the Snaketrix "
        echo "==========================="
        echo
        echo "1) Start Game"; echo "2) Options"; echo "3) High Scores"; echo "4) Quit"; echo "5) Matrix Rain"
        read -n1 -s choice
        case $choice in
            1) start_game ;;
            2) options_menu ;;
            3) show_scores ;;
            4) cleanup; exit 0 ;;
            5) matrix_rain 4 ;;
        esac
    done
}

# --- Snake / Apples / Specials / B hazards ---
draw_apple() { draw_char $1 $2 "$(tput setaf 2)A$(tput sgr0)"; }
draw_special() { draw_char $1 $2 "$(tput setaf 5)*$(tput sgr0)"; }
draw_b() { draw_char $1 $2 "$(tput setaf 0)B$(tput sgr0)"; }
draw_snake_part() {
    local y=$1 x=$2
    if [[ "$snake_colour" == "multi" ]]; then colour=$((RANDOM%6+1)); else colour=$snake_colour; fi
    draw_char $y $x "$(tput setaf $colour)$snake_char$(tput sgr0)"
}
clear_apples() {
    for ((i=0;i<${#apples[@]};i+=2)); do
        ay=${apples[i]}; ax=${apples[i+1]}
        [[ $ay -gt 0 && $ax -gt 0 ]] && tput cup $ay $ax && echo -n " "
    done
    apples=(); specials_on=0; flashing_specials_y=(); flashing_specials_x=(); flashing_visible_flags=()
}
spawn_apples() {
    count=$1
    for ((i=0;i<count;i++)); do
        ay=$((RANDOM%(rows-4)+2))
        ax=$((RANDOM%(cols-2)+2))
        apples+=($ay $ax)
        draw_apple $ay $ax
    done
}
spawn_flashing_special() {
    fy=$((RANDOM%(rows-4)+2)); fx=$((RANDOM%(cols-2)+2))
    flashing_specials_y+=($fy); flashing_specials_x+=($fx); flashing_visible_flags+=(1)
}
draw_flashing_specials() {
    for i in "${!flashing_specials_y[@]}"; do
        y=${flashing_specials_y[i]}; x=${flashing_specials_x[i]}; v=${flashing_visible_flags[i]}
        tput cup $y $x
        if ((v)); then color=$((RANDOM%6+1)); echo -ne "$(tput setaf $color)@$(tput sgr0)"
        else echo -n " "; fi
        flashing_visible_flags[i]=$((1-v))
    done
}

# --- Game Loop ---
start_game() {
    lives=3; speed=0.2; snake_len=5; snake_body=(); score=0
    rows=$(tput lines); cols=$(tput cols)
    apples=(); specials_on=0; flashing_special_eaten=0
    flashing_specials_y=(); flashing_specials_x=(); flashing_visible_flags=()
    b_y=(); b_x=()
    
    # Draw border
    for ((x=0;x<cols;x++)); do tput cup 0 $x; echo -n "-"; tput cup $((rows-1)) $x; echo -n "-"; done
    for ((y=0;y<rows;y++)); do tput cup $y 0; echo -n "|"; tput cup $y $((cols-1)); echo -n "|"; done
    
    spawn_apples 20
    for i in {1..5}; do spawn_flashing_special; done

    snake_y=$((rows/2)); snake_x=$((cols/2))
    snake_len=5

    while ((lives>0)); do
        snake_body=()
        for ((i=0;i<snake_len;i++)); do snake_body+=($snake_y $((snake_x-i))); done
        for ((i=0;i<${#snake_body[@]};i+=2)); do draw_snake_part ${snake_body[i]} ${snake_body[i+1]}; done
        if ! snake_game_loop; then
            ((lives--))
            if ((lives>0)); then
                snake_y=$((rows/2)); snake_x=$((cols/2))
                snake_len=5
                for ((i=0;i<snake_len;i++)); do snake_body+=($snake_y $((snake_x-i))); done
            fi
        fi
        clear_apples; spawn_apples 20
    done

    game_over_sequence
    save_score
    main_menu
}

snake_game_loop() {
    stty -echo -icanon time 0 min 0
    dir="RIGHT"; apples_eaten=0
    while true; do
        tput cup 0 $((cols-35))
        echo -n "Score: $score  Lives: $lives  B-Freq: $b_frequency"
        read -t $speed -n3 key
        case "$key" in
            $'\x1b[A'|w) [[ "$dir" != "DOWN" ]] && dir="UP" ;;
            $'\x1b[B'|s) [[ "$dir" != "UP" ]] && dir="DOWN" ;;
            $'\x1b[D'|a) [[ "$dir" != "RIGHT" ]] && dir="LEFT" ;;
            $'\x1b[C'|d) [[ "$dir" != "LEFT" ]] && dir="RIGHT" ;;
        esac
        case $dir in UP) ((snake_y--)) ;; DOWN) ((snake_y++)) ;; LEFT) ((snake_x--)) ;; RIGHT) ((snake_x++)) ;; esac

        ((snake_x<=0 || snake_x>=cols-1 || snake_y<=0 || snake_y>=rows-1)) && return 1

        for ((i=0;i<${#snake_body[@]};i+=2)); do
            ((snake_y==snake_body[i] && snake_x==snake_body[i+1])) && return 1
        done

        for i in "${!b_y[@]}"; do
            if ((snake_y==b_y[i] && snake_x==b_x[i])); then
                tput bel
                return 1
            fi
        done

        snake_body=($snake_y $snake_x "${snake_body[@]}")
        while (( ${#snake_body[@]} > snake_len*2 )); do
            tail_y=${snake_body[-2]}; tail_x=${snake_body[-1]}
            unset 'snake_body[-1]'; unset 'snake_body[-1]'
            tput cup $tail_y $tail_x; echo -n " "
        done
        draw_snake_part $snake_y $snake_x

        # Apples
        for ((i=0;i<${#apples[@]};i+=2)); do
            ay=${apples[i]}; ax=${apples[i+1]}
            if ((snake_y==ay && snake_x==ax)); then
                ((snake_len++)); ((score+=10)); ((apples_eaten++))
                apples[i]=0; apples[i+1]=0; tput bel
                spawn_apples 2
                spawn_flashing_special
                for ((b=0; b<b_frequency; b++)); do
                    by=$((RANDOM%(rows-4)+2))
                    bx=$((RANDOM%(cols-2)+2))
                    b_y+=($by)
                    b_x+=($bx)
                    draw_b $by $bx
                done
                if awk "BEGIN{exit !($speed>0.03)}"; then speed=$(awk "BEGIN{print $speed*0.95}"); fi
            fi
        done

        draw_flashing_specials
        for i in "${!flashing_specials_y[@]}"; do
            y=${flashing_specials_y[i]}; x=${flashing_specials_x[i]}
            if ((snake_y==y && snake_x==x)); then
                ((snake_len++)); ((score+=30))
                tput cup $y $x; echo -n " "; tput bel; sleep 0.05; tput bel
                unset 'flashing_specials_y[i]'; unset 'flashing_specials_x[i]'; unset 'flashing_visible_flags[i]'
                flashing_specials_y=("${flashing_specials_y[@]}"); flashing_specials_x=("${flashing_specials_x[@]}"); flashing_visible_flags=("${flashing_visible_flags[@]}")
                spawn_apples 2
                for ((b=0; b<b_frequency; b++)); do
                    by=$((RANDOM%(rows-4)+2))
                    bx=$((RANDOM%(cols-2)+2))
                    b_y+=($by)
                    b_x+=($bx)
                    draw_b $by $bx
                done
            fi
        done
    done
}

# --- Defaults ---
snake_colour=2
snake_char="O"
b_frequency=20  # Default number of B hazards per item eaten (range 0–50)

main_menu
