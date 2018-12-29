{% from 'django/map.jinja' import django with context %}
{% from 'django/macros.jinja' import sls_block, labels with context %}

{% for pkg in django.packages %}
{{ pkg }}:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}

{% for app in django.apps -%}
{%  include 'django/app.sls' with context %}
{% endfor -%}
