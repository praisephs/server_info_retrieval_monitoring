#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -p, --port [port_number]       Display active ports or detailed information about a specific port"
    echo "  -d, --docker [container_name]  List Docker images and containers or detailed information about a specific container"
    echo "  -n, --nginx [domain]           Display Nginx domains and their ports or detailed configuration information for a specific domain"
    echo "  -u, --users [username]         List users and their last login times or detailed information about a specific user"
    echo "  -t, --time [time_range]        Display activities within a specified time range"
    echo "  -h, --help                     Display this help message"
}

print_ports() {
    if [ -z "$1" ]; then
        echo "Active Ports and Services:" | tee -a $LOG_FILE
        echo "+-------+-----------------+------------------------------+------------------+" | tee -a $LOG_FILE
        echo "| Port  | Address         | Process                      | User             |" | tee -a $LOG_FILE
        echo "+-------+-----------------+------------------------------+------------------+" | tee -a $LOG_FILE

        sudo ss -tulnp | awk '
            NR > 1 {
                split($5, addr, ":")
                port = addr[2] ? addr[2] : $5
                address = (addr[1] ? addr[1]":"addr[2] : $5)
                process_info = $7
                split(process_info, proc, ",")
                pid_info = proc[2]
                cmd = substr(pid_info, index(pid_info, "=") + 1)
                gsub(/[^0-9]/, "", cmd)

                # Get the user associated with the PID
                user_cmd = "ps -o user= -p " cmd " 2>/dev/null"
                user_cmd | getline user
                close(user_cmd)

                printf "| %-5s | %-15s | %-28s | %-16s |\n", port, address, process_info, user
                print "+-------+-----------------+------------------------------+------------------+"
            }
        ' | tee -a $LOG_FILE
    else
        local port=$1
        echo "Details for Port $port:" | tee -a $LOG_FILE
        echo "+-------+-----------------+------------------------------+------------------+" | tee -a $LOG_FILE
        echo "| Port  | Address         | Process                      | User             |" | tee -a $LOG_FILE
        echo "+-------+-----------------+------------------------------+------------------+" | tee -a $LOG_FILE

        sudo ss -tulnp | awk -v port="$port" '
            NR > 1 {
                split($5, addr, ":")
                current_port = addr[2] ? addr[2] : $5
                address = (addr[1] ? addr[1]":"addr[2] : $5)
                process_info = $7
                split(process_info, proc, ",")
                pid_info = proc[2]
                cmd = substr(pid_info, index(pid_info, "=") + 1)
                gsub(/[^0-9]/, "", cmd)

                # Get the user associated with the PID
                user_cmd = "ps -o user= -p " cmd " 2>/dev/null"
                user_cmd | getline user
                close(user_cmd)

                if (current_port == port) {
                    printf "| %-5s | %-15s | %-28s | %-16s |\n", current_port, address, process_info, user
                    print "+-------+-----------------+------------------------------+------------------+"
                }
            }
        ' | tee -a $LOG_FILE
    fi
}



# print_ports() {
#     if [ -z "$1" ]; then
#         echo "Active Ports and Services:" | tee -a $LOG_FILE
#         echo "+-------+-----------------+------------------------------+" | tee -a $LOG_FILE
#         echo "| Port  | Address         | Process                      |" | tee -a $LOG_FILE
#         echo "+-------+-----------------+------------------------------+" | tee -a $LOG_FILE

#         sudo ss -tulnp | awk '
#             NR > 1 {
#                 split($5, addr, ":")
#                 port = addr[2] ? addr[2] : $5
#                 address = (addr[1] ? addr[1]":"addr[2] : $5)
#                 process = $7
#                 printf "| %-5s | %-15s | %-28s |\n", port, address, process
#                 print "+-------+-----------------+------------------------------+"
#             }
#         ' | tee -a $LOG_FILE
#     else
#         local port=$1
#         echo "Details for Port $port:" | tee -a $LOG_FILE
#         echo "+-------+-----------------+------------------------------+" | tee -a $LOG_FILE
#         echo "| Port  | Address         | Process                      |" | tee -a $LOG_FILE
#         echo "+-------+-----------------+------------------------------+" | tee -a $LOG_FILE

