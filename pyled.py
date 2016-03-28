import csv, ssh2
f = csv.reader(open('test.csv'), delimiter=";")
next(f)
for row in f:
    if "Host" in row[0]:
        if "Linux" in row[1]:
            print (row[2],row[3],row[4])
#    else:
#        print (row[0])