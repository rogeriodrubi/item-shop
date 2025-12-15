import os

IS_PRODUCTION = os.getenv("IS_PRODUCTION", 'False').lower() in ('1', 'true', 't', 'yes', 'y')

#IS_PRODUCTION = False

if IS_PRODUCTION:
    from core.conf.production.settings import *
else:
    from core.conf.development.settings import *