#         sudo ss -tulnp | awk -v port="$port" '
#             NR > 1 {
#                 split($5, addr, ":")
#                 current_port = addr[2] ? addr[2] : $5
#                 address = (addr[1] ? addr[1]":"addr[2] : $5)
#                 process = $7
#                 if (current_port == port) {
#                     printf "| %-5s | %-15s | %-28s |\n", current_port, address, process
#                     print "+-------+-----------------+------------------------------+"
#                 }
#             }
#         ' | tee -a $LOG_FILE
#     fi
# }



print_docker() {
    if [ -z "$1" ]; then
        echo "Docker Images:" | tee -a $LOG_FILE
        # Define maximum column widths
        local repo_width=18
        local tag_width=12
        local id_width=15
        local created_width=40

        # Print table header
        echo "+------------------+--------------+-----------------+----------------------+"
        echo "| REPOSITORY       | TAG          | IMAGE ID        | CREATED              |"
        echo "+------------------+--------------+-----------------+----------------------+"

        # Print Docker images
        docker images --format "{{.Repository}}|{{.Tag}}|{{.ID}}|{{.CreatedAt}}" | while IFS='|' read -r repo tag id created; do
            printf "| %-${repo_width}.${repo_width}s | %-${tag_width}.${tag_width}s | %-${id_width}.${id_width}s | %-${created_width}.${created_width}s |\n" "$repo" "$tag" "$id" "$created"
            echo "+------------------+--------------+-----------------+----------------------+"
        done | tee -a $LOG_FILE

        echo "" | tee -a $LOG_FILE
        echo "Docker Containers:" | tee -a $LOG_FILE

        # Define maximum column widths
        local cid_width=18
        local image_width=15
        local cmd_width=20
        local created_cont_width=20
        local status_width=40

        # Print table header
        echo "+------------------+-----------------+----------------------+----------------------+----------------------+" | tee -a $LOG_FILE
        echo "| CONTAINER ID     | IMAGE           | COMMAND              | CREATED              | STATUS               |" | tee -a $LOG_FILE
        echo "+------------------+-----------------+----------------------+----------------------+----------------------+" | tee -a $LOG_FILE

        # Print Docker containers
        docker ps -a --format "{{.ID}}|{{.Image}}|{{.Command}}|{{.CreatedAt}}|{{.Status}}" | while IFS='|' read -r cid image cmd created status; do
            printf "| %-${cid_width}.${cid_width}s | %-${image_width}.${image_width}s | %-${cmd_width}.${cmd_width}s | %-${created_cont_width}.${created_cont_width}s | %-${status_width}.${status_width}s |\n" "$cid" "$image" "$cmd" "$created" "$status"
            echo "+------------------+-----------------+----------------------+----------------------+----------------------+" | tee -a $LOG_FILE
        done | tee -a $LOG_FILE
    else
        echo "Details for Container $1:" | tee -a $LOG_FILE
        docker inspect $1 | tee -a $LOG_FILE
    fi
}



