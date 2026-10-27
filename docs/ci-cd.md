# CI/CD Flutter адаптера

## Покрытие адаптера

Widget тесты для Android и iOS проверяют передачу `banner`, `interstitial` и
`rewardVideo` в native-канал, параметры каждого формата, размер platform view
и обратные события загрузки, показа, ошибки, клика и закрытия. Для баннера и
interstitial проверяются доступные команды контроллера. Интеграционный тест
проверяет создание настоящего native view и обмен по каналу без обращения к
рекламной сети. Фактическая загрузка креатива и выдача награды зависят от
внешнего ad server и тестируются на уровне нативных SDK.

## Ветки и review

Одна задача — одна ветка: `feature/AD-123`, `bug-AD-123` или `sec-AD-123`.
Ветка задачи вливается через PR в `dev`; `dev` вливается через PR в `test`.
В описании PR обязательна ссылка на Jira вида `https://<host>/browse/AD-123`.

Настройте rulesets GitHub для `dev` и `test`: запрет прямого push, минимум одно
одобрение, обязательное разрешение всех review conversations и обязательные
статусы `policy`, `unit`, `android-integration`, `ios-integration` из workflow
`Flutter adapter CI`. Для `test` разрешите PR только из `dev`.
Настройте GitHub Environment `prod` с обязательным reviewer. Эти ограничения
нельзя надежно обеспечить одним файлом workflow: их проверяет GitHub до merge.

## Путь релиза

1. PR из ветки задачи в `dev`: policy → unit/widget → Android/iOS integration.
2. Обновите `version` в `pubspec.yaml` до `X.Y.Z` через PR в `dev`. Создайте
   на HEAD `dev` кандидатный тег `test/vX.Y.Z`. CI повторяет проверки и
   сверяет тег с версией и HEAD `dev`.
3. PR `dev` → `test`: те же проверки. Push в `test` запускает деплой consumer
   app в `stage` и Playwright smoke test. После успешного `stage` создайте
   на HEAD `test` релизный тег `vX.Y.Z` и отправьте его в origin.
4. CI релизного тега повторяет проверки, сверяет тег с `pubspec.yaml`, HEAD `test` и
   успешным `stage` check на этом commit. После одобрения Environment `prod`
   создает GitHub Release. Пользователи плагина могут ссылаться на этот тег.

Для `stage` задайте Environment variable `STAGE_URL` и secrets
`STAGE_DEPLOY_URL`, `STAGE_DEPLOY_TOKEN`. Webhook должен принять POST с JSON
`{"sha":"<commit>"}` и вернуть ошибку, если деплой не удался. Он должен
завершаться только после готовности приложения по `STAGE_URL`. Playwright
проверяет доступность web-приложения на stage. Он не проверяет native рекламу;
ее границу Flutter/native проверяет `integration_test` на эмуляторе и симуляторе.

Локально: `flutter test`; на устройстве: `cd example && flutter test
integration_test/plugin_integration_test.dart -d <device-id>`.
