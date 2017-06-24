#!/usr/bin/env python

"""
Example Usage:
"""

import argparse, os
from subprocess import Popen, PIPE

def resource_present(module, result):
  result = get_resource(module, result)
  if result['rc'] == 0:
    if not result['present']:
      result = apply_resource(module, result)

  return result

def resource_apply(module, result):
  if module.params['manifest']:
    result = apply_resource(module, result)
  else:
    result = get_resource(module, result)
    if result['rc'] == 0:
      if result['present']:
        result = delete_resource(module, result)
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
    ns = [ "-n", module.params['namespace'] ]
  else:
    ns = []
  if module.params['jsonpath']:
    jsonpath = [ "-o", "jsonpath=" + module.params['jsonpath'] ]
  else:
    jsonpath = []

  result = command(["kubectl", "get", module.params['resource'], module.params['name']] + ns + jsonpath, result)

  if result['rc'] == 0:
    result['present'] = True
  elif result['rc'] == 1 and result['failed'] == False and ( \
    ('"' + module.params['name'] +'" not found') in result['stderr'] or \
    ('"' + module.params['namespace'] +'" not found') in result['stderr'] \
  ):
    result['rc'] = 0 # not found is not an error
    result['present'] = False
  else:
    result['failed']  = True
    result['present'] = False

  return result

def apply_resource(module, result):
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

  result['changed'] = True
  if module.params['manifest']:
    if module.params['manifest'].startswith('gs://'):
      filename = "/tmp/ansible.gs." + str(os.getpid()) + ".yaml"
      result = command(["gsutil", "cp", module.params['manifest'], filename], result)
      if result['rc'] == 0:
        result = command(["kubectl", "apply", "-f", filename] + ns, result)
      command(["rm", filename], {})
    else:
      result = command(["kubectl", "apply", "-f", module.params['manifest']] + ns, result)
  else:
    result = command(["kubectl", "create", module.params['resource']] + resource_type + [module.params['name']] + ns + options, result)
  return result

def delete_resource(module, result):
  if module.params['namespace']:
    ns = [ "-n", module.params['namespace'] ]
  else:
    ns = []

  result['changed'] = True
  result = command(["kubectl", "delete", module.params['resource'], module.params['name']] + ns, result)

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
    "resource"  : {"required": True,  "type": "str"},
    "type"      : {"required": False, "type": "str"},
    "name"      : {"required": True,  "type": "str"},
    "namespace" : {"required": False, "type": "str"},
    "manifest"  : {"required": False, "type": "str"},
    "options"   : {"required": False, "type": "str"},
    "jsonpath"  : {"required": False, "type": "str"},
    "state": {
      "default": "present",
      "choices": ['present', 'absent', 'status', 'apply'],
      "type": 'str'
    }
  }

  choice_map = {
    "present": resource_present,
    "apply"  : resource_apply,
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
