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
    "github.com/hashicorp/terraform/helper/schema"
    "github.com/rvichery/vspk-go/vspk"
    "github.com/nuagenetworks/go-bambou/bambou"
)

func dataSource{{ specification.entity_name }}() *schema.Resource {
    return &schema.Resource{
        Read: dataSource{{specification.entity_name}}Read,
        Schema: map[string]*schema.Schema{
            "filter": dataSourceFiltersSchema(),
            "parent_id": &schema.Schema{
                Type:     schema.TypeString,
                Computed: true,
            },
            "parent_type": &schema.Schema{
                Type:     schema.TypeString,
                Computed: true,
            },
            "owner": &schema.Schema{
                Type:     schema.TypeString,
                Computed: true,
            },
            {%- for attribute in specification.attributes %}
            {%- if attribute.local_name.lower() not in ["connection", "count", "depends_on", "id", "lifecycle", "provider", "provisioner"] %}
            "{{ attribute.local_name|lower }}": &schema.Schema{
                Type:     {{ get_terraform_type(attribute.type) }},
                Computed: true,
                {%- if get_terraform_type(attribute.type) == "schema.TypeList" %}
                Elem:     &schema.Schema{Type: schema.TypeString},
                {%- endif %}
            },
            {%- endif %}
            {%- endfor %}
            {%- for api in parent_apis %}
            {%- if api.actions.get %}
            {%- if api.remote_spec.instance_name != "me" %}
            "parent_{{ api.remote_spec.instance_name }}": &schema.Schema{
                Type:     schema.TypeString,
                {%- if parent_apis | length == 1 %}
                Required: true,
                {%- else %}
                Optional: true,
                {%- if (parent_apis | selectattr('actions.get') | map(attribute='remote_spec.instance_name') | reject('equalto', api.remote_spec.instance_name) | reject('equalto', 'me')| list | length) >= 1 %}
                ConflictsWith: []string{% raw %}{{% endraw %}"parent_{{ parent_apis | selectattr('actions.get') | map(attribute='remote_spec.instance_name') | reject('equalto', api.remote_spec.instance_name) | reject('equalto', 'me')|join('", "parent_') }}{% raw %}"}{% endraw %},
                {%- endif %}
                {%- endif %}
            },
            {%- endif %}
            {%- endif %}
            {%- endfor %}
        },
    }
}


func dataSource{{specification.entity_name}}Read(d *schema.ResourceData, m interface{}) error {
    filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}} := vspk.{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}List{}
    err := &bambou.Error{}
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

    {%- if parent_apis | length == 1 %}
        {%- if parent_apis[0].remote_spec.instance_name != "me" and parent_apis[0].actions.get %}
    parent := &vspk.{{ parent_apis[0].remote_spec.entity_name }}{ID: d.Get("parent_{{ parent_apis[0].remote_spec.instance_name }}").(string)}
    filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}, err = parent.{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}(fetchFilter)
    if err != nil {
        return err
    }
        {%- else %}
    parent := m.(*vspk.Me)
    filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}, err = parent.{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}(fetchFilter)
    if err != nil {
        return err
    }
        {%- endif %}
    {%- else %}
        {%- for api in (parent_apis | selectattr('remote_spec.instance_name', 'ne', 'me')) %}
            {%- if api.actions.get %}
                {%- if loop.first %}
    if attr, ok := d.GetOk("parent_{{ api.remote_spec.instance_name }}"); ok {
                {%- else %}
    } else if attr, ok := d.GetOk("parent_{{ api.remote_spec.instance_name }}"); ok {
                {%- endif %}
        parent := &vspk.{{ api.remote_spec.entity_name }}{ID: attr.(string)}
        filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}, err = parent.{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}(fetchFilter)
        if err != nil {
            return err
        }
                {%- if loop.last %}
                    {%- if (parent_apis | selectattr('remote_spec.instance_name', 'eq', 'me')| list | length) == 0 %}
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
            {%- endif %}
        {%- endfor %}
    {%- endif %}

    {{specification.entity_name}} := &vspk.{{specification.entity_name[0:1].upper() + specification.entity_name[1:]}}{}

    if len(filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}) < 1 {
        return fmt.Errorf("Your query returned no results. Please change your search criteria and try again.")
    }

    if len(filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}) > 1 {
        return fmt.Errorf("Your query returned more than one result. Please try a more " +
            "specific search criteria.")
    }
    
    {{specification.entity_name}} = filtered{{specification.entity_name_plural[0:1].upper() + specification.entity_name_plural[1:]}}[0]

    {% for attribute in specification.attributes %}
    {%- if attribute.local_name.lower() not in ["connection", "count", "depends_on", "id", "lifecycle", "provider", "provisioner"] %}
    {%- set field_name = attribute.name[0:1].upper() + attribute.name[1:] -%}
    d.Set("{{ attribute.local_name|lower }}", {{specification.entity_name}}.{{ field_name }})
    {%- endif %}
    {% endfor %}
    d.Set("id", {{specification.entity_name}}.Identifier())
    d.Set("parent_id", {{specification.entity_name}}.ParentID)
    d.Set("parent_type", {{specification.entity_name}}.ParentType)
    d.Set("owner", {{specification.entity_name}}.Owner)

    d.SetId({{specification.entity_name}}.Identifier())
    
    return nil
}