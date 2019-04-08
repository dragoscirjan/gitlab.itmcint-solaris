try:
    from yaml import load, CLoader as Loader
except ImportError:
    from yaml import load, Loader

def load_projects():
	return load(open('/solaris/config/config.yml').read(), Loader=Loader)