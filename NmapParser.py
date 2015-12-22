#!/usr/bin/env python

import csv
import sys

# Name of file
finput = sys.argv[1]
fout_suffix = "_nmap.csv"
cols = ['PORT', 'STATE', 'SERVICE', 'VERSION']

def getIP(line):
    if not line:    return None
    if 'Nmap scan report for' in line:
        return line[21:-1]
    return ''

def findHead(line):
    if not line:  return False
    for i in cols:
        if i not in line:
            return False
    return True

def parseData(line):
    data = []
    for i in line.split():
        if i.isspace(): continue
        if len(data) == 0:
            for j in i.strip().split('/'):
                data.append(j)
        else:
            data.append(i.strip())
        
    # Get the version type
    i = 4
    version = ''
    while i < len(data):
        version += ' ' + data[i]
        data.remove(data[i])
    if version:
        data.append(version.strip())

    return data

def checkLine(line):
    for i in line:
        if i.isdigit(): continue
        if i == '/':    return True
        return False

# Open the file
with open(finput, 'r') as fin:
    while True:
        # Get IP address
        while True:
            ip = getIP(fin.readline())
            if ip != '':    break
        if ip == None:
            break
        
        # Get first column from port scan
        while not findHead(fin.readline()):
            pass
            
        # Get all data
        data = []
        while True:
            line = fin.readline()
            # All lines stating with '|' will be ignored
            if line[0] == '|':  continue
            
            # Check if line is invalid
            if not checkLine(line):   break
            
            # Record the line
            data.append(parseData(line))

        # Output into file
        with open(ip + fout_suffix, 'wb') as csvfile:
            # Get file to be written
            rows = csv.writer(csvfile)
            cols.insert(1, 'PROTOCOL')
            rows.writerow(cols)
            cols.remove('PROTOCOL')
            # Print all the rows
            rows.writerows(data)
