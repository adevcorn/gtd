import app/database
import app/models/item.{TodoItem}
import app/web.{type Context, Context}
import gleam/dynamic
import gleam/json.{bool, object, string}
import gleam/list
import gleam/result
import gleam/string_builder
import pog.{type Connection}
import wisp.{type Request, type Response}

type ItemsJson {
  ItemsJson(id: String, title: String, completed: Bool)
}

pub fn items_middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(Context) -> Response,
) {
  let _parsed_items = {
    case wisp.get_cookie(req, "items", wisp.PlainText) {
      Ok(json_string) -> {
        let decoder =
          dynamic.decode3(
            ItemsJson,
            dynamic.field("id", dynamic.string),
            dynamic.field("title", dynamic.string),
            dynamic.field("completed", dynamic.bool),
          )
          |> dynamic.list

        let result = json.decode(json_string, decoder)
        case result {
          Ok(items) -> items
          Error(_) -> []
        }
      }
      Error(_) -> []
    }
  }

  handle_request(ctx)
}

pub fn get_todos(connection: Connection) {
  let todo_items = database.get_todos(connection)
  let json_items =
    list.map(todo_items, fn(x) {
      object([
        #("id", string(x.id)),
        #("title", string(x.title)),
        #("body", string(x.body)),
        #("completed", bool(item.item_status_to_bool(x.status))),
      ])
    })

  let jsonarray = json.preprocessed_array(json_items)

  // wisp.response(200)
  wisp.json_response(json.to_string_builder(jsonarray), 200)
}

pub fn get_todo_item(id: Int, connection: Connection) {
  let todo_item = database.get_todo(id, connection)

  let json_item =
    object([
      #("id", string(todo_item.id)),
      #("title", string(todo_item.title)),
      #("body", string(todo_item.body)),
      #("completed", bool(item.item_status_to_bool(todo_item.status))),
    ])
    |> json.to_string
  wisp.json_response(string_builder.from_string(json_item), 200)
}

pub fn post_create_item(request: Request, context: Context) {
  use json <- wisp.require_json(request)

  let result = {
    use item_json <- result.try(item.decode_item(json))
    let write_result =
      database.write_item(context.connection, item.create_item(item_json))

    let object =
      json.object([
        #("title", json.string(item_json.title)),
        #("completed", json.bool(item_json.completed)),
      ])
    Ok(json.to_string_builder(object))
  }

  case result {
    Ok(json) -> wisp.json_response(json, 201)
    Error(_) -> wisp.unprocessable_entity()
  }
}
