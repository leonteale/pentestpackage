#!/usr/bin/python
import optparse
import re
import socket
import sys
from signal import signal, SIGPIPE, SIG_DFL
signal(SIGPIPE,SIG_DFL)

#########################################################################
# Program: <APPLICATION DESCRIPTION HERE>
#########################################################################
#########################################################################
# Copyright: <COPYRIGHT NOTICE HERE>
#########################################################################
__version__ =   "0.0.1" # <release>.<major change>.<minor change>
__prog__ =      "<APPLICATION NAME>"
__author__ =    "<YOUR NAME>"

#########################################################################
## Pipeline:
## TODO: 
#########################################################################

#########################################################################
# XXX: Configuration
#########################################################################

EXIT_CODES = {
	"ok"	  : 0,
	"generic" : 1,
	"invalid" : 3,
	"missing" : 5,
	"limit"   : 7,
}

#########################################################################
# XXX: Kick off
#########################################################################

def run():
	# <START CODING HERE>
	pass

#########################################################################
# XXX: Helpers
#########################################################################

def debug(msg, override=False):
	if options.debug or override:
		print msg

def warn(msg):
	debug("[WARNING]: %s" % msg)
	sys.stderr.write("[WARNING]: %s\n" % msg)

def err(msg, level="generic"):
	if level.lower() not in EXIT_CODES:
		level = "generic"
	
	sys.stderr.write("[ERROR]: %s\n" % msg)
	sys.exit(EXIT_CODES[level])

#########################################################################
# XXX: Initialisation
#########################################################################

if __name__ == "__main__":
	parser = optparse.OptionParser(
                usage="Usage: %prog [OPTIONS]",
                version="%s: v%s (%s)" % (__prog__, __version__, __author__),
                description="<DESCRIPTION OF THE APPLICATION HERE>",
                epilog="Example: <EXAMPLE HERE>",
        )

        parser.add_option("-c", "--conf", default="config.conf", action="store", dest="config",
                help="Specify which config to use (default: config.conf)")

        parser.add_option('-o', '--output', default="STDOUT", dest="output",
                help='Specify the output file (default: STDOUT)')

        parser.add_option('-d', '--debug', action='store_true', dest="debug",
                help='Display verbose processing details (default: False)')
        
	parser.add_option('-v', action='version',
                help="Shows the current version number and exits")

        (options, args) = parser.parse_args()

	try:
		run()
	except KeyboardInterrupt:
		print "\n\nCancelled."
		sys.exit(0)