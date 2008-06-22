#!/usr/bin/env python

# This should work:
#
#    Changed blah and foo to do this or that. Re #10 and #12, and qa #12.
#

import re
import sys
from datetime import datetime

from trac.env import open_environment
from trac.ticket.notification import TicketNotifyEmail
from trac.ticket import Ticket
from trac.ticket.web_ui import TicketModule
from trac.util.datefmt import utc
from trac.versioncontrol.api import NoSuchChangeset

project = sys.argv[1]
rev = sys.argv[2]

def refs(ticket):
	pass

def qa(ticket):
	if ticket['phase'] == 'Final Fixing':
		ticket['phase'] = 'Final QA'
	else:
		ticket['phase'] = 'Initial QA'
	ticket['owner'] = ''
	ticket['status'] = 'new'

commands = { 're': refs, 'refs': refs, 'qa': qa }
commandPattern = re.compile(r'(?P<action>[A-Za-z]*).?(?P<ticket>#[0-9]+(?:(?:[, &]*|[ ]?and[ ]?)#[0-9]+)*)')
ticketPattern = re.compile(r'#([0-9]*)')
tickets = {}

env = open_environment(project)
repos = env.get_repository()
repos.sync()

changeset = repos.get_changeset(rev)

for command, tickets in commandPattern.findall(changeset.message):
	if commands.has_key(command.lower()):
		for ticketId in ticketPattern.findall(tickets):
			tickets.setdefault(ticketId, []).append(commands[command.lower()])

for ticketId, commands in tickets.iteritems():
	db = env.get_db_cnx()

	ticket = Ticket(env, int(ticketId), db)
	for command in commands:
		command(ticket)

	# determine sequence number...
	cnum = 0
	tm = TicketModule(env)
	for change in tm.grouped_changelog_entries(ticket, db):
		if change['permanent']:
			cnum += 1

	now = datetime.now(utc)
	message = "(In [%s]) %s" % (rev, changeset.message)
	ticket.save_changes(changeset.author, message, now, db, cnum+1)
	db.commit()

	tn = TicketNotifyEmail(env)
	tn.notify(ticket, newticket=0, modtime=now)

