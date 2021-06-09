#!/usr/bin/python3
# -*- coding: utf-8 -*-


import os
import sys
import re
from datetime import datetime, date
import argparse
import lxml.etree as ET
import xlsxwriter

__author__ = "TheSecEng"
__website__ = "https://terminalconnection.io"
__copyright__ = "Copyright 2018, TheSecEng"
__credits__ = ["TheSecEng"]
__license__ = "GPL"
__version__ = "0.3.6"
__maintainer__ = "TheSecEng"
__email__ = "Nope"
__status__ = "Development"

SCRIPT_INFO = \
    """
NessusParser-Excel v.{0}

Created and maintained by {1} ({2})
Inspiration from Nessus Parser by Cody (http://www.melcara.com)

Latest Updates
\t- Remove Update Function
\t- Fixed some formatting
\t- Optimized Memory Usage
\t- Ignore Plugin ID's from file or switch or both
\t- CVSS Overview sheet added
\t- Plugin Overview sheet added
""".format(__version__,
           __author__,
           __website__)

PARSER = argparse.ArgumentParser(description='Parse Nessus Files')
PARSER.add_argument('-l', '--launch_directory',
                    help="Path to Nessus File Directory", required=True)
PARSER.add_argument('-o', '--output_file',
                    help="Filename to save results as", required=True)
PARSER.add_argument("-i", "--ignore_id", required=False,
                    help="Ignored Plugin Id's Ex: 12345,23456,34567")
PARSER.add_argument("-ig", "--ignore_id_file", required=False,
                    help="File with Plugin Id's to ignore")

ARGS = PARSER.parse_args()


class ColorPrint:
    """
        Discovered at https://stackoverflow.com/questions
        /39473297/how-do-i-print-colored-output-with-python-3
        By Nicholas Stommel
    """

    @staticmethod
    def print_fail(message, end='\n'):
        """
            Print failure messages
        """
        sys.stderr.write('\x1b[1;31m' + message + '\x1b[0m' + end)

    @staticmethod
    def print_pass(message, end='\n'):
        """
            Print passing messages
        """
        sys.stdout.write('\x1b[1;32m' + message + '\x1b[0m' + end)

    @staticmethod
    def print_warn(message, end='\n'):
        """
            Print warning messages
        """
        sys.stderr.write('\x1b[1;33m' + message + '\x1b[0m' + end)

    @staticmethod
    def print_info(message, end='\n'):
        """
            Print info messages
        """
        sys.stdout.write('\x1b[1;34m' + message + '\x1b[0m' + end)

    @staticmethod
    def print_bold(message, end='\n'):
        """
            Print bold messages
        """
        sys.stdout.write('\x1b[1;37m' + message + '\x1b[0m' + end)


# List of Nessus files for parsing
TO_BE_PARSED = list()
# Track created worksheets
WS_MAPPER = dict()
# Track current used row for worksheets
ROW_TRACKER = dict()
# Child Elements
SINGLE_FIELDS = ['risk_factor', 'vuln_publication_date', 'description',
                 'plugin_output', 'solution', 'synopsis',
                 'exploit_available', 'exploitability_ease', 'exploited_by_malware',
                 'plugin_publication_date', 'plugin_modification_date']
# Attribute Fields
ATTRIB_FIELDS = ['severity', 'pluginFamily', 'pluginID', 'pluginName']

SEVERITIES = {0: "Informational",
              1: "Low",
              2: "Medium",
              3: "High",
              4: "Critical"}
SEVERITY_TOTALS = {"Informational": 0,
                   "Low": 0,
                   "Medium": 0,
                   "High": 0,
                   "Critical": 0}
COUNT_UNIQUE_SEVERITIES = {0: 0,
                           1: 0,
                           2: 0,
                           3: 0,
                           4: 0}

IGNORED_IDS = list()
UNIQUE_PLUGIN_NAME = dict()

COMMON_CRIT = dict()
COMMON_HIGH = dict()
COMMON_MED = dict()
COMMON_LOW = dict()
COMMON_INFO = dict()

UNIQUE_IP_LIST = list()


def get_child_value(currelem, getchild):
    """
        Return child element value
    """
    if currelem.find(getchild) is not None:
        return currelem.find(getchild).text
    return ''


def get_attrib_value(currelem, attrib):
    """
        Get element attribute or return emtpy
    """
    if currelem.get(attrib) is not None:
        return currelem.get(attrib)
    return ''


def is_match(regex, text):
    """
        Check for match
    """
    pattern = re.compile(regex, text)
    return pattern.search(text) is not None


def return_match(regex, text):
    """
        Return regex result
    """
    pattern = re.compile(regex)
    return pattern.search(text).group(1)


