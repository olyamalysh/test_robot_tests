*** Settings ***
Library  openprocurement_client_helper.py


*** Keywords ***
Отримати internal id по UAid
  [Arguments]  ${username}  ${tender_uaid}
  Log  ${username}
  Log  ${tender_uaid}
  Log Many  ${ID_MAP}
  ${status}=  Run Keyword And Return Status  Dictionary Should Contain Key  ${ID_MAP}  ${tender_uaid}
  Run Keyword And Return If  ${status}  Get From Dictionary  ${ID_MAP}  ${tender_uaid}
  ${tenders}=  get_tenders  ${USERS.users['${username}'].client}
  Log Many  @{tenders}
  :FOR  ${tender}  IN  @{tenders}
  \  Set To Dictionary  ${ID_MAP}  ${tender.tenderID}  ${tender.id}
  Log Many  ${ID_MAP}
  Dictionary Should Contain Key  ${ID_MAP}  ${tender_uaid}
  Run Keyword And Return  Get From Dictionary  ${ID_MAP}  ${tender_uaid}


Підготувати клієнт для користувача
  [Arguments]  ${username}
  [Documentation]  Відкрити браузер, створити об’єкт api wrapper, тощо
  Log  ${api_host_url}
  Log  ${api_version}
  ${api_wrapper}=  prepare_api_wrapper  ${USERS.users['${username}'].api_key}  ${api_host_url}  ${api_version}
  Set To Dictionary  ${USERS.users['${username}']}  client  ${api_wrapper}
  Set To Dictionary  ${USERS.users['${username}']}  access_token  ${EMPTY}
  ${ID_MAP}=  Create Dictionary
  Set Suite Variable  ${ID_MAP}
  Log Variables


Підготувати дані для оголошення тендера
  ${INITIAL_TENDER_DATA}=  prepare_test_tender_data
  [return]   ${INITIAL_TENDER_DATA}


Створити тендер
  [Arguments]  ${username}  ${tender_data}
  ${tender}=  Call Method  ${USERS.users['${username}'].client}  create_tender  ${tender_data}
  Log object data  ${tender}  created_tender
  ${access_token}=  Get Variable Value  ${tender.access.token}
  Set To Dictionary  ${USERS.users['${username}']}   access_token   ${access_token}
  Set To Dictionary  ${USERS.users['${username}']}   tender_data   ${tender}
  Log   ${access_token}
  Log   ${tender.data.id}
  Log   ${USERS.users['${username}'].tender_data}
  [return]  ${tender.data.tenderID}


Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  ${internalid}=  Отримати internal id по UAid  ${username}  ${tender_uaid}
  ${tender}=  Отримати тендер   ${username}   ${internalid}
  [return]   ${tender}


Оновити сторінку з тендером
  [Arguments]  ${username}  ${tender_uaid}
  ${tender_data}=  openprocurement_client.Пошук тендера по ідентифікатору    ${username}  ${tender_uaid}
  Log  ${tender_data}


Отримати інформацію із тендера
  [Arguments]  ${username}  ${fieldname}
  Log  ${username}
  Log  ${fieldname}
  ${status}=  Run Keyword And Return Status  Dictionary Should Contain Key  ${USERS.users['${username}'].tender_data.data}  ${fieldname}
  Run Keyword Unless
  ...      ${status}
  ...      openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${TENDER['TENDER_UAID']}
  ${field_value}=  Get_From_Object  ${USERS.users['${username}'].tender_data.data}  ${fieldname}
  Log  ${field_value}
  [return]  ${field_value}


Внести зміни в тендер
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Set_To_Object  ${tender.data}   ${fieldname}   ${fieldvalue}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${tender}=  Call Method  ${USERS.users['${username}'].client}  patch_tender  ${tender}
  Set_To_Object   ${USERS.users['${username}'].tender_data}   ${fieldname}   ${fieldvalue}


