#!/bin/zsh

function verify_directory() {
    local directory="$1"
    echo "Verifying if directory exists"

    if [[ -d "$directory" ]]; then
        echo "The directory exists"
        return 0
    else
        echo "The directory does not exist"
        return 1
    fi
}

function change_organization() {
    local file_content=$(<~/.zshrc)
    local existing_organization=$(grep "^export REACT_APP_INSTANCE_FILES_DIR" <<< "$file_content" | cut -d '=' -f 2)
    echo "Changing REACT_APP_INSTANCE_FILES_DIR..."
    echo "The existing organization is: $existing_organization"

    if [[ "$existing_organization" == '"$HAWAII_APP_INSTANCE_FILES_DIR"' ]]; then
        echo "Changing existing organization to NOIPM_APP_INSTANCE_FILES_DIR"
        sed -i'.bak' 's/"$HAWAII_APP_INSTANCE_FILES_DIR"/"$NOIPM_APP_INSTANCE_FILES_DIR"/g' ~/.zshrc
    elif [[ "$existing_organization" == '"$NOIPM_APP_INSTANCE_FILES_DIR"' ]]; then
        echo "Changing existing organization to HAWAII_APP_INSTANCE_FILES_DIR"
        sed -i'.bak' 's/"$NOIPM_APP_INSTANCE_FILES_DIR"/"$HAWAII_APP_INSTANCE_FILES_DIR"/g' ~/.zshrc
    else 
        local hawaii_pattern='hawaii'
        if [[ "$existing_organization" =~ $hawaii_pattern ]]; then
            echo "Changing existing organization to NOIPM_APP_INSTANCE_FILES_DIR"
            sed -i'.bak' 's|'"export REACT_APP_INSTANCE_FILES_DIR=$existing_organization"'|export REACT_APP_INSTANCE_FILES_DIR="$NOIPM_APP_INSTANCE_FILES_DIR"|g' ~/.zshrc
        else
            echo "Changing existing organization to HAWAII_APP_INSTANCE_FILES_DIR"
            sed -i'.bak' 's|'"export REACT_APP_INSTANCE_FILES_DIR=$existing_organization"'|export REACT_APP_INSTANCE_FILES_DIR="$HAWAII_APP_INSTANCE_FILES_DIR"|g' ~/.zshrc
        fi
    fi
}

function set_instance_directory() {
    local instance_directory_hawaii='export REACT_APP_INSTANCE_FILES_DIR="$HAWAII_APP_INSTANCE_FILES_DIR"'
    local instance_directory_new_orleans='export REACT_APP_INSTANCE_FILES_DIR="$NOIPM_APP_INSTANCE_FILES_DIR"'
    local file_path="../docker-compose.yml"
    local file_content=$(<"$file_path")
    local existing_organization=$(grep "ORG" <<< "$file_content" | cut -d '=' -f 2)
    echo "Setting REACT_APP_INSTANCE_FILES_DIR to..."
    if [[ "$existing_organization" == "HAWAII" ]]; then
        echo "$instance_directory_hawaii"
        echo "$instance_directory_hawaii" >> ~/.zshrc
    else
        echo "$instance_directory_new_orleans"
        echo "$instance_directory_new_orleans" >> ~/.zshrc
    fi

}

function set_new_orleans() {
    local continue_prompt=true
        while $continue_prompt; do
        echo -n "Please input full path to NOIPM instance directory: " 
        read new_orleans_directory
        verify_directory "$new_orleans_directory"
        if [[ $? -eq 0 ]]; then
            local new_orleans="$new_orleans_directory"
            local yes_pattern='y'
            echo -n "Are you sure that $new_orleans is correct (y/n)? "
            read confirm_input
            if [[ "$confirm_input" =~ $yes_pattern ]]; then
                echo "Your path is: $new_orleans"
                sed -i'.bak' '1s|^|'"export NOIPM_APP_INSTANCE_FILES_DIR=\"$new_orleans\""'\n|' ~/.zshrc
                continue_prompt=false
            else
                echo "You have input no..."
            fi
        fi
    done
}

