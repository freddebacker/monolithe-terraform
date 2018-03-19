# -*- coding: utf-8 -*-
#
# Copyright (c) 2015, Alcatel-Lucent Inc
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the copyright holder nor the names of its contributors
#       may be used to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from __future__ import unicode_literals
from builtins import str
import os
import shutil
from collections import OrderedDict

from monolithe.lib import SDKUtils, TaskManager
from monolithe.generators.lib import TemplateFileWriter
from monolithe.specifications import SpecificationAPI

class APIVersionWriter(TemplateFileWriter):
    """ Provide usefull method to write Python files.

    """
    def __init__(self, monolithe_config, api_info):
        """ Initializes a _PythonSDKAPIVersionFileWriter

        """
        super(APIVersionWriter, self).__init__(package="monolithe.generators.lang.terraform")

        self.api_version = api_info["version"]
        self.api_root = api_info["root"]
        self.api_prefix = api_info["prefix"]

        self.monolithe_config = monolithe_config
        self._output = self.monolithe_config.get_option("output", "transformer")
        self._transformation_name = self.monolithe_config.get_option("name", "transformer")
        self._class_prefix = self.monolithe_config.get_option("class_prefix", "transformer")
        self._product_accronym = self.monolithe_config.get_option("product_accronym")
        self._product_name = self.monolithe_config.get_option("product_name")

        self.output_directory = "%s/terraform/nuagenetworks/" % self._output

        with open("%s/terraform/__code_header" % self._output, "r") as f:
            self.header_content = f.read()

    def perform(self, specifications):
        """
        """
        self.resource_filenames = dict()
        self.fetcher_filenames = dict()
        self._resolve_parent_apis(specifications)
        task_manager = TaskManager()
        resources = []
        for _, specification in specifications.items():
            create = specification.allows_create
            for parent_api in specification.parent_apis:
                if parent_api.allows_create:
                    create = True
                    break
            if create:
                resources.append(specification)
                task_manager.start_task(method=self._write_resource, specification=specification, specification_set=specifications)
        
        datasources = []
        for _, specification in specifications.items():
            read = specification.allows_get
            for parent_api in specification.parent_apis:
                if parent_api.allows_get:
                    read = True
                    break
            if read:
                datasources.append(specification)     
                task_manager.start_task(method=self._write_datasource, specification=specification, specification_set=specifications)
        task_manager.wait_until_exit()

        self.write(destination = self.output_directory,
                   filename="provider.go",
                   template_name="provider.go.tpl",
                   class_prefix = self._class_prefix,
                   specification_set_resources = resources,
                   specification_set_datasources = datasources)
    
    def _get_actions(self, obj):
        return {
            'create': obj.allows_create,
            'get': obj.allows_get,
            'update': obj.allows_update,
            'delete': obj.allows_delete
        }

    def _write_resource(self, specification, specification_set):
        """ Write autogenerate specification file

        """
        filename = "resource_nuagenetworks_%s.go" % (specification.entity_name.lower())
        # override_content = self._extract_override_content(specification.entity_name)
        # constants = self._extract_constants(specification)
        superclass_name = "NURESTRootObject" if specification.rest_name == self.api_root else "NURESTObject"

        parent_apis = []
        for rest_name, remote_spec in specification_set.items():
            for related_child_api in remote_spec.child_apis:
                if related_child_api.rest_name == specification.rest_name and related_child_api.allows_create:
                    parent_apis.append({"remote_spec": remote_spec, "actions": self._get_actions(related_child_api), "relationship": related_child_api.relationship})
        if specification.rest_name == 'addressrange' :
            print(parent_apis[0]['remote_spec'].instance_name)
        self.write(destination=self.output_directory, filename=filename, template_name="resource.go.tpl",
                   specification=specification,
                   specification_set=specification_set,
                   version=self.api_version,
                   class_prefix=self._class_prefix,
                   product_accronym=self._product_accronym,
                   parent_apis=parent_apis,
                #    override_content=override_content,
                   superclass_name=superclass_name,
                #    constants=constants,
                   header=self.header_content)

        self.resource_filenames[filename] = specification.entity_name


    def _write_datasource(self, specification, specification_set):
        """ Write autogenerate specification file

        """
        filename = "data_source_nuagenetworks_%s.go" % (specification.entity_name.lower())
        # override_content = self._extract_override_content(specification.entity_name)
        # constants = self._extract_constants(specification)
        superclass_name = "NURESTRootObject" if specification.rest_name == self.api_root else "NURESTObject"

        parent_apis = []
        for rest_name, remote_spec in specification_set.items():
            for related_child_api in remote_spec.child_apis:
                if related_child_api.rest_name == specification.rest_name and related_child_api.allows_get:
                    parent_apis.append({"remote_spec": remote_spec, "actions": self._get_actions(related_child_api), "relationship": related_child_api.relationship})
        
        self.write(destination=self.output_directory, filename=filename, template_name="data.go.tpl",
                   specification=specification,
                   specification_set=specification_set,
                   version=self.api_version,
                   class_prefix=self._class_prefix,
                   product_accronym=self._product_accronym,
                   parent_apis=parent_apis,
                #    override_content=override_content,
                   superclass_name=superclass_name,
                #    constants=constants,
                   header=self.header_content)

        self.resource_filenames[filename] = specification.entity_name

    def _write_init_models(self, filenames):
        """ Write provider.go file

            Args:
                filenames (dict): dict of filename and classes

        """

        self.write(destination=self.output_directory, filename="__init__.py", template_name="__init_model__.py.tpl",
                   filenames=self._prepare_filenames(filenames),
                   class_prefix=self._class_prefix,
                   product_accronym=self._product_accronym,
                   header=self.header_content)

    def _resolve_parent_apis(self, specifications):
        """
        """
        for specification_rest_name, specification in specifications.items():
            specification.parent_apis[:] = []
            for rest_name, remote_spec in specifications.items():
                for related_child_api in remote_spec.child_apis:
                    if related_child_api.rest_name == specification.rest_name:
                        parent_api = SpecificationAPI(specification=remote_spec)
                        parent_api.rest_name = remote_spec.rest_name
                        if related_child_api.allows_get:
                            parent_api.allows_get = True
                        if related_child_api.allows_create:
                            parent_api.allows_create = True
                        if related_child_api.allows_update:
                            parent_api.allows_update = True
                        if related_child_api.allows_delete:
                            parent_api.allows_Delete = True

                        specification.parent_apis.append(parent_api)