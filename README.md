# ZEN_PO_DEMO — PO 단가 변경 애플리케이션

SAP S/4 HANA 2022 (Release 757) 환경에서 구매 오더(Purchase Order) 아이템의 단가(Net Price)를 조회하고 수정하는 **RAP 기반 Fiori Elements 애플리케이션**입니다.

---
## 프로그램 시연

![프로그램 시연](./assets/프로그램_시연.gif)

## 개요

기존 SAP 표준 트랜잭션(ME22N)은 PO 단건 수정만 지원합니다. 이 애플리케이션은 List Report 화면에서 여러 PO 아이템을 한 번에 조회하고, 인라인 편집(Inline Edit)으로 단가를 직접 수정하여 저장할 수 있습니다.

---

## 개발 환경

| 항목 | 내용 |
|------|------|
| 플랫폼 | SAP S/4 HANA 2022 (Release 757) |
| 개발 방식 | ABAP RAP (Unmanaged) |
| UI 프레임워크 | SAP Fiori Elements (List Report) |
| OData 버전 | V2 |
| 코드 관리 | abapGit |

---

## 주요 기능

### 1. PO 아이템 목록 조회 및 필터링
- PO 번호, PO 유형, 회사 코드, 공급업체, 구매 조직, 플랜트, 자재 등 7개 조건으로 필터링
- 각 필드에 Value Help 제공 (I_PurchaseOrderAPI01, I_Supplier_VH, I_Plant, I_MaterialVH 등)

### 2. 단가 인라인 편집
- List Report에서 `NetPriceAmount` 필드를 직접 수정
- 수정된 데이터는 내부 버퍼(`lcl_buffer`)에 보관 후 저장 시 일괄 처리

### 3. BAPI 기반 저장
- 저장 시 `BAPI_PO_CHANGE`를 PO 번호별로 호출하여 실제 반영
- BAPI 오류 발생 시 RAP 오류 메시지로 사용자에게 피드백

---

## 아키텍처

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

---

## 주요 오브젝트

| 오브젝트 | 종류 | 역할 |
|----------|------|------|
| `ZR_POItemPriceDemo` | CDS Root View Entity | PO 아이템 인터페이스 뷰 (I_PurchaseOrderItemAPI01 기반) |
| `ZC_POItemPriceDemo` | CDS Projection View | UI 노출용 프로젝션 뷰 |
| `ZR_POItemPriceDemo` (BDEF) | Behavior Definition | update, action(changePrice), lock, etag 정의 |
| `ZC_POItemPriceDemo` (BDEF) | Behavior Definition | 프로젝션 동작 정의 (use update) |
| `ZBP_R_POItemPriceDemo` | Behavior Pool | update/read/lock 핸들러 및 save 구현 |
| `ZSD_PO_PRICE_DEMO_SRV` | Service Definition | ZC_POItemPriceDemo → POItemPrice 노출 |
| `ZUI_PO_PRICE_DEMO_V2` | Service Binding (V2) | OData V2 서비스 바인딩 |

---

## 데이터 모델

`ZR_POItemPriceDemo`는 `I_PurchaseOrderItemAPI01`(PO 아이템)과 `I_PurchaseOrderAPI01`(PO 헤더)를 조인하여 구성됩니다.

| 필드 | 편집 가능 여부 | 비고 |
|------|--------------|------|
| PurchaseOrder | 읽기 전용 | Key |
| PurchaseOrderItem | 읽기 전용 | Key |
| PurchaseOrderType | 읽기 전용 | 헤더 |
| CompanyCode | 읽기 전용 | 헤더 |
| PurchasingOrganization | 읽기 전용 | 헤더 |
| PurchasingGroup | 읽기 전용 | 헤더 |
| Supplier | 읽기 전용 | 헤더 |
| CreationDate | 읽기 전용 | 헤더 |
| Material | 읽기 전용 | 아이템 |
| Plant | 읽기 전용 | 아이템 |
| OrderQuantity | 읽기 전용 | 아이템 |
| PurchaseOrderQuantityUnit | 읽기 전용 | 아이템 |
| **NetPriceAmount** | **편집 가능** | 아이템 |
| DocumentCurrency | 읽기 전용 | 아이템 |
| LocalLastChangedAt | 읽기 전용 | ETag 기준 필드 |

---

## 저장 처리 흐름 (Unmanaged Save)

1. 사용자가 `NetPriceAmount` 수정 후 저장 요청
2. `update` 핸들러: 변경 데이터를 `lcl_buffer`에 적재
3. `save` 핸들러: 버퍼를 PO 번호별로 그룹화 후 `BAPI_PO_CHANGE` 호출
4. BAPI 오류 발생 시 RAP 오류 메시지 반환
5. `cleanup` 핸들러: 트랜잭션 종료 시 버퍼 초기화

---

## 설치 (abapGit)

1. SAP 시스템에서 abapGit 실행
2. 새 저장소 연결: 이 저장소 URL 입력
3. 패키지 지정 후 Pull
4. Service Binding 활성화: `ZUI_PO_PRICE_DEMO_V2`

> 자세한 기능 명세는 [PRD.md](./PRD.md)를 참고하세요.
