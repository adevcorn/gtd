import gleam/bool
import gleam/io
import gleam/string_builder
import pog.{type Connection}
import wisp

pub type Context {
  Context(static_directory: String, connection: Connection)
}

pub fn middleware(
  request: wisp.Request,
  context: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let request = wisp.method_override(request)
  io.debug(request)
  use <- wisp.serve_static(
    request,
    under: "/static",
    from: context.static_directory,
  )
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes
  use request <- wisp.handle_head(request)

  use <- default_responses

  handle_request(request)
}

fn default_responses(handle_request: fn() -> wisp.Response) -> wisp.Response {
  let response = handle_request()

  use <- bool.guard(when: response.body != wisp.Empty, return: response)

  case response.status {
    404 | 405 ->
      "<h1>Not Found</h1>"
      |> string_builder.from_string
      |> wisp.html_body(response, _)

    400 | 422 ->
      "<h1>Bad request</h1>"
      |> string_builder.from_string
      |> wisp.html_body(response, _)

    413 ->
      "<h1>Request entity too large</h1>"
      |> string_builder.from_string
      |> wisp.html_body(response, _)

    500 ->
      "<h1>Internal server error</h1>"
      |> string_builder.from_string
      |> wisp.html_body(response, _)

    _ -> response
  }
}
