# -*- encoding: utf-8 -*-

import os


from pathlib import Path

# Build paths inside the project like this: os.path.join(BASE_DIR, ...)
BASE_DIR = Path(__file__).parent.parent.parent.parent

def readSecret(envvarname: str):
    return str(open(os.environ[envvarname], 'rb').read(), encoding='ascii').strip()

# python -c "import secrets; print(secrets.token_urlsafe())"
SECRET_KEY = readSecret('SECRET_KEY_FILE')

# SECURITY WARNING: don't run with debug turned on in production!
#DEBUG = os.getenv("DEBUG", 'False').lower() in ('1', 'true', 't', 'yes', 'y')
DEBUG = 0

# load production server from .env
ALLOWED_HOSTS        = ['projetosd.com.br']
CSRF_TRUSTED_ORIGINS = ['projetosd.com.br']

ACCOUNT_DEFAULT_HTTP_PROTOCOL='https'

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# all-auth settings
SITE_ID = 1
ACCOUNT_AUTHENTICATION_METHOD = 'email'
ACCOUNT_EMAIL_REQUIRED = True
ACCOUNT_EMAIL_CONFIRMATION_EXPIRE_DAY = 7
ACCOUNT_EMAIL_VERIFICATION = 'mandatory'
ACCOUNT_LOGIN_ATTEMPTS_LIMIT = 5
ACCOUNT_LOGIN_ATTEMPTS_TIMEOUT = 300 # 5 min.
LOGIN_REDIRECT_URL = '/'

## The default behaviour is not log users in and to redirect them to ACCOUNT_EMAIL_CONFIRMATION_ANONYMOUS_REDIRECT_URL.
# By changing this setting to True, users will automatically be logged in once they confirm their email address. 
# Note however that this only works when confirming the email address immediately after signing up, 
# assuming users didn’t close their browser or used some sort of private browsing mode.
ACCOUNT_LOGIN_ON_EMAIL_CONFIRMATION = True
ACCOUNT_SIGNUP_EMAIL_ENTER_TWICE = True
ACCOUNT_SIGNUP_PASSWORD_ENTER_TWICE =True
ACCOUNT_UNIQUE_EMAIL = True

## The user is required to enter a username when signing up. Note that the user will be asked to do so even 
# if ACCOUNT_AUTHENTICATION_METHOD is set to email. Set to False when you do not wish to prompt the user to 
# enter a username.
ACCOUNT_USERNAME_REQUIRED = False

# Attempt to bypass the signup form by using fields (e.g. username, email)
# retrieved from the social account provider. If a conflict arises due to a
# duplicate e-mail address the signup form will still kick in.
SOCIALACCOUNT_AUTO_SIGNUP = True

SOCIALACCOUNT_QUERY_EMAIL = ACCOUNT_EMAIL_REQUIRED
SOCIALACCOUNT_EMAIL_REQUIRED = ACCOUNT_EMAIL_REQUIRED
SOCIALACCOUNT_STORE_TOKENS = False
ACCOUNT_EMAIL_CONFIRMATION_AUTHENTICATED_REDIRECT_URL = LOGIN_REDIRECT_URL

# EMAIL SERVER SETTINGS
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'

SESSION_EXPIRE_AT_BROWSER_CLOSE = False

ROOT_URLCONF = 'core.urls'
#LOGIN_REDIRECT_URL = "home"  # Route defined in home/urls.py
#LOGOUT_REDIRECT_URL = "home"  # Route defined in home/urls.py
ACCOUNT_LOGOUT_ON_GET = True
TEMPLATE_DIR = os.path.join(BASE_DIR, "apps/templates")  # ROOT dir for templates

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [TEMPLATE_DIR],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

AUTHENTICATION_BACKENDS = [
    #...
    # Needed to login by username in Django admin, regardless of `allauth`
    'django.contrib.auth.backends.ModelBackend',

    # `allauth` specific authentication methods, such as login by e-mail
    'allauth.account.auth_backends.AuthenticationBackend',
    #...
]

WSGI_APPLICATION = 'core.wsgi.application'

# Database
# https://docs.djangoproject.com/en/3.0/ref/settings/#databases

DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": "projetosd_db",
            "USER": os.environ.get('PG_APP_USER', 'postgres'),
            "HOST": 'projetosd_db',
            "PASSWORD": readSecret('PG_APP_PASSWORD_FILE'),
            "PORT": '5432',
        }
}

#############################################################
# SRC: https://devcenter.heroku.com/articles/django-assets

# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/1.9/howto/static-files/
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATIC_URL = '/static/'

# Extra places for collectstatic to find static files.
STATICFILES_DIRS = (os.path.join(BASE_DIR, 'apps/static'),)