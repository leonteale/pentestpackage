#!/usr/bin/env python

import csv
import sys

# Name of file
finput = sys.argv[1]
foutput = "newfile.csv"

# The items to get
items = ['Risk', 'Name']
itemindex = []
finalList = []

prio = { 'None':0, 'Low':1, 'Medium':2, 'High':4, 'Critical':8 }


# Get the lines in the file
def map_function(line):
    # Extract only needed items
    tmp = [line[i].rstrip() for i in itemindex]
    return [1, tmp]

# Combine same lines
def red_function(tp, finalList):
    for ind, i in enumerate(finalList):
        if i[1] == tp[1]:
            finalList[ind][0] += tp[0]
            return
    else:
        finalList.append(tp)

# Open the file
with open(finput, 'r') as csvfile:
    # Get file iterator
    rows = csv.reader(csvfile)
    
    # Get the title
    title = rows.next()
    itemindex = []
    for i in items:
        if i in title:
            itemindex.append(title.index(i))
        else:
            print i, "is not a column!"
    
    # Get input statistics
    map_result = map(map_function, rows)
    # Reduce same lines
    for i in map_result:
        red_function(i, finalList)

# Open output file
with open(foutput, 'w') as csvfile:
    # Get file to be written
    rows = csv.writer(csvfile)
    rows.writerow(['#'] + items)
    # Sort by risk
    if 'Risk' in items:
        n = items.index('Risk')
        for i in sorted(finalList, key=lambda x: (prio[x[1][n]], x[0]), reverse=True):
            # Change all None to Info
            if (i[1][n] == 'None'):
                i[1][n] = 'Info'
            rows.writerow(i[0:1] + i[1])
    else:
        # Sort by frequency if risk is not present
        for i in sorted(finalList, key=lambda x: x[0], reverse=True):
            rows.writerow(i[0:1] + i[1])

 
