#!/usr/bin/env python

"""
Example Usage:
"""

import argparse
from subprocess import Popen, PIPE

def which(module, result):
  result = command([ "which", module.params['name'] ], result)
  if result['rc'] == 0:
    result['present'] = True
  elif result['rc'] == 1 and result['failed'] == False:
    result['rc'] = 0 # not found is not an error
    result['present'] = False
  else:
    result['failed']  = True
    result['present'] = False

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


###############################################################################

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
    "name"  : {"required": True,  "type": "str"}
  }

  module = AnsibleModule(argument_spec=fields)
  result = which(module, result)
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
