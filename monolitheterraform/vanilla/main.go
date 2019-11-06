package main

import (
	"github.com/hashicorp/terraform-plugin-sdk/plugin"
	"terraform-provider-nuagenetworks/nuagenetworks"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: nuagenetworks.Provider})
}