print_nginx() {
    if [ -z "$1" ]; then
        echo "Nginx Domains and Proxied Addresses:" | tee -a $LOG_FILE

        # Define maximum column widths
        local domain_width=30
        local proxy_width=50

        # Print table header
        echo "+------------------------------+--------------------------------------------------+" | tee -a $LOG_FILE
        echo "| Domain                       | Proxied Address                                  |" | tee -a $LOG_FILE
        echo "+------------------------------+--------------------------------------------------+" | tee -a $LOG_FILE

        # Extract and format Nginx configuration
        sudo nginx -T 2>/dev/null | awk '
            BEGIN {
                domain=""; proxy=""; domain_flag=0; proxy_flag=0;
            }
            /server_name/ {
                if (domain != "" && proxy != "") {
                    printf "| %-30s | %-50s |\n", domain, proxy;
                }
                domain=$2; domain_flag=1; proxy=""; proxy_flag=0;
            }
            /proxy_pass/ {
                proxy=$2; proxy_flag=1;
            }
            /}/ {
                if (domain_flag && proxy_flag) {
                    printf "| %-30s | %-50s |\n", domain, proxy;
                    domain=""; proxy=""; domain_flag=0; proxy_flag=0;
                } else if (domain_flag) {
                    printf "| %-30s | %-50s |\n", domain, "";
                    domain=""; domain_flag=0;
                }
            }
            END {
                if (domain_flag) {
                    printf "| %-30s | %-50s |\n", domain, "";
                }
                print "+------------------------------+--------------------------------------------------+";
            }
        ' | tee -a $LOG_FILE

    else
        echo "Configuration for Domain $1:" | tee -a $LOG_FILE
        sudo nginx -T 2>/dev/null | awk -v domain="$1" '
            BEGIN {
                in_block=0;
                print "+-----------------+------------------------------------------------+";
                print "| Field           | Value                                          |";
                print "+-----------------+------------------------------------------------+";
            }
            $0 ~ "server_name" && $0 ~ domain {
                in_block=1;
                printf "| %-15s | %-46s |\n", "Domain", domain;
                print "+-----------------+------------------------------------------------+";
            }
            in_block {
                if ($0 ~ "proxy_pass") {
                    split($0, arr, " ");
                    printf "| %-15s | %-46s |\n", "Proxy Pass", arr[2];
                    print "+-----------------+------------------------------------------------+";
                }
                if ($0 ~ "^}") {
                    in_block=0;
                }
            }
        ' | tee -a $LOG_FILE
    fi
}



print_users() {
    if [ -z "$1" ]; then
        echo "Users and Last Login Times:" | tee -a $LOG_FILE

        # Define column widths
        local user_width=20
        local last_login_width=30

        # Print table header
        echo "+----------------------+------------------------------+" | tee -a $LOG_FILE
        echo "| User                 | Last Login Time              |" | tee -a $LOG_FILE
        echo "+----------------------+------------------------------+" | tee -a $LOG_FILE

        # Extract and format user login information, filtering out unwanted entries
        lastlog | awk -v user_width="$user_width" -v last_login_width="$last_login_width" '
            NR==1 { next }  # Skip header
            {
                user = $1
                last_login = $4" "$5" "$6" "$7

                # Filter out lines where last_login is "in**" or empty
                if (last_login !~ /in\*\*/ && last_login != "") {
                    printf "| %-"user_width"s | %-"last_login_width"s |\n", user, last_login
                    print "+----------------------+------------------------------+"
                }
            }
            END {
                # Ensure the last line is printed
                print "+----------------------+------------------------------+"
            }
        ' | tee -a $LOG_FILE

    else
        echo "Details for User $1:" | tee -a $LOG_FILE
        user_details=$(getent passwd "$1")

        if [ -n "$user_details" ]; then
            echo "$user_details" | awk -F: '
                BEGIN {
                    print "+-----------------+------------------------------------------------+";
                    print "| Field           | Value                                          |";
                    print "+-----------------+------------------------------------------------+";
                }
                {
                    printf "| %-15s | %-46s |\n", "Username", $1;
                    printf "| %-15s | %-46s |\n", "Password", $2;
                    printf "| %-15s | %-46s |\n", "User ID", $3;
                    printf "| %-15s | %-46s |\n", "Group ID", $4;
                    printf "| %-15s | %-46s |\n", "GECOS", $5;
                    printf "| %-15s | %-46s |\n", "Home Directory", $6;
                    printf "| %-15s | %-46s |\n", "Shell", $7;
                    print "+-----------------+------------------------------------------------+";
                }
            ' | tee -a $LOG_FILE

            echo "Last Login Time:" | tee -a $LOG_FILE
            lastlog -u $1 | awk -v user_width="$user_width" -v last_login_width="$last_login_width" '
                NR==1 { next }  # Skip header
                {
                    user = $1
                    last_login = $4" "$5" "$6" "$7

                    # Filter out lines where last_login is "in**" or empty
                    if (last_login !~ /in\*\*/ && last_login != "") {
                        printf "| %-"user_width"s | %-"last_login_width"s |\n", user, last_login
                        print "+----------------------+------------------------------+"
                    }
                }
                END {
                    # Ensure the last line is printed
                    print "+----------------------+------------------------------+"
                }
            ' | tee -a $LOG_FILE
        else
            echo "User $1 not found." | tee -a $LOG_FILE
        fi
    fi
}


