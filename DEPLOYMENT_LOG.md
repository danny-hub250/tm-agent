# 배포 실행 이력 (Deployment Log)

이 문서는 `terraform apply`로 실제 Azure에 배포를 실행한 이력을 남깁니다. 코드 변경 이력은 git log를, 리소스 이름/설계 근거는 `README.md`를 참고하세요.

## 2026-08-27 — aide-dev / aide-prd 최초 배포

**대상 구독**: `mySUNI AI Portal - LJK` (subscription id `d6ec08db-4ce1-4ed6-b16c-b4ff61504b4d`, tenant `SK Inc.` / `e102c4ba9ad04f3aa434.onmicrosoft.com`)

### 사전 변경 사항
- AI Search는 AKS 내 OSS로 대체 설치할 예정이라 `ai_search`/`search_pe`/`search_dns`/`search_dns_link` 모듈을 두 환경 모두 주석 처리 (향후 재사용 대비 코드는 보존).
- 배포 전 조회 결과, 이 구독의 EastUS2 리전 OpenAI GlobalStandard quota가 5개 모델(gpt-5.5, gpt-5.6-luna, gpt-5.6-sol, gpt-5.6-terra, text-embedding-3-large) 각각 1000(=1,000,000 TPM)으로 제한되어 있어, 원래 목표 capacity를 그대로 적용할 수 없었음.

### aide-dev 배포 결과 — ✅ 성공 (20/20)
- 모델 capacity를 원래 목표값(5004/3007/3990/3003/12003) 대신 quota 한도인 **1000**으로 임시 조정 후 배포.
- 리소스그룹 `aide-ai-dev-rg` 하위 20개 리소스 전부 `Succeeded`:
  VNet/Subnet, Private DNS Zone 4개 + Link 4개, Foundry(`aide-d-msf`) + 모델 배포 5개, Foundry PE, Container Registry(`aidedevcr`, Premium) + PE.
- 원래 목표 capacity 값은 `environments/aide-dev/main.tf` 주석에 보존.

### aide-prd 배포 결과 — ⚠️ 부분 성공 (15/20)
- dev와 동일 구독/리전을 사용하므로 EastUS2 quota가 dev 배포로 이미 모델당 1000/1000(잔여 0) 소진된 상태에서 시도.
- 모델 capacity를 100으로 낮춰 시도했으나, 5개 모델 배포(`gpt-5.5`, `gpt-5.6-luna`, `gpt-5.6-sol`, `gpt-5.6-terra`, `text-embedding-3-large`) 전부 `InsufficientQuota`(가용 용량 0)로 **실패**.
- 나머지 15개 리소스(RG `aide-ai-prd-rg`, VNet/Subnet, Private DNS Zone 4개 + Link 4개, Foundry 계정 `aide-p-msf`(모델 없음), Foundry PE, Container Registry(`aideprdcr`, Premium) + PE)는 정상 생성됨.
- `terraform state`에는 성공한 15개 리소스만 반영되어 있어, quota 증설 후 재적용 시 모델 배포 5개만 추가 생성되면 됨. 원래 목표 capacity 값(5997/2997/7993/6001/1964)은 `environments/aide-prd/main.tf` 주석에 보존.

### 후속 조치 (미완료)
- [ ] `mySUNI AI Portal - LJK` 구독의 EastUS2 OpenAI GlobalStandard quota를 dev+prd 합산 필요량 기준으로 증설 요청
- [ ] 증설 승인 후 두 환경 모두 `model_deployments`의 capacity를 주석에 남긴 원래 목표값으로 복원하고 `terraform apply` 재실행 (dev: gpt-5.5=5004/luna=3007/sol=3990/terra=3003/embedding=12003, prd: gpt-5.5=5997/luna=2997/sol=7993/terra=6001/embedding=1964)
- [ ] AI Search를 실제로 사용하게 될 경우 주석 처리된 `ai_search`/`search_pe`/`search_dns`/`search_dns_link` 모듈 복원

## 2026-08-27 — aide-dev / aide-prd 리소스 삭제

