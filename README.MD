<h1 align="center">✨ Cluster Kubernetes com OKE na OCI </h1>

Este repositório contém os arquivos de `terraform` utilizados para criação e gerenciamento de um cluster `kubernetes`, utlizando o `OKE` 
da `OCI`, da minha conta pessoal utilizada para estudos.

## Sumário

1. [Arquivo de estado](#arquivo-de-estado)
2. [Requisitos](#requisitos)
3. [Infraestrutura](#infraestrutura)
4. [Recursos provisionados e roadmap](#recursos-provisionados-e-roadmap)
5. [Instalando o provider e inicializando o backend](#instalando-o-provider-e-inicializando-o-backend)
6. [Planejando o ambiente](#planejando-o-ambiente)
7. [Subindo o ambiente](#subindo-o-ambiente)
8. [Configurando acesso ao cluster via kubectl](#configurando-acesso-ao-cluster-via-kubectl)
9. [Destruindo o ambiente](#destruindo-o-ambiente)
10. [Links úteis](#links-úteis)

## Arquivo de estado

Por motivos de padronização em meus projetos pessoais, esse repositório está apontando o `tfstate` para o meu `bucket s3`. Caso queira clonar e subir um ambiente utilizando esse repositório, será necessário alterar a seção de `backend` no arquivo `main.tf`, com a configuração desejada.

## Requisitos

- conta na `OCI`
- `terraform` instalado
- `kubect` instalado
- `oci cli` instalada e configurada
- ter um `API Key` criado na OCI
- conta na `AWS` e variavéis `access key`/`secret key`/`region` exportadas na shell em execução para armazenamento do `tfstate`, caso estiver utilizando o `s3` como `backend` (opcional)
- definir as variáveis necessárias para login e para alocação dos recursos, conforme tabela abaixo:

| Variável            | Descrição                                                             | Autenticação | Alocação |
| :-----------------: | :-------------------------------------------------------------------- | :----------: | :------: |
| tenancy_ocid        | identificação única da conta                                          | ✅           | ❌       |
| user_ocid           | usuário que está aplicando o `terraform`                              | ✅           | ❌       |
| fingerprint         | assinatura compatível com a `API Key`                                 | ✅           | ❌       |
| private_key_path    | caminho da chave privada compatível com a `API Key`                   | ✅           | ❌       |
| region              | região utilizada para declaração do `provider` e alocação de recursos | ✅           | ✅       |
| compartment_ocid    | compartimento utilizado para alocação dos recursos                    | ❌           | ✅       |
| availability_domain | domínio de disponibilidade utilizado para alocação dos recursos       | ❌           | ✅       |

Para definir as variáveis, estou utilizando o arquivo `terraform.tfvars`.
Exemplo de conteúdo do arquivo `terraform.tfvars`:

```shell
#!/bin/bash

tenancy_ocid = "ocid1.tenancy.oc1..XXXXXXXXXXXX"
user_ocid = "ocid1.user.oc1..XXXXXXXXXXXXXXXXXX"
fingerprint = "XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX"
private_key_path = "~/.keys/oci_api_key_tf.pem"
region = "sa-saopaulo-1"
compartment_ocid = "ocid1.compartment.oc1..XXXX"
availability_domain = "CyEp:SA-SAOPAULO-1-AD-1"
```

## Infraestrutura

O `terraform` atual provisiona um cluster `kubernetes`, utilizando o serviço de `kubernetes` gerenciado da oracle (`OKE`), com 4 `worker nodes` utilizando arquitetura `ARM`, e expoẽ publicamente o `endpoint` do `API server` através de um `IP` fixo.
Nesse modelo, temos uma `subnet` pública, que é utilizada para alocação do `API server`, futuramente o `load balancer` que será utilizado como `ingress` no cluster, e uma `subnet` privada, para alocação dos `worker nodes`.
Para garantir a segurança, são provisionados `NSGs` (network security groups) em cada recurso ao invés de `secutiry lists` a nível de `subnet`, sendo assim,
modificamos o `security list` padrão que é criado junto com a `VCN`, para liberar todo o tráfego.
OBS: Essa arquitetura está utilizando dos recursos **always free** da oracle, e **não é recomendado para produção** devido utilização da arquitetura `ARM` nos `worker nodes`.

## Recursos provisionados e roadmap

> ✅ = **Provisionado**

> :hourglass_flowing_sand: = **Em roadmap**

| Recurso                              | Descrição                                                                           | Status                   |
| :----------------------------------: | :---------------------------------------------------------------------------------  | :----------------------: |
| vcn                                  | rede virtual na nuvem                                                               | ✅                       |
| internet gateway                     | gateway utilizado para dar acesso a internet na subrede pública (entrada/saída)     | ✅                       |
| nat gateway                          | gateway utilizado para dar acesso a internet na subnet privada (somente saída)      | ✅                       |
| service gateway                      | gateway utilizada para dar acesso aos serviços internos da OCI                      | ✅                       |
| default vcn security list            | altera a security list padrão da vnc, liberando todo o tráfico.                     | ✅                       |
| public subnet                        | subnet pública, utilizada para alocação do Kubernetes API Endpoint e LB             | ✅                       |
| public subnet route table            | tabela de rotas da subnet publica                                                   | ✅                       |
| private subnet                       | subnet privada, utlizada para alocação dos worker nodes                             | ✅                       |
| private subnet route table           | tabela de rotas da subnet privada                                                   | ✅                       |
| api server network security group    | grupo de segurança do api server                                                    | ✅                       |
| oke master                           | serviço de kubernetes gerenciado                                                    | ✅                       |
| node poll network security group     | grupo de segurança dos worker nodes                                                 | ✅                       |
| node pool                            | abstração para conjunto de worker nodes                                             | ✅                       |
| load balancer network security group | grupo de segurança do LB                                                            | :hourglass_flowing_sand: |
| load balancer                        | load balancer utilizado como ingress do cluster                                     | :hourglass_flowing_sand: |
| bastion                              | acesso aos worker nodes da subnet privada                                           | :hourglass_flowing_sand: |
| container registry                   | utilizado para guardar as imagens de containers                                     | :hourglass_flowing_sand: |
| file system                          | utilizado para PVs do cluster                                                       | :hourglass_flowing_sand: |

## Instalando o provider e inicializando o backend

```shell
terraform init
```

## Planejando o ambiente

```shell
terraform plan
```

## Subindo o ambiente

```shell
terraform apply
```

## Configurando acesso ao cluster via kubectl

```shell
export OKE_CLUSTER_ID=$(terraform output -raw cluster_id)
oci ce cluster create-kubeconfig --cluster-id $OKE_CLUSTER_ID --file $HOME/.kube/config \
--region sa-saopaulo-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT
```

## Destruindo o ambiente

```shell
terraform destroy
```

## Links úteis

- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- [Variable Definitions (.tfvars) Files](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files)
- [Utilizando o Oracle Cloud Infrastructure CLI (OCI-CLI) - Parte 1](https://www.oracle.com/br/technical-resources/articles/cloudcomp/utilizando-oci-cli-p1.html)
- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [Utilizando o terraform com o OCI](https://www.oracle.com/br/technical-resources/articles/cloudcomp/terraform-com-cloud.html)
- [Configuração do Recurso de Rede para Criação e Implantação de Cluster](https://docs.oracle.com/pt-br/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm)
