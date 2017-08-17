# Noa

Noa is an OAuth2 Server Implementation. This is still a work-in-progress. It currently supports the following:

-   Authorization Code Grant
-   Implicit Grant
-   Client Credentials Grant
-   Refresh Token Grant

Resource Owner Credentials Grant is not supported. Besides this,
there is no support for custom grant types.

> Noa Installation Instructions are available further down on this page.

### Authorization Providers

Noa has the ability to support segmentation/isolation of authorization.
Any request approvals and issued tokens are confined to that context.
The authorization related services (`authorize`, `issue`,
`introspect`, `revoke`) provided in such isolation are known as
"Authorization Providers". Each authorize service provider has its
own "Provider URL" that looks like:

```
http://my.noa:4000/as/v1/6n33hfmvplm2sbctpuppz2upajrqvzup
```

The specific operation URLs for such a provider will look like:

```
http://my.noa:4000/as/v1/6n33hfmvplm2sbctpuppz2upajrqvzup/authorize
http://my.noa:4000/as/v1/6n33hfmvplm2sbctpuppz2upajrqvzup/issue
http://my.noa:4000/as/v1/6n33hfmvplm2sbctpuppz2upajrqvzup/introspect
http://my.noa:4000/as/v1/6n33hfmvplm2sbctpuppz2upajrqvzup/revoke
```

Out of these, `authorize` is supported as an HTTP GET request.
The rest of them are only supported with HTTP POST.

### Provider and Client Registrations

At this point in time there are no REST APIs or Web based administration
for managing Authorization Providers and OAuth Clients. Low level
APIs are available for these. A simple seeding mechnism is provided
to bootstrap the system using these low-level APIs. (Follow along the
installation instructions on how to set this up.)

### Resource Owner approvals

At its core, Noa is an OAuth2 system. It has to rely on other systems for
Resource Owner authentication during authorization request approval
during "Authorization Code Grant" and "Implicit Grant" flows. It does
have built-in ability to do prompt for end user consent once the
user is authenticated. For a successful adoption, Noa needs a
better integration story.

As it stands right now, this is pegged on Ueberauth. A "Quickstart"
show-me-how implementation is included. This implementation simply
authenticates the end use based on information in a credential file.

Other "enterprise-y" approaches such as fronting Noa with the likes of
Nginx for authentication and having Nginx make "authenticated user"
available in as a request header in a proxy forward would work as well.

### Noa Playground

There is a companion Github Repo [Noa Playground](https://github.com/handnot2/noa_playground).
This is very similar to Google OAuth2 Playground. Once Noa is setup and running
you can use Noa Playground to try-out Authorization Code Grant flow
end-to-end without writing any code!

Make sure to get Noa installed before you follow the instructions on setting up the playground.

## Installation

Make sure that you have Elixir 1.5.0/Erlang 20.0.x, Nodejs, npm
and Docker installed.

### Build Docker Image

```
git clone https://github.com/handnot2/noa
cd noa
mix deps.get
cd assets
npm install
cd ..
mix compile
sudo mix docker.build --no-cache
sudo mix docker.release --no-cache
```

> If you have any issues with PATH when doing `docker.build` and
> `docker.release` commands, insert `env "PATH=$PATH"` between sudo
> and mix in the above commands.

### Noa Installation using Docker Image

```
./noa_docker_init.sh ${HOME}/mynoa
cd ${HOME}/mynoa
vim seeds/ro_quickstart.creds
./noa_docker_seed.sh
```

Checkout the `README.md` file in `${HOME}/mynoa` for instructions on
`seeds/ro_quickstart.creds` file.

At the end of this you will have a docker based instance of Noa running.
From this point out, you simply use `docker-compose` to manage Noa.

> Make sure to add
>
> `127.0.0.1 my.noa`
>
> To your `/etc/hosts` file.

Head over to [Noa Playground](https://github.com/handnot2/noa_playground).
Instructions over there show how to setup your own local OAuth2 Playground
to work with Noa.