def parse_nessus_file(context, func, *args,
                      **kwargs):  # pylint: disable=too-many-statements, too-many-locals, too-many-branches, line-too-long
    """
        Paring the nessus file and generating information
    """
    vuln_data = list()
    host_data = list()
    device_data = list()
    # cpe_data = []
    host_cvss = dict()
    cvss_scores = dict()
    ms_process_info = list()
    count_ip_seen = 0
    start_tag = None
    for event, elem in context:
        host_properties = {}
        if event == 'start' and elem.tag == 'ReportHost' and start_tag is None:
            start_tag = elem.tag
            continue
        if event == 'end' and elem.tag == start_tag:
            host_properties['name'] = get_attrib_value(elem, 'name')
            host_properties['host-ip'] = ''
            host_properties['host-fqdn'] = ''
            host_properties['netbios-name'] = ''

            # CVSS Map Generation
            for i in range(0, 5):
                cvss_scores[i] = {
                    'cvss_base_score': 0, 'cvss_temporal_score': 0}

            # Building Host Data
            if elem.find('HostProperties') is not None:
                for child in elem.find('HostProperties'):
                    if child.get('name') in ['host-ip'] and child.text is not None:
                        host_properties['host-ip'] = child.text
                    if child.get('name') in ['host-fqdn'] and child.text is not None:
                        host_properties['host-fqdn'] = child.text
                    if child.get('name') in ['netbios-name'] and child.text is not None:
                        host_properties['netbios-name'] = child.text
                host_data.append(host_properties.copy())

            # Counting Total IP's seen
            count_ip_seen += 1
            # Counting Unique IP's seen
            if host_properties['host-ip'] not in UNIQUE_IP_LIST:
                UNIQUE_IP_LIST.append(host_properties['host-ip'])

            # Iter over each item
            for child in elem.iter('ReportItem'):
                plugin_name = get_attrib_value(child, "pluginName")
                plugin_id = get_attrib_value(child, "pluginID")

                # Check if we ignore this Plugin ID
                if plugin_id in IGNORED_IDS:
                    continue

                # Store unique plugin names and occurances
                if plugin_name not in UNIQUE_PLUGIN_NAME:
                    UNIQUE_PLUGIN_NAME[plugin_name] = [plugin_id, 0]
                UNIQUE_PLUGIN_NAME[plugin_name] = [UNIQUE_PLUGIN_NAME[plugin_name][0],
                                                   UNIQUE_PLUGIN_NAME[plugin_name][1] + 1]

                if get_child_value(child, 'cvss_base_score') != '':
                    base_score = round(float(get_child_value(child, 'cvss_base_score')), 2)
                    temp_severity = int(get_attrib_value(child, 'severity'))
                    cvss_scores[temp_severity]['cvss_base_score'] = round(
                        cvss_scores[temp_severity]['cvss_base_score'] + base_score, 2)
                    # cvss_scores[temp_severity]['count_base'] = cvss_scores[temp_severity]['count_base'] + 1

                if get_child_value(child, 'cvss_temporal_score') != '':
                    t_base_score = round(float(get_child_value(child, 'cvss_temporal_score')), 2)
                    t_temp_severity = int(get_attrib_value(child, 'severity'))
                    cvss_scores[t_temp_severity]['cvss_temporal_score'] = round(
                        cvss_scores[t_temp_severity]['cvss_temporal_score'] + t_base_score, 2)
                    # cvss_scores[t_temp_severity]['count_temporal'] = cvss_scores[t_temp_severity]['count_temporal'] + 1

                # CVE Per Item
                cve_item_list = list()
                if child.find("cve") is not None:
                    for cve in child.iter("cve"):
                        cve_item_list.append(cve.text)

                # Bugtraq ID Per Item
                bid_item_list = list()
                if child.find("bid") is not None:
                    for bid in child.iter("bid"):
                        bid_item_list.append(bid.text)

                # Process Info
                if plugin_id in ['70329']:
                    process_properties = host_properties

                    process_info = get_child_value(child, 'plugin_output')
                    process_info = process_info.replace(
                        'Process Overview : \n', '')
                    process_info = process_info.replace(
                        'SID: Process (PID)', '')
                    process_info = re.sub(
                        'Process_Information.*', '', process_info).replace('\n\n\n', '')

                    process_properties['processes'] = process_info
                    ms_process_info.append(process_properties.copy())

                # # CPE Info
                # if child.find('cpe') is not None:
                #     cpe_hash = host_properties
                #     cpe_hash['pluginID'] = get_attrib_value(child, 'pluginID')
                #     cpe_hash['cpe'] = get_child_value(child, 'cpe')
                #     cpe_hash['pluginFamily'] = get_attrib_value(
                #         child, 'pluginFamily')
                #     cpe_hash['pluginName'] = get_attrib_value(
                #         child, 'pluginName')
                #     cpe_hash['cpe-source'] = get_attrib_value(child, 'vuln')

                #     CPE_DATA.append(cpe_hash.copy())

                # # CPE Info
                # if get_attrib_value(child, 'pluginID') in ['45590']:
                #     if get_child_value(child, 'plugin_output') is not None:
                #         cpe_properties = get_child_value(
                #             child, 'plugin_output').split('\n')
                #     else:
                #         cpe_properties = 'None'

                #     for cpe_item in cpe_properties:
                #         if re.search('cpe\:\/(o|a|h)', cpe_item):
                #             cpe_item = cpe_item.replace('\s', '')

                #             cpe_hash = host_properties
                #             cpe_hash['pluginID'] = get_attrib_value(
                #                 child, 'pluginID')
                #             cpe_hash['cpe'] = cpe_item
                #             cpe_hash['pluginFamily'] = get_attrib_value(
                #                 child, 'pluginFamily')
                #             cpe_hash['pluginName'] = get_attrib_value(
                #                 child, 'pluginName')
                #             cpe_hash[
                #                 'cpe-source'] = get_attrib_value(child, 'cpe')

                #             CPE_DATA.append(cpe_hash.copy())

                # Device Info
                if plugin_id in ['54615']:
                    device_properties = host_properties

                    if get_child_value(child, 'plugin_output') is not None:
                        device_info = get_child_value(
                            child, 'plugin_output').replace('\n', ' ')
                    else:
                        device_info = 'None'

                    if re.search('(?<=type : )(.*)(?=Confidence )', device_info):
                        device_properties['type'] = re.search(
                            '(?<=type : )(.*)(?=Confidence )', device_info).group(1)
                    else:
                        device_properties['type'] = ''
                    if re.search(r'Confidence level : (\d+)', device_info):
                        device_properties['confidenceLevel'] = re.search(
                            r'Confidence level : (\d+)', device_info).group(1)
                    else:
                        device_properties['confidenceLevel'] = 0
                    device_data.append(device_properties.copy())
                # End

                # WiFi Info
                if plugin_id in ['11026']:
                    wifi_properties = host_properties

                    wifi_properties['mac_address'] = get_attrib_value(
                        child, 'mac_address')
                    wifi_properties[
                        'operating-system'] = get_attrib_value(child, 'operating-system')
                    wifi_properties[
                        'system-type'] = get_attrib_value(child, 'system-type')
                    wifi_properties[
                        'plugin-output'] = get_child_value(child, 'plugin-output')
                # End

                # Begin aggregation of data into vuln_properties
                # prior to adding to vuln_data
                vuln_properties = host_properties

                for field in SINGLE_FIELDS:
                    vuln_properties[field] = get_child_value(
                        child, field)

                for field in ATTRIB_FIELDS:
                    vuln_properties[field] = get_attrib_value(
                        child, field)

                vuln_properties['port'] = get_attrib_value(child, "port")
                vuln_properties['bid'] = ";\n".join(bid_item_list)
                vuln_properties['cve'] = ";\n".join(cve_item_list)
                if get_child_value(child, 'cvss_base_score') != '':
                    vuln_properties['cvss_base_score'] = round(float(get_child_value(child, 'cvss_base_score')), 2)
                else:
                    vuln_properties['cvss_base_score'] = 0

                if get_child_value(child, 'cvss_temporal_score') != '':
                    vuln_properties['cvss_temporal_score'] = round(float(get_child_value(child, 'cvss_temporal_score')),
                                                                   2)
                else:
                    vuln_properties['cvss_temporal_score'] = 0

                vuln_data.append(vuln_properties.copy())
            host_data.append(host_properties.copy())
            host_cvss[host_properties['host-ip']] = cvss_scores.copy()
            func(elem, *args, **kwargs)
            elem.clear()
            for ancestor in elem.xpath('ancestor-or-self::*'):
                while ancestor.getprevious() is not None:
                    del ancestor.getparent()[0]
    del context
    return vuln_data, device_data, ms_process_info, count_ip_seen, host_cvss


