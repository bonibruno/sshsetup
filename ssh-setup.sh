
#!/bin/bash

# Path to the file containing instance hostnames or IP addresses
instances_file="instances.txt"

# SSH username
username="ec2-user"

# Email for SSH key comment
email="boni.bruno@weka.io"

# Check if instances file exists
if [ ! -f "$instances_file" ]; then
    echo "Instances file not found: $instances_file"
instances=()
while IFS= read -r line; do
    instances+=("$line")
done < "$instances_file"

# Generate SSH key pair for each instance
for instance in "${instances[@]}"; do
    echo "Generating SSH key pair on $instance"
    ssh -i ~/.ssh/your-ssh-access-key -o StrictHostKeyChecking=no $username@$instance "ssh-keygen -t rsa -b 4096 -C \"$email\" -f ~/.ssh/id_rsa -N ''"
done

for src_instance in "${instances[@]}"; do
    for dest_instance in "${instances[@]}"; do
        if [ "$src_instance" != "$dest_instance" ]; then
            echo "Copying public key from $src_instance to $dest_instance"
            ssh -i ~/.ssh/your-ssh-access-key -o StrictHostKeyChecking=no "$username@$src_instance" "cat ~/.ssh/id_rsa.pub" | ssh -i ~/.ssh/your-ssh-access-key -o StrictHostKeyChecking=no "$username@$dest_instance" "cat >> ~/.ssh/authorized_keys"
        fi
    done
done

echo "SSH key setup complete"
