# loom-tm
Loom package for HPE's The Machine.  For more information on Loom look at its [github repo](https://github.com/HewlettPackard/loom).  This package incorporates the Loom server, [TM specific adaptor](http://https://github.com/HewlettPackard/loom-tm-adapter), the Management Dashboard using the default Loom user interface and also the Executive Dashboard using an [alternative front-end](http://https://github.com/HewlettPackard/loom-tm-ed).

This project is configured to pull down the version of Loom specified in `pom.xml` and the required versions of the adapter(s) which are placed in the `./adapters` folder.  Optional build stages are available for packaging and pushing Docker images.

## Building
Install Java 1.8

Install maven v3.3.9 upwards.

To build:

```
$ mvn clean install
```

Note that to ensure that the latest SNAPSHOT dependencies are being used the `-U` option should be used:

```sh
$ mvn -U clean install
```

## Running
You will need to reference `jetty-runner.jar` and `loom-server.jar` in order to run.  The required versions are stated in the `jetty-version` and `loom-version` variables in `pom.xml`.  The provided `deployment.properties` file must be used.

```
$ java -Ddeployment.properties=deployment.properties -jar target\jetty-runner.jar --config jetty.xml md-context.xml ed-context.xml loom-context.xml
```

If you wish to modify the logging output you may override the `log4j.properties` file packaged with Loom by specifying your own when you launch Loom, e.g.

```
$ java -Dlog4j.configuration=file:my-log4j.properties -Ddeployment.properties=deployment.properties -jar target\jetty-runner.jar --config jetty.xml md-context.xml ed-context.xml loom-context.xml
```

An example log4j configuration is provided in `example-log4j.properties`.

In order to support LDAP authentication (see section below), the location of the truststore must also be provided, e.g.:

```
$ java -Djavax.net.ssl.trustStore=truststore -Dlog4j.configuration=file:my-log4j.properties -Ddeployment.properties=deployment.properties -jar target\jetty-runner.jar --config jetty.xml md-context.xml ed-context.xml loom-context.xml
```

Depending on the demands of the loaded adapters, i.e. the amount of data managed by Loom, you will need to increase the default JVM heap size and preallocate for best performance, e.g.

```
$ java -Xmx2048m -Xms2048m -Ddeployment.properties=deployment.properties -jar target\jetty-runner.jar --config jetty.xml md-context.xml ed-context.xml loom-context.xml
```
 
### Authentication

If an email address is provided when asked for a username during login, the user will be authenticated with the configured Enterprise Directory.
The SSL connection to the LDAP service will fail unless a trust store is provided containing the directory's X.509 certificate.

To tell the JVM where the trust store is use set the `javax.net.ssl.trustStore` system property, e.g.:

```
$ java -Djavax.net.ssl.trustStore=truststore ...
```

If the trust store is not present, or a valid CA certificate cannot be found the following exception may be seen: `javax.naming.CommunicationException: simple bind failed: ldap:636 [Root exception is javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target]`

### Overriding jetty defaults
If you should need to move the location of/change the way the jar/war files are addressed, you can override the default paths used in `jetty.xml` by defining either or both of the `loom-server.path` and `weaver.path` system properties, e.g.

```
$ java -Dloom-server.path=/some/other/location/loom-server.war -Dweaver.path=/some/other/location/weaver.war ...
```

## Accessing Loom
Both the UIs and the Loom API can only be accessed via HTTPS.  The URL for the Management Dashboard is `https://localhost/md` and the Executive Dashboard can be found at `https://localhost/ed`.

> NOTE: a self-signed certificate is used by default and will cause a security exception in the browser which must be accepted before proceeding.  Instructions for getting and installing a certificate for a specific machine are given in the next section.

The Loom API is accessible via `https://localhost/loom`.

### Installing a CA-signed certificate

When the FQDN of the host is known, the `keystore` can be replaced after installation with a certificate signed by a valid CA to prevent the browser security exception.  In this example we create a certificate for the machine `themachine.local`.  When prompted for a password you should **always** supply the password specified in `jetty.xml`, e.g. `password`.

1) First of all download the required PEM encoded certificates for the CA.