print_time_range() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Please provide both start and end times." | tee -a $LOG_FILE
        echo "Usage: sudo ./devopsfetch.sh --time <start_time> <end_time>" | tee -a $LOG_FILE
        return
    fi

    local start_time="$1"
    local end_time="$2"

    echo "System Activities from $start_time to $end_time:" | tee -a $LOG_FILE

    journalctl --since="$start_time" --until="$end_time" --no-pager | awk '
        BEGIN {
            print "+-------------------------+----------------------+----------------------------------------------------+";
            print "| Timestamp               | Process              | Message                                            |";
            print "+-------------------------+----------------------+----------------------------------------------------+";
        }
        {
            timestamp = $1 " " $2 " " $3;
            process = $4;
            $1 = $2 = $3 = $4 = "";
            message = $0;
            printf "| %-23s | %-20s | %-50s |\n", timestamp, process, message;
            print "+-------------------------+----------------------+----------------------------------------------------+";
        }
    ' | tee -a $LOG_FILE
}


# print_usage() {
#     echo "Usage: $0 [OPTIONS]"
#     echo "Options:"
#     echo "  -p, --port [port_number]     Display active ports and services"
#     echo "  -d, --docker [container_name] Display Docker images and containers"
#     echo "  -n, --nginx [domain]         Display Nginx domains and their proxied addresses"
#     echo "  -u, --users [username]       Display users and their last login times"
#     echo "  -t, --time <start_time> <end_time> Display system activities within a time range"
#     echo "  -h, --help                   Display this help message"
# }

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--port) shift; print_ports $1; exit 0 ;;
        -d|--docker) shift; print_docker $1; exit 0 ;;
        -n|--nginx) shift; print_nginx $1; exit 0 ;;
        -u|--users) shift; print_users $1; exit 0 ;;
        -t|--time) shift; print_time_range "$1" "$2"; exit 0 ;;
        -h|--help) print_usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; print_usage; exit 1 ;;
    esac
    shift
done

print_usage

# print_time_range() {
#     if [ -z "$1" ]; then
#         echo "Please provide a time range." | tee -a $LOG_FILE
#         return
#     fi
#     echo "Activities within time range $1:" | tee -a $LOG_FILE
#     sudo journalctl --since "$1" | tee -a $LOG_FILE
# }

# while [[ "$#" -gt 0 ]]; do
#     case $1 in
#         -p|--port) shift; print_ports $1; exit 0 ;;
#         -d|--docker) shift; print_docker $1; exit 0 ;;
#         -n|--nginx) shift; print_nginx $1; exit 0 ;;
#         -u|--users) shift; print_users $1; exit 0 ;;
#         -t|--time) shift; print_time_range "$1"; exit 0 ;;
#         -h|--help) print_usage; exit 0 ;;
#         *) echo "Unknown parameter passed: $1"; print_usage; exit 1 ;;
#     esac
#     shift
# done

# print_usage






