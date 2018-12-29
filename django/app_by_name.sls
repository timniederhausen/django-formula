{%- from 'django/map.jinja' import django with context %}

{%- set app_by_name = [] %}
{%- set app_name = salt.pillar.get('app_name') %}
{%- if app_name %}
{%-  for app in django.apps %}
{%-   if app.name == app_name %}
{%-     do app_by_name.append(app) %}
{%-   endif %}
{%-  endfor %}
{%- endif %}

{%- if app_by_name %}
{%-  set app = app_by_name[0] %}
{%-  include 'django/app.sls' with context %}
{%- else %}
dj_app_not_found:
  test.fail_without_changes
{%- endif %}
