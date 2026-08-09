# Terraform Apply – Fehler & Learnings (für Interview)

## 1. AuthorizationFailed – Resource Group erstellen
**Symptom:** `az group create` / kein `resourcegroups/write`  
**Ursache:** Candidate-Subscription erlaubt keine neuen RGs, nur Arbeit in vorgegebener RG (`RG-Hoda-Yousof`).  
**Fix:** Bestehende RG per `data "azurerm_resource_group"` einlesen statt `resource` zu erstellen.  
**Interview:** Rechte prüfen (`az group list`, Role Assignments), vorgegebene RG nutzen.

## 2. Leere variables.tf / terraform.tfvars
**Symptom:** `Reference to undeclared input variable "resource_group_name"`  
**Ursache:** Dateien waren im Editor sichtbar, auf Disk aber 0 Bytes (nicht gespeichert).  
**Fix:** Dateien wirklich speichern; Terraform liest nur Dateien vom Disk.  
**Interview:** Editor ≠ Disk; immer speichern vor `plan`/`apply`.

## 3. AKS VM Size nicht erlaubt
**Symptom:** `Standard_B2s is not allowed in your subscription in location 'westeurope'`  
**Ursache:** SKU/Quota-Einschränkung in der Candidate-Subscription.  
**Fix:** Erlaubte Size aus Fehlermeldung nehmen → `Standard_B2s_v2`.  
**Interview:** SKUs sind regions- und subscription-abhängig; Fehlerliste lesen und anpassen.

## 4. Service CIDR überlappt VNet
**Symptom:** `ServiceCidrOverlapExistingSubnetsCidr` – `service CIDR 10.0.0.0/16` konfliktiert mit Subnet `10.0.1.0/24`  
**Ursache:** AKS Default-Service-CIDR = `10.0.0.0/16`, VNet ebenfalls `10.0.0.0/16`.  
**Fix:** Im `network_profile` z.B.  
`service_cidr = "172.16.0.0/16"` und `dns_service_ip = "172.16.0.10"`.  
**Interview:** Bei Azure CNI dürfen Service-CIDR und VNet-Address-Space nicht überlappen.

---

## Noch offen / später prüfen
- Ob `terraform apply` nach CIDR-Fix komplett durchläuft (AKS + Role Assignment)
- Optional härten: `public_network_access_enabled = false` für Key Vault/Storage
- GitHub Push + README + Variante A Konzept
