# TM Agent (taide) - Azure IaC

`@47. CEO Agent/Azure` (ceoagent-dev)의 구조/모듈 패턴을 기반으로 작성한 TM Agent(taide) 프로젝트용 Terraform 코드입니다.

## 구조

```
02. IaC/
├── modules/
│   ├── resourcegroup/       # Resource Group
│   ├── virtualnetwork/      # VNet (Private Endpoint용)
│   ├── subnet/               # Subnet
│   ├── privatednszone/       # Private DNS Zone
│   ├── privatednszonelink/   # Private DNS Zone <-> VNet Link
│   ├── privateendpoint/      # Private Endpoint
│   ├── foundry/              # AI Foundry (Cognitive Account: AIServices) + 모델 배포
│   ├── aisearch/             # Azure AI Search
│   ├── containerregistry/    # Azure Container Registry (Premium)
│   └── serviceprincipal/     # CI/CD 연동용 Entra ID App + Service Principal
└── environments/
    ├── taide-dev/         # 개발 환경
    ├── taide-prd/         # 운영 환경
    └── cicd/              # CI/CD용 공용 Service Principal + Role Assignment
```

## ceoagent-dev 대비 변경/제외 사항

- **테스트용 VM 제외**: ceoagent-dev의 "Foundry 연동 테스트용 VM"(및 관련 public IP, NSG, linuxvm 모듈)은 제외했습니다. 필요 없는 리소스이기 때문입니다.
- **Private Endpoint는 포함**: Foundry·AI Search·Container Registry 연결용으로 각 환경 전용 VNet/Subnet, Private DNS Zone(openai/cognitiveservices/services.ai/search/azurecr), Private Endpoint를 ceoagent-dev와 동일한 패턴으로 구성했습니다. (public network access는 기본값(Enabled)을 그대로 두었으며, 필요 시 `aisearch`/`containerregistry` 모듈의 `public_network_access_enabled`나 `foundry` 리소스에 `public_network_access_enabled = false`를 추가해 비활성화할 수 있습니다.)
- **AI Search 추가 (현재 비활성화)**: `modules/aisearch` 모듈을 신규로 만들어 각 환경에 `azurerm_search_service`를 추가했으나, AI Search는 AKS 내 OSS(예: OpenSearch 등)로 대체 설치할 예정이라 `environments/*/main.tf`의 `ai_search`/`search_pe`/`search_dns`/`search_dns_link` 모듈 블록은 현재 주석 처리되어 있습니다. 향후 Azure AI Search를 다시 사용할 경우를 대비해 코드는 남겨 두었습니다.
- **Container Registry 추가**: `modules/containerregistry` 모듈을 신규로 만들어 각 환경에 `azurerm_container_registry`(Premium — Private Endpoint 사용 요건)를 추가했습니다.
- **네트워크 리소스그룹 제외**: 별도 `network-rg` 없이 `ai-rg` 하나에 RG/VNet/PE 리소스를 모두 둡니다.

## 태그

모든 리소스에 다음 태그가 공통 적용됩니다 (`variables.tf`의 `tags`, 각 환경 `terraform.tfvars`에서 값 지정).

| key   | value                         |
|-------|-------------------------------|
| owner | `tm agent (taide)`             |
| env   | `dev` (taide-dev) / `prd` (taide-prd) |

## 리소스 이름 규칙

폴더/모듈 이름은 `taide-dev`, `taide-prd`를 유지하되, 실제 Azure 리소스 이름은 `dev → d`, `prd → p`로 축약하고 Foundry는 `msf`, AI Search는 `srch01`로 끝나도록 명명합니다. 단, Resource Group 이름은 `dev`/`prd`를 축약하지 않고 그대로 사용합니다.

| 리소스 | taide-dev | taide-prd |
|---|---|---|
| Resource Group | `taide-ai-dev-rg` | `taide-ai-prd-rg` |
| VNet | `taide-d-vnet` | `taide-p-vnet` |
| PE Subnet | `taide-pe-d-snet` | `taide-pe-p-snet` |
| AI Foundry | `taide-d-msf` | `taide-p-msf` |
| AI Foundry PE | `taide-d-msf-pe` | `taide-p-msf-pe` |
| AI Search (비활성화) | `taide-d-srch01` | `taide-p-srch01` |
| AI Search PE (비활성화) | `taide-d-srch01-pe` | `taide-p-srch01-pe` |
| Container Registry | `taidedevcr` | `taideprdcr` |
| Container Registry PE | `taidedevcr-pe` | `taideprdcr-pe` |

Container Registry 이름은 Azure 제약(영숫자만 허용, 하이픈 불가)에 맞춰 `taidedevcr`/`taideprdcr`로 지었습니다.

> **AI Search 비활성화 안내**: AI Search는 AKS 내 OSS로 대체 설치 예정이라 현재 `main.tf`에서 관련 모듈(`ai_search`, `search_pe`, `search_dns`, `search_dns_link`)이 주석 처리되어 실제로 배포되지 않습니다. 위 이름/SKU 표기는 향후 재사용 시 참고용입니다.

