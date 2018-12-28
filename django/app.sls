{%- from 'django/map.jinja' import django with context %}
{%- from 'django/macros.jinja' import sls_block, labels with context %}

{# Allow app_name-based selection #}
{%- if app is not defined and django.app_name is defined %}
{%  set app = django.apps | selectattr("name", "equalto", django.app_name) | first %}
{%- endif %}

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
    - name: {{ root }}/{{ app.name }}.tgz
    - user: {{ app.user }}
    - group: {{ app.group }}
    - makedirs: true
    {{ sls_block(app.archive) | indent(4) }}
{% do deps.append('file: dj_' + app.name + '_install') %}

dj_{{ app.name }}_unzip:
  file.directory:
    - name: {{ root }}/{{ app.name }}
    - user: {{ app.user }}
    - group: {{ app.group }}
  cmd.run:
    - name: tar xf {{ root }}/{{ app.name }}.tgz
    - runas: {{ app.user }}
    - cwd: {{ root }}/{{ app.name }}
    - onchanges:
      - file: dj_{{ app.name }}_install

dj_{{ app.name }}_venv:
  virtualenv.managed:
    - name: {{ venv }}
    - venv_bin: {{ app.get('virtualenv_bin', django.virtualenv_bin) }}
    - python: {{ app.get('python_bin', django.python_bin) }}
{% if app.requirements_file is defined %}
    - requirements: {{ root }}/{{ app.name }}/{{ app.requirements_file }}
{% endif %}
#    - user: {{ app.user }}
{% do deps.append('virtualenv: dj_' + app.name + '_venv') %}

# .env for decouple
dj_{{ app.name }}_env:
  file.managed:
    - name: {{ root }}/{{ app.name }}/.env
    - user: {{ app.user }}
    - group: {{ app.group }}
    {{ sls_block(app.env) | indent(4) }}
{% do deps.append('file: dj_' + app.name + '_env') %}

dj_{{ app.name }}_collectstatic:
  cmd.run:
    - name: '. {{ venv }}/bin/activate && python manage.py collectstatic --no-input'
    - cwd: {{ root }}/{{ app.name }}
    - runas: {{ app.user }}
    - shell: /bin/sh
    - onchanges:
      {{ labels(deps) | indent(6) }}

dj_{{ app.name }}_migrate:
  cmd.run:
    - name: '. {{ venv }}/bin/activate && python manage.py migrate'
    - cwd: {{ root }}/{{ app.name }}
    - runas: {{ app.user }}
    - shell: /bin/sh
    - onchanges:
      {{ labels(deps) | indent(6) }}

{% if app.touch is defined %}
dj_{{ app.name }}_touch:
  file.touch:
    - name: {{ app.touch }}
    - makedirs: true
    - onchanges:
      {{ labels(deps) | indent(6) }}
{% endif %}
