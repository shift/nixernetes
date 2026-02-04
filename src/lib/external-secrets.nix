# ExternalSecrets Integration
#
# This module provides:
# - ExternalSecret resource generation
# - Secret store configuration
# - Multi-backend support (Vault, AWS Secrets Manager, etc.)

{ lib }:

let
  inherit (lib) mkOption types;

in
{
  # Create ExternalSecret resource
  mkExternalSecret = { name, namespace ? "default", secretStore, target ? { name = name; template = { engineVersion = "v2"; }; }, data }:
    {
      apiVersion = "external-secrets.io/v1beta1";
      kind = "ExternalSecret";
      metadata = { inherit name namespace; };
      spec = {
        refreshInterval = "1h";
        secretStoreRef = {
          name = secretStore;
          kind = "SecretStore";
        };
        inherit target data;
      };
    };

  # Create SecretStore for Vault
  mkVaultSecretStore = { name, namespace ? "default", server, auth }:
    {
      apiVersion = "external-secrets.io/v1beta1";
      kind = "SecretStore";
      metadata = { inherit name namespace; };
      spec = {
        provider.vault = {
          inherit server auth;
          path = "secret";
          version = "v2";
        };
      };
    };

  # Create SecretStore for AWS Secrets Manager
  mkAWSSecretStore = { name, namespace ? "default", region, auth }:
    {
      apiVersion = "external-secrets.io/v1beta1";
      kind = "SecretStore";
      metadata = { inherit name namespace; };
      spec = {
        provider.aws = {
          service = "SecretsManager";
          inherit region auth;
        };
      };
    };

  # Create ClusterSecretStore (global)
  mkClusterSecretStore = { name, provider }:
    {
      apiVersion = "external-secrets.io/v1beta1";
      kind = "ClusterSecretStore";
      metadata = { inherit name; };
      spec = {
        inherit provider;
      };
    };

  # Helper: create secret from ExternalSecret
  secretFromExternal = { name, namespace ? "default", externalSecretName }:
    {
      apiVersion = "v1";
      kind = "Secret";
      metadata = { inherit name namespace; };
      type = "Opaque";
      data = { };
    };

  # Multi-backend configuration
  supportedBackends = [ "vault" "aws" "azure" "gcpsm" ];
}
