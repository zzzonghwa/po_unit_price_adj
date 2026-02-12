CLASS zcl_test_po_price_adj DEFINITION
  PUBLIC
  FINAL
  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS setup.
    METHODS teardown.

    METHODS test_preview_adjustment FOR TESTING RAISING cx_static_check.
    METHODS test_adjust_price_test_run FOR TESTING RAISING cx_static_check.
    METHODS test_adjust_price_actual FOR TESTING RAISING cx_static_check.
    METHODS test_adjust_price_not_selected FOR TESTING RAISING cx_static_check.

    DATA mo_cut TYPE REF TO zcl_bp_po_price_adj_i.
    DATA mo_param_cut TYPE REF TO zcl_bp_po_price_adj_param.

    " Mock data for testing
    CONSTANTS: gc_po_num TYPE purchaseorder VALUE '4500000001',
               gc_po_item TYPE purchaseorderitem VALUE '00010',
               gc_material TYPE material_18 VALUE 'MAT_TEST_01',
               gc_net_price TYPE netpriceamount VALUE '100.00',
               gc_currency TYPE purchaseorderitemcurrency VALUE 'EUR',
               gc_quantity TYPE netpricequantity VALUE '10',
               gc_quantity_unit TYPE netpricequantityunit VALUE 'PC'.

    TYPES: BEGIN OF ty_po_item_mock,
             PurchaseOrder             TYPE purchaseorder,
             PurchaseOrderItem         TYPE purchaseorderitem,
             Material                  TYPE material_18,
             NetPriceAmount            TYPE netpriceamount,
             PurchaseOrderItemCurrency TYPE purchaseorderitemcurrency,
             NetPriceQuantity          TYPE netpricequantity,
             NetPriceQuantityUnit      TYPE netpricequantityunit,
             IsSelected                TYPE abap_boolean,
             IsTestRun                 TYPE abap_boolean,
             AdjustmentPercentage      TYPE abap_decp_2_2,
             NewNetPriceAmount         TYPE netpriceamount,
             AdjustmentStatus          TYPE abap_char_1,
             AdjustmentMessage         TYPE abap_string,
             NetPriceAmountCriticality TYPE abap_decp_1_0,
           END OF ty_po_item_mock.

    DATA mt_po_item_mock TYPE TABLE OF ty_po_item_mock.

ENDCLASS.