# # Function to display help message
# display_help() {
#     echo "Usage: $0 [options]"
#     echo ""
#     echo "Options:"
#     echo "  -p, --port          Display all active ports, users, and services"
#     echo "  -p <port_number>    Provide detailed information about a specific port"
#     echo "  -u, --users         List all users and their last login times"
#     echo "  -u <username>       Provide detailed information about a specific user"
#     echo "  -n, --nginx         Display Nginx configurations"
#     echo "  -n <domain>         Provide detailed configuration information for a specific domain"
#     echo "  -d, --docker        Display Docker images and container statuses"
#     echo "  -d <container_id>   Provide detailed information about a specific container"
#     echo "  -t, --time          Display activities within a specified time range"
#     echo "  -h, --help          Display this help message"
# }

# # Function to get Nginx configurations and format them
# get_nginx_configurations() {
#     echo "Nginx Domains and Ports:"
#     sudo nginx -T 2>/dev/null | awk '
#     BEGIN {
#         RS = "\n\n"
#         print "Port\tDomain"
#         print "----\t------"
#     }
#     /server {/ {
#         domain = "N/A"
#         port = "N/A"
#         for (i = 1; i <= NF; i++) {
#             if ($i == "server_name") {
#                 domain = $(i + 1)
#                 if (domain ~ /;/) gsub(/;/, "", domain)
#             }
#             if ($i == "listen") {
#                 port = $(i + 1)
#                 if (port ~ /;/) gsub(/;/, "", port)
#             }
#         }
#         if (domain != "N/A" || port != "N/A") {
#             print port "\t" domain
#         }
#     }'
# }

# # Function to get detailed configuration information for a specific domain
# get_nginx_domain_details() {
#     local domain=$1
#     echo "Detailed Configuration for Domain $domain:"
#     sudo nginx -T 2>/dev/null | awk -v domain="$domain" '
#     BEGIN {found = 0}
#     /server {/ {server_block = ""}
#     {
#         server_block = server_block "\n" $0
#     }
#     /server_name.*domain/ {found = 1}
#     found && /^\s*}$/ {
#         print server_block
#         exit
#     }
#     '
# }

# # Function to get active ports with user and service information
# get_active_ports() {
#     echo "Active Ports, Users, and Services:"
#     printf "%-10s %-15s %-15s\n" "Port" "User" "Service"
#     ss -tuln | grep LISTEN | awk '
#     NR>1 {
#         split($5, address, ":")
#         port = address[2]
#         service = $1
#         if (port ~ /^[0-9]+$/) {
#             cmd = "lsof -i :" port " | awk \047NR>1{print $3}\047"
#             cmd | getline user
#             close(cmd)
#             printf "%-10s %-15s %-15s\n", port, user, service
#         }
#     }'
# }


# # Function to get detailed information about a specific port
# list_all_users() {
#     local port=$1
#     echo "Detailed Information for Port $port:"
#     ss -tuln | grep ":$port "
# }


# # Function to list all users and their last login times
# list_all_users() {
#     echo "All Users and Last Login Times:"
#     printf "%-20s %-20s\n" "User" "Last Login"

#     # List all non-system users (UID >= 1000) and loop through each
#     getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' | while read -r user; do
#         # Get last login information using 'lastlog'
#         last_login=$(lastlog -u "$user" 2>/dev/null | awk 'NR==2 {print $4, $5, $6, $7}')
        
#         # Handle cases where last_login might be malformed or empty
#         if [ -z "$last_login" ]; then
#             last_login="Never logged in"
#         elif [[ "$last_login" == "in**" ]]; then
#             last_login="Invalid or Malformed Entry"
#         fi
        
#         # Print user and last login information
#         printf "%-20s %-20s\n" "$user" "$last_login"
#     done
# }


# # Function to get detailed information about a specific user
# get_user_details() {
#     local user=$1
#     echo "Detailed Information for User $user:"

#     # Get last login information
#     echo -e "\nLast Login Information:"
#     printf "%-20s %-20s %-20s %-20s\n" "User" "TTY" "IP" "Last Login"
#     last -F | grep "^$user" | awk '{ printf "%-20s %-20s %-20s %-20s\n", $1, $2, $3, $4 }' || echo "No login information found for user $user."

