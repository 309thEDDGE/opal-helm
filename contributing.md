# Contribution Guide
## Table of Contents
- [Contribution Guide](#contribution-guide)
  - [Table of Contents](#table-of-contents)
  - [General Conventions](#general-conventions)
    - [Chart Names](#chart-names)
    - [Version Numbers](#version-numbers)
    - [Formatting YAML](#formatting-yaml)
    - [Usage of the Words Helm and Chart](#usage-of-the-words-helm-and-chart)
  - [Values](#values)
    - [Naming Conventions](#naming-conventions)
    - [Flat or Nested Values](#flat-or-nested-values)
    - [Make Types Clear](#make-types-clear)
    - [Consider How Users Will Use Your Values](#consider-how-users-will-use-your-values)
    - [Document values.yaml](#document-valuesyaml)
  - [Templates](#templates)
    - [Structure of templates/](#structure-of-templates)
    - [Names of Defined Templates](#names-of-defined-templates)
    - [Formatting Templates](#formatting-templates)
    - [Whitespace in Generated Templates](#whitespace-in-generated-templates)
    - [Comments (YAML Comments vs. Template Comments)](#comments-yaml-comments-vs-template-comments)
    - [Use of JSON in Templates and Template Output](#use-of-json-in-templates-and-template-output)
  - [Dependencies](#dependencies)
    - [Versions](#versions)
    - [Prerelease versions](#prerelease-versions)
    - [Repository URLs](#repository-urls)
    - [Conditions and Tags](#conditions-and-tags)
  - [Labels and Annotations](#labels-and-annotations)
    - [Is it a Label or an Annotation?](#is-it-a-label-or-an-annotation)
    - [Standard Labels](#standard-labels)
  - [Pods and PodTemplates](#pods-and-podtemplates)
    - [Images](#images)
    - [ImagePullPolicy](#imagepullpolicy)
    - [PodTemplates Should Declare Selectors](#podtemplates-should-declare-selectors)
  - [Custom Resource Definitions](#custom-resource-definitions)
    - [Install a CRD Declaration Before Using the Resource](#install-a-crd-declaration-before-using-the-resource)
  - [Role-Based Access Control](#role-based-access-control)
    - [YAML Configuration](#yaml-configuration)
    - [RBAC Resources Should be Created by Default](#rbac-resources-should-be-created-by-default)
    - [Using RBAC Resources](#using-rbac-resources)
  
## General Conventions
### Chart Names
Chart names must be lower case letters and numbers. Words may be separated with dashes (-):

Examples:

```
drupal
nginx-lego
aws-cluster-autoscaler
```


Neither uppercase letters nor underscores can be used in chart names. Dots should not be used in chart names.

### Version Numbers
Wherever possible, Helm uses SemVer 2 to represent version numbers. (Note that Docker image tags do not necessarily follow SemVer, and are thus considered an unfortunate exception to the rule.)

When SemVer versions are stored in Kubernetes labels, we conventionally alter the + character to an _ character, as labels do not allow the + sign as a value.

### Formatting YAML
YAML files should be indented using two spaces (and never tabs).

### Usage of the Words Helm and Chart
There are a few conventions for using the words Helm and helm.

- Helm refers to the project as a whole
- helm refers to the client-side command
- The term chart does not need to be capitalized, as it is not a proper noun
- However, Chart.yaml does need to be capitalized because the file name is case sensitive  

When in doubt, use Helm (with an uppercase 'H').

## Values
This part of the best practices guide covers using values. In this part of the guide, we provide recommendations on how you should structure and use your values, with focus on designing a chart's values.yaml file.

### Naming Conventions
Variable names should begin with a lowercase letter, and words should be separated with camelcase:

```
Correct:

chicken: true
chickenNoodleSoup: true
Incorrect:

Chicken: true  # initial caps may conflict with built-ins
chicken-noodle-soup: true # do not use hyphens in the name
```
Note that all of Helm's built-in variables begin with an uppercase letter to easily distinguish them from user-defined values: .Release.Name, .Capabilities.KubeVersion.

### Flat or Nested Values
YAML is a flexible format, and values may be nested deeply or flattened.

```
Nested:

server:
  name: nginx
  port: 80
Flat:

serverName: nginx
serverPort: 80
```
In most cases, flat should be favored over nested. The reason for this is that it is simpler for template developers and users.

For optimal safety, a nested value must be checked at every level:
```
{{ if .Values.server }}
  {{ default "none" .Values.server.name }}
{{ end }}
```
For every layer of nesting, an existence check must be done. But for flat configuration, such checks can be skipped, making the template easier to read and use.
```
{{ default "none" .Values.serverName }}
```
When there are a large number of related variables, and at least one of them is non-optional, nested values may be used to improve readability.

### Make Types Clear
YAML's type coercion rules are sometimes counterintuitive. For example, foo: false is not the same as foo: "false". Large integers like foo: 12345678 will get converted to scientific notation in some cases.

The easiest way to avoid type conversion errors is to be explicit about strings, and implicit about everything else. Or, in short, quote all strings.

Often, to avoid the integer casting issues, it is advantageous to store your integers as strings as well, and use {{ int $value }} in the template to convert from a string back to an integer.

In most cases, explicit type tags are respected, so foo: !!string 1234 should treat 1234 as a string. However, the YAML parser consumes tags, so the type data is lost after one parse.

### Consider How Users Will Use Your Values
There are three potential sources of values:

- A chart's values.yaml file
- A values file supplied by helm install -f or helm upgrade -f
- The values passed to a --set or --set-string flag on helm install or helm upgrade

When designing the structure of your values, keep in mind that users of your chart may want to override them via either the -f flag or with the --set option.

Since --set is more limited in expressiveness, the first guidelines for writing your values.yaml file is make it easy to override from --set.

For this reason, it's often better to structure your values file using maps.

Difficult to use with --set:
```
servers:
  - name: foo
    port: 80
  - name: bar
    port: 81
```
The above cannot be expressed with --set in Helm <=2.4. In Helm 2.5, accessing the port on foo is --set servers[0].port=80. Not only is it harder for the user to figure out, but it is prone to errors if at some later time the order of the servers is changed.

Easy to use:
```
servers:
  foo:
    port: 80
  bar:
    port: 81
```
Accessing foo's port is much more obvious: --set servers.foo.port=80.

### Document values.yaml
Every defined property in values.yaml should be documented. The documentation string should begin with the name of the property that it describes, and then give at least a one-sentence description.

Incorrect:
```
# the host name for the webserver
serverHost: example
serverPort: 9191
```
Correct:
```
# serverHost is the host name for the webserver
serverHost: example
# serverPort is the HTTP listener port for the webserver
serverPort: 9191
```
Beginning each comment with the name of the parameter it documents makes it easy to grep out documentation, and will enable documentation tools to reliably correlate doc strings with the parameters they describe.

## Templates
This part of the Best Practices Guide focuses on templates.

### Structure of templates/
The templates/ directory should be structured as follows:

- Template files should have the extension .yaml if they produce YAML output. The extension .tpl may be used for template files that produce no formatted content.
- Template file names should use dashed notation (my-example-configmap.yaml), not camelcase.
- Each resource definition should be in its own template file.
- Template file names should reflect the resource kind in the name. e.g. foo-pod.yaml, bar-svc.yaml  

### Names of Defined Templates
Defined templates (templates created inside a {{ define }} directive) are globally accessible. That means that a chart and all of its subcharts will have access to all of the templates created with {{ define }}.

For that reason, all defined template names should be namespaced.

Correct:
```
{{- define "nginx.fullname" }}
{{/* ... */}}
{{ end -}}
```
Incorrect:
```
{{- define "fullname" -}}
{{/* ... */}}
{{ end -}}
```
It is highly recommended that new charts are created via helm create command as the template names are automatically defined as per this best practice.

### Formatting Templates
Templates should be indented using two spaces (never tabs).

Template directives should have whitespace after the opening braces and before the closing braces:

Correct:
```
{{ .foo }}
{{ print "foo" }}
{{- print "bar" -}}
```
Incorrect:
```
{{.foo}}
{{print "foo"}}
{{-print "bar"-}}
```
Templates should chomp whitespace where possible:
```
foo:
  {{- range .Values.items }}
  {{ . }}
  {{ end -}}
```
Blocks (such as control structures) may be indented to indicate flow of the template code.
```
{{ if $foo -}}
  {{- with .Bar }}Hello{{ end -}}
{{- end -}}
```
However, since YAML is a whitespace-oriented language, it is often not possible for code indentation to follow that convention.

### Whitespace in Generated Templates
It is preferable to keep the amount of whitespace in generated templates to a minimum. In particular, numerous blank lines should not appear adjacent to each other. But occasional empty lines (particularly between logical sections) is fine.

This is best:
```
apiVersion: batch/v1
kind: Job
metadata:
  name: example
  labels:
    first: first
    second: second
```
This is okay:
```
apiVersion: batch/v1
kind: Job

metadata:
  name: example

  labels:
    first: first
    second: second
```
But this should be avoided:
```
apiVersion: batch/v1
kind: Job

metadata:
  name: example





  labels:
    first: first

    second: second
```
### Comments (YAML Comments vs. Template Comments)
Both YAML and Helm Templates have comment markers.

YAML comments:
```
# This is a comment
type: sprocket
```
Template Comments:
```
{{- /*
This is a comment.
*/}}
type: frobnitz
```
Template comments should be used when documenting features of a template, such as explaining a defined template:
```
{{- /*
mychart.shortname provides a 6 char truncated version of the release name.
*/}}
{{ define "mychart.shortname" -}}
{{ .Release.Name | trunc 6 }}
{{- end -}}
```
Inside of templates, YAML comments may be used when it is useful for Helm users to (possibly) see the comments during debugging.
```
# This may cause problems if the value is more than 100Gi
memory: {{ .Values.maxMem | quote }}
```
The comment above is visible when the user runs helm install --debug, while comments specified in {{- /* */}} sections are not.

Beware of adding # YAML comments on template sections containing Helm values that may be required by certain template functions.

For example, if required function is introduced to the above example, and maxMem is unset, then a # YAML comment will introduce a rendering error.

Correct: helm template does not render this block
```
{{- /*
# This may cause problems if the value is more than 100Gi
memory: {{ required "maxMem must be set" .Values.maxMem | quote }}
*/ -}}
```
Incorrect: helm template returns Error: execution error at (templates/test.yaml:2:13): maxMem must be set
```
# This may cause problems if the value is more than 100Gi
# memory: {{ required .Values.maxMem "maxMem must be set" | quote }}
```

### Use of JSON in Templates and Template Output
YAML is a superset of JSON. In some cases, using a JSON syntax can be more readable than other YAML representations.

For example, this YAML is closer to the normal YAML method of expressing lists:
```
arguments:
  - "--dirname"
  - "/foo"
```
But it is easier to read when collapsed into a JSON list style:
```
arguments: ["--dirname", "/foo"]
```
Using JSON for increased legibility is good. However, JSON syntax should not be used for representing more complex constructs.

When dealing with pure JSON embedded inside of YAML (such as init container configuration), it is of course appropriate to use the JSON format.

## Dependencies
This section of the guide covers best practices for dependencies declared in Chart.yaml.

### Versions
Where possible, use version ranges instead of pinning to an exact version. The suggested default is to use a patch-level version match:
```
version: ~1.2.3
```
This will match version 1.2.3 and any patches to that release. In other words, ~1.2.3 is equivalent to >= 1.2.3, < 1.3.0

For the complete version matching syntax, please see the semver documentation.

### Prerelease versions
The above versioning constraints will not match on pre-release versions. For example version: ~1.2.3 will match version: ~1.2.4 but not version: ~1.2.3-1. The following provides a pre-release as well as patch-level matching:
```
version: ~1.2.3-0
```
### Repository URLs
Where possible, use https:// repository URLs, followed by http:// URLs.

If the repository has been added to the repository index file, the repository name can be used as an alias of URL. Use alias: or @ followed by repository names.

File URLs (file://...) are considered a "special case" for charts that are assembled by a fixed deployment pipeline.

When using downloader plugins the URL scheme will be specific to the plugin. Note, a user of the chart will need to have a plugin supporting the scheme installed to update or build the dependency.

Helm cannot perform dependency management operations on the dependency when the repository field is left blank. In that case Helm will assume the dependency is in a sub-directory of the charts folder with the name being the same as the name property for the dependency.

### Conditions and Tags
Conditions or tags should be added to any dependencies that are optional.

The preferred form of a condition is:
```
condition: somechart.enabled
```
Where somechart is the chart name of the dependency.

When multiple subcharts (dependencies) together provide an optional or swappable feature, those charts should share the same tags.

For example, if both nginx and memcached together provide performance optimizations for the main app in the chart, and are required to both be present when that feature is enabled, then they should both have a tags section like this:
```
tags:
  - webaccelerator
```
This allows a user to turn that feature on and off with one tag.

## Labels and Annotations
This part of the Best Practices Guide discusses the best practices for using labels and annotations in your chart.

### Is it a Label or an Annotation?
An item of metadata should be a label under the following conditions:

- It is used by Kubernetes to identify this resource
- It is useful to expose to operators for the purpose of querying the system.

For example, we suggest using helm.sh/chart: NAME-VERSION as a label so that operators can conveniently find all of the instances of a particular chart to use.

If an item of metadata is not used for querying, it should be set as an annotation instead.

Helm hooks are always annotations.

### Standard Labels
The following table defines common labels that Helm charts use. Helm itself never requires that a particular label be present. Labels that are marked REC are recommended, and should be placed onto a chart for global consistency. Those marked OPT are optional. These are idiomatic or commonly in use, but are not relied upon frequently for operational purposes.

|Name|Status|Description|
| -- | ---- | --------- |
|app.kubernetes.io/name	| REC |	This should be the app name, reflecting the entire app.  Usually {{ template "name" . }} is used for this. This is used by many Kubernetes manifests, and is not Helm-specific.|
|helm.sh/chart	| REC |	This should be the chart name and version: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}.|
|app.kubernetes.io/managed-by |	REC |	This should always be set to {{ .Release.Service }}. It is for finding all things managed by Helm. |
|app.kubernetes.io/instance |	REC |	This should be the {{ .Release.Name }}. It aids in differentiating between different instances of the same application.|
|app.kubernetes.io/version |	OPT	| The version of the app and can be set to {{ .Chart.AppVersion }}.|
|app.kubernetes.io/component |	OPT |	This is a common label for marking the different roles that pieces may play in an application. For example, app.kubernetes.io/component: frontend. |
| app.kubernetes.io/part-of | OPT |	When multiple charts or pieces of software are used together to make one application. For example, application software and a database to produce a website. This can be set to the top level application being supported. |

You can find more information on the Kubernetes labels, prefixed with app.kubernetes.io, in the [Kubernetes documentation.](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)

## Pods and PodTemplates
This part of the Best Practices Guide discusses formatting the Pod and PodTemplate portions in chart manifests.

The following (non-exhaustive) list of resources use PodTemplates:

- Deployment
- ReplicationController
- ReplicaSet
- DaemonSet
- StatefulSet
### Images
A container image should use a fixed tag or the SHA of the image. It should not use the tags latest, head, canary, or other tags that are designed to be "floating".

Images may be defined in the values.yaml file to make it easy to swap out images.
```
image: {{ .Values.redisImage | quote }}
```
An image and a tag may be defined in values.yaml as two separate fields:
```
image: "{{ .Values.redisImage }}:{{ .Values.redisTag }}"
```
### ImagePullPolicy
helm create sets the imagePullPolicy to IfNotPresent by default by doing the following in your deployment.yaml:
```
imagePullPolicy: {{ .Values.image.pullPolicy }}
```
And values.yaml:
```
image:
  pullPolicy: IfNotPresent
```
Similarly, Kubernetes defaults the imagePullPolicy to IfNotPresent if it is not defined at all. If you want a value other than IfNotPresent, simply update the value in values.yaml to your desired value.

### PodTemplates Should Declare Selectors
All PodTemplate sections should specify a selector. For example:
```
selector:
  matchLabels:
      app.kubernetes.io/name: MyName
template:
  metadata:
    labels:
      app.kubernetes.io/name: MyName
```
This is a good practice because it makes the relationship between the set and the pod.

But this is even more important for sets like Deployment. Without this, the entire set of labels is used to select matching pods, and this will break if you use labels that change, like version or release date.

## Custom Resource Definitions
This section of the Best Practices Guide deals with creating and using Custom Resource Definition objects.

When working with Custom Resource Definitions (CRDs), it is important to distinguish two different pieces:

- There is a declaration of a CRD. This is the YAML file that has the kind CustomResourceDefinition
- Then there are resources that use the CRD. Say a CRD defines foo.example.com/v1. Any resource that has apiVersion: example.com/v1 and kind Foo is a resource that uses the CRD.
### Install a CRD Declaration Before Using the Resource
Helm is optimized to load as many resources into Kubernetes as fast as possible. By design, Kubernetes can take an entire set of manifests and bring them all online (this is called the reconciliation loop).

But there's a difference with CRDs.

For a CRD, the declaration must be registered before any resources of that CRDs kind(s) can be used. And the registration process sometimes takes a few seconds.

**Method 1: Let helm Do It For You**  
With the arrival of Helm 3, we removed the old crd-install hooks for a more simple methodology. There is now a special directory called crds that you can create in your chart to hold your CRDs. These CRDs are not templated, but will be installed by default when running a helm install for the chart. If the CRD already exists, it will be skipped with a warning. If you wish to skip the CRD installation step, you can pass the --skip-crds flag.

**Some caveats (and explanations)**  
There is no support at this time for upgrading or deleting CRDs using Helm. This was an explicit decision after much community discussion due to the danger for unintentional data loss. Furthermore, there is currently no community consensus around how to handle CRDs and their lifecycle. As this evolves, Helm will add support for those use cases.

The --dry-run flag of helm install and helm upgrade is not currently supported for CRDs. The purpose of "Dry Run" is to validate that the output of the chart will actually work if sent to the server. But CRDs are a modification of the server's behavior. Helm cannot install the CRD on a dry run, so the discovery client will not know about that Custom Resource (CR), and validation will fail. You can alternatively move the CRDs to their own chart or use helm template instead.

Another important point to consider in the discussion around CRD support is how the rendering of templates is handled. One of the distinct disadvantages of the crd-install method used in Helm 2 was the inability to properly validate charts due to changing API availability (a CRD is actually adding another available API to your Kubernetes cluster). If a chart installed a CRD, helm no longer had a valid set of API versions to work against. This is also the reason behind removing templating support from CRDs. With the new crds method of CRD installation, we now ensure that helm has completely valid information about the current state of the cluster.

**Method 2: Separate Charts**  
Another way to do this is to put the CRD definition in one chart, and then put any resources that use that CRD in another chart.

In this method, each chart must be installed separately. However, this workflow may be more useful for cluster operators who have admin access to a cluster.

## Role-Based Access Control
This part of the Best Practices Guide discusses the creation and formatting of RBAC resources in chart manifests.

RBAC resources are:

- ServiceAccount (namespaced)
- Role (namespaced)
- ClusterRole
- RoleBinding (namespaced)
- ClusterRoleBinding
### YAML Configuration
RBAC and ServiceAccount configuration should happen under separate keys. They are separate things. Splitting these two concepts out in the YAML disambiguates them and makes this clearer.
```
rbac:
  # Specifies whether RBAC resources should be created
  create: true

serviceAccount:
  # Specifies whether a ServiceAccount should be created
  create: true
  # The name of the ServiceAccount to use.
  # If not set and create is true, a name is generated using the fullname template
  name:
```
This structure can be extended for more complex charts that require multiple ServiceAccounts.
```
someComponent:
  serviceAccount:
    create: true
    name:
anotherComponent:
  serviceAccount:
    create: true
    name:
```
### RBAC Resources Should be Created by Default
rbac.create should be a boolean value controlling whether RBAC resources are created. The default should be true. Users who wish to manage RBAC access controls themselves can set this value to false (in which case see below).

### Using RBAC Resources
serviceAccount.name should be set to the name of the ServiceAccount to be used by access-controlled resources created by the chart. If serviceAccount.create is true, then a ServiceAccount with this name should be created. If the name is not set, then a name is generated using the fullname template, If serviceAccount.create is false, then it should not be created, but it should still be associated with the same resources so that manually-created RBAC resources created later that reference it will function correctly. If serviceAccount.create is false and the name is not specified, then the default ServiceAccount is used.

The following helper template should be used for the ServiceAccount.
```
{{/*
Create the name of the service account to use
*/}}
{{- define "mychart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "mychart.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
```