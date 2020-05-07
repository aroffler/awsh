# Ubuntu AWSH

#### Why
- Alpine deployment does not natively support a select set of the AWS CLI tools that are needed for instance access. specifically the AWS SSM session manager.
- Python2 is in a deprecated state, and is no longer supported by the major linux distros as a viable production environment.
- Ubuntu:Bionic is the most stable deployment from ubuntu that is ready for dockerized use.

#### Changes and updates

- Alpine os changed to Ubuntu:Bionic
- Package manager changed to Apt-get
- Terraform binaries added for both `Terraform 0.11.3` and `Terraform 0.12.24`
- Python3 requirements file built
- Adduser changed to debian command, with silenced no-password request
- Added ENV variable for silencing package manager screen requests. all packages use a default value.
- SAM CLI deployed
- SSM Session Manager deployed
- Ruby install changed to include update method for install cleanup, as --no-ri is now a unsupported and deprecated option.
- Split the various package and install scripts into pre-build , build, post build run deployments for my own sanity.


#### TODO
- Convert python2 scripts fully to python3 and remove any dependancy on deprecated python2 and pip installed packages where possible. Some of these changes will include `iteritems`, `print`, and `urlparse`.
	* bin/subcommands/awsh-sg-add
	* bin/subcommands/awsh-token-krb5formauth-create
	* bin/subcommands/awsh-token-mfaauth-create
	* bin/subcommands/awsh-vpc-viz
	* bin/tools/awsh-arnsplit
	* bin/tools/awsh-json2orderedtable
	* bin/tools/awsh-json2properties
	* lib/python/*
- trim out uneeded packages between pip and pip3 and apt that are bloating the build process.


#### Deployment
Can use same deployment strategy as Alpine AWSH box, for now is repo local only, no docker image in docker.io. Just pull down the ubuntu-image branch, build, and point to your local image.