###################EXCEL#####################

def generate_worksheets():  # pylint: disable=too-many-statements, too-many-branches, line-too-long
    """
        Generate worksheets and store them for later use
    """
    ColorPrint.print_pass("\nGenerating the worksheets")
    ws_names = ["Overview", "Graphs", "Full Report",
                "CVSS Overview", "Device Type", "Critical",
                "High", "Medium", "Low",
                "Informational", "MS Running Process Info",
                "Plugin Counts", "Graph Data"]
    for sheet in ws_names:
        ColorPrint.print_bold("\tCreating {0} worksheet".format(sheet))
        WS_MAPPER[sheet] = WB.add_worksheet(sheet)
        ROW_TRACKER[sheet] = 2
        active_ws = WS_MAPPER[sheet]
        if sheet == "Graphs":
            continue
        if sheet == "Overview":
            active_ws.set_column('A:A', 28)
            active_ws.set_column('B:B', 70)
            active_ws.merge_range('A1:B2', 'Overview', DARK_FORMAT)
            continue
        if sheet == "Full Report":
            active_ws.write(1, 0, 'Index', CENTER_BORDER_FORMAT)
            active_ws.write(1, 1, 'File', CENTER_BORDER_FORMAT)
            active_ws.write(1, 2, 'IP Address', CENTER_BORDER_FORMAT)
            active_ws.write(1, 3, 'Port', CENTER_BORDER_FORMAT)
            active_ws.write(1, 4, 'FQDN', CENTER_BORDER_FORMAT)
            active_ws.write(1, 5, 'Vuln Publication Date',
                            CENTER_BORDER_FORMAT)
            active_ws.write(1, 6, 'Vuln Age by Days', CENTER_BORDER_FORMAT)
            active_ws.write(1, 7, 'Severity', CENTER_BORDER_FORMAT)
            active_ws.write(1, 8, 'Risk Factor', CENTER_BORDER_FORMAT)
            active_ws.write(1, 9, 'Plugin ID', CENTER_BORDER_FORMAT)
            active_ws.write(1, 10, 'Plugin Family', CENTER_BORDER_FORMAT)
            active_ws.write(1, 11, 'Plugin Name', CENTER_BORDER_FORMAT)
            active_ws.write(1, 12, 'Description', CENTER_BORDER_FORMAT)
            active_ws.write(1, 13, 'Synopsis', CENTER_BORDER_FORMAT)
            active_ws.write(1, 14, 'Plugin Output', CENTER_BORDER_FORMAT)
            active_ws.write(1, 15, 'Solution', CENTER_BORDER_FORMAT)
            active_ws.write(1, 16, 'Exploit Available', CENTER_BORDER_FORMAT)
            active_ws.write(1, 17, 'Exploitability Ease', CENTER_BORDER_FORMAT)
            active_ws.write(1, 18, 'Exploited by Malware',
                            CENTER_BORDER_FORMAT)
            active_ws.write(1, 19, 'Plugin Publication Date',
                            CENTER_BORDER_FORMAT)
            active_ws.write(1, 20, 'Plugin Modification Date',
                            CENTER_BORDER_FORMAT)
            active_ws.write(1, 21, 'CVE Information', CENTER_BORDER_FORMAT)
            active_ws.write(1, 22, 'Bugtraq ID Information',
                            CENTER_BORDER_FORMAT)
            active_ws.write(1, 23, 'CVSS Base Score',
                            CENTER_BORDER_FORMAT)
            active_ws.write(1, 24, 'CVSS Temporal Score',
                            CENTER_BORDER_FORMAT)

            active_ws.freeze_panes('C3')
            active_ws.autofilter('A2:V2')
            active_ws.set_column('A:A', 10)
            active_ws.set_column('B:B', 35)
            active_ws.set_column('C:C', 15)
            active_ws.set_column('D:D', 15)
            active_ws.set_column('E:E', 25)
            active_ws.set_column('F:F', 20)
            active_ws.set_column('G:G', 15)
            active_ws.set_column('H:H', 15)
            active_ws.set_column('I:I', 25)
            active_ws.set_column('J:J', 25)
            active_ws.set_column('K:K', 25)
            active_ws.set_column('L:L', 100)
            active_ws.set_column('M:M', 25)
            active_ws.set_column('N:N', 25)
            active_ws.set_column('O:O', 25)
            active_ws.set_column('P:P', 25)
            active_ws.set_column('Q:Q', 25)
            active_ws.set_column('R:R', 25)
            active_ws.set_column('S:S', 25)
            active_ws.set_column('T:T', 25)
            active_ws.set_column('U:U', 25)
            active_ws.set_column('V:V', 25)
            active_ws.set_column('W:W', 25)
            active_ws.set_column('X:X', 25)
            active_ws.set_column('Y:Y', 25)
            continue
        if sheet == "CVSS Overview":
            ROW_TRACKER[sheet] = ROW_TRACKER[sheet] + 3
            active_ws.set_tab_color("#F3E2D3")
            active_ws.write(1, 1, 'Critical', CENTER_BORDER_FORMAT)
            active_ws.write(1, 2, 'High', CENTER_BORDER_FORMAT)
            active_ws.write(1, 3, 'Medium', CENTER_BORDER_FORMAT)
            active_ws.write(1, 4, 'Low', CENTER_BORDER_FORMAT)
            active_ws.write(1, 5, 'Informational', CENTER_BORDER_FORMAT)
            active_ws.write(2, 0, 'Multiplier', CENTER_BORDER_FORMAT)
            active_ws.write(2, 1, 1, NUMBER_FORMAT)
            active_ws.write(2, 2, 1, NUMBER_FORMAT)
            active_ws.write(2, 3, 1, NUMBER_FORMAT)
            active_ws.write(2, 4, 1, NUMBER_FORMAT)
            active_ws.write(2, 5, 1, NUMBER_FORMAT)

            active_ws.write(4, 0, 'Index', CENTER_BORDER_FORMAT)
            active_ws.write(4, 1, 'File', CENTER_BORDER_FORMAT)
            active_ws.write(4, 2, 'IP Address', CENTER_BORDER_FORMAT)
            active_ws.write(4, 3, 'Total', CENTER_BORDER_FORMAT)
            active_ws.write(4, 4, 'Base Total', CENTER_BORDER_FORMAT)
            active_ws.write(4, 5, 'Temporal Total', CENTER_BORDER_FORMAT)
            active_ws.write(4, 6, 'Base Critical', CENTER_BORDER_FORMAT)
            active_ws.write(4, 7, 'Temporal Critical', CENTER_BORDER_FORMAT)
            active_ws.write(4, 8, 'Base High', CENTER_BORDER_FORMAT)
            active_ws.write(4, 9, 'Temporal High', CENTER_BORDER_FORMAT)
            active_ws.write(4, 10, 'Base Medium', CENTER_BORDER_FORMAT)
            active_ws.write(4, 11, 'Temporal Medium', CENTER_BORDER_FORMAT)
            active_ws.write(4, 12, 'Base Low', CENTER_BORDER_FORMAT)
            active_ws.write(4, 13, 'Temporal Low', CENTER_BORDER_FORMAT)
            active_ws.write(4, 14, 'Base Informational', CENTER_BORDER_FORMAT)
            active_ws.write(4, 15, 'Temporal Informational',
                            CENTER_BORDER_FORMAT)

            active_ws.freeze_panes('G6')
            active_ws.autofilter('A5:P5')
            active_ws.set_column('A:A', 10)
            active_ws.set_column('B:B', 35)
            active_ws.set_column('C:C', 15)
            active_ws.set_column('D:D', 15)
            active_ws.set_column('E:E', 15)
            active_ws.set_column('F:F', 15)
            active_ws.set_column('G:G', 15)
            active_ws.set_column('H:H', 15)
            active_ws.set_column('I:I', 15)
            active_ws.set_column('J:J', 15)
            active_ws.set_column('K:K', 15)
            active_ws.set_column('L:L', 15)
            active_ws.set_column('M:M', 15)
            active_ws.set_column('N:N', 15)
            active_ws.set_column('O:O', 15)
            active_ws.set_column('P:P', 15)
            continue
        if sheet == "Device Type":
            active_ws.set_tab_color("#BDE1ED")
            active_ws.write(1, 0, 'Index', CENTER_BORDER_FORMAT)
            active_ws.write(1, 1, 'File', CENTER_BORDER_FORMAT)
            active_ws.write(1, 2, 'IP Address', CENTER_BORDER_FORMAT)
            active_ws.write(1, 3, 'FQDN', CENTER_BORDER_FORMAT)
            active_ws.write(1, 4, 'NetBios Name', CENTER_BORDER_FORMAT)
            active_ws.write(1, 5, 'Device Type', CENTER_BORDER_FORMAT)
            active_ws.write(1, 6, 'Confidence', CENTER_BORDER_FORMAT)

            active_ws.freeze_panes('C3')
            active_ws.autofilter('A2:G2')
            active_ws.set_column('A:A', 10)
            active_ws.set_column('B:B', 35)
            active_ws.set_column('C:C', 15)
            active_ws.set_column('D:D', 35)
            active_ws.set_column('E:E', 25)
            active_ws.set_column('F:F', 15)
            active_ws.set_column('G:G', 15)
            continue
        if sheet == 'MS Running Process Info':
            active_ws.set_tab_color("#9EC3FF")

            active_ws.write(1, 0, 'Index', CENTER_BORDER_FORMAT)
            active_ws.write(1, 1, 'File', CENTER_BORDER_FORMAT)
            active_ws.write(1, 2, 'IP Address', CENTER_BORDER_FORMAT)
            active_ws.write(1, 3, 'FQDN', CENTER_BORDER_FORMAT)
            active_ws.write(1, 4, 'NetBios Name', CENTER_BORDER_FORMAT)
            active_ws.write(1, 5, 'Process Name & Level', CENTER_BORDER_FORMAT)

            active_ws.freeze_panes('C3')
            active_ws.autofilter('A2:E2')
            active_ws.set_column('A:A', 10)
            active_ws.set_column('B:B', 35)
            active_ws.set_column('C:C', 15)
            active_ws.set_column('D:D', 35)
            active_ws.set_column('E:E', 25)
            active_ws.set_column('F:F', 80)
            continue
        if sheet == "Plugin Counts":
            active_ws.set_tab_color("#D1B7FF")
            active_ws.autofilter('A2:C2')
            active_ws.set_column('A:A', 85)
            active_ws.set_column('B:B', 15)
            active_ws.set_column('C:C', 15)
            active_ws.write(1, 0, 'Plugin Name', CENTER_BORDER_FORMAT)
            active_ws.write(1, 1, 'Plugin ID', CENTER_BORDER_FORMAT)
            active_ws.write(1, 2, 'Total', CENTER_BORDER_FORMAT)
            active_ws.freeze_panes('A3')
            continue
        if sheet == "Graph Data":
            active_ws.write(1, 0, 'Severity', CENTER_BORDER_FORMAT)
            active_ws.write(1, 1, 'Total', CENTER_BORDER_FORMAT)
            continue
        if sheet == "Informational":
            active_ws.set_tab_color('blue')
        if sheet == "Low":
            active_ws.set_tab_color('green')
        if sheet == "Medium":
            active_ws.set_tab_color('yellow')
        if sheet == "High":
            active_ws.set_tab_color('orange')
        if sheet == "Critical":
            active_ws.set_tab_color('red')

        active_ws.write(1, 0, 'Index', CENTER_BORDER_FORMAT)
        active_ws.write(1, 1, 'File', CENTER_BORDER_FORMAT)
        active_ws.write(1, 2, 'IP Address', CENTER_BORDER_FORMAT)
        active_ws.write(1, 3, 'Port', CENTER_BORDER_FORMAT)
        active_ws.write(1, 4, 'Vuln Publication Date', CENTER_BORDER_FORMAT)
        active_ws.write(1, 5, 'Plugin ID', CENTER_BORDER_FORMAT)
        active_ws.write(1, 6, 'Plugin Name', CENTER_BORDER_FORMAT)
        active_ws.write(1, 7, 'Exploit Avaiable', CENTER_BORDER_FORMAT)
        active_ws.write(1, 8, 'Exploit by Malware', CENTER_BORDER_FORMAT)
        active_ws.write(1, 9, 'CVE Information', CENTER_BORDER_FORMAT)
        active_ws.write(1, 10, 'Bugtraq ID Information', CENTER_BORDER_FORMAT)

        active_ws.freeze_panes('C3')
        active_ws.autofilter('A2:J2')
        active_ws.set_column('A:A', 10)
        active_ws.set_column('B:B', 35)
        active_ws.set_column('C:C', 15)
        active_ws.set_column('D:D', 15)
        active_ws.set_column('E:E', 15)
        active_ws.set_column('F:F', 15)
        active_ws.set_column('G:G', 100)
        active_ws.set_column('H:H', 25)
        active_ws.set_column('I:I', 25)
        active_ws.set_column('J:J', 25)
        active_ws.set_column('K:K', 25)

    active_ws = None


