package nuagenetworks

import (
    "errors"
    "log"
    "crypto/tls"
    "github.com/hashicorp/terraform-plugin-sdk/terraform"
    "github.com/hashicorp/terraform-plugin-sdk/helper/schema"
    "github.com/nuagenetworks/vspk-go/vspk"
    "github.com/nuagenetworks/go-bambou/bambou"
)

func Provider() terraform.ResourceProvider {
    return &schema.Provider{
        Schema: map[string]*schema.Schema{
            "enterprise": &schema.Schema{
                Type:        schema.TypeString,
                Required:    true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_ORGANIZATION", "csp"),
            },
            "vsd_endpoint": &schema.Schema{
                Type:        schema.TypeString,
                Required:    true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_ENDPOINT", nil),
            },
            "username": &schema.Schema{
                Type:        schema.TypeString,
                Optional:    true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_USERNAME", "csproot"),
            },
            "password": &schema.Schema{
                Type:        schema.TypeString,
                Optional:    true,
                Sensitive:   true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_PASSWORD", "csproot"),
            },
            "certificate_path": &schema.Schema{
                Type:        schema.TypeString,
                Optional:    true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_CERTIFICATE_PATH", nil),
            },
            "key_path": &schema.Schema{
                Type:        schema.TypeString,
                Optional:    true,
                DefaultFunc: schema.EnvDefaultFunc("VSD_KEY_PATH", nil),
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

func providerConfigure(d *schema.ResourceData) (root interface{}, err error) {
    // if we have a certificate path, we use cert auth
    log.Println("[INFO] Initializing Nuage Networks VSD client")

    var s *bambou.Session

    if certPathRaw, certPathOk := d.GetOk("certificate_path"); certPathOk {
      cert, tlsErr := tls.LoadX509KeyPair(certPathRaw.(string), d.Get("key_path").(string))
      if tlsErr != nil {
          return nil, errors.New("Error loading VSD generated certificates to authenticate with VSD: " + tlsErr.Error())
      }
      s, root = vspk.NewX509Session(&cert, d.Get("vsd_endpoint").(string))
    } else {
      s, root = vspk.NewSession(d.Get("username").(string), d.Get("password").(string), d.Get("enterprise").(string), d.Get("vsd_endpoint").(string))
    }

    berr := s.Start()

    if berr != nil {
        err = errors.New("Unable to connect to Nuage VSD: " + berr.Description)
        return
    }

    log.Println("[INFO] Nuage Networks VSD client initialized")

    return
}
