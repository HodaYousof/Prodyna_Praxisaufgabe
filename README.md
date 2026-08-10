# PRODYNA Praxisaufgabe – DevOps / Azure

Terraform-Projekt zur automatisierten Bereitstellung einer kleinen Azure-Umgebung mit privatem Networking, AKS, Key Vault und Storage Account.

**Rolle:** DevOps Engineer (Variante A – Konzept)

---

## Overview

Dieses Projekt stellt per Infrastructure as Code (Terraform) bereit:

- Virtual Network mit getrennten Subnets (AKS + Private Endpoints)
- Azure Kubernetes Service (einzelner Node)
- Azure Key Vault und Storage Account
- Private Endpoints + Private DNS Zones für private Erreichbarkeit
- RBAC (Managed Identity für AKS, Administrator für den Terraform-User)
- Remote State in Azure Storage

Die Lösung ist in der Candidate-Subscription deployed und live vorzeigbar.

---

## Prerequisites

- Azure CLI (`az`) und Login in die PRODYNA-Subscription
- Terraform >= 1.5
- Bestehende Resource Group ( RG-Hoda-Yousof)
- Remote-Backend einmalig angelegt:
  - Storage Account: `stprodynaterraform`
  - Container: `tfstate`
  - State-Key: `prodyna-dev.tfstate`

---

## Project structure

```text
.
├── main.tf                   # Provider, Backend, alle Azure-Ressourcen
├── variables.tf              # Eingabevariablen
├── terraform.tfvars.example  # Beispielwerte (tfvars ist gitignored)
├── outputs.tf                # Wichtige Ausgaben nach dem Apply
├── .gitignore
├── .terraform.lock.hcl       # Provider-Lockfile
└── README.md
```

Aktuell liegt die Konfiguration flach in `main.tf` (übersichtlich für den Aufgabenumfang). Eine mögliche Modul-Aufteilung ist unter [Modul-Aufteilung] beschrieben.

---

## How to deploy

1. Repository klonen und in das Projektverzeichnis wechseln.

2. Variablen-Datei anlegen:

```bash
cp terraform.tfvars.example terraform.tfvars
# Werte bei Bedarf anpassen (Resource Group, Subnet-CIDRs)
```

3. Bei Azure anmelden und Subscription prüfen:

```bash
az login
az account show
```

4. Terraform initialisieren, planen und anwenden:

```bash
terraform init
terraform plan
terraform apply
```

5. Outputs anzeigen:

```bash
terraform output
```

6. Optional: AKS-Credentials holen

```bash
az aks get-credentials \
  --resource-group RG-Hoda-Yousof \
  --name aks-prodyna-dev
kubectl get nodes
```

### Destroy (Kosten beachten)

```bash
terraform destroy
```

Hinweis: Der State-Storage Account (`stprodynaterraform`) wird vom Hauptprojekt nicht verwaltet und bleibt bestehen, bis er manuell gelöscht wird.

---

## Design decisions

### Bestehende Resource Group per `data`

In der Candidate-Subscription fehlt die Berechtigung `resourcegroups/write`. Deshalb wird die vorgegebene RG nicht erstellt, sondern eingelesen:

```hcl
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
```

### Getrennte Subnets für AKS und Private Endpoints

- **AKS-Subnet:** Worker-Nodes / Azure CNI
- **Endpoints-Subnet:** Private Endpoints + NSG

So lassen sich Netzwerkregeln und Verantwortlichkeiten klar trennen (Compute vs. Private Link).

### Remote State in Azure Storage

State enthält sensible Daten und muss für Team/Collaboration sowie State Locking remote liegen. Das Backend (Storage + Container) wird einmalig per Azure CLI angelegt (Henne-Ei-Problem vor dem ersten `terraform init`).

### Private Endpoints + Private DNS

Private Endpoints stellen die private „Tür“ zu Key Vault/Storage bereit. Private DNS Zones sorgen dafür, dass Hostnames auf die privaten IPs auflösen. Beides zusammen ermöglicht private Kommunikation im VNet.

### RBAC statt Secrets im Code

Key Vault nutzt RBAC. AKS erhält über System Assigned Identity die Rolle **Key Vault Secrets User**. Der ausführende User erhält **Key Vault Administrator**. Keine Klartext-Secrets in Terraform.

### AKS Netzwerk / SKU

- VM Size: `Standard_B2s_v2` (in dieser Subscription erlaubt; `Standard_B2s` nicht)
- `service_cidr` / `dns_service_ip` außerhalb des VNet-Address Spaces (`172.16.0.0/16`), damit kein CIDR-Overlap entsteht

---

## Modul-Aufteilung

Für diese Praxisaufgabe ist eine flache Struktur ausreichend und leichter nachvollziehbar.

