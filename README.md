# ZEN_PO_DEMO — PO 단가 일괄 조정 애플리케이션

SAP S/4 HANA 2022 (Release 757) 환경에서 구매 오더(Purchase Order)의 단가를 조회·편집·일괄 조정하는 **RAP 기반 Fiori Elements 애플리케이션**입니다.

---

## 개요

기존 SAP 표준 트랜잭션(ME22N)은 PO 단건 수정만 지원합니다. 이 애플리케이션은 다수의 PO 아이템에 대해 **퍼센트(%) 기반 단가 일괄 조정**과 **미리보기(Preview)** 기능을 제공하여 구매 담당자의 업무 효율을 높입니다.

---

## 개발 환경

| 항목 | 내용 |
|------|------|
| 플랫폼 | SAP S/4 HANA 2022 (Release 757) |
| 개발 방식 | ABAP RAP (RESTful Application Programming Model) |
| UI 프레임워크 | SAP Fiori Elements |
| OData 버전 | V2 |
| 코드 관리 | abapGit |

---

## 주요 기능

### 1. PO 목록 조회 및 필터링
- PO 번호, 자재, 공급업체, 구매 조직, 납기일 등 8개 조건으로 필터링
- PO Number / Supplier 시맨틱 네비게이션 지원

### 2. PO 단가 직접 편집 (단건)
- 개별 PO 아이템의 `NetPriceAmount`(단가) 직접 수정
- 저장 시 0 초과 여부 검증 (`validatePrice`)
- `BAPI_PO_CHANGE` 호출로 실제 PO 반영

### 3. PO 단가 일괄 % 조정
- 선택된 PO 아이템에 퍼센트를 입력하여 단가 일괄 변경
- **미리보기(Preview)**: 변경 금액을 노란색으로 확인 후 저장 결정
- **실제 적용(Adjust)**: `cl_po_processing_api`를 통해 PO 업데이트
- 성공(녹색) / 오류(빨간색) 상태를 Criticality 색상으로 시각화

---

## 아키텍처

두 가지 독립적인 RAP 스택으로 구성됩니다.

```
[단건 편집 - OData V2]
ZUI_PO_PRICE_EDIT_V2 (Service Binding)
  └── ZSD_PO_PRICE_EDIT (Service Definition)
        └── ZC_PO_PRICE_EDIT / ZC_PO_ITEM_PRICE_EDIT (Projection)
              └── ZI_PO_PRICE_EDIT / ZI_PO_ITEM_PRICE_EDIT (Interface)
                    └── I_PurchaseOrderAPI01 / I_PurchaseOrderItemAPI01
                          └── BAPI_PO_CHANGE (Unmanaged Save)

[일괄 조정 - OData V4]
ZS_PO_PRICE_ADJ_O4 (Service Binding)
  └── ZC_PO_PRICE_ADJ_I (Projection + Actions)
        └── I_PurchaseOrderItem / I_PurchaseOrder
              └── cl_po_processing_api (Managed Save)
```

---

## 주요 오브젝트

| 오브젝트 | 종류 | 역할 |
|----------|------|------|
| `ZI_PO_PRICE_EDIT` | CDS Root View | PO 헤더 인터페이스 뷰 |
| `ZI_PO_ITEM_PRICE_EDIT` | CDS View | PO 아이템 인터페이스 뷰 |
| `ZC_PO_PRICE_EDIT` | CDS Projection | PO 헤더 프로젝션 뷰 |
| `ZC_PO_ITEM_PRICE_EDIT` | CDS Projection | PO 아이템 프로젝션 뷰 |
| `ZBP_I_PO_PRICE_EDIT` | Behavior Pool | 단가 검증(validatePrice) 및 BAPI 저장 |
| `ZC_PO_PRICE_ADJ_I` | CDS View + Annotations | 단가 조정 복합 뷰 |
| `ZBP_C_PO_PRICE_ADJ_I` | Behavior Pool | adjustPrice / previewAdjustment 액션 |
| `ZCL_TEST_PO_PRICE_ADJ` | ABAP Unit Test | 단가 조정 단위 테스트 |

---

## 단가 조정 로직

```
새 단가 = 현재 단가 × (1 + 조정% / 100)
소수점 2자리 반올림 적용
```

| 조정 상태 | Status 값 | 색상 |
|-----------|-----------|------|
| 미리보기 | `P` | 노란색 (Criticality 2) |
| 성공 | `S` | 녹색 (Criticality 3) |
| 오류 | `E` | 빨간색 (Criticality 1) |

---

## 테스트

`ZCL_TEST_PO_PRICE_ADJ` ABAP Unit Test 클래스가 포함되어 있습니다.

| 테스트 | 내용 |
|--------|------|
| `test_preview_adjustment` | 10% 인상 미리보기 (100 → 110) |
| `test_adjust_price_test_run` | 5% 인상 테스트 실행 - DB 미변경 확인 |
| `test_adjust_price_actual` | -5% 인하 실제 적용 (100 → 95) |
| `test_adjust_price_not_selected` | 미선택 아이템 오류 처리 확인 |

---

## 설치 (abapGit)

1. SAP 시스템에서 abapGit 실행
2. 새 저장소 연결: 이 저장소 URL 입력
3. 패키지 지정 후 Pull
4. Service Binding 활성화 (`ZUI_PO_PRICE_EDIT_V2`, `ZS_PO_PRICE_ADJ_O4`)

> 자세한 기능 명세는 [PRD.md](./PRD.md)를 참고하세요.
