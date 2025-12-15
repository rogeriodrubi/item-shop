import re
from django import forms
from datetime import timedelta
from django.utils import timezone
from django.forms.widgets import HiddenInput
from django.db.models import Sum
from django.template.defaultfilters import pluralize

from django.contrib.auth import get_user_model
from core.utils import convert_to_localtime, get_or_none

from allauth.account.forms import SignupForm, LoginForm, ResetPasswordForm
from django_recaptcha.fields import ReCaptchaField
from django_recaptcha.widgets import ReCaptchaV2Checkbox




class CustomSignupForm(SignupForm):

    captcha = ReCaptchaField(widget=ReCaptchaV2Checkbox())

    def save(self, request):

        user = super(CustomSignupForm, self).save(request)

        return user
    

class CustomLoginForm(LoginForm):

    captcha = ReCaptchaField(widget=ReCaptchaV2Checkbox())

    def save(self, request):

        user = super(CustomLoginForm, self).save(request)

        return user
    

class CustomResetPasswordForm(ResetPasswordForm):

    captcha = ReCaptchaField(widget=ReCaptchaV2Checkbox())

    def save(self, request):

        user = super(CustomResetPasswordForm, self).save(request)

        return user