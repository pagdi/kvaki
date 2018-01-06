# Kvaki

## Запуск

Сервер:

mix run --no-halt

http://localhost:8000/


Модульные тесты:

mix test


Прочие тесты:

mix semper


Нагрузочный тест:

wrk -d5s -t4 -c4 -s kvstore.semper.lua http://127.0.0.1:8000



License
-------

Серьёзно?..
