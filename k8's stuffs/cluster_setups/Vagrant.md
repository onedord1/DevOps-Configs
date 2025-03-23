# Vagrant Installation Guide

## For Linux Distributions

1. Add the HashiCorp GPG key:

    ```bash
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    ```

2. Add the HashiCorp repository:

    ```bash
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    ```

3. Update the package list and install Vagrant:

    ```bash
    sudo apt update && sudo apt install vagrant
    ```

## For macOS

1. Tap the HashiCorp repository:

    ```bash
    brew tap hashicorp/tap
    ```

2. Install Vagrant:

    ```bash
    brew install hashicorp/tap/hashicorp-vagrant
    ```

## Using Vagrant

1. Navigate to the directory containing your `Vagrantfile`.

2. Start the Vagrant environment:

    ```bash
    vagrant up
    ```

## Accessing the VMs

You can access the VMs using the following commands:

- Master VM:

    ```bash
    vagrant ssh master
    ```

- Worker 1 VM:

    ```bash
    vagrant ssh worker1
    ```

- Worker 2 VM:

    ```bash
    vagrant ssh worker2
    ```
