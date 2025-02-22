{% macro get_terraform_type(type) -%}
    {%- if type == "enum" or type == "string" -%}
    schema.TypeString
    {%- elif type == "integer" -%}
    schema.TypeInt
    {%- elif type == "float" -%}
    schema.TypeFloat
    {%- elif type == "integer" -%}
    schema.TypeInt
    {%- elif type == "list" -%}
    schema.TypeList
    {%- elif type == "time" -%}
    schema.TypeFloat
    {%- elif type == "boolean" -%}
    schema.TypeBool
    {%- else -%}
    schema.TypeString
    {%- endif -%}
{%- endmacro -%}

{% macro get_default_value(attribute) -%}
    {%- if attribute.type == "string" or attribute.type == "enum" -%}
    "{{ attribute.default_value }}"
    {%- else -%}
    {{ attribute.default_value }}
    {%- endif -%}
{%- endmacro -%}

package nuagenetworks

import (
    "fmt"
    "github.com/hashicorp/terraform-plugin-sdk/helper/schema"
    "github.com/hashicorp/terraform-plugin-sdk/helper/resource"
    "github.com/nuagenetworks/vspk-go/vspk"
    "github.com/nuagenetworks/go-bambou/bambou"
)

func dataSource{{ specification.entity_name }}s() *schema.Resource {
    return &schema.Resource{
        Read: dataSource{{specification.entity_name}}sRead,
        Schema: map[string]*schema.Schema{
            "filter": &schema.Schema{
                Type:     schema.TypeSet,
                Optional: true,
                ForceNew: true,
                Elem: &schema.Resource{
                    Schema: map[string]*schema.Schema{
                        "key": {
                            Type:     schema.TypeString,
                            Required: true,
                        },
                        "operator": {
                            Type:     schema.TypeString,
                            Optional: true,
                            Default:  "==",
                        },
                        "value": {
                            Type:     schema.TypeString,
                            Required: true,
                        },
                    },
                },
            },
            "keys": {
                Type:     schema.TypeList,
                Computed: true,
                Elem:     &schema.Schema{Type: schema.TypeString},
            },
            {%- for api in parent_apis %}
            {%- if api.actions.get %}
            {%- if api.remote_spec.instance_name|lower != "me" %}
            "parent_{{ api.remote_spec.instance_name|lower }}": &schema.Schema{
                Type:     schema.TypeString,
                {%- if parent_apis | length == 1 %}
                Required: true,
                {%- else %}
                Optional: true,
                {%- if (parent_apis | selectattr('actions.get') | map(attribute='remote_spec.instance_name') | reject('equalto', api.remote_spec.instance_name) | map('lower') | reject('equalto', 'me')| list | length) >= 1 %}
                ConflictsWith: []string{% raw %}{{% endraw %}"parent_{{ parent_apis | selectattr('actions.get') | map(attribute='remote_spec.instance_name') | reject('equalto', api.remote_spec.instance_name) | map('lower') | reject('equalto', 'me')|join('", "parent_') }}{% raw %}"}{% endraw %},
                {%- endif %}
                {%- endif %}
            },
            {%- endif %}
            {%- endif %}
            {%- endfor %}
        },
    }
}


func dataSource{{specification.entity_name}}sRead(d *schema.ResourceData, m interface{}) error {
    filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}} := vspk.{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}List{}
    {%- if parent_apis | length > 0 %}
    err := &bambou.Error{}
    {%- endif %}
    fetchFilter := &bambou.FetchingInfo{}
 
    filters, filtersOk := d.GetOk("filter")
    if filtersOk {
        fetchFilter = bambou.NewFetchingInfo()
        for _, v := range filters.(*schema.Set).List() {
            m := v.(map[string]interface{})
            if fetchFilter.Filter != "" {
                fetchFilter.Filter = fmt.Sprintf("%s AND %s %s '%s'", fetchFilter.Filter, m["key"].(string),  m["operator"].(string),  m["value"].(string))
            } else {
                fetchFilter.Filter = fmt.Sprintf("%s %s '%s'", m["key"].(string), m["operator"].(string), m["value"].(string))
            }
        }
    }

    {%- if (parent_apis | selectattr('actions.get') | list | length) == 1 %}
        {%- if parent_apis[0].remote_spec.entity_name | lower == "me" %}
    parent := m.(*vspk.Me)
        {%- else %}
    parent := &vspk.{{ parent_apis[0].remote_spec.entity_name[0:1].upper() + parent_apis[0].remote_spec.entity_name[1:] }}{ID: d.Get("parent_{{ parent_apis[0].remote_spec.instance_name|lower }}").(string)}
        {%- endif %}
    filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}, err = parent.{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}(fetchFilter)
    if err != nil {
        return err
    }
    {%- elif (parent_apis | selectattr('actions.get') | list | length) > 1 %}
        {%- for api in parent_apis | selectattr('actions.get') | rejectattr('remote_spec.instance_name', 'in', ['me', 'Me', 'mE', 'ME']) %}
            {%- if loop.first %}
    if attr, ok := d.GetOk("parent_{{ api.remote_spec.instance_name|lower }}"); ok {
            {%- else %}
    } else if attr, ok := d.GetOk("parent_{{ api.remote_spec.instance_name|lower }}"); ok {
            {%- endif %}
        parent := &vspk.{{ api.remote_spec.entity_name[0:1].upper() + api.remote_spec.entity_name[1:] }}{ID: attr.(string)}
        filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}, err = parent.{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}(fetchFilter)
        if err != nil {
            return err
        }
            {%- if loop.last %}
                {%- if (parent_apis | map(attribute='remote_spec.instance_name') | map('lower') | select('equalto', 'me')| list | length) == 0 %}
    }
                {%- else %}
    } else {
        parent := m.(*vspk.Me)
        filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}, err = parent.{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}(fetchFilter)
        if err != nil {
            return err
        }
    }
                {%- endif %}
            {%- endif %}
        {%- endfor %}
    {%- endif %}

    var keys []string
    for _, object := range filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}} {
        keys = append(keys, object.Identifier())
    }
    d.Set("keys", keys)

    d.SetId(resource.UniqueId())
    return nil
}
