#!/usr/bin/env python

"""
Example Usage:
"""

import argparse
from subprocess import Popen, PIPE

def package_status(module):
  is_error    = False
  has_changed = False
  meta        = {}

  rc, present, meta = which(module)
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

#############################################################################

def which(module):
  command = ["which", module.params['name']]
  rc, meta = _exec(command)
  if rc == 0:
    return 0, True, meta
  elif rc == 1: # and (module.params['name'] + ' not found') in meta['stdout']:
    return 0, False, meta
  else:
    return rc, False, meta

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


###############################################################################

def main():
  fields = {
    "name"  : {"required": True,  "type": "str"}
  }

  module = AnsibleModule(argument_spec=fields)
  is_error, has_changed, result = package_status(module)

  if not is_error:
    module.exit_json(changed=has_changed, meta=result)
  else:
    module.fail_json(msg="Error WHICH", meta=result)

###############################################################################

from ansible.module_utils.basic import AnsibleModule

if __name__ == '__main__':
   main()
