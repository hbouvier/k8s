#!/usr/bin/env python

"""
Example Usage:
"""

import argparse
from subprocess import Popen, PIPE

def resource_status(module):
  is_error    = False
  has_changed = False
  meta        = {}

  rc, present, meta = get_resource(module)
  if rc != 0:
    is_error = True
    meta['present'] = False
    module.fail_json(
      msg='Error: ' + meta['cmd'] + ' rc=' + str(rc) + ' ' + meta['stderr'],
      cmd=meta['cmd'], out=meta['stdout'], err=meta['stderr'], rc=rc
    )
  else:
    meta['present'] = present
  return is_error, has_changed, meta

def resource_present(module):
  is_error    = False
  has_changed = False
  meta        = {}

  rc, present, meta = get_resource(module)
  if rc != 0:
    is_error = True
    module.fail_json(
      msg='Error: ' + meta['cmd'] + ' rc=' + str(rc) + ' ' + meta['stderr'],
      cmd=meta['cmd'], out=meta['stdout'], err=meta['stderr'], rc=rc
    )
  elif not present:
    rc, meta = apply_resource(module)
    if rc != 0:
      is_error = True
      module.fail_json(
        msg='Error: ' + meta['cmd'] + ' rc=' + str(rc) + ' ' + meta['stderr'],
        cmd=meta['cmd'], out=meta['stdout'], err=meta['stderr'], rc=rc
      )
    has_changed = True
  return is_error, has_changed, meta

def resource_absent(module):
  is_error = False
  has_changed = False
  meta    = {}

  rc, present, meta = get_resource(module)
  if rc != 0:
    is_error = True
    module.fail_json(
      msg='Error: ' + meta['cmd'] + ' rc=' + str(rc) + ' ' + meta['stderr'],
      cmd=meta['cmd'], out=meta['stdout'], err=meta['stderr'], rc=rc
    )
  elif present:
    rc, meta = delete_resource(module)
    if rc != 0:
      is_error = True
      module.fail_json(
        msg='Error: ' + meta['cmd'] + ' rc=' + str(rc) + ' ' + meta['stderr'],
        cmd=meta['cmd'], out=meta['stdout'], err=meta['stderr'], rc=rc
      )
    has_changed = True
  return is_error, has_changed, meta

#############################################################################

def get_resource(module):
  if module.params['namespace']:
    ns = [ "-n", module.params['namespace'] ]
  else:
    ns = []

  command = ["kubectl", "get", module.params['resource'], module.params['name']] + ns
  rc, meta = _exec(command)
  if rc == 0:
    return 0, True, meta
  elif rc == 1 and ( \
    ('"' + module.params['name'] +'" not found') in meta['stderr'] or \
    ('"' + module.params['namespace'] +'" not found') in meta['stderr'] \
  ):
    return 0, False, meta
  else:
    return rc, False, meta

def apply_resource(module):
  if module.params['namespace']:
    ns = [ "-n", module.params['namespace'] ]
  else:
    ns = []
  
  if module.params['type']:
    resource_type = module.params['type'].split(' ')
  else:
    resource_type = []

  if module.params['options']:
    options = module.params['options'].split(' ')
  else:
    options = []

  if module.params['manifest']:
    command = ["kubectl", "apply", "-f", module.params['manifest']] + ns
  else:
    command = ["kubectl", "create", module.params['resource']] + resource_type + [module.params['name']] + ns + options
  rc, meta = _exec(command)
  return rc, meta

def delete_resource(module):
  if module.params['namespace']:
    ns = [ "-n", module.params['namespace'] ]
  else:
    ns = []
  command = ["kubectl", "delete", module.params['resource'], module.params['name']] + ns
  rc, meta = _exec(command)
  return rc, meta

def _exec(args):
  args = map(str, args)
  command = ' '.join(args)
  try:
    popen = Popen(args, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    stdout, stderr = popen.communicate()
    rc = popen.returncode
  except Exception, e:
    rc = -10000
    stdout = ''
    stderr = str(e)
  msg =  "cmd='" + command + "'"
  if rc != 0:
    msg = "ERROR: rc=" + str(rc) + ", " + msg + " =>  " + stderr
  meta = {
    "rc" : rc,
    "cmd" : command,
    "stdout" : stdout,
    "stderr" : stderr,
    "msg" : msg
  }
  return rc, meta

#############################################################################

try:
    import json
except ImportError:
    import simplejson as json


###############################################################################

def main():
  fields = {
    "resource"  : {"required": True,  "type": "str"},
    "type"      : {"required": False, "type": "str"},
    "name"      : {"required": True,  "type": "str"},
    "namespace" : {"required": False, "type": "str"},
    "manifest"  : {"required": False, "type": "str"},
    "options"   : {"required": False, "type": "str"},
    "state": {
      "default": "present",
      "choices": ['present', 'absent', 'status'],
      "type": 'str'
    }
  }

  choice_map = {
    "present": resource_present,
    "absent":  resource_absent,
    "status":  resource_status,
  }

  module = AnsibleModule(argument_spec=fields)
  is_error, has_changed, result = choice_map.get(module.params['state'])(module)

  if not is_error:
    module.exit_json(changed=has_changed, meta=result)
  else:
    module.fail_json(msg="Error deleting resource", meta=result)

###############################################################################

from ansible.module_utils.basic import AnsibleModule

if __name__ == '__main__':
   main()
