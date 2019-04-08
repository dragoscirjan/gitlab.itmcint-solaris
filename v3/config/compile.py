#! /usr/bin/env python

import solaris.certbot
import solaris.config

config = solaris.config.load_projects()

solaris.certbot.compile_certbot_sh(config)