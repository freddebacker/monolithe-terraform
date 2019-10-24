from setuptools import setup, find_packages

setup(name='monolitheterraform',
      version='0.2',
      description='Terraform generator for monolithe',
      packages=find_packages(exclude=['ez_setup', 'examples', 'tests', '.git', '.gitignore', 'README.md']),
      include_package_data=True,
      
      # This is very important!
      #
      # This is how Monolithe will find and decide to use your plugin.
      # The entry point *MUST* be 'monolithe.plugin.lang.xxx' where 'xxx'
      # is what the user will enter as value for the '--language' option.
      # The the value *MUST* be an 'info:name_of_the_package:name_of_info_function'
      # keep things simple, and always use these names. Just adapt the package name.
      entry_points={'monolithe.plugin.lang.terraform': ['info=monolitheterraform:plugin_info']},
      )