위에서 배포했던 두 환경을 모두 `terraform destroy`로 삭제함.
- **aide-dev**: 20/20 리소스 삭제 성공 (`aide-ai-dev-rg` 리소스그룹 자체도 삭제 완료).
- **aide-prd**: state에 반영되어 있던 15/15 리소스 삭제 성공 (모델 배포 5개는 애초에 quota 실패로 생성되지 않아 대상에서 제외).
- `az group exists`로 두 리소스그룹 모두 삭제 확인.

## 2026-08-27 — 프로젝트 네이밍 `aide` → `taide` 전체 변경

실제 Azure에 배포된 리소스가 없는 상태에서, 프로젝트 닉네임과 리소스 이름 프리픽스를 `aide`에서 `taide`로 전체 변경함 (폴더명, Azure 리소스 이름 문자열, `owner` 태그 값, `README.md`). 위 두 절(최초 배포/삭제)의 기록은 **당시 실제 사용된 이름(`aide-*`) 그대로 보존**하며, 이후 재배포 시에는 `taide-*` 이름으로 생성됨:

| 리소스 | 변경 전 (aide) | 변경 후 (taide) |
|---|---|---|
| 환경 폴더 | `environments/aide-dev`, `environments/aide-prd` | `environments/taide-dev`, `environments/taide-prd` |
| Resource Group | `aide-ai-dev-rg` / `aide-ai-prd-rg` | `taide-ai-dev-rg` / `taide-ai-prd-rg` |
| VNet / Subnet | `aide-d-vnet` 등 | `taide-d-vnet` 등 |
| AI Foundry | `aide-d-msf` / `aide-p-msf` | `taide-d-msf` / `taide-p-msf` |
| Container Registry | `aidedevcr` / `aideprdcr` | `taidedevcr` / `taideprdcr` |
| owner 태그 | `tm agent (aide)` | `tm agent (taide)` |

`tm-agent-aide-iac.md`(세션 노트)는 과거 의사결정 히스토리 문서라 그대로 두었고, README.md가 현재 네이밍의 source of truth임.

## 2026-08-31 — 프로젝트 네이밍 `taide` → `aiden` 전체 변경 + Foundry Project 리소스 추가

사내 리소스 구성 내역 시트(`04. 리소스 구성 내역`)의 네이밍에 맞춰 프로젝트 닉네임과 리소스
이름 프리픽스를 `taide`에서 `aiden`으로 다시 변경함 (폴더명, Azure 리소스 이름 문자열, `owner`
태그 값, `README.md`, `environments/cicd`). 이전 절들의 `aide-*`/`taide-*` 기록은 그대로
보존하며, 이후 재배포 시에는 `aiden-*` 이름으로 생성됨:

| 리소스 | 변경 전 (taide) | 변경 후 (aiden) |
|---|---|---|
| 환경 폴더 | `environments/taide-dev`, `environments/taide-prd` | `environments/aiden-dev`, `environments/aiden-prd` |
| Resource Group | `taide-ai-dev-rg` / `taide-ai-prd-rg` | `aiden-ai-dev-rg` / `aiden-ai-prd-rg` |
| AI Foundry | `taide-d-msf` / `taide-p-msf` | `aiden-d-msf` / `aiden-p-msf` |
| Container Registry | `taidedevcr` / `taideprdcr` | `aidendevcr` / `aidenprdcr` |
| CI/CD SP | `taide-cicd-acr-sp` | `aiden-cicd-acr-sp` |
| owner 태그 | `tm agent (taide)` | `tm agent (aiden)` |

같은 작업에서 `modules/foundry`에 **Foundry Project**(`azurerm_cognitive_account_project`,
`Microsoft.CognitiveServices/accounts/projects`) 리소스 생성 기능을 추가하고, 두 환경 모두
`aiden-{d,p}-msf-aidenagent` 프로젝트를 생성하도록 연결함(System-Assigned Identity 필요 —
리소스 자체가 identity 블록을 요구함).

