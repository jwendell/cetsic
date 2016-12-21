# cetsic - Cloud Enablement TestSuite In a Container

Run the [Cloud Enablement Test Suite](https://github.com/jboss-openshift/ce-testsuite) directly from a container.

### The problem
You need to run the ce-testsuite tests against an OpenShift server. But:
- You don't want to worry about its dependencies
- You don't want to mess your local maven repository
- You want to verify the tests are passing (or failing; or executing) regardless of your environment

### The solution
*cetsic* is an tool - in a form of an container - that configures this environment for you and run the tests against an OpenShift server. It gives you a fresh, totally clean environment for you to run the ce-testsuite.

### Benefits
- Avoids "Works on my machine" answers
- Allows simultaneous tests to run, because they are isolated into containers
  - Can run different set of tests and/or
  - Against different Openshift clusters
- Ideal for testing patches/pull requests
  - You can instruct *cetsic* to run **your** version of a test, by pointing it to your fork (See below under **Variables** section)
  - Allows integration with GitHub for doing automated tests against PR's [future work]

### Usage
```
$ docker pull jwendell/cetsic
$ docker run --rm [-e|--env-file] jwendell/cetsic
```
This will setup a container with all dependencies for the testsuite and will run the tests from there. Almost anything can be customized through environment variables that can be passed to `docker run`.

### Variables
- `KUBERNETES_MASTER`: URL of the Openshift instance on which the tests will run. **Mandatory**.
  - Example: `https://1.2.3.4:8443` 
- `MAVEN_SETTINGS_URL`: URL of a *settings.xml* file that will be used by maven. If not present, maven will use its default repository to look for dependencies.
  - Example: `https://my-company.com/files/settings.xml`
  - Hint: Deploy a maven mirror on your local network and configure this *settings.xml* to point to it. Believe me, you'll want this.
- `OPENSHIFT_ROUTER_HOST`: IP Address of the Openshift router. Some tests make external access to apps. If those apps don't have a public accessible hostname, and instead use hostnames like `app-1.svc.local`, then you need to supply this IP address so that tests know how to reach the apps.
- `CE_ARQ_URL`: Git repository of ce-arq.
  - Default value: `https://github.com/jboss-openshift/ce-arq.git`
- `CE_ARQ_BRANCH`: Git branch of ce-arq.
  - Default value: `master`
- `CE_TESTSUITE_URL`: Git repository of ce-testsuite.
  - Default value: `https://github.com/jboss-openshift/ce-testsuite.git`
- `CE_TESTSUITE_BRANCH`: Git branch of ce-testsuite.
  - Default value: `master`
- `MAVEN_ARGS`: Additional arguments to be passed to maven when executing the tests.
  - Example: `-Dtest=ASimpleTest`

Suggestion: If you are using many variables, put them in a file, in the form `VARIABLE=value`, one per line, and pass this file to `docker run --env-file=<your-file>`.

### Customization

You can customize which tests you will run by tweaking the variable `MAVEN_ARGS`. Examples:
- To run a single test: `MAVEN_ARGS=-Dtest=Eap70BasicTest -DfailIfNoTests=false`
- To run all EAP 7 tests: `MAVEN_ARGS=-pl eap/eap70`

There's much more. Check out the [Surefire documentation](http://maven.apache.org/surefire/maven-surefire-plugin/examples/single-test.html) to see what you can put into that variable in order to customize the tests execution.
