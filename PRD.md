# PRD (Product Requirements Document)
## PO 단가 변경 애플리케이션 (ZEN_PO_DEMO)

---

## 1. 프로젝트 개요

### 1.1 배경 및 목적

SAP S/4 HANA 2022 (Release 757) 환경에서 구매 오더(Purchase Order) 아이템의 단가(Net Price)를 효율적으로 조회하고 수정하기 위한 Fiori Elements 기반의 RAP(ABAP RESTful Application Programming Model) 애플리케이션이다.

기존 SAP 표준 트랜잭션(ME22N)은 PO 단건 수정만 지원하여 다수의 PO 아이템 단가를 변경할 때 반복 작업이 필요하다. 본 애플리케이션은 List Report 화면에서 다수의 PO 아이템을 한 번에 조회하고 인라인 편집으로 단가를 수정하여 구매 담당자의 업무 효율을 높이는 것을 목적으로 한다.

### 1.2 개발 환경

| 항목 | 내용 |
|------|------|
| 플랫폼 | SAP S/4 HANA 2022 (Release 757) |
| 개발 방식 | ABAP RAP (Unmanaged) |
| UI 프레임워크 | SAP Fiori Elements (List Report) |
| OData 버전 | V2 |
| 코드 관리 | abapGit |

---

## 2. 시스템 아키텍처

### 2.1 RAP 레이어 구조

```
[Fiori Elements - List Report (OData V2)]
        ↓
ZUI_PO_PRICE_DEMO_V2 (Service Binding - OData V2)
        ↓
ZSD_PO_PRICE_DEMO_SRV (Service Definition)
        ↓
ZC_POItemPriceDemo (Projection View / BDEF)
        ↓
ZR_POItemPriceDemo (Interface Root View / BDEF)
        ↓
I_PurchaseOrderItemAPI01 + I_PurchaseOrderAPI01 (SAP Standard CDS)
        ↓
ZBP_R_POItemPriceDemo (Behavior Pool - Unmanaged)
        ↓
BAPI_PO_CHANGE (Save 처리)
```

### 2.2 주요 오브젝트 목록

| 오브젝트 | 종류 | 역할 |
|----------|------|------|
| `ZR_POItemPriceDemo` | CDS Root View Entity | PO 아이템 인터페이스 뷰 |
| `ZC_POItemPriceDemo` | CDS Projection View | UI 노출용 프로젝션 뷰 |
| `ZR_POItemPriceDemo` (BDEF) | Behavior Definition | update, action(changePrice), lock, etag 정의 |
| `ZC_POItemPriceDemo` (BDEF) | Behavior Definition | 프로젝션 동작 정의 (use update) |
| `ZBP_R_POItemPriceDemo` | Behavior Pool | update/read/lock 핸들러 및 save 구현 |
| `ZSD_PO_PRICE_DEMO_SRV` | Service Definition | POItemPrice 엔티티 노출 |
| `ZUI_PO_PRICE_DEMO_V2` | Service Binding (V2) | OData V2 서비스 바인딩 |

---

## 3. 기능 요구사항

### 3.1 기능 1: PO 아이템 목록 조회 및 필터링

**설명**: 사용자가 조건을 입력하여 구매 오더 아이템 목록을 조회한다.

**필터 조건 (Selection Fields)**:

| 순번 | 필드 | CDS 필드 | Value Help |
|------|------|----------|------------|
| 10 | PO 번호 | `PurchaseOrder` | I_PurchaseOrderAPI01 |
| 20 | PO 유형 | `PurchaseOrderType` | I_PurchaseOrderType |
| 30 | 회사 코드 | `CompanyCode` | I_CompanyCode |
| 40 | 공급업체 | `Supplier` | I_Supplier_VH |
| 50 | 구매 조직 | `PurchasingOrganization` | I_PurchasingOrganization |
| 60 | 플랜트 | `Plant` | I_Plant |
| 70 | 자재 | `Material` | I_MaterialVH |

**목록 표시 컬럼**:

