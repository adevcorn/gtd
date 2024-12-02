import gleam/dynamic.{type Dynamic}
import wisp

pub type ItemStatus {
  Completed
  Uncompleted
}

pub type TodoItem {
  TodoItem(id: String, title: String, body: String, status: ItemStatus)
}

pub type ItemJson {
  ItemJson(title: String, body: String, completed: Bool)
}

pub fn create_item(item_json: ItemJson) -> TodoItem {
  let id = wisp.random_string(64)
  case item_json.completed {
    True -> TodoItem(id, item_json.title, item_json.body, status: Completed)
    False -> TodoItem(id, item_json.title, item_json.body, status: Uncompleted)
  }
}

pub fn decode_item(json: Dynamic) -> Result(ItemJson, List(dynamic.DecodeError)) {
  let decoder =
    dynamic.decode3(
      ItemJson,
      dynamic.field("title", dynamic.string),
      dynamic.field("body", dynamic.string),
      dynamic.field("completed", dynamic.bool),
    )

  decoder(json)
}

pub fn toggle_todo(item: TodoItem) -> TodoItem {
  let new_status = case item.status {
    Completed -> Uncompleted
    Uncompleted -> Completed
  }

  TodoItem(..item, status: new_status)
}

pub fn item_status_to_bool(status: ItemStatus) -> Bool {
  case status {
    Completed -> True
    Uncompleted -> False
  }
}

pub fn bool_to_item_status(status: Bool) -> ItemStatus {
  case status {
    True -> Completed
    False -> Uncompleted
  }
}
