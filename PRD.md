# PRD (Product Requirements Document)
## PO 단가 일괄 조정 애플리케이션 (ZEN_PO_DEMO)

---

## 1. 프로젝트 개요

### 1.1 배경 및 목적

SAP S/4 HANA 2022 (Release 757) 환경에서 구매 오더(Purchase Order)의 단가(Net Price)를 효율적으로 조회하고 수정하기 위한 Fiori Elements 기반의 RAP(ABAP RESTful Application Programming) 애플리케이션이다.

기존 SAP 표준 트랜잭션(ME22N 등)은 PO 단건 수정만 지원하여, 다수의 PO 아이템 단가를 일괄 변경하는 업무에 비효율이 발생하였다. 본 애플리케이션은 퍼센트(%) 기반의 일괄 단가 조정 및 미리보기(Preview) 기능을 제공하여 구매 담당자의 업무 효율을 높이는 것을 목적으로 한다.

### 1.2 개발 환경

| 항목 | 내용 |
|------|------|
| 플랫폼 | SAP S/4 HANA 2022 (Release 757) |
| 개발 방식 | ABAP RAP (RESTful Application Programming Model) |
| UI 프레임워크 | SAP Fiori Elements (List Report + Object Page) |
| OData 버전 | OData V2 |
| 코드 관리 | abapGit |

---

## 2. 시스템 아키텍처

### 2.1 RAP 레이어 구조

본 애플리케이션은 두 가지 독립적인 RAP 스택으로 구성된다.

#### 스택 1: PO 헤더/아이템 직접 편집 (단건 수정)

```
[UI - Fiori Elements]
        ↓
ZSD_PO_PRICE_EDIT (Service Definition)
        ↓
ZC_PO_PRICE_EDIT / ZC_PO_ITEM_PRICE_EDIT (Projection Layer - BDEF)
        ↓
ZI_PO_PRICE_EDIT / ZI_PO_ITEM_PRICE_EDIT (Interface Layer - BDEF)
        ↓
I_PurchaseOrderAPI01 / I_PurchaseOrderItemAPI01 (SAP Standard CDS API)
        ↓
BAPI_PO_CHANGE (Save 처리 - Unmanaged Save)
```

#### 스택 2: PO 단가 일괄 조정 (% 기반 대량 조정)

```
[UI - Fiori Elements]
        ↓
ZS_PO_PRICE_ADJ_O4 (Service Binding - OData V4)
        ↓
ZC_PO_PRICE_ADJ_I (Projection View + BDEF Actions)
        ↓
I_PurchaseOrderItem / I_PurchaseOrder (SAP Standard CDS)
        ↓
cl_po_processing_api (Save 처리 - Managed API)
```

### 2.2 주요 오브젝트 목록

| 오브젝트 | 종류 | 역할 |
|----------|------|------|
| `ZI_PO_PRICE_EDIT` | CDS Root View Entity | PO 헤더 인터페이스 뷰 |
| `ZI_PO_ITEM_PRICE_EDIT` | CDS View Entity | PO 아이템 인터페이스 뷰 |
| `ZC_PO_PRICE_EDIT` | CDS Projection View | PO 헤더 프로젝션 뷰 |
| `ZC_PO_ITEM_PRICE_EDIT` | CDS Projection View | PO 아이템 프로젝션 뷰 |
| `ZI_PO_PRICE_EDIT` (BDEF) | Behavior Definition | 인터페이스 동작 정의 |
| `ZC_PO_PRICE_EDIT` (BDEF) | Behavior Definition | 프로젝션 동작 정의 |
| `ZBP_I_PO_PRICE_EDIT` | Behavior Pool | 단가 검증 및 저장 처리 |
| `ZC_PO_PRICE_ADJ_I` | CDS View Entity | 단가 조정 복합 뷰 |
| `ZBP_C_PO_PRICE_ADJ_I` | Behavior Pool | 단가 조정 액션 처리 |
| `ZSD_PO_PRICE_EDIT` | Service Definition | 단건 편집 서비스 정의 |
| `ZS_PO_PRICE_ADJ_O4` | Service Binding (V4) | 일괄 조정 서비스 바인딩 |
| `ZUI_PO_PRICE_EDIT_V2` | Service Binding (V2) | 단건 편집 서비스 바인딩 |
| `ZCL_TEST_PO_PRICE_ADJ` | ABAP Unit Test | 단가 조정 단위 테스트 |

