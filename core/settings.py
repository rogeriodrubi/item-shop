import os

def readSecret(envvarname: str):
    # NOTE: `readSecret` foi movida para cá para estar disponível para todos os arquivos de settings.
    return str(open(os.environ[envvarname], 'rb').read(), encoding='ascii').strip()

IS_PRODUCTION = os.getenv("IS_PRODUCTION", 'False').lower() in ('1', 'true', 't', 'yes', 'y')

if IS_PRODUCTION:
    from .conf.production.settings import *
else:
    from .conf.development.settings import *

# Application definition
INSTALLED_APPS = [
    'django.contrib.humanize',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'produtos', 
    
    # required by all-auth
    'django.contrib.sites',
    'allauth',
    'allauth.account',
    'allauth.socialaccount',

    # providers all-auth
    # https://django-allauth.readthedocs.io/en/latest/installation.html
    'allauth.socialaccount.providers.google',
    
    # https://pypi.org/project/django-widget-tweaks/
    'widget_tweaks',

    # Enable the inner home (home)   
    'apps.enquetes',
    'apps.inventario',
    'apps.mercado',
]

# configurações servem apenas para send_common (SMTP using DJango)
EMAIL_HOST = os.environ.get('EMAIL_HOST')
EMAIL_USE_TLS = True
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', 587))
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER')
EMAIL_HOST_PASSWORD = readSecret('EMAIL_HOST_PASSWORD_FILE')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL')
DEFAULT_REPLY_TO = os.environ.get('DEFAULT_REPLY_TO', 'falecom@projetosd.com.br')

# Internationalization
LANGUAGE_CODE = 'pt-br'

USE_I18N = True
USE_L10N = True

USE_TZ = True
TIME_ZONE = 'America/Recife'

# --- Correção para Django 4.0+ ---
CSRF_TRUSTED_ORIGINS = [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'https://localhost:8000',
    'https://127.0.0.1:8000',
]

# Permite acesso externo (necessário para acessar via navegador no Windows)
ALLOWED_HOSTS = ['*']

# Configuração de Arquivos de Mídia (Imagens)
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
