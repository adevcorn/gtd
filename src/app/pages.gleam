import app/models/item.{type TodoItem}
import app/pages/home

pub fn home(items: List(TodoItem)) {
  home.root(items)
}