---

## 3. 기능 요구사항

### 3.1 기능 1: PO 목록 조회 및 필터링

**설명**: 사용자가 조건을 입력하여 구매 오더 목록을 조회한다.

**필터 조건 (Selection Fields)**:

| 필드명 | CDS 필드 | 설명 |
|--------|----------|------|
| PO 번호 | `PurchaseOrder` | 구매 오더 번호 |
| PO 아이템 | `PurchaseOrderItem` | 구매 오더 아이템 |
| 자재 | `Material` | 자재 코드 (Value Help: I_Material) |
| 생성일 | `PurchaseOrderCreationDate` | PO 생성일 |
| 공급업체 | `Supplier` | 공급업체 코드 |
| 구매 조직 | `PurchasingOrganization` | 구매 조직 |
| 구매 그룹 | `PurchasingGroup` | 구매 그룹 |
| 문서 유형 | `PurchaseOrderType` | PO 문서 유형 |
| 납기일 | `ScheduleLineDeliveryDate` | 납품 예정일 |
| 단가 범위 | `NetPriceAmount` | 현재 단가 |

**목록 표시 컬럼**:

| 순번 | 필드 | 중요도 |
|------|------|--------|
| 10 | PO Number | HIGH |
| 20 | PO Item | HIGH |
| 30 | Material | - |
| 40 | Net Price Amount | HIGH (criticality 색상 표시) |
| 50 | PO Creation Date | - |
| 60 | Supplier | - |
| 70 | Purchasing Organization | - |
| 80 | Purchasing Group | - |
| 90 | Document Type | - |
| 100 | Delivery Date | - |

**Semantic Navigation**:
- PO Number → `PurchaseOrder` 시맨틱 오브젝트 (display 액션)
- Supplier → `Supplier` 시맨틱 오브젝트 (display 액션)

---

### 3.2 기능 2: PO 단가 직접 편집 (단건)

**설명**: 개별 PO 아이템의 단가를 직접 입력하여 수정한다. List Report + Object Page 패턴.

**헤더 정보 (읽기 전용)**:

| 필드 | 설명 |
|------|------|
| PurchaseOrder | PO 번호 (Key) |
| PurchaseOrderType | 문서 유형 |
| CompanyCode | 회사 코드 |
| PurchasingOrganization | 구매 조직 |
| PurchasingGroup | 구매 그룹 |
| Supplier | 공급업체 |
| DocumentCurrency | 통화 |
| PurchaseOrderDate | PO 날짜 |
| CreatedByUser | 생성자 |
| CreationDate | 생성일 |

**아이템 정보**:

| 필드 | 편집 가능 | 필수 |
|------|-----------|------|
| PurchaseOrderItem | 읽기 전용 | - |
| Material | 읽기 전용 | - |
| PurchaseOrderItemText | 읽기 전용 | - |
| Plant | 읽기 전용 | - |
| StorageLocation | 읽기 전용 | - |
| OrderQuantity | 읽기 전용 | - |
| PurchaseOrderQuantityUnit | 읽기 전용 | - |
| **NetPriceAmount** | **편집 가능** | **필수 (Mandatory)** |
| NetPriceQuantity | 읽기 전용 | - |
| OrderPriceUnit | 읽기 전용 | - |
| DocumentCurrency | 읽기 전용 | - |

**저장 처리**: `BAPI_PO_CHANGE` 호출 (Unmanaged Save)

**검증 규칙**:
- `NetPriceAmount`는 반드시 0보다 커야 한다 (`validatePrice` on save)
- 오류 메시지: "가격은 0보다 커야 합니다."

---

### 3.3 기능 3: PO 단가 일괄 % 조정

**설명**: 다수의 PO 아이템을 선택하여 퍼센트 기반으로 단가를 일괄 조정한다.

#### 3.3.1 미리보기 (previewAdjustment) 액션

