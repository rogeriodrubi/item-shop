#!/usr/bin/env python

import os
import sys
try:
    import debugpy
except ImportError:
    debugpy = None
from django.conf import settings

def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

    # added for debug
    if settings.DEBUG:
        if debugpy and (os.environ.get('RUN_MAIN') or os.environ.get('WERKZEUG_RUN_MAIN')):
            try:
                debugpy.listen(("0.0.0.0", 3000))
                print("🐛 Debugger pronto na porta 3000!")
                # debugpy.wait_for_client()  <-- COMENTE ESSA LINHA
            except Exception as e:
                print(f"🐛 Falha ao iniciar o debugger na porta 3000: {e}")
    # added for debug

    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)

if __name__ == '__main__':
    main()
