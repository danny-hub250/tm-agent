# TM Agent (aide) Azure Terraform IaC — Session Notes

Separate Terraform IaC project for "TM Agent" (nickname **aide**), at `D:\01. 프로젝트\@46. TM Agent\02. IaC` — outside the `@47. CEO Agent\Azure` git repo (a different project folder, not currently its own git repo as of 2026-08-26). Built by copying/adapting the `ceoagent-dev` environment's module pattern but diverges in several ways.

**Structure**: `modules/` (resourcegroup, virtualnetwork, subnet, privatednszone, privatednszonelink, privateendpoint, foundry, aisearch, containerregistry) + `environments/aide-dev/` and `environments/aide-prd/`. Full rationale and current resource-name table are kept in this project's own `README.md` — read that first before assuming names, since naming has been revised multiple times in conversation (RG name, subnet name, msf/srch01 suffixes, etc.) and the README is the source of truth, not this file.

**Key conventions established via user requests (not derivable from a fresh code read alone):**
- Tags: `owner = "tm agent (aide)"`, `env = "dev"|"prd"` — exact literal casing requested by user.
- Resource naming generally abbreviates dev→d, prd→p (e.g. `aide-d-msf`, `aide-p-srch01`), **except** the Resource Group, which the user explicitly asked to keep as full `dev`/`prd`: `aide-ai-dev-rg` / `aide-ai-prd-rg`.
- Foundry resource name must end in `msf`; AI Search must end in `srch01`; Container Registry names are `aidedevcr`/`aideprdcr` (no hyphens — required by Azure ACR naming rules, and matches user's literal request).
- User's source-of-truth for the network/PE layout is a company architecture diagram (tenant `aidesk.onmicrosoft.com`) showing per-env VNet (`aide-d-vnet`/`aide-p-vnet`) with a PE subnet (`aide-pe-d-snet`/`aide-pe-p-snet`), OpenAI/AI Search/Container Registry private endpoints — this was reproduced in the IaC on request. If the user shares more of that diagram later, prefer matching it exactly over inventing new naming.
- ACR was made Premium SKU (required for Private Endpoint support); AI Search was set to `basic` SKU — both explicit user choices, not defaults.
- The `foundry` module's `model_deployments` is a map (for_each) supporting multiple OpenAI deployments per Foundry account; default `version_upgrade_option` for every deployment is `OnceCurrentVersionExpired` per user request. aide-prd's deployment capacities were later tuned from a live Azure portal screenshot (dev capacities were left at their original values — dev and prd intentionally differ).
- Foundry is pinned to region `EastUS2` (model availability) while other resources follow `var.location` (tfvars default `koreacentral`) — mirrors ceoagent-dev's pattern.

**Verification habit for this project**: after any change, run `terraform -chdir=<path> fmt -recursive` then `init -backend=false` + `validate` for both aide-dev and aide-prd, then delete the generated `.terraform/` cache dirs (keep `.terraform.lock.hcl`) — network access for provider download has been available in this sandbox.

## 진행 이력 (이번 세션)

1. `@47. CEO Agent\Azure\environments\ceoagent-dev` 구조/모듈을 참고해 `02. IaC`에 `aide-dev`/`aide-prd` 두 환경 생성 (vnet 연계·테스트 VM 제외, AI Search 신규 추가, `owner`/`env` 태그 적용).
2. 리소스 이름 축약 규칙 적용: `dev→d`, `prd→p`, Foundry는 `msf`로 끝나도록.
3. AI Search 이름을 `srch01`로 끝나도록 수정.
4. Resource Group 이름만 예외적으로 `aide-ai-dev-rg` / `aide-ai-prd-rg`(축약 없이)로 변경.
5. Foundry·AI Search 연결용 Private Endpoint 추가 요청 → 신규 VNet/Subnet 생성 방식으로 결정, `virtualnetwork`/`subnet`/`privatednszone`/`privatednszonelink`/`privateendpoint` 모듈 신설. 공유된 아키텍처 그림(tenant `aidesk.onmicrosoft.com`)의 네이밍(`aide-d-vnet`, `aide-pe-d-snet` 등)에 맞춰 서브넷 이름 정정.
6. Container Registry(`aidedevcr`/`aideprdcr`) + 연결 PE(`aidedevcr-pe`/`aideprdcr-pe`) 추가.
7. `admin_enabled` 옵션 설명 (기본값 `false` 유지, 관리자 계정 미사용 권장 이유 설명).
8. SKU 명시: Container Registry `Premium`, AI Search `basic`.
9. Foundry(`msf`)에 OpenAI 모델 다중 배포 지원 가능한지 질문 → `foundry` 모듈을 `for_each` 기반 `model_deployments` 맵으로 리팩터링(하위 호환 유지). 공유된 포털 스크린샷 그대로 5개 모델(gpt-5.5, gpt-5.6-luna, gpt-5.6-sol, gpt-5.6-terra, text-embedding-3-large)을 dev/prd 동일 값으로 추가.
10. 모델 배포 버전 업그레이드 정책을 "현재 버전이 만료되는 경우"로 요청 → `version_upgrade_option = "OnceCurrentVersionExpired"`를 기본값으로 전 배포에 적용.
11. `version_upgrade_option` 코드 위치 질문에 답변 (`modules/foundry/main.tf`, `variables.tf`).
12. aide-prd 모델 배포 용량을 새 포털 스크린샷 값(5997/2997/7993/6001/1964)으로 갱신 (aide-dev는 기존 값 유지).
13. VSCode Explorer에 `modules` 폴더가 안 보이는 이유 질문 → 워크스페이스 루트가 `environments`로 열려 있어서라고 설명, `02. IaC`를 루트로 열도록 안내.
14. 세션 요약을 메모리에 저장 → 이후 사용자 요청으로 이 파일을 Claude 내부 메모리 폴더에서 `02. IaC` 폴더로 이동(현재 파일).

앞으로 이 폴더에서 실제 배포 작업을 진행할 예정 — 새 세션에서 이어갈 때는 이 파일과 `README.md`를 함께 참고할 것.