**입력 파라미터**:
- `AdjustmentPercentage`: 조정 퍼센트 (양수: 인상, 음수: 인하)
- `IsTestRun`: 테스트 실행 여부

**처리 로직**:
1. 선택된(`IsSelected = 'X'`) 아이템만 처리
2. 새 단가 계산: `NewNetPrice = OldNetPrice × (1 + Percentage / 100)`
3. 소수점 2자리 반올림 처리
4. 트랜지언트 필드 업데이트:
   - `NewNetPriceAmount`: 계산된 새 단가
   - `AdjustmentPercentage`: 적용된 퍼센트
   - `AdjustmentStatus`: `'P'` (Previewed)
   - `AdjustmentMessage`: "Preview: Price will change to {새단가} {통화}"
   - `NetPriceAmountCriticality`: `2` (노란색 표시)
5. 실제 PO 데이터는 변경하지 않음

#### 3.3.2 실제 조정 (adjustPrice) 액션

**입력 파라미터**:
- `AdjustmentPercentage`: 조정 퍼센트
- `IsTestRun`: `false` (실제 저장)

**처리 로직**:
1. 선택된(`IsSelected = 'X'`) 아이템만 처리
2. 새 단가 계산 (미리보기와 동일)
3. `cl_po_processing_api→update_item()` 호출로 실제 PO 업데이트
4. 성공 시:
   - `AdjustmentStatus`: `'S'` (Success)
   - `NetPriceAmountCriticality`: `3` (녹색 표시)
   - `COMMIT ENTITIES` 실행
5. 실패 시:
   - `AdjustmentStatus`: `'E'` (Error)
   - `AdjustmentMessage`: "Error updating PO: {오류메시지}"
   - `NetPriceAmountCriticality`: `1` (빨간색 표시)
   - `ROLLBACK ENTITIES` 실행

#### 3.3.3 액션 활성화 조건

- `IsSelected = 'X'`인 아이템에서만 `adjustPrice` 및 `previewAdjustment` 액션 활성화
- 선택되지 않은 아이템에서는 두 액션 모두 비활성화 (`get_features` 처리)

---

### 3.4 기능 4: Criticality 색상 표시

단가 조정 상태에 따라 `NetPriceAmount` 컬럼에 색상을 시각적으로 표시한다.

| Criticality 값 | 색상 | 의미 |
|---------------|------|------|
| 0 | 기본 | 미처리 |
| 1 | 빨간색 | 오류 (Error) |
| 2 | 노란색 | 미리보기 (Preview) |
| 3 | 녹색 | 성공 (Success) |

---

## 4. 비기능 요구사항

### 4.1 권한 관리

- `ZI_PO_PRICE_EDIT`: `@AccessControl.authorizationCheck: #CHECK` 적용
- `ZI_PO_ITEM_PRICE_EDIT`: `@AccessControl.authorizationCheck: #CHECK` 적용
- `ZC_PO_PRICE_ADJ_I`: `@AccessControl.authorizationCheck: #NOT_REQUIRED` (조정 뷰)
- 헤더 레벨: `authorization master (global)` 설정
- 아이템 레벨: `authorization dependent by _Header` 설정
- 서비스 바인딩(`ZUI_PO_PRICE_EDIT_V2`) 접근 시 `S_SERVICE` 권한 오브젝트 검사

### 4.2 데이터 무결성

- PO 잠금: `lock master` / `lock dependent by _Header` 설정으로 동시 수정 방지
- BAPI 저장 시 `BAPI_TRANSACTION_COMMIT/ROLLBACK` 처리
- 실제 조정 실패 시 전체 롤백 (`ROLLBACK ENTITIES`)

### 4.3 테스트

`ZCL_TEST_PO_PRICE_ADJ` ABAP Unit Test 클래스 제공:

| 테스트 메서드 | 내용 |
|--------------|------|
| `test_preview_adjustment` | 10% 인상 미리보기 → 100 → 110 검증 |
| `test_adjust_price_test_run` | 5% 인상 테스트 실행 → DB 미변경 검증 |
| `test_adjust_price_actual` | -5% 인하 실제 적용 → 95 검증 |
| `test_adjust_price_not_selected` | 미선택 아이템 오류 메시지(ZCM_PO_PRICE_ADJ/001) 검증 |