2) Create the public/private key pair for the host in a *new* keystore (make sure there isn't a keystore of the same name in the working directory).  The `CN` (alias) must be the FQDN of the machine, e.g. `themachine.local`.  Other fields should be set as appropriate for your CA.

```
$ keytool -genkey -alias themachine -keyalg RSA -keystore keystore -keysize 2048
```

3) Create the CSR.

```
4 keytool -certreq -alias themachine -file themachine.csr -keystore keystore
```

5) Next, get your cert signed by your CA and saved into a file, e.g. `themachine.cer`.  Make sure there are 5 dashes to either side of the BEGIN CERTIFICATE and END CERTIFICATE and that no white spaces, extra line breaks or additional characters have been inadvertently added.

6) Import the each CA cert you downloaded previously into the keystore.  E.g for a single required cert, `CA.cer`:

```
$ keytool -importcert -trustcacerts -alias privateRootCA -keystore keystore -storepass "password" -file CA.cer

```

5) Add the signed certificate into the keystore.

```
$ keytool -importcert -alias themachine -keystore keystore -storepass "password" -file themachine.cer
```

6) (Optional) Visually inspect keystore:

```
$ keytool -list -v -keystore keystore -storepass "password" | less
```

7) Replace the previously installed keystore with the one you have created, e.g. if you have previously installed from the Debian package, replace `/usr/share/loom-tm/keystore` with `keystore`.

## Using different versions
While not recommended, if you wish to experiment with other versions of Loom, Weaver or the adapters(s) then you must modify `loom-version` and/or `weaver-version` in `pom.xml`.

## Docker

To build a container image use the `docker:build` target, e.g.

```
$ mvn -U clean package docker:build
```

This will create an image with two tags: one is a 7 character abbreviation of the git commmit ID and another using "latest".  E.g. `loom-tm:7df9149` and `loom-tm:latest`.

To create images for use with a private registry then you must provide the reference to the registry when building the images to ensure the correct tags are used.  Ensure that the registry reference ends in "/".

```
$ mvn -U -Ddocker.registry="myregistry.local:5000/" clean package docker:build
```

This will produce images appropriate tags, e.g. `myregistry.local:5000/loom-tm:latest` and `myregistry.local:5000/loom-tm:7df9149`.

To push images to the registry you can use the `docker:push` target.

```
$ mvn -U -Ddocker.registry="myregistry.local:5000/" clean package docker:build docker:push
```

To run the image you must mount the folder containing the TM Configuration File to /loom/config.  The standard location for TMCF is `/etc/tmconfig` so to run use:

```
$ docker run -d -p 9099:9099 -v /etc:/loom/config myregistry.local:5000/loom-tm
```

## Making a Release

All pre-release work is assigned a snapshot version, e.g. 1.0-SNAPSHOT represents pre-release work for 1.0.  Making a release requires updating the Debian version prior to starting the maven release process.

### 1) Update Debian release version

Edit `debian/changelog` and add an entry for the new release.

> Commit and push this immediately otherwise you will not be able to proceed.

### 2) Prepare the maven release process:

```sh
$ mvn release:prepare -Darguments="-Dmaven.test.skip"
```

This will prompt for: release version, tag for git and what the next version will be and it will provide suggested defaults for each. The git tag should just be the version number. For example, if the current version is `1.0-SNAPSHOT`, the release version should be `1.0` and the git tag `1.0`.

It will then make the changes to the POM files (all sub modules take the same version as the parent). Run a clean build package across all the modules but skipping the tests. Once it has completed it will tag the code, bump up the version numbers and commit the new POM's (ready to carry on dev).

Two commits will be made and pushed to the repo in the process.

### 3) Actually perform the release:

```sh
$ mvn release:perform -Darguments="-Dmaven.test.skip"
```

This will perform a 'deploy site-deploy' which pulls the release from the remote repo, builds the artifacts again and pushes all the artifacts to any configured repos.

The committed pom.xml version will have been moved onto the next snapshot release, e.g. `1.1-SNAPSHOT`.

### 4) Create Debian package

In order to create a Debian package, you must work from a tagged version of the repo.  Following on from step 3), you have progressed past the last tag so you must explicitly checkout that tagged version.

```
$ git checkout <version>
```

Packaging should only be perfomed on an L4TM machine.  In the top-level folder of your local working copy execute:

```
$ dpkg-buildpackage -uc -us -sa
```

The Debian package build tools create files in the parent folder.
