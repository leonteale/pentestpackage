#!/usr/bin/python

import csv, sys, os


def get_data(ip, check, checker, info):
    filtered = 9999
    opened = 9999
    closed = 9999
    response = 'down'
    os = 'idk'
    ports = []
    with open(finput, 'r') as g:
        for l in g:
            if 'Nmap scan report for' in l:
                if l[21:-1] == ip:
                    for l in g:
                        if 'Host is up' in l:
                            response = 'up'
                        if 'Not shown:' in l:
                            filtered = int(l.split('Not shown: ')[1].split(' ')[0])
                        if '/tcp' in l and 'open' in l and 'Discovered' not in l:
                            port = int(l.split('/tcp')[0])
                            ports.append(port)
                            opened = len(ports)
                        if 'All 65535 scanned ports' in l and l.rsplit(None)[-1] == 'closed':
                            opened = 0
                            filtered = 0
                            closed = 65535
                        elif 'All 65535 scanned ports' in l and l.rsplit(None)[-1] == 'filtered':
                            opened = 0
                            filtered = 65535
                            closed = 0
                        if opened != 0 and filtered != 0:
                            closed = 65535 - (opened + filtered)
                        if 'OS details:' in l:
                            os = l.split('OS details: ')[1].split('\n')[0]
                        elif 'Too many fingerprints match this host' in l:
                            os = None
                        elif 'Aggressive OS guesses:' in l:
                            os = l.split('Aggressive OS guesses: ')[1].split(' (')[0]
                        if 'Nmap scan report for' in l:
                            break
    parsed_data = [ip, opened, filtered, closed, os, response]
    # print parsed_data
    info.append(parsed_data)
    checker += 1
    if checker == checker:
        output(info, finput)


def output(all, dir):
    dir = os.path.dirname(dir)
    if len(dir) == 0:
        file_out = 'data_nmap.csv'
    else:
        file_out = dir + os.path.sep + 'data_nmap.csv'
    with open(file_out, 'wb') as csvfile:
        rows = csv.writer(csvfile)
        rows.writerow(cols)
        rows.writerows(all)


finput = sys.argv[1]
cols = ['Machine', 'Open', 'Filtered', 'Closed', 'OS detection guess', 'ICMP response']
count = 0
counter = 0
data = []
with open(finput) as input_file:
    for line in input_file:
        if 'Nmap scan report for' in line:
            count += 1
with open(finput) as input_file:
    for line in input_file:
        if 'Nmap scan report for' in line:
            machine = line[21:-1]
            get_data(machine, count, counter, data)