**의도적으로 반영하지 않은 시트 내용**: 참고 시트에는 이 외에도 (1) `ai-rg`와 별도인
`network-rg` 분리, (2) 허브 VNet과의 Peering, (3) VNet `/27` 등 다른 주소 체계가 있었으나,
사용자 요청 범위가 "네이밍 + Foundry Project"로 한정되어 이번엔 반영하지 않음. 필요 시 별도
작업으로 진행.

fmt/init/validate/plan 모두 통과 (dev/prd 각각 21개 리소스 생성 예정 — 기존 20개 + Foundry
Project 1개). 아직 `terraform apply`는 하지 않음(Azure에 배포된 리소스 없음).

## 2026-08-31 — CI/CD Service Principal 이름 변경

`environments/cicd`의 SP `display_name`을 `aiden-cicd-acr-sp` → **`aidencr-sp`**로 변경함
(사용자 요청). ACR push/pull용 SP라는 용도만 명확히 드러내는 짧은 이름으로 단순화. 역할/스코프
(AcrPush, dev·prd RG 단위) 등 나머지 설정은 변경 없음. fmt/validate 통과, 아직 apply 안 함.

## 2026-08-31 — 배포 대상 구독 확정(aide-dev/aide-prd) + CI/CD 역할을 full-admin-acr 커스텀 롤로 교체

- `aiden-dev`/`aiden-prd`의 실제 배포 대상을 그동안 쓰던 `mySUNI AI Portal - LJK`(테넌트
  SK Inc.)에서, 프로젝트 전용 구독인 **`aide-dev`(3c71accf-dcb0-4a1d-8c8b-8e363c06a8bb)**/
  **`aide-prd`(dc07dd36-71ed-4355-8c70-0a753a948c63)**(테넌트 `skinc-aide` /
  `taidesk.onmicrosoft.com`)로 확정. 각 환경 `providers.tf`에 `subscription_id`/`tenant_id`
  를 명시해 az cli의 현재 활성 구독과 무관하게 항상 올바른 구독을 타겟하도록 함.
- `environments/cicd`의 SP 권한을 내장 역할 `AcrPush`에서, 참고 프로젝트(skbax)가 쓰던
  **`full-admin-acr` 커스텀 역할**(ACR 관리 전반 113개 액션)을 그대로 재현한
  `azurerm_role_definition`으로 교체. dev/prd가 서로 다른 구독이라 `azurerm.dev`/
  `azurerm.prd` provider alias를 나눠 각 리소스그룹에 role assignment를 생성하고, 역할
  정의 자체는 `assignable_scopes`에 두 구독을 모두 넣어 하나로 공유.
- fmt/init/validate 통과. `terraform plan`은 현재 로그인된 az cli 계정이 `mySUNI` 테넌트
  세션이라 `skinc-aide` 테넌트 리소스에 접근 못 해 인증 에러로 중단됨(MFA 필요, 대화형 로그인
  필요 — `az login --tenant 06c7ea6f-b5db-4ca2-a0fe-e1d59620e937`) — 문법/로직은 검증됐고
  실제 apply 전 사용자가 직접 로그인해야 함.

## 2026-08-31 — 개발자 전달용 엔드포인트 output 추가 + ACR 데이터 엔드포인트 활성화

`04. 리소스 구성 내역` 시트의 Azure 엔드포인트 표(AOAI 3종 + ACR 로그인서버/데이터 엔드포인트,
dev/prd)를 배포 후 바로 전달할 수 있도록 `environments/aiden-dev`, `environments/aiden-prd`에
`outputs.tf`를 추가함 (`aoai_openai_endpoint`, `aoai_cognitiveservices_endpoint`,
`aoai_services_ai_endpoint`, `acr_login_server_endpoint`, `acr_data_endpoints`).

시트에 있던 `<registry>.<region>.data.azurecr.io`(ACR 지역별 전용 데이터 엔드포인트)가 기존
코드에서는 비활성화 상태(`data_endpoint_enabled` 기본값 false)라 실제로 존재하지 않았음 —
사용자 확인 후 `modules/containerregistry`의 기본값을 `true`로 변경해 실제로 생성되도록 함
(Premium SKU 필요, 이미 Premium 사용 중이라 문제 없음).

