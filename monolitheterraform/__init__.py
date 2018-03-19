__all__ = ['APIVersionWriter', 'VanillaWriter', 'plugin_info', 'get_idiomatic_name', 'get_type_name']

from .writers.apiversionwriter import APIVersionWriter
from .writers.vanillawriter import VanillaWriter
from .converter import get_idiomatic_name, get_type_name
def plugin_info():
    """ Entry point of your plugin. This will be called by Monolithe to check if
        it should use this plugin to generate a particular language.
    """

    return {
        # 'VanillaWriter' is used to copy some vanilla files.
        'VanillaWriter': VanillaWriter,

        # 'APIVersionWriter' is reponsible to write files for a particular api version.
        'APIVersionWriter': APIVersionWriter,

        # 'PackageWriter' is reponsible to assemble all the api version sets created by APIVersionWriter, if needed
        'PackageWriter': None,

        # 'CLIWriter' is reponsible to write a CLI if needed
        'CLIWriter': None,

        # 'get_idiomatic_name' is a function that will be called when a word from the specification
        # might need to get adjusted to respect the idioms of your language. for instance 'HelloWorld' in Python
        # should be translated to 'hello_world'
        'get_idiomatic_name': get_idiomatic_name,

        # 'get_type_name' is needed to translate a type from a specification to the name of the type used
        # by your language. For instance, a spec type 'list' needs to be translated to '[]<subtype>' in Go.
        'get_type_name':  get_type_name
    }
