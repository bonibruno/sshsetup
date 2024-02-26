#!/bin/bash
# This scripts requires that your access key be installed on each instance, this key will initially be used to generate unique keys on each instance and then copy these unique keys across your entire cluster so each instance can ssh to any other instance using it's local ssh key.

# Path to the file containing instance hostnames or IP addresses you want passwordless ssh setup.
instances_file="instances.txt"

# SSH username
username="ec2-user"

# Email for SSH key comment
email="name@your-email.com"

# Check if instances file exists
if [ ! -f "$instances_file" ]; then
    echo "Instances file not found: $instances_file"
    exit 1
fi

# Read instance hostnames or IP addresses from the file into an array
instances=()
while IFS= read -r line; do
    instances+=("$line")
done < "$instances_file"

# Check SSH availability for each instance
for instance in "${instances[@]}"; do
    if ! ssh -q -o BatchMode=yes -i ~/.ssh/your-access-ssh-key -o StrictHostKeyChecking=no "$username@$instance" exit; then
        echo "SSH not available for $instance"
        exit 1
    fi
done

# Generate SSH key pair for each instance
for instance in "${instances[@]}"; do
    echo "Generating SSH key pair on $instance"
    if ssh -i ~/.ssh/your-access-ssh-key -o StrictHostKeyChecking=no "$username@$instance" "ssh-keygen -t rsa -b 4096 -C \"$email\" -f ~/.ssh/id_rsa -N ''"; then
        echo "SSH key pair generated successfully on $instance"
    else
        echo "Failed to generate SSH key pair on $instance"
        exit 1
    fi
done

# Initialize array to keep track of copied keys
declare -A copied_keys

# Copy public keys from each instance to itself and all other instances
for src_instance in "${instances[@]}"; do
    for dest_instance in "${instances[@]}"; do
        if [ "$src_instance" != "$dest_instance" ]; then
            echo "Copying public key from $src_instance to $dest_instance"
            if ssh -i ~/.ssh/your-access-ssh-key -o StrictHostKeyChecking=no "$username@$src_instance" "cat ~/.ssh/id_rsa.pub" | ssh -i ~/.ssh/your-access-ssh-key -o StrictHostKeyChecking=no "$username@$dest_instance" "cat >> ~/.ssh/authorized_keys"; then
                echo "Public key copied successfully from $src_instance to $dest_instance"
            else
                echo "Failed to copy public key from $src_instance to $dest_instance"
            fi
        fi
    done
    # Copy public key from each instance to itself
    echo "Copying public key from $src_instance to itself"
    if ssh -i ~/.ssh/your-access-ssh-key -o StrictHostKeyChecking=no "$username@$src_instance" "cat ~/.ssh/id_rsa.pub" | ssh -i ~/.ssh/your-access-ssh-key -o StrictHostKeyChecking=no "$username@$src_instance" "cat >> ~/.ssh/authorized_keys"; then
        echo "Public key copied successfully from $src_instance to itself"
    else
        echo "Failed to copy public key from $src_instance to itself"
    fi
done

echo "SSH key setup complete"
