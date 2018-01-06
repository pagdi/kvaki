-- Сценарий нагрузочного тестирования KVstore.
--
-- Запуск:
--    wrk -d5s -t4 -c4 -s kvstore.semper.lua http://127.0.0.1:8000
--
-- NB:  Строго говоря, нагрузочное на локальной машине - по определению несерьёзно.
--      Но за неимением гербовой.
--

math.randomseed(os.time())
math.random()
math.random()
math.random()

counter=0

request=function()
  counter=counter+1

  -- Простой запрос страницы.
  local path="/"

  -- Запрос одного значения по ключу.
  if math.random()>0.90 then
    path="/?"..math.random(1, 1000)
  end

  -- Добавление значения по ключу.
  if math.random()>0.95 then
    path="/?"..math.random(1, 1000).."="..math.random(1, 10000)
    -- Опциональное указание времени хранения.
    if math.random()>0.5 then
      path=path.."&"..math.random(1, 99)
    end
  end

  -- Аналогично можно добавить "/purge", но нет смысла.

  -- print(counter..": "..path)
  return wrk.format("GET", path, nil, "")
end
