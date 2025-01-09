#!/bin/bash

# Tool Name: dirEnum
# Version: 0.1
# Author: securitybong

# Display the banner
function banner() {
    echo "==========================================="
    echo "              dirEnum v0.1                 "
    echo "      The Most Reliable Directory Enum     "
    echo "           Author: securitybong            "
    echo "==========================================="
    echo
}

# Check dependencies and prompt for installation
function check_dependencies() {
    local dependencies=("curl" "xargs" "awk")
    local missing_deps=()

    for cmd in "${dependencies[@]}"; do
        if ! command -v $cmd &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "[-] Missing dependencies detected: ${missing_deps[*]}"
        echo "[?] Would you like to install the missing dependencies? (y/n):"
        read -r install_choice

        if [[ $install_choice == "y" || $install_choice == "Y" ]]; then
            for dep in "${missing_deps[@]}"; do
                echo "[*] Installing $dep..."
                if command -v apt &>/dev/null; then
                    sudo apt update && sudo apt install -y "$dep"
                elif command -v yum &>/dev/null; then
                    sudo yum install -y "$dep"
                elif command -v pacman &>/dev/null; then
                    sudo pacman -Syu --noconfirm "$dep"
                else
                    echo "[-] Unsupported package manager. Please install $dep manually."
                    exit 1
                fi
            done
            echo "[*] Dependencies installed successfully!"
        else
            echo "[-] Cannot continue without installing the required dependencies."
            exit 1
        fi
    fi
}

# Perform directory enumeration
function enumerate() {
    local url="$1"
    local wordlist="$2"
    local threads="$3"
    local output="$4"
    local error_log="errors.log"

    echo "[*] Starting enumeration on $url with $threads threads..."
    echo

    if [ -n "$output" ]; then
        echo "[*] Results will be saved to $output"
        echo "[!] Errors will be logged to $error_log"
    fi

    # Ensure error log is cleared
    > "$error_log"

    # Start enumeration using xargs for parallel processing
    cat "$wordlist" | xargs -P "$threads" -I {} bash -c "
        response=\$(curl -s -o /dev/null -w \"%{http_code}:::%{size_download}\" \"$url/{}\");
        status_code=\$(echo \"\$response\" | awk -F ':::' '{print \$1}')
        size=\$(echo \"\$response\" | awk -F ':::' '{print \$2}')

        # Display only valid status codes and filter out small responses
        if [[ \"\$status_code\" =~ ^(200|301|302)$ && \$size -gt 100 ]]; then
            echo \"$url/{} (\$status_code, Size: \$size bytes)\"
            if [ -n \"$output\" ]; then
                echo \"$url/{} (\$status_code, Size: \$size bytes)\" >> \"$output\"
            fi
        else
            echo \"$url/{} (\$status_code, Size: \$size bytes)\" >> \"$error_log\"
        fi
    "

    echo
    echo "[*] Enumeration completed."
}

# Recursive enumeration
function recursive_enumerate() {
    local base_url="$1"
    local wordlist="$2"
    local threads="$3"
    local output="$4"
    local visited_list="/tmp/dirEnum_visited.txt"

    # Ensure visited list is cleared
    > "$visited_list"

    enumerate "$base_url" "$wordlist" "$threads" "$output"

    # Dynamically find new directories for recursive enumeration
    for subdir in $(cat "$wordlist"); do
        response=$(curl -s -o /dev/null -w "%{http_code}" "$base_url/$subdir/")
        if [[ "$response" == "200" && ! $(grep -Fx "$base_url/$subdir" "$visited_list") ]]; then
            echo "$base_url/$subdir" >> "$visited_list"
            echo "[*] Found subdirectory: $base_url/$subdir/"
            recursive_enumerate "$base_url/$subdir" "$wordlist" "$threads" "$output"
        fi
    done
}

# User prompts
function user_mode() {
    banner

    echo "[?] Please enter the target URL (e.g., http://example.com):"
    read -r url

    if [[ ! $url =~ ^https?:// ]]; then
        echo "Error: Invalid URL format. URL must start with 'http://' or 'https://'."
        exit 1
    fi

    echo "[?] Would you like to perform recursive enumeration? (y/n):"
    read -r recursive

    echo "[?] Please provide the path to the wordlist (or press Enter to use the default):"
    read -r wordlist

    # Use a default wordlist if none provided
    if [ -z "$wordlist" ]; then
        wordlist="/tmp/dirEnum_default_wordlist.txt"
        echo "admin
login
uploads
images
assets
css
js" > "$wordlist"
        echo "[*] Using built-in default wordlist."
    fi

    if [ ! -f "$wordlist" ]; then
        echo "Error: Wordlist file '$wordlist' not found!"
        exit 1
    fi

    echo "[?] How many threads would you like to use? (default: 10):"
    read -r threads
    threads=${threads:-10}

    echo "[?] Would you like to save results to a file? (y/n):"
    read -r save_results

    if [[ $save_results == "y" || $save_results == "Y" ]]; then
        echo "[?] Please specify the output file name:"
        read -r output
        if [ -f "$output" ]; then
            echo "[!] Warning: Output file already exists. Overwrite? (y/n):"
            read -r overwrite
            if [[ $overwrite != "y" && $overwrite != "Y" ]]; then
                echo "[-] Operation cancelled."
                exit 1
            fi
        fi
    else
        output=""
    fi

    check_dependencies

    if [[ $recursive == "y" || $recursive == "Y" ]]; then
        recursive_enumerate "$url" "$wordlist" "$threads" "$output"
    else
        enumerate "$url" "$wordlist" "$threads" "$output"
    fi
}

# Main function
function main() {
    user_mode
}

# Start the main function
main
