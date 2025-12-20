# -*- coding: utf-8 -*-
# Custom YAML callback plugin compatible with ansible-core >=2.19

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
    author: mac-dev-playbook maintainers
    name: readable_yaml
    type: stdout
    short_description: YAML formatted callback output that works with modern ansible-core
    description:
        - Provides readable YAML output similar to community.general.yaml but
          compatible with the Ansible dumper changes in 2.19+.
    extends_documentation_fragment:
      - default_callback
    requirements:
      - set as stdout in configuration
'''

import json
import re
import string
import yaml

from ansible.module_utils.common.text.converters import to_text

try:  # ansible-core >= 2.19 requires accessing the class via the internal module
    from ansible._internal._yaml import _dumper as _ansible_yaml_dumper
    BaseDumper = _ansible_yaml_dumper.AnsibleDumper
except Exception:  # pragma: no cover - fallback for older ansible releases
    from ansible.parsing.yaml.dumper import AnsibleDumper as BaseDumper

from ansible.plugins.callback import strip_internal_keys, module_response_deepcopy
from ansible.plugins.callback.default import CallbackModule as Default


def should_use_block(value):
    """Returns true if string should be in block format"""
    for c in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
        if c in value:
            return True
    return False


class ReadableDumper(BaseDumper):
    """Custom dumper that keeps multi-line strings readable."""

    def represent_scalar(self, tag, value, style=None):
        if style is None and isinstance(value, str):
            if should_use_block(value):
                style = '|'
                value = value.rstrip()
                value = ''.join(x for x in value if x in string.printable or ord(x) >= 0xA0)
                value = value.expandtabs()
                value = re.sub(r'[\x0b\x0c\r]', '', value)
                value = re.sub(r' +\n', '\n', value)
            else:
                style = self.default_style
        node = yaml.representer.ScalarNode(tag, value, style=style)
        if self.alias_key is not None:
            self.represented_objects[self.alias_key] = node
        return node


class CallbackModule(Default):
    """
    Variation of the Default output which uses nicely readable YAML instead
    of JSON for printing results.
    """

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'readable_yaml'

    def __init__(self):
        super(CallbackModule, self).__init__()

    def _dump_results(self, result, indent=None, sort_keys=True, keep_invocation=False):
        if result.get('_ansible_no_log', False):
            return json.dumps(dict(censored="The output has been hidden due to the fact that 'no_log: true' was specified for this result"))

        abridged_result = strip_internal_keys(module_response_deepcopy(result))

        if not keep_invocation and self._display.verbosity < 3 and 'invocation' in result:
            del abridged_result['invocation']

        if self._display.verbosity < 3 and 'diff' in result:
            del abridged_result['diff']

        if 'exception' in abridged_result:
            del abridged_result['exception']

        dumped = ''

        if 'changed' in abridged_result:
            dumped += 'changed=' + str(abridged_result['changed']).lower() + ' '
            del abridged_result['changed']

        if 'skipped' in abridged_result:
            dumped += 'skipped=' + str(abridged_result['skipped']).lower() + ' '
            del abridged_result['skipped']

        if 'stdout' in abridged_result and 'stdout_lines' in abridged_result:
            abridged_result['stdout_lines'] = '<omitted>'

        if 'stderr' in abridged_result and 'stderr_lines' in abridged_result:
            abridged_result['stderr_lines'] = '<omitted>'

        if abridged_result:
            dumped += '\n'
            dumped += to_text(yaml.dump(abridged_result, allow_unicode=True, width=1000, Dumper=ReadableDumper, default_flow_style=False))

        dumped = '\n  '.join(dumped.split('\n')).rstrip()
        return dumped

    def _serialize_diff(self, diff):
        return to_text(yaml.dump(diff, allow_unicode=True, width=1000, Dumper=BaseDumper, default_flow_style=False))
