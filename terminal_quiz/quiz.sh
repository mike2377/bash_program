#!/bin/bash

# Global variables
QUESTIONS_FILE="questions.txt"
HIGHSCORES_FILE="highscores.txt"
score=0
current_question_index=0
player_name=""
mode="normal"  # normal or practice

# Arrays to store questions
declare -a question_texts
declare -a question_options
declare -a question_correct_answers

# Load questions from file
load_questions() {
    if [[ ! -f "$QUESTIONS_FILE" ]]; then
        echo "Error: File '$QUESTIONS_FILE' not found!"
        exit 1
    fi
    
    if [[ ! -s "$QUESTIONS_FILE" ]]; then
        echo "Error: File '$QUESTIONS_FILE' is empty!"
        exit 1
    fi
    
    local index=0
    while IFS='|' read -r question opt_a opt_b opt_c opt_d correct; do
        if [[ -z "$question" ]]; then
            continue
        fi
        
        if [[ -n "$question" && -n "$opt_a" && -n "$opt_b" && -n "$opt_c" && -n "$opt_d" && -n "$correct" ]]; then
            question_texts[index]="$question"
            
            local clean_opt_a clean_opt_b clean_opt_c clean_opt_d
            clean_opt_a="${opt_a//[A-D]) /}"
            clean_opt_b="${opt_b//[A-D]) /}"
            clean_opt_c="${opt_c//[A-D]) /}"
            clean_opt_d="${opt_d//[A-D]) /}"
            
            question_options[index]="$clean_opt_a|$clean_opt_b|$clean_opt_c|$clean_opt_d"
            question_correct_answers[index]="$correct"
            ((index++))
        fi
    done < "$QUESTIONS_FILE"
    
    if [[ ${#question_texts[@]} -eq 0 ]]; then
        echo "Error: No valid questions found!"
        exit 1
    fi
}

# Shuffle questions randomly
shuffle_questions() {
    local size=${#question_texts[@]}
    [[ $size -eq 0 ]] && return

    # Fix : Use mapfile
    local indices=()
    mapfile -t indices < <(shuf -i 0-$((size - 1)))

    local new_texts=() new_options=() new_answers=()

    for idx in "${indices[@]}"; do
        new_texts+=("${question_texts[idx]}")
        new_options+=("${question_options[idx]}")
        new_answers+=("${question_correct_answers[idx]}")
    done

    question_texts=("${new_texts[@]}")
    question_options=("${new_options[@]}")
    question_correct_answers=("${new_answers[@]}")
}

# Check if quiz is finished
is_quiz_finished() {
    if [[ $current_question_index -ge ${#question_texts[@]} ]]; then
        return 0
    else
        return 1
    fi
}

# Get current question text
get_current_question() {
    echo "${question_texts[$current_question_index]}"
}

# Get current question options
get_current_options() {
    echo "${question_options[$current_question_index]}"
}

# Get correct answer letter
get_correct_answer() {
    echo "${question_correct_answers[$current_question_index]}"
}

# Move to next question
next_question() {
    ((current_question_index++))
}

# Reset quiz state
reset_quiz() {
    score=0
    current_question_index=0
    shuffle_questions
}

# Save score to highscores file (normal mode only)
save_highscore() {
    local percentage=$((score * 100 / ${#question_texts[@]}))
    local date_str  # Fix SC2155: split declaration and assignment
    date_str=$(date "+%Y-%m-%d")
    echo "$player_name|$percentage|$score/${#question_texts[@]}|$date_str" >> "$HIGHSCORES_FILE"
}

# Display high scores
show_highscores() {
    if [[ ! -f "$HIGHSCORES_FILE" ]] || [[ ! -s "$HIGHSCORES_FILE" ]]; then
        echo "=========================================="
        echo "            TOP 5 HIGH SCORES"
        echo "=========================================="
        echo "No high scores yet!"
        echo "=========================================="
        return
    fi
    
    echo "=========================================="
    echo "            TOP 5 HIGH SCORES"
    echo "=========================================="
    echo ""
    
    # Fix SC2030/SC2031: Use process substitution instead of pipe
    while IFS='|' read -r name highscore details date_str; do
        printf "%-15s | %3d%% | %-12s | %s\n" "$name" "$highscore" "$details" "$date_str"
    done < <(sort -t'|' -k2 -rn "$HIGHSCORES_FILE" | head -5)
    
    echo ""
    echo "=========================================="
}

# Display quiz interface
display_quiz() {
    clear
    
    if [[ "$mode" == "normal" ]]; then
        echo "=========================================="
        echo "                QUIZMASTER"
        echo "=========================================="
    else
        echo "=========================================="
        echo "          QUIZMASTER - PRACTICE MODE"
        echo "=========================================="
    fi
    echo ""
    
    if is_quiz_finished; then
        if [[ "$mode" == "normal" ]]; then
            show_final_results
        else
            echo "Practice session completed!"
            echo ""
            echo -n "Press Enter to exit..."
            read -r
            exit 0
        fi
    fi
    
    # Display question number and question
    echo "Question $((current_question_index + 1)) of ${#question_texts[@]}"
    echo "------------------------------------------"
    get_current_question
    echo "------------------------------------------"
    echo ""
    
    # Display options
    local options
    options=$(get_current_options)
    IFS='|' read -r opt_a opt_b opt_c opt_d <<< "$options"
    
    echo "  A) $opt_a"
    echo "  B) $opt_b"
    echo "  C) $opt_c"
    echo "  D) $opt_d"
    
    echo ""
    echo "=========================================="
    
    # Show score only in normal mode
    if [[ "$mode" == "normal" ]]; then
        echo "Score: $score"
        echo "=========================================="
    else
        echo "PRACTICE MODE - No scoring"
        echo "=========================================="
    fi
}

# Show final results (normal mode only)
show_final_results() {
    clear
    echo "=========================================="
    echo "              QUIZ COMPLETED!"
    echo "=========================================="
    echo ""
    echo "Player: $player_name"
    echo "Score: $score / ${#question_texts[@]}"
    
    local percentage=$((score * 100 / ${#question_texts[@]}))
    echo "Percentage: ${percentage}%"
    
    if [[ $percentage -ge 80 ]]; then
        echo "Rating: Excellent!"
    elif [[ $percentage -ge 60 ]]; then
        echo "Rating: Good job!"
    else
        echo "Rating: Keep practicing!"
    fi
    
    # Save highscore
    save_highscore
    echo ""
    echo "Score saved to highscores.txt!"
    
    echo "=========================================="
    echo ""
    echo -n "Press Enter to exit..."
    read -r
    exit 0
}

# Verify answer in normal mode
verify_answer_normal() {
    local user_answer=$1
    local correct_answer
    correct_answer=$(get_correct_answer)
    
    echo ""
    if [[ "$user_answer" == "$correct_answer" ]]; then
        echo -e "\033[0;32mCorrect! ($correct_answer)\033[0m"
        # Increment score for correct answer
        ((score++))
    else
        echo -e "\033[0;31mIncorrect. The correct answer was $correct_answer\033[0m"
    fi
    
    echo ""
    echo -n "Press Enter to continue..."
    read -r
    
    next_question
}

# Verify answer in practice mode
verify_answer_practice() {
    local user_answer=$1
    local correct_answer 
    correct_answer=$(get_correct_answer)
    
    echo ""
    if [[ "$user_answer" == "$correct_answer" ]]; then
        echo "Correct! ($correct_answer)"
    else
        echo "Incorrect. The correct answer was $correct_answer"
    fi
    
    echo ""
    echo -n "Press Enter to continue..."
    read -r
    
    next_question
}

# Ask for player name (normal mode only)
ask_player_name() {
    clear
    echo "=========================================="
    echo "          WELCOME TO QUIZMASTER"
    echo "=========================================="
    echo ""
    echo -n "Enter your name: "
    read -r player_name
    
    while [[ -z "$player_name" ]]; do
        echo -n "Name cannot be empty! Enter your name: "
        read -r player_name
    done
    
    echo ""
    echo "Good luck, $player_name!"
    echo ""
    echo -n "Press Enter to start..."
    read -r
}

# Main game loop
main_loop() {
    while true; do
        if is_quiz_finished; then
            if [[ "$mode" == "normal" ]]; then
                show_final_results
            else
                clear
                echo "=========================================="
                echo "          PRACTICE SESSION COMPLETED!"
                echo "=========================================="
                echo ""
                echo "You've completed all ${#question_texts[@]} questions!"
                echo ""
                echo -n "Press Enter to exit..."
                read -r
                exit 0
            fi
        fi
        
        display_quiz
        
        if ! is_quiz_finished; then
            echo -n "Your answer (A/B/C/D): "
            read -r response
            
            # Convert to uppercase
            response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
            
            # Validate input
            while [[ ! "$response" =~ ^[ABCD]$ ]]; do
                echo -n "Invalid input! Please enter A, B, C, or D: "
                read -r response
                response=$(echo "$response" | tr '[:lower:]' '[:upper:]')
            done
            
            # Call appropriate verification function
            if [[ "$mode" == "normal" ]]; then
                verify_answer_normal "$response"
            else
                verify_answer_practice "$response"
            fi
        fi
    done
}

# Display usage information
usage() {
    echo "=========================================="
    echo "              QUIZMASTER USAGE"
    echo "=========================================="
    echo ""
    echo "  ./quiz.sh              - Normal mode (scores saved)"
    echo "  ./quiz.sh practice     - Practice mode (no scoring)"
    echo "  ./quiz.sh highscores   - View top 5 high scores"
    echo ""
    echo "=========================================="
    exit 0
}

# Main function
main() {
    # Check command line arguments
    case "$1" in
        practice)
            mode="practice"
            load_questions
            shuffle_questions
            main_loop
            ;;
        highscores)
            show_highscores
            exit 0
            ;;
        "")
            mode="normal"
            load_questions
            shuffle_questions
            ask_player_name
            main_loop
            ;;
        *)
            usage
            ;;
    esac
}

# Launch the game
main "$1"