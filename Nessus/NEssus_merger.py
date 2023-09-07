# file: merger.py
# based off: http://cmikavac.net/2011/07/09/merging-multiple-nessus-scans-python-script/
# by: mastahyeti

import xml.etree.ElementTree as etree
import shutil
import os

first = 1
for fileName in os.listdir("."):
   if ".nessus" in fileName:
      print(":: Parsing", fileName)
      if first:
         mainTree = etree.parse(fileName)
         report = mainTree.find('Report')
         report.attrib['name'] = 'Merged Report'
         first = 0
      else:
         tree = etree.parse(fileName)
         for host in tree.findall('.//ReportHost'):
            existing_host = report.find(".//ReportHost[@name='"+host.attrib['name']+"']")
            if not existing_host:
                print "adding host: " + host.attrib['name']
                report.append(host)
            else:
                for item in host.findall('ReportItem'):
                    if not existing_host.find("ReportItem[@port='"+ item.attrib['port'] +"'][@pluginID='"+ item.attrib['pluginID'] +"']"):
                        print "adding finding: " + item.attrib['port'] + ":" + item.attrib['pluginID']
                        existing_host.append(item)
      print(":: => done.")    
   
if "nss_report" in os.listdir("."):
   shutil.rmtree("nss_report")
   
os.mkdir("nss_report")
mainTree.write("nss_report/report.nessus", encoding="utf-8", xml_declaration=True)
