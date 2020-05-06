#!/usr/bin/env python

import os
import commands
import socket
import time
import logging
import traceback
from resource_management.libraries.functions import hive_check
from resource_management.libraries.functions import format
from resource_management.libraries.functions import get_kinit_path
from ambari_commons.os_check import OSConst
from ambari_commons.os_family_impl import OsFamilyFuncImpl, OsFamilyImpl
from resource_management.core.signal_utils import TerminateStrategy


HIVE_SERVER_THRIFT_PORT_KEY = '{{hive-site/hive.server2.thrift.port}}'
HIVESERVER2_PORT_DEFAULT = 10000

# script parameter keys
WARN_CEIL_P = 'check.warning.value'
CRITICAL_FLOOR_P = 'check.critical.value'


def get_tokens():
  """
  Returns a tuple of tokens in the format {{site/property}} that will be used
  to build the dictionary passed into execute

  :rtype tuple
  """
  return (HIVE_SERVER_THRIFT_PORT_KEY)


def getstatus(numcon, WARN_CEIL, CRITICAL_FLOOR):
    if numcon >= WARN_CEIL and numcon < CRITICAL_FLOOR:
        result_code = 'WARNING'
        label = "Total number of Active HS2 connection ", numcon
    if numcon < WARN_CEIL:
        result_code = 'OK'
        label = "Total number of Active HS2 connection ", numcon
    if numcon >= CRITICAL_FLOOR:
        result_code = 'CRITICAL'
        label = "Total number of Active HS2 connection ", numcon
    return ((result_code, [label]))


def execute(configurations={}, parameters={}, host_name=None):
    
    port = 10000
    if  HIVE_SERVER_THRIFT_PORT_KEY in configurations:
         port = int(configurations[HIVE_SERVER_THRIFT_PORT_KEY])
    cmdstring = "netstat -tpln | grep %s | awk '{print $7}'" % (port)
    result = commands.getoutput(cmdstring)
    cmdstringnetstat = "netstat -anp | grep %s | grep %s | grep ESTABLISHED | wc -l" % (port, result)
    numconnections = commands.getoutput(cmdstringnetstat)
    WARN_CEIL = int(parameters[WARN_CEIL_P])
    CRITICAL_FLOOR = int(parameters[CRITICAL_FLOOR_P])
    status = getstatus(int(numconnections), WARN_CEIL, CRITICAL_FLOOR)
    return status
