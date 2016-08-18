#!/usr/bin/env python


import csv
import sys


# Name of file
finput = sys.argv[1]


data = {}
# Open the file
with open(finput, 'r') as csvfile:
    # Get file iterator
    reader = csv.DictReader(csvfile)

    for row in reader:
        if row['Risk'] != "None":
            name = str(row['Name'])+'    '+str(row['CVSS'])
            value = str(row['Host'])+':'+str(row['Port'])+"\t("+str(row['Protocol'])+')'
            if data.has_key(name):
                data[name].append(value)
            else:
                data[name] = [value]


# The data is printed and saved in files

foutput = "output.txt"

with open(foutput, "w") as output:
    for d in data:
        print "\n\n"+ d +"\n\n"
        output.write("\n\n"+ d +"\n\n")
        filtered = sorted(set(data[d]))
        for i in filtered:
            print i
            output.write(i+"\n")
