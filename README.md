# PRODYNA Praxisaufgabe – DevOps / Azure

Terraform-Projekt für eine kleine Azure-Umgebung mit privatem Networking, AKS, Key Vault und Storage.

**Rolle:** DevOps Engineer (Variante A – Konzept)  
**Status:** In der Candidate-Subscription deployed und live vorzeigbar.

---

## Overview

Das Projekt stellt per Terraform bereit:

- VNet mit getrennten Subnets (AKS + Private Endpoints) und NSG
- AKS (1 Node)
- Key Vault + Storage Account
- Private Endpoints, Private DNS Zones, RBAC
- Remote State in Azure Storage

---

## Prerequisites

- Azure CLI + Login in die PRODYNA-Subscription
- Terraform >= 1.5
- Bestehende Resource Group: `RG-Hoda-Yousof` (keine Rechte zum Anlegen neuer RGs)
- State-Backend einmalig angelegt: Storage `stprodynaterraform`, Container `tfstate`, Key `prodyna-dev.tfstate`

---

## Project structure

```text
.
├── main.tf                   # Provider, Backend, Azure-Ressourcen
├── variables.tf              # Eingabevariablen
├── terraform.tfvars.example  # Beispielwerte (echte tfvars ist gitignored)
├── outputs.tf                # Ausgaben nach dem Apply
├── .gitignore
├── .terraform.lock.hcl
└── README.md
```

Flache Struktur bewusst für den Aufgabenumfang. Mögliche Module siehe unten.

---

## How to deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # Werte anpassen
az login && az account show

terraform init
terraform plan
terraform apply
terraform output
```

Optional AKS:

```bash
az aks get-credentials --resource-group RG-Hoda-Yousof --name aks-prodyna-dev
kubectl get nodes
```

Destroy (Kosten): `terraform destroy`  
Hinweis: Der State-Storage wird vom Projekt nicht mitgelöscht.

---

## Design decisions

| Entscheidung | Warum |
|---|---|
| `data` statt `resource` für die RG | Keine `resourcegroups/write`-Rechte; vorgegebene RG nutzen |
| Zwei Subnets | AKS (Compute) getrennt von Private Endpoints (+ NSG) |
| Remote State | Locking, Collaboration, State enthält sensible Daten; Backend muss vor `init` existieren |
| Private Endpoint + DNS | Endpoint = private Tür; DNS = Name → private IP |
| RBAC | AKS Identity = *Key Vault Secrets User*; Terraform-User = *Administrator*; keine Secrets im Code |
| AKS `Standard_B2s_v2` | `Standard_B2s` in dieser Subscription/Region nicht erlaubt |
| Service-CIDR `172.16.0.0/16` | Darf nicht mit VNet `10.0.0.0/16` überlappen |

Terraform verbindet Ressourcen über Referenzen (z. B. `azurerm_subnet.endpoints.id`), nicht über hartcodierte IDs — daraus entsteht der Dependency Graph.

---

## Modul-Aufteilung

Aktuell flach in `main.tf`. Für Skalierung sinnvoll:

| Modul | Inhalt |
|---|---|
| `modules/network` | VNet, Subnets, NSG |
| `modules/aks` | Cluster + Node Pool |
| `modules/keyvault` | Key Vault + PE + DNS |
| `modules/storage` | Storage + PE + DNS |
| `modules/rbac` | Role Assignments |

Vorteil: Wiederverwendung und Staging/Prod über dieselben Module + unterschiedliche `tfvars`.

---

## Azure Infrastructure Architecture

```mermaid
flowchart TB

    %% =========================================================
    %% TERRAFORM
    %% =========================================================

    TF["Terraform"]

    BACKEND["Terraform Backend<br/>Storage Account: stprodynaterraform<br/>Container: tfstate<br/>State: prodyna-dev.tfstate"]

    TF -. "State lesen / speichern" .-> BACKEND


    %% =========================================================
    %% EXISTING RESOURCE GROUP
    %% =========================================================

    subgraph RG["Existing Resource Group: RG-Hoda-Yousof"]

        direction TB

        %% =====================================================
        %% NETWORK
        %% =====================================================

        subgraph VNET["Virtual Network: vnet-prodyna-dev"]

            direction LR

            subgraph AKSNET["AKS Subnet<br/>snet-aks-prodyna-dev"]

                AKS["AKS Cluster<br/>aks-prodyna-dev"]

                NODEPOOL["System Node Pool<br/>Standard_B2s_v2<br/>1 Node"]

                AKS --> NODEPOOL

            end


            subgraph PENET["Private Endpoint Subnet<br/>snet-endpoints-prodyna-dev"]

                NSG["Network Security Group<br/>nsg-prodyna-dev"]

                PEKV["Private Endpoint<br/>Key Vault"]

                PEST["Private Endpoint<br/>Storage Blob"]

            end

        end


        %% =====================================================
        %% AZURE SERVICES
        %% =====================================================

        subgraph SERVICES["Private Azure Services"]

            direction LR

            KV["Key Vault<br/>kv-prodyna-dev<br/>RBAC enabled"]

            STORAGE["Storage Account<br/>stprodynadev<br/>Blob"]

        end


        %% =====================================================
        %% PRIVATE DNS
        %% =====================================================

        subgraph DNS["Private DNS"]

            direction LR

            DNSKV["Private DNS Zone<br/>privatelink.vaultcore.azure.net"]

            DNSST["Private DNS Zone<br/>privatelink.blob.core.windows.net"]

        end


        %% =====================================================
        %% NETWORK CONNECTIONS
        %% =====================================================

        NSG -->|"NSG Association"| PENET

        PEKV -->|"private_connection_resource_id<br/>azurerm_key_vault.main.id"| KV

        PEST -->|"private_connection_resource_id<br/>azurerm_storage_account.main.id"| STORAGE


        %% =====================================================
        %% DNS ZONE GROUPS
        %% =====================================================

        PEKV -.->|"private_dns_zone_ids"| DNSKV

        PEST -.->|"private_dns_zone_ids"| DNSST


        %% =====================================================
        %% VNET DNS LINKS
        %% =====================================================

        DNSKV -.->|"Virtual Network Link"| VNET

        DNSST -.->|"Virtual Network Link"| VNET


        %% =====================================================
        %% RBAC
        %% =====================================================

        AKS -.->|"Managed Identity<br/>Key Vault Secrets User"| KV

        ADMIN["Terraform User<br/>azurerm_client_config.current"]

        ADMIN -.->|"Key Vault Administrator"| KV

    end


    %% =========================================================
    %% TERRAFORM -> RESOURCE GROUP
    %% =========================================================

    TF -->|"data.azurerm_resource_group.main"| RG
