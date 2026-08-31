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