fmt/init/validate 통과(dev/prd 모두). `terraform plan`은 이전과 동일하게 skinc-aide 테넌트
로그인이 안 된 상태라 인증 에러로 중단됨 — 코드 자체는 유효함.

## 2026-08-31 — 방화벽 신청용 Private Endpoint IP-FQDN 매핑 output 추가

사용자가 참고 프로젝트(audit-d-msf-pe, auditdevcr)의 "DNS 구성" 화면을 첨부하며 Private
Endpoint의 IP-FQDN 매핑 정보가 필요하다고 함(방화벽 신청용). 확인 결과 DNS Private Zone 구조
(ACR은 zone 1개로 로그인서버·데이터 엔드포인트 두 FQDN을 모두 커버, Foundry는 zone 3개)는
기존 코드와 이미 일치해 변경 불필요. ACR PE 리소스 이름은 `-pe` 접미사 유지로 확정(질문 결과).

`modules/privateendpoint`에 `dns_configs` output(`azurerm_private_endpoint.custom_dns_configs`,
`{fqdn, ip_addresses}` 목록)을 추가하고, `environments/aiden-dev`/`aiden-prd`에
`firewall_endpoints` output(Foundry PE + ACR PE dns_configs를 합친 목록)을 추가함 — 배포 후
`terraform output -json firewall_endpoints`로 방화벽 신청에 필요한 실제 사설 IP를 바로 확인
가능. fmt/init/validate 통과.

## 2026-08-31 — VNet/Subnet CIDR 확정 (10.70.254.0/27 대역)

사내 IP 관리 시트 기준으로 VNet 주소 공간을 확정함. VNet peering(허브 VNet 연결)은 이번
범위에서 명시적으로 제외(추후 별도 작업).

| 리소스 | 변경 전 | 변경 후 |
|---|---|---|
| aiden-d-vnet | 10.160.0.0/24 | 10.70.254.0/27 |
| aiden-pe-d-snet | 10.160.0.0/25 | 10.70.254.0/27 |
| aiden-p-vnet | 10.161.0.0/24 | 10.70.254.32/27 |
| aiden-pe-p-snet | 10.161.0.0/25 | 10.70.254.32/27 |

az login(`--tenant 06c7ea6f-b5db-4ca2-a0fe-e1d59620e937`) 완료 후 처음으로 `terraform plan`이
정상적으로 끝까지 수행됨 — aiden-dev/aiden-prd 각각 21개 리소스 추가 예정, 삭제/변경 없음.
아직 apply는 하지 않음(사용자가 배포 직전 일시 중단 요청).

## 2026-08-31 — 프로젝트 네이밍 `aiden` → `aide`로 되돌림

사용자 요청으로 프로젝트 닉네임/리소스 프리픽스를 `aiden`에서 **`aide`**로 다시 변경함 (폴더명,
Azure 리소스 이름 문자열, owner 태그, README, `environments/cicd`). 공교롭게도 이 이름은 실제
배포 대상 구독 이름(`aide-dev`/`aide-prd`)과도 정확히 일치하게 됨. 이전 절들의 `aiden-*` 기록은
그대로 보존하며, 이후 재배포 시에는 `aide-*` 이름으로 생성됨:

| 리소스 | 변경 전 (aiden) | 변경 후 (aide) |
|---|---|---|
| 환경 폴더 | `environments/aiden-dev`, `environments/aiden-prd` | `environments/aide-dev`, `environments/aide-prd` |
| Resource Group | `aiden-ai-dev-rg` / `aiden-ai-prd-rg` | `aide-ai-dev-rg` / `aide-ai-prd-rg` |
| AI Foundry | `aiden-d-msf` / `aiden-p-msf` | `aide-d-msf` / `aide-p-msf` |
| Foundry Project | `aiden-{d,p}-msf-aidenagent` | `aide-{d,p}-msf-aideagent` |
| Container Registry | `aidendevcr` / `aidenprdcr` | `aidedevcr` / `aideprdcr` |
| CI/CD SP | `aidencr-sp` | `aidecr-sp` |
| owner 태그 | `tm agent (aiden)` | `tm agent (aide)` |