```

### Wie die Architektur gelesen wird

```text
Terraform
   │
   ├── State
   │      ↓
   │   Azure Storage Backend
   │
   └── liest bestehende Resource Group
          ↓
   RG-Hoda-Yousof
          │
          ▼
   Virtual Network
          │
          ├───────────────────────────────┐
          │                               │
          ▼                               ▼
     AKS Subnet                  Private Endpoint Subnet
          │                               │
          ▼                      ┌────────┴────────┐
     AKS Cluster                 │                 │
          │                      ▼                 ▼
          │                  PE Key Vault      PE Storage
          │                      │                 │
          │                      ▼                 ▼
          │                  Key Vault         Storage
          │
          │
          └──── Key Vault Secrets User ────────► Key Vault
```

### Private DNS

```text
Key Vault
    ▲
    │
Private Endpoint
    │
    │ DNS Zone Group
    ▼
privatelink.vaultcore.azure.net
    │
    │ Virtual Network Link
    ▼
   VNet
    │
    ▼
AKS kann Key Vault
über private IP auflösen
```

Für Storage funktioniert genau das gleiche Prinzip:

```text
Storage Account
      ▲
      │
Private Endpoint
      │
      │ DNS Zone Group
      ▼
privatelink.blob.core.windows.net
      │
      │ Virtual Network Link
      ▼
     VNet
```

### Die wichtigsten Terraform-Referenzen

```text
AKS Node Pool
    │
    │ vnet_subnet_id
    ▼
azurerm_subnet.aks.id
```

→ **In welches Subnet sollen die AKS Nodes?**

```text
Private Endpoint
    │
    │ subnet_id
    ▼
azurerm_subnet.endpoints.id
```

→ **Wo soll die Netzwerkkarte des Private Endpoints liegen?**

```text
Private Endpoint
    │
    │ private_connection_resource_id
    ▼
azurerm_key_vault.main.id
```

→ **Mit welcher Azure-Ressource soll dieser Private Endpoint verbunden werden?**

```text
Private Endpoint
    │
    │ private_dns_zone_ids
    ▼
azurerm_private_dns_zone.kv.id
```

→ **Welche DNS Zone gehört zu diesem Private Endpoint?**

```text
Private DNS Zone
    │
    │ virtual_network_id
    ▼
azurerm_virtual_network.main.id
```

→ **Welches VNet darf diese Private DNS Zone benutzen?**

```text
Role Assignment
    │
    │ principal_id
    ▼
AKS Managed Identity
```

→ **WER bekommt die Berechtigung?**

```text
Role Assignment
    │
    │ scope
    ▼
Key Vault
```

→ **AUF WELCHER Ressource gilt die Berechtigung?**


**Kurzfluss DNS:** Name → Private DNS Zone → private IP → Private Endpoint → Service.  
**RBAC:** Netzwerkpfad und Berechtigung sind getrennt (PE/DNS vs. Role Assignment).

---

## Variante A – Konzept (DevOps)

> Konzeptbeschreibung laut Aufgabe — nicht zwingend implementiert.

### 1) nginx Deployment + Service (Staging / Production)

IaC im Repo (Kustomize-Overlays oder Helm-Values pro Stage):

- `Deployment` (`nginx:stable`), `Service` (ClusterIP / Ingress)
- Namespaces `staging` / `production`
- Staging: 1 Replica; Production: >= 2, Requests/Limits, immutable Image-Tags, TLS empfohlen
- Pipeline-Idee: GitHub Actions → `kubectl`/`helm` nach Login via OIDC/Service Principal (keine Dauer-Secrets im Repo)

### 2) Secret Sync Key Vault → Cluster

**External Secrets Operator** (oder Secrets Store CSI Driver):

1. Operator installieren  
2. `SecretStore` auf Key Vault  
3. Auth über AKS Managed Identity / Workload Identity (Rolle *Key Vault Secrets User* bereits vorhanden)  
4. `ExternalSecret` mappt KV-Secret → Kubernetes Secret  
5. App nutzt Env/Volume; Sync läuft periodisch, Rotation möglich  

Kein Klartext im Git — nur Declarative CRs, Werte bleiben im Vault.

---

## Demo checklist

- Portal: Ressourcen in `RG-Hoda-Yousof` zeigen  
- `terraform plan` (sollte clean / minimal sein)  
- Erklären: Endpoint = Tür, DNS = Telefonbuch, RBAC = Erlaubnis  