Für eine produktivere Weiterentwicklung wäre sinnvoll:

| Modul | Inhalt |
|---|---|
| `modules/network` | VNet, Subnets, NSG |
| `modules/aks` | Kubernetes Cluster + Node Pool |
| `modules/keyvault` | Key Vault + Private Endpoint + DNS |
| `modules/storage` | Storage Account + Private Endpoint + DNS |
| `modules/rbac` | Role Assignments |

Vorteile: Wiederverwendbarkeit, klarere Ownership, einfacheres Staging/Prod mit gleichen Modulen und unterschiedlichen `tfvars`.

---

## Infrastruktur-Architektur

Die Terraform-Konfiguration verwendet eine bereits vorhandene Azure Resource Group und erstellt darin ein Virtual Network mit getrennten Subnetzen für AKS und Private Endpoints.

Key Vault und Storage Account werden über Private Endpoints erreichbar gemacht. Private DNS Zones sorgen dafür, dass die Azure-Dienste innerhalb des VNets auf ihre privaten IP-Adressen aufgelöst werden.

flowchart TB %% ========================================================= %% TERRAFORM %% ========================================================= TF["Terraform"] BACKEND["Terraform Backend<br/>Storage Account: stprodynaterraform<br/>Container: tfstate<br/>State: prodyna-dev.tfstate"] TF -. "State lesen / speichern" .-> BACKEND %% ========================================================= %% EXISTING RESOURCE GROUP %% ========================================================= subgraph RG["Existing Resource Group: RG-Hoda-Yousof"] direction TB %% ===================================================== %% NETWORK %% ===================================================== subgraph VNET["Virtual Network: vnet-prodyna-dev"] direction LR subgraph AKSNET["AKS Subnet<br/>snet-aks-prodyna-dev"] AKS["AKS Cluster<br/>aks-prodyna-dev"] NODEPOOL["System Node Pool<br/>Standard_B2s_v2<br/>1 Node"] AKS --> NODEPOOL end subgraph PENET["Private Endpoint Subnet<br/>snet-endpoints-prodyna-dev"] NSG["Network Security Group<br/>nsg-prodyna-dev"] PEKV["Private Endpoint<br/>Key Vault"] PEST["Private Endpoint<br/>Storage Blob"] end end %% ===================================================== %% AZURE SERVICES %% ===================================================== subgraph SERVICES["Private Azure Services"] direction LR KV["Key Vault<br/>kv-prodyna-dev<br/>RBAC enabled"] STORAGE["Storage Account<br/>stprodynadev<br/>Blob"] end %% ===================================================== %% PRIVATE DNS %% ===================================================== subgraph DNS["Private DNS"] direction LR DNSKV["Private DNS Zone<br/>privatelink.vaultcore.azure.net"] DNSST["Private DNS Zone<br/>privatelink.blob.core.windows.net"] end %% ===================================================== %% NETWORK CONNECTIONS %% ===================================================== NSG -->|"NSG Association"| PENET PEKV -->|"private_connection_resource_id<br/>azurerm_key_vault.main.id"| KV PEST -->|"private_connection_resource_id<br/>azurerm_storage_account.main.id"| STORAGE %% ===================================================== %% DNS ZONE GROUPS %% ===================================================== PEKV -.->|"private_dns_zone_ids"| DNSKV PEST -.->|"private_dns_zone_ids"| DNSST %% ===================================================== %% VNET DNS LINKS %% ===================================================== DNSKV -.->|"Virtual Network Link"| VNET DNSST -.->|"Virtual Network Link"| VNET %% ===================================================== %% RBAC %% ===================================================== AKS -.->|"Managed Identity<br/>Key Vault Secrets User"| KV ADMIN["Terraform User<br/>azurerm_client_config.current"] ADMIN -.->|"Key Vault Administrator"| KV end %% ========================================================= %% TERRAFORM -> RESOURCE GROUP %% ========================================================= TF -->|"data.azurerm_resource_group.main"| RG

## Ressourcenstruktur

```text
Azure Subscription
│
├── Terraform State
│   └── Storage Account: stprodynaterraform
│       └── Container: tfstate
│           └── prodyna-dev.tfstate
│
└── Existing Resource Group: RG-Hoda-Yousof
    │
    ├── Virtual Network: vnet-prodyna-dev
    │   ├── AKS Subnet: snet-aks-prodyna-dev
    │   │   └── AKS Cluster: aks-prodyna-dev (Node Pool)
    │   └── Private Endpoint Subnet: snet-endpoints-prodyna-dev
    │       ├── NSG: nsg-prodyna-dev
    │       ├── Private Endpoint → Key Vault
    │       └── Private Endpoint → Storage (Blob)
    │
    ├── Key Vault: kv-prodyna-dev
    ├── Storage Account: stprodynadev
    ├── Private DNS Zone: privatelink.vaultcore.azure.net
    └── Private DNS Zone: privatelink.blob.core.windows.net
```

