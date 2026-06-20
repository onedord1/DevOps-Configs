stuck executing ansible.cfg file

solve:
    analyze executing that file : ansible-playbook file.name -vvv
    add local user to sudo group and add nopasswd to visudo file