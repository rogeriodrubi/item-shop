# -*- encoding: utf-8 -*-
"""
Copyright (c) 2019 - present AppSeed.us
"""

from django.contrib import admin
from django.urls import path, include  # add this
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls, name='admin'),                # Django admin route
    path('accounts/', include('django.contrib.auth.urls')),
    path('', include('produtos.urls')), # <-- AQUI: Joga tudo da raiz para o app produtos
    path('accounts/', include('allauth.urls')),     # django all-auth
    path("", include("apps.enquetes.urls")),             # UI Kits Html files  
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
