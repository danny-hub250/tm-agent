# TM Agent (aide) - Azure IaC

`@47. CEO Agent/Azure` (ceoagent-dev)의 구조/모듈 패턴을 기반으로 작성한 TM Agent(aide) 프로젝트용 Terraform 코드입니다.

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
│   ├── foundry/              # AI Foundry (Cognitive Account: AIServices) + 모델 배포 + Foundry Project
│   ├── aisearch/             # Azure AI Search
│   ├── containerregistry/    # Azure Container Registry (Premium)
│   └── serviceprincipal/     # CI/CD 연동용 Entra ID App + Service Principal
└── environments/
    ├── aide-dev/         # 개발 환경
    ├── aide-prd/         # 운영 환경
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
| owner | `tm agent (aide)`             |
| env   | `dev` (aide-dev) / `prd` (aide-prd) |

## 리소스 이름 규칙

폴더/모듈 이름은 `aide-dev`, `aide-prd`를 유지하되, 실제 Azure 리소스 이름은 `dev → d`, `prd → p`로 축약하고 Foundry는 `msf`, AI Search는 `srch01`로 끝나도록 명명합니다. 단, Resource Group 이름은 `dev`/`prd`를 축약하지 않고 그대로 사용합니다.

| 리소스 | aide-dev | aide-prd |
|---|---|---|
| Resource Group | `aide-ai-dev-rg` | `aide-ai-prd-rg` |
| VNet | `aide-d-vnet` | `aide-p-vnet` |
| PE Subnet | `aide-pe-d-snet` | `aide-pe-p-snet` |
| AI Foundry | `aide-d-msf` | `aide-p-msf` |
| AI Foundry PE | `aide-d-msf-pe` | `aide-p-msf-pe` |
| Foundry Project | `aide-d-msf-aideagent` | `aide-p-msf-aideagent` |
| AI Search (비활성화) | `aide-d-srch01` | `aide-p-srch01` |
| AI Search PE (비활성화) | `aide-d-srch01-pe` | `aide-p-srch01-pe` |
| Container Registry | `aidedevcr` | `aideprdcr` |
| Container Registry PE | `aidedevcr-pe` | `aideprdcr-pe` |

Container Registry 이름은 Azure 제약(영숫자만 허용, 하이픈 불가)에 맞춰 `aidedevcr`/`aideprdcr`로 지었습니다.

> **AI Search 비활성화 안내**: AI Search는 AKS 내 OSS로 대체 설치 예정이라 현재 `main.tf`에서 관련 모듈(`ai_search`, `search_pe`, `search_dns`, `search_dns_link`)이 주석 처리되어 실제로 배포되지 않습니다. 위 이름/SKU 표기는 향후 재사용 시 참고용입니다.

## SKU

두 환경 동일하게 다음 SKU로 명시 지정했습니다 (`main.tf`에서 모듈 기본값을 오버라이드).

| 리소스 | SKU |
|---|---|
| Container Registry | `Premium` (Private Endpoint 사용 요건) |
| AI Search | `basic` |

VNet 주소 공간은 `aide-dev` = `10.70.254.0/27`, `aide-prd` = `10.70.254.32/27`로 서로
겹치지 않게 나눴습니다(사내 IP 관리 시트 기준 확정값). PE 서브넷은 각 VNet의 `/27` 전체
대역을 그대로 사용합니다(환경당 서브넷이 1개뿐이라 별도로 쪼개지 않음). VNet peering(허브
VNet 연결)은 이번 범위에서 제외했습니다 — 추후 별도로 추가할 예정입니다.

## 모델 배포

`foundry` 모듈은 `model_deployments`(map, `for_each`)로 Foundry 계정 하나에 여러 OpenAI 모델을 배포할 수 있습니다. 두 환경 모두 아래 5개 모델을 배포하며, 버전 업그레이드 정책은 전 배포 공통으로 `version_upgrade_option = "OnceCurrentVersionExpired"`(현재 버전이 만료되는 경우)입니다.

| 배포 이름 | 모델 버전 | aide-dev capacity | aide-prd capacity |
|---|---|---|---|
| gpt-5.5 | 2026-04-24 | 5004 | 5997 |
| gpt-5.6-luna | 2026-07-09 | 3007 | 2997 |
| gpt-5.6-sol | 2026-07-09 | 3990 | 7993 |
| gpt-5.6-terra | 2026-07-09 | 3003 | 6001 |
| text-embedding-3-large | 1 | 10000\* | 1964 |