Отримати тендер
  [Arguments]  ${username}  ${internalid}
  Log  ${username}
  Log  ${internalid}
  ${tender}=  Call Method  ${USERS.users['${username}'].client}  get_tender  ${internalid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  Set To Dictionary  ${USERS.users['${username}']}  tender_data  ${tender}
  Log  ${tender}
  [Return]  ${tender}


Відняти предмети закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${number}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  @{items}=  Get From Object   ${tender.data}    items
  Log Many  @{items}
  :FOR    ${INDEX}    IN RANGE    ${number}
   \          Remove From List  ${items}  0
  Log Many  @{items}
  Set_To_Object    ${tender.data}   items  ${items}
  Call Method  ${USERS.users['${username}'].client}  patch_tender  ${tender}


Додати предмети закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${number}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  @{items}=  Get From Object   ${tender.data}    items
  Log Many  @{items}
  :FOR    ${INDEX}    IN RANGE    ${number}
  \    ${item}=  test_item_data
  \    Append To List  ${items}  ${item}
  Log Many  @{items}
  Set_To_Object    ${tender.data}   items  ${items}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  Call Method  ${USERS.users['${username}'].client}  patch_tender  ${tender}


Задати питання
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  Log  ${question}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${biddingresponse}=  Call Method  ${USERS.users['${username}'].client}  create_question  ${tender}  ${question}
  [return]  ${biddingresponse}


Відповісти на питання
  [Arguments]  ${username}  ${tender_uaid}  ${question_id}  ${answer_data}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${answer_data.data.id}=  Set Variable   ${tender.data.questions[${question_id}].id}
  ${question_with_answer}=  Call Method  ${USERS.users['${username}'].client}  patch_question  ${tender}  ${answer_data}
  Log object data   ${question_with_answer}  question_with_answer


Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${biddingresponse}=  Call Method  ${USERS.users['${username}'].client}  create_bid  ${tender}  ${bid}
  Log  ${biddingresponse}
  [return]  ${biddingresponse}


Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${changed_bid}=  Call Method  ${USERS.users['${username}'].client}  patch_bid  ${tender}  ${bid}
  Log  ${changed_bid}
  [return]   ${changed_bid}


Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${changed_bid}=  Call Method  ${USERS.users['${username}'].client}  delete_bid   ${tender}  ${bid}
  Log  ${changed_bid}
  [return]   ${changed_bid}


Прийняти цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${award}
  ${internalid}=  Отримати internal id по UAid  ${username}  ${tender_uaid}
  ${tender}=  Call Method  ${USERS.users['${username}'].client}  get_tender  ${internalid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${award_activeted_response}=  Call Method  ${USERS.users['${username}'].client}  patch_award  ${tender}  ${award}
  Log  ${award_activeted_response}
  [return]  ${award_activeted_response}


Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}
  ${bid_id}=  Get Variable Value   ${USERS.users['${username}'].bidresponses['resp'].data.id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  ${response}=  Call Method  ${USERS.users['${username}'].client}  upload_bid_document  ${path}  ${tender}  ${bid_id}
  ${uploaded_file} =  Create Dictionary   filepath  ${path}   upload_response  ${response}
  Log  ${response}
  Log object data   ${uploaded_file}
  [return]  ${uploaded_file}


Змінити документ в ставці
  [Arguments]  ${username}  ${path}  ${bidid}  ${docid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${TENDER['TENDER_UAID']}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  ${response}=  Call Method  ${USERS.users['${username}'].client}  update_bid_document  ${path}  ${tender}   ${bidid}   ${docid}
  ${uploaded_file} =  Create Dictionary   filepath  ${path}   upload_response  ${response}
  Log  ${response}
  Log object data   ${uploaded_file}
  [return]  ${uploaded_file}


Завантажити документ
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}
  Log  ${username}
  Log  ${tender_uaid}
  Log  ${filepath}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}   ${USERS.users['${username}'].access_token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  upload_document  ${filepath}  ${tender}
  Log object data   ${reply}  reply
  [return]   ${reply}


Отримати посилання на аукціон для глядача
  [Arguments]  ${username}  ${tender_uaid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  [return]  ${tender.data.auctionUrl}


Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}
  ${bid}=  Викликати для учасника  ${username}  Отримати пропозицію  ${tender_uaid}
  [return]  ${bid.data.participationUrl}


Отримати пропозицію
  [Arguments]  ${username}  ${tender_uaid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${bid_id}=  Get Variable Value  ${USERS.users['${username}'].bidresponses['resp'].data.id}
  ${token}=  Get Variable Value  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  ${bid}=  Call Method  ${USERS.users['${username}'].client}  get_bid  ${tender}  ${bid_id}  ${token}
  [return]  ${bid}


Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${url}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${token}=    Get Variable Value  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  ${contents}  ${filename}=  Call Method  ${USERS.users['${username}'].client}  get_file   ${tender}   ${url}   ${token}
  Log   ${filename}
  [return]   ${contents}  ${filename}


Створити лот
  [Arguments]  ${username}  ${tender}  ${lot}
  Log  ${username}
  Log  ${tender}
  Log  ${lot}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${tender_lot}=  Call Method  ${USERS.users['${username}'].client}   create_lot   ${tender}    ${lot}
  Log   ${tender_lot}
  [return]  ${tender_lot}
  #TODO:
  #[Arguments]  ${username}  ${tender_uaid}  ${lot}
  #${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}


Змінити лот
  [Arguments]  ${username}  ${tender}  ${lot}
  ${tender}=  set_access_key  ${tender}   ${USERS.users['${username}'].access_token}
  ${tender_lot}=  Call Method  ${USERS.users['${username}'].client}   patch_lot   ${tender}    ${lot}
  Log   ${tender_lot}
  [return]  ${tender_lot}
  #TODO:
  #[Arguments]  ${username}  ${tender_uaid}  ${lot}
  #${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}


Завантажити документ в лот
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}  ${lot_id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}   ${USERS.users['${username}'].access_token}
  ${doc}=  Завантажити документ  ${username}  ${filepath}  ${tender_uaid}
  ${lot_doc}=  test_lot_document_data  ${doc}  ${lot_id}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_document   ${tender}   ${lot_doc}
  Log object data   ${reply}  reply
  [return]   ${reply}


Видалити лот
  [Arguments]  ${username}  ${tender}  ${lot}
  ${tender}=  set_access_key  ${tender}   ${USERS.users['${username}'].access_token}
  ${tender_lot}=  Call Method  ${USERS.users['${username}'].client}   delete_lot   ${tender}   ${lot}
  Log   ${tender_lot}
  [return]  ${tender_lot}
  #TODO:
  #[Arguments]  ${username}  ${tender_uaid}  ${lot}
  #${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}

##############################################################################
#             Limited procurement
##############################################################################

Модифікувати закупівлю
  [Documentation]
  ...      [Arguments] Username and tender uaid
  ...      Find tender using uaid, get data from test_additional_items_data and call patch_tender
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${data}=  test_additional_items_data  ${tender['data']['id']}  ${tender['access']['token']}
  Log  ${data}
  Set To Dictionary  ${USERS.users['${tender_owner}']}  additional_items  ${data['data']['items']}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_tender  ${data}
  Log  ${reply}


Додати постачальника
  [Documentation]
  ...      [Arguments] Username and tender uaid
  ...      Find tender using uaid, get data from Підготувати дані про постачальника and call create_award
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${supplier_data}=  Підготувати дані про постачальника  ${username}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  create_award  ${tender}  ${supplier_data}
  Log  ${reply}


Підтвердити постачальника
  [Documentation]
  ...      [Arguments] Username, tender uaid and number of the award to confirm
  ...      Find tender using uaid, get data from test_confirm_supplier and call patch_award
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${data}=  test_confirm_supplier_data  ${tender['data']['awards'][${award_num}]['id']}
  Log  ${data}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_award  ${tender}  ${data}
  Log  ${reply}


Додати запит на скасування
  [Documentation]
  ...      [Arguments] Username, tender uaid and cancellation reason
  ...      Find tender using uaid, set cancellation reason, get data from test_cancel_tender
  ...      and call create_cancellation
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${cancellation_reason}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${data}=  test_cancel_tender_data  ${cancellation_reason}
  Log  ${data}
  Set To Dictionary  ${USERS.users['${tender_owner}']}  cancellation_reason  ${data}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  create_cancellation  ${tender}  ${data}
  Log  ${reply}


Завантажити документацію до запиту на скасування
  [Documentation]
  ...      [Arguments] Username, tender uaid and number of cancellation
  ...      Find tender using uaid, create fake documentation and call upload_cancellation_document
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${cancel_num}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${first_cancel_doc}=  create_fake_doc
  Set To Dictionary  ${USERS.users['${tender_owner}']}  first_cancel_doc  ${first_cancel_doc}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  upload_cancellation_document  ${first_cancel_doc}  ${tender}  ${tender['data']['cancellations'][${cancel_num}]['id']}
  Log  ${reply}


Змінити опис документа в скасуванні
  [Documentation]
  ...      [Arguments] Username, tender uaid, cancellation number and cancellation document number
  ...      Find tender using uaid, get data from test_change_cancellation_document_field and call
  ...      patch_cancellation_document
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${cancel_num}  ${doc_num}  ${field}  ${value}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${data}=  test_change_cancellation_document_field_data  ${field}  ${value}
  Log  ${data}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_cancellation_document  ${tender}  ${data}  ${tender['data']['cancellations'][${cancel_num}]['id']}  ${tender['data']['cancellations'][${cancel_num}]['documents'][${doc_num}]['id']}
  Log  ${reply}


Завантажити нову версію документа до запиту на скасування
  [Documentation]
  ...      [Arguments] Username, tender uaid, cancallation number and cancellation document number
  ...      Find tender using uaid, create fake documentation and call update_cancellation_document
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${cancel_num}  ${doc_num}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${second_cancel_doc}=  create_fake_doc
  Set To Dictionary  ${USERS.users['${tender_owner}']}  second_cancel_doc  ${second_cancel_doc}
  Log  ${second_cancel_doc}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  update_cancellation_document  ${second_cancel_doc}  ${tender}  ${tender['data']['cancellations'][${cancel_num}]['id']}  ${tender['data']['cancellations'][${cancel_num}]['documents'][${doc_num}]['id']}
  Log  ${reply}


Підтвердити скасування закупівлі
  [Documentation]
  ...      [Arguments] Username, tender uaid, cancellation number
  ...      Find tender using uaid, get cancellation test_confirmation data and call patch_cancellation
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${cancel_num}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${data}=  test_confirm_cancellation_data  ${tender['data']['cancellations'][${cancel_num}]['id']}
  Log  ${data}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_cancellation  ${tender}  ${data}
  Log  ${reply}


Підтвердити підписання контракту
  [Documentation]
  ...      [Arguments] Username, tender uaid, contract number
  ...      Find tender using uaid, get contract test_confirmation data and call patch_contract
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}
  ${tender}=  Викликати для учасника  ${username}  Пошук тендера по ідентифікатору  ${tender_uaid}
  ${data}=  test_confirm_contract_data  ${tender['data']['contracts'][${contract_num}]['id']}
  Log  ${data}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_contract  ${tender}  ${data}
  Log  ${reply}

##############################################################################
#             singleItemTenderclaims
##############################################################################

Створити вимогу
  [Documentation]  Створює вимогу у статусі "draft"
  [Arguments]  ${username}  ${tender_uaid}  ${claim}
  Log  ${claim}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору
  ...      ${username}
  ...      ${tender_uaid}
  ${reply}=  Call Method
  ...      ${USERS.users['${username}'].client}
  ...      create_complaint
  ...      ${tender}
  ...      ${claim}
  Log  ${reply}
  [return]  ${reply}


Завантажити документацію до вимоги
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${document}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${claim.access.token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  upload_complaint_document  ${document}  ${tender}  ${claim['data']['id']}
  Log  ${reply}


Подати вимогу
  [Documentation]  Переводить вимогу зі статусу "draft" у статус "claim"
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${confirmation_data}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${claim.access.token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_complaint  ${tender}  ${confirmation_data}
  Log  ${reply}


Відповісти на вирішену вимогу
  [Documentation]  Переводить вимогу зі статусу "claim" у статус "answered"
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${answer_data}
  Log  ${claim}
  Log  ${answer_data}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  log  ${tender}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_complaint  ${tender}  ${answer_data}
  Log  ${reply}


Підтвердити вирішення вимоги
  [Documentation]  Переводить вимогу зі статусу "answered" у статус "resolved"
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${confirmation_data}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${claim.access.token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_complaint  ${tender}  ${confirmation_data}
  Log  ${reply}


Скасувати вимогу
  [Documentation]  Переводить вимогу в статус "canceled"
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${cancellation_data}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${claim.access.token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_complaint  ${tender}  ${cancellation_data}
  Log  ${reply}


Перетворити вимогу в скаргу
  [Documentation]  Переводить вимогу зі статусу "answered" у статус "pending"
  [Arguments]  ${username}  ${tender_uaid}  ${claim}  ${escalating_data}
  ${tender}=  Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${claim.access.token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_complaint  ${tender}  ${escalating_data}
  Log  ${reply}
