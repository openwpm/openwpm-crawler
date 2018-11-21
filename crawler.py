from __future__ import absolute_import

import os

from six.moves import range

import crawl_utils as cu
from OpenWPM.automation import CommandSequence, TaskManager

NUM_BROWSERS = 15
OUTPUT_NAME = 'XXX'
SITES = ['http://' + x for x in cu.get_top_1m(
    os.path.expanduser('~/Desktop/%s/' % OUTPUT_NAME))]

manager_params, browser_params = TaskManager.load_default_params(NUM_BROWSERS)

for i in range(NUM_BROWSERS):
    browser_params[i]['cookie_instrument'] = True
    browser_params[i]['js_instrument'] = True
    browser_params[i]['save_javascript'] = True
    browser_params[i]['http_instrument'] = True
    browser_params[i]['headless'] = True

manager_params['data_directory'] = '~/Desktop/%s/' % OUTPUT_NAME
manager_params['log_directory'] = '~/Desktop/%s/' % OUTPUT_NAME
manager_params['output_format'] = 's3'
manager_params['s3_bucket'] = 'openwpm-crawls'
manager_params['s3_directory'] = OUTPUT_NAME

manager = TaskManager.TaskManager(manager_params, browser_params)
for site in SITES[0:10000]:
    command_sequence = CommandSequence.CommandSequence(site, reset=True)
    command_sequence.get(sleep=10, timeout=60)
    manager.execute_command_sequence(command_sequence)
manager.close()
