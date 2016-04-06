import csv
import os
import unixpackage
import paramiko
import pycrypto
import ecdsa

def deploy(file):
    f = csv.reader(open(file), delimiter=";")
    next(f)
    for row in f:
        hostip = row[1]
        login = row[2]
        passw = row[3]
        sshport = row[4]
        for i in row[1]:
            ssh = paramiko.SSHClient()
            ssh.connect(host = i,
                    login = login,
                    passw = passw,
                    port = sshport)
            for p in row[5]:
                COMMAND = unixpackage.install([p], polite=True)
                ssh.exec_command(COMMAND, sudo=True)