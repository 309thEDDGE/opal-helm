# Keycloak

Operators work by effectively extending the Kubernetes API with the operator Pod simply executing the code to fulfill a given request. The operator itself is not something anyone would log into directly so SSO is not necessary to configure. Access to the operator is effectively gatekept by RBAC rules defined in the cluster in the same way as RBAC for any other Pod or Namespace.
