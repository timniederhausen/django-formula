{% from 'django/map.jinja' import django with context %}
{% from 'django/macros.jinja' import labels with context %}

{% for pkg in django.packages %}
dj_pkg_{{ pkg }}:
  pkg.installed:
    - name: {{ pkg }}
{% endfor %}

{% if grains.os_family == 'FreeBSD' %}
dj_ensurepip:
  cmd.run:
    - name: {{ django.python }} -m ensurepip
    - creates: /usr/local/lib/python3.5/site-packages/pip
{% endif %}

{% for app in django.apps %}
{% set root = app.get('root', '/home/' + app.user) %}
{% set venv = root + '/' + app.virtualenv %}
{% set deps = [] %}
dj_{{ app.name }}_user:
  user.present:
    - name: {{ app.user }}

dj_{{ app.name }}_group:
  group.present:
    - name: {{ app.group }}

dj_{{ app.name }}_install:
  file.managed:
    - name: {{ root }}/{{ app.name }}.zip
    - user: {{ app.user }}
    - group: {{ app.group }}
    {{ sls_block(app.archive) | indent(4) }}
{% do deps.append('file: dj_' + app.name + '_install') %}

dj_{{ app.name }}_unzip:
  archive.extracted:
    - name: {{ root }}/{{ app.name }}
    - user: {{ app.user }}
    - group: {{ app.group }}
    - source: {{ root }}/{{ app.name }}.zip
    - onchanges:
      - file: dj_{{ app.name }}_install

dj_{{ app.name }}_venv:
  virtualenv.managed:
    - name: {{ venv }}
{% if app.requirements_file is defined %}
    - requirements: {{ root }}/{{ app.name }}/{{ app.requirements_file }}
{% endif %}
    - user: {{ app.user }}
{% do deps.append('virtualenv: dj_' + app.name + '_install') %}

# .env for decouple
dj_{{ app.name }}_env:
  file.managed:
    - name: {{ root }}/{{ app.name }}/.env
    - user: {{ app.user }}
    - group: {{ app.group }}
    {{ sls_block(app.env) | indent(4) }}
{% do deps.append('file: dj_' + app.name + '_env') %}

dj_{{ app.name }}_migrate:
  cmd.run:
    - name: '. {{ venv }}/bin/activate && python manage.py migrate'
    - onchanges:
      {{ labels(deps) | indent(4) }}
{% do deps.append('file: dj_' + app.name + '_install') %}

{% endfor %}