| 순번 | 필드 | 레이블 | 중요도 |
|------|------|--------|--------|
| 10 | PurchaseOrder | Purchase Order | HIGH |
| 20 | PurchaseOrderItem | Item | HIGH |
| 30 | PurchaseOrderType | PO Type | - |
| 40 | CompanyCode | Company Code | - |
| 50 | Supplier | Supplier | - |
| 60 | Material | Material | - |
| 70 | PurchaseOrderItemText | Material Description | - |
| 80 | Plant | Plant | - |
| 90 | OrderQuantity | Order Quantity | - |
| 100 | PurchaseOrderQuantityUnit | Unit | - |
| 110 | **NetPriceAmount** | **Net Price** | **HIGH** |
| 120 | DocumentCurrency | Currency | - |

---

### 3.2 기능 2: 단가 인라인 편집

**설명**: List Report에서 `NetPriceAmount` 필드를 직접 수정한다.

| 필드 | 편집 가능 여부 | 비고 |
|------|--------------|------|
| PurchaseOrder | 읽기 전용 | Key |
| PurchaseOrderItem | 읽기 전용 | Key |
| PurchaseOrderType | 읽기 전용 | 헤더 데이터 |
| CompanyCode | 읽기 전용 | 헤더 데이터 |
| PurchasingOrganization | 읽기 전용 | 헤더 데이터 |
| PurchasingGroup | 읽기 전용 | 헤더 데이터 |
| Supplier | 읽기 전용 | 헤더 데이터 |
| CreationDate | 읽기 전용 | 헤더 데이터 |
| Material | 읽기 전용 | 아이템 데이터 |
| Plant | 읽기 전용 | 아이템 데이터 |
| OrderQuantity | 읽기 전용 | 아이템 데이터 |
| PurchaseOrderQuantityUnit | 읽기 전용 | 아이템 데이터 |
| AccountAssignmentCategory | 읽기 전용 | 아이템 데이터 |
| **NetPriceAmount** | **편집 가능** | 유일한 편집 대상 |
| DocumentCurrency | 읽기 전용 | 아이템 데이터 |
| LocalLastChangedAt | 읽기 전용 | ETag 기준 필드 |

**동시성 제어**: `LocalLastChangedAt`(PO 헤더의 `LastChangeDateTime`)을 ETag로 사용하여 동시 수정 충돌 방지

---

### 3.3 기능 3: BAPI 기반 저장 (Unmanaged Save)

**설명**: 수정된 단가 데이터를 `BAPI_PO_CHANGE`를 통해 실제 PO에 반영한다.

**저장 처리 흐름**:

1. 사용자가 `NetPriceAmount` 수정 후 저장 요청
2. `update` 핸들러: 변경 데이터(PO 번호, 아이템, 단가, 통화)를 `lcl_buffer`에 적재
3. `save` 핸들러:
   - 버퍼 데이터를 PO 번호별로 그룹화
   - PO별로 `BAPI_PO_CHANGE` 호출 (`no_price_from_po = abap_true` 설정)
   - BAPI 오류(타입 A/E/X) 발생 시 RAP 오류 메시지(`reported`) 반환
4. `cleanup` 핸들러: 트랜잭션 종료 시 `lcl_buffer` 초기화

**BAPI 호출 주요 파라미터**:

| 파라미터 | 값 | 비고 |
|----------|---|------|
| PURCHASEORDER | PO 번호 | 필수 |
| POHEADER-CURRENCY | DocumentCurrency | 통화 코드 |
| POITEM-PO_ITEM | PurchaseOrderItem | 아이템 번호 |
| POITEM-NET_PRICE | NetPriceAmount | 변경할 단가 |
| POITEMX-NET_PRICE | `abap_true` | 변경 플래그 |
| NO_PRICE_FROM_PO | `abap_true` | 기존 단가 덮어쓰기 방지 |

---

### 3.4 기능 4: changePrice 액션

`action (features: instance) changePrice result [1] $self`로 BDEF에 정의된 액션이다.

