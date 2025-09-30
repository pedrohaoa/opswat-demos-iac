# opswat-demos-iac

Infraestructura como código (IaC) en **Azure** con **Bicep** para desplegar un entorno de demo seguro que integra:
- **MinIO** (S3 compatible) en VM Ubuntu con **cloud-init** y secretos en **Azure Key Vault** (vía **User-Assigned Managed Identity**).
- Red **VNet** con subredes separadas (`snet-opswat`, `snet-minio`, `snet-admin`) y **Azure Bastion**.
- **Key Vault** con **RBAC + Private Endpoint + Private DNS**.
- **Log Analytics** + **Diagnostic Settings** para auditoría (Key Vault) y red (NSG MinIO).
- Espacio para añadir VMs **OPSWAT MetaDefender Core** y **MetaDefender Storage Security (MDSS)**.

> **Estado**: pensado para *PoC/Dev*. Incluye controles de seguridad base y recomendaciones para endurecer a producción.

---

## 🗂️ Estructura del repositorio
.
├─ cloud-init/
│ ├─ minio-cloud-config.yaml # cloud-init (IMDS + REST a Key Vault; monta data disk)
│ └─ minio-setup.sh # versión anterior (no recomendada); se mantiene por referencia
├─ modules/
│ ├─ keyvault.bicep # KV + UAMI + roles + secretos MinIO (outputs: clientId, etc.)
│ └─ minio-vm.bicep # VM MinIO + NSG restringido + data disk + cloud-init
├─ main.bicep # VNet + subnets + Bastion + Private DNS + PE KV + LAW + Diag
└─ README.md

---

## 🔐 Diseño de seguridad (resumen)

- **Secretos** en **Key Vault** con **RBAC** (no Access Policies).  
- **Key Vault** con **Private Endpoint** y **Private DNS** (`privatelink.vaultcore.azure.net`).  
- **MinIO** sin IP pública; **NSG** permite **22/9000/9001 solo desde la VNet** (acceso mediante **Bastion** / jumpbox).  
- **cloud-init** usa **IMDS + REST** (no Azure CLI) para obtener secretos con la **UAMI**.  
- **Disco de datos** dedicado (XFS) montado en `/data`.  
- **Log Analytics** + **Diagnostic Settings**: `AuditEvent` (KV) y eventos/contadores de NSG.

---

## ✅ Prerrequisitos

- **Azure CLI** (>=2.58) con `az login`.
- **VS Code** con extensión **Bicep**.
- Permisos RBAC para crear recursos en el **Resource Group** (Contributor + Key Vault Administrator recomendado para bootstrap).
- Tu **Object ID** de Entra ID:
  ```bash
  az ad signed-in-user show --query id -o tsv


⚙️ Parâmetros principales
Parámetro	        Dónde	                   Descripción
namePrefix	        main.bicep	            Prefijo de nombres (p.ej., opswat).
adminUsername	    main.bicep	            Usuario admin para VMs.
adminPassword	    main.bicep	            Contraseña admin (se solicita/puede ir por parámetro).
adminObjectId	    main.bicep	            Object ID del usuario para RBAC en Key Vault.
lawRetentionDays	main.bicep	            Días de retención en Log Analytics (default 30).
dataDiskSizeGB	    modules/minio-vm.bicep	Tamaño del disco de datos de MinIO (default 512 GB).

Secretos MinIO: minio-root-user y minio-root-password se crean en Key Vault dentro del módulo keyvault.bicep. 
Cambia el valor por defecto del usuario y no reutilices contraseñas.