function set_hawaii() {
    local continue_prompt=true
    while $continue_prompt; do
        echo -n "Please input full path to HAWAII instance directory: " 
        read hawaii_directory
        verify_directory "$hawaii_directory"
        if [[ $? -eq 0 ]]; then
            local hawaii="$hawaii_directory"
            local yes_pattern='y'
            echo -n "Are you sure you that $hawaii is correct (y/n)? "
            read confirm_input

            if [[ "$confirm_input" =~ $yes_pattern ]]; then
                echo "Your path is: $hawaii"
                sed -i'.bak' '1s|^|'"export HAWAII_APP_INSTANCE_FILES_DIR=\"$hawaii\""'\n|' ~/.zshrc
                continue_prompt=false
            else
                echo "You have input no..."
            fi
        fi
    done
}

function detect_instance_directory() {
    local instance_directory="$(grep '^export REACT_APP_INSTANCE_FILES_DIR' ~/.zshrc)"
    echo "Detecting if REACT_APP_INSTANCE_FILES_DIR is set in ~/.zshrc"
    if [[ "$instance_directory" ]]; then
        echo "REACT_APP_INSTANCE_FILES_DIR is set"
        change_organization
    else
        echo "REACT_APP_INSTANCE_FILES_DIR is not set"
        set_instance_directory
    fi
}

function detect_new_orleans() {
    local new_orleans="$(grep "NOIPM_APP_INSTANCE_FILES_DIR=" ~/.zshrc)"
    echo "Detecting if NOIPM_APP_INSTANCE_FILES_DIR is set in ~/.zshrc"
    if [[ "$new_orleans" ]]; then
        echo "NOIPM is set"
    else
        echo "NOIPM is not set"
        set_new_orleans
    fi
}

function detect_hawaii() {
    local hawaii="$(grep "HAWAII_APP_INSTANCE_FILES_DIR=" ~/.zshrc)"
    echo "Detecting if HAWAII_APP_INSTANCE_FILES_DIR is set in ~/.zshrc"
    if [[ "$hawaii" ]]; then
        echo "HAWAII is set"
    else
        echo "HAWAII is not set"
        set_hawaii
    fi
}

function change_docker_organization() {
    local file_path="../docker-compose.yml"
    local file_content=$(<"$file_path")
    local existing_organization=$(grep "ORG" <<< "$file_content" | cut -d '=' -f 2)
    echo "$existing_organization"
    echo "Changing ORG variable in docker-compose.yml"

    if [[ "$existing_organization" == "HAWAII" ]]; then
        echo "Changing ORG from HAWAII to NOIPM"
        sed -i'.bak' 's/HAWAII/NOIPM/g' "$file_path"
    else
        echo "Changing ORG from NOIPM to HAWAII"
        sed -i'.bak' 's/NOIPM/HAWAII/g' "$file_path"
    fi
}

function detect_current_directory() {
    local current_directory_path="$(pwd)"
    local parent_directory="$(basename "$current_directory_path")"
    echo "$parent_directory"
    echo "Detecting current directory..."
    if [[ "$parent_directory" == "scripts" ]]; then
        change_docker_organization
    else
        echo "Please run script within the scripts directory of complaint manager"
        exit 1
    fi
}

function remove_docker_backup_file() {
    echo "Removing script generated backup files"
    rm ../docker-compose.yml.bak
}

function stop_docker_process() {
    container_ids=$(docker ps -q)
    echo "Stopping all docker containers..."
    for id in $container_ids; do
        docker stop $id
    done    
}

function source_zshrc_file() {
    echo "Source ~/.zshrc"
    source ~/.zshrc
}

function select_docker_startup() {
    local options=("lose local db data" "persist local db data" "quit") 
    echo "Input an option: "

    select option in "${options[@]}"; do
        case $option in
            "lose local db data")
                echo "Changing directory..."
                cd ..
                echo "Running docker compose down..."
                docker compose down
                echo "Running docker compose up app..."
                docker compose up app
                echo "Done!"
                break
                ;;
            "persist local db data")
                echo "Changing directory..."
                cd ..
                echo "Running docker compose up app..."
                docker compose up app
                echo "Running docker compose run --rm app yarn reseed:db"
                docker compose run --rm app yarn reseed:db
                echo "Done!"
                break
                ;;
            "quit")
                echo "Quitting application..."
                break 2
                ;;
            *) echo "invalid option";;
        esac
    done
}

function detect_environment_variables() {
    detect_instance_directory
    detect_new_orleans
    detect_hawaii
}

function rerun_startup() {
    stop_docker_process
    source_zshrc_file
    select_docker_startup
}

detect_current_directory
detect_environment_variables
remove_docker_backup_file
rerun_startup