테스트 데이터:
- PO: `4500000001`, Item: `00010`, Material: `MAT_TEST_01`
- 기준 단가: 100 EUR, 수량: 10 PC

---

## 5. 메시지 클래스

| 메시지 클래스 | 번호 | 내용 |
|--------------|------|------|
| `ZCM_PO_PRICE_ADJ` | 001 | 선택되지 않은 아이템 오류 |
| `ZCM_PO_PRICE_ADJ` | 002 | PO 업데이트 실패 오류 |
| `ZCM_PO_PRICE_ADJ` | 003 | PO 업데이트 정보 메시지 |

---

## 6. UI/UX 설계

### 6.1 Fiori Elements 패턴

- **List Report**: PO 아이템 목록 조회 (필터 조건 + 결과 테이블)
- **Object Page**: PO 헤더 + 아이템 Facet 구조

### 6.2 Object Page Facet 구조 (단건 편집)

```
PO Header (headerInfo: PurchaseOrder / Supplier)
  └── Facet: PO 아이템 (LineItem Reference → _Item)
```

### 6.3 Object Page Facet 구조 (일괄 조정)

```
PO Price Adjustment (Collection)
  ├── General Information (Form)
  └── Pricing Details (Form)
```

---

## 7. OData 서비스 구성

| 서비스 | 버전 | 노출 엔티티 |
|--------|------|------------|
| `ZSD_PO_PRICE_EDIT` | V2 (`ZUI_PO_PRICE_EDIT_V2`) | POHeader, POItem |
| `ZS_PO_PRICE_ADJ_O4` | V4 | POPriceAdjustment, AdjustmentParameter |

---

## 8. 트랜지언트 필드 (런타임 전용)

`ZC_PO_PRICE_ADJ_I` 뷰에서 실제 DB에 저장하지 않고 런타임에만 사용하는 계산 필드:

| 필드 | 타입 | 용도 |
|------|------|------|
| `AdjustmentStatus` | CHAR(1) | 조정 상태 (P/S/E) |
| `AdjustmentMessage` | STRING | 조정 결과 메시지 |
| `NewNetPriceAmount` | DEC(15,2) | 계산된 새 단가 |
| `AdjustmentPercentage` | DEC(15,2) | 적용 퍼센트 |
| `IsTestRun` | CHAR(1) | 테스트 실행 여부 |
| `IsSelected` | CHAR(1) | 아이템 선택 여부 |
| `NetPriceAmountCriticality` | DEC(1,0) | 색상 표시 값 (0/1/2/3) |

---

## 9. 제약 사항 및 한계

1. **테스트 더블 미구현**: `zcl_test_po_price_adj`에서 `cl_po_processing_api` 모킹이 개념적 수준으로만 구현되어 있어 완전한 단위 테스트 자동화에 한계가 있음
2. **통화 소수점 고정**: 단가 반올림 시 통화별 소수점 자릿수를 동적으로 처리하지 않고 2자리로 고정
3. **아이템 선택 메커니즘**: `IsSelected` 필드가 트랜지언트 필드로 구현되어 있어, UI에서 선택 상태를 어떻게 서버에 전달하는지에 대한 별도 구현 필요
4. **Authorization**: `ZC_PO_PRICE_ADJ_I`에 `#NOT_REQUIRED` 설정으로 권한 검사가 생략되어 있어 프로덕션 적용 전 권한 검토 필요

---

## 10. 향후 개선 사항 (제안)

| 우선순위 | 개선 내용 |
|----------|-----------|
| High | 통화별 소수점 자릿수 동적 처리 |
| High | `ZC_PO_PRICE_ADJ_I` 권한 검사 활성화 |
| Medium | ABAP Test Double Framework를 활용한 완전한 단위 테스트 구현 |
| Medium | 일괄 조정 결과 로그 테이블 및 이력 관리 |
| Low | 조정 퍼센트 범위 검증 (예: ±100% 초과 방지) |
| Low | 다중 PO 동시 잠금 처리 개선 |

---

*문서 작성일: 2026-02-19*
*대상 시스템: SAP S/4 HANA 2022 (Release 757)*