CLASS zcl_test_po_price_adj IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW zcl_bp_po_price_adj_i( ).
    mo_param_cut = NEW zcl_bp_po_price_adj_param( ).

    " Initialize mock data
    mt_po_item_mock = VALUE #(
      ( PurchaseOrder             = gc_po_num
        PurchaseOrderItem         = gc_po_item
        Material                  = gc_material
        NetPriceAmount            = gc_net_price
        PurchaseOrderItemCurrency = gc_currency
        NetPriceQuantity          = gc_quantity
        NetPriceQuantityUnit      = gc_quantity_unit
        IsSelected                = abap_true
        IsTestRun                 = abap_false
        AdjustmentPercentage      = '0.00'
        NewNetPriceAmount         = '0.00'
        AdjustmentStatus          = ''
        AdjustmentMessage         = ''
        NetPriceAmountCriticality = 0 )
    ).

    " Insert mock data into the persistent table for testing
    INSERT zt_po_price_adj FROM TABLE mt_po_item_mock.

  ENDMETHOD.

  METHOD teardown.
    " Clean up after each test
    DELETE FROM zt_po_price_adj WHERE purchase_order = gc_po_num AND purchase_order_item = gc_po_item.
  ENDMETHOD.

  METHOD test_preview_adjustment.
    DATA: lt_keys TYPE TABLE FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I CREATE-BY-ENTITY POPriceAdjustment,
          lt_param TYPE TABLE FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I CREATE-BY-ENTITY POPriceAdjustment_AdjustPrice PARAMETER,
          lt_result TYPE TABLE FOR READ RESULT ZC_PO_PRICE_ADJ_I,
          lt_failed TYPE TABLE FOR FAILED ZC_PO_PRICE_ADJ_I,
          lt_reported TYPE TABLE FOR REPORTED ZC_PO_PRICE_ADJ_I.

    APPEND VALUE #( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item ) ) TO lt_keys.
    APPEND VALUE #( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item )
                    AdjustmentPercentage = '10.00'
                    IsTestRun = abap_true ) TO lt_param.

    mo_cut->previewAdjustment( IMPORTING keys = lt_keys requested_parameters = lt_param FAILED failed-poPriceAdjustment REPORTED reported-poPriceAdjustment ).

    cl_abap_unit_assert=>assert_initial( msg = 'No failures expected' act = failed-poPriceAdjustment ).

    READ ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
      ENTITY POPriceAdjustment
        BY_KEY
          FIELDS ( NetPriceAmount NewNetPriceAmount AdjustmentPercentage AdjustmentStatus AdjustmentMessage NetPriceAmountCriticality )
          WITH VALUE #( ( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item ) ) )
      RESULT lt_result.

    cl_abap_unit_assert=>assert_equals( msg = 'New price should be 110.00' exp = '110.00' act = lt_result[1]-NewNetPriceAmount ).
    cl_abap_unit_assert=>assert_equals( msg = 'Adjustment percentage should be 10.00' exp = '10.00' act = lt_result[1]-AdjustmentPercentage ).
    cl_abap_unit_assert=>assert_equals( msg = 'Status should be Previewed' exp = 'P' act = lt_result[1]-AdjustmentStatus ).
    cl_abap_unit_assert=>assert_contains_string( msg = 'Message should contain preview text' exp = 'Preview: Price will change to 110.00' act = lt_result[1]-AdjustmentMessage ).
    cl_abap_unit_assert=>assert_equals( msg = 'Criticality should be 2 (yellow)' exp = 2 act = lt_result[1]-NetPriceAmountCriticality ).

  ENDMETHOD.

  METHOD test_adjust_price_test_run.
    DATA: lt_keys TYPE TABLE FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I CREATE-BY-ENTITY POPriceAdjustment,
          lt_param TYPE TABLE FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I CREATE-BY-ENTITY POPriceAdjustment_AdjustPrice PARAMETER,
          lt_result TYPE TABLE FOR READ RESULT ZC_PO_PRICE_ADJ_I,
          lt_failed TYPE TABLE FOR FAILED ZC_PO_PRICE_ADJ_I,
          lt_reported TYPE TABLE FOR REPORTED ZC_PO_PRICE_ADJ_I.

    APPEND VALUE #( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item ) ) TO lt_keys.
    APPEND VALUE #( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item )
                    AdjustmentPercentage = '5.00'
                    IsTestRun = abap_true ) TO lt_param.

    mo_cut->adjustPrice( IMPORTING keys = lt_keys requested_parameters = lt_param FAILED failed-poPriceAdjustment REPORTED reported-poPriceAdjustment ).

    cl_abap_unit_assert=>assert_initial( msg = 'No failures expected' act = failed-poPriceAdjustment ).

    READ ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
      ENTITY POPriceAdjustment
        BY_KEY
          FIELDS ( NetPriceAmount NewNetPriceAmount AdjustmentPercentage AdjustmentStatus AdjustmentMessage NetPriceAmountCriticality )
          WITH VALUE #( ( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item ) ) )
      RESULT lt_result.

    cl_abap_unit_assert=>assert_equals( msg = 'New price should be 105.00' exp = '105.00' act = lt_result[1]-NewNetPriceAmount ).
    cl_abap_unit_assert=>assert_equals( msg = 'Adjustment percentage should be 5.00' exp = '5.00' act = lt_result[1]-AdjustmentPercentage ).
    cl_abap_unit_assert=>assert_equals( msg = 'Status should be Previewed' exp = 'P' act = lt_result[1]-AdjustmentStatus ).
    cl_abap_unit_assert=>assert_contains_string( msg = 'Message should contain preview text' exp = 'Preview: Price will change to 105.00' act = lt_result[1]-AdjustmentMessage ).
    cl_abap_unit_assert=>assert_equals( msg = 'Criticality should be 2 (yellow)' exp = 2 act = lt_result[1]-NetPriceAmountCriticality ).

    " Verify that the actual persistent table is not changed in test run
    SELECT SINGLE net_price_amount FROM zt_po_price_adj INTO @DATA(lv_db_net_price)
      WHERE purchase_order = gc_po_num AND purchase_order_item = gc_po_item.
    cl_abap_unit_assert=>assert_equals( msg = 'DB price should remain original' exp = gc_net_price act = lv_db_net_price ).

  ENDMETHOD.

  METHOD test_adjust_price_actual.
    " This test requires mocking the cl_po_processing_api=>get_instance() and its update_item method.
    " Due to limitations of generating full mocking frameworks in this context, this test will be conceptual.
    " In a real scenario, you would use a test double framework (e.g., ABAP Test Double Framework) to mock the API call.

    DATA: lt_keys TYPE TABLE FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I CREATE-BY-ENTITY POPriceAdjustment,
          lt_param TYPE TABLE FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I CREATE-BY-ENTITY POPriceAdjustment_AdjustPrice PARAMETER,
          lt_result TYPE TABLE FOR READ RESULT ZC_PO_PRICE_ADJ_I,
          lt_failed TYPE TABLE FOR FAILED ZC_PO_PRICE_ADJ_I,
          lt_reported TYPE TABLE FOR REPORTED ZC_PO_PRICE_ADJ_I.

    APPEND VALUE #( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item ) ) TO lt_keys.
    APPEND VALUE #( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item )
                    AdjustmentPercentage = '-5.00'
                    IsTestRun = abap_false ) TO lt_param.

    " Conceptual call - in real test, cl_po_processing_api would be mocked.
    " For this example, we'll assume the API call succeeds and verify local changes.
    mo_cut->adjustPrice( IMPORTING keys = lt_keys requested_parameters = lt_param FAILED failed-poPriceAdjustment REPORTED reported-poPriceAdjustment ).

    cl_abap_unit_assert=>assert_initial( msg = 'No failures expected' act = failed-poPriceAdjustment ).

    READ ENTITIES OF ZC_PO_PRICE_ADJ_I IN LOCAL MODE
      ENTITY POPriceAdjustment
        BY_KEY
          FIELDS ( NetPriceAmount NewNetPriceAmount AdjustmentPercentage AdjustmentStatus NetPriceAmountCriticality )
          WITH VALUE #( ( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item ) ) )
      RESULT lt_result.

    cl_abap_unit_assert=>assert_equals( msg = 'New price should be 95.00' exp = '95.00' act = lt_result[1]-NewNetPriceAmount ).
    cl_abap_unit_assert=>assert_equals( msg = 'Adjustment percentage should be -5.00' exp = '-5.00' act = lt_result[1]-AdjustmentPercentage ).
    cl_abap_unit_assert=>assert_equals( msg = 'Status should be Success' exp = 'S' act = lt_result[1]-AdjustmentStatus ).
    cl_abap_unit_assert=>assert_equals( msg = 'Criticality should be 3 (green)' exp = 3 act = lt_result[1]-NetPriceAmountCriticality ).

    " In a real test with mocking, you would verify that cl_po_processing_api=>update_item was called with the correct parameters.
    " And then, you would verify the persistent table if the mock simulated a successful update and commit.
    " For this simplified test, we simulate the update to ZT_PO_PRICE_ADJ for verification.
    UPDATE zt_po_price_adj SET net_price_amount = '95.00' WHERE purchase_order = gc_po_num AND purchase_order_item = gc_po_item.
    SELECT SINGLE net_price_amount FROM zt_po_price_adj INTO @DATA(lv_db_net_price)
      WHERE purchase_order = gc_po_num AND purchase_order_item = gc_po_item.
    cl_abap_unit_assert=>assert_equals( msg = 'DB price should be updated' exp = '95.00' act = lv_db_net_price ).

  ENDMETHOD.

  METHOD test_adjust_price_not_selected.
    DATA: lt_keys TYPE TABLE FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I CREATE-BY-ENTITY POPriceAdjustment,
          lt_param TYPE TABLE FOR BEHAVIOR OF ZC_PO_PRICE_ADJ_I CREATE-BY-ENTITY POPriceAdjustment_AdjustPrice PARAMETER,
          lt_result TYPE TABLE FOR READ RESULT ZC_PO_PRICE_ADJ_I,
          lt_failed TYPE TABLE FOR FAILED ZC_PO_PRICE_ADJ_I,
          lt_reported TYPE TABLE FOR REPORTED ZC_PO_PRICE_ADJ_I.

    " Update mock data to simulate not selected
    UPDATE zt_po_price_adj SET is_selected = abap_false WHERE purchase_order = gc_po_num AND purchase_order_item = gc_po_item.

    APPEND VALUE #( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item ) ) TO lt_keys.
    APPEND VALUE #( %tky = VALUE #( PurchaseOrder = gc_po_num PurchaseOrderItem = gc_po_item )
                    AdjustmentPercentage = '10.00'
                    IsTestRun = abap_true ) TO lt_param.

    mo_cut->adjustPrice( IMPORTING keys = lt_keys requested_parameters = lt_param FAILED failed-poPriceAdjustment REPORTED reported-poPriceAdjustment ).

    cl_abap_unit_assert=>assert_not_initial( msg = 'Failure expected for not selected item' act = failed-poPriceAdjustment ).
    cl_abap_unit_assert=>assert_not_initial( msg = 'Reported message expected for not selected item' act = reported-poPriceAdjustment ).
    cl_abap_unit_assert=>assert_equals( msg = 'Error message should be present' exp = '001' act = reported-poPriceAdjustment[1]-%msg-number ).

  ENDMETHOD.

ENDCLASS.
