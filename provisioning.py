#!/usr/bin/env python3
import fileinput
import inspect
import os
import re
import subprocess
import time
from datetime import datetime
from multiprocessing import Process
from subprocess import PIPE

env = dict(os.environ)


def _print_line_number(number_of_outer_frame=1):
    cf = inspect.currentframe()
    frame = cf
    for ii in range(number_of_outer_frame):
        frame = frame.f_back

    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    print('\n'.join(['#' * 40, '[%s] LINE NUMBER: %d' % (timestamp, frame.f_lineno), '#' * 40]))


def _run(cmd, file_path_name=None, cwd=None):
    def _f():
        if not file_path_name:
            _p = subprocess.Popen(cmd, cwd=cwd, env=env)
            _p.communicate()
            if _p.returncode != 0:
                raise Exception()
        else:
            with open(file_path_name, 'a') as f:
                _p = subprocess.Popen(cmd, stdout=f, cwd=cwd, env=env)
                _p.communicate()
                if _p.returncode != 0:
                    raise Exception()

    _print_line_number(2)
    cmd_string = ' '.join(cmd)
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    print('\n'.join(['#' * 40, '[%s] COMMAND: %s' % (timestamp, cmd_string), '#' * 40]))

    pp = Process(target=_f)
    pp.start()
    pp.join()
    if pp.exitcode != 0:
        raise Exception()


def _file_line_replace(file_path_name, str_old, str_new, backup='.bak'):
    with fileinput.FileInput(file_path_name, inplace=True, backup=backup) as f:
        for line in f:
            new_line = re.sub(str_old, str_new, line)
            print(new_line, end='')


def _settings_file_line_replace(settings_file_path_name, key, value, backup='.bak'):
    with fileinput.FileInput(settings_file_path_name, inplace=True, backup=backup) as f:
        for line in f:
            new_line = re.sub('^(' + key + ') .*', '\\1 = \'%s\'' % value, line)
            print(new_line, end='')


def _preprocess(hostname):
    _print_line_number()

    _file_line_replace('/etc/sysconfig/network', '^HOSTNAME=localhost.localdomain$', 'HOSTNAME=%s' % hostname)
    with open('/etc/hosts', 'a') as f:
        f.write('127.0.0.1 %s\n' % hostname)
    _run(['hostname', hostname])
    _run(['/etc/init.d/network', 'restart'])

    _print_line_number()

    with open('/etc/server_info', 'w') as f:
        f.write('AWS_EC2_INSTANCE_ID=i-01234567\n')
        f.write('AWS_EC2_AVAILABILITY_ZONE=my-local-1a\n')

    _print_line_number()

    _run(['fallocate', '-l', '2G', '/swapfile'])
    _run(['chmod', '600', '/swapfile'])
    _run(['mkswap', '/swapfile'])
    _run(['swapon', '/swapfile'])
    with open('/etc/fstab', 'a') as f:
        f.write('/swapfile	swap	swap	sw	0	0\n')

    _print_line_number()

    subprocess.Popen(['chpasswd'], stdin=PIPE).communicate(b'root:1234qwer')
    _file_line_replace('/etc/ssh/sshd_config', '^#PermitRootLogin yes$', 'PermitRootLogin yes')
    _file_line_replace('/etc/ssh/sshd_config', '^PasswordAuthentication no$', 'PasswordAuthentication yes')
    _run(['service', 'sshd', 'restart'])

    _print_line_number()

    _run(['yum-config-manager', '--enable', 'epel'])

    file_path_name = '/vagrant/requirements_rpm.txt'
    if os.path.exists(file_path_name):
        with open(file_path_name, 'r') as f:
            lines = f.readlines()
            for ll in lines:
                _run(['yum', '-y', 'install', ll.strip()])

    _print_line_number()

    file_path_name = '/vagrant/requirements.txt'
    if os.path.exists(file_path_name):
        _run(['pip-3.5', 'install', '--upgrade', 'pip'])
        with open(file_path_name, 'r') as f:
            lines = f.readlines()
            for ll in lines:
                _run(['/usr/local/bin/pip3', 'install', ll.strip()])


def main():
    hostname = 'dv-lili-my-local-1a-012345'

    _preprocess(hostname)

    _print_line_number()

    _run(['mkdir', '-p', '/etc/uwsgi'])
    _run(['mkdir', '-p', '/root/.ssh'])
    _run(['mkdir', '-p', '/var/log/raynor'])
    _run(['mkdir', '-p', '/var/log/uwsgi'])

    _print_line_number()

    cmd_common = ['cp', '--backup']
    file_list = list()
    file_list.append('/etc/init.d/raynor')
    file_list.append('/etc/nginx/conf.d/raynor.conf')
    file_list.append('/etc/nginx/nginx.conf')
    file_list.append('/etc/uwsgi/raynor.ini')
    for ff in file_list:
        cmd = cmd_common + ['/vagrant/configuration' + ff, ff]
        _run(cmd)

    _print_line_number()

    is_success = False
    for ii in range(10):
        print('Git clone try count: %d' % (ii + 1))
        # noinspection PyBroadException
        try:
            # Non interactive git clone (ssh fingerprint prompt)
            _run(['ssh-keyscan', 'github.com'], '/root/.ssh/known_hosts')
            _run(['git', 'clone', '--depth=1', 'https://github.com/HardBoiledSmith/johanna.git'], cwd='/opt')
            if os.path.exists('/opt/johanna'):
                is_success = True
                break
        except Exception:
            time.sleep(3)

    if not is_success:
        raise Exception()

    _print_line_number()

    is_success = False
    for ii in range(10):
        print('Git clone try count: %d' % (ii + 1))
        # noinspection PyBroadException
        try:
            # Non interactive git clone (ssh fingerprint prompt)
            _run(['ssh-keyscan', 'github.com'], '/root/.ssh/known_hosts')
            _run(['git', 'clone', '--depth=1', 'https://github.com/HardBoiledSmith/raynor.git'], cwd='/opt')
            if os.path.exists('/opt/raynor'):
                is_success = True
                break
        except Exception:
            time.sleep(3)

    if not is_success:
        raise Exception()

    _print_line_number()

    _run(['cp', 'config_sample.json', 'config.json'], cwd='/opt/johanna')
    _run(['./manage.py', 'collectstatic', '--noinput'], cwd='/opt/raynor')
    _run(['chkconfig', '--add', 'raynor'])
    _run(['chkconfig', 'nginx', 'on'])
    _run(['chkconfig', 'raynor', 'on'])
    _run(['chkconfig', 'redis', 'on'])
    _run(['reboot'])


if __name__ == "__main__":
    main()