capacity 단위는 1,000 TPM(분당 토큰) 기준이며(예: `5004` = 5,004,000 TPM), 배포 유형은 모두 `GlobalStandard`(글로벌 표준)입니다.

\* aide-dev 구독의 EastUS2 text-embedding-3-large quota 한도가 10000이라, 원래 목표(12003)를
넘어 quota 최대치로 낮췄습니다. 나머지 4개 모델은 두 구독 모두 quota(10000) 이내라 원래
목표값 그대로입니다.

`foundry` 모듈은 `project_name`을 지정하면 Foundry 계정 하위에 **Foundry Project**
(`azurerm_cognitive_account_project`, ARM 타입 `Microsoft.CognitiveServices/accounts/projects`)도
함께 생성합니다. 두 환경 모두 `aide-{d,p}-msf-aideagent`라는 이름으로 프로젝트를 생성하며,
System-Assigned Identity를 사용합니다. Foundry Project를 만들려면 상위 Foundry 계정
(`azurerm_cognitive_account`) 자체도 `project_management_enabled = true`와
System-Assigned Identity가 있어야 해서, `project_name`이 지정된 경우에만 계정에도 identity
블록을 동적으로 추가합니다.

## 배포 대상 구독

`aide-dev`/`aide-prd`는 **서로 다른 구독**에 배포됩니다 (`providers.tf`에 `subscription_id`/
`tenant_id`를 명시).

| 환경 | 구독 이름 | 구독 ID |
|---|---|---|
| aide-dev | `aide-dev` | `3c71accf-dcb0-4a1d-8c8b-8e363c06a8bb` |
| aide-prd | `aide-prd` | `dc07dd36-71ed-4355-8c70-0a753a948c63` |

두 구독 모두 테넌트 `skinc-aide`(`taidesk.onmicrosoft.com`, tenant id
`06c7ea6f-b5db-4ca2-a0fe-e1d59620e937`) 소속입니다. `terraform apply` 전 이 테넌트로
`az login --tenant 06c7ea6f-b5db-4ca2-a0fe-e1d59620e937`이 되어 있어야 합니다(별도 조직
계정이라 MFA 등 대화형 로그인 필요).

## CI/CD 연동용 Service Principal + 커스텀 Role (`environments/cicd`)

별도 CI/CD 파이프라인이 `aidedevcr`/`aideprdcr`에 접근할 수 있도록, dev/prd 공용 Service
Principal과 커스텀 Role Assignment를 `environments/cicd`에 구성했습니다.

- **SP 구성**: dev/prd 공용 1개 (`modules/serviceprincipal`이 Entra ID App 등록 +
  Service Principal + 클라이언트 시크릿을 생성). 이름은 `aidecr-sp`.
- **권한**: 참고 프로젝트(skbax)의 `full-admin-acr` 커스텀 역할을 그대로 재현한
  `azurerm_role_definition`(ACR 등록/삭제/자격증명/replication/webhook/task 등 113개 액션 —
  Container Registry에 대한 전권). 내장 역할 `AcrPush`보다 넓은 범위이므로 필요 이상의 권한이
  아닌지 주기적으로 재검토하는 것을 권장합니다.
- **범위(scope)**: `aide-dev`/`aide-prd` **구독 단위**로 role assignment(참고
  프로젝트 skbax와 동일한 패턴 — 구독에 할당하면 그 하위 모든 RG/ACR에 자동 상속됨). 역할
  자체의 `assignable_scopes`도 이 두 구독을 포함하도록 만들어 하나의 역할 정의를 양쪽에서
  재사용합니다.
- **구독 분리 대응**: dev/prd가 서로 다른 구독이라, `providers.tf`에 `azurerm.dev`/
  `azurerm.prd` 두 개의 provider alias를 두고 각 구독의 role assignment에 명시적으로
  지정합니다. SP(앱 등록) 자체는 테넌트 단위 리소스라 별칭 없는 단일 `azuread` provider로
  한 번만 생성합니다.
- **시크릿 로테이션**: 기본 365일 유효(`secret_validity_days` 변수)이며, `time_rotating`
  리소스로 관리되어 유효기간이 지나야만 다음 apply 때 새 시크릿으로 교체됩니다(매 apply마다
  바뀌지 않음).
