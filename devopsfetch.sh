#!/bin/bash

# Log file to store the output of the script
LOG_FILE="/var/log/devopsfetch.log"

# Function to display the usage instructions for the script
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

# Function to print active ports and their details
print_ports() {
    if [ -z "$1" ]; then
        # Print header for active ports section
        echo "Active Ports and Services:" | tee -a $LOG_FILE
        echo "+-------+-----------------+------------------------------+------------------+" | tee -a $LOG_FILE
        echo "| Port  | Address         | Process                      | User             |" | tee -a $LOG_FILE
        echo "+-------+-----------------+------------------------------+------------------+" | tee -a $LOG_FILE

        # Display active ports and associated processes
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
        # Print header for specific port details
        echo "Details for Port $port:" | tee -a $LOG_FILE
        echo "+-------+-----------------+------------------------------+------------------+" | tee -a $LOG_FILE
        echo "| Port  | Address         | Process                      | User             |" | tee -a $LOG_FILE
        echo "+-------+-----------------+------------------------------+------------------+" | tee -a $LOG_FILE

        # Display details for a specific port
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

# Function to print Docker images and containers
print_docker() {
    if [ -z "$1" ]; then
        echo "Docker Images:" | tee -a $LOG_FILE
        # Define maximum column widths for Docker images
        local repo_width=18
        local tag_width=12
        local id_width=15
        local created_width=40

        # Print table header for Docker images
        echo "+------------------+--------------+-----------------+----------------------+" | tee -a $LOG_FILE
        echo "| REPOSITORY       | TAG          | IMAGE ID        | CREATED              |" | tee -a $LOG_FILE
        echo "+------------------+--------------+-----------------+----------------------+" | tee -a $LOG_FILE

        # Print Docker images
        docker images --format "{{.Repository}}|{{.Tag}}|{{.ID}}|{{.CreatedAt}}" | while IFS='|' read -r repo tag id created; do
            printf "| %-${repo_width}.${repo_width}s | %-${tag_width}.${tag_width}s | %-${id_width}.${id_width}s | %-${created_width}.${created_width}s |\n" "$repo" "$tag" "$id" "$created"
            echo "+------------------+--------------+-----------------+----------------------+" | tee -a $LOG_FILE
        done | tee -a $LOG_FILE

        echo "" | tee -a $LOG_FILE
        echo "Docker Containers:" | tee -a $LOG_FILE

        # Define maximum column widths for Docker containers
        local cid_width=18
        local image_width=15
        local cmd_width=20
        local created_cont_width=20
        local status_width=40

        # Print table header for Docker containers
        echo "+------------------+-----------------+----------------------+----------------------+----------------------+" | tee -a $LOG_FILE
        echo "| CONTAINER ID     | IMAGE           | COMMAND              | CREATED              | STATUS               |" | tee -a $LOG_FILE
        echo "+------------------+-----------------+----------------------+----------------------+----------------------+" | tee -a $LOG_FILE

        # Print Docker containers
        docker ps -a --format "{{.ID}}|{{.Image}}|{{.Command}}|{{.CreatedAt}}|{{.Status}}" | while IFS='|' read -r cid image cmd created status; do
            printf "| %-${cid_width}.${cid_width}s | %-${image_width}.${image_width}s | %-${cmd_width}.${cmd_width}s | %-${created_cont_width}.${created_cont_width}s | %-${status_width}.${status_width}s |\n" "$cid" "$image" "$cmd" "$created" "$status"
            echo "+------------------+-----------------+----------------------+----------------------+----------------------+" | tee -a $LOG_FILE
        done | tee -a $LOG_FILE
    else
        # Print details for a specific Docker container
        echo "Details for Container $1:" | tee -a $LOG_FILE
        docker inspect $1 | tee -a $LOG_FILE
    fi
}

# Function to print Nginx domains and proxied addresses
print_nginx() {
    if [ -z "$1" ]; then
        echo "Nginx Domains and Proxied Addresses:" | tee -a $LOG_FILE

        # Define maximum column widths for Nginx domains and proxies
        local domain_width=30
        local proxy_width=50

        # Print table header for Nginx domains
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
        # Print detailed configuration for a specific Nginx domain
        echo "Configuration for Domain $1:" | tee -a $LOG_FILE
        sudo nginx -T 2>/dev/null | awk -v domain="$1" '
            BEGIN {
                in_block=0;
                print "+-----------------+------------------------------------------------+";
                print "| Field           | Value                                          |";
                print "+-----------------+------------------------------------------------+";
            }
            /server_name/ {
                if ($2 == domain) {
                    in_block=1;
                }
            }
            in_block && /server {/ {
                in_block=2;
            }
            in_block == 2 && /}/ {
                in_block=0;
            }
            in_block == 2 {
                print "| " $1 " " $2 " | " $0 " |";
            }
            END {
                print "+-----------------+------------------------------------------------+";
            }
        ' | tee -a $LOG_FILE
    fi
}

# Function to print user details and last login times
print_users() {
    if [ -z "$1" ]; then
        echo "Users and Last Login Times:" | tee -a $LOG_FILE
        echo "+------------------+---------------------+" | tee -a $LOG_FILE
        echo "| User             | Last Login Time     |" | tee -a $LOG_FILE
        echo "+------------------+---------------------+" | tee -a $LOG_FILE

        # Print users and last login times
        who | awk '{printf "| %-16s | %-19s |\n", $1, $4 " " $5}' | tee -a $LOG_FILE
        echo "+------------------+---------------------+" | tee -a $LOG_FILE
    else
        # Print detailed information about a specific user
        echo "Details for User $1:" | tee -a $LOG_FILE
        id $1 | tee -a $LOG_FILE
        echo "Last Login Time:" | tee -a $LOG_FILE
        last $1 | head -n 10 | tee -a $LOG_FILE
    fi
}

# Function to print activities within a specified time range
print_time_range() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Please specify both start and end times." | tee -a $LOG_FILE
        return
    fi

    echo "Activities from $1 to $2:" | tee -a $LOG_FILE
    echo "+------------------------+----------------------------------------------+" | tee -a $LOG_FILE
    echo "| Time                   | Activity                                     |" | tee -a $LOG_FILE
    echo "+------------------------+----------------------------------------------+" | tee -a $LOG_FILE

    # Print activities within the time range
    # For demonstration, we're using the `dmesg` command. Replace with actual commands as needed.
    dmesg --ctime | awk -v start="$1" -v end="$2" '
        $0 ~ start, $0 ~ end {
            printf "| %-22s | %-46s |\n", $1, substr($0, index($0, $2));
        }
        END {
            print "+------------------------+----------------------------------------------+";
        }
    ' | tee -a $LOG_FILE
}

# Main script logic
while [ "$#" -gt 0 ]; do
    case "$1" in
        -p|--port)
            shift
            print_ports "$1"
            ;;
        -d|--docker)
            shift
            print_docker "$1"
            ;;
        -n|--nginx)
            shift
            print_nginx "$1"
            ;;
        -u|--users)
            shift
            print_users "$1"
            ;;
        -t|--time)
            shift
            print_time_range "$1" "$2"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Invalid option: $1" | tee -a $LOG_FILE
            print_usage
            exit 1
            ;;
    esac
    shift
done