fmt/init/validate 통과(aide-dev, aide-prd, cicd 모두). 아직 미해결 상태로 남아있는 것:
- `modules/foundry`의 Foundry Project 생성 시 `allowProjectManagement` 관련 설정 누락 버그
  (직전 aiden-dev apply에서 발견, 아직 미수정)
- text-embedding-3-large capacity(12003)가 이 구독의 quota 한도(10000)를 초과하는 문제
  (아직 미해결)

두 문제 모두 이번 rename 작업 범위 밖이라 손대지 않음.

## 2026-08-31 — 미해결 이슈 2건 수정 (Foundry Project 버그, embedding quota)

지난 aiden-dev(현 aide-dev) apply에서 발견된 두 가지 문제를 모두 수정함.

1. **Foundry Project 생성 버그**: `azurerm_cognitive_account`에 `project_management_enabled
   = var.project_name != null`를 추가했더니 "a managed identity must be assigned" 에러가
   추가로 발생 — 계정 자체에도 System-Assigned Identity가 있어야 함을 확인하고,
   `project_name`이 지정된 경우에만 `identity { type = "SystemAssigned" }` 블록을 동적으로
   추가하도록 `modules/foundry`를 수정함.
2. **text-embedding-3-large quota 초과**: `aide-dev`/`aide-prd` 구독의 EastUS2 quota를
   재조회한 결과, 두 구독 모두 5개 모델 quota 한도가 **10000**으로 확인됨(직전 mySUNI
   구독의 1000/100과는 다름). dev의 원래 목표 capacity 중 text-embedding-3-large(12003)만
   유일하게 10000을 초과해 10000으로 낮춤. 나머지 4개 모델(dev) + prd 5개 모델은 모두 원래
   목표값이 10000 이내라 변경 없음.

fmt/init/validate/plan 통과 — aide-dev 21개, aide-prd 21개 리소스 생성 예정(변경/삭제 없음).
이제 재배포 시 이 두 문제로 인한 실패는 없을 것으로 예상.

## 2026-08-31 — aide-dev 배포 성공 (21/21) + firewall_endpoints 버그 수정

`aide-dev`를 구독 `aide-dev`(3c71accf-dcb0-4a1d-8c8b-8e363c06a8bb)에 재배포 시도 → **21/21
리소스 전부 성공** (RG/VNet/Subnet/DNS 4개+Link 4개/Foundry 계정+Foundry Project
`aide-d-msf-aideagent`+모델 5개(전부 성공, embedding capacity 10000 포함)/Foundry PE/
ACR(`aidedevcr`)+PE). 직전에 수정한 Foundry Project 버그, embedding quota 조정이 모두
실제로 통했음을 확인.

배포 직후 `firewall_endpoints` output이 빈 배열로 나오는 문제 발견 — `azurerm_private_endpoint`의
`custom_dns_configs`는 `private_dns_zone_group`을 쓰는 구성(우리 프로젝트 전부 해당)에서는
항상 비어있고, 실제 IP-FQDN 레코드는 `private_dns_zone_configs[].record_sets[]`에 생성된다는
것을 `az network private-endpoint dns-zone-group list`로 확인. `modules/privateendpoint`의
`dns_configs` output을 이 필드를 평탄화하는 방식으로 수정 → 재확인 결과 정상적으로 5개
FQDN-IP 쌍 모두 출력됨(Foundry 3개, ACR 2개).

**aide-dev 방화벽 신청용 정보**:
| FQDN | IP |
|---|---|
| aide-d-msf.privatelink.cognitiveservices.azure.com | 10.70.254.4 |
| aide-d-msf.privatelink.openai.azure.com | 10.70.254.5 |
| aide-d-msf.privatelink.services.ai.azure.com | 10.70.254.6 |
| aidedevcr.koreacentral.data.privatelink.azurecr.io | 10.70.254.7 |
| aidedevcr.privatelink.azurecr.io | 10.70.254.8 |

`aide-prd`도 이어서 apply 진행 중.

## 2026-08-31 — aide-prd 배포 성공 + environments/cicd(SP) 배포 성공 — 전체 완료