- **자격증명 확인 및 개발자 전달**: `terraform apply` 후 아래 값을 꺼내 개발자에게 전달하고,
  CI/CD 플랫폼의 시크릿 저장소에도 등록하세요.

  | 전달 항목 | Terraform output | 확인 명령 |
  |---|---|---|
  | appid | `client_id` | `terraform output client_id` |
  | tenantid | `tenant_id` | `terraform output tenant_id` |
  | secret | `client_secret` | `terraform output -raw client_secret` |

  시크릿은 `terraform.tfstate`에도 평문으로 남으므로(다른 환경과 마찬가지로 `.gitignore`에
  의해 git에는 커밋되지 않음) state 파일 자체의 접근 권한 관리가 중요합니다.
- **사전 권한 요건**: Azure 구독 권한(커스텀 역할 정의를 만들 수 있는 `Owner` 또는
  `User Access Administrator`)과, **Entra ID(Azure AD)에서 앱 등록 권한**(Application
  Administrator/Cloud Application Administrator 역할, 또는 테넌트가 일반 사용자의 앱 등록을
  허용하는 설정)이 모두 있어야 `terraform apply`가 성공합니다.

## 개발자 전달용 엔드포인트 목록

`environments/aide-dev`, `environments/aide-prd` 각각에 `outputs.tf`를 추가해, `04. 리소스
구성 내역` 시트의 Azure 엔드포인트 표(AOAI/ACR, env, Endpoint, Port)에 대응하는 값을
`terraform apply` 직후 바로 뽑을 수 있게 했습니다 (`terraform output`).

| 리소스 | env | Endpoint | Terraform output | Port |
|---|---|---|---|---|
| AOAI | Dev/Prd | `https://aide-{d,p}-msf.openai.azure.com/` | `aoai_openai_endpoint` | 443 |
| AOAI | Dev/Prd | `https://aide-{d,p}-msf.cognitiveservices.azure.com` | `aoai_cognitiveservices_endpoint` | 443 |
| AOAI | Dev/Prd | `https://aide-{d,p}-msf.services.ai.azure.com` | `aoai_services_ai_endpoint` | 443 |
| ACR | Dev/Prd | `https://aide{dev,prd}cr.azurecr.io` | `acr_login_server_endpoint` | 443 |
| ACR | Dev/Prd | `https://aide{dev,prd}cr.koreacentral.data.azurecr.io` | `acr_data_endpoints` | 443 |

ACR의 지역별 전용 데이터 엔드포인트(`<registry>.<region>.data.azurecr.io`)를 실제로 노출하기
위해 `modules/containerregistry`의 `data_endpoint_enabled` 기본값을 `true`로 설정했습니다
(Premium SKU에서만 지원).

### 방화벽 신청용 IP 확인 (`firewall_endpoints`)

위 표의 IP는 Private Endpoint 특성상 고정값이 아니라 배포 시점에 VNet 대역 내에서 할당되는
사설 IP라, 미리 채울 수 없습니다. 대신 `terraform apply` 후 `terraform output -json
firewall_endpoints`로 각 환경의 Foundry PE(3개 FQDN) + ACR PE(2개 FQDN, 로그인서버·데이터
엔드포인트)에 실제 할당된 `{fqdn, ip_addresses}` 목록을 바로 확인할 수 있습니다
(`modules/privateendpoint`의 `dns_configs` output). `private_dns_zone_group`을 쓰는 구성에서는
`azurerm_private_endpoint`의 `custom_dns_configs`가 항상 빈 목록으로 남고, 실제 레코드는
`private_dns_zone_configs[].record_sets[]`에 생성되므로 이를 평탄화해서 노출합니다(2026-08-31
`aide-dev` 실배포로 확인함). 방화벽 신청 문서에는 이 값을 그대로 사용하면 됩니다.

## 사용법

```bash
cd environments/aide-dev   # 또는 aide-prd
terraform init
terraform plan
terraform apply
```

- `terraform.tfvars.example`을 참고해 `terraform.tfvars`의 값을 환경에 맞게 조정하세요.
- Foundry 리소스는 ceoagent-dev와 동일하게 모델 가용 리전인 `EastUS2`에 고정 배포되며, 그 외 리소스(RG, AI Search)는 `var.location`(기본 `koreacentral`)을 따릅니다.
- 리소스 이름(`aide-d-msf`, `aide-d-srch01` 등)은 Azure 전역에서 고유해야 하는 리소스이므로, 실제 배포 전 이름 충돌 여부를 확인하세요.
