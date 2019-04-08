from .config import load_projects

from jinja2 import Template

import os

def compile_certbot_sh(config: dict):
	file_path = os.path.dirname(os.path.realpath(__file__))
	template = Template(open(os.path.join(file_path, 'certbot.sh.jinja2')).read())
	f = open('/solaris/certbot/certbot.sh', 'w')
	f.write(template.render(projects=config['projects']))
	f.close()