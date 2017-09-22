import os
import errno
import json as js
if not hasattr(js, 'dumps'):
    js = js.json

try:
    from ansible.plugins.callback import CallbackBase
except ImportError:
    print "Fallback to Ansible 1.x compatibility"
    CallbackBase = object

class CallbackModule(CallbackBase):
    """
    This Ansible callback plugin flags idempotency tests failures
    """
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'changes'
    CALLBACK_NEEDS_WHITELIST = True

    def __init__(self):
        super(CallbackModule, self).__init__()

        self.change_file = os.getenv('PLUGIN_CHANGES_FILE', "/tmp/kitchen_ansible_callback/changes")
        change_dir = os.path.dirname(self.change_file)
        if not os.path.exists(change_dir):
            os.makedirs(change_dir)

        try:
            os.remove(self.change_file)
        except OSError as e: # this would be "except OSError, e:" before Python 2.6
            if e.errno != errno.ENOENT: # errno.ENOENT = no such file or directory
                raise # re-raise exception if a different error occurred


    def write_changed_to_file(self, host, res, name=None):
        changed_data = dict()
        invocation = res.get("invocation", {})
        changed_data["changed_module_args"] = invocation.get("module_args", "")
        changed_data["changed_module_name"] = invocation.get("module_name", "")
        changed_data["host"] = host
        if name:
            changed_data["task_name"] = str(name)
        changed_data["changed_msg"] = res.get("msg", "")

        try:
            with open(self.change_file, 'at') as the_file:
                the_file.write(js.dumps(changed_data) + "\n")
        except Exception, e:
            print "Ansible callback idempotency: Write to file failed '%s' error:'%s'" % (self.change_file, e)
            exit(1)

    def on_any(self, *args, **kwargs):
        pass

    def runner_on_failed(self, host, res, ignore_errors=False):
        pass

    def runner_on_ok(self, host, res):
        if res.get("changed"):
            self.write_changed_to_file(host, res, self.current_task)

    def runner_on_skipped(self, host, item=None):
        pass

    def runner_on_unreachable(self, host, res):
        pass

    def runner_on_no_hosts(self):
        pass

    def runner_on_async_poll(self, host, res, jid, clock):
        pass

    def runner_on_async_ok(self, host, res, jid):
        pass

    def runner_on_async_failed(self, host, res, jid):
        pass

    def playbook_on_start(self):
        pass

    def playbook_on_notify(self, host, handler):
        pass

    def playbook_on_no_hosts_matched(self):
        pass

    def playbook_on_no_hosts_remaining(self):
        pass

    def playbook_on_task_start(self, name, is_conditional):
        self.current_task = name

    def playbook_on_vars_prompt(self, varname, private=True, prompt=None, encrypt=None, confirm=False, salt_size=None, salt=None, default=None):
        pass

    def playbook_on_setup(self):
        pass

    def playbook_on_import_for_host(self, host, imported_file):
        pass

    def playbook_on_not_import_for_host(self, host, missing_file):
        pass

    def playbook_on_play_start(self, name):
        pass

    def playbook_on_stats(self, stats):
        print "Call back end"