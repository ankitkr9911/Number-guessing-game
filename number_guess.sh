#!/bin/bash

# PostgreSQL connection command
PSQL="psql -U freecodecamp -d number_guess -t -A -c"

welcome_user() {
  local username=$1
  local games_played
  local best_game
  local user_exists

  # Check if the user exists
  user_exists=$($PSQL "SELECT COUNT(*) FROM users WHERE username='$username';")

  # Error handling for database query
  if [[ $? -ne 0 ]]; then
    echo "Error checking user in the database."
    exit 1
  fi

  if [[ $user_exists -gt 0 ]]; then
    # Fetch games_played and best_game from the database
    games_played=$($PSQL "SELECT games_played FROM users WHERE username='$username';")
    best_game=$($PSQL "SELECT best_game FROM users WHERE username='$username';")

    # Ensure games_played and best_game are valid numbers
    if [[ -z "$games_played" || -z "$best_game" ]]; then
      echo "Error retrieving data from the database."
      exit 1
    fi

    echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
  else
    # New user, initialize games_played and best_game
    echo "Welcome, $username! It looks like this is your first time here."
    games_played=0
    best_game=0
  fi

  # Generate a random number between 1 and 1000
  secret_number=$(( RANDOM % 1000 + 1 ))
  number_of_guesses=0

  echo "Guess the secret number between 1 and 1000:"

  while true; do
    read GUESS

    # Check if the input is an integer
    if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
      continue
    fi

    ((number_of_guesses++))

    # Check the guess
    if [[ $GUESS -gt $secret_number ]]; then
      echo "It's lower than that, guess again:"
    elif [[ $GUESS -lt $secret_number ]]; then
      echo "It's higher than that, guess again:"
    else
      echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
      break
    fi
  done
  
  # Update best_game if this is the best performance
  if (( games_played == 0 || number_of_guesses < best_game || best_game == 0 )); then
    best_game=$number_of_guesses
  fi
  ((games_played++))

  # Update the users table: insert if new, or update if existing
  update_query=$($PSQL "INSERT INTO users (username, games_played, best_game) 
                        VALUES ('$username', $games_played, $best_game)
                        ON CONFLICT (username) DO UPDATE 
                        SET games_played = EXCLUDED.games_played,
                            best_game = LEAST(users.best_game, EXCLUDED.best_game);")

  # Error handling for database update
  if [[ $? -ne 0 ]]; then
    echo "Error updating the database."
    exit 1
  fi
}

# Prompt for username
echo "Enter your username: "
read username

# Validate username length
if [[ ${#username} -gt 22 ]]; then
  echo "Username must be 22 characters or less."
  exit 1
fi 

# Start the game
welcome_user "$username"
