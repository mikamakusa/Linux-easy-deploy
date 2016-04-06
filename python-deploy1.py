import csv
import os
import unixpackage
from pssh import ParallelSSHClient

def deploy(file):
    f = csv.reader(open(file), delimiter=";")
    next(f)
    for row in f:
        hostip = row[1]
        login = row[2]
        passw = row[3]
        sshport = row[4]
        for i in row[1]:
            client = ParallelSSHClient(i)
            for p in row[5]:
                COMMAND = unixpackage.install([p], polite=True)
                client.run_command(COMMAND, sudo=True)
