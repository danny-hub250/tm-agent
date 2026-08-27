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
