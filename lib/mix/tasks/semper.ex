defmodule Mix.Tasks.Semper do
  use Mix.Task

  @shortdoc "Тест персистентности"
  @moduledoc ~S"""
  Используется для быстрой проверки функций модуля Storage,
  в том числе с учётом временных интервалов хранения.
  #Usage
  ```
    mix semper
  ```
  """

  def run(_) do
      Storage.start(true)

      tests = [
        { "Storage key", :storage_key },
        { "Storage multi key", :storage_multi_key },
        { "Storage wrong key", :storage_wrong_key },
        { "Storage timeout", :storage_timeout },
        { "Storage purge", :storage_purge },
      ]

      overall = length(tests)
      passed = countTests(tests)
      report(overall, passed, overall-3)
  end

  # Отображаем общее количество тестов, пройденных и проваленных
  # (так легче отслеживать ошибки первого и второго рода).
  def report(overall, passed, expected) do
    IO.puts "Всего тестов: " <> Integer.to_string(overall) <>
            ", пройдено: " <> Integer.to_string(passed) <>
            ", ожидалось пройденных: " <> Integer.to_string(expected)
    IO.puts "~~~"
    case passed==expected do
      true -> IO.puts "Полностью успешное прохождение."
      _ -> IO.puts "НЕ полностью успешное прохождение."
    end
  end

  def countTests(list), do: countTests(list, 0)
  def countTests([test | xs], acc) do
    {test_name, function} = test
    success = assert(test_name, apply(__MODULE__, function, []))
    countTests(xs, acc+success)
  end
  def countTests([], acc), do: acc

  # Макросы зло, поэтому в лоб проверяем истинность.
  @good ": тест пройден успешно."
  @bad ": тест НЕ пройден."
  def assert(test_name, value) do
    case value do
      true ->
        IO.puts test_name <> @good
        1 # Возвращаем количество пройденных тестов (1 из 1).
      _ ->
        IO.puts test_name <> @bad
        0 # Возвращаем количество пройденных тестов (0 из 1).
    end
  end

  # Собственно тесты.

  def storage_key() do
    test_key="_test_key"
    test_value="_test_value"
    Storage.set(test_key, test_value, 9999)
    Storage.get(test_key)==test_value # Ожидается true
  end

  def storage_multi_key() do
    test_key1="_test_key1"
    test_key2="_test_key2"
    test_key3="_test_key3"
    test_value1="_test_value1"
    test_value2="_test_value2"
    test_value3="_test_value3"
    Storage.set(test_key1, test_value1, 9999)
    Storage.set(test_key2, test_value2, 9999)
    Storage.set(test_key3, test_value3, 9999)
    Storage.get(test_key1)==test_value1
      and Storage.get(test_key2)==test_value2
      and Storage.get(test_key3)==test_value3 # Ожидается true
  end

  def storage_wrong_key() do
    test_key="_test_key"
    test_value="_test_value"
    wrong_test_value="_wrong_test_value"
    Storage.set(test_key, test_value, 9999)
    Storage.get(test_key)==wrong_test_value  # Ожидается false
  end

  def storage_timeout() do
    test_key="_test_key"
    test_value="_test_value"
    Storage.set(test_key, test_value, 1)
    :timer.sleep(:timer.seconds(2))
    Storage.get(test_key)==test_value  # Ожидается false
  end

  def storage_purge() do
    test_key="_test_key"
    test_value="_test_value"
    Storage.set(test_key, test_value, 9999)
    Storage.purge()
    Storage.get(test_key)==test_value  # Ожидается false
  end
end