#     # Get user account details
#     echo -e "\nUser Account Details:"
#     printf "%-20s %-20s\n" "Field" "Value"
#     id $user 2>/dev/null | awk -F'[ =()]' '{ printf "%-20s %-20s\n", "User ID", $2; printf "%-20s %-20s\n", "Group ID", $4; printf "%-20s %-20s\n", "Groups", $6 }' || echo "No details found for user $user."

#     # Check for user in /etc/passwd
#     echo -e "\nUser Information from /etc/passwd:"
#     printf "%-20s %-20s\n" "Field" "Value"
#     grep "^$user:" /etc/passwd | awk -F: '{ printf "%-20s %-20s\n", "Username", $1; printf "%-20s %-20s\n", "User ID", $3; printf "%-20s %-20s\n", "Group ID", $4; printf "%-20s %-20s\n", "Home Directory", $6; printf "%-20s %-20s\n", "Shell", $7 }' || echo "No entry found in /etc/passwd for user $user."
# }

# # Function to get Docker images
# get_docker_images() {
#     echo "Docker Images:"
#     docker images
# }

# # Function to get Docker container statuses
# get_docker_containers() {
#     echo "Docker Containers:"
#     docker ps -a
# }

# # Function to get detailed information about a specific Docker container
# get_container_details() {
#     local container=$1
#     if command -v jq > /dev/null 2>&1; then
#         echo "Detailed Information for Container $container:"
#         docker inspect $container | jq .
#     else
#         echo "Error: jq is not installed. Please install jq to view detailed container information."
#         exit
#     fi
# }

# # Function to display activities within a specified time range
# get_activities_within_time_range() {
#     local start_time=$1
#     local end_time=$2
#     echo "Activities from $start_time to $end_time:"
#     journalctl --since="$start_time" --until="$end_time"
# }

# # Log file
# LOGFILE="/var/log/devopsfetch.log"

# # Main script logic
# if [[ $# -eq 0 ]]; then
#     # No arguments, collect and log system information
#     {
#         echo "=== devopsfetch - $(date) ==="
#         get_active_ports
#         echo ""
#         get_user_logins
#         echo ""
#         get_nginx_configurations
#         echo ""
#         get_docker_images
#         echo ""
#         get_docker_containers
#         echo "=============================="
#     } >> "$LOGFILE"
# else
#     # Parse command-line arguments
#     case $1 in
#         -p|--port)
#             if [[ -z $2 ]]; then
#                 # Display all active ports
#                 get_active_ports
#             else
#                 # Provide detailed information about a specific port
#                 get_port_details $2
#             fi
#             ;;
#         -u|--users)
#             if [[ -z $2 ]]; then
#                 # List all users and their last login times
#                 list_all_users
#             else
#                 # Provide detailed information about a specific user
#                 get_user_details $2
#             fi
#             ;;
#         -n|--nginx)
#             if [[ -z $2 ]]; then
#                 # Display Nginx configurations
#                 get_nginx_configurations
#             else
#                 # Provide detailed configuration information for a specific domain
#                 get_nginx_domain_details $2
#             fi
#             ;;
#         -d|--docker)
#             if [[ -z $2 ]]; then
#                 # Display Docker images and container statuses
#                 get_docker_images
#                 echo ""
#                 get_docker_containers
#             else
#                 # Provide detailed information about a specific container
#                 get_container_details $2
#             fi
#             ;;
#         -t|--time)
#             if [[ -z $2 ]] || [[ -z $3 ]]; then
#                 echo "Error: Time range is missing"
#                 display_help
#             else
#                 # Display activities within a specified time range
#                 get_activities_within_time_range $2 $3
#             fi
#             ;;
#         -h|--help)
#             display_help
#             ;;
#         *)
#             echo "Invalid option: $1"
#             display_help
#             ;;
#     esac
# fi

# echo "Script execution completed"