`aide-prd`를 구독 `aide-prd`(dc07dd36-71ed-4355-8c70-0a753a948c63)에 배포 → **21/21 성공**
(aide-dev와 동일 구성, embedding capacity는 원래 목표값 1964 그대로 정상 배포됨 — quota 문제
없었음).

**aide-prd 방화벽 신청용 정보**:
| FQDN | IP |
|---|---|
| aide-p-msf.privatelink.cognitiveservices.azure.com | 10.70.254.36 |
| aide-p-msf.privatelink.openai.azure.com | 10.70.254.37 |
| aide-p-msf.privatelink.services.ai.azure.com | 10.70.254.38 |
| aideprdcr.koreacentral.data.privatelink.azurecr.io | 10.70.254.39 |
| aideprdcr.privatelink.azurecr.io | 10.70.254.40 |

이어서 `environments/cicd` 배포 → **7/7 성공** (Entra ID App/SP `aidecr-sp`, 클라이언트 시크릿,
커스텀 role `full-admin-acr`, dev/prd 양쪽 RG에 role assignment). `az role assignment list`로
두 RG(`aide-ai-dev-rg`, `aide-ai-prd-rg`) 모두에 정상 할당된 것을 확인.

**CI/CD SP 자격증명** (개발자 전달 완료, secret은 대화 중 1회만 노출 — 안전한 곳에 보관 요청):
- appid: `80e3ee66-dda2-47a4-bc26-d0e02ffb1234`
- tenantid: `06c7ea6f-b5db-4ca2-a0fe-e1d59620e937`

**결론: 2026-08-31 기준 aide-dev/aide-prd/cicd 3개 환경 전부 정상 배포 완료.**

## 2026-08-31 — CI/CD role assignment 범위를 RG → 구독 단위로 변경

배포 후 Azure Portal에서 확인해보니 사용자가 원했던 건 참고 프로젝트(skbax)처럼 **구독
단위**(상속됨) 할당이었는데, 실제로는 RG 단위로 붙어있었음. `environments/cicd`의
`azurerm_role_assignment.acr_admin_dev`/`acr_admin_prd`의 `scope`를 각 리소스그룹 ID에서
구독 ID(`/subscriptions/<id>`)로 변경 — `data "azurerm_resource_group"` 조회도 더 이상
필요 없어져 제거함. `scope`는 role assignment의 ForceNew 속성이라 Terraform이 자동으로
replace(삭제 후 재생성) 처리 — SP/시크릿/역할 정의는 영향 없음.

재적용 후 `az role assignment list`로 두 구독(`aide-dev`, `aide-prd`) 모두 스코프가
`/subscriptions/<id>`(구독 전체)로 정상 반영된 것을 확인.

## 2026-09-02 — Foundry 방화벽(network_acls) IaC drift 수정

배포 후 Azure Portal에서 수동으로 aide-d-msf/aide-p-msf의 네트워킹 설정을 "선택한 네트워크"로
바꾸고 회사 NAT IP(`211.45.60.0/29`)만 허용하도록 방화벽을 강화했는데, 이 설정이 Terraform
코드에는 없어서 `terraform plan`을 돌려보니 다음 apply 시 이 방화벽이 삭제되고 다시 전체
네트워크에 열리는 drift가 확인됨(`az cognitiveservices account show`로 실제 설정
`defaultAction=Deny, bypass=AzureServices, ipRules=[211.45.60.0/29]` 확인).

`modules/foundry`에 `firewall_allowed_ip_rules` 변수를 추가하고, 값이 있을 때만
`network_acls` 블록을 동적으로 생성하도록 수정. `aide-dev`/`aide-prd` 양쪽에
`firewall_allowed_ip_rules = ["211.45.60.0/29"]`를 설정.

재검증 결과 aide-dev는 `terraform plan` "No changes", aide-prd는 무관한 사전 존재 drift
(각 모델 배포의 `rai_policy_name = "Microsoft.DefaultV2" -> null`, 5건) 외에는 network_acls
관련 diff 없음 — 방화벽 drift는 완전히 해소됨. `rai_policy_name` drift는 이번 작업 범위 밖이라
별도 처리하지 않음.