- `get_instance_features` 핸들러에서 모든 아이템에 대해 `%features-%update = if_abap_behv=>fc-o-enabled` 설정
- 현재 모든 아이템이 편집 가능 상태로 설정되어 있음

---

## 4. 비기능 요구사항

### 4.1 권한 관리

- `ZR_POItemPriceDemo`: `@AccessControl.authorizationCheck: #CHECK` 적용
- `ZC_POItemPriceDemo`: `@AccessControl.authorizationCheck: #CHECK` 적용
- 헤더 레벨: `authorization master (global)` 설정
- `get_global_authorizations` 핸들러 구현 (현재 빈 구현 → 운영 전 검토 필요)

### 4.2 데이터 무결성

- ETag(`LocalLastChangedAt`) 기반 낙관적 잠금(Optimistic Lock)으로 동시 수정 충돌 방지
- `lock master` 설정으로 RAP 표준 잠금 적용
- BAPI 호출 오류 시 RAP 프레임워크의 롤백 메커니즘으로 데이터 무결성 유지

### 4.3 성능

- 버퍼(`lcl_buffer`) 패턴으로 update 단계에서 DB 접근 없이 메모리에 변경사항 적재
- save 단계에서 PO 번호별 그룹화 후 BAPI를 PO 단위로 호출하여 호출 횟수 최소화

---

## 5. UI/UX 설계

### 5.1 Fiori Elements 패턴

- **List Report**: PO 아이템 목록 조회 + 인라인 편집 (단일 화면 구성)

### 5.2 화면 구성

```
┌─────────────────────────────────────────────────────┐
│  Filter Bar                                         │
│  [PO 번호] [PO 유형] [회사 코드] [공급업체]            │
│  [구매 조직] [플랜트] [자재]            [Go]          │
├─────────────────────────────────────────────────────┤
│  List Report Table                                  │
│  PO | Item | Type | Supplier | Material | Plant     │
│  | Qty | Unit | Net Price (편집 가능) | Currency    │
├─────────────────────────────────────────────────────┤
│                          [Save]  [Discard]          │
└─────────────────────────────────────────────────────┘
```

### 5.3 Object Page Identification Facet

```
ZC_POItemPriceDemo Object Page
  └── Facet: PO Item (IDENTIFICATION_REFERENCE)
        - PurchaseOrder
        - Plant
        - NetPriceAmount
```

---

## 6. OData 서비스 구성

| 항목 | 내용 |
|------|------|
| Service Definition | `ZSD_PO_PRICE_DEMO_SRV` |
| 노출 엔티티 | `ZC_POItemPriceDemo` → `POItemPrice` |
| Service Binding | `ZUI_PO_PRICE_DEMO_V2` |
| OData 버전 | V2 |
| 배포 상태 | Published / Binding Created |

---

## 7. 제약 사항 및 한계

1. **권한 미구현**: `get_global_authorizations` 핸들러가 빈 구현으로 되어 있어 운영 적용 전 권한 로직 추가 필요
2. **단가 단독 편집**: `NetPriceAmount` 한 필드만 편집 가능하며 수량 등 다른 필드 변경 불가
3. **입력 검증 미구현**: 단가 입력값에 대한 서버 사이드 검증(0 초과 여부 등)이 구현되어 있지 않음
4. **lock 미구현**: `lock` 핸들러가 빈 구현으로 되어 있어 실질적인 DB 잠금이 동작하지 않음

---

## 8. 향후 개선 사항 (제안)

| 우선순위 | 개선 내용 |
|----------|-----------|
| High | 단가 입력값 서버 사이드 검증 추가 (0 초과, 최대값 등) |
| High | `get_global_authorizations` 권한 로직 구현 |
| High | `lock` 핸들러 구현으로 실질적 잠금 처리 |
| Medium | 변경 이력 로그 테이블 구현 |
| Medium | 다수 아이템 선택 후 동일 단가 일괄 적용 기능 |
| Low | 저장 결과 성공/실패 건수 요약 메시지 표시 |

---

*문서 작성일: 2026-02-19*
*대상 시스템: SAP S/4 HANA 2022 (Release 757)*