## Wichtige Terraform-Referenzen

Die Ressourcen werden nicht über hartcodierte Azure Resource IDs miteinander verbunden. Terraform verwendet Referenzen auf bereits definierte Ressourcen und baut daraus den Dependency Graph.

Beispiele:

```hcl
subnet_id                          = azurerm_subnet.endpoints.id
private_connection_resource_id     = azurerm_key_vault.main.id
vnet_subnet_id                     = azurerm_subnet.aks.id
virtual_network_id                 = azurerm_virtual_network.main.id
```

Dadurch weiß Terraform die Reihenfolge (z. B. erst Subnet, dann Private Endpoint) und hält IDs konsistent.

## DNS-Auflösung

```text
AKS / Workload
  → Name (z. B. kv-....vault.azure.net)
  → Private DNS Zone (privatelink.*)
  → Private IP des Private Endpoints
  → Private Endpoint
  → Key Vault / Storage
```

Ohne Private DNS würde der öffentliche Name oft auf eine öffentliche IP zeigen. Mit Private DNS bleibt der Traffic im privaten Pfad.

## RBAC

```text
AKS Managed Identity  →  Key Vault Secrets User  →  Key Vault
Terraform User        →  Key Vault Administrator →  Key Vault
```

Netzwerkzugang (Private Endpoint/DNS) und Berechtigung (RBAC) sind bewusst getrennt.

---

## Variante A – Konzept (DevOps Engineer)

> Laut Aufgabenstellung als Konzeptbeschreibung – nicht zwingend implementiert. Im technischen Gespräch vertiefbar.

### 1) Workload: nginx als Deployment + Service (Staging/Production)

**Ziel:** Einfacher Webserver im AKS, konfigurierbar für mehrere Stages.

**IaC-Ansatz (Kubernetes Manifeste oder Helm, versioniert im Repo):**

- `Deployment`: Image `nginx:stable`, Replicas stage-abhängig (z. B. staging=1, prod=2+)
- `Service`: `ClusterIP` intern oder `LoadBalancer`/`Ingress` für externen Zugriff
- Getrennte Werte pro Environment:
  - Ordner `k8s/overlays/staging` und `k8s/overlays/production` (Kustomize), **oder**
  - Helm Chart mit `values-staging.yaml` / `values-production.yaml`

**Staging/Prod-tauglich bedeutet u. a.:**

| Thema | Staging | Production |
|---|---|---|
| Replicas | 1 | >= 2 |
| Resources | klein | Requests/Limits gesetzt |
| Image tag | flexibel / latest-ok für Demo | immutable Digest/Tag |
| Namespace | `staging` | `production` |
| Ingress/TLS | optional | empfohlen |
| Pipeline | deploy bei Merge auf `develop` | deploy bei Tag/Release auf `main` |

**Beispiel-Pipeline-Idee:** GitHub Actions → `kubectl apply -k overlays/$ENV` oder `helm upgrade --install` nach `az aks get-credentials` (Auth über OIDC/Service Principal, keine dauerhaften Secrets im Repo).

### 2) Secret Sync aus Key Vault in den Cluster

**Ziel:** z. B. ein MySQL-Connection-String aus Key Vault landet als Kubernetes Secret / Volume im Pod – ohne Klartext in Git.

**Empfohlener Operator:** [External Secrets Operator](https://external-secrets.io/) **oder** Azure Key Vault Provider for Secrets Store CSI Driver.

**Ablauf mit External Secrets Operator:**

1. Operator im Cluster installieren (Helm)
2. `SecretStore` / `ClusterSecretStore` mit Azure Key Vault als Backend
3. Authentifizierung über **Workload Identity** oder die bestehende AKS Managed Identity (bereits Rolle *Key Vault Secrets User*)
4. `ExternalSecret`-CR definiert: welches KV-Secret → welches K8s-Secret
5. Operator synchronisiert periodisch; App mountet das K8s-Secret als Env/Volume

**Warum Operator statt manueller Sync?**

- Declarative, wiederholbar, auditierbar
- Rotation im Key Vault kann nachgezogen werden
- Passt zu GitOps (CRDs im Repo, Werte bleiben im Vault)

**Alternative CSI Driver:** Secret wird als Volume in den Pod gemountet; ebenfalls identity-basiert gegen Key Vault.

---

## Hinweise für die Demo

- Resource Group im Azure Portal öffnen und Ressourcen zeigen
- `terraform plan` sollte nach erfolgreichem Apply keine bzw. minimale Änderungen zeigen
- Architektur erklären: Endpoint = Tür, DNS = Telefonbuch, RBAC = Erlaubnis