def add_overview_data(sev, seen_ip):
    """
        Generating overview
    """
    ColorPrint.print_warn("\nGenerating Overview worksheet")
    active_ws = WS_MAPPER['Overview']

    active_ws.write(2, 0, "Total IP's Scanned", LIGHT_FORMAT)
    active_ws.write(2, 1, seen_ip, NUMBER_FORMAT)

    active_ws.write(3, 0, "Unique IP's Scanned", LIGHT_FORMAT)
    active_ws.write(3, 1, len(UNIQUE_IP_LIST), NUMBER_FORMAT)

    active_ws.write(4, 0, "", SM_DARK_FORMAT)
    active_ws.write(4, 1, "", SM_DARK_FORMAT)

    active_ws.write(5, 0, "Unique Critical Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(5, 1, len(COMMON_CRIT), NUMBER_FORMAT)

    active_ws.write(6, 0, "Unique High Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(6, 1, len(COMMON_HIGH), NUMBER_FORMAT)

    active_ws.write(7, 0, "Unique Medium Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(7, 1, len(COMMON_MED), NUMBER_FORMAT)

    active_ws.write(8, 0, "Unique Low Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(8, 1, len(COMMON_LOW), NUMBER_FORMAT)

    active_ws.write(9, 0, "Unique Informational Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(9, 1, len(COMMON_INFO), NUMBER_FORMAT)

    active_ws.write(10, 0, "", SM_DARK_FORMAT)
    active_ws.write(10, 1, "", SM_DARK_FORMAT)

    active_ws.write(11, 0, "Total Critical Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(11, 1, sev["Critical"], NUMBER_FORMAT)

    active_ws.write(12, 0, "Total High Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(12, 1, sev["High"], NUMBER_FORMAT)

    active_ws.write(13, 0, "Total Medium Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(13, 1, sev["Medium"], NUMBER_FORMAT)

    active_ws.write(14, 0, "Total Low Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(14, 1, sev["Low"], NUMBER_FORMAT)

    active_ws.write(15, 0, "Total Informational Vulnerabilities", LIGHT_FORMAT)
    active_ws.write(15, 1, sev["Informational"], NUMBER_FORMAT)

    active_ws.write(16, 0, "", SM_DARK_FORMAT)
    active_ws.write(16, 1, "", SM_DARK_FORMAT)

    active_ws.write(17, 0, "Top 5 Seen Critical", LIGHT_FORMAT)
    if COMMON_CRIT:
        top_crit = sorted(COMMON_CRIT, key=lambda key:
        COMMON_CRIT[key], reverse=True)[:5]
        for crit in top_crit:
            active_ws.write(17 + top_crit.index(crit),
                            1, crit, WRAP_TEXT_FORMAT)

    active_ws.write(22, 0, "", SM_DARK_FORMAT)
    active_ws.write(22, 1, "", SM_DARK_FORMAT)

    active_ws.write(23, 0, "Top 5 Seen High", LIGHT_FORMAT)
    if COMMON_HIGH:
        top_high = sorted(COMMON_HIGH, key=lambda key:
        COMMON_HIGH[key], reverse=True)[:5]
        for high in top_high:
            active_ws.write(23 + top_high.index(high),
                            1, high, WRAP_TEXT_FORMAT)


def add_chart_data(data):
    """
        Generation of graphs
    """
    ColorPrint.print_warn("\nGenerating Vulnerabilities by Severity graph")
    active_ws = WS_MAPPER["Graph Data"]
    temp_cnt = 2
    for key, value in data.items():
        active_ws.write(temp_cnt, 0, key)
        active_ws.write(temp_cnt, 1, value)
        temp_cnt += 1
    active_ws.hide()
    active_ws = WS_MAPPER["Graphs"]
    severity_chart = WB.add_chart({'type': 'pie'})

    # Configure Chart Data
    # Break down for range [SHEETNAME, START ROW-Header, COLUMN, END ROW, END
    # COLUMN]
    severity_chart.set_size({'width': 624, 'height': 480})
    severity_chart.add_series({
        'name': 'Total Vulnerabilities',
        'data_labels': {'value': 1},
        'categories': ["Graph Data", 2, 0, 6, 0],
        'values': ["Graph Data", 2, 1, 6, 1],
        'points': [
            {'fill': {'color': '#618ECD'}},
            {'fill': {'color': '#58BF65'}},
            {'fill': {'color': '#F7F552'}},
            {'fill': {'color': '#E9A23A'}},
            {'fill': {'color': '#B8504B'}},
        ]
    })
    severity_chart.set_title({'name': 'Vulnerabilities by Severity'})
    severity_chart.set_legend({'font': {'size': 14}})

    # Set an Excel chart style. Colors with white outline and shadow.
    severity_chart.set_style(10)

    # Insert the chart into the worksheet (with an offset).
    active_ws.insert_chart('A2', severity_chart, {
        'x_offset': 25, 'y_offset': 10})


def add_report_data(report_data_list, the_file):
    """
        Function responsible for inserting data into the Full Report
        worksheet
    """
    ColorPrint.print_bold("\tInserting data into Full Report worksheet")
    # Retrieve correct worksheet from out Worksheet tracker
    report_ws = WS_MAPPER['Full Report']
    # Resume inserting rows at our last unused row
    temp_cnt = ROW_TRACKER['Full Report']
    # Iterate over out VULN List and insert records to worksheet
    for reportitem in report_data_list:
        # If we have a valid Vulnerability publication date
        # lets generate the Days old cell value
        if reportitem["vuln_publication_date"] != '':
            date_format = "%Y/%m/%d"
            date_one = datetime.strptime(
                reportitem["vuln_publication_date"], date_format)
            date_two = datetime.strptime(
                str(date.today()).replace("-", "/"), date_format)
            report_ws.write(temp_cnt, 6,
                            (date_two - date_one).days, NUMBER_FORMAT)
        else:
            report_ws.write(temp_cnt, 6,
                            reportitem["vuln_publication_date"], NUMBER_FORMAT)
        report_ws.write(temp_cnt, 0, temp_cnt - 2, WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 1, the_file, WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 2, reportitem[
            'host-ip'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 3, int(reportitem[
                                             "port"]), NUMBER_FORMAT)
        report_ws.write(temp_cnt, 4, reportitem[
            'host-fqdn'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 5, reportitem[
            "vuln_publication_date"], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 7,
                        int(reportitem["severity"]), NUMBER_FORMAT)
        report_ws.write(temp_cnt, 8, reportitem[
            "risk_factor"], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 9,
                        int(reportitem["pluginID"]), NUMBER_FORMAT)
        report_ws.write(temp_cnt, 10, reportitem[
            "pluginFamily"], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 11, reportitem[
            "pluginName"], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 12, reportitem[
            "description"], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 13, reportitem[
            'synopsis'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 14, reportitem[
            'plugin_output'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 15, reportitem[
            'solution'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 16, reportitem[
            'exploit_available'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 17, reportitem[
            'exploitability_ease'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 18, reportitem[
            'exploited_by_malware'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 19, reportitem[
            'plugin_publication_date'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 20, reportitem[
            'plugin_modification_date'], WRAP_TEXT_FORMAT)
        report_ws.write(temp_cnt, 21, reportitem[
            'cve'], NUMBER_FORMAT)
        report_ws.write(temp_cnt, 22, reportitem[
            'bid'], NUMBER_FORMAT)
        report_ws.write(temp_cnt, 23, reportitem[
            'cvss_base_score'], NUMBER_FORMAT)
        report_ws.write(temp_cnt, 24, reportitem[
            'cvss_temporal_score'], NUMBER_FORMAT)

        temp_cnt += 1
    # Save the last unused row for use on the next Nessus file
    ROW_TRACKER['Full Report'] = temp_cnt


def add_cvss_info(cvss_data, the_file):
    """
        Add unique Plugin information
    """
    ColorPrint.print_bold("\tInserting data into CVSS worksheet")
    active_ws = WS_MAPPER['CVSS Overview']
    temp_cnt = ROW_TRACKER['CVSS Overview']
    for key, value in cvss_data.items():
        active_ws.write(temp_cnt, 0, temp_cnt - 5, WRAP_TEXT_FORMAT)
        active_ws.write(temp_cnt, 1, the_file, WRAP_TEXT_FORMAT)
        active_ws.write(temp_cnt, 2, key, WRAP_TEXT_FORMAT)
        active_ws.write(temp_cnt, 3, "=E{0}+F{1}".format(
            temp_cnt + 1, temp_cnt + 1), WRAP_TEXT_FORMAT)
        active_ws.write(temp_cnt, 4,
                        "=(B3*G{0})+(C3*I{1})+(D3*K{2})+(E3*M{3})+(F3*O{4})".format(
                            temp_cnt + 1, temp_cnt + 1, temp_cnt + 1, temp_cnt + 1, temp_cnt + 1),
                        WRAP_TEXT_FORMAT)
        active_ws.write(temp_cnt, 5,
                        "=(B3*H{0})+(C3*J{1})+(D3*L{2})+(E3*N{3})+(F3*P{4})".format(
                            temp_cnt + 1, temp_cnt + 1, temp_cnt + 1, temp_cnt + 1, temp_cnt + 1),
                        WRAP_TEXT_FORMAT)
        temp_col = 6
        for skey, svalue in value.items():  # pylint: unused-variable
            for dkey, dvalue in svalue.items():  # pylint: unused-variable
                active_ws.write(temp_cnt, temp_col, dvalue, NUMBER_FORMAT)
                temp_col += 1

        temp_cnt += 1
    ROW_TRACKER['CVSS Overview'] = temp_cnt


def add_device_type(device_info, the_file):
    """
        Add Device Type information
    """
    ColorPrint.print_bold("\tInserting data into Device Type worksheet")
    device_ws = WS_MAPPER['Device Type']
    temp_cnt = ROW_TRACKER['Device Type']
    for host in device_info:
        device_ws.write(temp_cnt, 0, temp_cnt - 2, WRAP_TEXT_FORMAT)
        device_ws.write(temp_cnt, 1, the_file, WRAP_TEXT_FORMAT)
        device_ws.write(temp_cnt, 2, host['host-ip'], WRAP_TEXT_FORMAT)
        device_ws.write(temp_cnt, 3, host['host-fqdn'], WRAP_TEXT_FORMAT)
        device_ws.write(temp_cnt, 4, host['netbios-name'], WRAP_TEXT_FORMAT)
        device_ws.write(temp_cnt, 5, host['type'], WRAP_TEXT_FORMAT)
        device_ws.write(temp_cnt, 6, int(
            host['confidenceLevel']), NUMBER_FORMAT)
        temp_cnt += 1
    ROW_TRACKER['Device Type'] = temp_cnt


def add_vuln_info(vuln_list, the_file):
    """
        Add Vulnerability information
    """
    for key, value in SEVERITIES.items():
        ColorPrint.print_bold(
            "\tInserting data into {0} worksheet".format(value))
        vuln_ws = WS_MAPPER[value]
        temp_cnt = ROW_TRACKER[value]
        for vuln in vuln_list:
            if not int(vuln['severity']) == key:
                continue
            if int(vuln['severity']) == 4:
                COMMON_CRIT[vuln['pluginName']] = COMMON_CRIT.get(
                    vuln['pluginName'], 0) + 1
            if int(vuln['severity']) == 3:
                COMMON_HIGH[vuln['pluginName']] = COMMON_HIGH.get(
                    vuln['pluginName'], 0) + 1
            if int(vuln['severity']) == 2:
                COMMON_MED[vuln['pluginName']] = COMMON_MED.get(
                    vuln['pluginName'], 0) + 1
            if int(vuln['severity']) == 1:
                COMMON_LOW[vuln['pluginName']] = COMMON_LOW.get(
                    vuln['pluginName'], 0) + 1
            if int(vuln['severity']) == 0:
                COMMON_INFO[vuln['pluginName']] = COMMON_INFO.get(
                    vuln['pluginName'], 0) + 1
            SEVERITY_TOTALS[value] += 1
            vuln_ws.write(temp_cnt, 0, temp_cnt - 2, WRAP_TEXT_FORMAT)
            vuln_ws.write(temp_cnt, 1, the_file, WRAP_TEXT_FORMAT)
            vuln_ws.write(temp_cnt, 2, vuln['host-ip'], WRAP_TEXT_FORMAT)
            vuln_ws.write(temp_cnt, 3, int(vuln['port']), NUMBER_FORMAT)
            vuln_ws.write(temp_cnt, 4, vuln[
                'vuln_publication_date'], WRAP_TEXT_FORMAT)
            vuln_ws.write(temp_cnt, 5, int(vuln['pluginID']), NUMBER_FORMAT)
            vuln_ws.write(temp_cnt, 6, vuln['pluginName'], WRAP_TEXT_FORMAT)
            vuln_ws.write(temp_cnt, 7, vuln[
                'exploit_available'], WRAP_TEXT_FORMAT)
            vuln_ws.write(temp_cnt, 8, vuln[
                'exploited_by_malware'], WRAP_TEXT_FORMAT)
            vuln_ws.write(temp_cnt, 9, vuln['cve'], WRAP_TEXT_FORMAT)
            vuln_ws.write(temp_cnt, 10, vuln['bid'], WRAP_TEXT_FORMAT)
            temp_cnt += 1
        ROW_TRACKER[value] = temp_cnt


def add_ms_process_info(proc_info, the_file):
    """
        Add MS Process information
    """
    ColorPrint.print_bold("\tInserting data into MS Process Info worksheet")
    ms_proc_ws = WS_MAPPER['MS Running Process Info']
    temp_cnt = ROW_TRACKER['MS Running Process Info']
    for host in proc_info:
        for proc in host['processes'].split('\n'):
            ms_proc_ws.write(temp_cnt, 0, temp_cnt - 2, WRAP_TEXT_FORMAT)
            ms_proc_ws.write(temp_cnt, 1, the_file, WRAP_TEXT_FORMAT)
            ms_proc_ws.write(temp_cnt, 2, host['host-ip'], WRAP_TEXT_FORMAT)
            ms_proc_ws.write(temp_cnt, 3, host['host-fqdn'], WRAP_TEXT_FORMAT)
            ms_proc_ws.write(temp_cnt, 4, host[
                'netbios-name'], WRAP_TEXT_FORMAT)
            ms_proc_ws.write(temp_cnt, 5, proc, WRAP_TEXT_FORMAT)
            temp_cnt += 1
    ROW_TRACKER['MS Running Process Info'] = temp_cnt


def add_plugin_info(plugin_count):
    """
        Add unique Plugin information
    """
    ColorPrint.print_warn("\nGenerating Plugin worksheet")
    active_ws = WS_MAPPER['Plugin Counts']
    temp_cnt = ROW_TRACKER['Plugin Counts']
    for key, value in plugin_count.items():
        active_ws.write(temp_cnt, 0, key, WRAP_TEXT_FORMAT)
        active_ws.write(temp_cnt, 1, int(value[0]), NUMBER_FORMAT)
        active_ws.write(temp_cnt, 2, int(value[1]), NUMBER_FORMAT)
        temp_cnt += 1
    ROW_TRACKER['Plugin Counts'] = temp_cnt


#############################################
#############################################


def begin_parsing():  # pylint: disable=c-extension-no-member
    """
        Provides the initial starting point for validating root tag
        is for a Nessus v2 File. Initiates parsing and then writes to
        the associated workbook sheets.
    """
    count_ip_seen = 0
    curr_iteration = 0
    for report in TO_BE_PARSED:
        context = ET.iterparse(report, events=('start', 'end',))
        context = iter(context)
        event, root = next(context)

        if root.tag in ["NessusClientData_v2"]:
            ColorPrint.print_pass(
                "\nBegin parsing of {0}".format(report))
            vuln_data, device_data, ms_process_info, seen_ip, host_cvss = parse_nessus_file(
                context, lambda elem: None)
            count_ip_seen += seen_ip
            add_report_data(vuln_data, report)
            add_vuln_info(vuln_data, report)
            add_cvss_info(host_cvss, report)
            add_device_type(device_data, report)
            add_ms_process_info(ms_process_info, report)
            vuln_data = None
            device_data = None
            ms_process_info = None
            seen_ip = None
        del context
        curr_iteration += 1
        ColorPrint.print_bold("\n{0}% ({1}/{2}) of files parsed".format(
            round((curr_iteration / len(TO_BE_PARSED)) * 100, 2),
            curr_iteration,
            len(TO_BE_PARSED)))
    add_chart_data(SEVERITY_TOTALS)
    add_plugin_info(UNIQUE_PLUGIN_NAME)
    add_overview_data(SEVERITY_TOTALS, count_ip_seen)


if __name__ == "__main__":
    ColorPrint.print_bold(SCRIPT_INFO)

    FILE_COUNT = len([name for name in os.listdir(
        ARGS.launch_directory) if name.endswith('.nessus')])
    REPORT_NAME = ARGS.output_file

    if FILE_COUNT == 0:
        print("No files found")
        sys.exit()
    elif FILE_COUNT > 25:
        USER_RESPONSE = input(
            '\x1b[1;33mFolder contains 25+ Nessus files. Continue? [y/n]: \x1b[0m')[0].lower()
        if USER_RESPONSE != 'y':
            sys.exit()

    if ARGS.ignore_id:
        try:
            for nessus_id in ARGS.ignore_id.split(","):
                if re.sub(r'\s+', '', nessus_id) not in IGNORED_IDS:
                    IGNORED_IDS.append(re.sub(r'\s+', '', nessus_id))
        except:
            ColorPrint.print_fail("Error reading Ignore Plugin Id's " +
                                  "please ensure format is: 12345,23455,42342,23423")
            sys.exit()
    if ARGS.ignore_id_file:
        try:
            with open(ARGS.ignore_id_file) as fp:
                for cnt, line in enumerate(fp):
                    if re.sub(r'\s+', '', line) not in IGNORED_IDS:
                        IGNORED_IDS.append(re.sub(r'\s+', '', line))
        except:
            ColorPrint.print_fail("Error reading Ignore Plugin Id's fle" +
                                  "please ensure format is on ID per line")
            sys.exit()
    if os.path.isfile("{0}.xlsx".format(ARGS.output_file)):
        REPORT_NAME = "{0}_{1}".format(ARGS.output_file, f("{datetime.now():%Y-%m-%d-%S-%s}"))
        ColorPrint.print_warn("\nExisting report detected. Report will be saved as {0}.xlsx".format(
            REPORT_NAME))

    WB = xlsxwriter.Workbook(
        '{0}.xlsx'.format(REPORT_NAME), {'strings_to_urls': False, 'constant_memory': True})
    CENTER_BORDER_FORMAT = WB.add_format(
        {'bg_color': '#1D365A',
         'font_color': 'white',
         'bold': True,
         'italic': True,
         'border': True})
    WRAP_TEXT_FORMAT = WB.add_format(
        {'border': True})
    NUMBER_FORMAT = WB.add_format(
        {'border': True, 'num_format': '0'})
    DARK_FORMAT = WB.add_format(
        {'bg_color': '#1D365A',
         'font_color': 'white',
         'font_size': 22,
         'bold': 1,
         'border': 1,
         'align': 'center',
         'valign': 'vcenter'})
    SM_DARK_FORMAT = WB.add_format(
        {'bg_color': '#1D365A',
         'font_color': 'white',
         'font_size': 12,
         'bold': 1,
         'border': 1})
    LIGHT_FORMAT = WB.add_format(
        {'bg_color': '#9AB3D4',
         'font_color': 'black',
         'font_size': 12,
         'border': 1,
         'align': 'left',
         'valign': 'top'})

    MAX_EXPECTED_MEMORY_USAGE = 0
    for nessus_report in os.listdir(ARGS.launch_directory):
        if nessus_report.endswith(".nessus") or nessus_report.endswith(".xml"):
            TO_BE_PARSED.append(os.path.join(
                ARGS.launch_directory, nessus_report))
            FILE_SIZE = (os.path.getsize(
                TO_BE_PARSED[-1]) >> 20) * 2
            if FILE_SIZE > MAX_EXPECTED_MEMORY_USAGE:
                MAX_EXPECTED_MEMORY_USAGE = FILE_SIZE

    ColorPrint.print_warn(
        "\n*** Max expected memory usage {0} MB ***".format(MAX_EXPECTED_MEMORY_USAGE))

    if IGNORED_IDS:
        ColorPrint.print_warn(
            "\nIgnoring {0} Plugin ID's".format(len(IGNORED_IDS)))
    generate_worksheets()
    begin_parsing()
    WB.close()

    ColorPrint.print_pass(
        "\nReport has been saved as {0}.xlsx".format(REPORT_NAME))
