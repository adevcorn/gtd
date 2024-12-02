import app/routes/item_routes
import app/web.{type Context}
import gleam/http
import gleam/int
import wisp.{type Request, type Response}

pub fn handle_request(request: Request, context: Context) -> Response {
  use request <- web.middleware(request, context)

  case wisp.path_segments(request) {
    ["api", "items", "create"] -> {
      use <- wisp.require_method(request, http.Post)
      item_routes.post_create_item(request, context)
    }

    ["api", "items"] -> {
      use <- wisp.require_method(request, http.Get)
      item_routes.get_todos(context.connection)
    }

    ["api", "items", id] -> {
      use <- wisp.require_method(request, http.Get)
      let assert Ok(id) = int.parse(id)
      item_routes.get_todo_item(id, context.connection)
    }

    // All the empty responses
    ["internal-server-error"] -> wisp.internal_server_error()
    ["unprocessable-entity"] -> wisp.unprocessable_entity()
    ["method-not-allowed"] -> wisp.method_not_allowed([])
    ["entity-too-large"] -> wisp.entity_too_large()
    ["bad-request"] -> wisp.bad_request()
    _ -> wisp.not_found()
  }
}
