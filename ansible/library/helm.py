#!/usr/bin/env python

"""
Example Usage:
"""

import argparse
from subprocess import Popen, PIPE

def resource_present(module, result):
  result = get_resource(module, result)
  if result['rc'] == 0:
    if not result['present']:
      result = apply_resource(module, result)

  return result

def resource_absent(module, result):
  result = get_resource(module, result)
  if result['rc'] == 0:
    if result['present']:
      result = delete_resource(module, result)

  return result

#############################################################################

def get_resource(module, result):
  if module.params['namespace']:
    ns = [ "--namespace", module.params['namespace'] ]
  else:
    ns = []

  result = command(["helm", "list", module.params['name']] + ns, result)

  if result['rc'] == 0:
    if module.params['name'] in result['stdout'] and 'DEPLOYED' in result['stdout']:
      result['present'] = True
    else:
      result['present'] = False
  else:
    result['failed']  = True
    result['present'] = False

  return result

def apply_resource(module, result):
  if module.params['namespace']:
    ns = [ "--namespace", module.params['namespace'] ]
  else:
    ns = []

  if module.params['manifest']:
    manifest = [ "-f", module.params['manifest'] ]
  else:
    manifest = []

  if module.params['options']:
    options = module.params['options'].split(' ')
  else:
    options = []

  result['changed'] = True
  if result['present']:
    result = command(["helm", "upgrade", module.params['chart'], "--name", module.params['name']] + ns + manifest + options, result)
  else:
    result = command(["helm", "install", module.params['chart'], "--name", module.params['name']] + ns + manifest + options, result)
  return result

def delete_resource(module, result):
  if module.params['options']:
    options = module.params['options'].split(' ')
  else:
    options = []

  result['changed'] = True
  result = command(["helm", "delete", module.params['name']] + options, result)

  return result

def command(args, result):
  args = map(str, args)
  result['cmd'] = ' '.join(args)
  try:
    popen = Popen(args, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    result['stdout'], result['stderr'] = popen.communicate()
    result['rc'] = popen.returncode
    result['msg'] = '[' + str(popen.returncode) + '] ' + result['cmd'] + ' => ' + result['stdout']
  except Exception, e:
    result['failed'] = True
    result['rc'] = -32767
    result['stdout'] = 'n/a'
    result['stderr'] = str(e)
    result['msg'] = '[KO] ' + result['cmd'] + ' => ' + result['stderr']
  result['stdout_lines'] = result['stdout'].splitlines()
  result['stderr_lines'] = result['stderr'].splitlines()
  return result

#############################################################################

try:
  import json
except ImportError:
  import simplejson as json

import datetime

def main():
  result = {
    "changed": False,
    "failed":  False,
    "rc":  0,
    "start": datetime.datetime.now()
  }

  fields = {
    "name"      : {"required": True,  "type": "str"},
    "chart"     : {"required": False, "type": "str"},
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
    "status":  get_resource,
  }

  module = AnsibleModule(argument_spec=fields)
  result = choice_map.get(module.params['state'])(module, result)

  result['end'] = datetime.datetime.now()
  result['delta'] = str(result['end'] - result['start'])
  result['start'] = str(result['start'])
  result['end'] = str(result['end'])
  if result['failed']:
    module.fail_json(**result)
  else:
    module.exit_json(**result)    

###############################################################################

from ansible.module_utils.basic import AnsibleModule

if __name__ == '__main__':
   main()
