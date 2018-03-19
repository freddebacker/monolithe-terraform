package nuagenetworks

import (
    "errors"
    "log"
    "crypto/tls"
    "github.com/hashicorp/terraform/helper/schema"
    "github.com/hashicorp/terraform/terraform"
    "github.com/rvichery/vspk-go/vspk"
)

func Provider() terraform.ResourceProvider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            // Only supporting cert based authentication for now
            // "username": &schema.Schema{
            //     Type:        schema.TypeString,
            //     Required:    true,
            //     DefaultFunc: schema.EnvDefaultFunc("VSD_USERNAME", "csproot"),
            // },
            // "password": &schema.Schema{
            //     Type:        schema.TypeString,
            //     Required:    true,
            //     Sensitive:   true,
            //     DefaultFunc: schema.EnvDefaultFunc("VSD_PASSWORD", "csproot"),
            // },
            // "enterprise": &schema.Schema{
            //     Type:        schema.TypeString,
            //     Required:    true,
            //     DefaultFunc: schema.EnvDefaultFunc("VSD_ORGANIZATION", "csp"),
            // },
            "certificate_path": &schema.Schema{
                Type:        schema.TypeString,
                Required:    true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_CERTIFICATE_PATH", nil),
            },
            "key_path": &schema.Schema{
                Type:        schema.TypeString,
                Required:    true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_KEY_PATH", nil),
            },
            
            "vsd_endpoint": &schema.Schema{
                Type:        schema.TypeString,
                Required:    true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_ENDPOINT", nil),
            },
        },
        ConfigureFunc: providerConfigure,
        DataSourcesMap: map[string]*schema.Resource{
            {%- for specification in specification_set_datasources %}
            "nuagenetworks_{{ specification.instance_name }}": dataSource{{ specification.entity_name }}(),
            {%- endfor %}
        },
        ResourcesMap: map[string]*schema.Resource{
            {%- for specification in specification_set_resources %}
            "nuagenetworks_{{ specification.instance_name }}": resource{{ specification.entity_name }}(),
            {%- endfor %}
        },
    }
}

func providerConfigure(d *schema.ResourceData) (interface{}, error) {
    // s, root := vspk.NewSession(d.Get("username").(string), d.Get("password").(string), d.Get("enterprise").(string), d.Get("vsd_endpoint").(string))

    cert, tlsErr := tls.LoadX509KeyPair(d.Get("certificate_path").(string), d.Get("key_path").(string))
    if tlsErr != nil {
        return nil, errors.New("Error loading VSD generated certificates to authenticate with VSD: " + tlsErr.Error())
    }
    s, root := vspk.NewX509Session(&cert, d.Get("vsd_endpoint").(string))

    log.Println("[INFO] Initializing Nuage Networks VSD client")
    err := s.Start()
    if err != nil {
        return nil, errors.New("Unable to connect to Nuage VSD: " + err.Description)
    }
    log.Println("[INFO] Nuage Networks VSD client initialized")

    return root, nil
}