## SKU

두 환경 동일하게 다음 SKU로 명시 지정했습니다 (`main.tf`에서 모듈 기본값을 오버라이드).

| 리소스 | SKU |
|---|---|
| Container Registry | `Premium` (Private Endpoint 사용 요건) |
| AI Search | `basic` |

VNet 주소 공간은 `taide-dev` = `10.160.0.0/24`, `taide-prd` = `10.161.0.0/24` (PE 서브넷은 각각 `.0/25`)로 두어 서로 겹치지 않게 했습니다.

## 모델 배포

`foundry` 모듈은 `model_deployments`(map, `for_each`)로 Foundry 계정 하나에 여러 OpenAI 모델을 배포할 수 있습니다. 두 환경 모두 아래 5개 모델을 배포하며, 버전 업그레이드 정책은 전 배포 공통으로 `version_upgrade_option = "OnceCurrentVersionExpired"`(현재 버전이 만료되는 경우)입니다.

| 배포 이름 | 모델 버전 | taide-dev capacity | taide-prd capacity |
|---|---|---|---|
| gpt-5.5 | 2026-04-24 | 5004 | 5997 |
| gpt-5.6-luna | 2026-07-09 | 3007 | 2997 |
| gpt-5.6-sol | 2026-07-09 | 3990 | 7993 |
| gpt-5.6-terra | 2026-07-09 | 3003 | 6001 |
| text-embedding-3-large | 1 | 12003 | 1964 |

capacity 단위는 1,000 TPM(분당 토큰) 기준이며(예: `5004` = 5,004,000 TPM), 배포 유형은 모두 `GlobalStandard`(글로벌 표준)입니다.

## CI/CD 연동용 Service Principal (`environments/cicd`)

별도 CI/CD 파이프라인이 `taidedevcr`/`taideprdcr`에 이미지를 push/pull할 수 있도록, dev/prd
공용 Service Principal(`taide-cicd-acr-sp`)과 Role Assignment를 `environments/cicd`에
따로 구성했습니다.

- **SP 구성**: dev/prd 공용 1개 (`modules/serviceprincipal`이 Entra ID App 등록 +
  Service Principal + 클라이언트 시크릿을 생성).
- **권한**: `AcrPush`(push+pull) — 이미지를 빌드해 push하고 필요 시 pull도 하는 일반적인
  CI/CD 빌드 파이프라인에 맞춘 권한입니다.
- **범위(scope)**: ACR 리소스 단위가 아니라 **리소스그룹 단위**(`taide-ai-dev-rg`,
  `taide-ai-prd-rg`)로 부여했습니다. `AcrPush`는 Container Registry 리소스 타입에만
  의미가 있는 액션이라, RG 단위로 줘도 실질적으로는 해당 RG 안의 ACR에만 적용됩니다.
- **시크릿 로테이션**: 기본 365일 유효(`secret_validity_days` 변수)이며, `time_rotating`
  리소스로 관리되어 유효기간이 지나야만 다음 apply 때 새 시크릿으로 교체됩니다(매 apply마다
  바뀌지 않음).
- **배포 순서**: `environments/cicd`는 `data "azurerm_resource_group"`로 dev/prd
  리소스그룹을 조회하므로, **taide-dev/taide-prd가 먼저 배포되어 있어야** 합니다.
- **자격증명 확인**: `terraform apply` 후 `terraform output client_id` /
  `terraform output tenant_id` / `terraform output -raw client_secret`으로 값을 꺼내
  CI/CD 플랫폼의 시크릿 저장소에 등록하세요. 시크릿은 `terraform.tfstate`에도 평문으로
  남으므로(다른 환경과 마찬가지로 `.gitignore`에 의해 git에는 커밋되지 않음) state 파일
  자체의 접근 권한 관리가 중요합니다.
- **사전 권한 요건**: 이 환경은 Azure 구독 권한이 아니라 **Entra ID(Azure AD)에서 앱 등록
  권한**(Application Administrator/Cloud Application Administrator 역할, 또는 테넌트가
  일반 사용자의 앱 등록을 허용하는 설정)이 있어야 `terraform apply`가 성공합니다.

## 사용법

```bash
cd environments/taide-dev   # 또는 taide-prd
terraform init
terraform plan
terraform apply
```

- `terraform.tfvars.example`을 참고해 `terraform.tfvars`의 값을 환경에 맞게 조정하세요.
- Foundry 리소스는 ceoagent-dev와 동일하게 모델 가용 리전인 `EastUS2`에 고정 배포되며, 그 외 리소스(RG, AI Search)는 `var.location`(기본 `koreacentral`)을 따릅니다.
- 리소스 이름(`taide-d-msf`, `taide-d-srch01` 등)은 Azure 전역에서 고유해야 하는 리소스이므로, 실제 배포 전 이름 충돌 여부를 확인하세요.
