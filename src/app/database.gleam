import app/models/item.{type TodoItem}
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import pog.{type Connection}

pub fn initialize_database(password: String) {
  let pw = Some(password)

  pog.default_config()
  |> pog.host("localhost")
  |> pog.database("gleam_app")
  |> pog.password(pw)
  |> pog.pool_size(15)
  |> pog.connect
}

pub fn configure_database(connection: Connection) {
  let sql_query =
    "
    CREATE TABLE IF NOT EXISTS public.item(
    item_id SERIAL PRIMARY KEY,
    title varchar(50) not null,
    body text,
    completed bool not null)
  "
  pog.query(sql_query)
  |> pog.execute(connection)
}

pub fn get_todos(connection: Connection) {
  let query =
    "
    select item_id, title, body, completed
    from public.item
  "

  let row_decoder =
    dynamic.tuple4(dynamic.int, dynamic.string, dynamic.string, dynamic.bool)

  let assert Ok(rows) =
    pog.query(query)
    |> pog.returning(row_decoder)
    |> pog.execute(connection)

  io.debug(rows.rows)

  list.map(rows.rows, fn(x) {
    item.TodoItem(
      int.to_string(x.0),
      title: x.1,
      body: x.2,
      status: item.bool_to_item_status(x.3),
    )
  })
}

pub fn get_todo(id: Int, connection: Connection) {
  let query =
    "
    select item_id, title, body, completed
    from public.item
    where item_id = $1
  "

  let row_decoder =
    dynamic.tuple4(dynamic.int, dynamic.string, dynamic.string, dynamic.bool)

  let assert Ok(response) =
    pog.query(query)
    |> pog.parameter(pog.int(id))
    |> pog.returning(row_decoder)
    |> pog.execute(connection)

  let assert Ok(row) = list.first(response.rows)

  item.TodoItem(
    int.to_string(row.0),
    row.1,
    row.2,
    item.bool_to_item_status(row.3),
  )
}

pub fn write_item(connection: Connection, todo_item: TodoItem) {
  let sql_query =
    "
    INSERT INTO item (title, body, completed)
    VALUES ($1, $2, $3);
  "

  pog.query(sql_query)
  |> pog.parameter(pog.text(todo_item.title))
  |> pog.parameter(pog.text(todo_item.body))
  |> pog.parameter(pog.bool(item.item_status_to_bool(todo_item.status)))
  |> pog.execute(connection)
}
