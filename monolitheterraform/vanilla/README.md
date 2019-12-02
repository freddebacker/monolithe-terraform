# Build and install instructions

- Install [go](https://golang.org/dl/), see [instructions](https://golang.org/doc/install).
- Navigate to you the source folder in your go workspace; usually `$HOME/go/src`, unless you modified with `GOPATH` environment variable. (note: you might have to create this...)
- Clone this repo in your workspace's `src` folder
- Run `go build`
- See [Terraform documentation](https://www.terraform.io/docs/extend/how-terraform-works.html#plugin-locations) on where to put the binary for Terraform to find it.
